#!/usr/bin/env ruby -w
#
# No warranty. And definitely no refunds.
#

require 'turtles'

class Bar; def spoo; 42; end; end

class Foo
  attr_reader :bar
  def initialize()
    @bar = Bar.new
  end
end

def break_something!
  raise RuntimeError, "Oops! I bwoke something!"
end

describe Turtles, "Basic Behavior" do
  before(:each) do
    @foo = Foo.new
    @arr = [1,2,3]
    no_turtles!
  end
  
  it "should not affect regular object chaining" do
    with_turtles { @foo.bar.spoo }.should == 42
  end
  
  it "should return nil when a method is invoked on Nil" do
    with_turtles { nil.bar }.should == nil
  end
  
  it "should allow a block to return correctly" do
    with_turtles { @arr.collect {|f| f*2} }.should == [2,4,6]
  end
  
  it "should return nil from a block when the block is invoked on nil" do
    with_turtles { nil.collect {|f| f*2} }.should == nil
  end
  
  it "should return nil when global turtles are enabled" do
    turtles!
    nil.bar.spoo.should == nil
    nil.collect {|f| f*2}.should == nil
  end
  
  it "should leave turtles enabled or disabled as they were before with_turtles" do
    no_turtles!
    with_turtles { nil.bar.spoo }.should == nil
    turtles?.should == false
    
    turtles!
    with_turtles { nil.bar.spoo }.should == nil
    turtles?.should == true
  end
  
  it "should not leave the turtle block when nils are found" do
    with_turtles do
      nil.bar.spoo.should == nil
      @foo.bar.spoo.should == 42
      nil.collect {|f| f*2}.should == nil
      @arr.collect {|f| f*2}.should == [2,4,6]
    end
  end
  
  it "should ensure turtles deactivation if code raises an exception" do
    begin
      with_turtles { break_something! }
    rescue RuntimeError
      nil
    end
    turtles?.should == false
  end

  it 'should give you access to the most recent turtle-chain in the thread' do
    (c = ParentWithTurtles.new).foo.should == nil
    Turtles.last_chain.should == [:foo]

    c.moo.should == nil
    Turtles.last_chain.should == [:moo]

    turtles!
    c.foo.moo.goo.gai.pan.should == nil
    Turtles.last_chain.should == [:foo, :moo, :goo, :gai, :pan]
    
    c.shoo.moo.goo.gai.pan.should == nil
    Turtles.last_chain.should == [:shoo, :moo, :goo, :gai, :pan]

    # an edge case is that if we start a new chain from nil directly, rather
    # than an object, Turtles is unaware were on a new chain. The workaround is
    # to delimit such cases in a with_turtles block if that may be the case
    with_turtles{
      nil.floo.moo.goo.gai.pan.should == nil
      Turtles.last_chain.should == [:floo, :moo, :goo, :gai, :pan]
    }

    c.groo.moo.goo.turtle_chain.join(".").should == "groo.moo.goo"
    c.oorg.moo.goo.turtle_chain.join("/").should == "oorg/moo/goo"

  end
end

describe Turtles, "Inheritance Use Cases" do
  class Parent;                                                    end
  class ParentWithTurtles < Parent;    include Turtles;            end

  class ParentWithoutTurtles < Parent;                             end
  class ChildOfTurtledParent < ParentWithTurtles;                  end
  class ChildOfTurtledParent2 < ParentWithTurtles;                 end
  class ChildOfTurtlelessParent < ParentWithoutTurtles;            end
  class ChildOfTurtledParentMM < ParentWithTurtles                
    def method_missing(name, *args, &block)
      if name.to_s.length==1
        "MM: #{name}"
      else
        super
      end
    end
  end
    
  it 'should have enabled turtles in ParentWithTurtles' do
    ParentWithTurtles.turtles?.should == true
  end

  it 'should have enabled turtles in its descendents' do
    ChildOfTurtledParent.turtles?.should == true
  end

  it 'should enable turtles in a child of a turtled parent' do
    ct = ChildOfTurtledParent.new
    ParentWithTurtles.turtles?.should == true
    ct.class.turtles?.should == true
  end

  it 'should let a child class define method missing without parents turtles interfering' do 
    cwmm = ChildOfTurtledParentMM.new
    cwmm.fizoo.should == nil

    # messages of length == 1 should be handled by child
    cwmm.f.should == "MM: f"
  end 

  it "should keep descendent classes' values of turtles? be distinct" do
    [ParentWithTurtles, ChildOfTurtledParent, ChildOfTurtledParent2].map(&:turtles?).uniq.should == [true]

    ChildOfTurtledParent.no_turtles!

    ChildOfTurtledParent.turtles?.should == false
    ChildOfTurtledParent2.turtles?.should == true
  end
end
