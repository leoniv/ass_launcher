# encoding: utf-8

module AssLauncher
  module Enterprise
    require 'ass_launcher/enterprise/binary_wrapper'

    extend AssLauncher::Support::Platforms

    WIN_BINARIES = { ThinClient => '1cv8c.exe',
                     ThickClient => '1cv8.exe'
                    }
    LINUX_BINARIES = { ThinClient => '1cv8c',
                       ThickClient => '1cv8'
                     }
    WEB_BROWSERS = %i(firefox iexplore chrome safary)
    def self.windows_or_cygwin?
      platform.cygwin? || platform.windows?
    end
    private_class_method :windows_or_cygwin?

    def self.linux?
      platform.linux?
    end
    private_class_method :linux?

    def self.search_paths
      sp = []
      sp << platform.env[/ASSPATH/i]
      if windows_or_cygwin?
        sp += platform.env[/\Aprogram\s*files.*/i].uniq.map{|pf| "#{pf}/1c*" }
      elsif linux?
        sp += %w(/opt/1C /opt/1c)
      end
      sp.compact.uniq
    end

    def self.binaries(klass)
      if windows_or_cygwin?
        WIN_BINARIES[klass]
      elsif linux?
        LINUX_BINARIES[klass]
      end
    end

    def self.find_clients(klass)
      find_binaries(binaries(klass)).map do |binpath|
        klass.new(binpath)
      end
    end
    private_class_method :find_clients

    def self.requiremet?(client, requiremet)
      return true if requiremet.empty?
      Gem::Requirement.new(requiremet).satisfied_by? client.version
    end
    private_class_method :requiremet?

    def self.thin_clients(requiremet = '')
      find_clients(ThinClient).map do |c|
        c if requiremet?(c, requiremet)
      end.compact
    end

    def self.thick_clients(requiremet = '')
      find_clients(ThickClient).map do |c|
        c if requiremet?(c, requiremet)
      end.compact
    end

    # @todo
    #  TODO, implements #vebclients
    # @return [Hash] - key is web browser name value is [WebClient]
    def self.web_clients(browser = :iexplore)
      fail 'Not implemented yet'
    end

    # Find and return all 1C:Entrprise binaries
    # @return [Array<BinaryWrapper>]
    def self.find_binaries(basename)
      return [] if basename.to_s.empty?
      r = []
      search_paths.flatten.each do |sp|
        r += platform.glob("#{sp}/**/#{basename}")
      end
      r
    end
    private_class_method :find_binaries
  end
end
