# frozen_string_literal: true

require 'English'
require 'json'
require 'yaml'

module BoltDynamicInventory
  module Provider
    module Vmpooler
      # Class for generating Bolt inventory from VMPooler VMs
      # Handles VM discovery and inventory file generation with group pattern support
      class Inventory
        def initialize(config = {})
          @group_patterns = parse_group_patterns(config['group_patterns'])
        end

        # Generate a Bolt inventory structure from VMPooler VMs
        def generate
          vms = fetch_vmpooler_vms
          generate_inventory(vms)
        end

        # Fetch VMPooler VM details
        def fetch_vmpooler_vms
          output = `bundle exec floaty list --active --json`
          raise 'Failed to get VM list from floaty' unless $CHILD_STATUS.success?

          # Parse JSON output
          data = JSON.parse(output)

          # Extract VMs that are in 'filled' state and have allocated resources
          data.values.select { |job| job['state'] == 'filled' }.flat_map do |job|
            job['allocated_resources'].map do |resource|
              {
                'hostname' => resource['hostname'],
                'type' => resource['type']
              }
            end
          end
        end

        # Generate the Bolt inventory structure
        def generate_inventory(vms)
          # Extract targets temporarily keeping the 'type' for grouping
          targets_with_type = vms.map do |vm|
            {
              'name' => vm['hostname'].split('.').first,
              'uri' => vm['hostname'],
              'type' => vm['type']
            }
          end

          # group the targets by type, in other worder, either windows or linux
          windows_targets = targets_with_type.select { |t| t['type'].include?('win') }.map { |t| t['name'] }
          linux_targets = targets_with_type.reject { |t| t['type'].include?('win') }.map { |t| t['name'] }

          # now remove the 'type' field; otherwise bolt will complain
          targets = targets_with_type.map { |t| t.except('type') }

          # Start with base groups
          base_groups = [
            {
              'name' => 'windows',
              'config' => {
                'transport' => 'ssh',
                'ssh' => {
                  '_plugin' => 'yaml',
                  'filepath' => '~/.secrets/bolt/windows/ssh/vmpooler/windows_credentials.yaml'
                }
              },
              'facts' => { 'role' => 'windows' },
              'targets' => windows_targets
            },
            {
              'name' => 'linux',
              'config' => {
                'transport' => 'ssh',
                'ssh' => {
                  'native-ssh' => true,
                  'load-config' => true,
                  'login-shell' => 'bash',
                  'tty' => false,
                  'host-key-check' => false,
                  'run-as' => 'root',
                  'user' => 'root'
                }
              },
              'facts' => { 'role' => 'linux' },
              'targets' => linux_targets
            }
          ]

          # Generate regex-based groups
          target_names = targets_with_type.map { |t| t['name'] }
          regex_groups = generate_groups(target_names)

          # Construct inventory with both base and regex groups
          {
            'targets' => targets,
            'groups' => base_groups + regex_groups
          }
        end

        private

        def parse_group_patterns(patterns)
          return [] unless patterns

          patterns.map do |pattern|
            {
              regex: Regexp.new(pattern['pattern'] || pattern['regex']),
              group: pattern['group']
            }
          end
        end

        def generate_targets(vms)
          vms.map do |vm|
            {
              'uri' => vm['name'],
              'name' => vm['name'],
              'config' => {
                'ssh' => {
                  'host' => vm['hostname'] || vm['name']
                }
              }
            }
          end
        end

        def generate_groups(target_names)
          return [] if @group_patterns.empty?

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
