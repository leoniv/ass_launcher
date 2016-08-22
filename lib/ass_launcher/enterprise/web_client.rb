# encoding: utf-8

module AssLauncher
  module Enterprise
    # Abstract 1C:Enterprise client. Provides {#location} method as URI
    # generator for connection to
    # 1C information base via web browser.
    # @example (see #initialize)
    # @example (see #location)
    class WebClient
      require 'uri'
      # Run mode defined for webclient
      RUN_MODE = :webclient
      DEFAULT_OPTIONS = { disable_startup_messages: true }
      DEFAULT_VERSION = '999'

      # @return [URI] base uri location
      attr_accessor :uri
      # Version for 1C:Enterprise platform
      attr_reader :version
      # @return [WebClient]
      # @example
      #
      #  # Get webclient usin connection string:
      #  connection_string =\
      #  AssLauncher::Support::ConnectionString.new(
      #    'ws="http://host:port/infobase"')
      #  wc = AssLauncher::Enterprise::WebClient.new(cs.uri)
      #
      #  #or without connection_string
      #  wc = AssLauncher::Enterprise::WebClient.new('http://host/path')
      #
      # @param uri [String URI] base infobase location
      # @param version [String] version 1C:Enterprise platform.
      #  The {Enterprise::WebClient#cli_spec}
      #  depends on the {Enterprise::WebClient#version}.
      #  Default supposed max possable version.
      #  {Enterprise::WebClient::DEFAULT_VERSION}
      #
      def initialize(uri = '', version = DEFAULT_VERSION)
        @version = Gem::Version.new(version || DEFAULT_VERSION)
        @uri ||= URI(uri || '')
      end

      # @return [Cli::CliSpec]
      def cli_spec
        AssLauncher::Enterprise::Cli::CliSpec.for(self, RUN_MODE)
      end

      # (see RUN_MODE)
      # @return [Array] see {RUN_MODE}
      def run_modes
        [RUN_MODE]
      end

      def build_args(&block)
        Cli::ArgumentsBuilder.new(cli_spec).build_args(&block)
      end
      private :build_args

      # Build URI location for connect to web infobase.
      #
      # We can use {Cli::ArgumentsBuilder} for
      # build connection string with validation parameters on defined in
      # {#cli_spec} specifications.
      #
      # Or we can pass parameters as +args+ array directly.
      # @example
      #  wc = AssLauncher::Enterprise::WebClient.new('http://host/path')
      #
      #  # Without ArgumentsBulder
      #  wc.location(['O', 'low', 'C', 'passed string',
      #    'N', '1cuser',
      #    'P', '1cpassw',
      #    'Authoff', '']) #=> URI
      #
      #  # With ArgumentsBulder
      #  wc.location do
      #    _O :Low
      #    _C 'passed string'
      #    _N '1cuser'
      #    _P '1cuser_password'
      #    wA :-
      #    oIDA :-
      #    authOff
      #    _L 'en'
      #    vL 'en'
      #    debuggerURL 'localhost'
      #    _UsePrivilegedMode
      #  end  #=> URI
      #
      # @param args [Arry]
      # @option options [bool] :disable_startup_messages adds or not
      #  '/DisableStartupMessages' flag parameter into +args+
      #
      def location(args = [], **options, &block)
        options = DEFAULT_OPTIONS.merge options
        args += ['DisableStartupMessages', '']\
          if options[:disable_startup_messages]
        args += build_args(&block) if block_given?
        add_to_query uri.dup, args_to_query(args)
      end

      def add_to_query(uri, q)
        if uri.query
          uri.query += URI.escape "&#{q}" if q
        else
          uri.query = URI.escape "#{q}" if q
        end
        uri
      end
      private :add_to_query

      CLI_TO_WEB_PARAM_NAME = %r{^/}

      def args_to_query(args)
        r = to_query(args)
        r.gsub!(/&$/, '')
        return nil if r.empty?
        r
      end
      private :args_to_query

      def to_query(args)
        r = ''
        args.each_with_index do |v, i|
          next if (i + 1).even?
          r << "#{v.gsub(CLI_TO_WEB_PARAM_NAME, '')}"
          r << "=#{args[i + 1]}" unless args[i + 1].to_s.empty?
          r << '&'
        end
        r
      end
      private :to_query
    end
  end
end
