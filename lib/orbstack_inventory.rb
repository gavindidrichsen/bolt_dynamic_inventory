#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'yaml'

# Define the OrbstackInventory class here
class OrbstackInventory
  def initialize(config = {})
    @group_patterns = parse_group_patterns(config['group_patterns'])
  end

  # This method is called by Bolt to fetch inventory data
  def resolve_reference(_opts = {})
    orbs = fetch_orbstack_vms
    generate_inventory(orbs)
  end

  # Fetch Orbstack VM details using the CLI
  def fetch_orbstack_vms
    JSON.parse(`orb list --format json`)
  end

  # Generate the Bolt inventory structure
  def generate_inventory(orbs)
    value = {
      'config' => {
        'transport' => 'ssh',
        'ssh' => {
          'native-ssh' => true,
          'load-config' => true,
          'login-shell' => 'bash',
          'tty' => false,
          'host-key-check' => false,
          'run-as' => 'root',
          'user' => 'root',
          'port' => 32_222
        }
      },
      'targets' => generate_targets(orbs)
    }

    groups = generate_groups(orbs)
    value['groups'] = groups unless groups.empty?

    { 'value' => value }
  end

  private

  def parse_group_patterns(patterns)
    return [] unless patterns

    patterns.map do |pattern|
      {
        group: pattern['group'],
        regex: Regexp.new(pattern['regex'])
      }
    end
  end

  def generate_targets(orbs)
    orbs.map do |orb|
      {
        'name' => orb['name'],
        'uri' => "#{orb['name']}@orb"
      }
    end
  end

  def generate_groups(orbs)
    return [] if @group_patterns.empty?

    target_names = orbs.map { |orb| orb['name'] }

    @group_patterns.each_with_object([]) do |pattern, groups|
      matching_targets = target_names.select { |name| name.match?(pattern[:regex]) }
      next if matching_targets.empty?

      groups << {
        'name' => pattern[:group],
        'targets' => matching_targets
      }
    end
  end
end
