# frozen_string_literal: true

require 'spec_helper'
require 'bolt_dynamic_inventory/vm_cache'
require 'tmpdir'
require 'json'

RSpec.describe BoltDynamicInventory::VmCache do
  let(:tmpdir) { Dir.mktmpdir }
  let(:cache) { described_class.new(provider: 'test') }

  before do
    stub_const('BoltDynamicInventory::VmCache::BASE_DIR', tmpdir)
  end

  after do
    FileUtils.remove_entry(tmpdir)
  end

  describe '#write' do
    it 'includes an expires_at field in the cache file' do
      cache.write([{ 'hostname' => 'a.example.com', 'type' => 'ubuntu' }])
      data = JSON.parse(File.read(File.join(tmpdir, 'test', 'cache.json')))

      expect(data).to have_key('expires_at')
      expect(Time.parse(data['expires_at'])).to be > Time.now
    end

    it 'caps expiry at the shortest-lived VM when shorter than default' do
      now = Time.now
      short_lived_reap = now + 3600
      vms = [
        { 'hostname' => 'a.example.com', 'type' => 'ubuntu', 'ttl' => short_lived_reap.strftime('%Y-%m-%d %H:%M') },
        { 'hostname' => 'b.example.com', 'type' => 'ubuntu', 'ttl' => (now + 86_400).strftime('%Y-%m-%d %H:%M') }
      ]

      cache.write(vms)
      data = JSON.parse(File.read(File.join(tmpdir, 'test', 'cache.json')))

      expect(data).to have_key('expires_in')
      expect(data).not_to have_key('ttl_seconds')
      expires_at = Time.parse(data['expires_at'])
      expect(expires_at).to be_within(60).of(short_lived_reap)
    end

    it 'uses default TTL when no VMs have a ttl field' do
      vms = [
        { 'hostname' => 'a.example.com', 'type' => 'ubuntu' },
        { 'hostname' => 'b.example.com', 'type' => 'ubuntu' }
      ]

      cache.write(vms)
      data = JSON.parse(File.read(File.join(tmpdir, 'test', 'cache.json')))

      expect(data['expires_in']).to eq('24 hours')
    end

    it 'uses default TTL when shortest VM TTL exceeds default' do
      now = Time.now
      vms = [
        { 'hostname' => 'a.example.com', 'type' => 'ubuntu', 'ttl' => (now + 100_000).strftime('%Y-%m-%d %H:%M') }
      ]

      cache.write(vms)
      data = JSON.parse(File.read(File.join(tmpdir, 'test', 'cache.json')))

      expect(data['expires_in']).to eq('24 hours')
    end

    it 'uses default TTL when VM ttl is already expired' do
      past = Time.now - 3600
      vms = [
        { 'hostname' => 'a.example.com', 'type' => 'ubuntu', 'ttl' => past.strftime('%Y-%m-%d %H:%M') }
      ]

      cache.write(vms)
      data = JSON.parse(File.read(File.join(tmpdir, 'test', 'cache.json')))

      expect(data['expires_in']).to eq('24 hours')
    end
  end

  describe '#write_inventory' do
    it 'prepends created and expires comments from cache metadata' do
      cache.write([{ 'hostname' => 'a.example.com', 'type' => 'ubuntu' }])
      inventory_data = { 'targets' => [], 'groups' => [] }
      cache.write_inventory(inventory_data)

      content = File.read(cache.inventory_path)
      expect(content).to match(/^# created: \d{4}-\d{2}-\d{2}/)
      expect(content).to match(/^# expires: \d{4}-\d{2}-\d{2}/)
    end
  end

  describe '#read' do
    it 'returns vms when cache has not expired' do
      vms = [{ 'hostname' => 'a.example.com', 'type' => 'ubuntu' }]
      cache.write(vms)

      expect(cache.read).to eq(vms)
    end

    it 'returns nil when cache has expired' do
      FileUtils.mkdir_p(File.join(tmpdir, 'test'))
      payload = {
        'stored_at' => (Time.now - 200).iso8601,
        'expires_at' => (Time.now - 100).iso8601,
        'provider' => 'test',
        'expires_in' => '1 minute, 40 seconds',
        'vms' => [{ 'hostname' => 'a.example.com', 'type' => 'ubuntu' }]
      }
      File.write(File.join(tmpdir, 'test', 'cache.json'), JSON.pretty_generate(payload))

      expect(cache.read).to be_nil
    end

    it 'returns nil for old-format cache files without expires_at' do
      FileUtils.mkdir_p(File.join(tmpdir, 'test'))
      payload = {
        'stored_at' => Time.now.iso8601,
        'provider' => 'test',
        'expires_in' => '24 hours',
        'vms' => [{ 'hostname' => 'a.example.com', 'type' => 'ubuntu' }]
      }
      File.write(File.join(tmpdir, 'test', 'cache.json'), JSON.pretty_generate(payload))

      expect(cache.read).to be_nil
    end
  end

  describe '#fresh?' do
    it 'returns true when cache has not expired' do
      cache.write([{ 'hostname' => 'a.example.com', 'type' => 'ubuntu' }])
      expect(cache.fresh?).to be true
    end

    it 'returns false when cache has expired' do
      FileUtils.mkdir_p(File.join(tmpdir, 'test'))
      payload = {
        'stored_at' => (Time.now - 200).iso8601,
        'expires_at' => (Time.now - 100).iso8601,
        'provider' => 'test',
        'expires_in' => '1 minute, 40 seconds',
        'vms' => []
      }
      File.write(File.join(tmpdir, 'test', 'cache.json'), JSON.pretty_generate(payload))

      expect(cache.fresh?).to be false
    end

    it 'returns false for old-format cache files' do
      FileUtils.mkdir_p(File.join(tmpdir, 'test'))
      payload = {
        'stored_at' => Time.now.iso8601,
        'provider' => 'test',
        'expires_in' => '24 hours',
        'vms' => []
      }
      File.write(File.join(tmpdir, 'test', 'cache.json'), JSON.pretty_generate(payload))

      expect(cache.fresh?).to be false
    end
  end
end
