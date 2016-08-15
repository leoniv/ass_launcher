require 'test_helper'

class ApiTest < Minitest::Test

  def inst
    Class.new do
      include AssLauncher::Api
    end.new
  end

  def test_thicks
    array = mock()
    array.expects(:sort).returns(array)
    AssLauncher::Enterprise.expects(:thick_clients).with(:requiremet).returns(array)
    assert_equal array, inst.thicks(:requiremet)
  end

  def test_thins
    array = mock()
    array.expects(:sort).returns(array)
    AssLauncher::Enterprise.expects(:thin_clients).with(:requiremet).returns(array)
    assert_equal array, inst.thins(:requiremet)
  end

  def test_cs
    assert_instance_of AssLauncher::Support::ConnectionString::File,
      inst.cs('File="."')
  end

  def test_cs_file
    assert_instance_of AssLauncher::Support::ConnectionString::File,
      inst.cs_file({file: '.'})
  end

  def test_cs_http
    assert_instance_of AssLauncher::Support::ConnectionString::Http,
      inst.cs_http({ws: 'http://example.com'})
  end

  def test_cs_srv
    assert_instance_of AssLauncher::Support::ConnectionString::Server,
      inst.cs_srv({srvr: 'example.com', ref: 'ib'})
  end

  def test_load_v8i
    AssLauncher::Support::V8iFile.expects(:load).with(:filename).returns(:v8i)
    assert_equal :v8i, inst.load_v8i(:filename)
  end

  def test_ole
    ole = mock()
    ole.expects(:new).with(:requiremet).returns(ole)
    AssLauncher::Enterprise::Ole.expects(:ole_client).with(:type).returns(
      ole)
    assert_equal ole, inst.ole(:type, :requiremet)
  end
end
