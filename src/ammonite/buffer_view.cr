require "./byte_buffer.cr"

module Ammonite
  class BufferView(T)
    @byte_buffer : ByteBuffer
    @slice : Slice(T)

    def initialize(size : Int32, value : T)
      @byte_buffer = ByteBuffer.new(sizeof(T)*size)
      @slice = get_slice

      @slice.each_index do |i|
        @slice[i] = value
      end
    end

    def initialize(size : Int32)
      @byte_buffer = ByteBuffer.new(sizeof(T)*size)
      @slice = get_slice
    end

    def initialize(@byte_buffer : ByteBuffer)
      unless @byte_buffer.size % sizeof(T) == 0
        raise "Type #{T} has size #{sizeof(T)}, and does not fit in ByteBuffer of size #{@byte_buffer.size}"
      end

      @slice = get_slice
    end

    def [](index : Int32) : T
      @slice[index]
    end

    def []=(index : Int32, value) : T
      @slice[index] = T.new(value)
    end

    private def get_slice
      Slice(T).new(@byte_buffer.buffer.to_unsafe.as(Pointer(T)), @byte_buffer.size / sizeof(T))
    end
  end
end
