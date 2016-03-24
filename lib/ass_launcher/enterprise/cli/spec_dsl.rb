# encoding: utf-8

module AssLauncher
  module Enterprise
    module Cli
      module SpecDsl
        def thick_client(v = '>= 0')
          BinaryMatcher.new(:thick, v)
        end

        def thin_client(v = '>= 0')
          BinaryMatcher.new(:thin, v)
        end

        def all_client(v = '>= 0')
          BinaryMatcher.new(:all, v)
        end

        def parameters
          @parameters ||= Parameters::ParamtersList.new
        end

        def define(parameter, &block)
          parameters.define(parameter, &block)
        end
        private :define

        def mode(modes, &block)
          raise 'FIXME'
        end
      end # SpecDsl
    end
  end
end
