# encoding: utf-8

require 'ffi'

module FFI
  # Monkey patch of [FFI::Platform]
  module Platform
    IS_CYGWIN = is_os('cygwin')

    def self.cygwin?
      IS_CYGWIN
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
    # OS-specific things
    module Platforms
      def cygwin?
        FFI::Platform.cygwin?
      end
      module_function :cygwin?

      def windows?
        FFI::Platform.windows?
      end
      module_function :windows?

      def linux?
        FFI::Platform.linux?
      end
      module_function :linux?

      def platform
        AssLauncher::Support::Platforms
      end

      require 'pathname'

      # Return suitable class
      # @return [UnixPath | WinPath | CygPath]
      def self.path
        if cygwin?
          CygPath
        elsif windows?
          WinPath
        else
          UnixPath
        end
      end

      # Parent for OS-specific *Path class
      # Класс предназначен для унификации работы с путями ФС в различных ОС.
      # ОС зависимые методы будут переопределены в классах потомках [UnixPath WinPath
      # CygPath].
      #
      # Пути в ФС могут приходить из следующих источников:
      # - из консоли - при этом в Cygwin путь вида '/cygdrive/c' бедт непонятен
      #   за пределами Cygwin
      # - из ENV - при этом путь \\host\share будет непонятен в Unix
      #
      # Общая мысль в следующем:
      # - пути приводятся к mixed_path - /cygwin/c -> C:/, C:\ -> C:/,
      #   \\host\share -> //host/share
      # - переопределяется метод glob класса [Pathname] при этом метод в Cygwin
      #   будет иметь свою реализацию т.к. в cygwin Dirname.glob('C:/') вернет
      #   пустой массив, а Dirname.glob('/cygdrive/c') отработает правильно.
      class PathnameExt < Pathname
        # Override constructor for lead path to (#mixed_path)
        # @param string [String] - string of path
        def initialize(string)
          @raw = string.to_s.strip
          super mixed_path(@raw)
        end

        #
        def join(*args)
          self.class.new(super(*args).to_s)
        end

        def parent
          self.class.new(super.to_s)
        end

        # TODO this is fix (bug or featere)? of [Pathname] method. Called in
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

        # Return path suitable for windows apps. In Unix this method overridden
        # @return [String]
        def win_string(string)
          string.tr('/', '\\')
        end

        # Override [Pathname] method for correct work with windows paths like a
        # '\\host\share', 'C:\' and Cygwin paths like a '/cygdrive/c'
        # @param (see Pathname.glob)
        # @return [Array<PathnameExt>]
        def self.glob(p1, *args)
          super mixed_path(p1), *args
        end
      end

      # Class for MinGW Ruby
      class WinPath < PathnameExt; end

      # Class for Unix Ruby
      class UnixPath < PathnameExt
        def win_string(string)
          string
        end
      end

      # Class for Cygwin Ruby
      class CygPath < PathnameExt
        def mixed_path(string)
          `cygpath -m #{string.escape}`.strip
        end

        def self.glob(p1, *args)
          super `cygpath -u #{p1.escape}`.chomp, *args
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
