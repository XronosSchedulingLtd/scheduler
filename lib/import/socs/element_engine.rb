#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

#
#  An engine to find elements as needed, cacheing the work which
#  it's done so far.
#
class ElementEngine

  def initialize
    @known_elements = Hash.new
  end

  def find(name_or_id)
    #
    #  Note the use of key? to check the hash, because some of
    #  the data items may be nil, which is falsey.
    #
    if @known_elements.key?(name_or_id)
      return @known_elements[name_or_id]
    else
      #
      #  Let's see if we can find it.  First assume it's a name, then
      #  an ID.  Note that ActiveRecord can cope with a numeric id
      #  being passed as a string.
      #
      element = Element.find_by(name: name_or_id)
      unless element
        element = Element.find_by(id: name_or_id)
      end
      #
      #  And now, whether or not element is nil, we store it in known_elements
      #  and return it.
      #
      @known_elements[name_or_id] = element
      return element
    end
  end

end

