# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

#
#  Assemble a list of potential quick buttons for the current system
#  configuration and event.
#
class QuickButtons < Array
  def initialize(event)
    super()
    #
    #  Pre-requisites are getting to be perhaps slightly mis-named
    #  They were originally intended for selection *before* the event
    #  was created, hence the name, but now we are treating them as
    #  more general highlighted items.  We give a button for
    #  each one which isn't already attached to the event.
    #
    #  Even a tentative attachment (awaiting approval) suppresses
    #  the corresponding button.
    #
    existing_element_ids = event.commitments.collect {|c| c.element_id}
    PreRequisite.order(:priority).each do |pr|
      unless existing_element_ids.include?(pr.element_id)
        self << pr
      end
    end
  end
end
