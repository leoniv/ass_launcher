require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

Rake::TestTask.new(:run_examples) do |t|
  t.libs << 'examples'
  t.libs << 'lib'
  t.test_files = FileList['examples/**/*_example.rb']
end

task :default => :test
