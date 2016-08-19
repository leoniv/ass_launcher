module AssLauncher
  module Support
    # Implemet section of v8i file
    class V8iSection
      # Class provaides case insensitive access to {#_hash} fields of
      # {V8iSection}
      # @api private
      class Fields
        # Define required fields of v8i
        REQUIRED = [:connect]

        # @return [Hash] containe {V8iSection} fields
        attr_reader :_hash

        # @param hash [Hash]
        # @raise [ArgumentError] if not all {REQUIRED} given
        def initialize(hash)
          @_hash = hash
          fail ArgumentError if\
            (REQUIRED - dict.keys).size > 0
        end

        # Dictionary for case insensitive access to {#_hash} values
        # @return [Hash]
        def dict
          @dict ||= build_dict
        end

        # :nodoc:
        def build_dict
          r = {}
          _hash.each_key do |key|
            r[key.downcase.to_sym] = key
          end
          r
        end
        private :build_dict

        # Translate any +key+ in to real {#_hash} key
        def trans(key)
          dict[key.downcase.to_sym]
        end
        private :trans

        # :nodoc:
        def [](key)
          _hash[trans(key)]
        end

        # :nodoc:
        def []=(key, value)
          _hash[trans(key)] = value
        end

        # :nodoc:
        def key?(key)
          !trans(key).nil?
        end

        # :nodoc:
        def to_s
          res = ''
          _hash.each do |key, value|
            res << "#{key}=#{value}\r\n"
          end
          res
        end
      end

      # @return [String]
      attr_accessor :caption
      # @return [Fields]
      attr_reader :fields
      # @param caption [String] caption of section
      # @param fields [Hash]
      def initialize(caption, fields)
        @caption = caption
        @fields = Fields.new(fields)
      end

      # Return value of field +key+
      # @note It case insensitive
      # @param key [String, Symbol]
      def [](key)
        fields[key]
      end

      # Set value of field +key+
      # @note (see #[])
      # @param key (see #[])
      # @param value [String]
      def []=(key, value)
        fields[key] = value
      end

      # @note (see #[])
      # @param key (see #[])
      def key?(key)
        fields.key?(key)
      end

      # :nodoc:
      def to_s
        res = ''
        res << "[#{caption}]\r\n"
        res << fields.to_s
        res
      end
    end
  end
end
