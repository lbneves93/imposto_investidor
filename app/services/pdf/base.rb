module Pdf
  class Base
    attr_accessor :file_path
    attr_reader :reader

    def initialize(file_path)
      @file_path = file_path
    end

    def open
      @reader = PDF::Reader.new(@file_path)
      self
    rescue ArgumentError
      'File doesn\'t exists.'
    end
  end
end