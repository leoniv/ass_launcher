# encoding: utf-8

module AssLauncher
  module Support
    # Utils for Linux platform
    module Linux
      extend Platforms
      # Rpm package manager utils
      module Rpm
        # Return instaled package version for +file+
        # @param file [String] path to file
        # @return [Gem::Version] package version
        def self.version(file)
          out = `rpm -q --queryformat '%{RPMTAG_VERSION}.%{RPMTAG_RELEASE}' #{pkg(file)}`
          Gem::Version.new(out.strip)
        end

        # Return package name for +file+
        # @param file (see .version)
        def self.pkg(file)
          `rpm -qf #{file}`.strip
        end

        # True if it's pakage manager
        def self.manager?
          `rpm --version`
          return true
        rescue Errno::ENOENT
          return false
        end
      end

      # Deb package manager utils
      module Deb
        # (see Rpm.version)
        def self.version(file)
          pkg = pkg(file)
          return if pkg.to_s.empty?
          out = `dpkg-query --showformat '${Version}' --show #{pkg}`.strip
          Gem::Version.new(out.gsub('-', '.'))
        end

        # (see Rpm.version)
        def self.pkg(file)
          out = `dpkg -S #{file}`.strip.split(': ')[0]
        end

        # (see Rpm.manager?)
        def self.manager?
          `dpkg --version`
          return true
        rescue Errno::ENOENT
          return false
        end
      end

      # (see Rpm.version)
      # @raise [NotImplementedError]
      def get_pkg_version(file)
        return pkg_manager.version(file) if pkg_manager
        fail NotImplementedError
      end

      # Return suitable manager or +nil+
      # @return (see #current_pkg_manager)
      def pkg_manager
        @pkg_manager ||= current_pkg_manager
      end

      # Clculate current package manager
      # @return [Deb Rpm nil]
      def current_pkg_manager
        return Deb if Deb.manager?
        return Rpm if Rpm.manager?
      end

      def rpm?
        pkg_manager == Rpm
      end

      def deb?
        pkg_manager == Deb
      end

      extend self
    end
  end
end
