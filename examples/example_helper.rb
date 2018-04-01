$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ass_launcher'

module Examples
  MIN_PLATFORM_VERSION = '8.3.10'

  PLATFORM_VER = "~> #{MIN_PLATFORM_VERSION}"
  PLATFORM_ARCH = 'i386'
  fail "\nRuby i386 require!\n" if RbConfig::CONFIG['arch'] =~ %r{x86_64}
  OLE_V8 = '83'

  # Examples executing control
  # Be careful with them!!!!
  module TROUBLES_EXECUTE_CONTROL
    # Will be executed examples which show GUI dialogs.
    # It is require human interaction!!!
    SHOW_STUPID_GUI = !ENV['SHOW_STUPID_GUI'].nil?
    # Will be executed examples which create infobases not where you need
    SHOW_TROBLES_WITH_CREATEINFOBASE = !ENV['SHOW_TROBLES_WITH_CREATEINFOBASE'].nil?
  end

  module PLATFORM
    extend AssLauncher::Support::Platforms
    LINUX = linux?
    CYGWIN = cygwin?
    WINDOWS = windows?
  end

  module CLIENTS
    extend AssLauncher::Api
    THICK = thicks_i386(Examples::PLATFORM_VER).last
    fail "1C:Enterprise thick client i386 v.#{Examples::PLATFORM_VER} not found" if\
      THICK.nil?
    THIN = thins_i386(Examples::PLATFORM_VER).last
    fail "1C:Enterprise thin client i386 v.#{Examples::PLATFORM_VER} not found" if\
      THIN.nil?
    WEB = web_client('http://example.org', MIN_PLATFORM_VERSION)
  end

  module TEMPLATES
    CF = File.expand_path('../templates/example_template.cf', __FILE__)
    V8I = File.expand_path('../templates/example_template.v8i', __FILE__)
    HELLO_EPF = File.expand_path('../templates/hello.epf', __FILE__)
  end

  module IbMaker
    include AssLauncher::Api

    def ibases
      @ibases ||= {}
    end

    def rm(name)
      fail 'Abstract method call'
    end

    def exists?(name)
      File.exists? ib_file_path(name)
    end

    def ib_file_path(name)
      File.join ib_dir(name), '1Cv8.1CD'
    end

    def ib_dir(name)
      File.join ibases_root, name
    end

    def ibases_root
      fail 'Abstract method call'
    end

    def make(name)
      ibases[name] = make_ib(name)
    end

    def cl
      CLIENTS::THICK
    end

    def make_ib(name)
      conns = cs_file file: ib_dir(name)
      build_ib(conns) unless exists? name
      conns.path.to_s
    end
    private :make_ib

    def build_ib(conns)
      command = cl.command(:createinfobase) do
        connection_string conns
      end
      command.run.wait.result.verify!
    end
    private :build_ib

    def rm_all
      ibases.keys.each do |name|
        rm name
      end
    end
  end

  module TMP
    extend AssLauncher::Api
    module TmpIb
      extend IbMaker
      def self.rm(name)
        FileUtils.rm_rf ibases[name] if File.exists? ibases[name]
      end

      def self.ibases_root
        Dir.tmpdir
      end

      at_exit do
        TmpIb.rm_all
      end
    end
    EMPTY_IB = TmpIb.make('AssLauncher_Examples_EMPTY_IB')
    EMPTY_IB_CS = cs_file file: EMPTY_IB
  end
end

require "minitest/autorun"
