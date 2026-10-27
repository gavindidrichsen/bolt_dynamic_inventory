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
        { 'name' => 'webserver01', 'status' => 'running' },
        { 'name' => 'compiler01', 'status' => 'running' },
        { 'name' => 'agent02', 'status' => 'running' },
        { 'name' => 'agent01', 'status' => 'running' }
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
          'copy-command' => ['scp', '-r', '-O'],
          'load-config' => true,
          'login-shell' => 'bash',
          'tty' => false,
          'host-key-check' => false,
          'run-as' => 'root',
          'user' => 'root',
          'port' => 32_222
        )
      end

      it 'sorts targets alphabetically by name' do
        result = inventory.generate

        expect(result['targets'].map { |t| t['name'] }).to eq(
          %w[agent01 agent02 compiler01 webserver01]
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
    before do
      allow_any_instance_of(BoltDynamicInventory::VmCache).to receive(:read).and_return(nil)
      allow_any_instance_of(BoltDynamicInventory::VmCache).to receive(:write)
      allow_any_instance_of(BoltDynamicInventory::VmCache).to receive(:write_inventory)
      # keep the persisted groups.yaml out of the real home
      allow_any_instance_of(BoltDynamicInventory::VmCache).to receive(:groups_path)
        .and_return(File.join(groups_dir, 'groups.yaml'))
    end

    after { FileUtils.remove_entry(groups_dir) }

    let(:groups_dir) { Dir.mktmpdir }
    let(:mock_abs_json) do
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

    let(:mock_vmpooler_service_json) do
      {
        'onetime-algebra' => {
          'template' => 'win-2019-x86_64',
          'fqdn' => 'onetime-algebra.delivery.puppetlabs.net',
          'state' => 'running',
          'lifetime' => 24,
          'running' => 3.5
        },
        'tender-punditry' => {
          'template' => 'ubuntu-2004-x86_64',
          'fqdn' => 'tender-punditry.delivery.puppetlabs.net',
          'state' => 'running',
          'lifetime' => 24,
          'running' => 6.0,
          'snapshots' => %w[snapaaa snapbbb]
        },
        'normal-meddling' => {
          'template' => 'ubuntu-2004-x86_64',
          'fqdn' => 'normal-meddling.delivery.puppetlabs.net',
          'state' => 'running',
          'lifetime' => 24,
          'running' => 6.0
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

    let(:success_status) { instance_double(Process::Status, success?: true) }

    def stub_abs_response(json_str)
      allow(Open3).to receive(:capture3)
        .with('floaty', 'list', '--active', '--json')
        .and_return([json_str, '', success_status])
    end

    def stub_vmpooler_service_response(json_str)
      allow(Open3).to receive(:capture3)
        .with('floaty', 'list', '--active', '--json', '--service', 'vmpooler')
        .and_return([json_str, '', success_status])
    end

    context 'when no VMs are available' do
      before do
        stub_abs_response('')
        stub_vmpooler_service_response('')
      end

      it 'generates inventory with empty targets and base groups' do
        inventory = described_class.new
        result = inventory.generate

        expect(result['targets']).to eq([])

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

        linux_group = result['groups'].find { |g| g['name'] == 'linux' }
        expect(linux_group['targets']).to eq([])
        expect(linux_group['facts']).to eq('role' => 'linux')
        expect(linux_group['config']['ssh']).to include(
          'native-ssh' => true,
          'copy-command' => ['scp', '-r', '-O'],
          'load-config' => true,
          'login-shell' => 'bash'
        )
      end

      it 'generates an empty custom group in groups.yaml' do
        inventory = described_class.new(
          'group_patterns' => [
            { 'group' => 'agent', 'pattern' => 'tender|normal' }
          ]
        )
        result = inventory.generate

        expect(result['groups'].map { |g| g['name'] || g['_plugin'] }).to eq(%w[windows linux yaml])
        saved = YAML.safe_load_file(File.join(groups_dir, 'groups.yaml'))['groups']
        expect(saved.find { |g| g['name'] == 'agent' }['targets']).to eq([])
      end
    end

    describe 'with available VMs' do
      before do
        stub_abs_response(mock_abs_json)
        stub_vmpooler_service_response(mock_vmpooler_service_json)
        allow(Open3).to receive(:capture3)
          .with('nmap', '-Pn', '-p', '22', *hostnames)
          .and_return([mock_nmap_output_all_alive, mock_nmap_stderr, success_status])
      end

      let(:inventory) { described_class.new }
      let(:result) { inventory.generate }

      it 'generates correct targets' do
        expect(result['targets'].length).to eq(3)
        expect(result['targets'].map { |t| t['name'] }).to contain_exactly(
          'onetime-algebra.delivery.puppetlabs.net',
          'tender-punditry.delivery.puppetlabs.net',
          'normal-meddling.delivery.puppetlabs.net'
        )
      end

      it 'names each target by FQDN with the short name as alias' do
        target = result['targets'].find { |t| t['alias'] == 'tender-punditry' }
        expect(target['name']).to eq('tender-punditry.delivery.puppetlabs.net')
        expect(target['uri']).to eq('tender-punditry.delivery.puppetlabs.net')
      end

      it 'sorts targets alphabetically by name' do
        expect(result['targets'].map { |t| t['name'] }).to eq(
          %w[normal-meddling.delivery.puppetlabs.net onetime-algebra.delivery.puppetlabs.net
             tender-punditry.delivery.puppetlabs.net]
        )
      end

      it 'includes vars with type and ttl for each target' do
        targets = result['targets']

        onetime_target = targets.find { |t| t['name'] == 'onetime-algebra.delivery.puppetlabs.net' }
        expect(onetime_target['vars']['type']).to eq('win-2019-x86_64')
        expect(onetime_target['vars']['ttl']).to match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/)

        tender_target = targets.find { |t| t['name'] == 'tender-punditry.delivery.puppetlabs.net' }
        expect(tender_target['vars']['type']).to eq('ubuntu-2004-x86_64')
        expect(tender_target['vars']['ttl']).to match(/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$/)
      end

      it 'lists snapshot ids in vars only for VMs that have snapshots' do
        tender = result['targets'].find { |t| t['alias'] == 'tender-punditry' }
        expect(tender['vars']['snapshots']).to eq(%w[snapaaa snapbbb])

        onetime = result['targets'].find { |t| t['alias'] == 'onetime-algebra' }
        expect(onetime['vars']).not_to have_key('snapshots')
      end

      it 'configures windows group correctly' do
        windows_group = result['groups'].find { |g| g['name'] == 'windows' }
        expect(windows_group['targets']).to contain_exactly('onetime-algebra.delivery.puppetlabs.net')
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
        expect(linux_group['targets']).to contain_exactly('tender-punditry.delivery.puppetlabs.net',
                                                          'normal-meddling.delivery.puppetlabs.net')
        expect(linux_group['facts']).to eq('role' => 'linux')
        expect(linux_group['config']['ssh']).to include(
          'native-ssh' => true,
          'copy-command' => ['scp', '-r', '-O'],
          'load-config' => true,
          'login-shell' => 'bash'
        )
      end

      it 'keeps custom groups in groups.yaml and loads them with the yaml plugin' do
        inventory = described_class.new(
          'group_patterns' => [
            { 'group' => 'agent', 'pattern' => 'tender|normal' }
          ]
        )
        result = inventory.generate

        expect(result['groups'].map { |g| g['name'] || g['_plugin'] }).to eq(%w[windows linux yaml])
        expect(result['groups'].last['filepath']).to end_with('groups.yaml')

        saved = YAML.safe_load_file(File.join(groups_dir, 'groups.yaml'))['groups']
        agent_group = saved.find { |g| g['name'] == 'agent' }
        expect(agent_group['targets']).to contain_exactly('tender-punditry.delivery.puppetlabs.net',
                                                          'normal-meddling.delivery.puppetlabs.net')
        expect(agent_group['facts']).to eq('role' => 'agent')
      end
    end

    describe 'merging VMs from ABS and vmpooler services' do
      let(:extra_vmpooler_json) do
        {
          'onetime-algebra.delivery.puppetlabs.net' => {
            'template' => 'win-2019-x86_64',
            'fqdn' => 'onetime-algebra.delivery.puppetlabs.net',
            'state' => 'running',
            'lifetime' => 24,
            'running' => 3.5
          },
          'tender-punditry.delivery.puppetlabs.net' => {
            'template' => 'ubuntu-2004-x86_64',
            'fqdn' => 'tender-punditry.delivery.puppetlabs.net',
            'state' => 'running',
            'lifetime' => 24,
            'running' => 6.0
          },
          'normal-meddling.delivery.puppetlabs.net' => {
            'template' => 'ubuntu-2004-x86_64',
            'fqdn' => 'normal-meddling.delivery.puppetlabs.net',
            'state' => 'running',
            'lifetime' => 24,
            'running' => 6.0
          },
          'tight-mantrap.delivery.puppetlabs.net' => {
            'template' => 'ubuntu-2404-x86_64',
            'fqdn' => 'tight-mantrap.delivery.puppetlabs.net',
            'state' => 'running',
            'lifetime' => 24,
            'running' => 1.0
          },
          'unhurt-gadgetry.delivery.puppetlabs.net' => {
            'template' => 'ubuntu-2404-x86_64',
            'fqdn' => 'unhurt-gadgetry.delivery.puppetlabs.net',
            'state' => 'running',
            'lifetime' => 24,
            'running' => 1.0
          }
        }.to_json
      end

      let(:all_hostnames) do
        %w[
          onetime-algebra.delivery.puppetlabs.net
          tender-punditry.delivery.puppetlabs.net
          normal-meddling.delivery.puppetlabs.net
          tight-mantrap.delivery.puppetlabs.net
          unhurt-gadgetry.delivery.puppetlabs.net
        ]
      end

      let(:mock_nmap_output_all_five) do
        <<~NMAP
          Starting Nmap 7.98 ( https://nmap.org ) at 2025-10-28 18:00 +0000
          Nmap scan report for onetime-algebra.delivery.puppetlabs.net (10.16.121.11)
          Host is up (0.15s latency).
          Nmap scan report for tender-punditry.delivery.puppetlabs.net (10.16.121.12)
          Host is up (0.15s latency).
          Nmap scan report for normal-meddling.delivery.puppetlabs.net (10.16.121.13)
          Host is up (0.15s latency).
          Nmap scan report for tight-mantrap.delivery.puppetlabs.net (10.16.121.14)
          Host is up (0.15s latency).
          Nmap scan report for unhurt-gadgetry.delivery.puppetlabs.net (10.16.121.15)
          Host is up (0.15s latency).
          Nmap done: 5 IP addresses (5 hosts up) scanned in 1.34 seconds
        NMAP
      end

      before do
        stub_abs_response(mock_abs_json)
        stub_vmpooler_service_response(extra_vmpooler_json)
        allow(Open3).to receive(:capture3)
          .with('nmap', '-Pn', '-p', '22', *all_hostnames)
          .and_return([mock_nmap_output_all_five, '', success_status])
      end

      it 'includes VMs from both ABS and vmpooler services' do
        inventory = described_class.new
        result = inventory.generate

        expect(result['targets'].map { |t| t['name'] }).to contain_exactly(
          'onetime-algebra.delivery.puppetlabs.net',
          'tender-punditry.delivery.puppetlabs.net',
          'normal-meddling.delivery.puppetlabs.net',
          'tight-mantrap.delivery.puppetlabs.net', 'unhurt-gadgetry.delivery.puppetlabs.net'
        )
      end

      it 'does not duplicate VMs present in both sources' do
        inventory = described_class.new
        result = inventory.generate

        hostnames_in_result = result['targets'].map { |t| t['uri'] }
        expect(hostnames_in_result.length).to eq(hostnames_in_result.uniq.length)
      end

      it 'correctly groups merged VMs by OS type' do
        inventory = described_class.new
        result = inventory.generate

        windows_group = result['groups'].find { |g| g['name'] == 'windows' }
        expect(windows_group['targets']).to contain_exactly('onetime-algebra.delivery.puppetlabs.net')

        linux_group = result['groups'].find { |g| g['name'] == 'linux' }
        expect(linux_group['targets']).to contain_exactly(
          'tender-punditry.delivery.puppetlabs.net',
          'normal-meddling.delivery.puppetlabs.net',
          'tight-mantrap.delivery.puppetlabs.net',
          'unhurt-gadgetry.delivery.puppetlabs.net'
        )
      end
    end

    describe 'VMs only in vmpooler service' do
      let(:vmpooler_only_json) do
        {
          'tight-mantrap.delivery.puppetlabs.net' => {
            'template' => 'ubuntu-2404-x86_64',
            'fqdn' => 'tight-mantrap.delivery.puppetlabs.net',
            'state' => 'running',
            'lifetime' => 24,
            'running' => 2.0
          }
        }.to_json
      end

      let(:vmpooler_only_nmap) do
        <<~NMAP
          Nmap scan report for tight-mantrap.delivery.puppetlabs.net (10.16.121.14)
          Host is up (0.15s latency).
        NMAP
      end

      before do
        stub_abs_response('{}')
        stub_vmpooler_service_response(vmpooler_only_json)
        allow(Open3).to receive(:capture3)
          .with('nmap', '-Pn', '-p', '22', 'tight-mantrap.delivery.puppetlabs.net')
          .and_return([vmpooler_only_nmap, '', success_status])
      end

      it 'discovers VMs not tracked by ABS' do
        inventory = described_class.new
        result = inventory.generate

        expect(result['targets'].length).to eq(1)
        expect(result['targets'].first['name']).to eq('tight-mantrap.delivery.puppetlabs.net')
        expect(result['targets'].first['vars']['type']).to eq('ubuntu-2404-x86_64')
      end
    end

    describe 'host filtering with nmap' do
      before do
        stub_abs_response(mock_abs_json)
        stub_vmpooler_service_response(mock_vmpooler_service_json)
      end

      context 'when some hosts are unreachable' do
        before do
          allow(Open3).to receive(:capture3)
            .with('nmap', '-Pn', '-p', '22', *hostnames)
            .and_return([mock_nmap_output_partial, mock_nmap_stderr, success_status])
        end

        it 'moves unreachable hosts to the unavailable group' do
          inventory = described_class.new
          result = inventory.generate

          expect(result['targets'].length).to eq(3)

          windows_group = result['groups'].find { |g| g['name'] == 'windows' }
          expect(windows_group['targets']).to eq([])

          linux_group = result['groups'].find { |g| g['name'] == 'linux' }
          expect(linux_group['targets']).to contain_exactly('tender-punditry.delivery.puppetlabs.net',
                                                            'normal-meddling.delivery.puppetlabs.net')

          unavailable_group = result['groups'].find { |g| g['name'] == 'unavailable' }
          expect(unavailable_group['targets']).to contain_exactly('onetime-algebra.delivery.puppetlabs.net')
          expect(unavailable_group['facts']).to eq('role' => 'unavailable')
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
            .and_return(['', mock_nmap_stderr, success_status])
        end

        it 'puts all targets in the unavailable group' do
          inventory = described_class.new
          result = inventory.generate

          expect(result['targets'].length).to eq(3)
          expect(result['groups'].find { |g| g['name'] == 'windows' }['targets']).to eq([])
          expect(result['groups'].find { |g| g['name'] == 'linux' }['targets']).to eq([])

          unavailable_group = result['groups'].find { |g| g['name'] == 'unavailable' }
          expect(unavailable_group['targets']).to contain_exactly(
            'onetime-algebra.delivery.puppetlabs.net',
            'tender-punditry.delivery.puppetlabs.net',
            'normal-meddling.delivery.puppetlabs.net'
          )
        end
      end
    end
  end
end
