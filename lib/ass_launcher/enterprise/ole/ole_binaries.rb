# encoding: utf-8

# Monkey patch for WIN32OLE class
# - Define dummy class for Linux. Fail +NotImplementedError+ in constructor.
#
# - Patch for have chanse to close connection with 1C infobase in class
#   {AssLauncher::Enterprise::Ole::IbConnection IBConnector}. For this reason
#   overload
#   method +WIN32OLE#method_missing+ and hold Ole object refs retuned from ole
#   method into {#__objects__} array.
#   {AssLauncher::Enterprise::Ole::IbConnection IBConnector}
#   when close connection call
#   {#\_\_ass_ole_free\_\_} and try to ole_free for all in {#__objects__} array.
# @see AssLauncher::Enterprise::Ole::IbConnection#__close__
class WIN32OLE
  if AssLauncher::Support::Platforms.linux?
    class << self
      define_method(:new) do |*_|
        fail NotImplementedError, 'WIN32OLE undefined for this machine'
      end
    end
  else
    require 'win32ole'
  end

  # Hold created Ole objects
  # @return [Array]
  # @api private
  def __objects__
    @__objects__ ||= []
  end

  # @note WIN32OLE avtomaticaly wrapp Ruby objects into WIN32OLE class
  #  when they passed as parameter.
  #  When passed object retuns on Ruby side he will keep as WIN32OLE
  #
  # True if real object is Ruby object
  def __ruby__?
    ole_respond_to? :object_id
  end

  # @note (see #__ruby__?)
  # Return Ruby object wrapped in to WIN32OLE. If {#__ruby__?} is *false*
  # return *self*
  # @return [Object, self]
  def __real_obj__
    return self unless __ruby__?
    ObjectSpace._id2ref(invoke :object_id)
  end

  # @api private
  # Call ole_free for all created chiled Ole objects then free self
  def __ass_ole_free__
    @__objects__ = __ass_ole_free_objects__
    self.class.__ass_ole_free__(self)
  end

  # Free created chiled Ole objects
  def __ass_ole_free_objects__
    __objects__.each do |o|
      o.send :__ass_ole_free__ if o.is_a? WIN32OLE
    end
    nil
  end
  private :__ass_ole_free_objects__

  # @api private
  # Try call ole_free for ole object
  # @param obj [WIN32OLE] object for free
  def self.__ass_ole_free__(obj)
    return if WIN32OLE.ole_reference_count(obj) <= 0
    obj.ole_free
  end

  # @!method method_missing(*args)
  # @overload {WIN32OLE#method_missing} and hold Ole object into
  # {#__objects__} array if called Ole method return Ole object
  old_method_missing = instance_method(:method_missing)
  define_method(:method_missing) do |*args|
    o = old_method_missing.bind(self).call(*args)
    __objects__ << o if o.is_a? WIN32OLE
    o
  end
end

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
            fail NotImplementedError, 'WIN32OLE undefined for this machine'\
              if linux?
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
            version.to_s.split('.').slice(0, 2).join('')
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
            fail 'FIXME'
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
            fail "Platform version `#{requirement}' not instaled."\
              unless instaled?
            reg_server
          end

          def reg_server
            faisl 'Abstract method call'
          end
          private :reg_server

          # Unregister Ole server
          def unreg
            return true unless registred?
            fail "Platform version `#{requirement}' not instaled."\
              unless instaled?
            unreg_server
          end

          def unreg_server
            faisl 'Abstract method call'
          end
          private :unreg_server

          def path
            @path ||= _path
          end
          protected :path

          def _path
            return unless binary_wrapper
            platform.path(File.join(binary_wrapper.path.dirname.to_s, binary))
          end
          private :_path

          def clsid
            clsids[v8x]
          end
          private :clsid

          def clsids
            fail 'Abstract method call'
          end
          private :clsids
        end

        # Wrapper for v8x.COMConnector inproc OLE server
        # @note It work not correct. If old version ole object is loded in
        # memory new registred version will be ignored.
        class COMConnector < AbstractAssOleBinary
          require 'english'
          BINARY = 'comcntr.dll'
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
            Enterprise.thick_clients(requirement.to_s).last
          end
          private :_binary_wrapper

          # @note It work not correct. If old version ole object is loded in
          # memory new registred version will be ignored.
          def reg_server
            `regsvr32 /i /s "#{path.win_string}"`
            fail "Failure register `#{path.win_string}' #{$CHILD_STATUS}"\
              unless $CHILD_STATUS.success?
          end
          private :reg_server

          def unreg_server
            `regsvr32 /u /s "#{path.win_string}"`
            fail "Failure register `#{path.win_string}' #{$CHILD_STATUS}"\
              unless $CHILD_STATUS.success?
          end
          private :unreg_server
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
            Enterprise.thick_clients(requirement.to_s).last
          end
          private :_binary_wrapper

          def reg_server
            run_as_enterprise ['/regserver']
          end
          private :reg_server

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
            Enterprise.thin_clients(requirement.to_s).last
          end
          private :_binary_wrapper

          def run_as_enterprise(args)
            binary_wrapper.command(args)
              .run.wait.result.verify!
            true
          end
          private :run_as_enterprise
        end
      end
    end
  end
end
