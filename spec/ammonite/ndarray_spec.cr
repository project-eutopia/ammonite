require "../spec_helper"
require "../../src/ammonite/ndarray.cr"

describe Ammonite::Ndarray do
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
  end
end
