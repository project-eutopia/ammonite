module Ammonite
  class ByteBuffer
    getter size : Int32
    getter buffer : Slice(UInt8)

    def initialize(@size : Int32)
      @buffer = Slice(UInt8).new(@size)
    end

    def initialize(@size : Int32, value : UInt8)
      @buffer = Slice(UInt8).new(@size, value)
    end

    def [](index : Int32)
      @buffer[index]
    end

    def []=(index : Int32, value : UInt8)
      @buffer[index] = value
    end
  end
end
