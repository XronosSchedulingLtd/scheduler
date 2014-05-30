module Elemental
  extend ActiveSupport::Concern

  included do
    has_one :element, :as => :entity, :dependent => :destroy

    after_save :update_element

  end

  module ClassMethods
  end

  #
  #  This method makes sure we keep our element record.
  #
  def update_element
    if self.element
      if self.active
        if self.element.name != self.element_name
          self.element.name = self.element_name
          self.element.save
        end
      else
        #
        #  An inactive entity shouldn't have an element.
        #
        self.element.destroy
      end
    else
      if self.active
        Element.create(:name => self.element_name,
                       :entity => self)
      end
    end
  end

  #
  #  And shims to provide access to the instance methods in Element
  #
  def groups(given_date = nil, recurse = true)
    self.element.groups(given_date, recurse)
  end

end
