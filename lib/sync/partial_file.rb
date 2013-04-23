module Sync
  class PartialFile
    
    attr_reader :filename

    def initialize(filename)
      @filename = filename.to_s
    end

    def valid?
      @filename[0] == "_"
    end

    def name_without_underscore
      basename[1..basename.length]
    end

    def basename
      @basename ||= @filename.split(".").first
    end
  end
end