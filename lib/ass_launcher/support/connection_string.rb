module AssLauncher
  module Support
    # Implement 1C connection string
    module ConnectionString
      class Error < StandardError; end
      # Commonn connection string fields
      COMMON_FIELDS = %w(Usr Pwd LicDstr prmod Locale)
      # Fields for server infobase
      SERVER_FIELDS = %w(Srvr Ref)
      # Fields for file infobase
      FILE_FIELDS = %w(File)
      # Fields for infobase published on http server
      HTTP_FIELDS = %w(Ws)
      # Field for make server infobase
      IB_MAKER_FIELDS = %w(DBMS
                           DBSrvr
                           DB
                           DBUID
                           DBPwd
                           SQLYOffs
                           CrSQLDB
                           SchJobDn
                           SUsr
                           SPwd)
      # Values for DBMS field
      DBMS_VALUES = %w(MSSQLServer PostgreSQL IBMDB2 OracleDatabase)

      # Analyzes connect string and build suitable class
      # @param connstr (see parse)
      # @return [Server | File | Http] instanse
      def self.[](connstr)
        case connstr
        when /^File=/i then File.new(prase(connstr))
        when /^Server=/i then Server.new(prase(connstr))
        when /^Ws=/i then Http.new(parse(connstr))
        else
          fail "Uncknown connstr `#{connstr}'"
        end
      end

      # Parse connect string into hash
      # @param connstr [String]
      def self.parse(connstr)
        raise 'FIXME'
      end

      def is
        name.split('::').last.downcase.to_sym
      end

      def is?(symbol)
        is == symbol
      end

      def to_hash
        result = {}
        fields.each do |f|
          result[f.downcase.to_sym] = get_property(f)
        end
      end

      def to_s(only_fields = nil)
        only_fields ||= fields
        result = ''
        only_fields.each do |f|
          result << prop_to_s(f) if get_property(f)
        end
        result
      end

      def required_fields
        self.class.required_fields
      end

      def fields
        self.class.fields
      end

      def self.included(base)
        base.fields.each do |f|
          base.send(:attr_accessor, f.downcase.to_sym)
        end
      end

      private

      def _set_properties(hash)
        hash.each do |key, value|
          set_property(key, value)
        end
      end
      private_method :_set_properties

      def set_property(prop, value)
        send("#{prop.downcase}=".to_sym, value)
      end
      private_method :set_property

      def get_property(prop)
        send(prop.downcase.to_sym)
      end
      private_method :get_property

      def prop_to_s(prop)
        "#{prop}=\"#{get_property.gsub('"', '""')}\""
      end
      private_method :prop_to_s

      def required_fields_passed?(passed_fields)
        (required_fields.map { |f| f.downcase.to_sym }\
          & passed_fields.keys.map { |k| k.downcase.to_sym }) == \
          required_fields.map { |f| f.downcase.to_sym }
      end
      private_method :required_fields_passed?

      # Connection string for server infobases
      class Server
        # Simple class host:port
        class ServerDescr
          attr_reader :host, :port

          def initialize(host, port = nil)
            @host = host
            @port = port
          end

          def self.parse(srv_str)
            r = []
            srv_str.split(',').each do |srv|
              srv.strip
              r << new(srv.chomp.split(':')) unless srv.empty?
            end
            r
          end

          def to_s
            "#{host}:#{port}"
          end
        end

        include ConnectionString

        def initialize(hash)
          fail ConnectionString::Error unless required_fields_passed?(hash)
          _set_properties(hash)
          @servers = ServerDescr.parce(@srvr)
        end

        def self.required_fields
          SERVER_FIELDS
        end

        # @return [Array<ServerDescr>]
        def servers
          @servers ||= []
        end

        def srvr=(str)
          @srvers = ServerDescr.parce(str)
          @srvr = str
        end

        def srvr
          servers.join(',')
        end

        def srvr_raw
          @srvr
        end

        def self.fields
          required_fields | COMMON_FIELDS | IB_MAKER_FIELDS
        end

        # (see DBMS_VALUES)
        def dbms=(value)
          fail ArgumentError, "Bad value #{value}" unless\
            DBMS_VALUES.map(&:downcase).include? value.downcase
          @dbms = value
        end
      end

      # Connection string for file infobases
      class File
        include ConnectionString
        def initialize(hash)
          fail ConnectionString::Error unless required_fields_passed?(hash)
          _set_properties(hash)
        end

        def self.required_fields
          FILE_FIELDS
        end

        def self.fields
          required_fields | COMMON_FIELDS
        end
      end

      # Connection string for infobases published on http server
      class Http < File
        include ConnectionString
        def self.required_fields
          HTTP_FIELDS
        end

        def uri
          URI(ws)
        end
      end
    end
  end
end
