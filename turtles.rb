#!/usr/bin/env ruby -w
#
# No warranty. And definitely no refunds.
#
# turtles.rb - Implement Object#andand in a turtles_all_the_way_down fashion.

# If you don't like this requirement, reimplement class_inheritable_accessor, et al. into your project
require 'active_support/core_ext'

module Turtles
  def self.included(base)
    base.class_eval do
      alias_method :method_missing_without_turtles, :method_missing
      alias_method :method_missing, :method_missing_with_turtles      

      # For a discussion of class_inheritable_accessor:
      # http://www.raulparolari.com/Rails/class_inheritable
      class_inheritable_accessor :turtles
      def self.turtles!;        self.turtles = true  ; end
      def self.no_turtles!;     self.turtles = false ; end
      def self.turtles?;     !! self.turtles         ; end
    end

    # Turtles are enabled by default upon inclusion
    base.turtles!
  end

  def method_missing_with_turtles(sym, *args, &block)
    if self.class.turtles?
      nil
    else
      method_missing_without_turtles(sym, *args, &block)
    end
  end

end

class NilClass
  include Turtles
end

def turtles?
  NilClass.turtles?
end

def turtles!
  NilClass.turtles!
end

def no_turtles!
  NilClass.no_turtles!
end

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

