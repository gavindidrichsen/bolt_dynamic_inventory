# frozen_string_literal: true

require 'bolt_dynamic_inventory/version'
require 'bolt_dynamic_inventory/provider/orbstack/inventory'
require 'bolt_dynamic_inventory/provider/vmpooler/inventory'

module BoltDynamicInventory
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
