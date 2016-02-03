# encoding: utf-8

require 'ffi'

module FFI
  # Monkey patch of [FFI::Platform]
  module Platform
    IS_CYGWIN = is_os('cygwin')

    def self.cygwin?
      IS_CYGWIN
    end

    def self.linux?
      IS_LINUX
    end
  end
end

# Monkey patch for [String]
class String
  require 'shellwords'
  def escape
    Shellwords.escape self
  end
end

module AssLauncher
  module Support
    # TODO, extract into 'support/shell.rb'
    module Shell
      # Raises when shell exitststus != 0
      class RunError < StandardError; end
      # Raises when other error given
      class Error < StandardError; end
    end
    # OS-specific things
    # Mixin module help work with things as paths and env in other plases
    # @example
    #  include AssLauncher::Support::Platforms
    #
    #  if cigwin?
    #    #do if run in Cygwin
    #  end
    #
    #  # Find env value on regex
    #  pf = platform.env[/program\s*files/i]
    #  return if pf.size == 0
    #
    #  # Use #path
    #  p = platform.path(pf[0])
    #  p.exists?
    #
    #  # Use #path_class
    #  platform.path_class.glob('C:/*').each do |path|
    #    path.exists?
    #  end
    #
    #  # Use #glob directly
    #  platform.glob('C:/*').each do |path|
    #    path.exists?
    #  end
    #
    #
    module Platforms
      # True if run in Cygwin
      def cygwin?
        FFI::Platform.cygwin?
      end
      module_function :cygwin?

      # True if run in MinGW
      def windows?
        FFI::Platform.windows?
      end
      module_function :windows?

      # True if run in Linux
      def linux?
        FFI::Platform.linux?
      end
      module_function :linux?

      # Return module [Platforms] as helper
      # @return [Platforms]
      def platform
        AssLauncher::Support::Platforms
      end

      require 'pathname'

      # Return suitable class
      # @return [UnixPath | WinPath | CygPath]
      def self.path_class
        if cygwin?
          PathnameExt::CygPath
        elsif windows?
          PathnameExt::WinPath
        else
          PathnameExt::UnixPath
        end
      end

      # Return suitable class instance
      # @return [UnixPath | WinPath | CygPath]
      def self.path(string)
        path_class.new(string)
      end

      # (see PathnameExt.glob)
      def self.glob(p1, *args)
        path_class.glob(p1, *args)
      end

      # Parent for OS-specific *Path classes
      # @todo TRANSLATE THIS:
      #
      # rubocop:disable AsciiComments
      # @note
      #  Класс предназначен для унификации работы с путями ФС в различных
      #  ОС.
      #  ОС зависимые методы будут переопределены в классах потомках
      #  [UnixPath | WinPath | CygPath].
      #
      #  Пути могут приходить из следующих источников:
      #  - из консоли - при этом в Cygwin путь вида '/cygdrive/c' будет
      #    непонятен за пределами Cygwin
      #  - из ENV - при этом путь \\\\host\\share будет непонятен в Unix
      #
      #  Общая мысль в следующем:
      #  - пути приводятся к mixed_path - /cygwin/c -> C:/, C:\\ -> C:/,
      #    \\\\host\\share -> //host/share
      #  - переопределяется метод glob класса [Pathname] при этом метод в
      #    Cygwin будет иметь свою реализацию т.к. в cygwin
      #    Dirname.glob('C:/') вернет пустой массив,
      #    а Dirname.glob('/cygdrive/c') отработает правильно.
      # rubocop:enable AsciiComments
      class PathnameExt < Pathname
        # Override constructor for lead path to (#mixed_path)
        # @param string [String] - string of path
        def initialize(string)
          @raw = string.to_s.strip
          super mixed_path(@raw)
        end

        # This is fix (bug or featere)? of [Pathname] method. Called in
        # chiled clesses returns not childe class instance but returns
        # [Pathname] instance
        def +(other)
          self.class.new(super(other).to_s)
        end

        # Return mixed_path where delimiter is '/'
        # @return [String]
        def mixed_path(string)
          string.tr('\\', '/')
        end
        private :mixed_path

        # Return path suitable for windows apps. In Unix this method overridden
        # @return [String]
        def win_string
          to_s.tr('/', '\\')
        end

        # Override (Pathname.glob) method for correct work with windows paths
        # like a '\\\\host\\share', 'C:\\' and Cygwin paths like a '/cygdrive/c'
        # @param (see Pathname.glob)
        # @return [Array<PathnameExt>]
        def self.glob(p1, *args)
          super p1.tr('\\', '/'), *args
        end

        # Class for MinGW Ruby
        class WinPath < PathnameExt; end

        # Class for Unix Ruby
        class UnixPath < PathnameExt
          # (see PathnameExt#win_string)
          def win_string
            to_s
          end
        end

        # Class for Cygwin Ruby
        class CygPath < PathnameExt
          # (cee PathnameExt#mixed_path)
          def mixed_path(string)
            cygpath(string, :m)
          end

          # (see PathnameExt.glob)
          def self.glob(p1, *args)
            super cygpath(p1, :u), *args
          end

          def self.cygpath(p1, flag)
            fail ArgumentError, 'Only accepts :w | :m | :u flags'\
              unless %i(w m u).include? flag
            # TODO, extract shell call into Shell module
            out = `cygpath -#{flag} #{p1.escape} 2>&1`.chomp
            fail Shell::RunError, out unless exitstatus == 0
            out
          end

          # TODO, extract shell call into Shell module
          def self.exitstatus
            # rubocop:disable all
            fail Shell::Error, 'Unexpected $?.nil?' if $?.nil?
            $?.exitstatus
            # rubocop:enable all
          end
          private_class_method :exitstatus

          def cygpath(p1, flag)
            self.class.cygpath(p1, flag)
          end
        end
      end

      # Return suitable class
      # @return [UnixEnv | WinEnv | CygEnv]
      def self.env
        if cygwin?
          CygEnv
        elsif windows?
          WinEnv
        else
          UnixEnv
        end
      end

      # Wrapper for ENV in Unix Ruby
      class UnixEnv
        # Return values ENV on regex
        def self.[](regex)
          ENV.map { |k, v| v if k =~ regex }.compact
        end
      end
      # Wrapper for ENV in Cygwin Ruby
      class CygEnv < UnixEnv; end
      # Wrapper for ENV in MinGw Ruby
      class WinEnv < UnixEnv; end
    end
  end
end
