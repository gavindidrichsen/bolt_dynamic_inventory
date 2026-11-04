# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'tmpdir'
require 'rbconfig'

# Runs the real exe/binv with a stand-in `orb` command and a throwaway HOME
RSpec.describe 'binv output', type: :feature do
  let(:home) { Dir.mktmpdir }
  let(:bin) { Dir.mktmpdir }
  let(:root) { File.expand_path('..', __dir__) }
  let(:inventory_path) { File.join(home, '.config', 'bolt_dynamic_inventory', 'orbstack', 'inventory.yaml') }

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

  it 'prints only the inventory.yaml path by default, and the file and its groups.yaml exist' do
    out, _err, status = binv('--provider=orbstack')

    expect(status).to be_success
    expect(out).to eq("#{inventory_path}\n")
    expect(File).to exist(inventory_path)
    groups = YAML.safe_load_file(File.join(File.dirname(inventory_path), 'groups.yaml')).map { |g| g['name'] }
    expect(groups).to start_with('global', 'ungrouped')
  end

  it 'defaults to the orbstack provider' do
    out, _err, = binv

    expect(out).to eq("#{inventory_path}\n")
  end

  it 'prints the inventory YAML with --stdout, and still writes the file' do
    out, _err, = binv('--provider=orbstack', '--stdout')

    expect(YAML.safe_load(out)['targets'].map { |t| t['name'] }).to eq(['agent01'])
    expect(File).to exist(inventory_path)
  end

  it 'no longer has --path' do
    _out, err, status = binv('--path')

    expect(status).not_to be_success
    expect(err).to include('invalid option: --path')
  end
end
