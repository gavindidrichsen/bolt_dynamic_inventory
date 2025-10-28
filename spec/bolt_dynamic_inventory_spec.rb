# frozen_string_literal: true

require 'spec_helper'
require 'bolt_dynamic_inventory'
require 'open3'

RSpec.describe BoltDynamicInventory do
  describe '.new' do
    it 'creates an Orbstack provider by default' do
      inventory = described_class.new
      expect(inventory).to be_a(BoltDynamicInventory::Provider::Orbstack::Inventory)
    end

    it 'creates a VMPooler provider when specified' do
      inventory = described_class.new('provider' => 'vmpooler')
      expect(inventory).to be_a(BoltDynamicInventory::Provider::Vmpooler::Inventory)
    end

    it 'raises error for unknown provider' do
      expect { described_class.new('provider' => 'unknown') }.to raise_error(BoltDynamicInventory::Error)
    end
  end

  describe BoltDynamicInventory::Provider::Orbstack::Inventory do
    let(:mock_orbs) do
      [
        { 'name' => 'agent01', 'status' => 'running' },
        { 'name' => 'agent02', 'status' => 'running' },
        { 'name' => 'compiler01', 'status' => 'running' },
        { 'name' => 'webserver01', 'status' => 'running' }
      ]
    end

    before do
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

  describe BoltDynamicInventory::Provider::Vmpooler::Inventory do
    let(:mock_vmpooler_json) do
      {
        'job-1' => {
          'state' => 'filled',
          'allocated_resources' => [
            { 'hostname' => 'onetime-algebra.delivery.puppetlabs.net', 'type' => 'win-2019-x86_64' }
          ]
        },
        'job-2' => {
          'state' => 'allocated',
          'allocated_resources' => [
            { 'hostname' => 'tender-punditry.delivery.puppetlabs.net', 'type' => 'ubuntu-2004-x86_64' },
            { 'hostname' => 'normal-meddling.delivery.puppetlabs.net', 'type' => 'ubuntu-2004-x86_64' }
          ]
        }
      }.to_json
    end

    let(:mock_vms) do
      [
        { 'hostname' => 'onetime-algebra.delivery.puppetlabs.net', 'type' => 'win-2019-x86_64' },
        { 'hostname' => 'tender-punditry.delivery.puppetlabs.net', 'type' => 'ubuntu-2004-x86_64' },
        { 'hostname' => 'normal-meddling.delivery.puppetlabs.net', 'type' => 'ubuntu-2004-x86_64' }
      ]
    end

    let(:hostnames) do
      %w[
        onetime-algebra.delivery.puppetlabs.net
        tender-punditry.delivery.puppetlabs.net
        normal-meddling.delivery.puppetlabs.net
      ]
    end

    let(:mock_nmap_output_all_alive) do
      <<~NMAP
        Starting Nmap 7.98 ( https://nmap.org ) at 2025-10-28 18:00 +0000
        Nmap scan report for onetime-algebra.delivery.puppetlabs.net (10.16.121.11)
        Host is up (0.15s latency).

        PORT   STATE SERVICE
        22/tcp open  ssh

        Nmap scan report for tender-punditry.delivery.puppetlabs.net (10.16.121.12)
        Host is up (0.15s latency).

        PORT   STATE SERVICE
        22/tcp open  ssh

        Nmap scan report for normal-meddling.delivery.puppetlabs.net (10.16.121.13)
        Host is up (0.15s latency).

        PORT   STATE SERVICE
        22/tcp open  ssh

        Nmap done: 3 IP addresses (3 hosts up) scanned in 1.34 seconds
      NMAP
    end

    let(:mock_nmap_output_partial) do
      <<~NMAP
        Starting Nmap 7.98 ( https://nmap.org ) at 2025-10-28 18:00 +0000
        Nmap scan report for tender-punditry.delivery.puppetlabs.net (10.16.121.12)
        Host is up (0.15s latency).

        PORT   STATE SERVICE
        22/tcp open  ssh

        Nmap scan report for normal-meddling.delivery.puppetlabs.net (10.16.121.13)
        Host is up (0.15s latency).

        PORT   STATE SERVICE
        22/tcp open  ssh

        Nmap done: 2 IP addresses (2 hosts up) scanned in 1.34 seconds
      NMAP
    end

    let(:mock_nmap_stderr) do
      <<~STDERR
        Failed to resolve "onetime-algebra.delivery.puppetlabs.net".
      STDERR
    end

    context 'when no VMs are available' do
      before do
        allow(Open3).to receive(:capture3)
          .with('floaty list --active --json')
          .and_return(['', '', instance_double(Process::Status, success?: true)])
        # No need to mock nmap since no VMs means no filtering needed
      end

      it 'generates inventory with empty targets and base groups' do
        inventory = described_class.new
        result = inventory.generate

        expect(result['targets']).to eq([])

        # Check windows group is empty but configured
        windows_group = result['groups'].find { |g| g['name'] == 'windows' }
        expect(windows_group['targets']).to eq([])
        expect(windows_group['facts']).to eq('role' => 'windows')
        expect(windows_group['config']).to include(
          'transport' => 'winrm',
          'winrm' => {
            'password' => {
              '_plugin' => 'env_var',
              'var' => 'VMPOOLER_WINDOWS_PASSWORD'
            },
            'ssl' => false,
            'user' => 'Administrator'
          }
        )

        # Check linux group is empty but configured
        linux_group = result['groups'].find { |g| g['name'] == 'linux' }
        expect(linux_group['targets']).to eq([])
        expect(linux_group['facts']).to eq('role' => 'linux')
        expect(linux_group['config']['ssh']).to include(
          'native-ssh' => true,
          'load-config' => true,
          'login-shell' => 'bash'
        )
      end

      it 'generates inventory with empty regex-based groups' do
        inventory = described_class.new(
          'group_patterns' => [
            { 'group' => 'agent', 'pattern' => 'tender|normal' }
          ]
        )
        result = inventory.generate

        # Check regex-based group is empty
        agent_group = result['groups'].find { |g| g['name'] == 'agent' }
        expect(agent_group['targets']).to eq([])
        expect(agent_group['facts']).to eq('role' => 'agent')
      end
    end

    describe 'with available VMs' do
      before do
        allow(Open3).to receive(:capture3)
          .with('floaty list --active --json')
          .and_return([mock_vmpooler_json, '', instance_double(Process::Status, success?: true)])
        allow(Open3).to receive(:capture3)
          .with('nmap', '-Pn', '-p', '22', *hostnames)
          .and_return([mock_nmap_output_all_alive, mock_nmap_stderr, instance_double(Process::Status, success?: true)])
      end

      let(:inventory) { described_class.new }
      let(:result) { inventory.generate }

      it 'generates correct targets' do
        expect(result['targets'].length).to eq(3)
        expect(result['targets'].map { |t| t['name'] }).to contain_exactly(
          'onetime-algebra', 'tender-punditry', 'normal-meddling'
        )
      end

      it 'configures windows group correctly' do
        windows_group = result['groups'].find { |g| g['name'] == 'windows' }
        expect(windows_group['targets']).to contain_exactly('onetime-algebra')
        expect(windows_group['facts']).to eq('role' => 'windows')
        expect(windows_group['config']).to include(
          'transport' => 'winrm',
          'winrm' => {
            'password' => {
              '_plugin' => 'env_var',
              'var' => 'VMPOOLER_WINDOWS_PASSWORD'
            },
            'ssl' => false,
            'user' => 'Administrator'
          }
        )
      end

      it 'configures linux group correctly' do
        linux_group = result['groups'].find { |g| g['name'] == 'linux' }
        expect(linux_group['targets']).to contain_exactly('tender-punditry', 'normal-meddling')
        expect(linux_group['facts']).to eq('role' => 'linux')
        expect(linux_group['config']['ssh']).to include(
          'native-ssh' => true,
          'load-config' => true,
          'login-shell' => 'bash'
        )
      end

      it 'generates inventory with both base and regex-based groups when patterns are provided' do
        inventory = described_class.new(
          'group_patterns' => [
            { 'group' => 'agent', 'pattern' => 'tender|normal' }
          ]
        )
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

    describe 'host filtering with nmap' do
      before do
        allow(Open3).to receive(:capture3)
          .with('floaty list --active --json')
          .and_return([mock_vmpooler_json, '', instance_double(Process::Status, success?: true)])
      end

      context 'when some hosts are unreachable' do
        before do
          allow(Open3).to receive(:capture3)
            .with('nmap', '-Pn', '-p', '22', *hostnames)
            .and_return([mock_nmap_output_partial, mock_nmap_stderr, instance_double(Process::Status, success?: true)])
        end

        it 'filters out unreachable hosts' do
          inventory = described_class.new
          result = inventory.generate

          expect(result['targets'].length).to eq(2)
          expect(result['targets'].map { |t| t['name'] }).to contain_exactly('tender-punditry', 'normal-meddling')

          # Windows group should be empty since onetime-algebra is unreachable
          windows_group = result['groups'].find { |g| g['name'] == 'windows' }
          expect(windows_group['targets']).to eq([])

          # Linux group should only contain reachable hosts
          linux_group = result['groups'].find { |g| g['name'] == 'linux' }
          expect(linux_group['targets']).to contain_exactly('tender-punditry', 'normal-meddling')
        end
      end

      context 'when nmap fails' do
        before do
          allow(Open3).to receive(:capture3)
            .with('nmap', '-Pn', '-p', '22', *hostnames)
            .and_return(['', 'nmap: command not found',
                         instance_double(Process::Status, success?: false, exitstatus: 127)])
        end

        it 'raises an error with details' do
          inventory = described_class.new
          expect { inventory.generate }.to raise_error(/nmap failed.*127.*nmap: command not found/)
        end
      end

      context 'when all hosts are unreachable' do
        before do
          allow(Open3).to receive(:capture3)
            .with('nmap', '-Pn', '-p', '22', *hostnames)
            .and_return(['', mock_nmap_stderr, instance_double(Process::Status, success?: true)])
        end

        it 'generates inventory with empty targets' do
          inventory = described_class.new
          result = inventory.generate

          expect(result['targets']).to eq([])
          expect(result['groups'].find { |g| g['name'] == 'windows' }['targets']).to eq([])
          expect(result['groups'].find { |g| g['name'] == 'linux' }['targets']).to eq([])
        end
      end
    end
  end
end
