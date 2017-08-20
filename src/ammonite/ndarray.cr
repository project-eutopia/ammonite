require "./buffer_view.cr"

module Ammonite
  # T is the type stored in the array
  class Ndarray(T)
    getter shape : Array(Int32)
    getter ndim : Int32
    getter size : Int32
    getter elem_size : Int32
    getter total_bytes : Int32
    getter offset : Int32
    getter strides : Array(Int32)
    getter buffer_view : BufferView(T)

    def self.empty(shape : Array(Int32))
      new(shape, nil)
    end

    def self.zeros(shape : Array(Int32))
      new(shape, T.new(0))
    end

    def initialize(@shape : Array(Int32), value : (T | Nil))
      # {{ raise unless T.is_a?(Number) }}
      raise "shape must be of non-negative integers" unless shape.all? {|i| i.is_a?(Int) && i >= 0}
      raise "shape must have at least one element" if shape.size == 0

      @ndim = shape.size
      @size = shape.reduce(1) {|res, n| res*n}

      @elem_size = sizeof(T)
      @total_bytes = @elem_size * @size
      @offset = 0
      @strides = @shape.size.times.to_a.reverse.map {|i| @shape[(@ndim-i)...@ndim].reduce(1) {|res,n| res*n}}

      if value.nil?
        @buffer_view = BufferView(T).new(@size)
      else
        @buffer_view = BufferView(T).new(@size, value)
      end
    end

    protected def initialize(other : Ndarray, index : Int32)
      @shape = [1]
      @ndim = 1
      @size = 1
      @elem_size = sizeof(T)
      @total_bytes = @elem_size * @size

      @offset = index
      @strides = [1]

      @buffer_view = other.buffer_view
    end

    def [](*args)
      index = 0
      @strides.each_with_index do |stride, i|
        index += stride*args[i]
      end
      self.class.new(self, index)
    end

    def set(other)
      @buffer_view[@offset] = T.new(other)
    end

    def value : T
      raise "Cannot call value on Ndarray with more than 1 element" unless @size == 1
      @buffer_view[@offset]
    end
  end
end
