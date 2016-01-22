require 'test_helper'
class TestServerDescr < Minitest::Test

  def cls
    AssLauncher::Common::ConnectionString::ServerDesc
  end

  def test_parse
    actual = cls.parse('server1:port1, server2:port2, server3, ')
    assert_equal 3, actual.size
    actual.each do |sd|
      assert_instace_of cls, sd
    end
    assert_equal 'server1', actual[0].host
    assert_equal 'port1', actual[0].port
  end

  def test_to_s
    actual = cls.parse('server1:port1, server2:port2, server3, ')
    assert_equal 'server2:port2', actual[1].to_s
    assert_equal 'server1:port1,server2:port2,server3', actual.join(',')
  end

end

class TestConnectionString < Minitest::Test

  class Server
    def self.fields
      []
    end

    def self.required_fields
      []
    end
    include AssLauncher::Support::ConnectionString
  end


  def mod
    AssLauncher::Support::ConnectionString
  end

  def test_fail
    raise "FIXME"
  end

  def test_set_property
    skip
  end

  def test_set_properties
    skip
  end

  def test_constants
    skip
  end

  def test_parse
    skip
  end

  def test_file_string
    assert_instace_of AssLauncher::Common::ConnectionString::File, mod['File="C:\Bla\Bla"']
    assert_instace_of AssLauncher::Common::ConnectionString::File, mod['File="C:/Bla/Bla"']
  end

  def test_server_string
    assert_instace_of AssLauncher::Common::ConnectionString::Server, mod['Srvr="host:port, host:port";Ref="IbName";']
  end

  def test_http_string
    assert_instace_of AssLauncher::Common::ConnectionString::Http, mod['Ws="http://example.org";']
  end

  def test_is
    assert_equal :server, Server.is
  end

  def test_is?
    assert Server.is?, :server
  end

end
