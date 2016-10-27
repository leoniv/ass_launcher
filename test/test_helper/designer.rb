module TestHelper
  module Designer
    module Cmd
      require 'clamp'
      require 'ass_launcher'
      class Main < Clamp::Command
        def self.banner
          '1C designer wrapper'
        end

        class Run < Clamp::Command
          include AssLauncher::Api
          option ['-v', '--version'], 'VERSION', 'specify of platform version',
            required: true

          def execute
            conn_str = tmp_ib
            cl.command(:designer) do
              connection_string conn_str
            end.run.wait
          ensure
            rm_ib
          end

          def rm_ib
            FileUtils.rm_r tmp_ib_path if File.exists? tmp_ib_path
          end

          def cl
            @cl ||= cl_get
          end

          def cl_get
            r = thicks(version).last
            signal_usage_error "Platform version `#{version}' not found" if r.nil?
            r
          end

          def tmp_ib
            rm_ib
            conn_str = cs_file(:file => tmp_ib_path)
            process_holder = cl.command(:createinfobase) do
              connection_string conn_str
            end.run.wait
            process_holder.result.verify!
            conn_str
          end

          def tmp_ib_path
            @tmp_ib_path ||= File.join(Dir.tmpdir, ib_dir_mame)
          end

          def ib_dir_mame
            "#{self.class.name.gsub('::','-')}(#{version})"
          end
        end

        class Platforms < Clamp::Command
          include AssLauncher::Api
          def execute
            $stdout.puts thicks.map {|c| c.version}.sort.join("\n")
          end
        end

        subcommand 'run', 'run of designer', Run
        subcommand 'platforms', 'show list of instaled platforms', Platforms
      end
    end
  end
end
