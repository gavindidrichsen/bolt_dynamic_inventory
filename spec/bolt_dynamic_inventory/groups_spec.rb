# frozen_string_literal: true

require 'spec_helper'
require 'bolt_dynamic_inventory/groups'
require 'tmpdir'

RSpec.describe BoltDynamicInventory::Groups do
  let(:tmpdir) { Dir.mktmpdir }
  let(:path) { File.join(tmpdir, 'vmpooler', 'groups.yaml') }
  let(:answers) { [] }
  let(:answer) { true }
  let(:prompter) do
    lambda { |message|
      answers << message
      answer
    }
  end
  let(:groups) { described_class.new(path: path, prompter: prompter) }
  let(:all_names) { %w[a1.x.net a2.x.net b1.x.net p1.x.net] }

  before { allow(groups).to receive(:warn) }

  after { FileUtils.remove_entry(tmpdir) }

  def sync(**opts)
    groups.sync(all_names: all_names, alive_names: all_names, **opts)
    saved
  end

  def saved
    YAML.safe_load_file(path)
  end

  def targets(name)
    saved.find { |g| g['name'] == name }['targets']
  end

  def write_groups(list)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, list.to_yaml)
  end

  it 'creates the file with global first, as the yaml plugin needs it to exist' do
    sync

    expect(saved).to eq([{ 'name' => 'global', 'targets' => all_names.sort }])
  end

  it 'writes a plain list of groups, as the yaml plugin returns the file as the group list' do
    sync

    expect(YAML.safe_load_file(path)).to be_an(Array)
  end

  it 'reads an older file with a groups: key and rewrites it as a plain list' do
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, { 'groups' => [{ 'name' => 'agents', 'targets' => ['a1.x.net'] }] }.to_yaml)

    expect(sync.map { |g| g['name'] }).to eq(%w[global agents])
  end

  it 'points Bolt at the file with the yaml plugin' do
    expect(groups.plugin_entry).to eq('_plugin' => 'yaml', 'filepath' => path.sub(Dir.home, '~'))
  end

  it 'persists a -g group with its role fact and no pattern key (Bolt rejects unknown group keys)' do
    sync(patterns: [{ group: 'agents', regex: /^a/ }])

    expect(saved.last).to eq('name' => 'agents', 'targets' => %w[a1.x.net a2.x.net],
                             'facts' => { 'role' => 'agents' })
  end

  it 'keeps the stored targets on later runs without -g' do
    sync(patterns: [{ group: 'agents', regex: /^a/ }])
    sync

    expect(targets('agents')).to eq(%w[a1.x.net a2.x.net])
  end

  it 'does not overwrite an existing group without force' do
    sync(patterns: [{ group: 'agents', regex: /^a/ }])
    sync(patterns: [{ group: 'agents', regex: /^b/ }])

    expect(targets('agents')).to eq(%w[a1.x.net a2.x.net])
    expect(groups).to have_received(:warn).with(/already exists.*--force/)
  end

  it 'overwrites an existing group with force' do
    sync(patterns: [{ group: 'agents', regex: /^a/ }])
    sync(patterns: [{ group: 'agents', regex: /^b/ }], force: true)

    expect(targets('agents')).to eq(['b1.x.net'])
  end

  it 'refuses names that clash with the built-in groups' do
    sync(patterns: [{ group: 'linux', regex: /^a/ }, { group: 'global', regex: /^a/ }])

    expect(saved.map { |g| g['name'] }).to eq(['global'])
  end

  it 'rebuilds global from the current VMs' do
    write_groups([{ 'name' => 'global', 'targets' => ['old.x.net'] }])

    expect(sync.first['targets']).to eq(all_names.sort)
  end

  it 'drops targets that are no longer in global and keeps the emptied group' do
    write_groups([{ 'name' => 'agents', 'targets' => ['gone.x.net'] }])
    sync

    expect(targets('agents')).to eq([])
  end

  context 'when the answer is no' do
    let(:answer) { false }

    it 'asks before dropping and keeps the targets' do
      write_groups([{ 'name' => 'agents', 'targets' => %w[a1.x.net gone.x.net] }])
      sync

      expect(targets('agents')).to eq(%w[a1.x.net gone.x.net])
      expect(answers.first).to match(/agents: gone.x.net/)
    end
  end

  it 'does not prune anything when the VM list is empty' do
    write_groups([{ 'name' => 'agents', 'targets' => ['a1.x.net'] }])
    groups.sync(all_names: [], alive_names: [])

    expect(targets('agents')).to eq(['a1.x.net'])
  end

  it 'names the VMs that are in no group' do
    write_groups([{ 'name' => 'agents', 'targets' => ['a1.x.net'] }])
    sync

    expect(groups).to have_received(:warn).with(/Not in any group: a2.x.net, b1.x.net, p1.x.net/)
  end

  describe 'the file shape' do
    it 'has no header comment and no pattern key' do
      sync(patterns: [{ group: 'agents', regex: /^a/ }])

      expect(File.read(path)).to start_with("---\n").and(satisfy { |t| !t.include?('pattern') })
    end

    it 'drops a pattern key left by an older file' do
      write_groups([{ 'name' => 'old', 'pattern' => '^o', 'targets' => [] }])
      sync

      expect(saved.find { |g| g['name'] == 'old' }).to eq('name' => 'old', 'targets' => [])
    end
  end
end
