# encoding: utf-8
module AssLauncher
  # Helpers for easy to use ass_launcher
  module Api
    # Define type of 1C OLE clients
    OLE_CLIENTS = {
      external: AssLauncher::Enterprise::Ole::IbConnection,
      wprocess: AssLauncher::Enterprise::Ole::WpConnection,
      sagent: AssLauncher::Enterprise::Ole::AgentConnection,
      thin: AssLauncher::Enterprise::Ole::ThinApplication,
      thick: AssLauncher::Enterprise::Ole::ThickApplication
    }

    # Return sorted array of instaled 1C binary wrappers
    # @example
    #  inclide AssLauncher::Api
    #  # I can get 1C thick client specific version
    #  cl = thicks('~> 8.3.8.0').last
    #  fail "Client '~> 8.3.8.0' not found" if cl.nil?
    # @param requiremet [String, Gem::Version::Requirement] spec require version
    # @return [Array<AssLauncher::Enterprise::BinaryWrapper::ThickClient>]
    def thicks(requiremet = '>= 0')
      AssLauncher::Enterprise.thick_clients(requiremet).sort
    end

    # Return sorted array of instaled 1C binary wrappers
    # @example
    #  inclide AssLauncher::Api
    #  # I can get 1C thin client specific version
    #  cl = thins('~> 8.3.8.0').last
    #  fail "Client '~> 8.3.8.0' not found" if cl.nil?
    # @param (see .thicks)
    # @return [Array<AssLauncher::Enterprise::BinaryWrapper::ThinClient>]
    def thins(requiremet = '>= 0')
      AssLauncher::Enterprise.thin_clients(requiremet).sort
    end

    # (see AssLauncher::Support::ConnectionString.new)
    # @example
    #  include AssLauncher::Api
    #  file_cs = cs 'file="path";'
    #  srv_cs = cs 'srvr="host";ref="ib_name";'
    #  http_cs = cs 'ws="http://host/ib";'
    def cs(connstr)
      AssLauncher::Support::ConnectionString.new(connstr)
    end

    # @example
    #  include AssLauncher::Api
    #  fcs = cs_file({:file => 'path'})
    # @return [AssLauncher::Support::ConnectionString::File]
    def cs_file(hash)
      AssLauncher::Support::ConnectionString::File.new hash
    end

    # @example
    #  include AssLauncher::Api
    #  httpcs = cs_http({:ws => 'http://host/ib'})
    # @return [AssLauncher::Support::ConnectionString::Http]
    def cs_http(hash)
      AssLauncher::Support::ConnectionString::Http.new hash
    end

    # @example
    #  include AssLauncher::Api
    #  srvcs = cs_srv({:srvr => 'host', :ref=> 'ib'})
    # @return [AssLauncher::Support::ConnectionString::Server]
    def cs_srv(hash)
      AssLauncher::Support::ConnectionString::Server.new hash
    end

    # (see AssLauncher::Support::V8iFile.load)
    # @example
    #  include AssLauncher::Api
    #
    #  v8i = load_v8i('infobase.v8i')
    #  conn_str = cs(v8i.connect)
    #  conn_str.usr = 'admin'
    #  conn_str.pwd = 'password'
    #  designer = thicks.last.command(:designer, conn_str.to_args)
    #  designer.run.wait
    def load_v8i(filename)
      AssLauncher::Support::V8iFile.load(filename)
    end

    # Return 1C ole client suitable class instance
    # @param type [Symbol] type of 1C ole client. See {OLE_CLIENTS}
    # @param requiremet [String, Gem::Version::Requirement] require version spec
    # @raise [ArgumentError] if invalid +type+ given
    def ole(type, requiremet = '>= 0')
      fail ArgumentError, "Invalid ole type `#{type}'. Use types:"\
        " #{OLE_CLIENTS.keys}" unless OLE_CLIENTS.key? type
      OLE_CLIENTS[type].new(requiremet)
    end
  end
end
