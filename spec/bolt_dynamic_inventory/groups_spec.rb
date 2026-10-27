# frozen_string_literal: true

require 'spec_helper'
require 'bolt_dynamic_inventory/groups'
require 'tmpdir'

RSpec.describe BoltDynamicInventory::Groups do
  let(:tmpdir) { Dir.mktmpdir }
  let(:global_path) { File.join(tmpdir, 'global', 'groups.yaml') }
  let(:local_path) { File.join(tmpdir, 'groups.yaml') }
  let(:answers) { [] }
  let(:answer) { true }
  let(:prompter) do
    lambda { |message|
      answers << message
      answer
    }
  end
  let(:groups) { described_class.new(global_path: global_path, local_path: local_path, prompter: prompter) }
  let(:all_names) { %w[a1.x.net a2.x.net b1.x.net p1.x.net] }

  before do
    allow(groups).to receive(:warn)
  end

  after { FileUtils.remove_entry(tmpdir) }

  def sync(**opts)
    groups.sync(all_names: all_names, alive_names: all_names, **opts)
  end

  def names(result, name)
    result.find { |g| g['name'] == name }['targets']
  end

  def write_groups(path, list)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, { 'groups' => list }.to_yaml)
  end

  it 'treats missing files as no groups and always lists every target in global' do
    result = sync

    expect(result.map { |g| g['name'] }).to eq(['global'])
    expect(names(result, 'global')).to eq(all_names.sort)
  end

  it 'persists a -g group to the global file' do
    sync(patterns: [{ group: 'agents', regex: /^a/ }])

    saved = YAML.safe_load_file(global_path)['groups']
    expect(saved.find { |g| g['name'] == 'agents' }).to include('pattern' => '^a', 'targets' => %w[a1.x.net a2.x.net])
  end

  it 'keeps the stored targets on later runs without -g' do
    sync(patterns: [{ group: 'agents', regex: /^a/ }])

    expect(names(sync, 'agents')).to eq(%w[a1.x.net a2.x.net])
  end

  it 'does not overwrite an existing group without force' do
    sync(patterns: [{ group: 'agents', regex: /^a/ }])

    result = sync(patterns: [{ group: 'agents', regex: /^b/ }])

    expect(names(result, 'agents')).to eq(%w[a1.x.net a2.x.net])
    expect(groups).to have_received(:warn).with(/already exists.*--force/)
  end

  it 'overwrites an existing group with force' do
    sync(patterns: [{ group: 'agents', regex: /^a/ }])

    result = sync(patterns: [{ group: 'agents', regex: /^b/ }], force: true)

    expect(names(result, 'agents')).to eq(['b1.x.net'])
  end

  it 'lets a local group replace a global group of the same name' do
    write_groups(global_path, [{ 'name' => 'agents', 'targets' => %w[a1.x.net a2.x.net] }])
    write_groups(local_path, [{ 'name' => 'agents', 'targets' => ['a2.x.net'] }])

    expect(names(sync, 'agents')).to eq(['a2.x.net'])
  end

  it 'adds local groups to the global ones' do
    write_groups(global_path, [{ 'name' => 'agents', 'targets' => ['a1.x.net'] }])
    write_groups(local_path, [{ 'name' => 'mine', 'targets' => ['b1.x.net'] }])

    expect(sync.map { |g| g['name'] }).to eq(%w[global agents mine])
  end

  it 'drops targets that are no longer in global and rewrites the file' do
    write_groups(global_path, [{ 'name' => 'agents', 'targets' => %w[a1.x.net gone.x.net] }])

    expect(names(sync, 'agents')).to eq(['a1.x.net'])
    expect(YAML.safe_load_file(global_path)['groups'].last['targets']).to eq(['a1.x.net'])
  end

  context 'when the answer is no' do
    let(:answer) { false }

    it 'asks before dropping and keeps the targets' do
      write_groups(global_path, [{ 'name' => 'agents', 'targets' => %w[a1.x.net gone.x.net] }])

      expect(names(sync, 'agents')).to eq(%w[a1.x.net gone.x.net])
      expect(answers.first).to match(/agents: gone.x.net/)
    end
  end

  it 'does not prune anything when the VM list is empty' do
    write_groups(global_path, [{ 'name' => 'agents', 'targets' => ['a1.x.net'] }])

    result = groups.sync(all_names: [], alive_names: [])

    expect(names(result, 'agents')).to eq(['a1.x.net'])
  end

  it 'names the VMs that are in no group' do
    write_groups(global_path, [{ 'name' => 'agents', 'targets' => ['a1.x.net'] }])

    sync

    expect(groups).to have_received(:warn).with(/Not in any group: a2.x.net, b1.x.net, p1.x.net/)
  end
end
