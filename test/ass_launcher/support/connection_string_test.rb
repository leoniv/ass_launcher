require 'test_helper'
class TestServerDescr < Minitest::Test

  def cls
    AssLauncher::Support::ConnectionString::Server::ServerDescr
  end

  def test_parse
    actual = cls.parse('server1:port1, server2:port2, server3, ')
    assert_equal 3, actual.size
    actual.each do |sd|
      assert_instance_of cls, sd
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

  class FakeConnStr
    def self.fields
      []
    end

    def self.required_fields
      %w'F1 F2 F3'
    end
    include AssLauncher::Support::ConnectionString
  end

  def mod
    AssLauncher::Support::ConnectionString
  end

  def test_required_fields_received?
    assert FakeConnStr.new.send(:required_fields_received?, { f1:'', f2:'', f3:'', f4:'' })
    assert ! FakeConnStr.new.send(:required_fields_received?, { f2:'', f3:'', f4:'' })
  end

  def test_set_property
    mock = FakeConnStr.new
    mock.expects(:fakeprop=).with('fake prop value')
    mock.send(:set_property, 'FakeProp', 'fake prop value')
  end

  def test_get_property
    mock = FakeConnStr.new
    mock.expects(:fakeprop).returns('fake prop value')
    assert_equal 'fake prop value', mock.send(:get_property, 'FakeProp')
  end

  def test_set_properties
    mock = FakeConnStr.new
    mock.expects(:set_property).with('FakeProp1', 'fake value 1')
    mock.expects(:set_property).with('FakeProp2', 'fake value 2')
    hash = {'FakeProp1'=>'fake value 1',
            'FakeProp2'=>'fake value 2'}
    mock.send(:_set_properties, hash)
  end

  def test_parse
    string = ' Field1="Value of f1"; Field2 ="Value of f2";Field3= "Value=""Quoted value""" '
    hash = { field1: 'Value of f1',
             field2: 'Value of f2',
             field3: 'Value="Quoted value"'
            }
    assert_equal hash, mod.parse(string)
  end

  def test_fail_parse
    assert_raises AssLauncher::Support::ConnectionString::ParseError do
      string = '+Field=""'
      mod.parse string
    end
  end

  def test_to_hash
    mock = FakeConnStr.new
    mock.expects(:get_property).with('FakeProp1').returns('fake value 1')
    mock.expects(:get_property).with('FakeProp2').returns('fake value 2')
    mock.expects(:fields).returns(%w'FakeProp1 FakeProp2')
    hash = {:fakeprop1 => 'fake value 1',
            :fakeprop2 => 'fake value 2'}
    assert_equal hash, mock.to_hash
  end

  def test_fields
    FakeConnStr.expects(:fields)
    FakeConnStr.new.fields
  end

  def test_fields_to_hash
    mock = FakeConnStr.new
    mock.expects(:fields).returns(%w'F1 F2 F3')
    assert_equal({f1:'F1', f2:'F2', f3:'F3'}, mock.send(:fields_to_hash))
  end

  def test_prop_to_s
    mock = FakeConnStr.new
    mock.expects(:fields_to_hash).returns({fakeprop:'FakeProp', emptyprop:'EmptyProp'}).at_least_once
    mock.expects(:get_property).with('FakeProp').returns('Fake "value"')
    mock.expects(:get_property).with('EmptyProp').returns('')
    assert_equal 'FakeProp="Fake ""value"""', mock.send(:prop_to_s, 'FakeProp')
    assert_equal 'EmptyProp=""', mock.send(:prop_to_s, 'EmptyProp')
  end

  def test_to_s
    FakeConnStr.expects(:fields).returns(%w'F1 EmptyField F3').at_least_once
    mock = FakeConnStr.new
    mock.expects(:f1).returns('value 1').twice
    mock.expects(:emptyfield).returns('').once
    mock.expects(:f3).returns('value 3').twice
    string = 'F1="value 1";F3="value 3";'
    assert_equal string, mock.to_s
  end

  def test_to_s_with_param
    FakeConnStr.expects(:fields).returns(%w'F1 EmptyField F3')
    mock = FakeConnStr.new
    mock.expects(:f1).never
    mock.expects(:emptyfield).returns('').once
    mock.expects(:f3).returns('value 3').twice
    string = 'F3="value 3";'
    assert_equal string, mock.to_s([:emptyfield, :f3])
  end

  def test_build_file_string
    ['File="C:/Bla/Bla"',
     'File="\\\\Bla\\Bla"',
     'File="//Bla/Bla"'].each do |str|
      AssLauncher::Support::ConnectionString.expects(:parse)
      AssLauncher::Support::ConnectionString::File.expects(:new).returns('FakeFile')
      assert_equal 'FakeFile', mod[str]
    end
  end

  def test_build_server_string
    AssLauncher::Support::ConnectionString.expects(:parse)
    AssLauncher::Support::ConnectionString::Server.expects(:new).returns('FakeServer')
    assert_equal 'FakeServer' , mod['Srvr="host:port, host:port";Ref="IbName";']
  end

  def test_build_http_string
    AssLauncher::Support::ConnectionString.expects(:parse)
    AssLauncher::Support::ConnectionString::Http.expects(:new).returns('FakeHttp')
    assert_equal 'FakeHttp', mod['Ws="http://example.org";']
  end

  def test_fail_bild_string
    assert_raises AssLauncher::Support::ConnectionString::ParseError do
      mod['BadString="']
    end
  end

  def test_is
    assert_equal :fakeconnstr, FakeConnStr.new.is
  end

  def test_is?
    assert FakeConnStr.new.is? :fakeconnstr
  end
