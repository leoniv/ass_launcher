module DevHelper
  module Designer
    module Cmd
      require 'clamp'
      require 'ass_launcher'
      class Main < Clamp::Command
        AssLauncher.config.search_path = ENV['ASSPATH'] if ENV['ASSPATH']
        def self.banner
          "1C designer wrapper.\n"\
          "Current seaching paths of 1C:Enterprise installations:\n"\
          "#{Paths.list}\n"\
          "For add custom search path set env $ASSPATH"
        end

        class Designer < Clamp::Command
          include AssLauncher::Api
          option ['-v', '--version'], 'VERSION', 'specify of platform version',
            required: true

          def cl
            @cl ||= cl_get
          end

          def cl_get
            r = thicks(version).last
            signal_usage_error "Platform version `#{version}' not found" if r.nil?
            r
          end
        end

        module ConnSring
          def self.included(base)
            base.option ['-b', '--info-base'], 'PATH',
              baner(base),
              required: _required(base) do |s|
              @conn_str = cs_file(file: s)
            end
            base.send :attr_reader, :conn_str
          end

          def self._required(base)
            base.respond_to? :conn_str_required?
          end

          def self.baner(base)
            r = 'specify infobase path.'
            r << ' If not specify it will make tmp infobase' unless\
              _required(base)
            r
          end
        end

        class Run < Designer
          include ConnSring
          option ['-a', '--args'], '["ARG", "VAL" ...]',
            'specify designer cmd arguments like Ruby Array' do |s|
            @args = eval(s)
            fail ArgumentError,
              'specify designer cmd arguments like Ruby Array' unless\
              @args.is_a? Array
            @args
          end

          def execute
            conn_str_ = conn_str || tmp_ib
            args_ = args || []
            cl.command(:designer, args_) do
              connection_string conn_str_
            end.run.wait.result.verify!
          ensure
            rm_tmp_ib
          end

          def rm_tmp_ib
             FileUtils.rm_r tmp_ib_path if File.exists? tmp_ib_path
          end

          def tmp_ib
            rm_tmp_ib
            conn_str_ = cs_file(:file => tmp_ib_path)
            process_holder = cl.command(:createinfobase) do
              connection_string conn_str_
            end.run.wait
            process_holder.result.verify!
            conn_str_
          end

          def tmp_ib_path
            @tmp_ib_path ||= File.join(Dir.tmpdir, ib_dir_mame)
          end

          def ib_dir_mame
            "#{self.class.name.gsub('::','-')}(#{version})"
          end
        end

        class CreateInfobase < Designer

          def self.conn_str_required?
            true
          end

          include ConnSring

          option ['-t', '--template'], 'PATH[.cf|.dt]',
            'Create infobase from template' do |s|
            @template = s
          end

          def execute
            $stdout.puts "Success make ib: `#{make_infobase}'"
          end

          def make_infobase
            conn_str_ = conn_str
            template_ = template
            cl.command(:createinfobase) do
              connection_string conn_str_
              useTemplate template_ if template_
            end.run.wait.result.verify!
            conn_str_
          end

        end

        class Platforms < Clamp::Command
          include AssLauncher::Api
          def execute
            $stdout.puts paths
            $stdout.puts thicks_list
            $stdout.puts thins_list
          end

          def paths
            "Search paths:\n"\
            "#{Paths.list}"
          end

          def thicks_list
            "thik clients:\n"\
            "#{list(thicks)}"
          end

          def thins_list
            "thin clients:\n"\
            "#{list(thins)}"
          end

          def list(clients)
            " * #{clients.map {|c| c.version}.sort.join("\n * ")}"
          end
        end

        class Paths < Clamp::Command
          def self.list
            " * #{AssLauncher::Enterprise.search_paths.join("\n * ")}"
          end

          def execute
            $stdout.puts self.class.list
          end
        end

        subcommand 'run', 'run of designer', Run
        subcommand 'createinfobase', 'create file infrmation base', CreateInfobase
        subcommand 'platforms', 'show list of instaled platforms', Platforms
        subcommand 'search-paths', 'show search paths of 1C:Enterprise'\
          ' installations', Paths
      end
    end
  end
end
