require 'example_helper'

module Examples
  module CreateInfobase
    require 'ass_launcher'

    describe 'Create new 1C:Enterprise application aka "information base"' do
      extend AssLauncher::Api

      # Get 1C:Enterprise binary wrapper or fail
      binary = thicks(PLATFORM_VER).last
      fail "Enterprise v #{PLATFORM_VER} not installed" if binary.nil?

      # Build connection string for new infobase.
      # In this case uses file 1C:Enterprise application type but
      # we can create infobase on 1C:Enterprise server. For it we should use
      # Api.cs_srv method which returns server connection string
      conns = cs_file(file: File.join(Dir.tmpdir,'examples.create_infobase.ib'))
      # 1C:Enterprise application Template
      template = Examples::TEMPLATES::CF

      # Build command whith ArgumentsBuilder
      command = binary.command(:createinfobase) do
        connection_string conns
        useTemplate template
        _L 'en'
      end

      # Running and waiting until process executing
      # because it executing in forked process
      process_holder = command.run.wait

      it 'New infobase created whithout errors' do
        # verify execution result
        process_holder.result.verify!
        # 1C:Enterprise application directory really exists
        File.directory?(conns.file).must_equal true
      end

      after do
        FileUtils.rm_rf conns.file if File.exists?(conns.file)
      end
    end
  end
end
