#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class LocationTreeNode
  attr_reader :location, :children

  #
  #  Note that each location tree node has zero or more offspring.
  #  It's like a fractal structure - each offspring is itself
  #  a location tree node.
  #
  def initialize(location)
    @location = location
    @children = Array.new
  end

  def note_child(ltn)
    @children << ltn
  end

  def <=>(other)
    if other.instance_of?(LocationTreeNode)
      self.location <=> other.location
    else
      nil
    end
  end

  #
  #  We are interested in any locations given by the selector which
  #  form part of a tree.  Others are discarded.
  #
  #  There are two possibilities:
  #
  #  1) A location is a root node
  #  2) A location is subsidiary
  #
  #  If neither of those applies, then we're not interested.
  #
  def self.generate(selector)
    #
    #  Let's hit the database just once.
    #
    candidates = selector.to_a
    #
    #  And hash them up by id.
    #
    locations_by_id = Hash.new
    parental_ids = Array.new
    candidates.each do |location|
      locations_by_id[location.id] = location
      if location.subsidiary?
        unless parental_ids.include?(location.subsidiary_to_id)
          parental_ids << location.subsidiary_to_id
        end
      end
    end
    #
    #  Now get rid of everything which is neither a parent nor subsidiary.
    #
    candidates, others = candidates.partition { |location|
      location.subsidiary? || parental_ids.include?(location.id)
    }
    #
    #  All the locations need a node record.
    #
    nodes_by_location_id = Hash.new
    candidates.each do |location|
      nodes_by_location_id[location.id] = LocationTreeNode.new(location)
    end
    other_nodes = Array.new
    others.each do |location|
      other_nodes << LocationTreeNode.new(location)
    end
    #
    #  And now organise them.
    #
    root_nodes = Array.new
    nodes_by_location_id.each do |location_id, node|
      if node.location.subsidiary?
        parent = nodes_by_location_id[node.location.subsidiary_to_id]
        if parent
          parent.note_child(node)
        else
          #
          #  This shouldn't happen, but put it at the top of the tree
          #  so we can at least see it.
          #
          root_nodes << node
        end
      else
        root_nodes << node
      end
    end
    root_nodes.sort + other_nodes.sort
  end

  def to_partial_path
    'location_tree_node'
  end
end

