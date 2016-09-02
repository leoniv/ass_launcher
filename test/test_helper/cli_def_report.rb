require 'ass_launcher'
module TestHelper
  class CliDefReport
    module Cmd
      require 'clamp'
      class AbstractCommand < Clamp::Command
        option ['-v', '--version'], 'VERSION',
          'specific 1C:Enterprise version'
      end

      class Report < AbstractCommand
        option '--clients', 'CLIENTS ...', 'specific clients' do |s|
          s.split.map(&:to_sym).map(&:downcase)
        end

        option '--modes', 'MODES ...', 'specific run modes' do |s|
          s.split.map(&:to_sym).map(&:downcase)
        end

        option ['-c', '--columns'], 'COLUMNS ...',
          'specific report columns' do |s|
          s.split.map(&:to_sym).map(&:downcase)
        end

        option ['-a', '--show-appiared-only'], :flag,
          'show parameters which appiared in --version only'

        def execute
          $stdout.puts TestHelper::CliDefReport
            .for(version, clients: clients, modes: modes,
                 appiared_only: show_appiared_only?).to_csv(columns)
        rescue ArgumentError => e
          signal_usage_error e.message
        end
      end
    end

    COLUMS = [:full_name, :parameter, :klass, :parent, :group, :modes,
              :clients, :requirement, :have_value_validator,
              :have_switch_value, :accepted_values,  :desc]
    class ParamReport
      CliDefReport::COLUMS.each do |col|
        attr_accessor col
      end

      def initialize
        yield self
      end

      def to_csv(columns)
        r = ''
        columns.each do |col|
          r << "\"#{self.send(col).to_s.gsub('"','\'')}\";"
        end
        r.gsub(/;$/,'')
      end
    end

    def self.for(version = nil, **filter)
      new(version, **filter).execute
    end

    DEF_FILER = {clients: nil,
                 modes: nil,
                 appiared_only: nil}

    include TestHelper::CliDefValidator

    attr_reader :version
    def initialize(version = nil, **filter)
      @version = version
      @filter = DEF_FILER.merge filter
      validate_modes
      validate_clients
    end

    def version
      Gem::Version.new(@version.to_s) if @version
    end

    def filter(name)
      @filter[name] || instance_eval("valid_#{name}")
    end

    def appiared_only
      @filter[:appiared_only] || false
    end

    def to_csv(columns = nil)
      _columns = columns || COLUMS
      r = "#{_columns.join(';')}\n"
      rows.each do |row|
        r << row.to_csv(_columns)
        r << "\n"
      end
      r
    end

    def clients
      filter(:clients)
    end

    def modes
      filter(:modes)
    end

    def new_row(p)
      ParamReport.new do |pr|
        pr.parameter = p
        pr.full_name = p.full_name
        pr.klass = p.class
        pr.parent = p.parent
        pr.group = p.group
        pr.modes = p.modes
        pr.clients = p.binary_matcher.clients
        pr.requirement = p.binary_matcher.requirement
        pr.have_value_validator = !p.options[:value_validator].nil?
        pr.have_switch_value = !p.options[:switch_value].nil?
        pr.accepted_values = accepted_values_get(p)
        pr.desc = p.desc
      end
    end

    def accepted_values_get(p)
      xxx_list_keys(:switch ,p) + xxx_list_keys(:chose, p)
    end

    def xxx_list_keys(list, p)
      list = p.send("#{list}_list".to_sym)
      return list.keys if list
      []
    end

    def write(file, format = :csv)
      fail "Fiele #{file} exists. Use #write!" if File.exists?(file)
      write!(file, format)
    end

    def write!(file, format = :csv)
      f = File.new(file, 'w')
      f.write send("to_#{format}".to_sym)
      f.close
    end

    def rows
      @rows ||= []
    end

    def not_filtred?(p)
      clients?(p) && modes?(p)
    end

    def clients?(p)
      (p.binary_matcher.clients & filter(:clients)).size > 0
    end

    def modes?(p)
      (p.modes & filter(:modes)).size > 0
    end

    def execute
      AssLauncher::Enterprise::Cli::CliSpec
        .cli_def.parameters.parameters.each do |p|
        rows << new_row(p) if match_version?(p) && not_filtred?(p)
      end
      self
    end

    def match_version?(p)
      return true if version.nil?
      if appiared_only
        p.binary_matcher.requirement.to_s =~ /^>=\s*#{version}/
      else
        p.match_version?(version) unless appiared_only
      end
    end
  end
end
