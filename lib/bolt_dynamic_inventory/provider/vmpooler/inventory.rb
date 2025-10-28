# frozen_string_literal: true

require 'English'
require 'json'
require 'open3'
require 'yaml'

module BoltDynamicInventory
  module Provider
    module Vmpooler
      # Class for generating Bolt inventory from VMPooler VMs
      # Handles VM discovery and inventory file generation with group pattern support
      class Inventory
        WINDOWS_CONFIG = {
          'transport' => 'winrm',
          'winrm' => {
            'user' => 'Administrator',
            'password' => {
              '_plugin' => 'env_var',
              'var' => 'VMPOOLER_WINDOWS_PASSWORD'
            },
            'ssl' => false
          }
        }.freeze

        LINUX_CONFIG = {
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
        }.freeze

        def initialize(config = {})
          @group_patterns = parse_group_patterns(config['group_patterns'])
        end

        # Generate a Bolt inventory structure from VMPooler VMs
        def generate
          vms = fetch_vmpooler_vms
          vms = filter_alive_hosts(vms)
          generate_inventory(vms)
        end

        private

        def print_and_abort(message, stderr, status)
          error_msg = "#{message}"
          error_msg += ": #{stderr.strip}" unless stderr.empty?
          raise error_msg
        end

        def filter_alive_hosts(vms)
          hostnames = vms.map { |item| item["hostname"] }
          stdout, stderr, status = Open3.capture3('nmap', '-sn', *hostnames)
          
          print_and_abort("nmap failed", stderr) unless status.success?

          active_hostnames = stdout.lines
            .grep(/^Nmap scan report for/)
            .map { |line| line.match(/^Nmap scan report for (\S+)/)[1]}
          
          return [] if active_hostnames.empty?

          vms.select { |vm| active_hostnames.include?(vm["hostname"])}
        end

        # Fetch VMPooler VM details
        def fetch_vmpooler_vms
          output, sterr, status = Open3.capture3('floaty list --active --json')
          print_and_abort("Failed to get VM list from floaty", stderr) unless status.success?

          # Return empty array if output is empty (no VMs)
          return [] if output.strip.empty?

          # Parse JSON output and return empty array if data is nil or empty
          data = JSON.parse(output)
          return [] if data.nil? || data.empty?

          # Extract VMs that are in 'filled' or 'allocated' state and have allocated resources
          result = data.values.select { |job| %w[filled allocated].include?(job['state']) }.flat_map do |job|
            job['allocated_resources'].map do |resource|
              {
                'hostname' => resource['hostname'],
                'type' => resource['type']
              }
            end
          end

          result
        end

        # Generate the Bolt inventory structure
        def generate_inventory(vms)
          targets_with_type = extract_targets_with_type(vms)
          target_names = targets_with_type.map { |t| t['name'] }
          windows_targets, linux_targets = partition_targets_by_type(targets_with_type)
          targets = targets_with_type.map { |t| t.except('type') }

          {
            'targets' => targets,
            'groups' => base_groups(windows_targets, linux_targets) + regex_groups(target_names)
          }
        end

        def extract_targets_with_type(vms)
          vms.map do |vm|
            {
              'name' => vm['hostname'].split('.').first,
              'uri' => vm['hostname'],
              'type' => vm['type']
            }
          end
        end

        def partition_targets_by_type(targets_with_type)
          windows = targets_with_type.select { |t| t['type'].include?('win') }.map { |t| t['name'] }
          linux = targets_with_type.reject { |t| t['type'].include?('win') }.map { |t| t['name'] }
          [windows, linux]
        end

        def base_groups(windows_targets, linux_targets)
          [
            windows_group(windows_targets),
            linux_group(linux_targets)
          ]
        end

        def windows_group(targets)
          {
            'name' => 'windows',
            'config' => WINDOWS_CONFIG,
            'facts' => { 'role' => 'windows' },
            'targets' => targets
          }
        end

        def linux_group(targets)
          {
            'name' => 'linux',
            'config' => LINUX_CONFIG,
            'facts' => { 'role' => 'linux' },
            'targets' => targets
          }
        end

        def regex_groups(target_names)
          @group_patterns.map do |pattern|
            {
              'name' => pattern[:group],
              'targets' => target_names.grep(pattern[:regex]),
              'facts' => { 'role' => pattern[:group] }
            }
          end
        end

        def parse_group_patterns(patterns)
          return [] unless patterns

          patterns.map do |pattern|
            {
              regex: Regexp.new(pattern['pattern'] || pattern['regex']),
              group: pattern['group']
            }
          end
        end
      end
    end
  end
end
