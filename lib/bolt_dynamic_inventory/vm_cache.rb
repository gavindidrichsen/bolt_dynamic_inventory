# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'

module BoltDynamicInventory
  # TTL-based file cache for provider VM data.
  class VmCache
    DEFAULT_TTL_SECONDS = 86_400 # 24 hours
    CACHE_DIR = File.join(Dir.home, '.config', 'bolt_dynamic_inventory', 'cache')

    def initialize(provider:, ttl: DEFAULT_TTL_SECONDS)
      @provider = provider
      @ttl = ttl
      @cache_dir = CACHE_DIR
    end

    def read
      return nil unless File.exist?(cache_path)

      data = JSON.parse(File.read(cache_path))
      stored_at = Time.parse(data['stored_at'])
      return nil if Time.now - stored_at > @ttl

      data['vms']
    rescue JSON::ParserError, TypeError, ArgumentError
      nil
    end

    def write(vms)
      FileUtils.mkdir_p(@cache_dir)
      payload = {
        'stored_at' => Time.now.iso8601,
        'provider' => @provider,
        'ttl_seconds' => @ttl,
        'vms' => vms
      }
      File.write(cache_path, JSON.pretty_generate(payload))
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
      stored_at = Time.parse(data['stored_at'])
      Time.now - stored_at <= @ttl
    rescue JSON::ParserError, TypeError, ArgumentError
      false
    end

    private

    def cache_path
      File.join(@cache_dir, "#{@provider}_vms.json")
    end
  end
end