end

class TestConnectionStringServer < Minitest::Test
  def cls
    AssLauncher::Support::ConnectionString::Server
  end

  def test_initialize
    hash = {srvr:'Server1:Port1,Server2:port2', ref:'ibname'}
    AssLauncher::Support::ConnectionString::Server::ServerDescr.expects(:parse).returns('fake parsed servers')
    inst = cls.new(hash)
    assert_equal 'fake parsed servers', inst.servers
    assert_equal 'Server1:Port1,Server2:port2', inst.srvr_raw
  end

  def test_initialize_fail
    hash = {f1:'', f2:''}
    assert_raises AssLauncher::Support::ConnectionString::Error do
      cls.new(hash)
    end
  end

  def test_srvr
    mock = Class.new(cls) do
      def initialize
      end
    end.new
    mock.expects(:servers).returns(%w'1 2 3')
    assert_equal '1,2,3', mock.srvr
  end

  def test_set_empty_srvr
    mock = Class.new(cls) do
      def initialize
      end
    end.new
    assert_raises ArgumentError do
      mock.srvr=''
    end
  end

  def test_set_empty_ref
    mock = Class.new(cls) do
      def initialize
      end
    end.new
    assert_raises ArgumentError do
      mock.ref=''
    end
  end

  def test_dbms
    mock = Class.new(cls) do
      def initialize
      end
    end.new
    mock.dbms = 'MSSQLServer'
    assert_equal 'MSSQLServer', mock.dbms
    mock.dbms = 'MSSQLServer'.upcase
    assert_equal 'MSSQLServer'.upcase, mock.dbms, 'should be not case insensitive'
  end

  def test_dbms_fail
    mock = Class.new(cls) do
      def initialize
      end
    end.new
    assert_raises ArgumentError do
      mock.dbms = 'Bad dbms'
    end
  end

  def test_to_cmd
    raise 'TODO implements #to_cmd(binary_wrapper)'
  end
end

class TestConnectionStringFile < Minitest::Test
  def cls
    AssLauncher::Support::ConnectionString::File
  end

  def test_initialize
    hash = {file: 'path'}
    assert_equal 'path', cls.new(hash).file
  end

  def test_initialize_fail
    hash = {}
    assert_raises AssLauncher::Support::ConnectionString::Error do
      cls.new hash
    end
  end

  def test_set_empty_file
    mock = Class.new(cls) do
      def initialize
      end
    end.new
    assert_raises ArgumentError do
      mock.file=''
    end
  end

  def test_to_cmd
    raise 'TODO implements #to_cmd(binary_wrapper)'
  end
end

class TestConnectionStringHttp < Minitest::Test
  def cls
    AssLauncher::Support::ConnectionString::Http
  end

  def test_initialize
    hash = {ws: 'http://example.com'}
    assert_equal 'http://example.com', cls.new(hash).ws
  end

  def initialize_fail
    hash = {}
    assert_raises AssLauncher::Support::ConnectionString::Error do
      cls.new hash
    end
  end

  def test_set_empty_ws
    mock = Class.new(cls) do
      def initialize
      end
    end.new
    assert_raises ArgumentError do
      mock.ws=''
    end
  end

  def test_uri
    mock = Class.new(cls) do
      def initialize

      end
    end.new
    mock.expects(:ws).returns('http://exaple.com')
    assert_kind_of ::URI, mock.uri
  end

  def test_to_cmd
    raise 'TODO implements #to_cmd(binary_wrapper)'
  end
end
