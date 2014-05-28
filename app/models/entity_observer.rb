class EntityObserver < ActiveRecord::Observer

  observe Pupil, Staff

  #  This should be called each time one of my observed entities has
  #  been saved to the database.
  def after_save(entity)
    if entity.element
      if entity.active
        if entity.element.name != entity.element_name
          entity.element.name = entity.element_name
          entity.element.save
        end
      else
        #
        #  An inactive entity shouldn't have an element.
        #
        entity.element.destroy
      end
    else
      if entity.active
        Element.create(:name => entity.element_name,
                       :entity => entity)
      end
    end
  end

# This bit isn't needed because we can use dependencies to achieve
# the same thing.

#  def after_destroy(entity)
#    if entity.element
#      entity.element.destroy
#    end
#  end

end
