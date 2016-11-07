require 'example_helper'

module Examples
  module BinaryWrapper
    require 'ass_launcher'

    describe '1C:Enterprise binaries search paths' do

      # AssLauncher searching 1C:Enterprise binaries
      # in default installation paths which depends of
      # operation system
      it 'Array of default search paths' do
        AssLauncher::Enterprise.search_paths.must_be_instance_of Array
        AssLauncher::Enterprise.search_paths.wont_include __FILE__
      end

      # But we can add custom path into searching array
      it 'Array of default search paths include custom path' do
        # Add custom path
        AssLauncher.config.search_path = __FILE__

        AssLauncher::Enterprise.search_paths.must_include __FILE__

        # Reset defauls
        AssLauncher.config.search_path = nil
      end

    end

    describe '1C:Enterprise binary types' do
      extend AssLauncher::Api

      # AssLauncher search two different 1C:Enterprise binary files aka
      # 'thick' and 'thin' clients and returns array of suitable
      # objects sach as BinaryWrapper::Thick and BinaryWrapper::Thin.

      # Get thin clients array Api.thins method
      thin_clients = thins
      # Get thick clients array Api.thicks method
      thick_clients = thicks

      it 'Both method returned Array' do
        thin_clients.must_be_instance_of Array
        thick_clients.must_be_instance_of Array
      end
    end

    describe '1C:Enterprise binary version' do
      extend AssLauncher::Api

      # AssLauncher provides posebility chose of 1C:Enterprise version.
      # For define of required version uses Gem::Version::Requirement
      # string.

      # Get thick clients with version requiremet
      thick_clients = thicks('~> 8.3.8.0')

      it 'Fail if bad Gem::Version::Requirement' do
        proc do
          AssLauncher::Enterprise.thick_clients('bad version string')
        end.must_raise ArgumentError
      end
    end

    describe 'Binary wrappers run modes' do
      # For BinaryWrapper::Thick objects
      # defined run modes such as :enterprise, :designer and :createinfobase
      it 'Run modes for thick client' do
        AssLauncher::Enterprise::BinaryWrapper::ThickClient\
          .run_modes.must_equal [:createinfobase, :enterprise, :designer]
      end

      # For BinaryWrapper::Thin objects
      # defined :enterprise only run mode
      it 'Run modes for thin client' do
        AssLauncher::Enterprise::BinaryWrapper::ThinClient\
          .run_modes.must_equal [:enterprise]
      end
    end

    describe 'Execution thick client' do
      extend AssLauncher::Api

      # Get binary wrapper
      client = thicks(Examples::PLATFORM_VER).last

      # Fail if not 1C:Enterprise instalation found
      fail "1C:Enterprise v.#{Examples::PLATFORM_VER} not found" if client.nil?

      # Build command for necessary run mode 1C:Enterprise
      # using arguments array
      command = client.command(:designer,
                               ['/F','bad infobase path',
                                '/CheckModules','',
                                '-Server','',
                                '/L', 'en'])


      # Run 1C:Enterprise in forked process
      command.run

      # Wait until 1C:Enterprise execution.
      # But we can use 'command.ran.wait' for run and wait together
      process_holder = command.process_holder.wait

      it 'Verify execution result manually' do
        process_holder.result.success?.must_equal false
        process_holder.result.assout.must_match /Infobase not found!/i
      end

      it 'Verify execution result automatically' do
        proc do
          process_holder.result.verify!
        end.must_raise AssLauncher::Support::Shell::RunAssResult::RunAssError
      end
    end

    describe 'Execution thin client' do
      extend AssLauncher::Api

      # Get binary wrapper
      client = thins(Examples::PLATFORM_VER).last

      # Fail if not 1C:Enterprise instalation found
      fail "1C:Enterprise v.#{Examples::PLATFORM_VER} not found" if client.nil?

      # Build command for 1C:Enterprise using arguments array.
      command = client.command( ['/F','bad infobase path',
                                '/CheckModules','',
                                '-Server','',
                                '/L', 'en'])


      # Run 1C:Enterprise in forked process
      process_holder = command.run

      # Working process

      # Kill 1C:Enterprise if no longer used
      process_holder.kill
    end

    describe 'Building commands' do
      extend AssLauncher::Api

      # For building commands we can:
      # 1) passing arguments array directly into command
      # 2) using arguments builder DSL and passing block into command
      # 3) using connection string passed into arguments builder
      # 4) mix all this


      # For more info about arguments builder see source code of
      # class AssLauncher::Enterprise::Cli::ArgumentsBuilder

      # Get binary wrapper
      client = thicks(Examples::PLATFORM_VER).last

      # Fail if not 1C:Enterprise instalation found
      fail "1C:Enterprise v.#{Examples::PLATFORM_VER} not found" if client.nil?

      # Build command for necessary run mode 1C:Enterprise
      # using arguments array
      command_first = client.command(:designer,
                               ['/UC', 'uc value',
                                '/S','example.org/infobase',
                                '/CheckModules','',
                                '-Server','',
                                '/L', 'en'])

      # Build command for necessary run mode 1C:Enterprise
      # using arguments builder and arguments array
      command_second = client.command(:designer, ['/UC', 'uc value']) do
        _S 'example.org/infobase'
        checkModules do
          server
        end
        _L 'en'
      end

      # Build command for necessary run mode 1C:Enterprise
      # using arguments builder and connection string and arguments array
      conns = cs_srv srvr: 'example.org', ref: 'infobase'
      command_third = client.command(:designer, ['/UC', 'uc value']) do
        connection_string conns
        checkModules do
          server
        end
        _L 'en'
      end

      it 'All commands are equal exclude "/OUT" argument value' do
        expected_args = ["DESIGNER",
                         "/UC", "uc value",
                         "/S", "example.org/infobase",
                         "/CheckModules", "",
                         "-Server", "",
                         "/L", "en",
                         "/DisableStartupDialogs", "",
                         "/DisableStartupMessages", "",
                         "/OUT"]
        command_first.args.pop
        command_first.args.must_equal expected_args

        command_second.args.pop
        command_second.args.must_equal expected_args

        command_third.args.pop
        command_third.args.must_equal expected_args
      end
    end
  end
end
