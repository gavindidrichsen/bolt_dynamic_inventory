# frozen_string_literal: true

require 'spec_helper'
require 'orbstack_bolt_inventory'

RSpec.describe OrbstackBoltInventory::Inventory do
  let(:mock_orbs) do
    [
      { 'name' => 'agent01', 'status' => 'running' },
      { 'name' => 'agent02', 'status' => 'running' },
      { 'name' => 'compiler01', 'status' => 'running' },
      { 'name' => 'webserver01', 'status' => 'running' }
    ]
  end

  before(:each) do
    # Mock the orb list command
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
      expect(result).not_to have_key('groups')
    end
  end

  context 'inventory with matching group patterns' do
    let(:group_patterns) do
      {
        'group_patterns' => [
          { 'group' => 'agents', 'regex' => '^agent' },
          { 'group' => 'compilers', 'regex' => '^compiler' }
        ]
      }
    end
    let(:inventory) { described_class.new(group_patterns) }

    it 'generates inventory with both groups' do
      result = inventory.generate

      expect(result['groups'].length).to eq(2)

      agents_group = result['groups'].find { |g| g['name'] == 'agents' }
      expect(agents_group['targets']).to contain_exactly('agent01', 'agent02')

      compilers_group = result['groups'].find { |g| g['name'] == 'compilers' }
      expect(compilers_group['targets']).to contain_exactly('compiler01')
    end
  end

  context 'inventory with partially matching group patterns' do
    let(:group_patterns) do
      {
        'group_patterns' => [
          { 'group' => 'agents', 'regex' => '^agent' },
          { 'group' => 'databases', 'regex' => '^db' } # Won't match any targets
        ]
      }
    end
    let(:inventory) { described_class.new(group_patterns) }

    it 'generates inventory with only matching groups' do
      result = inventory.generate

      expect(result['groups'].length).to eq(1)

      agents_group = result['groups'].find { |g| g['name'] == 'agents' }
      expect(agents_group['targets']).to contain_exactly('agent01', 'agent02')

      expect(result['groups'].none? { |g| g['name'] == 'databases' }).to be true
    end
  end

  context 'ssh configuration' do
    let(:inventory) { described_class.new }

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
end
