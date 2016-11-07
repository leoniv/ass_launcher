module AssLauncher
  # Common objects and methods
  module Support
    EOF = "\r\n"
    BOM = "\xEF\xBB\xBF".force_encoding('utf-8')

    # v8i file reader-writer
    module V8iFile
      require 'inifile'
      class ReadError < StandardError; end

      # Read v8i content and return array of v8i sections
      # @param io [IO] the input starem opened for read
      # @return [Array<V8iSection>]
      def self.read(io)
        res = []
        inifile = to_inifile(io.read)
        inifile.each_section do |caption|
          res << V8iSection.new(caption, inifile[caption])
        end
        res
      end

      # Read v8i file
      # @param filename [String]
      # @return (see read)
      # @raise [ReadError] if file not exists
      def self.load(filename)
        fail ReadError, "File #{filename} not exist or not a file"\
          unless File.file? filename
        read File.new(filename, 'r:bom|utf-8')
      end

      # Write sections in to output stream
      # @param io [IO] the output stream open for writing
      # @param sections [Array<V8iSection>] sections for write
      def self.write(io, sections)
        sections.each do |s|
          io.write(s.to_s + "\r\n")
        end
      end

      # Save sections in to v8i file
      # @param filename [String]
      # @param sections (see write)
      def self.save(filename, sections)
        f = File.new(filename, 'w')
        write f, sections
        f.close
      end

      private

      def self.to_inifile(content)
        IniFile.new(content: "#{escape_content(content)}", comment: '')
      end

      def self.escape_content(content)
        content.gsub!(BOM, '')
        content.gsub!(/\\\\/, '\\\\\\\\\\')
        %w(r n t 0).each do |l|
          content.gsub!(/\\#{l}/, "\\\\\\#{l}")
        end
        content
      end
    end
  end
end
