#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../lib/bolt_dynamic_inventory/provider/orbstack/inventory'
require_relative '../lib/bolt_dynamic_inventory/provider/vmpooler/inventory'

params = JSON.parse($stdin.read) # Read the input from Bolt
group_patterns = params['group_patterns']
provider = params['provider'] || 'orbstack' # Default to orbstack if not specified

# Create inventory based on provider type
inventory = case provider
            when 'orbstack'
              BoltDynamicInventory::Provider::Orbstack::Inventory.new({ 'group_patterns' => group_patterns })
            when 'vmpooler'
              BoltDynamicInventory::Provider::Vmpooler::Inventory.new({ 'group_patterns' => group_patterns })
            else
              raise "Unknown provider type: #{provider}. Supported types: orbstack, vmpooler"
            end

# Generate the inventory and output the result
begin
  # Wrap the inventory result in a 'value' key as expected by Bolt
  result = { 'value' => inventory.generate }
  puts result.to_json
rescue StandardError => e
  warn({ _error: { msg: e.message, kind: 'bolt/plugin-error' } }.to_json)
  exit 1
end
