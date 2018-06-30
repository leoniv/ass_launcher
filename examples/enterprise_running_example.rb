require 'example_helper'

module Examples
  module EnterpriseRun
    describe 'Basic examples for running 1C:Enterprise' do
      it 'Running thick client in :designer run mode' do
        # 1) Get AssLauncher::Api helper
        extend AssLauncher::Api

        # 2) Get 1C:Enterprise binary wrappers which satisfied by version
        #    requirement and choose last version from them
        thick_client = thicks('~> 8.3').last

        # 3) Fail if required 1C:Enterprise installation not found
        fail '1C:Enterprise ~> 8.3 not found' if thick_client.nil?

        # 4) Build command for required run mode.
        designer = thick_client.command(:designer) do
          # This block writes on DSL and
          # will be passed to arguments builder instance
          connection_string "File=\"#{TMP::EMPTY_IB}\";"
          checkModules do
            _Server
          end
          _L 'en'
        end

        # 5) Running 1C:Enterprise and waiting
        designer.run.wait

        # 6) Verify result
        designer.process_holder.result.verify!
      end

      it 'Running thin client' do
        # 1) Get AssLauncher::Api helper
        extend AssLauncher::Api

        # 2) Get 1C:Enterprise binary wrappers which satisfied by version
        #    requirement and choose last version from them
        thin_client = thins('~> 8.3').last

        # 3) Fail if required 1C:Enterprise installation not found
        fail '1C:Enterprise ~> 8.3 not found' if thin_client.nil?

        # 4) Build command
        enterprise = thin_client.command do
          # This block writes on DSL and
          # will be passed to arguments builder instance
          connection_string "File=\"#{TMP::EMPTY_IB}\";"
          _L 'en'
          _Debug :'-tcp'
          _DebuggerUrl 'tcp://localhost'
        end

        # 5) Run enterprise
        enterprise.run

        # 6) Kill enterprise
        enterprise.process_holder.kill
      end

      it 'Running web client' do
        # 1) Get AssLauncher::Api helper
        extend AssLauncher::Api

        # 2) Get wrapper for specified 1C:Enterprise version
        wc = web_client('http://host/path/infobase', '8.3.6')

        # 3) Build URI
        loc = wc.location do
          # Buld arguments
          _N 'user name'
          _P 'pass'
          _L 'en'
          testClientID 'id'
          debuggerURL 'http://debugger:5668'
        end

        # 4) Navigate to location
        # `firefox #{loc}`
      end

      it 'Running ole sever' do
        # 1) Get AssLauncher::Api helper
        extend AssLauncher::Api

        # 2) Get wrapper for last version of 1C:Enterprise
        #    which satisfied by version requirement
        external_connection = ole(:external, '~> 8.3.0')

        # 3) Open connection
        begin
          external_connection.__open__ 'connection_string'
        rescue
        end

        # 4) Close connection
        external_connection.__close__
      end
    end
  end
end
