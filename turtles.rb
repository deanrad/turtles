#!/usr/bin/env ruby -w
#
# No warranty. And definitely no refunds.
#
# turtles.rb - Implement Object#andand in a turtles_all_the_way_down fashion.

# If you don't like this requirement, reimplement class_inheritable_accessor, et al. into your project
require 'active_support/core_ext'

module Turtles
  def self.included(base)
    # NilClass becomes (and stays) turtlized upon including Turtles into some class
    NilClass.send(:include,Turtles) unless NilClass.ancestors.include?(Turtles)

    base.class_eval do
      alias_method :method_missing_without_turtles, :method_missing
      alias_method :method_missing, :method_missing_with_turtles      

      # For a discussion of class_inheritable_accessor:
      # http://www.raulparolari.com/Rails/class_inheritable
      class_inheritable_accessor :turtles
      def self.turtles!;        self.turtles = true  ; end
      def self.no_turtles!;     self.turtles = false ; end
      def self.turtles?;     !! self.turtles         ; end

      class_inheritable_accessor :turtle_evaluator
      self.turtle_evaluator = :turtle_eval #overridable
    end

    # Turtles are enabled by default upon inclusion 
    base.turtles! # this will have to be tweaked for NilClass
  end

  # Adds methods to the metaclass of the singleton instance of NilClass
  # to indicate that it is a turtle nil. Note: nil still has all the happy
  # nil properties, just a few extra !!
  def turtlize_nil!
    def nil.__hecho_por_tortugas; true; end

    # Returns the turtle chain in lexographical order and unmods nil 
    def nil.turtle_chain
      c = Turtles.last_chain
      nil.metaclass.instance_eval do
        undef_method :__hecho_por_tortugas if method_defined? :__hecho_por_tortugas
        undef_method :turtle_chain if method_defined? :turtle_chain
        undef_method :turtle_eval if method_defined? :turtle_eval
      end
      c
    end

    # Sends the value of the turtle_chain to the given method on the turtle_root
    # object (by default turtle_eval). Optional block preprocesses the chain.
    def nil.eval_turtles!( &block )
      root = Turtles.turtle_root
      c = Turtles.last_chain
      if block_given?
        c = block.call(c)
      end
      result = root.send(root.class.turtle_evaluator, c)
      Turtles.turtle_root = nil
      result
    end
  end
  private :turtlize_nil!

  # For this thread of execution, the last chain of turtle calls, defined as
  # a chain that starts from an object, and goes through 0 or more instances
  # of NilClass. This is self-clearing by default - in other words, once
  # asked for, the caller is the only one with a reference to the array.
  def last_chain( preserve=false )
    Thread.current[:turtle_chain] ||= []
    if preserve
      Thread.current[:turtle_chain]
    else
      old = Thread.current[:turtle_chain].dup
      Thread.current[:turtle_chain] = nil
      old
    end
  end
  module_function :last_chain

  # Defines the root object of a chain of turtle calls. 
  # Set when a chain of calls on a non-turtlized nil object is initiated.
  def turtle_root
    Thread.current[:turtle_root]
  end
  def turtle_root= obj
    Thread.current[:turtle_root] = obj
  end
  module_function :turtle_root, :turtle_root=

  # Defines a method, overridable in callers, which will recieve
  # the value of the chain- example [:m0, :m1, :m2], and return it by default
  # obj.m0.m1.m2.eval_turtles!
  def turtle_eval( chain, &block )
    chain
  end

  # When we return nil through turtles, we add a singleton method on it to
  # mark it so we can build up a memory of the last call chain
  def method_missing_with_turtles(sym, *args, &block)
    if self.class.turtles? || self == nil

      # initialize the stack when called on an object not returned by turtles
      unless self.respond_to?(:__hecho_por_tortugas)
        Turtles.last_chain(true).clear
        Turtles.turtle_root = self
      end
      Turtles.last_chain(true).push sym

      turtlize_nil!
      nil
    else
      method_missing_without_turtles(sym, *args, &block)
    end
  end

end

# By default nil gets turtlized when this module is required. 
# Comment out if this is not desired behavior
#NilClass.class_eval do
#   include Turtles; # thus enabling it
#end

def turtles?
  NilClass.turtles?
end

def turtles!
  NilClass.turtles!
end

def no_turtles!
  NilClass.no_turtles!
  # NilClass.uninclude(Turtles) # for which versions of ruby/rails can you uninclude Modules
end

# Serves as a tool to narrow the scope for turtles and the thread-local turtle chain
def with_turtles
  already_turtles = turtles?
  turtles!
  begin
    result = yield
  ensure
    no_turtles! unless already_turtles
  end
  result
end

