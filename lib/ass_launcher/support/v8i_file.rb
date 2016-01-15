module AssLauncher
  module Support
    EOF = "\r\n"
    BOM = "\xEF\xBB\xBF"

    # v8i file reader-writer
    module V8iFile
      class ReadError < StandardError; end

      # Read v8i file and return array of v8i sections
      # @param io [IO] the input starem opened for read
      # @return [Array<V8iSection>]
      def self.read(io)
        ['FIXME','FIXME']
      end

      # Write sections in to v8i file
      # @param io [IO] the output stream open for writing
      # @param sections [Array<V8iSection>] sections for write
      def self.write(io, sections)
        sections.each do |s|
          io.write(s.to_s+"\r\n")
        end
      end
    end
  end
end
