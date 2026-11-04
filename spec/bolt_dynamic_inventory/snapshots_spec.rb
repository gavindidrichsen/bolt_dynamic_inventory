# frozen_string_literal: true

require 'spec_helper'
require 'bolt_dynamic_inventory/snapshots'
require 'tmpdir'
require 'json'

RSpec.describe BoltDynamicInventory::Snapshots do
  let(:dir) { Dir.mktmpdir }
  let(:path) { File.join(dir, 'snapshots.json') }
  let(:host) { 'tender-ant.delivery.puppetlabs.net' }

  after { FileUtils.remove_entry(dir) }

  def write_ledger(entries)
    File.write(path, JSON.generate(host => entries))
  end

  it 'puts a UTC date on each id and lists the newest last, whatever order vmpooler gave' do
    write_ledger([{ 'id' => 'old', 'at' => 1_793_622_895 }, { 'id' => 'new', 'at' => 1_793_626_512 }])

    expect(described_class.new(path: path).annotate(host, %w[new old]))
      .to eq(%w[old:2026-11-02T12:34:55Z new:2026-11-02T13:35:12Z])
  end

  it 'lists ids the ledger does not know first, as unknown' do
    write_ledger([{ 'id' => 'known', 'at' => 1_793_622_895 }])

    expect(described_class.new(path: path).annotate(host, %w[known mystery]))
      .to eq(%w[mystery:unknown known:2026-11-02T12:34:55Z])
  end

  it 'marks every id unknown when there is no ledger or it cannot be read' do
    expect(described_class.new(path: path).annotate(host, %w[a b])).to eq(%w[a:unknown b:unknown])

    File.write(path, 'not json')
    expect(described_class.new(path: path).annotate(host, %w[a])).to eq(%w[a:unknown])
  end
end
