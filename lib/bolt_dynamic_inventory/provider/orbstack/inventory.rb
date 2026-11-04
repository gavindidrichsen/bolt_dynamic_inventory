# frozen_string_literal: true

require 'json'
require 'yaml'
require 'bolt_dynamic_inventory/vm_cache'
require 'bolt_dynamic_inventory/groups'

module BoltDynamicInventory
  module Provider
    module Orbstack
      # Class for generating Bolt inventory from Orbstack VMs
      # Handles VM discovery and inventory file generation with group pattern support
      class Inventory
        CONFIG = {
          'transport' => 'ssh',
          'ssh' => {
            'native-ssh' => true,
            'copy-command' => ['scp', '-r', '-O'],
            'load-config' => true,
            'login-shell' => 'bash',
            'tty' => false,
            'host-key-check' => false,
            'run-as' => 'root',
            'user' => 'root',
            'port' => 32_222
          }
        }.freeze

        def initialize(config = {})
          @group_patterns = parse_group_patterns(config['group_patterns'])
          @force = config['force'] || false
          @cache = VmCache.new(provider: 'orbstack')
          @groups = Groups.new(path: @cache.groups_path)
        end

        # Generate a Bolt inventory structure from Orbstack VMs and persist it, as the vmpooler provider does,
        # so `binv --path` can name a file that Bolt reads (its groups come from the provider's groups.yaml)
        def generate
          orbs = fetch_orbstack_vms
          inventory_data = generate_inventory(orbs)
          @cache.write_inventory(inventory_data)
          inventory_data
        end

        # Fetch Orbstack VM details using the CLI
        def fetch_orbstack_vms
          JSON.parse(`orb list --format json`)
        end

        # Generate the Bolt inventory structure
        def generate_inventory(orbs)
          inventory = { 'config' => CONFIG, 'targets' => generate_targets(orbs) }

          # the groups file must exist before Bolt loads it, so it is written before the inventory
          names = orbs.map { |orb| orb['name'] }.sort
          @groups.sync(all_names: names, alive_names: names, patterns: @group_patterns, force: @force)
          inventory['groups'] = [@groups.plugin_entry]

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
          targets = orbs.map do |orb|
            {
              'name' => orb['name'],
              'uri' => "#{orb['name']}@orb"
            }
          end
          targets.sort_by { |t| t['name'] }
        end
      end
    end
  end
end
