module AssLauncher
  module Support
    # Implemet section of v8i file
    class V8iSection
      attr_accessor :caption
      attr_reader :fields
      def initialize(caption, fields)
        fail ArgumentError unless\
          self.class.fields_required & fields.keys == self.class.fields_required
        @caption = caption
        @fields = fields
      end

      # Define required fields of v8i
      # @return [Array<String>]
      #  - Connect - connection string to infobase
      def self.fields_required
        %w( Connect )
      end

      # Define extra fields for v8i not defined 1C. This fields use
      # admin tools for automate support infodases
      # @return [Array<String>] of:
      #  - AdmConnect - connection string to infobase for admin tools.
      #    'Srvr' or 'File' connects only
      #  - BaseCodeName - infobase configuration code name. For example
      #    'Accounting', 'HRM', 'KzAccounting' etc.
      #  - GetUpdateInfoURI - URI for configuration updateinfo file for example:
      #    http://downloads.1c.ru/ipp/ITSREPV/V8Update/Configs/Accounting/20/82/
      #  - BaseCurentVersion - curent configuration version
      #  - GlobalWS - connection string for access to infobase from internet
      #  - Vendor - configuration vendor. '1C' 'Rarys' etc.
      def self.fields_extras
        %w( AdmConnect
            BaseCodeName
            GetUpdateInfoURI
            BaseCurentVersion
            GlobalWS
            Vendor )
      end

      # Define optional fields of v8i
      # @return [Array<String>]
      def self.fields_optional
        'TODO'
      end

      def [](key)
        fields[key]
      end

      def []=(key, value)
        fields[key] = value
      end

      def key?(key)
        fields.key?(key)
      end

      def to_s
        res = ''
        res << "[#{caption}]\r\n"
        fields.each do |key, value|
          res << "#{key}=#{value}\r\n"
        end
        res
      end
    end
  end
end
