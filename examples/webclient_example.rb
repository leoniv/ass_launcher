require 'example_helper'

module Examples
  module WebClient
    require 'ass_launcher'

    describe 'Get web client instanse for connect to infobase' do
      describe 'Whith URL of infobase' do
        extend AssLauncher::Api

        wc = web_client('http://host/path/infobase', '8.3.8')
        loc = wc.location do
          # Buld arguments
          _N 'user name'
          _P 'pass'
          _L 'en'
          testClientID 'id'
          debuggerURL 'http://debugger:5668'
        end

        it 'We get URI::HTTP instanse' do
          loc.must_be_instance_of URI::HTTP
        end

        it 'We get perfect string for connect to infobase' do
          loc.to_s.must_equal 'http://host/path/infobase?'\
            'DisableStartupMessages&'\
            'N=user%20name&'\
            'P=pass&'\
            'L=en&'\
            'TESTCLIENTID=id&'\
            'DebuggerURL=http%3A%2F%2Fdebugger%3A5668'
        end
      end

      describe 'Whith connection string' do
        extend AssLauncher::Api

        cs = cs_http(ws: 'http://host/path/infobase', usr: 'user name',
                    pwd: 'pass')
        wc = web_client(cs.uri, '8.3.8')

        loc = wc.location do
          # Buld arguments
          _L 'en'
          testClientID 'id'
          debuggerURL 'http://debugger:5668'
        end

        it 'We get URI::HTTP instanse' do
          loc.must_be_instance_of URI::HTTP
        end

        it 'We get perfect string for connect to infobase' do
          loc.to_s.must_equal 'http://host/path/infobase?'\
            'N=user%20name&'\
            'P=pass&'\
            'DisableStartupMessages&'\
            'L=en&'\
            'TESTCLIENTID=id&'\
            'DebuggerURL=http%3A%2F%2Fdebugger%3A5668'
        end

      end
    end
  end
end
