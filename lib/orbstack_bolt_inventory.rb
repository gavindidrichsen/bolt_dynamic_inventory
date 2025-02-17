# frozen_string_literal: true

require 'orbstack_bolt_inventory/version'
require 'orbstack_bolt_inventory/provider/orbstack/inventory'
require 'orbstack_bolt_inventory/provider/vmpooler/inventory'

module OrbstackBoltInventory
  class Error < StandardError; end

  # Convenience method to create a new inventory instance
  def self.new(config = {})
    provider_type = config['provider'] || 'orbstack'
    provider_class = case provider_type
                    when 'orbstack'
                      Provider::Orbstack::Inventory
                    when 'vmpooler'
                      Provider::Vmpooler::Inventory
                    else
                      raise Error, "Unknown provider type: #{provider_type}. Supported types: orbstack, vmpooler"
                    end
    provider_class.new(config)
  end
end
