require 'example_helper'

module Examples
  module TroublesWithCreateFileinfobase
    describe "CREATEINFOBASE doesn't check self argument for valid connection string" do
      extend AssLauncher::Api
      # 1C:Enterprise thick client runned in CREATEINFOBASE mode
      # not veryfies self argument for valid connection string and
      # creates default infobase in user profile directory.
      # It's buf or feature? I'm suppose it's bug.
      conns = cs_file file: File.join(Dir.tmpdir, 'create_default_infobase.ib')

      it 'Creates default infobase in user profile' do
        command = CLIENTS::THICK.command :createinfobase do
          connection_string conns
        end

        command.args.insert(1, '/L','en')

        command.args[0].must_equal 'CREATEINFOBASE'
        # Argument for CREATEINFOBASE is /L
        command.args[1].must_equal '/L'
        command.args[2].must_equal 'en'
        # Nex is connection string
        command.args[3].must_equal conns.createinfobase_args[0]

        skip unless TROUBLES_EXECUTE_CONTROL::SHOW_TROBLES_WITH_CREATEINFOBASE
        command.run.wait

        # Infobase which we want not exists
        File.exists?(conns.file).must_equal false

        # But created infobase which we don't want
        command.process_holder.result.success?.must_equal true
        command.process_holder.result.assout =~\
          /Creation of infobase \("File\s?=\s?"([^"]+)/i
        created = Regexp.last_match[1]
        created.must_match(/InfoBase\D?/i)

        File.exists?(created).must_equal true
      end

      it 'Creates infobase which we want' do
        command = CLIENTS::THICK.command :createinfobase do
          connection_string conns
          _L 'en'
        end

        command.args[0].must_equal 'CREATEINFOBASE'
        # Argument for CREATEINFOBASE is connection string
        command.args[1].must_equal conns.createinfobase_args[0]
        # Nex is other
        command.args[2].must_equal '/L'
        command.args[3].must_equal 'en'

        command.run.wait

        # Created infobase which we want
        command.process_holder.result.success?.must_equal true
        command.process_holder.result.assout =~\
          /Creation of infobase \("File\s?=\s?'([^']+)/i
        created = Regexp.last_match[1]
        command.args[1].must_include created
        File.exists?(conns.file).must_equal true
      end

      after do
        FileUtils.rm_rf conns.file if File.exists? conns.file
      end

      describe 'Solution with AssLauncher' do
        it 'ThckClient verifies of argument for CREATEINFOBASE mode' do
          e = proc {
              CLIENTS::THICK.command(:createinfobase, ['bad connection srtring'])
           }.must_raise ArgumentError
          e.message.must_match(
            /:createinfobase expects file or server connection string/i
          )
        end
      end
    end

    describe 'CREATEINFOBASE fails if file connection string having double quote' do
      infobasedir = File.join(Dir.tmpdir,
                              'example_connection_string_with_double_quote.ib')
      infobasedir = AssLauncher::Support::Platforms\
        .path(infobasedir).win_string

      before do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end

      it "Fails if connection string double quoted" do
        conns = "File=\"#{infobasedir}\""

        # Path like C:\tempdir\infobase
        infobasedir.wont_match(/\//)
        # Double quoted path
        conns.must_match(/File="(.+)"/i)

        command = CLIENTS::THICK.command :createinfobase,
          [conns, '/L', 'en']

        command.run.wait

        command.process_holder.result.exitstatus.wont_equal 0
        command.process_holder.result.assout.must_match(
          /Invalid path to file '1Cv8\.cdn'/i)
      end

      it 'Solution with ConnectionString::File' do
        # ConnectionString::File converts connection string
        # for CREATEINFOBASE mode from double quoted:
        # 'File="pat";' to single quoted: "File='path';" string
        extend AssLauncher::Api
        conns = cs("File=\"#{infobasedir}\"")
        # Like File='path'
        conns.createinfobase_args[0].must_match(/File\s?=\s?'[^']+/)

        command = CLIENTS::THICK.command :createinfobase,
          conns.createinfobase_args + ['/L', 'en']

        command.run.wait

        # Created infobase which we want
        command.process_holder.result.success?.must_equal true
        command.process_holder.result.assout =~\
          /Creation of infobase \("File\s?=\s?'([^']+)/i
        created = Regexp.last_match[1]

        conns.file.must_equal created
        File.exists?(conns.file).must_equal true
      end

      after do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end
    end

    describe "CREATEINFOBASE doesn't understand paths with right slashes" do
      # This case doesn't actual in Linux

      infobasedir = File.join(Dir.tmpdir,
                              'example_create_infobase_with_right_slashes.ib')

      before do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end

      describe 'Using single quote in connection string' do
        conns = "File=\'#{infobasedir}\'"

        it 'Fails CREATEINFOBASE' do
          skip 'Not actual in Linux' if PLATFORM::LINUX

          command = CLIENTS::THICK.command :createinfobase,
            [conns, '/L', 'en']

          command.run.wait

          command.process_holder.result.success?.must_equal false
          command.process_holder.result.assout.must_match(
            /Invalid or missing parameters for connection to the Infobase/i)
        end
      end

      describe 'Using double quote in connection string' do
        conns = "File=\"#{infobasedir}\""

        it 'Infobase is created not where you need' do
          skip 'Not actual in Linux' if PLATFORM::LINUX
          # Path like C:/tempdir/infobase
          infobasedir.wont_match(/\\/)

          command = CLIENTS::THICK.command :createinfobase,
            [conns, '/L', 'en']

          # This command creates or finds existing infobase files like 1Cv8.1CD
          # in a root of the file system.
          # On the machine where i'm writing this test, infobase was
          # created in root of drive C:!!!
          skip unless TROUBLES_EXECUTE_CONTROL::SHOW_TROBLES_WITH_CREATEINFOBASE
          command.run.wait

          # Exit status and assout:
          if command.process_holder.result.exitstatus == 0
            # First run test: created new infobase in root filesystem
            command.process_holder.result.assout.must_match(
              /Creation of infobase \("File=\\;.+\) completed successfully/i)
          else
            # Next runs test: found infobase files in root the file system
            command.process_holder.result.assout.must_match(
              /The Infobase specified already exists/i)
          end

          # Realy infobase not exists
          File.exists?(infobasedir).must_equal false
        end
      end

      after do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end
    end

    describe "CREATEINFOBASE doesn't understand relative paths beginning from `..'" do
      require 'pathname'
      infobasedir = File.join('..',
                              'trouble_not_undersnant_relative_path.ib',
                              )
      infobasedir = infobasedir.gsub('/','\\')\

      describe 'Using single quoted connection string' do
        it 'Infobase is created not where you need' do
          conns = "File='#{infobasedir}'"
          Pathname.new(infobasedir).relative?.must_equal true

          command = CLIENTS::THICK.command :createinfobase,
            [conns, '/L', 'en']

          skip unless TROUBLES_EXECUTE_CONTROL::SHOW_TROBLES_WITH_CREATEINFOBASE

          # This command creates or finds existing infobase
          # in a current directory not a parent!.
          command.run.wait

          # Exit status and assout:
          if command.process_holder.result.exitstatus == 0
            # First run test: created new infobase in the current directory
            command.process_holder.result.assout.must_match(
              /Creation of infobase \("File='\.\.\\trouble_.+\) \S+ successfully/i)
          else
            # Next runs test: found infobase files in the current directory
            command.process_holder.result.assout.must_match(
              /The Infobase specified already exists/i)
          end

          # Realy infobase not exists
          File.exists?(infobasedir).must_equal false
          # Infobase created in the current directory created
          File.exists?(infobasedir.gsub('..','.')).must_equal true

        end
      end

      describe 'Using double quoted connection string' do
        it "Fails if connection string double quoted" do
          conns = "File=\"#{infobasedir}\""
          Pathname.new(infobasedir).relative?.must_equal true

          command = CLIENTS::THICK.command :createinfobase,
            [conns, '/L', 'en']

          command.run.wait

          command.process_holder.result.exitstatus.wont_equal 0
          command.process_holder.result.assout.must_match(
            /Invalid path to file '1Cv8\.cdn'/i)
        end
      end

      it 'Solution with ConnectionString::File' do
        require 'pathname'
        extend AssLauncher::Api
        # ConnectionString::File converts relative path
        # to absolute for CREATEINFOBASE argument

        conns = cs_file file: infobasedir
        Pathname.new(conns.file).relative?.must_equal true

        newcs = cs(conns.createinfobase_args[0].tr('\'','"'))

        Pathname.new(newcs.file).absolute?.must_equal true
      end

      after do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end
    end

    describe "CREATEINFOBASE doesn't understand paths having `-'" do
      extend AssLauncher::Support::Platforms
      root = FileUtils.mkdir_p(File.join(Dir.tmpdir,'trouble-create-infobase'))[0]

      infobasedir = File.join(root, 'tmp.ib')
      infobasedir = AssLauncher::Support::Platforms\
        .path(infobasedir).win_string

      describe 'Using single quoted connection' do
        it 'Fails CREATEINFOBASE' do
          extend AssLauncher::Api

          File.exists?(root).must_equal true
          conns = cs_file file: infobasedir

          command = CLIENTS::THICK.command :createinfobase,
            conns.createinfobase_args + ['/L', 'en']

          command.run.wait

          command.process_holder.result.success?.must_equal false
          command.process_holder.result.assout.must_match(
            /Invalid or missing parameters for connection to the Infobase/i)
        end
      end

      describe 'Using double quoted connection string' do
        it 'Infobase is created not where you need' do
          File.exists?(root).must_equal true
          conns = "File=\"#{infobasedir}\""

          command = CLIENTS::THICK.command :createinfobase,
            [conns, '/L', 'en']

          # This command creates or finds existng infobase files like 1Cv8.1CD
          # in a root of the file system.
          # On the machine where i'm writing this test, infobase was
          # created in root of drive C:!!!
          skip unless TROUBLES_EXECUTE_CONTROL::SHOW_TROBLES_WITH_CREATEINFOBASE
          command.run.wait

          # Exit status and assout:
          if command.process_holder.result.exitstatus == 0
            # First run test: created new infobase in root filesystem
            command.process_holder.result.assout.must_match(
              /Creation of infobase \("File=\\;.+\) completed successfully/i)
          else
            # Next runs test: found infobase files in root of the file system
            command.process_holder.result.assout.must_match(
              /The Infobase specified already exists/i)
          end

          # Realy infobase not exists
          File.exists?(infobasedir).must_equal false
        end
      end

      before do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end

      after do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end
    end

    describe "CREATEINFOBASE doesn't understand paths having spaces" do
      extend AssLauncher::Support::Platforms
      root = FileUtils.mkdir_p(File.join(Dir.tmpdir,'trouble create infobase'))[0]

      infobasedir = File.join(root, 'tmp.ib')
      infobasedir = AssLauncher::Support::Platforms\
        .path(infobasedir).win_string

      it 'Solution with ConnectionString::File' do
        extend AssLauncher::Api

        File.exists?(root).must_equal true
        # ConnectionString::File converts connection string
        # for CREATEINFOBASE mode from double quoted:
        # 'File="pat";' to single quoted: "File='path';" string
        conns = cs_file file: infobasedir

        command = CLIENTS::THICK.command :createinfobase,
          conns.createinfobase_args + ['/L', 'en']

        command.run.wait

        # Created infobase which we want
        command.process_holder.result.success?.must_equal true
        command.process_holder.result.assout =~\
          /Creation of infobase \("File\s?=\s?'([^']+)/i
        created = Regexp.last_match[1]

        conns.file.must_equal created
        File.exists?(conns.file).must_equal true
      end

      describe 'Using double quoted connection string' do
        it 'Fails CREATEINFOBASE' do
          File.exists?(root).must_equal true
          conns = "File=\"#{infobasedir}\""

          command = CLIENTS::THICK.command :createinfobase,
            [conns, '/L', 'en']

          # This command creates or finds existng infobase files like 1Cv8.1CD
          # in a root of the file system.
          # On the machine where i'm writing this test, infobase was
          # created in root of drive C:!!!
          command.run.wait

          command.process_holder.result.success?.must_equal false
          command.process_holder.result.assout.must_match(
            /Invalid or missing parameters for connection to the Infobase/i)
        end
      end

      before do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end

      after do
        FileUtils.rm_rf infobasedir if File.exists? infobasedir
      end
    end
  end
end
