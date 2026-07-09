# frozen_string_literal: true

require 'English'
require 'json'
require 'open3'
require 'set'
require 'yaml'
require 'bolt_dynamic_inventory/vm_cache'

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
            'copy-command' => ['scp', '-r', '-O'],
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
          @refresh = config['refresh'] || false
          @cache = VmCache.new(provider: 'vmpooler')
        end

        def generate
          vms = load_vms
          vms = filter_alive_hosts(vms)
          generate_inventory(vms)
        end

        private

        def load_vms
          unless @refresh
            cached = @cache.read
            return cached if cached
          end

          vms = fetch_vmpooler_vms
          @cache.write(vms)
          vms
        end

        def print_and_abort(message, stderr, status)
          error_msg = "#{message} with exit code #{status.exitstatus}"
          error_msg += ": #{stderr.strip}" unless stderr.empty?
          raise error_msg
        end

        def filter_alive_hosts(vms)
          return vms if vms.empty?

          hostnames = vms.map { |item| item['hostname'] }
          # Use -Pn to skip ping and check SSH port 22
          # This works for both Linux and Windows hosts in modern environments
          stdout, stderr, status = Open3.capture3('nmap', '-Pn', '-p', '22', *hostnames)

          print_and_abort('nmap failed', stderr, status) unless status.success?

          # Extract hostnames from "Host is up" entries
          active_hostnames = stdout.lines
                                   .grep(/^Nmap scan report for/)
                                   .map { |line| line.match(/^Nmap scan report for (\S+)/)[1] }

          return [] if active_hostnames.empty?

          vms.select { |vm| active_hostnames.include?(vm['hostname']) }
        end

        # Fetch VMPooler VM details from both ABS and vmpooler services
        def fetch_vmpooler_vms
          abs_vms = fetch_abs_vms
          vmpooler_vms = fetch_vmpooler_service_vms
          merge_vm_lists(abs_vms, vmpooler_vms)
        end

        def fetch_abs_vms
          stdout, stderr, status = Open3.capture3('floaty', 'list', '--active', '--json')
          print_and_abort('Failed to get VM list from floaty', stderr, status) unless status.success?

          return [] if stdout.strip.empty?

          data = JSON.parse(stdout)
          return [] if data.nil? || data.empty?

          data.values.select { |job| %w[filled allocated].include?(job['state']) }.flat_map do |job|
            job['allocated_resources'].map do |resource|
              {
                'hostname' => resource['hostname'],
                'type' => resource['type']
              }
            end
          end
        end

        def fetch_vmpooler_service_vms
          stdout, stderr, status = Open3.capture3('floaty', 'list', '--active', '--json', '--service', 'vmpooler')
          print_and_abort('Failed to get VM list from vmpooler service', stderr, status) unless status.success?

          return [] if stdout.strip.empty?

          data = JSON.parse(stdout)
          return [] if data.nil? || data.empty?

          data.map do |_short_name, vm_info|
            {
              'hostname' => vm_info['fqdn'] || "#{_short_name}.delivery.puppetlabs.net",
              'type' => vm_info['template']
            }
          end
        end

        def merge_vm_lists(abs_vms, vmpooler_vms)
          seen = abs_vms.map { |vm| vm['hostname'] }.to_set
          merged = abs_vms.dup
          vmpooler_vms.each do |vm|
            merged << vm unless seen.include?(vm['hostname'])
          end
          merged
        end

        # Generate the Bolt inventory structure
        def generate_inventory(vms)
          targets = extract_targets_with_type(vms)
          target_names = targets.map { |t| t['name'] }
          windows_targets, linux_targets = partition_targets_by_type(targets)

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
              'vars' => {
                'type' => vm['type']
              }
            }
          end
        end

        def partition_targets_by_type(targets_with_type)
          windows = targets_with_type.select { |t| t['vars']['type'].include?('win') }.map { |t| t['name'] }
          linux = targets_with_type.reject { |t| t['vars']['type'].include?('win') }.map { |t| t['name'] }
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
