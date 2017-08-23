require "../spec_helper"
require "../../src/ammonite/ndarray.cr"

describe Ammonite::Ndarray do
  describe "#new(shape, value)" do
    it "allocates array with given shape and fill value" do
      a = Ammonite::Ndarray(Int32).new([2,3], 5)
      a[0,0].value.should eq 5
      a[0,1].value.should eq 5
      a[1,1].value.should eq 5
      a[1,2].value.should eq 5
    end
  end

  describe "#new(array)" do
    it "allocates array with given input" do
      a = Ammonite[444]
      a.ndim.should eq 0
      a.shape.should eq [] of Int32
      a.value.should eq 444
      a[].value.should eq 444

      aa = Ammonite[[[1,2,3,4], [9,8,7,6]]]
      aa[0,0].value.should eq 1
      aa[0,1].value.should eq 2
      aa[0,2].value.should eq 3
      aa[0,3].value.should eq 4
      aa[1,0].value.should eq 9
      aa[1,1].value.should eq 8
      aa[1,2].value.should eq 7
      aa[1,3].value.should eq 6

      a0 = Ammonite::Ndarray(Int32).new([] of Int32)
      a0.shape.should eq [0]
      a0.ndim.should eq 1
      a0.size.should eq 0

      a1 = Ammonite::Ndarray(Int32).new([1, 3, 5, 7])
      a1.shape.should eq [4]
      a1.ndim.should eq 1
      a1.size.should eq 4
      a1[0].value.should eq 1
      a1[2].value.should eq 5
      a1[3].value.should eq 7

      a2 = Ammonite::Ndarray(Int32).new([[2, 4, 6], [12, 14, 16]])
      a2.shape.should eq [2,3]
      a2.ndim.should eq 2
      a2[0,0].value.should eq 2
      a2[0,1].value.should eq 4
      a2[0,2].value.should eq 6
      a2[1,0].value.should eq 12
      a2[1,1].value.should eq 14
      a2[1,2].value.should eq 16

      expect_raises { Ammonite::Ndarray(Int32).new([[1], [2,3]]) }
    end
  end

  describe "#empty" do
    it "allocates with correct attributes" do
      a = Ammonite::Ndarray(Int32).empty([4, 2])
      a.shape.should eq [4, 2]
      a.size.should eq 8
      a.elem_size.should eq 4
      a.total_bytes.should eq 32
      a.offset.should eq 0
      a.strides.should eq [2, 1]

      b = Ammonite::Ndarray(UInt16).empty([2, 3, 4])
      b.shape.should eq [2, 3, 4]
      b.size.should eq 24
      b.elem_size.should eq 2
      b.total_bytes.should eq 48
      b.offset.should eq 0
      b.strides.should eq [3*4, 4, 1]
    end
  end

  describe "#zeros" do
    it "is initialized to all zeros" do
      a = Ammonite::Ndarray(Int32).zeros([3,2,4])
      a.shape.should eq [3,2,4]
      a.all? {|i| i == 0}.should eq true
    end
  end

  describe "#ones" do
    it "is initialized to all ones" do
      a = Ammonite::Ndarray(UInt16).ones([10,2,1])
      a.shape.should eq [10,2,1]
      a.all? {|i| i == 1}.should eq true
    end
  end

  describe "#arange" do
    it "is initialized to numbers between 0 and N" do
      a = Ammonite::Ndarray(UInt16).arange(15)
      a.shape.should eq [15]
      a.each_with_index do |v, i|
        v.should eq i
      end
    end

    it "raises error for negative numbers" do
      expect_raises do
        Ammonite::Ndarray(Int8).arange(-1)
      end
    end
  end

  describe "#reshape" do
    context "when for a continguous block of memory" do
      it "returns a new view (same underlying buffer) of the array with the new shape" do
        a = Ammonite::Ndarray(UInt16).arange(24)
        b = a.reshape([2,3,4])

        b.shape.should eq [2, 3, 4]
        b[0,0,0].value.should eq 0
        b[0,0,1].value.should eq 1
        b[0,1,0].value.should eq 4
        b[1,0,0].value.should eq 12
        b[1,2,3].value.should eq 23

        b[1,1,1].set 100
        # It is a new view, so changes the original array too
        a[1 + 4 + 3*4].value.should eq 100
      end
    end

    context "when for a non-continguous block of memory" do
      it "returns a copy of the array with the new shape" do
        a = Ammonite::Ndarray(UInt16).arange(24)
        b = a[{nil,2,nil}].reshape([2,3,2])

        b.shape.should eq [2, 3, 2]
        b[0,0,0].value.should eq 0
        b[0,0,1].value.should eq 2
        b[0,1,0].value.should eq 4
        b[1,0,0].value.should eq 12
        b[1,2,1].value.should eq 22

        b[1,1,1].set 100
        # It is a copy, so does not change the original array
        a.all? {|v| v != 100}.should eq true
      end
    end
  end

  describe "#flatten" do
    it "returns a copy of the data reduced to a single dimension" do
      a = Ammonite::Ndarray(UInt16).arange(20).reshape([2,10])
      b = a[nil, {nil, 4, nil}].flatten
      b.to_a.should eq [0,4,8,10,14,18]
    end
  end

  describe "#t" do
    it "transposes the array" do
      a1 = Ammonite[[2, 3, 5, 7]]
      a1.t.shape.should eq [4]
      a1.t[0].value.should eq 2
      a1.t[1].value.should eq 3
      a1.t[2].value.should eq 5
      a1.t[3].value.should eq 7

      a2 = Ammonite[[[2,3,4], [7, 8, 9]]]
      a2t = a2.t
      a2t.shape.should eq [3,2]
      a2t[0,0].value.should eq 2
      a2t[0,1].value.should eq 7
      a2t[1,0].value.should eq 3
      a2t[1,1].value.should eq 8
      a2t[2,0].value.should eq 4
      a2t[2,1].value.should eq 9

      a3 = Ammonite::Ndarray(Int32).arange(24).reshape([2,3,4])
      a3.t.shape.should eq [4,3,2]
      a3.t[0,0,0].value.should eq 0
      a3.t[0,0,1].value.should eq 12
      a3.t[0,1,0].value.should eq 4
      a3.t[1,0,0].value.should eq 1
    end
  end

  describe "#[]" do
    it "returns a slice of the array" do
      sizes = (1..7).to_a
      sliced_sizes = [1, 1, 1, 2, 2, 2, 3]

      sizes.each_with_index do |size, i|
        Ammonite::Ndarray(Int32).arange(size).tap do |array|
          array[{nil,3,nil}].shape.should eq [sliced_sizes[i]]
        end
      end
    end

    describe "multiple calls" do
      it "can be chained" do
        a = Ammonite::Ndarray(Int32).arange(100)
        b = a[{2,2,98}][{2,3,9}]
        b.shape.should eq [3]
        b.to_a.should eq [6, 12, 18]
      end
    end

    describe "{nil, step, nil}" do
      it "goes across whole array by given step sizes" do
        a = Ammonite::Ndarray(Int32).arange(10)

        a[{nil,1,nil}].to_a.should eq (0...10).to_a
        a[{nil,2,nil}].to_a.should eq [0, 2, 4, 6, 8]
        a[{nil,3,nil}].to_a.should eq [0, 3, 6, 9]
        a[{nil,-1,nil}].to_a.should eq [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
        a[{nil,-2,nil}].to_a.should eq [9, 7, 5, 3, 1]
        a[{nil,-3,nil}].to_a.should eq [9, 6, 3, 0]

        expect_raises { a[{nil, 0, nil}] }
      end
    end

    describe "{nil, step, end}" do
      it "goes across whole array by given step sizes up to end" do
        a = Ammonite::Ndarray(Int32).arange(10)

        a[{nil,1,5}].to_a.should eq (0...5).to_a
        a[{nil,1,-1}].to_a.should eq (0...9).to_a
        a[{nil,1,-3}].to_a.should eq (0...7).to_a
        a[{nil,3,-1}].to_a.should eq [0, 3, 6]
        a[{nil,-1,0}].to_a.should eq [9, 8, 7, 6, 5, 4, 3, 2, 1]
        a[{nil,-2,-5}].to_a.should eq [9, 7]
      end
    end

    describe "{start, step, nil}" do
      it "goes across whole array by given step sizes from start" do
        a = Ammonite::Ndarray(Int32).arange(10)

        a[{0,1,nil}].to_a.should eq (0...10).to_a
        a[{2,2,nil}].to_a.should eq [2, 4, 6, 8]
        a[{5,-1,nil}].to_a.should eq (0..5).to_a.reverse
        a[{-1,-1,nil}].to_a.should eq (0...10).to_a.reverse
        a[{-4,2,nil}].to_a.should eq [6, 8]
        a[{-3,-3,nil}].to_a.should eq [7, 4, 1]
      end
    end

    describe "{start, step, end}" do
      it "goes across whole array by given step sizes from start" do
        a = Ammonite::Ndarray(Int32).arange(10)

        a[{0,1,0}].to_a.should eq [] of Int32
        a[{0,1,-1}].to_a.should eq (0...9).to_a
        a[{0,1,9}].to_a.should eq (0...9).to_a
        a[{0,1,10}].to_a.should eq (0...10).to_a
        a[{1,3,10}].to_a.should eq [1, 4, 7]
        a[{2,3,9}].to_a.should eq [2, 5, 8]
        a[{2,3,8}].to_a.should eq [2, 5]
        a[{2,3,-2}].to_a.should eq [2, 5]
        a[{-1,3,10}].to_a.should eq [9]
        a[{-1,3,9}].to_a.should eq [] of Int32
        a[{-1,3,-2}].to_a.should eq [] of Int32

        b = a[{5,-1,0}]
        b.ndim.should eq 1
        b.shape.should eq [5]
        b.to_a.should eq [5, 4, 3, 2, 1]

        c = a[{0,1,0}]
        c.ndim.should eq 1
        c.shape.should eq [0]
        c.to_a.should eq [] of Int32
      end
    end
  end

  describe "#set" do
    context "when simple value" do
    end

    context "when ndarray" do
      it "broadcasts along collapsed axes" do
        a = Ammonite::Ndarray(Int32).zeros([3, 3])

        b1 = Ammonite::Ndarray(Int32).arange(3)
        a.set b1

        a[0,0].value.should eq 0
        a[0,1].value.should eq 1
        a[0,2].value.should eq 2
        a[1,0].value.should eq 0
        a[1,1].value.should eq 1
        a[1,2].value.should eq 2
        a[2,0].value.should eq 0
        a[2,1].value.should eq 1
        a[2,2].value.should eq 2

        b2 = Ammonite::Ndarray(Int32).arange(3).reshape([3,1])
        a.set b2

        a[0,0].value.should eq 0
        a[0,1].value.should eq 0
        a[0,2].value.should eq 0
        a[1,0].value.should eq 1
        a[1,1].value.should eq 1
        a[1,2].value.should eq 1
        a[2,0].value.should eq 2
        a[2,1].value.should eq 2
        a[2,2].value.should eq 2
      end

      it "raises error when shape of rhs is incompatible (too large)" do
        expect_raises do
          a = Ammonite::Ndarray(Int32).zeros([3, 1])
          b = Ammonite::Ndarray(Int32).zeros([3, 3])
          a.set b
        end
      end
    end
  end
end
