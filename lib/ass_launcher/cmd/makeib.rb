module AssLauncher
  module Cmd
    class Main
      module SubCommands
        # @api private
        class MakeIb < Abstract::SubCommand
          include Abstract::Parameter::IB_PATH_NAME
          include Abstract::Option::Dbms
          include Abstract::Option::Dbsrv
          include Abstract::Option::Esrv
          include Abstract::Option::Pattern
          include Abstract::Option::Version
          include Abstract::Option::DryRun
          include Abstract::Option::SearchPath
          include Abstract::Option::Arch
          include Abstract::BinaryWrapper

          def self.command_name
            'makeib'
          end

          def self._banner
            'Make new information base'
          end

          # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
          def connection_string
            return cs_file(file: ib_path) if dbms == 'File'
            cs = cs_srv(srvr: esrv_host, ref: ib_path)
            cs.dbms = dbms
            cs.dbsrvr = dbsrv_host
            cs.db = ib_path
            cs.dbuid = dbsrv_user
            cs.dbpwd = dbsrv_pass
            cs.crsqldb = 'Y'
            cs.susr = esrv_user
            cs.spwd = esrv_pass
            cs
          end
          # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

          def make_command
            cs = connection_string
            template = pattern
            binary_wrapper.command(:createinfobase) do
              connection_string cs
              useTemplate template if template
            end
          end

          def execute
            _verify_required_option_ unless dbms =~ %r{^File$}i
            cmd = run_enterprise(make_command)
            puts Colorize.green(cmd.process_holder.result.assout) unless\
              dry_run?
          end

          def _verify_required_option_
            %w{esrv dbsrv}.each do |oname|
              next unless send(oname).to_s.empty?
              opt = self.class.recognised_options.find do |o|
                o.attribute_name == oname
              end
               signal_usage_error Clamp
                 .message(:option_required, :option => opt.switches.first)
            end
          end
        end
      end
    end
  end
end
