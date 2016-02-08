# encoding: utf-8

module AssLauncher
  module Enterprise
    # TODO: extract into enterprise/run_modes.rb
    module RunModes
      #@api private
      module DefinedArguments
        def self.extented(base)
          raise 'FIXME not implemented'
        end
      end

      class Enterprise
        attr_reader :wrapper
        # @api private
        def initialize(wrapper, connection_string)
          @connection_string = connection_string
          @wrapper = wrapper
          extend DefinedArguments
        end

        def validate_connection_string
          raise 'FIXME'
          #fail ArgumentError "Invalid connection_string #{@connection_string} \
          #  for `#{@wrapper.class}' running in #{self.class}"\
          #  unless @wrapper.accepted_connstr.include?(@connection_string.is)
        end

        def connection_string_to_cmd
          raise 'FIXME'
        end
        private :connection_string_to_cmd

        def to_cmd(args)
          raise 'FIXME'
        end
        private :to_cmd

        # @api puplic
        def run(args)
          @wrapper.dirtyrun(to_cmd(args))
        end
      end #Enterprise

      class CreateInfoBase < RunModes::Enterprise
        def connection_string_to_cmd
          raise 'FIXME'
        end
        private :connection_string_to_cmd

        def to_cmd(args, pkg_mode)
          raise 'FIXME'
        end
        private :to_cmd
      end #CreateInfoBase

      class Designer < RunModes::Enterprise
        def connection_string_to_cmd
          raise 'FIXME'
        end
        private :connection_string_to_cmd

        def to_cmd(args, pkg_mode)
          raise 'FIXME'
        end
        private :to_cmd

        def pkg_command(command, args)
          PackageMode.new(self, command, args)
        end

        def run_pkg(args, pkg_mode)
          raise 'FIXME'
        end
        private :run_pkg

        class PackageMode
          attr_reader :command
          def initialize(designer, command, args)
            @designer = designer
            @wrapper = designer.wrapper
            extend DefinedArguments
          end

          # @api puplic
          def run(args)
            @designer.run_pkg(args, self)
          end
        end #PackageMode
      end #Designer
    end
  end
end
