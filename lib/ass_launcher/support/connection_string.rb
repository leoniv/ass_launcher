module AssLauncher
  module Support
    # Implement 1C connection string
    # Mixin for connection string classes
    module ConnectionString
      class Error < StandardError; end
      class ParseError < StandardError; end
      # Commonn connection string fields
      COMMON_FIELDS = %w(Usr Pwd LicDstr prmod Locale)
      # Fields for server-infobase
      SERVER_FIELDS = %w(Srvr Ref)
      # Fields for file-infobase
      FILE_FIELDS = %w(File)
      # Fields for infobase published on http server
      HTTP_FIELDS = %w(Ws)
      # Proxy fields for accsess to infobase published on http server via proxy
      PROXY_FIELDS = %w(Wsn Wsp WspAuto WspSrv WspPort WspUser WspPwd)
      # Fields for makes server-infobase
      IB_MAKER_FIELDS = %w(DBMS DBSrvr DB
                           DBUID DBPwd SQLYOffs
                           CrSQLDB SchJobDn SUsr SPwd)
      # Values for DBMS field
      DBMS_VALUES = %w(MSSQLServer PostgreSQL IBMDB2 OracleDatabase)

      # Analyzes connect string and build suitable class
      # @param connstr (see parse)
      # @return [Server | File | Http] instanse
      def self.[](connstr)
        case connstr
        when /(\W|\A)File\s*=\s*"/i then File.new(parse(connstr))
        when /(\W|\A)Srvr\s*=\s*"/i then Server.new(parse(connstr))
        when /(\W|\A)Ws\s*=\s*"/i then Http.new(parse(connstr))
        else
          fail ParseError, "Uncknown connstr `#{connstr}'"
        end
      end

      # Parse connect string into hash.
      # Connect string have format:
      #  'Field1="Value";Field2="Value";'
      # Quotes ' " ' in value of field escape as doble quote ' "" '.
      # Fields name convert to downcase [Symbol]
      # @example
      #  parse 'Field="""Value"""' -> {field: '"Value"'}
      # @param connstr [String]
      # @return [Hash]
      def self.parse(connstr)
        res = {}
        connstr.split(';').each do |str|
          str.strip!
          res.merge!(parse_key_value str) unless str.empty?
        end
        res
      end

      def self.parse_key_value(str)
        fail ParseError, "Invalid string #{str}" unless\
          /\A\s*(?<field>\w+)\s*=\s*"(?<value>.*)"\s*\z/i =~ str
        { field.downcase.to_sym => value.gsub('""', '"') }
      end
      private_class_method :parse_key_value

      def is
        self.class.name.split('::').last.downcase.to_sym
      end

      def is?(symbol)
        is == symbol
      end

      def to_hash
        result = {}
        fields.each do |f|
          result[f.downcase.to_sym] = get_property(f)
        end
        result
      end

      def to_s(only_fields = nil)
        only_fields ||= fields
        result = ''
        only_fields.each do |f|
          result << "#{prop_to_s(f)};" unless get_property(f).to_s.empty?
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

      def set_property(prop, value)
        send("#{prop.downcase}=".to_sym, value)
      end

      def get_property(prop)
        send(prop.downcase.to_sym)
      end

      def prop_to_s(prop)
        "#{fields_to_hash[prop.downcase.to_sym]}="\
          +"\"#{get_property(prop).gsub('"', '""')}\""
      end

      def fields_to_hash
        res = {}
        fields.each do |f|
          res[f.downcase.to_sym] = f
        end
        res
      end

      def required_fields_received?(received_fields)
        (required_fields.map { |f| f.downcase.to_sym }\
          & received_fields.keys.map { |k| k.downcase.to_sym }) == \
          required_fields.map { |f| f.downcase.to_sym }
      end

      # Connection string for server-infobases
      class Server
        # Simple class host:port
        class ServerDescr
          attr_reader :host, :port

          # @param host [String] hostname
          # @param port [String] port number
          def initialize(host, port = nil)
            @host = host.strip
            @port = port.to_s.strip
          end

          # Parse sting <srv_string>
          # @param srv_str [String] string like 'host:port,host:port'
          # @return [Arry<ServerDescr>]
          def self.parse(srv_str)
            r = []
            srv_str.split(',').each do |srv|
              srv.strip!
              r << new(* srv.chomp.split(':')) unless srv.empty?
            end
            r
          end

          # @return [String] formated 'host:port'
          def to_s
            "#{host}" + (port.empty? ? '' : ":#{port}")
          end
        end

        def self.fields
          required_fields | COMMON_FIELDS | IB_MAKER_FIELDS
        end

        def self.required_fields
          SERVER_FIELDS
        end

        include ConnectionString

        def initialize(hash)
          fail ConnectionString::Error unless required_fields_received?(hash)
          _set_properties(hash)
        end

        # @return [Array<ServerDescr>]
        def servers
          @servers ||= []
        end

        def srvr=(str)
          @servers = ServerDescr.parse(str)
          @srvr = str
        end

        def srvr
          servers.join(',')
        end

        def srvr_raw
          @srvr
        end

        # (see DBMS_VALUES)
        def dbms=(value)
          fail ArgumentError, "Bad value #{value}" unless\
            DBMS_VALUES.map(&:downcase).include? value.downcase
          @dbms = value
        end
      end

      # Connection string for file-infobases
      class File
        def self.required_fields
          FILE_FIELDS
        end

        def self.fields
          required_fields | COMMON_FIELDS
        end

        include ConnectionString

        def initialize(hash)
          fail ConnectionString::Error unless required_fields_received?(hash)
          _set_properties(hash)
        end
      end

      # Connection string for infobases published on http server
      class Http
        def self.required_fields
          HTTP_FIELDS
        end

        def self.fields
          required_fields | COMMON_FIELDS | PROXY_FIELDS
        end

        include ConnectionString

        def initialize(hash)
          fail ConnectionString::Error unless required_fields_received?(hash)
          _set_properties(hash)
        end

        def uri
          require 'uri'
          uri = URI(ws)
          uri.user = wsn
          uri.password = wsp
          uri
        end
      end
    end
  end
end
