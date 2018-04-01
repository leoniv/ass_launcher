module AssLauncher
  VERSION = "0.4.0.pre.2"
  module KNOWN_ENTERPRISE_VERSIONS
    require 'ass_launcher/enterprise/cli_defs_loader'
    extend AssLauncher::Enterprise::CliDefsLoader
    def self.get
      defs_versions
    end
  end
end
