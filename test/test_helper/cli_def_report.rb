module TestHelper
  class CliDefReport
    COLUMS = [:full_name, :name, :klass, :parent, :group, :modes,
              :clients, :requirement, :desc]
    class ParamReport
      CliDefReport::COLUMS.each do |col|
        attr_accessor col
      end

      def initialize
        yield self
      end

      def to_csv
        r = ''
        CliDefReport::COLUMS.each do |col|
          r << "\"#{self.send(col).to_s.gsub('"','\'')}\";"
        end
        r.gsub(/;$/,'')
      end
    end

    def self.for(version, **filter)
      new(version, **filter).execute
    end

    DEF_FILER = {clients: nil,
                 modes: nil}

    attr_reader :version
    def initialize(version, **filter)
      @version = Gem::Version.new(version.to_s)
    end

    def to_csv
      r = "#{COLUMS.join(';')}\n"
      rows.each do |row|
        r << row.to_csv
        r << "\n"
      end
      r
    end

    def new_row(p)
      ParamReport.new do |pr|
        pr.full_name = p.full_name
        pr.name = p.full_name
        pr.klass = p.class
        pr.parent = p.parent
        pr.group = p.group
        pr.modes = p.modes
        pr.clients = p.binary_matcher.clients
        pr.requirement = p.binary_matcher.requirement
        pr.desc = p.desc
      end
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

    def execute
      AssLauncher::Enterprise::Cli::CliSpec
        .cli_def.parameters.parameters.each do |p|
        rows << new_row(p) if p.match_version? version
      end
      self
    end
  end
end
