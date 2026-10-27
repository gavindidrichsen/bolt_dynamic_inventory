# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module BoltDynamicInventory
  # Persistent groups: a global groups.yaml layered with a local one (same name: local wins).
  # See docs/adr/0013-persist-vmpooler-groups-in-a-global-and-a-local-groups-yaml.md
  class Groups
    GLOBAL = 'global'

    def initialize(global_path:, local_path: File.join(Dir.pwd, 'groups.yaml'), prompter: nil)
      @global_path = global_path
      @local_path = local_path
      @prompter = prompter || method(:ask_on_terminal)
    end

    # Returns every group to emit: 'global' first, then the layered groups.
    def sync(all_names:, alive_names:, patterns: [], force: false)
      global = read(@global_path)
      local = read(@local_path)
      add_patterns(global, patterns, alive_names, force)
      prune!(global, 'global groups.yaml', all_names)
      pruned_local = prune!(local, 'local groups.yaml', all_names)

      global_group = { 'name' => GLOBAL, 'targets' => all_names.sort }
      persist(global_group, global, local, pruned_local)
      merged = layer(global, local)
      report_unassigned(merged, all_names)
      [global_group] + merged
    end

    private

    def read(path)
      return [] unless File.exist?(path)

      Array(YAML.safe_load_file(path)&.fetch('groups', nil))
    end

    def write(path, groups)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, { 'groups' => groups }.to_yaml)
    end

    # -g creates groups at the global level and never overwrites a name without --force
    def add_patterns(groups, patterns, alive_names, force)
      patterns.each do |pattern|
        existing = groups.find { |g| g['name'] == pattern[:group] }
        if existing && !force
          warn "Group '#{pattern[:group]}' already exists in #{@global_path}; use --force to replace it"
          next
        end
        groups.delete(existing) if existing
        groups << new_group(pattern, alive_names)
      end
    end

    def new_group(pattern, alive_names)
      # patterns match the short name so existing regexes keep working
      targets = alive_names.select { |n| n.split('.').first.match?(pattern[:regex]) }
      { 'name' => pattern[:group], 'pattern' => pattern[:regex].source, 'targets' => targets }
    end

    # Drops targets no longer in 'global' (after asking); returns whether any were dropped
    def prune!(groups, label, all_names)
      return false if all_names.empty?

      stale = groups.to_h { |g| [g['name'], Array(g['targets']) - all_names] }.reject { |_, t| t.empty? }
      return false if stale.empty?

      summary = stale.map { |name, targets| "#{name}: #{targets.join(', ')}" }.join('; ')
      return false unless @prompter.call("#{label} lists targets that no longer exist (#{summary}). Drop them?")

      groups.each { |g| g['targets'] = Array(g['targets']) & all_names }
      true
    end

    def persist(global_group, global, local, pruned_local)
      global_groups = global.reject { |g| g['name'] == GLOBAL }
      write(@global_path, [global_group] + global_groups)
      write(@local_path, local) if pruned_local
    end

    def layer(global, local)
      names = local.map { |g| g['name'] }
      (global.reject { |g| names.include?(g['name']) || g['name'] == GLOBAL } + local).map do |g|
        { 'name' => g['name'], 'targets' => Array(g['targets']), 'facts' => { 'role' => g['name'] } }
      end
    end

    def report_unassigned(groups, all_names)
      return if groups.empty?

      free = all_names - groups.flat_map { |g| g['targets'] }
      warn "Not in any group: #{free.join(', ')}" unless free.empty?
    end

    # Asks only on a terminal; otherwise drops and says so
    def ask_on_terminal(message)
      unless $stdin.tty? && $stderr.tty?
        warn "#{message} (dropped)"
        return true
      end

      warn "#{message} [yN]"
      $stdin.gets.to_s.strip.downcase.start_with?('y')
    end
  end
end
