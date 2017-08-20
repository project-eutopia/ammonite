require "../spec_helper"
require "../../src/ammonite/ndarray.cr"

describe Ammonite::Ndarray do
  it "works" do
    a = Ammonite::Ndarray(Int32).empty([4, 2])
    a.strides.should eq [2, 1]

    b = Ammonite::Ndarray(UInt16).empty([2, 3, 4])
    b.strides.should eq [3*4, 4, 1]

    b[1,2,3].set 14
    b[1,2,3].value.should eq 14
  end
end
