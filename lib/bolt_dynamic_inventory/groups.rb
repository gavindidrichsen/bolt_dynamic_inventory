# frozen_string_literal: true

require 'fileutils'
require 'yaml'

module BoltDynamicInventory
  # Persistent groups in one global groups.yaml that inventory.yaml loads with Bolt's yaml plugin.
  # See docs/adr/0013-persist-vmpooler-groups-in-a-global-groups-yaml-loaded-by-bolt.md
  class Groups
    GLOBAL = 'global'
    RESERVED = %w[windows linux unavailable].freeze

    def initialize(path:, prompter: nil)
      @path = path
      @prompter = prompter || method(:ask_on_terminal)
    end

    # Rewrites the groups file for the current VMs; it always exists afterwards, as the yaml plugin needs it
    def sync(all_names:, alive_names:, patterns: [], force: false)
      groups = read
      add_patterns(groups, patterns, alive_names, force)
      prune!(groups, all_names)
      write([{ 'name' => GLOBAL, 'targets' => all_names.sort }] + groups)
      report_unassigned(groups, all_names)
    end

    # The inventory group entry that makes Bolt load the file
    def plugin_entry
      { '_plugin' => 'yaml', 'filepath' => @path.sub(Dir.home, '~') }
    end

    private

    def read
      return [] unless File.exist?(@path)

      Array(YAML.safe_load_file(@path)&.fetch('groups', nil)).reject { |g| g['name'] == GLOBAL }
    end

    def write(groups)
      FileUtils.mkdir_p(File.dirname(@path))
      File.write(@path, "#{header(groups)}#{{ 'groups' => groups }.to_yaml}")
    end

    # The comment is rebuilt from each group's pattern on every write, so it matches hand edits
    def header(groups)
      args = groups.filter_map { |g| "#{g['name']}:#{g['pattern']}" if g['pattern'] }.join(',')
      lines = ['# Recreate these groups (global is always kept, never part of -g):',
               "#   binvv --refresh -g \"#{args.gsub(/[\\"$`]/) { |c| "\\#{c}" }}\""]
      manual = groups.reject { |g| g['pattern'] || g['name'] == GLOBAL }.map { |g| g['name'] }
      lines << "# Without a pattern (kept by hand): #{manual.join(', ')}" unless manual.empty?
      "#{lines.join("\n")}\n"
    end

    # -g creates groups here and never overwrites a name without --force
    def add_patterns(groups, patterns, alive_names, force)
      patterns.each do |pattern|
        name = pattern[:group]
        existing = groups.find { |g| g['name'] == name }
        next warn("Group '#{name}' is reserved; choose another name") if RESERVED.include?(name) || name == GLOBAL
        next warn("Group '#{name}' already exists in #{@path}; use --force to replace it") if existing && !force

        groups.delete(existing) if existing
        groups << new_group(pattern, alive_names)
      end
    end

    def new_group(pattern, alive_names)
      # patterns match the short name so existing regexes keep working
      targets = alive_names.select { |n| n.split('.').first.match?(pattern[:regex]) }
      { 'name' => pattern[:group], 'pattern' => pattern[:regex].source, 'targets' => targets,
        'facts' => { 'role' => pattern[:group] } }
    end

    # Drops targets no longer in 'global' (after asking); empty groups are kept
    def prune!(groups, all_names)
      return if all_names.empty?

      stale = groups.to_h { |g| [g['name'], Array(g['targets']) - all_names] }.reject { |_, t| t.empty? }
      return if stale.empty?

      summary = stale.map { |name, targets| "#{name}: #{targets.join(', ')}" }.join('; ')
      return unless @prompter.call("#{@path} lists targets that no longer exist (#{summary}). Drop them?")

      groups.each { |g| g['targets'] = Array(g['targets']) & all_names }
    end

    def report_unassigned(groups, all_names)
      return if groups.empty?

      free = all_names - groups.flat_map { |g| Array(g['targets']) }
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
