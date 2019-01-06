require 'example_helper'

module Examples
  module V8iFile
    require 'ass_launcher'

    describe 'Build new v8i file' do

      it 'V8i section must have :Connect field' do
        proc do
          AssLauncher::Support::V8iSection\
            .new('Info base 1', {})
        end.must_raise(ArgumentError)
      end

      # Build v8i section
      v8i_section = AssLauncher::Support::V8iSection\
        .new('Info base 1', 'Connect' => 'File="path"') do |s|
        s[:ClientConnectionSpeed] = :Normal
        s[:App] = :Auto
      end

      it 'V8i section is case insensitive' do
        v8i_section[:app].must_equal :Auto
      end

      it 'For v8i section a Symbol key equal a String key' do
        v8i_section[:app].must_equal :Auto
        v8i_section[:app.to_s].must_equal :Auto
      end

      # Write section to file
      v8i_file = File.join(Dir.tmpdir,'v8i_file_example.v8i')
      # v8i file may contain many of sections
      AssLauncher::Support::V8iFile.save(v8i_file, [v8i_section])


      it 'File exists and valid' do
        File.read(v8i_file).must_equal "[Info base 1]\r\n"\
          "Connect=File=\"path\"\r\n"\
          "ClientConnectionSpeed=Normal\r\n"\
          "App=Auto\r\n"\
          "\r\n"
        FileUtils.rm_f v8i_file if File.exist? v8i_file
      end
    end

    describe 'Use exists v8i file' do
      extend AssLauncher::Api

      # Read v8i file
      v8i_sections = load_v8i(Examples::TEMPLATES::V8I)

      # Get sections contained in v8i file
      v8i_ib1 = v8i_sections.find {|s| s.caption == 'Info base 1'}
      v8i_ib2 = v8i_sections.find {|s| s.caption == 'Info base 2'}

      it 'v8i file contain sections describe two 1C:Enterprise applications' do
        v8i_ib1.must_be_instance_of AssLauncher::Support::V8iSection
        v8i_ib2.must_be_instance_of AssLauncher::Support::V8iSection
      end

      # Build connection string for 'Info base 1'
      conns_ib1 = cs(v8i_ib1[:connect])

      it 'Server connection string' do
        conns_ib1.must_be_instance_of\
          AssLauncher::Support::ConnectionString::Server
      end
    end
  end
end
