class Freefinder < ActiveRecord::Base

  belongs_to :element

  attr_reader :free_elements, :done_search

  def element_name
    self.element ? self.element.name : ""
  end

  def element_name=
    # Not interested
  end

  def start_time_text
    if self.start_time
      self.start_time.strftime("%H:%M")
    else
      ""
    end
  end

  def start_time_text=(value)
    self.start_time = Chronic.parse(value)
  end

  def end_time_text
    if self.end_time
      self.end_time.strftime("%H:%M")
    else
      ""
    end
  end

  def end_time_text=(value)
    self.end_time = Chronic.parse(value)
  end

  def do_find
    #
    #  The very minimum which we need in order to do our work is a
    #  group with which to start.  If date and time aren't specified
    #  then each defaults to "now".
    #
    if self.element && self.element.entity.instance_of?(Group)
      target_group = self.element.entity
      #
      #  Need to convert separately specified dates and times (or possibly
      #  not specified) into two unified delimiters.
      #
      self.on ||= Date.today
      if self.start_time
        start_string = self.start_time.strftime("%H:%M:00")
      else
        start_string = Time.zone.now.strftime("%H:%M:00")
        self.start_time = Chronic.parse(start_string)
      end
      if self.end_time
        end_string = self.end_time.strftime("%H:%M:00")
      else
        end_string = start_string
        self.end_time = Chronic.parse(end_string)
      end
      starts_at = Time.zone.parse(start_string, self.on)
      ends_at = Time.zone.parse(end_string, self.on)
      #
      #  Now - I need to have a list of all the all the atomic elements
      #  which were members of this group on the specified date.
      #
      member_elements =
        target_group.members(self.on, true, true).collect {|e| e.element}
      Rails.logger.debug("Found #{member_elements.size} possible elements.")
      #
      #  And a list of all the events occuring at the specified time,
      #  from which we construct a list of all the elements committed to
      #  those events.
      #
      #  Note that, although the commitments_on method allows a list
      #  of resources to be specified, it only checks for commitments
      #  directly involving those resources.  Generally ours will be
      #  involved by way of a group membership, so we need to be
      #  slightly more long-winded.
      #
      #  End times are treated throughout the application as being
      #  exclusive, which leads to a slight problem here.  If someone
      #  enters an end time which is exactly the same as the start time
      #  (or leaves it blank) then we will not detect an overlap with
      #  an event which starts at exactly the same time.  This is technically
      #  correct, but surprises people.  Hence we add 1 second to our
      #  specified end time, so that we run on into the next slot.
      #
      overlapping_commitments =
        Commitment.commitments_during(start_time: starts_at,
                                      end_time: ends_at + 1.second)
      Rails.logger.debug("Found #{overlapping_commitments.size} overlapping commitments.")
      #
      #  Now I need a list of all the non-group entities referenced through
      #  these commitments.
      #
      committed_elements = Array.new
      overlapping_commitments.each do |oc|
        if oc.element.entity.instance_of?(Group)
          committed_elements += 
            oc.element.entity.members(self.on,
                                      true,
                                      true).collect {|e| e.element}
        else
          committed_elements << oc.element
        end
      end
      committed_elements = committed_elements.uniq
      #
      #  And now subtract
      #
      @free_elements = member_elements - committed_elements
      @done_search = true
    else
      errors.add(:element_name,
                 "The name of an existing group must be specified.")
    end
  end

end
