# encoding: utf-8

module AssLauncher
  module Enterprise
    require 'ass_launcher/enterprise/binary_wrapper'

    extend AssLauncher::Support::Platforms

    CLIENTS = {}
    SEARCH_PATHES = []
    SEARCH_PATHES << ENV['ASSPATH'] if ENV['ASSPATH']

    if cygwin? || windows?
      CLIENTS[:thin] = '1cv8.exe'
      CLIENTS[:thick] = '1cv8c.exe'
      platform.env[/\Aprogram\s*files.*/i].uniq.map {|p| SEARCH_PATHES << p}
    elsif linux?
      CLIENTS[:thin] = '1cv8'
      CLIENTS[:thick] = '1cv8c'
      SEARCH_PATHES << '/opt/1C/'
    end

    def self.clients
      CLIENTS.values do |v|
        v unless v.to_s.empty?
      end.compact
    end

    # Find and return all 1C:Entrprise binaries
    # @return [Array<BinaryWrapper>]
    def self.binaries
      return [] unless CLIENTS[:thin] || CLIENTS[:thick]
      return [] if SEARCH_PATH.size = 0
      b = []
      SEARCH_PATHES.each do |path_str|
        platform.glob('**',"{#{FIXME}}")
      end
      raise 'FIXME'
      b
    end
  end
end
