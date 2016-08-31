$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'simplecov'
require 'ass_launcher'
Dir.glob(File.join(File.expand_path('../test_helper'),'*.rb')).each do |l|
  require l
end

require 'minitest/autorun'
require 'mocha/mini_test'
