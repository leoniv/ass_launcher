module AssLauncher
  module Support
    # Implement 1C connection string
    # Mixin for connection string classes
    # @note All connection string class have methods for get and set values
    #  of defined fields. Methods have name as fields but in downcase
    #  All fields defined for connection string class retutn {#fields}
    # @example
    #  cs =  AssLauncher::Support::\
    #    ConnectionString.new('File="\\fileserver\accounting.ib"')
    #  cs.is #-> :file
    #  cs.is? :file #-> true
    #  cs.usr = 'username'
    #  cs.pwd = 'password'
    #  cmd = "1civ8.exe enterprise #{cs.to_cmd}"
    #  run_result = AssLauncher::Support::Shell.run_ass(cmd)
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
      HTTP_WEB_AUTH_FIELDS = %w(Wsn Wsp)
      # Rule for {#to_cmd}
      FIELDS_TO_CMD = { Usr: lambda { " /N\"#{usr}\" " },
                        Pwd: lambda { " /P\"#{pwd}\" " },
                        prmod: lambda { ' /UsePrivilegedMode ' },
                        Locale: lambda { " /L\"#{locale}\" " },
                        Srvr: lambda { " /S\"#{srvr}/#{ref}\" " },
                        File: lambda do
                          " /F\"#{AssLauncher::Support::\
                                      Platforms.path(file).win_string}\" "
                        end,
                        Ws: lambda { " /WS\"#{ws}\" " },
                        Wsn: lambda { " /WSN\"#{wsn}\" " },
                        Wsp: lambda { " /WSP\"#{wsp}\" " }
      }
      FIELDS_TO_CMD.freeze
      # Proxy fields for accsess to infobase published on http server via proxy
      PROXY_FIELDS = %w(WspAuto WspSrv WspPort WspUser WspPwd)
      # Fields for makes server-infobase
      IB_MAKER_FIELDS = %w(DBMS DBSrvr DB
                           DBUID DBPwd SQLYOffs
                           CrSQLDB SchJobDn SUsr SPwd)
      # Values for DBMS field
      DBMS_VALUES = %w(MSSQLServer PostgreSQL IBMDB2 OracleDatabase)

      # Analyzes connect string and build suitable class
      # @param connstr (see parse)
      # @return [Server | File | Http] instanse
      def self.new(connstr)
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

      # Return type of connection string
      # :file, :server, :http
      # @return [Symbol]
      def is
        self.class.name.split('::').last.downcase.to_sym
      end

      # Check connection string for type :file, :server, :http
      # @param symbol [Symvol]
      # @example
      #  if cs.is? :file
      #    #do for connect to the file infobase
      #  else
      #    raise "#{cs.is} unsupport
      #  end
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

      # Convert connection string to 1C:Enterprise launch parameters
      # like /N"usr" /P"pwd" etc
      # see {FIELDS_TO_CMD} and {#proxy_cmd}
      # @return [String]
      def to_cmd
        r = ''
        fields.each do |f|
          r += "#{prop_to_cmd(f)} " unless get_property(f).to_s.empty?
        end
        r += proxy_cmd
      end

      def prop_to_cmd(f)
        instance_exec &FIELDS_TO_CMD[f.to_sym] if FIELDS_TO_CMD.key? f.to_sym
      end
      private :prop_to_cmd

      # @api private
      # Convert proxy fields to 1C:Enterprise launch parameter /Proxy
      # see {PROXY_FIELDS}
      # @return [String]
      def proxy_cmd
        return '' unless is? :http
        return '' if wspauto
        return " /Proxy -PSrv\"#{wspsrv}\""\
               " -PPort\"#{wspport}\""\
               " -PUser\"#{wspuser}\""\
               " -PPwd\"#{wsppwd}\" "\
               if wspsrv
        ''
      end

      # @api private
      # Fields required for new instance of connection string
      def required_fields
        self.class.required_fields
      end

      # All fields defined for connection string
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
      # @note (see ConnectionString)
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
          fail ArgumentError if str.empty?
          @servers = ServerDescr.parse(str)
          @srvr = str
        end

        def ref=(str)
          fail ArgumentError if str.empty?
          @ref = str
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
      # @note (see ConnectionString)
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

        def file=(str)
          fail ArgumentError if str.empty?
          @file = str
        end
      end

      # Connection string for infobases published on http server
      # @note (see ConnectionString)
      class Http
        def self.required_fields
          HTTP_FIELDS
        end

        def self.fields
          required_fields | COMMON_FIELDS | HTTP_WEB_AUTH_FIELDS | PROXY_FIELDS
        end

        include ConnectionString

        def initialize(hash)
          fail ConnectionString::Error unless required_fields_received?(hash)
          _set_properties(hash)
        end

        def ws=(str)
          fail ArgumentError if str.empty?
          @ws = str
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
