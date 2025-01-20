# frozen_string_literal: true

require 'orbstack_bolt_inventory/version'
require 'orbstack_bolt_inventory/inventory'

module OrbstackBoltInventory
  class Error < StandardError; end

  # Convenience method to create a new inventory instance
  def self.new(config = {})
    Inventory.new(config)
  end
end
# require_relative 'orbstack_inventory'
