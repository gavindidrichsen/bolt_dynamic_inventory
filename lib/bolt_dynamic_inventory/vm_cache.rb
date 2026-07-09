# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

module BoltDynamicInventory
  # TTL-based file cache for provider VM data.
  class VmCache
    DEFAULT_TTL_SECONDS = 86_400 # 24 hours
    BASE_DIR = File.join(Dir.home, '.config', 'bolt_dynamic_inventory')

    def initialize(provider:, ttl: DEFAULT_TTL_SECONDS)
      @provider = provider
      @ttl = ttl
      @provider_dir = File.join(BASE_DIR, provider)
    end

    def read
      return nil unless File.exist?(cache_path)

      data = JSON.parse(File.read(cache_path))
      expires_at = Time.parse(data['expires_at'])
      return nil if Time.now >= expires_at

      data['vms']
    rescue JSON::ParserError, TypeError, ArgumentError
      nil
    end

    def write(vms)
      FileUtils.mkdir_p(@provider_dir)
      now = Time.now
      effective_ttl = effective_ttl_for(vms, now)
      expires_at = now + effective_ttl
      payload = {
        'stored_at' => now.iso8601,
        'expires_at' => expires_at.iso8601,
        'expires_in' => humanize_duration(effective_ttl),
        'provider' => @provider,
        'vms' => vms
      }
      File.write(cache_path, JSON.pretty_generate(payload))
    end

    def write_inventory(inventory_data)
      FileUtils.mkdir_p(@provider_dir)
      header = inventory_header
      File.write(inventory_path, header + inventory_data.to_yaml)
    end

    def inventory_path
      File.join(@provider_dir, 'inventory.yaml')
    end

    def clear
      FileUtils.rm_f(cache_path)
    end

    def any_vm_expired?(vms)
      now = Time.now
      vms.any? do |vm|
        next false unless vm['ttl']

        reap_time = Time.parse(vm['ttl'])
        reap_time <= now
      end
    rescue ArgumentError
      false
    end

    def stale?
      !fresh?
    end

    def fresh?
      return false unless File.exist?(cache_path)

      data = JSON.parse(File.read(cache_path))
      expires_at = Time.parse(data['expires_at'])
      Time.now < expires_at
    rescue JSON::ParserError, TypeError, ArgumentError
      false
    end

    private

    def humanize_duration(seconds)
      seconds = seconds.to_i
      hours, remainder = seconds.divmod(3600)
      minutes = remainder / 60
      parts = []
      parts << "#{hours} hour#{'s' unless hours == 1}" if hours > 0
      parts << "#{minutes} minute#{'s' unless minutes == 1}" if minutes > 0
      parts.empty? ? '0 minutes' : parts.join(', ')
    end

    def inventory_header
      return '' unless File.exist?(cache_path)

      data = JSON.parse(File.read(cache_path))
      stored = data['stored_at']
      expires = data['expires_at']
      "# created: #{stored}\n# expires: #{expires}\n"
    rescue JSON::ParserError, TypeError
      ''
    end

    def effective_ttl_for(vms, now)
      earliest_reap = earliest_vm_reap_time(vms)
      return @ttl unless earliest_reap

      vm_remaining = (earliest_reap - now).to_i
      return @ttl if vm_remaining <= 0

      [vm_remaining, @ttl].min
    end

    def earliest_vm_reap_time(vms)
      reap_times = vms.filter_map do |vm|
        Time.parse(vm['ttl']) if vm['ttl']
      rescue ArgumentError
        nil
      end
      reap_times.min
    end

    def cache_path
      File.join(@provider_dir, 'cache.json')
    end
  end
end
