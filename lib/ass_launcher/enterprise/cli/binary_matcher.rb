module AssLauncher
  module Enterprise
    module Cli
      # @api private
      class BinaryMatcher
        ALL_CLIENTS = [:thick, :thin, :web]

        def self.modes_for
          @modes_for ||= {
            web: Enterprise::WebClient.run_modes,
            thick: Enterprise::BinaryWrapper::ThickClient.run_modes,
            thin: Enterprise::BinaryWrapper::ThinClient.run_modes
          }
        end
        private_class_method :modes_for

        # Calculate matcher for +run_mode+
        def self.auto(run_modes, requirement = '> 0')
          new auto_client(run_modes), requirement
        end

        def self.auto_client(modes)
          r = []
          r << :web if satisfied? modes, :web
          r << :thick if satisfied? modes, :thick
          r << :thin if satisfied? modes, :thin
          r
        end
        private_class_method :auto_client

        def self.satisfied?(modes, client)
          (modes & modes_for[client]).size > 0
        end
        private_class_method :satisfied?

        attr_reader :clients, :requirement
        def initialize(clients_array = nil, requirement = '>= 0')
          @clients = nil_if_zsize(clients_array) || ALL_CLIENTS
          @requirement = Gem::Requirement.new requirement.to_s
        end

        def nil_if_zsize(array)
          return nil if (array || []).size == 0
          array
        end
        private :nil_if_zsize

        def requirement=(r)
          fail ArgumentError unless r.is_a? Gem::Version::Requirement
          @requirement = r
        end

        def match?(binary_wrapper)
          match_client?(binary_wrapper) && match_version?(binary_wrapper)
        end

        private
        def match_client?(bw)
          clients.include? bw.class.name.split('::').last.
            to_s.downcase.gsub(/client$/,'').to_sym
        end

        def match_version?(bw)
          requirement.satisfied_by? bw.version
        end
      end
    end
  end
end
