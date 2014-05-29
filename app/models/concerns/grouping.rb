require 'activesupport/concern'

module Grouping
  extend ActiveSupport::Concern

  included do
    has_one :group, :as => :visible_group, :dependent => :destroy
  end

  module ClassMethods
  end

  #
  #  And some instance methods to make it look like we actually have
  #  members.  All are shims to the real methods in the Group model.
  #
  def add_member(item, as_of = nil)
    group.add_member(item, as_of)
  end

end
