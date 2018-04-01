require 'test_helper'

class ApiTest < Minitest::Test

  def bw_cls_stubed
    Class.new(AssLauncher::Enterprise::BinaryWrapper) do
      def initialize; end
    end
  end

  def bw_stub(arch)
    r = mock
    r.responds_like(bw_cls_stubed.new)
    r.stubs(:arch => arch)
    r

  end

  def i386_bw
    r = bw_stub('i386')
    r.stubs(:x86_64? => false)
    r
  end

  def x86_64_bw
    r = bw_stub('x86_64')
    r.stubs(:x86_64? => true)
    r
  end

  def inst
    @inst ||= Class.new do
      include AssLauncher::Api
    end.new
  end

  def test_thicks
    array = mock()
    array.expects(:sort).returns(array)
    AssLauncher::Enterprise.expects(:thick_clients).with(:requiremet).returns(array)
    assert_equal array, inst.thicks(:requiremet)
  end

  def test_thicks_i386
    inst.expects(:thicks).with(:requiremet)
      .returns([i386_bw, i386_bw, x86_64_bw, x86_64_bw])
    assert_equal 'i386', inst
      .thicks_i386(:requiremet).map {|bw| bw.arch}.uniq[0]
  end

  def test_thicks_x86_64
    inst.expects(:thicks).with(:requiremet)
      .returns([i386_bw, i386_bw, x86_64_bw, x86_64_bw])
    assert_equal 'x86_64', inst
      .thicks_x86_64(:requiremet).map {|bw| bw.arch}.uniq[0]
  end

  def test_thins
    array = mock()
    array.expects(:sort).returns(array)
    AssLauncher::Enterprise.expects(:thin_clients).with(:requiremet).returns(array)
    assert_equal array, inst.thins(:requiremet)
  end

  def test_thins_i386
    inst.expects(:thins).with(:requiremet)
      .returns([i386_bw, i386_bw, x86_64_bw, x86_64_bw])
    assert_equal 'i386', inst
      .thins_i386(:requiremet).map {|bw| bw.arch}.uniq[0]
  end

  def test_thins_x86_64
    inst.expects(:thins).with(:requiremet)
      .returns([i386_bw, i386_bw, x86_64_bw, x86_64_bw])
    assert_equal 'x86_64', inst
      .thins_x86_64(:requiremet).map {|bw| bw.arch}.uniq[0]
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

  def test_web_client
    assert_instance_of AssLauncher::Enterprise::WebClient, inst.web_client
  end
end
