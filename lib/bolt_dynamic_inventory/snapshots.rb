# frozen_string_literal: true

require 'json'

module BoltDynamicInventory
  # Puts a date on each vmpooler snapshot id, from the floatys ledger, so the newest is the last in the list.
  # vmpooler lists ids only, in no reliable order, so the dates are the ledger's
  # (when floatys made, or first saw, the id).
  # See docs/adr/0015-list-vmpooler-snapshots-as-id-and-date-newest-last.md
  class Snapshots
    LEDGER = File.join(Dir.home, '.config', 'floaty', 'snapshots.json')
    UNKNOWN = 'unknown'

    def initialize(path: LEDGER)
      @path = path
    end

    # ['id:2026-11-02T12:59:39Z', ...] oldest first; an id the ledger does not know is 'id:unknown' and sorts first
    def annotate(host, ids)
      times = ledger.fetch(host, []).to_h { |entry| [entry['id'], entry['at']] }
      unknown, known = ids.partition { |id| times[id].nil? }
      (unknown + known.sort_by { |id| times[id] }).map { |id| "#{id}:#{stamp(times[id])}" }
    end

    private

    def stamp(epoch)
      epoch ? Time.at(epoch).utc.strftime('%Y-%m-%dT%H:%M:%SZ') : UNKNOWN
    end

    def ledger
      @ledger ||= File.exist?(@path) ? JSON.parse(File.read(@path)) : {}
    rescue JSON::ParserError
      {}
    end
  end
end
