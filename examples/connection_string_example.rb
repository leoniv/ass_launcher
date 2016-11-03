require 'example_helper'

module Examples
  module ConnectionString
    require 'ass_launcher'

    describe 'Parse connection string from string: Api.cs method' do
      it 'File infobase connection string' do
        extend AssLauncher::Api
        conns = cs 'File="path";Usr="user name";Pwd="pass"'

        conns.must_be_instance_of AssLauncher::Support::ConnectionString::File
        conns.is?(:file) .must_equal true
      end

      it 'Server connection string' do
        extend AssLauncher::Api
        conns = cs 'srvr="host";ref="infibase";usr="user name";pwd="pass"'

        conns.must_be_instance_of AssLauncher::Support::ConnectionString::Server
        conns.is?(:server) .must_equal true
      end

      it 'HTTP connection string' do
        extend AssLauncher::Api
        conns = cs 'ws="http://example.org/ib";usr="user name";pwd="pass"'

        conns.must_be_instance_of AssLauncher::Support::ConnectionString::Http
        conns.is?(:http) .must_equal true
      end
    end

    describe 'New connection string' do
      it 'File connection string: Api.cs_file method' do
        extend AssLauncher::Api
        conns = cs_file file: 'path', usr: 'user name', pwd: 'pass'

        conns.must_be_instance_of AssLauncher::Support::ConnectionString::File
        conns.is?(:file) .must_equal true
      end

      it 'Server connection string Api.cs_srv method' do
        extend AssLauncher::Api
        conns = cs_srv srvr: 'host', ref: 'infibase', usr: 'user name', pwd: 'pass'

        conns.must_be_instance_of AssLauncher::Support::ConnectionString::Server
        conns.is?(:server) .must_equal true
      end

      it 'HTTP connection string: Api.cs_http method' do
        extend AssLauncher::Api
        conns = cs_http ws: 'http://example.org/ib', usr: 'user name', pwd: 'pass'

        conns.must_be_instance_of AssLauncher::Support::ConnectionString::Http
        conns.is?(:http) .must_equal true
      end
    end
  end
end
