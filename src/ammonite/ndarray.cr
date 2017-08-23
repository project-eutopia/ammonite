require "./index.cr"
require "./buffer_view.cr"
require "./broadcaster.cr"

module Ammonite
  def self.[](values)
    # Dig down to get type
    cur_values = values
    while cur_values.responds_to?(:size)
      cur_values = cur_values[0]
    end

    # Call default Ndarray constructor
    Ndarray(typeof(cur_values)).new(values)
  end

  # T is the type stored in the array
  class Ndarray(T)
    include Enumerable(T)

    alias Shape = Array(Int32)
    alias Strides = Array(Int32)

    # Single uninitialized variable used for type checking
    protected getter type : T

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
      @type = uninitialized T
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

    def initialize(values)
      @type = uninitialized T
      @shape = [] of Int32
      @ndim = 0

      # Get shape and dimension
      cur_dim = 0
      cur_array = values
      loop do
        break if cur_array.is_a?(T)

        @ndim += 1
        @shape << cur_array.size

        break if cur_array.size == 0
        cur_array = cur_array[0]
      end

      @size = @shape.reduce(1) {|res,n| res*n}

      @elem_size = sizeof(T)
      @total_bytes = @elem_size * @size
      @offset = 0
      @strides = self.class.strides_from_shape(shape)

      @buffer_view = BufferView(T).new(@size)

      if values.is_a?(T)
        @buffer_view[0] = values
      else
        fill_in_buffer([] of Int32, values)
      end
    end

    private def fill_in_buffer(cur_indexes : Array(Int32), values)
      # Here we are still going down the value array
      if cur_indexes.size < ndim
        raise "Invalid input data" if values.is_a?(T)
        # Should have expected number of elements at this depth
        raise "Incorrect shape" unless values.size == shape[cur_indexes.size]

        shape[cur_indexes.size].times.each do |i|
          cur_indexes << i
          fill_in_buffer(cur_indexes, values[i])
          cur_indexes.pop
        end
      else
        case values
        when T
          offset = offset_from_multi_index(MultiIndex.new(shape, cur_indexes))
          @buffer_view[offset] = values
        else
          raise "Bad value #{values}"
        end
      end
    end

    def self.strides_from_shape(shape : Shape) : Strides
      ndim = shape.size
      shape.size.times.to_a.reverse.map {|i| shape[(ndim-i)...ndim].reduce(1) {|res,n| res*n}}
    end

    protected def initialize(other : Ndarray, indexes : Array(Index))
      @type = uninitialized T
      temp_shape = indexes.map {|index| index.axis_shape}
      @ndim = indexes.select {|index| !index.collapsed}.size
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
      @type = uninitialized T
      @ndim = @shape.size
      @size = shape.reduce(1) {|res,n| res*n}
      @elem_size = sizeof(T)
      @total_bytes = @elem_size * @size

      @buffer_view = other.buffer_view
    end

    def []
      raise "Invalid number of arguments" unless @ndim == 0
      self.class.new(self, [] of Index)
    end

    def [](*args)
      raise "Invalid number of arguments" unless args.size == @ndim
      indexes = args.map_with_index {|arg,i| Index.new(shape, i, arg)}
      self.class.new(self, indexes)
    end

    def each
      MultiIndexIterator.new(shape).each do |multi_index|
        yield @buffer_view[offset_from_multi_index(multi_index)]
      end
    end

    def each_with_multi_index
      MultiIndexIterator.new(shape).each do |multi_index|
        yield @buffer_view[offset_from_multi_index(multi_index)], multi_index
      end
    end

    # TODO: upcast types
    def set(other)
      if other.is_a?(Ndarray)
        broadcaster = Broadcaster.new(shape, other.shape)
        raise "Invalid rhs to set -- shape #{other.shape} is too large to broadcast into #{shape}" unless broadcaster.shape1_contains_shape2

        broadcaster.iterator.each do |multi_indexes1, multi_indexes2, _|
          offset1 = offset_from_multi_index(multi_indexes1)
          offset2 = other.offset_from_multi_index(multi_indexes2)

          @buffer_view[offset1] = other.buffer_view[offset2]
        end
      else
        @buffer_view[@offset] = T.new(other)
      end
    end

    {% for name in [:+, :-, :*, :/, :**] %}
      def {{name.id}}(other)
        other = Ndarray(typeof(other)).new(other) unless other.is_a?(Ndarray)
        broadcaster = Broadcaster.new(shape, other.shape)

        # Upcast based on return of operation
        res = Ndarray(typeof(self.type.{{name.id}}(other.type))).empty(broadcaster.broadcast_shape)

        broadcaster.iterator.each do |multi_index1, multi_index2, multi_index|
          offset1 = offset_from_multi_index(multi_index1)
          offset2 = other.offset_from_multi_index(multi_index2)
          offset  = res.offset_from_multi_index(multi_index)

          res.buffer_view[offset] = self.buffer_view[offset1].{{name.id}}(other.buffer_view[offset2])
        end

        res
      end
    {% end %}

    # Returns a copy of the data with the new shape
    def reshape(new_shape : Array(Int32))
      raise "Incompatible shape #{new_shape} with Ndarray of shape #{shape}" unless new_shape.reduce(1) {|res,n| res*n} == size

      if strides == self.class.strides_from_shape(shape)
        # Here we have continguous memory, so just return a new view
        self.class.new(self, offset, new_shape, self.class.strides_from_shape(new_shape))
      else
        # Here the data is not stored in a block, so we have to make a copy
        self.class.empty(new_shape).tap do |array|
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
      array = self.class.empty([size])
      each_with_index do |value, index|
        array[index].set value
      end
      array
    end

    def t
      self.class.new(self, @offset, @shape.reverse, @strides.reverse)
    end

    def value : T
      # @ndim = 0 for singular, @size = 1 for n-dim array with single element (e.g. shape [1,1,1])
      raise "Cannot call value on Ndarray with more than 1 element" unless @size == 1
      @buffer_view[@offset]
    end

    protected def offset_from_multi_index(multi_index : MultiIndex)
      offset = @offset
      strides.each_with_index do |stride, axis|
        offset += stride*multi_index.indexes[axis]
      end
      offset
    end
  end
end
