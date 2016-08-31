module AssLauncher
  module Enterprise
    # @api private
    # Mixin for {CliDef}
    # Load all CLI definitions from files +cli_def/v.v.v.rb+
    module CliDefsLoader
      DEFS_PATH = File.expand_path('../cli_def', __FILE__)
      def version_from_file_name(file)
        Gem::Version.new File.basename(file, '.rb')
      end
      private :version_from_file_name

      def defs_versions
        Dir.glob(File.join(DEFS_PATH, '*.rb')).map do |l|
          version_from_file_name l
        end.sort
      end
      private :defs_versions

      def load_def(v)
        require File.join(DEFS_PATH, "#{v}")
        @loaded_defs ||= []
        @loaded_defs << v
      end
      private :load_def

      def load_defs
        defs_versions.sort.each do |v|
          enterprise_version v
          load_def v
        end
      end
      private :load_defs
    end
  end
end
