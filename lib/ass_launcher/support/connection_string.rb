module AssLauncher
  module Support
    module ConnectionString
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

      class Error < StandardError; end
      COMMON_FIELDS = %w(Usr Pwd LicDstr prmod Locale)
      SERVER_FIELDS = %w(Srvr Ref)
      FILE_FIELDS = %w(File)
      HTTP_FIELDS = %w(Ws)
      IB_MAKER_FIELDS = %w(DBMS DBSrvr DB DBUID DBPwd SQLYOffs CrSQLDB SchJobDn SUsr SPwd)
      DBMS_VALUES = %w(MSSQLServer PostgreSQL IBMDB2 OracleDatabase)
      (COMMON_FIELDS | SERVER_FIELDS | FILE_FIELDS |\
       IB_MAKER_FIELDS | HTTP_FIELDS).each do |f|
        attr_accessor f.downcase.to_sym
      end
      def self[](connstr)
        case connstr
        when /File=/i then File.new(prase(connstr))
        when /Server=/i then Server.new(prase(connstr))
        else
          fail  "Uncknown connstr `#{connstr}'"
        end
      end

      # @return [Array<ServerDescr>]
      def servers
        @servers ||= []
      end

      def all_required?(fields)
        (required_fields & fields.keys.map(|k| k.downcase)) == required_fields
      end

      def set_properties(fields)
        fields.each do |key, value|
          set_property(key, value)
        end
      end

      def set_property(prop, value)
        self.send("#{prop.downcase}=".to_sym, value)
      end

      def is
        name.split('::').last.downcase.to_sym
      end

      def is?(symbol)
        is == symbol
      end

      class Server
        include ConnectionString
        def initialize(fields, ib_maker_fields)
          fail ConnectionString::Error unless all_required?(fields)
          set_properties(fields)
          set_properties(ib_maker_fields)
          @servers = ServerDescr.parce(@srvr)
        end

        def required_fields
          ConnectionString::SERVER_FIELDS.map(|f| f.downcase)
        end

        # (see DBMS_VALUES)
        def dbms=(value)
          raise 'Not emplement'
          #faile ArgumentError unless value.downcase
          @dbms = value
        end
      end
      class File
        include ConnectionString
        def initialize(fields)
          fail ConnectionString::Error unless all_required?(fields)
          set_properties(fields)
        end

        def required_fields
          ConnectionString::FILE_FIELDS.map(|f| f.downcase)
        end
      end
      class Http < File
        include ConnectionString
        def required_fields
          ConnectionString::HTTP_FIELDS.map(|f| f.downcase)
        end
      end
    end
  end
end
