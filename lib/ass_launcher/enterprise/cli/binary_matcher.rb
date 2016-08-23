module AssLauncher
  module Enterprise
    module Cli
      # @api private
      class BinaryMatcher
        attr_reader :client, :requirement
        def initialize(client = :all, version = '>= 0')
          @client = client.to_sym
          @requirement = Gem::Requirement.new version
        end

        def match?(binary_wrapper)
          match_client?(binary_wrapper) && match_version?(binary_wrapper)
        end

        private
        def match_client?(bw)
          return true if client == :all
          client == bw.class.name.split('::').last.
            to_s.downcase.gsub(/client$/,'').to_sym
        end

        def match_version?(bw)
          requirement.satisfied_by? bw.version
        end
      end
    end
  end
end
