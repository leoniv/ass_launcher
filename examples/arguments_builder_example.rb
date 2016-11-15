require 'example_helper'

module Examples
  module ArgumentsBuilder

    # 1C:Enterprise doesn't check CLI parameters and their arguments
    # it may be cause of some problems when automation script writing
    #
    # AssLauncher provides feature for check CLI parameters.
    # Feature consists of two parts:
    # 1) CLI specifications which describe 1C:Enterprise CLI interface
    # 2) Arguments builder which uses CLI specifications for checking CLI
    #    parameters when we building command or location for running 1C clients

    describe '1C:Enterprise CLI specifications' do
      it 'AssLauncher defines specifications for 1C:Enterprise CLI interface' do
        AssLauncher::Enterprise::Cli::CliSpec.cli_def.must_equal\
          AssLauncher::Enterprise::CliDef
      end

      it 'Defined CLI specifications have CLI parameters collection' do
        AssLauncher::Enterprise::Cli::CliSpec.cli_def.parameters\
          .must_be_instance_of\
           AssLauncher::Enterprise::Cli::Parameters::AllParameters
      end

      it 'CLI parameter defined for client type, version and run mode' do
        parameter = AssLauncher::Enterprise::Cli::CliSpec.cli_def\
          .parameters.find('/F', nil)[0]

        # Parameter define for thick client in :enterprise mode
        parameter.match?(CLIENTS::THICK, :enterprise).must_equal true

        # Parameter doesn't defined for webclient
        parameter.match?(CLIENTS::WEB, :webclient).must_equal false
      end

      it "All client's wrappers know self CLI specifications" do
        CLIENTS::THICK.cli_spec.must_be_instance_of\
          AssLauncher::Enterprise::Cli::CliSpec

        CLIENTS::THIN.cli_spec.must_be_instance_of\
          AssLauncher::Enterprise::Cli::CliSpec

        CLIENTS::WEB.cli_spec.must_be_instance_of\
          AssLauncher::Enterprise::Cli::CliSpec
      end

      it 'CliSpec have collection of CLI parameters which depended of run mode' do
        CLIENTS::THICK.cli_spec.parameters(:designer).find('/CheckModules', nil)\
          .must_be_instance_of\
            AssLauncher::Enterprise::Cli::Parameters::Flag

        CLIENTS::THICK.cli_spec.parameters(:enterprise).find('/CheckModules', nil)\
          .must_be_nil
      end
    end

    describe AssLauncher::Enterprise::Cli::ArgumentsBuilder do
      # ArgumentsBuilder generate DSL for defined CLI cpecs
      it 'When we build command or location we can use ArgumentsBuilder' do

        command = CLIENTS::THICK.command(:designer) do
          connection_string TMP::EMPTY_IB_CS
          checkModules do
            _Server
            _ThinClient
          end
        end

        command.args.join(', ').must_match\
          %r{DESIGNER, /F, (.+), /CheckModules, , -Server, , -ThinClient}
      end

      # ArgumentsBuilder generates DSL which accepts case insensetive methods
      # and methods with underscore prefix for separate uppercased method
      # from the Ruby constant
      it 'ArgumentsBuilder accepts DSL methods called as parameters name' do

        proc {
          CLIENTS::THIN.command do
            DebuggerURL
          end
        }.must_raise NameError

        args_1 = CLIENTS::THIN.command do
          _DebuggerUrl 'http://example.org'
        end.args.join(', ')

        args_2 = CLIENTS::THIN.command do
          debuggerUrl 'http://example.org'
        end.args.join(', ')

        # This example with () looks ugly
        args_3 = CLIENTS::THIN.command do
          DebuggerUrl('http://example.org')
        end.args.join(', ')

        # In all three cases arguments is equal
        args_1.must_match %r{ENTERPRISE, /DebuggerURL, http://example\.org}
        args_2.must_match %r{ENTERPRISE, /DebuggerURL, http://example\.org}
        args_3.must_match %r{ENTERPRISE, /DebuggerURL, http://example\.org}
      end

      it 'ArgumentsBuilder have static DSL method #connection_string' do
        args = CLIENTS::THIN.command do
          connection_string TMP::EMPTY_IB_CS
        end.args.join(', ')

        args.must_match %r{ENTERPRISE, /F, (.+)}
      end

      it 'ArgumentsBuilder fail if parameter not defined' do
        e = proc {
          CLIENTS::WEB.location do
            _BadParameter
          end
        }.must_raise AssLauncher::Enterprise::Cli::ArgumentsBuilder::BuildError

        e.message.must_match %r{CLI parameter `/BadParameter' not definded .+}

        e = proc {
          CLIENTS::THICK.command(:designer) do
            checkModules do
              _BadSubParameter
            end
          end
        }.must_raise AssLauncher::Enterprise::Cli::ArgumentsBuilder::BuildError

        e.message.must_match %r{CLI parameter `-BadSubParameter' not definded .+}
      end

      it 'ArgumentsBuilder check CLI parameter arguments' do
        e = proc {
          CLIENTS::THIN.command do
            _O 'Bad value'
          end
        }.must_raise ArgumentError

        e.message.must_equal 'Wrong value `Bad value\' for /O parameter'

        args = CLIENTS::THIN.command do
          _O :Low
        end.args.join(', ')

        args.must_match %r{ENTERPRISE, /O, Low}
      end
    end
  end
end
