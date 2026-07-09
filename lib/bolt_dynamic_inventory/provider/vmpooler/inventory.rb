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
          alive, unavailable = partition_by_availability(vms)
          generate_inventory(alive, unavailable)
        end

        private

        def load_vms
          unless @refresh
            cached = @cache.read
            return cached if cached && !@cache.any_vm_expired?(cached)
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

        def partition_by_availability(vms)
          return [[], []] if vms.empty?

          hostnames = vms.map { |item| item['hostname'] }
          stdout, stderr, status = Open3.capture3('nmap', '-Pn', '-p', '22', *hostnames)

          print_and_abort('nmap failed', stderr, status) unless status.success?

          active_hostnames = stdout.lines
                                   .grep(/^Nmap scan report for/)
                                   .map { |line| line.match(/^Nmap scan report for (\S+)/)[1] }
                                   .to_set

          alive = vms.select { |vm| active_hostnames.include?(vm['hostname']) }
          unavailable = vms.reject { |vm| active_hostnames.include?(vm['hostname']) }
          [alive, unavailable]
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

          now = Time.now
          data.map do |short_name, vm_info|
            vm = {
              'hostname' => vm_info['fqdn'] || "#{short_name}.delivery.puppetlabs.net",
              'type' => vm_info['template']
            }
            lifetime = vm_info['lifetime']
            running = vm_info['running']
            if lifetime && running
              remaining_hours = lifetime.to_f - running.to_f
              reap_time = now + (remaining_hours * 3600)
              vm['ttl'] = reap_time.strftime('%Y-%m-%d %H:%M')
            end
            vm
          end
        end

        def merge_vm_lists(abs_vms, vmpooler_vms)
          vmpooler_by_host = vmpooler_vms.each_with_object({}) { |vm, h| h[vm['hostname']] = vm }

          merged = abs_vms.map do |abs_vm|
            vmpooler_vm = vmpooler_by_host.delete(abs_vm['hostname'])
            if vmpooler_vm && vmpooler_vm['ttl']
              abs_vm.merge('ttl' => vmpooler_vm['ttl'])
            else
              abs_vm
            end
          end

          merged.concat(vmpooler_by_host.values)
        end

        def generate_inventory(alive_vms, unavailable_vms)
          targets = extract_targets(alive_vms + unavailable_vms)
          alive_names = alive_vms.map { |vm| vm['hostname'].split('.').first }
          unavailable_names = unavailable_vms.map { |vm| vm['hostname'].split('.').first }

          alive_targets = targets.select { |t| alive_names.include?(t['name']) }
          windows_targets, linux_targets = partition_targets_by_type(alive_targets)

          groups = base_groups(windows_targets, linux_targets)
          groups << unavailable_group(unavailable_names) unless unavailable_names.empty?
          groups.concat(regex_groups(alive_names))

          {
            'targets' => targets,
            'groups' => groups
          }
        end

        def extract_targets(vms)
          vms.map do |vm|
            vars = { 'type' => vm['type'] }
            vars['ttl'] = vm['ttl'] if vm['ttl']
            {
              'name' => vm['hostname'].split('.').first,
              'uri' => vm['hostname'],
              'vars' => vars
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

        def unavailable_group(targets)
          {
            'name' => 'unavailable',
            'facts' => { 'role' => 'unavailable' },
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
