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
end
