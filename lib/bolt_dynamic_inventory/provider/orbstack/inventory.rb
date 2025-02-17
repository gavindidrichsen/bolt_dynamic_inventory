# frozen_string_literal: true

require 'json'
require 'yaml'

module BoltDynamicInventory
  module Provider
    module Orbstack
      # Class for generating Bolt inventory from Orbstack VMs
      # Handles VM discovery and inventory file generation with group pattern support
      class Inventory
        def initialize(config = {})
          @group_patterns = parse_group_patterns(config['group_patterns'])
        end

        # Generate a Bolt inventory structure from Orbstack VMs
        def generate
          orbs = fetch_orbstack_vms
          generate_inventory(orbs)
        end

        # Fetch Orbstack VM details using the CLI
        def fetch_orbstack_vms
          JSON.parse(`orb list --format json`)
        end

        # Generate the Bolt inventory structure
        def generate_inventory(orbs)
          inventory = {
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
          inventory['groups'] = groups unless groups.empty?

          inventory
        end

        private

        def parse_group_patterns(patterns)
          return [] unless patterns

          patterns.map do |pattern|
            {
              group: pattern['group'],
              regex: Regexp.new(pattern['pattern'] || pattern['regex'])
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
            matching_targets = target_names.grep(pattern[:regex])
            next if matching_targets.empty?

            groups << {
              'name' => pattern[:group],
              'facts' => { 'role' => pattern[:group] },
              'targets' => matching_targets
            }
          end
        end
      end
    end
  end
end
