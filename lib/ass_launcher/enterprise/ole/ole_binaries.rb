# encoding: utf-8
require 'ass_launcher/enterprise/ole/win32ole'
#
module AssLauncher
  #
  module Enterprise
    #
    module Ole
      # Wrappers fore 1C Enterprise OLE servers
      module OleBinaries
        # @abstract
        class AbstractAssOleBinary
          include AssLauncher::Support::Platforms

          # @return [Gem::Version::Requirement]
          attr_reader :requirement

          # @param requirement [Gem::Version::Requirement] version of 1C Ole
          #  server
          def initialize(requirement)
            fail NotImplementedError, 'WIN32OLE undefined for this machine' if\
              linux?
            @requirement = Gem::Version::Requirement.new(requirement)
          end

          # @return [WIN32OLE] 1C Ole server object
          def ole
            @ole ||= new_ole
          end

          def new_ole
            reg
            WIN32OLE.new(prog_id)
          end
          private :new_ole

          def v8x
            instaled_version.to_s.split('.').slice(0, 2).join('')
          end
          private :v8x

          def instaled_version
            return binary_wrapper.version if binary_wrapper
          end
          alias_method :version, :instaled_version

          # @return [AssLauncher::Enterprise::BinaryWrapper]
          def binary_wrapper
            @binary_wrapper ||= _binary_wrapper
          end
          protected :binary_wrapper

          def _binary_wrapper
            fail 'Abstract method call'
          end
          private :_binary_wrapper

          def registred_version
            fail NotImplementedError # FIXME: not find object in WinReg
          end
          private :registred_version

          # Return +true+ if 1C Ole object instaled
          def instaled?
            return false unless version
            requirement.satisfied_by?(version) && File.file?(path.to_s)
          end

          def registred?
            # FIXME: always return false and not find object in WinReg
            # registred_version == version
            false # FIXME
          end
          private :registred?

          # Register Ole server
          def reg
            return true if registred?
            fail "Platform version `#{requirement}' not instaled"\
              " for #{arch} Ruby." unless instaled?
            reg_server
          end

          def reg_server
            fail 'Abstract method call'
          end
          private :reg_server

          # Unregister Ole server
          def unreg
            return true unless registred?
            fail "Platform version `#{requirement}' not instaled." unless\
              instaled?
            unreg_server
          end

          def unreg_server
            fail 'Abstract method call'
          end
          private :unreg_server

          def path
            @path ||= _path
          end
          protected :path

          def binary
            fail 'Abstract method call'
          end
          protected :binary

          def _path
            return unless binary_wrapper
            platform.path(File.join(binary_wrapper.path.dirname.to_s, binary))
          end
          private :_path

          def clsid
            clsids[v8x]
          end
          protected :clsid

          def clsids
            fail 'Abstract method call'
          end
          protected :clsids

          # Ruby for x32 architectures
          X32_ARCHS = ['i386-mingw32', 'i386-cygwin']

          def arch
            RbConfig::CONFIG['arch']
          end

          def x32_arch?
            X32_ARCHS.include? arch
          end

          def ruby_x86_64?
            !x32_arch?
          end
        end

        # Wrapper for v8x.COMConnector inproc OLE server
        # @note It work not correct. If old version ole object is loded in
        # memory new registred version will be ignored.
        class COMConnector < AbstractAssOleBinary
          require 'English'
          BINARY = 'comcntr.dll'

          # (see AbstractAssOleBinary#initialize)
          def initialize(requirement)
            super requirement
            fail "v8x.COMConnector is unstable in #{arch} Ruby" unless\
              x32_arch?
          end

          def binary
            BINARY
          end
          private :binary

          def prog_id
            "v#{v8x}.COMConnector"
          end
          private :prog_id

          def clsids
            { '83' => '{181E893D-73A4-4722-B61D-D604B3D67D47}',
              '82' => '{2B0C1632-A199-4350-AA2D-2AEE3D2D573A}',
              '81' => '{48EE4DBA-DE11-4af2-83B9-1F7FD6B6B3E3}'
            }
          end
          private :clsids

          def _binary_wrapper
            Enterprise.thick_clients(requirement.to_s).select do |bw|
              bw.x86_64? == ruby_x86_64?
            end.sort.last
          end
          private :_binary_wrapper

          # @note It work not correct. If old version ole object is loded in
          # memory new registred version will be ignored.
          def reg_server
            fail_reg_unreg_server('register', reg_unreg_server('i'))
          end
          private :reg_server

          def unreg_server
            fail_reg_unreg_server('unregister', reg_unreg_server('u'))
          end
          private :unreg_server

          def reg_unreg_server(mode)
            `regsvr32 /#{mode} /s "#{path.win_string}"`
            childe_status
          end
          private :reg_unreg_server

          def childe_status
            $CHILD_STATUS
          end
          private :childe_status

          def fail_reg_unreg_server(message, status)
            fail "Failure #{message} `#{path.win_string}' #{status}" unless\
              status.success?
            status
          end
          private :fail_reg_unreg_server
        end

        # Wrapper for v8x.Application standalone OLE server
        class ThickApplication < AbstractAssOleBinary
          BINARY = '1cv8.exe'
          def binary
            BINARY
          end
          private :binary

          def prog_id
            "v#{v8x}.Application"
          end
          private :prog_id

          def _binary_wrapper
            Enterprise.thick_clients(requirement.to_s).select do |bw|
              bw.x86_64? == ruby_x86_64?
            end.sort.last
          end
          private :_binary_wrapper

          def reg_server
            run_as_enterprise reg_server_args
          end
          private :reg_server

          def reg_server_args
            r = ['/regserver']
            r << '-currentuser' if version >= Gem::Version.new('8.3.9')
            r
          end
          private :reg_server_args

          def unreg_server
            run_as_enterprise ['/unregserver']
          end
          private :unreg_server

          def run_as_enterprise(args)
            binary_wrapper.command(:enterprise, args)
              .run.wait.result.verify!
          end
          private :run_as_enterprise
        end

        # Wrapper for v8xc.Application standalone OLE server
        class ThinApplication < ThickApplication
          BINARY = '1cv8c.exe'
          def binary
            BINARY
          end
          private :binary

          def prog_id
            "v#{v8x}c.Application"
          end
          private :prog_id

          def _binary_wrapper
            Enterprise.thin_clients(requirement.to_s).select do |bw|
              bw.x86_64? == ruby_x86_64?
            end.sort.last
          end
          private :_binary_wrapper

          def run_as_enterprise(args)
            binary_wrapper.command(args)
              .run.wait.result.verify!
          end
          private :run_as_enterprise
        end
      end
    end
  end
end
