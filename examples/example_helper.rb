$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require "minitest/autorun"
require 'ass_launcher'

module Examples
  PLATFORM_VER = '~> 8.3.8.0'
  module TEMPLATES
    CF = File.expand_path('../templates/example_template.cf', __FILE__)
    V8I = File.expand_path('../templates/example_template.v8i', __FILE__)
  end
end

