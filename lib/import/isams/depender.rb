#
#  Depender module for use by extractor program
#  Copyright (C) Abingdon School, 2016
#

Dependency = Struct.new(:collection, :ident, :attr_name, :compulsory)

#
#  A module containing the common code used to set up dependencies
#  between records.
#
module Depender
  def self.included(parent)
    parent::DEPENDENCIES.each do |dependency|
      attr_accessor dependency[:attr_name]
    end
  end

  def find_dependencies(accumulator, dependencies, verbose = true)
    success = true
    dependencies.each do |dependency|
      collection = accumulator[dependency[:collection]]
      if collection
        required_ident = self.instance_variable_get("@#{dependency[:ident]}")
        item = collection[required_ident]
        if item
          self.instance_variable_set("@#{dependency[:attr_name]}", item)
        else
          unless required_ident == nil ||
                 required_ident == 0 ||
                 required_ident == -4995 ||
                 (required_ident.instance_of?(String) && required_ident.empty?) ||
                 !verbose
            puts "Unable to find entry #{required_ident} in #{dependency[:collection]} for #{self.class}."
          end
          if dependency[:compulsory]
            if verbose
              puts "Required ident was #{required_ident}"
            end
            success = false
          end
        end
      else
        puts "Unable to find #{dependency[:collection]} needed by #{self.class}."
        success = false
      end
    end
    success
  end

end

