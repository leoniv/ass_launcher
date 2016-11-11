require 'example_helper'

module Examples
  module TroublesWithRunning1C
    describe '1C:Enterprise show stupid GUI' do
      # In this cases 1C:Enterprise open GUI dialog.
      # Such stupid 1C:Enerprise behavior made difficult to run 1C:Enterprise
      # without human watching

      # For show dialogs set $SHOW_STUPID_GUI

      it 'Thin client show dialog with error message' do
        skip unless TROUBLES_EXECUTE_CONTROL::SHOW_STUPID_GUI
        command = CLIENTS::THIN.command(['/F','bad infobase path', '/L', 'en'])
        # It show error message window
        command.run.wait
        # But 1C:Enterprise process exit with status 0
        command.process_holder.result.success?.must_equal true
      end

      it 'Thick client show dialog with offer for create new infobase' do
        skip unless TROUBLES_EXECUTE_CONTROL::SHOW_STUPID_GUI
        command = CLIENTS::THICK\
          .command(:enterprise, ['/F','bad infobase path', '/L', 'en'])
        # It show GUI dialg with offer create new infobase
        command.run.wait
      end

      it 'Designer show dialg with error message for serevr infobase' do
        skip unless TROUBLES_EXECUTE_CONTROL::SHOW_STUPID_GUI
        designer = CLIENTS::THICK.command :designer do
            _S 'example.org/fake_ib'
            _L 'en'
          end

        # It show GUI
        designer.run.wait
      end

      describe 'Solution. For file infobase only!!!' do
        it 'Arguments builder check existing path for /F parameter' do
          proc {
            CLIENTS::THICK.command(:enterprise) do
              _F 'bad infobase path'
            end
          }.must_raise ArgumentError
        end

        it 'Connection string fails in #to_args method if path not exists' do
          extend AssLauncher::Api
          conns = cs_file file: 'bad infobase path'

          # Call #to_args directly
          proc {
            CLIENTS::THIN.command(conns.to_args)
          }.must_raise Errno::ENOENT

          # Passing connection string into arguments builder
          # have the same effect
          proc {
            CLIENTS::THIN.command do
              connection_string conns
            end
          }.must_raise Errno::ENOENT
        end
      end
    end

    describe '1C:Enterprise ignores mistakes in CLI parameters' do
      # Usually command line apps are checking CLI parameters and
      # exits with non zero status but usually 1C:Enterprise doesn't it

      it 'Pass wrong parameter name /WrongParameter' do
        command = CLIENTS::THICK\
          .command(:designer, ['/F', TMP::EMPTY_IB, '/WrongParameter','']) do
            checkModules do
              thinClient
            end
          end
        command.run.wait.result.exitstatus.must_equal 0
      end

      it 'Pass wrong parameter value' do
        skip unless CLIENTS::THICK.version < Gem::Version.new('8.3.4')
        command = CLIENTS::THICK\
          .command(:designer, ['/F', TMP::EMPTY_IB,
                   '/SetPredefinedDataUpdate','Bad value'
        ])
        command.run.wait.result.exitstatus.must_equal 0
      end

      it 'One of the rare cases when 1C:Enterprise verifies of paramter value' do
        command = CLIENTS::THICK\
          .command(:designer, ['/F', TMP::EMPTY_IB]) do
            checkModules do
              thinClient
              eXtension 'bad value'
            end
          end
        command.run.wait.result.exitstatus.wont_equal 0

        # But doesn't explains cause of error
        command.process_holder.result.assout.must_equal ''
      end

      describe 'Solutions this troubles with arguments builder' do
        it 'Arguments builder fails BuildError if unknown parameter given' do
          proc {
            CLIENTS::THICK\
              .command (:enterprise) do
              uncknownParameter
            end
          }.must_raise AssLauncher::Enterprise::Cli::ArgumentsBuilder::BuildError
        end

        it 'Cli::Parameter instance verifies given value' do
          proc {
            CLIENTS::THICK\
              .command (:designer) do
                setPredefinedDataUpdate 'Bad value'
            end
          }.must_raise ArgumentError

          proc {
            CLIENTS::THICK\
              .command (:enterprise) do
              debuggerURL 'tcp:/baduri'
            end
          }.must_raise ArgumentError
        end
      end
    end

    describe 'Trouble with /C CLI parameter' do
      it 'Transform value if value contains double quote char' do
        source_string = 'Hello "World"'

        enterprise = CLIENTS::THICK\
          .command :enterprise, ['/C', source_string] do
          connection_string TMP::EMPTY_IB_CS
          _Execute TEMPLATES::HELLO_EPF
        end

        enterprise.run.wait
        ret_string = enterprise.process_holder.result.assout.strip

        source_string.wont_equal ret_string
        ret_string.must_equal 'Hello \\'
      end

      it 'Transform value if value contains escaped double quote char' do
        source_string = 'Hello \"World\"'

        enterprise = CLIENTS::THICK\
          .command :enterprise, ['/C', source_string] do
          connection_string TMP::EMPTY_IB_CS
          _Execute TEMPLATES::HELLO_EPF
        end

        enterprise.run.wait
        ret_string = enterprise.process_holder.result.assout.strip

        source_string.wont_equal ret_string
        ret_string.must_equal 'Hello \\\\\\'
      end

      describe 'Solutions' do
        it 'Check value /C parameter with arguments builder' do
          proc {
            CLIENTS::THIN.command do
              _C '"'
            end
          }.must_raise ArgumentError
        end

        it 'Passing value with single quote char' do
          source_string = 'Hello \'World\''

          enterprise = CLIENTS::THICK\
            .command :enterprise do
            _C source_string
            connection_string TMP::EMPTY_IB_CS
            _Debug
            debuggerURL 'tcp://localhost'
            _Execute TEMPLATES::HELLO_EPF
          end

          enterprise.run.wait
          ret_string = enterprise.process_holder.result.assout.strip

          source_string.must_equal ret_string
        end
      end
    end

    describe 'Designer talks "Infobase not found!" but exit with 0 for file infobase' do
      designer = CLIENTS::THICK.command :designer, ['/F','./fake_ib'] do
        _L 'en'
      end

      designer.run.wait

      it 'Exitstatus == 0' do
        designer.process_holder.result.exitstatus.must_equal 0
      end

      it 'Error message in out' do
        designer.process_holder.result.assout.strip.must_equal 'Infobase not found!'
      end
    end
  end
end
