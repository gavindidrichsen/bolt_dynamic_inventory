# frozen_string_literal: true

require 'spec_helper'
require 'orbstack_bolt_inventory'

RSpec.describe OrbstackBoltInventory do
  describe '.new' do
    it 'creates an Orbstack provider by default' do
      inventory = described_class.new
      expect(inventory).to be_a(OrbstackBoltInventory::Provider::Orbstack::Inventory)
    end

    it 'creates a VMPooler provider when specified' do
      inventory = described_class.new('provider' => 'vmpooler')
      expect(inventory).to be_a(OrbstackBoltInventory::Provider::Vmpooler::Inventory)
    end

    it 'raises error for unknown provider' do
      expect { described_class.new('provider' => 'unknown') }.to raise_error(OrbstackBoltInventory::Error)
    end
  end

  describe OrbstackBoltInventory::Provider::Orbstack::Inventory do
    let(:mock_orbs) do
      [
        { 'name' => 'agent01', 'status' => 'running' },
        { 'name' => 'agent02', 'status' => 'running' },
        { 'name' => 'compiler01', 'status' => 'running' },
        { 'name' => 'webserver01', 'status' => 'running' }
      ]
    end

    before(:each) do
      allow_any_instance_of(described_class).to receive(:fetch_orbstack_vms).and_return(mock_orbs)
    end

    context 'basic inventory without group_patterns' do
      let(:inventory) { described_class.new }

      it 'generates inventory with only targets' do
        result = inventory.generate

        expect(result['targets'].length).to eq(4)
        expect(result['targets'].map { |t| t['name'] }).to contain_exactly(
          'agent01', 'agent02', 'compiler01', 'webserver01'
        )
        expect(result['targets'].map { |t| t['uri'] }).to contain_exactly(
          'agent01@orb', 'agent02@orb', 'compiler01@orb', 'webserver01@orb'
        )
      end

      it 'includes correct ssh configuration' do
        result = inventory.generate
        ssh_config = result['config']['ssh']

        expect(ssh_config).to include(
          'native-ssh' => true,
          'load-config' => true,
          'login-shell' => 'bash',
          'tty' => false,
          'host-key-check' => false,
          'run-as' => 'root',
          'user' => 'root',
          'port' => 32_222
        )
      end
    end

    context 'with group patterns' do
      let(:inventory) do
        described_class.new(
          'group_patterns' => [
            { 'group' => 'agent', 'pattern' => '^agent' },
            { 'group' => 'compiler', 'pattern' => '^compiler' }
          ]
        )
      end

      it 'generates inventory with regex-based groups and role facts' do
        result = inventory.generate

        expect(result['groups'].length).to eq(2)

        agent_group = result['groups'].find { |g| g['name'] == 'agent' }
        expect(agent_group['targets']).to contain_exactly('agent01', 'agent02')
        expect(agent_group['facts']).to eq('role' => 'agent')

        compiler_group = result['groups'].find { |g| g['name'] == 'compiler' }
        expect(compiler_group['targets']).to contain_exactly('compiler01')
        expect(compiler_group['facts']).to eq('role' => 'compiler')
      end
    end
  end

  describe OrbstackBoltInventory::Provider::Vmpooler::Inventory do
    let(:mock_vms) do
      [
        { 'hostname' => 'onetime-algebra.delivery.puppetlabs.net', 'type' => 'win-2019-x86_64' },
        { 'hostname' => 'tender-punditry.delivery.puppetlabs.net', 'type' => 'ubuntu-2004-x86_64' },
        { 'hostname' => 'normal-meddling.delivery.puppetlabs.net', 'type' => 'ubuntu-2004-x86_64' }
      ]
    end

    before(:each) do
      allow_any_instance_of(described_class).to receive(:fetch_vmpooler_vms).and_return(mock_vms)
    end

    context 'basic inventory without group_patterns' do
      let(:inventory) { described_class.new }

      it 'generates inventory with targets and base groups' do
        result = inventory.generate

        expect(result['targets'].length).to eq(3)
        expect(result['targets'].map { |t| t['name'] }).to contain_exactly(
          'onetime-algebra', 'tender-punditry', 'normal-meddling'
        )

        # Check windows group
        windows_group = result['groups'].find { |g| g['name'] == 'windows' }
        expect(windows_group['targets']).to contain_exactly('onetime-algebra')
        expect(windows_group['facts']).to eq('role' => 'windows')
        expect(windows_group['config']['ssh']).to include(
          '_plugin' => 'yaml',
          'filepath' => '~/.secrets/bolt/windows/ssh/vmpooler/windows_credentials.yaml'
        )

        # Check linux group
        linux_group = result['groups'].find { |g| g['name'] == 'linux' }
        expect(linux_group['targets']).to contain_exactly('tender-punditry', 'normal-meddling')
        expect(linux_group['facts']).to eq('role' => 'linux')
        expect(linux_group['config']['ssh']).to include(
          'native-ssh' => true,
          'load-config' => true,
          'login-shell' => 'bash'
        )
      end
    end

    context 'with group patterns' do
      let(:inventory) do
        described_class.new(
          'group_patterns' => [
            { 'group' => 'agent', 'pattern' => 'tender|normal' }
          ]
        )
      end

      it 'generates inventory with both base and regex-based groups' do
        result = inventory.generate

        # Base groups should still exist
        expect(result['groups'].find { |g| g['name'] == 'windows' }).not_to be_nil
        expect(result['groups'].find { |g| g['name'] == 'linux' }).not_to be_nil

        # Check regex-based group
        agent_group = result['groups'].find { |g| g['name'] == 'agent' }
        expect(agent_group['targets']).to contain_exactly('tender-punditry', 'normal-meddling')
        expect(agent_group['facts']).to eq('role' => 'agent')
      end
    end
  end
end
