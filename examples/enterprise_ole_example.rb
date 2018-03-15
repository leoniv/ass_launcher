require 'example_helper'

module Examples
  module EnterpriseOle
    fail 'OLE in UNIX??? :)' if PLATFORM::LINUX
    module HRESULT
      RPC_SERVER_UNAVALIBLE = '0x800706ba'
    end

    # 1C:Enterprise provides three OLE servers:
    # v8x.Application - thick client standalone OLE server
    # v8xC.Application - thin client standalone OLE server
    # v8x.ComConnector - inproc ole server for connect to:
    #  - 1C:Enterprise application aka infobases
    #  - 1C:Enterprise server agent
    #  - 1C:Enterprise server working process

    describe 'AssLauncher provides wrappers for 1C:Enterprise Ole servers' do
      extend AssLauncher::Api

      # Wrappers returned AssLauncher::Api#ole method

      thick_app = ole(:thick, PLATFORM_VER)
      it 'Wrapper for "Thick application ole server" (aka v83.Application)' do
        thick_app.must_be_instance_of AssLauncher::Enterprise::Ole::ThickApplication
      end

      thin_app = ole(:thin, PLATFORM_VER)
      it 'Wrapper for "Thin application ole server" (aka v83c.Application)' do
        thin_app.must_be_instance_of AssLauncher::Enterprise::Ole::ThinApplication
      end

      external = ole(:external, PLATFORM_VER)
      it 'Wrapper for "External connection with infobase" (childe v83.ComConnector)' do
        external.must_be_instance_of AssLauncher::Enterprise::Ole::IbConnection
      end

      wpconn = ole(:wprocess, PLATFORM_VER)
      it 'Wrapper for "1C:Enterprise server working process connection" (childe v83.ComConnector)' do
        wpconn.must_be_instance_of AssLauncher::Enterprise::Ole::WpConnection
      end

      saconn = ole(:sagent, PLATFORM_VER)
      it 'Wrapper for "1C:Enterprise server agent connection" (childe v83.ComConnector)' do
        saconn.must_be_instance_of AssLauncher::Enterprise::Ole::AgentConnection
      end
    end

    describe 'Example for basic to use' do
      extend AssLauncher::Api

      # Get ole wrapper
      external = ole(:external, PLATFORM_VER)

      it 'Example' do
        # Open connection with connection string
        # For WpConnection and AgentConnection __connect__
        # expects URI string
        external.__open__ TMP::EMPTY_IB_CS

        # Call 1C:Enterprise method #InfoBaseConnectionString
        external.InfoBaseConnectionString.must_equal\
          TMP::EMPTY_IB_CS.to_ole_string

        # Close connection
        external.__close__
      end

      after do
        external.__close__
      end
    end

    describe 'Closing connection' do
      describe 'For standalone server it working perfect' do
        extend AssLauncher::Api
        thick_app = ole(:thick, PLATFORM_VER)

        it 'Connection realy closed of thick_app' do
          thick_app.__open__ TMP::EMPTY_IB_CS

          ole_array = thick_app.newObject('Array')
          ole_array.Count.must_equal 0

          thick_app.__close__

          # Fails because OLE server is down
          e = proc {
            ole_array.Count
          }.must_raise NoMethodError

          e.message.must_match %r{error code:#{HRESULT::RPC_SERVER_UNAVALIBLE}}
        end

        after do
          thick_app.__close__
        end
      end

      describe 'For inproc server close connection working with restrictions' do
        # 1C inproc OLE servers haven't method for closing connection!
        # Connection keep alive while live ruby process.
        #
        # If in one ruby script we want to use inproc connection for some work
        # do in the infobase and after them we want run other connection
        # or application or designer with flag of exclusive mode, in this case
        # opened inproc connection doesn't give us to do it
        #
        # AssLauncher provide feature for closing inproc connection  but
        # it working with restrictions.
        #
        # AssLauncher patching WIN32OLE and collect all ole objects which
        # generated and try kill refs calling #ole_free method for them when
        # #__close__ method call.
        #
        # But it works not always. Connection keep alive while have any alive
        # WIN32OLE refs generated this connection

        describe 'Case when inproc server connection realy closed' do
          extend AssLauncher::Api

          # Get standalone ole server wrapper
          # It is service connector
          thick_app = ole(:thick, PLATFORM_VER)

          # Get inproc ole server wrapper
          # It object under test
          external = ole(:external, PLATFORM_VER)

          it 'External connection realy closed' do
            thick_app.__open__ TMP::EMPTY_IB_CS
            external.__open__ TMP::EMPTY_IB_CS

            # We have two working sessions
            thick_app.GetInfoBaseSessions.Count.must_equal 2

            ole_array = external.newObject('Array')
            ole_array.Count.must_equal 0

            external.__close__

            # External connection was closed
            # and only one working session is alive
            thick_app.GetInfoBaseSessions.Count.must_equal 1

            # Fails 'failed to get Dispatch Interface'
            # because #ole_free was called while external.__close__
            e = proc {
              ole_array.Count
            }.must_raise RuntimeError
            e.message.must_match %r{failed to get Dispatch Interface}i
          end

          after do
            thick_app.__close__
            external.__close__
          end
        end
      end
    end

    describe 'We can chose version of 1C:Enterprise ole server' do
      # We can choosing 1C ole server's version.
      # AssLauncher automatically register needed server version
      # and returns suitable wrapper.
      #
      # Registration version of ole server working correct only for standalone
      # servers such as Thin and Thick applications.
      #
      # We don't get new version of inproc ole server until old version
      # is loaded in memory

      it "Fail if 1C:Enterprise version doesn't instaled" do
        extend AssLauncher::Api
        external = ole(:external, '~> 999')
        e = proc {
          external.__open__ ''
        }.must_raise RuntimeError
        e.message.must_match %r{Platform version `~> 999' not instaled}
      end

      describe 'Choosing version of standalone ole server working perfect' do
        extend AssLauncher::Api

        thick_app = ole(:thick, PLATFORM_VER)

        it 'Ole server have suitable version' do
          thick_app.__open__ TMP::EMPTY_IB_CS
          system_info = thick_app.newObject('SystemInfo')

          real_ole_app_version = Gem::Version.new(system_info.AppVersion)

          real_ole_app_version.must_equal\
            thick_app.instance_variable_get(:@__ole_binary__).version

          thick_app.__close__
        end

        after do
          thick_app.__close__
        end
      end
    end

    describe 'AssLauncher patching WIN32OLE for some reason' do
      describe 'Getting real Ruby objects from WIN32OLE wrapper' do

        # Ruby WIN32OLE automatically convert Ruby objects into IDispatch
        # when they passed as parameter in to OLE server's side.
        # When such objects returns on the Ruby's side they will keep as WIN32OLE
        # AssLauncher provides feature for getting real Ruby object

        it 'Example' do
          ole_server = WIN32OLE.new('Scripting.Dictionary')

          ruby_obj = Object.new

          skip "It usually Segmentation fault in ruby:\n"\
          " 2.0.0p645 (2015-04-13 revision 50299) [i386-cygwin]\n"\
          " 2.3.6p384 (2017-12-14 revision 9808) [i386-cygwin]"

          # Call OLE server
          ole_server.add(1, ruby_obj)
          wrapped_obj = ole_server.items[0]

          # Ruby object wrapped into WIN32OLE
          wrapped_obj.must_be_instance_of WIN32OLE

          # Ask: Is it Ryuby object?
          wrapped_obj.__ruby__?.must_equal true

          # Get Ruby object
          wrapped_obj.__real_obj__.must_equal ruby_obj
        end
      end
    end
  end
end
