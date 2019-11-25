#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  This module enables the import of data from an XML source.
#
#  Within your class, specify an XML_SELECTOR and an XML_REQUIRED_FIELDS
#  constant, then include this module.
#
#  For each chunk you want to import, call self.slurp.
#
#  You need to provide a YourClass#adjust method, and optionally
#  a YourClass#initialize_generic_bit method.
#
#  The slurp method will create N instances of objects of your class,
#  N being driven by how many entries it finds in the XML.  For each
#  instance the adjust and initialize_generic_bit methods will be
#  called, and then the whole lot will be returned as an array.
#

XmlField = Struct.new(:selector, :attr_name, :source_type, :target_type)

module XMLImport
  def self.included(parent)
    parent.extend ClassMethods
    parent.prepend Initializer
    parent::REQUIRED_FIELDS.each do |field|
      attr_accessor field[:attr_name]
    end
    attr_reader :entry
  end

  #
  #  Default to true.  May well be over-ridden in the class.
  #
  def wanted?
    true
  end

  #
  #  Likewise, may well be over-ridden.
  #
  def adjust
  end

  module Initializer

    def initialize(entry)
#      puts "In XMLImport initialize"
      @entry = entry
      self.class::REQUIRED_FIELDS.each do |field|
        attr_name = field[:attr_name]
        if field[:source_type] == :attribute
          attr = entry.attribute(field[:selector])
          if attr
            if field[:target_type] == :string
              self.send("#{attr_name}=", attr.value)
            else
              self.send("#{attr_name}=", attr.value.to_i)
            end
          else
            if field[:target_type] == :string
              self.send("#{attr_name}=", "")
            else
              self.send("#{attr_name}=", nil)
            end
          end
        else
          contents = entry.at_css(field[:selector])
          if contents
            if field[:target_type] == :string
              self.send("#{attr_name}=", contents.text)
            else
              self.send("#{attr_name}=", contents.text.to_i)
            end
          else
            #
            #  For ease of processing, missing strings are taken as
            #  empty strings, but missing values are set as nil.
            #
            if field[:target_type] == :string
              self.send("#{attr_name}=", "")
            else
              self.send("#{attr_name}=", nil)
            end
          end
        end
      end
      super
    end

  end

  module ClassMethods
    def slurp(data, verbose = true)
      results = Array.new
      entries = data.css(self::SELECTOR)
      if entries && entries.size > 0
        entries.each do |entry|
          rec = self.new(entry)
          rec.adjust
          if rec.respond_to?(:initialize_generic_bit)
            rec.initialize_generic_bit
          end
          if rec.wanted?
            results << rec
          end
        end
      else
        puts "Unable to find entries using selector \"#{self::SELECTOR}\"." if verbose
      end
      results
    end
  end
end
