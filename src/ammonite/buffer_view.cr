require "./byte_buffer.cr"

module Ammonite
  class BufferView(T)
    @byte_buffer : ByteBuffer
    @slice : Slice(T)

    def initialize(@byte_buffer : ByteBuffer)
      unless @byte_buffer.size % sizeof(T) == 0
        raise "Type #{T} has size #{sizeof(T)}, and does not fit in ByteBuffer of size #{@byte_buffer.size}"
      end

      @slice = Slice(T).new(@byte_buffer.buffer.to_unsafe.as(Pointer(T)), @byte_buffer.size / sizeof(T))
    end

    def [](index : Int32)
      @slice[index]
    end

    def []=(index : Int32, value : T)
      @slice[index] = value
    end
  end
end
