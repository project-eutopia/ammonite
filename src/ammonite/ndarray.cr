require "./index.cr"
require "./buffer_view.cr"

module Ammonite
  # T is the type stored in the array
  class Ndarray(T)
    include Enumerable(T)

    alias Shape = Array(Int32)
    alias Strides = Array(Int32)

    getter shape : Shape
    getter ndim : Int32
    getter size : Int32
    getter elem_size : Int32
    getter total_bytes : Int32
    getter offset : Int32
    getter strides : Strides
    getter buffer_view : BufferView(T)

    def self.empty(shape : Shape)
      new(shape, nil)
    end

    def self.zeros(shape : Shape)
      new(shape, T.new(0))
    end

    def self.ones(shape : Shape)
      new(shape, T.new(1))
    end

    def self.arange(n)
      new([n], nil).tap do |array|
        (0...n).each do |i|
          array[i].set T.new(i)
        end
      end
    end

    def initialize(@shape : Shape, value : (T | Nil))
      # {{ raise unless T.is_a?(Number) }}
      raise "shape must be of non-negative integers" unless shape.all? {|i| i.is_a?(Int) && i >= 0}
      raise "shape must have at least one element" if shape.size == 0

      @ndim = shape.size
      @size = shape.reduce(1) {|res, n| res*n}

      @elem_size = sizeof(T)
      @total_bytes = @elem_size * @size
      @offset = 0
      @strides = self.class.strides_from_shape(shape)

      if value.nil?
        @buffer_view = BufferView(T).new(@size)
      else
        @buffer_view = BufferView(T).new(@size, value)
      end
    end

    def self.strides_from_shape(shape : Shape) : Strides
      ndim = shape.size
      shape.size.times.to_a.reverse.map {|i| shape[(ndim-i)...ndim].reduce(1) {|res,n| res*n}}
    end

    protected def initialize(other : Ndarray, indexes : Array(Index))
      temp_shape = indexes.map {|index| index.axis_shape}
      @ndim = indexes.select {|index| index.slice?}.size
      @size = temp_shape.reduce(1) {|res, n| res * (n || 1)}
      @elem_size = sizeof(T)
      @total_bytes = @elem_size * @size

      @offset = other.offset
      other.strides.each_with_index do |stride, axis|
        @offset += stride*indexes[axis].base
      end

      # TODO
      temp_strides = indexes.map_with_index {|index, axis| other.strides[axis] * index.step}

      @shape = [] of Int32
      @strides = [] of Int32
      temp_shape.each_with_index do |s, axis|
        if !s.nil?
          @shape << s
          @strides << indexes[axis].step * other.strides[axis]
        end
      end

      @buffer_view = other.buffer_view
    end

    protected def initialize(other : Ndarray, @offset, @shape, @strides)
      @ndim = @shape.size
      @size = shape.reduce(1) {|res,n| res*n}
      @elem_size = sizeof(T)
      @total_bytes = @elem_size * @size

      @buffer_view = other.buffer_view
    end

    def [](*args)
      raise "Invalid number of arguments" unless args.size == @ndim
      indexes = args.map_with_index {|arg,i| Index.new(shape, i, arg)}
      self.class.new(self, indexes)
    end

    def each
      MultiIndexEnumerator.new(shape).each do |multi_index|
        yield @buffer_view[offset_from_multi_index(multi_index)]
      end
    end

    def each_with_multi_index
      MultiIndexEnumerator.new(shape).each do |multi_index|
        yield @buffer_view[offset_from_multi_index(multi_index)], multi_index
      end
    end

    def set(other)
      # TODO: handle sliced, validate compatible shapes
      @buffer_view[@offset] = T.new(other)
    end

    # Returns a copy of the data with the new shape
    def reshape(new_shape : Array(Int32))
      raise "Incompatible shape #{new_shape} with Ndarray of shape #{shape}" unless new_shape.reduce(1) {|res,n| res*n} == size

      if strides == self.class.strides_from_shape(shape)
        # Here we have continguous memory, so just return a new view
        Ndarray(T).new(self, offset, new_shape, self.class.strides_from_shape(new_shape))
      else
        # Here the data is not stored in a block, so we have to make a copy
        Ndarray(T).empty(new_shape).tap do |array|
          i = 0
          each do |value|
            array.buffer_view[i] = value
            i += 1
          end
        end
      end
    end

    # Returns a copy of the array, flattened to a single dimension
    def flatten
      array = Ndarray(T).empty([size])
      each_with_index do |value, index|
        array[index].set value
      end
      array
    end

    def value : T
      # @ndim = 0 for singular, @size = 1 for n-dim array with single element (e.g. shape [1,1,1])
      raise "Cannot call value on Ndarray with more than 1 element" unless @size == 1
      @buffer_view[@offset]
    end

    private def offset_from_multi_index(multi_index : MultiIndex)
      offset = 0
      strides.each_with_index do |stride, axis|
        offset += stride*multi_index.indexes[axis]
      end
      offset
    end
  end
end
