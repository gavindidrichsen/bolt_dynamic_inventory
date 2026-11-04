# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'tmpdir'
require 'rbconfig'

# Runs the real exe/binv with a stand-in `orb` command and a throwaway HOME
RSpec.describe 'binv --path', type: :feature do
  let(:home) { Dir.mktmpdir }
  let(:bin) { Dir.mktmpdir }
  let(:root) { File.expand_path('..', __dir__) }

  before do
    stub_command('orb', %(echo '[{"name":"agent01","status":"running"}]'))
  end

  after do
    FileUtils.remove_entry(home)
    FileUtils.remove_entry(bin)
  end

  def stub_command(name, body)
    path = File.join(bin, name)
    File.write(path, "#!/bin/sh\n#{body}\n")
    File.chmod(0o755, path)
  end

  def binv(*args)
    Open3.capture3({ 'HOME' => home, 'PATH' => "#{bin}:/usr/bin:/bin" },
                   RbConfig.ruby, "-I#{File.join(root, 'lib')}", File.join(root, 'exe', 'binv'), *args)
  end

  it 'prints only the orbstack inventory.yaml path on stdout, and the file and its groups.yaml exist' do
    out, _err, status = binv('--provider=orbstack', '--path')
    dir = File.join(home, '.config', 'bolt_dynamic_inventory', 'orbstack')

    expect(status).to be_success
    expect(out).to eq("#{File.join(dir, 'inventory.yaml')}\n")
    expect(File).to exist(File.join(dir, 'inventory.yaml'))
    groups = YAML.safe_load_file(File.join(dir, 'groups.yaml')).map { |g| g['name'] }
    expect(groups).to start_with('global', 'ungrouped')
  end

  it 'defaults to the orbstack provider' do
    out, _err, = binv('--path')

    expect(out).to eq("#{File.join(home, '.config', 'bolt_dynamic_inventory', 'orbstack', 'inventory.yaml')}\n")
  end

  it 'still prints the inventory YAML without --path' do
    out, = binv('--provider=orbstack')

    expect(YAML.safe_load(out)['targets'].map { |t| t['name'] }).to eq(['agent01'])
  end
end
