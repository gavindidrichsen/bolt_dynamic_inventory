#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require_relative '../lib/orbstack_bolt_inventory/inventory'

params = JSON.parse(STDIN.read)                                 # Read the input from Bolt
group_patterns = params['group_patterns']

inventory = OrbstackBoltInventory::Inventory.new({ 'group_patterns' => group_patterns })

# Generate the inventory and output the result
begin
  # Wrap the inventory result in a 'value' key as expected by Bolt
  result = { 'value' => inventory.generate }
  puts result.to_json
rescue StandardError => e
  STDERR.puts({ _error: { msg: e.message, kind: 'bolt/plugin-error' } }.to_json)
  exit 1
end