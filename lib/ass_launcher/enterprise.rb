# encoding: utf-8

module AssLauncher
  #
  class Configuration
    # Path for search 1C binaries
    attr_accessor :search_path
  end
  # 1C:Entrprise platform abstraction layer
  module Enterprise
    require 'ass_launcher/enterprise/binary_wrapper'
    require 'ass_launcher/enterprise/web_client'
    require 'ass_launcher/enterprise/ole'

    extend AssLauncher::Support::Platforms

    WIN_BINARIES = { BinaryWrapper::ThinClient => '1cv8c.exe',
                     BinaryWrapper::ThickClient => '1cv8.exe'
    }.freeze
    LINUX_BINARIES = { BinaryWrapper::ThinClient => '1cv8c',
                       BinaryWrapper::ThickClient => '1cv8'
    }.freeze
    def self.windows_or_cygwin?
      platform.cygwin? || platform.windows?
    end
    private_class_method :windows_or_cygwin?

    def self.linux?
      platform.linux?
    end
    private_class_method :linux?

    # Return paths for searching instaled 1C platform
    # @note
    #  - For Windows return value of 'Program Files' env.
    #  - For Linux return '/opt/1C'
    #  - In both cases you can set {AssLauncher::Configuration#search_path} and
    #    it will be added into array
    # @return [Array<String>
    def self.search_paths
      sp = []
      sp << AssLauncher.config.search_path
      if windows_or_cygwin?
        sp += platform.env[/\Aprogram\s*(files.*|W6432)/i].uniq.map { |pf| "#{pf}/1c*" }
      elsif linux?
        sp += %w(/opt/1C /opt/1c)
      end
      sp.compact.uniq
    end

    # @api private
    def self.binaries(klass)
      if windows_or_cygwin?
        WIN_BINARIES[klass]
      elsif linux?
        LINUX_BINARIES[klass]
      end
    end

    # Caching {BinaryWrapper} instances
    # @api private
    # @return [Hash]
    def self.binary_wrappers_cache
      @binary_wrappers_cache ||= {}
    end

    def self.find_clients(klass)
      find_binaries(binaries(klass)).map do |binpath|
        if binary_wrappers_cache.key?(binpath)
          binary_wrappers_cache[binpath]
        else
          binary_wrappers_cache[binpath] = klass.new(binpath)
        end
      end
    end
    private_class_method :find_clients

    def self.requiremet?(client, requiremet)
      return true if requiremet.empty?
      Gem::Requirement.new(requiremet).satisfied_by? client.version
    end
    private_class_method :requiremet?

    # Return array of wrappers for 1C thin client executables
    # found in {.search_paths}
    # @param requiremet [String] - suitable for [Gem::Requirement] string.
    #  Define requiremet version of 1C:Platform.
    # @return [Array<BinaryWrapper::ThinClient>]
    def self.thin_clients(requiremet = '')
      find_clients(BinaryWrapper::ThinClient).map do |c|
        c if requiremet?(c, requiremet)
      end.compact
    end

    # Return array of wrappers for 1C platform(thick client) executables
    # found in {.search_paths}
    # @param (see thin_clients)
    # @return [Array<BinaryWrapper::ThickClient>]
    def self.thick_clients(requiremet = '')
      find_clients(BinaryWrapper::ThickClient).map do |c|
        c if requiremet?(c, requiremet)
      end.compact
    end

    # @param uri (see WebClient#initialize)
    # @param version (see WebClient#initialize)
    # @return [AssLauncher::Enterprise::WebClient]
    def self.web_client(uri = nil, version = nil)
      WebClient.new(uri, version)
    end

    # Find binaries in Cygwin work slow.
    # For rapid get binaries uses catch
    # @return [Hash]
    # @api private
    def self.glob_cache
      @glob_cache ||= {}
    end

    # Cliar {.glob_cache}
    def self.clear_glob_cache
      @glob_cache = nil
    end

    # Find and return all 1C:Entrprise binaries
    # @return [Array<BinaryWrapper>]
    def self.find_binaries(basename)
      return [] if basename.to_s.empty?
      return glob_cache[basename] if glob_cache.key?(basename)
      r = []
      search_paths.flatten.each do |sp|
        r += platform.glob("#{sp}/**/#{basename}")
      end
      glob_cache[basename] = r
    end
    private_class_method :find_binaries
  end
end
