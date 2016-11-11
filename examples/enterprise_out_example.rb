require 'example_helper'

module Examples
  module EneterpriseOut
    # 1C:Enterprise not work with stdout and stderr
    # For out 1C use /OUT"file" parameter and write message into. Message
    # encoding 'cp1251' for windows and 'utf-8' for Linux

    describe 'AssLauncher provides automaticaly capturing 1C:Enterprise out' do
      enterprise = CLIENTS::THICK.command :enterprise do
        connection_string TMP::EMPTY_IB_CS
        _Execute TEMPLATES::HELLO_EPF
        _C 'Hello World'
      end

      it 'Out Hello World' do
        enterprise.run.wait
        enterprise_output = enterprise.process_holder.result.assout
        enterprise_output.strip.must_equal 'Hello World'
      end
    end

    describe "AssLauncher checks duplication of /OUT parameter and fails if it's true" do
      it 'Fails' do
        e = proc {
          enterprise = CLIENTS::THICK.command :enterprise, ['/OUT', 'path']
        }.must_raise ArgumentError
        e.message.must_match %r{set option capture_assout: false}i
      end
    end

    describe 'Arguments builder checks for /OUT file exists' do
      it 'Fails' do
        e = proc {
          enterprise = CLIENTS::THICK.command :enterprise do
            connection_string TMP::EMPTY_IB_CS
            _OUT './fake_out_file'
          end
        }.must_raise ArgumentError
        e.message.must_match %r{fake_out_file not exists}i
      end

    end

    describe 'We can define owner /OUT file but we must set :capture_assout => false' do
      # method #command having option :capture_assout which
      # control automatically capturing behavior.
      # On default :capture_assout => true

      out_file = File.join(Dir.tmpdir, 'enterprise_out_example.out')
      FileUtils.touch out_file

      enterprise = CLIENTS::THICK\
        .command :enterprise, [], capture_assout: false do
        connection_string TMP::EMPTY_IB_CS
        _Execute TEMPLATES::HELLO_EPF
        _OUT out_file
        _C 'Hello World'
      end

      it 'Out Hello World' do
        enterprise.run.wait
        enterprise_output = File.read(out_file)
        enterprise_output.strip.must_equal 'Hello World'
      end

      def after
        FileUtils.rm_f out_file if Fail.exists? out_file
      end
    end

    describe "1C:Enterprise thin client doesn't puts messages into /OUT :(" do
      enterprise = CLIENTS::THIN.command do
        connection_string TMP::EMPTY_IB_CS
        _Execute TEMPLATES::HELLO_EPF
        _C 'Hello World'
      end

      it "Out empty" do
        enterprise.run.wait

        enterprise_output = enterprise.process_holder.result.assout
        enterprise_output.strip.must_equal ''
      end
    end
  end
end
