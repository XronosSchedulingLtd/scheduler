# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2015 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

require 'csv'

class ElementsController < ApplicationController

  #
  #  A class to hold a set of groups, each of a similar type.
  #
  class GroupSet < Array
    attr_reader :title

    def initialize(title, contents)
      super(contents)
      if self.size == 1
        @title = title
      else
        @title = "#{title}s"
      end
    end

    def to_partial_path
      "group_set"
    end

  end

  #
  #  A class to sort and hold a collection of groups.  All groups of the
  #  same type are put in a GroupSet, and then we hold all the GroupSets.
  #
  class GroupSetHolder < Array

    KNOWN_GROUP_ORDERING = [
      "Tutor",
      "Teaching",
      "Otherhalf",
      "Tag",
      "Vanilla"]

    NICER_NAMES = {
      "Tutor"     => "Tutor Group",
      "Teaching"  => "Teaching Set",
      "Otherhalf" => "Other Half Group",
      "Tag"       => "Custom Group",
      "Vanilla"   => "Plain Group"
    }

    def initialize(contents, old_contents = [])
      #
      #  Explicitly don't want to pass our parameter in to the
      #  Array#initialize.  We will add the contents.
      #
      super()
      unless contents.empty?
        type_hash = Hash.new
        contents.each do |group|
          type = group.type
          type_hash[type] ||= Array.new
          type_hash[type] << group
        end
        #
        #  And now add them in order to our array, sorting them as they go.
        #
        KNOWN_GROUP_ORDERING.each do |type|
          if type_hash[type]
            title = NICER_NAMES[type] || type
            self << GroupSet.new(title, type_hash[type].uniq.sort)
          end
        end
      end
      #
      #  And any erstwhile groups?
      #
      unless old_contents.empty?
        type_hash = Hash.new
        old_contents.each do |group|
          type = group.type
          type_hash[type] ||= Array.new
          type_hash[type] << group
        end
        #
        #  And now add them in order to our array, sorting them as they go.
        #
        KNOWN_GROUP_ORDERING.each do |type|
          if type_hash[type]
            title = NICER_NAMES[type] || type
            self << GroupSet.new("Former #{title}", type_hash[type].uniq.sort)
          end
        end
      end
    end

  end

  #
  #  A class to hold a set of members, each of a similar type.
  #
  class MemberSet < Array
    attr_reader :type

    def initialize(type, contents)
      super(contents)
      @type = type
    end

    def to_partial_path
      "member_set"
    end

  end

  #
  #  A class to sort and hold a collection of members.  All members of the
  #  same type are put in a MemberSet, and then we hold all the MemberSets.
  #
  class MemberSetHolder < Array

    def initialize(contents)
      #
      #  Explicitly don't want to pass our parameter in to the
      #  Array#initialize.  We will add the contents.
      #
      super()
      unless contents.empty?
        type_hash = Hash.new
        contents.each do |member|
          type = member.class.to_s
          type_hash[type] ||= Array.new
          type_hash[type] << member
        end
        #
        #  And now add them in order to our array, sorting them as they go.
        #
        type_hash.each do |type, members|
          self << MemberSet.new(type, members.sort)
        end
      end
    end

  end

  #
  #  It would be nice to be able to use a line like the following to
  #  generate by action, but unfortunately one of my scopes needs
  #  a parameter.  Hence I have to do it manually.
  #
  #autocomplete :element, :name, :scopes => [:current, :mine_or_system], :full => true

  def autocomplete_element_name
    term = params[:term].split(" ").join("%")
    elements =
      Element.current.
              mine_or_system(current_user).
              where('name LIKE ?', "%#{term}%").
              order("LENGTH(elements.name)").
              order(:name).
              all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  def autocomplete_unowned_element_name
    term = params[:term].split(" ").join("%")
    elements =
      Element.current.
              disowned.
              mine_or_system(current_user).
              where('name LIKE ?', "%#{term}%").
              order("LENGTH(elements.name)").
              order(:name).
              all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  def autocomplete_staff_element_name
    term = params[:term].split(" ").join("%")
    elements =
      Element.current.
              staff.
              mine_or_system(current_user).
              where('name LIKE ?', "%#{term}%").
              order(:name).
              all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  def autocomplete_group_element_name
    term = params[:term].split(" ").join("%")
    elements =
      Element.current.
              agroup.
              mine_or_system(current_user).
              where('name LIKE ?', "%#{term}%").
              order("LENGTH(elements.name)").
              order(:name).
              all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  def autocomplete_property_element_name
    term = params[:term].split(" ").join("%")
    elements =
      Element.current.
              property.
              where('name LIKE ?', "%#{term}%").
              order("LENGTH(elements.name)").
              order(:name).
              all
    render :json => elements.map { |element| {:id => element.id, :label => element.name, :value => element.name} }
  end

  #
  #  This method does a lot of work in showing various kinds of information
  #  for various types of element.  Each element has a corresponding entity
  #  which currently may be:
  #
  #    Pupil
  #    Staff
  #    Group
  #    Location
  #    Service
  #    Property
  #    Subject
  #
  #  and depending on which one you're looking at, and how far back we
  #  have information about it, you will get to see different panels
  #  and columns.
  #
  #  The most interesting item is the @mwd_set, which stands for
  #  MembershipWithDuration Set.  It is generated by some very clever
  #  code in the Element and Membership models which works by recursion
  #  and eventually produces a whole lot of membership records, grouped
  #  by the duration for which our element was a member of those sets.
  #  (When I say "eventually", the code is actually extremely fast.)
  #
  #  Each membership record in turn allows us to find a group of which
  #  this element was a member at some time, but we work with the
  #  membership record because it contains more information and from it
  #  the group is trivial to find.  The other way around is much more
  #  difficult.
  #
  #  Our element may well not have been a direct member of
  #  the indicated group.  It could be many layers of nested memberships
  #  away, but by the time we get the MWD_Set the hard work has been done.
  #  We now know that our element *was* a member of the indicated group,
  #  and the membership record which we're looking at is the last link
  #  in the chain.
  #
  #  Note that we need to use the duration from the MembershipWithDuration
  #  record, and not that in the indicated membership record.  Consider
  #  the following example.
  #
  #  Able is a member of GroupA from 1st Feb to 28th Feb
  #  GroupA is a member of GroupB from 1st Jan to 31st Mar
  #
  #  When we are asked to show Able's memberships, the membership
  #  record linking GroupA to GroupB will be returned (indicating that
  #  he was a member of GroupB) but the corresponding duration will
  #  be 1st to 28th Feb.  This is given in the MembershipWithDuration
  #  record, but will not match what is in the Membership record (1st Jan
  #  to 31st Mar).
  #
  def show
    @element = Element.find(params[:id])
    #
    #  Users who can't roam are allowed to look only at
    #  things for which they currently have concerns.
    #
    if can_roam? || current_user.concern_with(@element)
      @mwd_set = @element.memberships_by_duration(start_date: nil,
                                                  end_date: nil)
      #
      #  We want to break things up by era.
      #
      all_eras = Era.all.to_a
      #
      #  Get other eras in reverse chronological order.
      #
      current_era = Setting.current_era
      perpetual_era = Setting.perpetual_era
      other_eras =
        (all_eras - [current_era, perpetual_era]).sort.reverse
      current_eras_mwd_set = @mwd_set.filter_to(current_era)
      #
      #  Now we're going to construct one or more panels which display
      #  information for this element.  All elements get a current panel.
      #  Most get some history too.
      #
      @panels = Array.new
      #
      #  Some more detailed processing for the current era's stuff.
      #
      #  Direct groups are given by memberships which are current,
      #  and which have a level of 1.  The current-ness can be decided
      #  whilst the mwds are still grouped, but then the level applies
      #  to each membership record individually.
      #
      panel = DisplayPanel.new(0, "Current", true)
      memberships = current_eras_mwd_set.current_grouped_mwds.flatten
      old_memberships = current_eras_mwd_set.past_grouped_mwds.flatten
      populate_panel(panel, memberships, old_memberships, @element, current_era)
      @panels << panel
      if @element.show_historic_panels?
        index = 1
        other_eras.each do |era|
          era_set = @mwd_set.filter_to(era)
          unless era_set.empty? || era.starts_on > Date.today
            panel = DisplayPanel.new(index, era.short_name, false)
            index += 1
            memberships = era_set.grouped_mwds.flatten
            populate_panel(panel, memberships, [], @element, era)
            @panels << panel
          end
        end
      end
    else
      render :forbidden
    end
  end

  IcalDataSet = Struct.new(:prefix, :data)

  # GET /elements/:id/ical
  def ical
    #
    #  We expect to find the element by id, but if that doesn't work then
    #  for reverse compatibility, we'll let emulate what the staffs
    #  controller used to do.
    #
    #  Because creating an ical download is an expensive operation
    #  (5 to 10 seconds) we cache the result for an hour.  We won't
    #  re-generate it within that hour.
    #
    cal_data = Rails.cache.fetch(request.env["ORIGINAL_FULLPATH"],
                                 :expires_in => 1.hour,
                                 :race_condition_ttl => 10.seconds) do
      got_something = false
      any_params    = false
      by_initials   = false
      prefix = "notset"
      calendar_name = "notset"
      calendar_description = "notset"
      include_cover = true
      include_non_cover = true
      customer_categories = nil
      remove_categories = []
      era = Setting.previous_era || Setting.current_era
      starts_on = era.starts_on
      ends_on = :never
      element_id = params[:id]
      if params.has_key?(:cover)
        any_params = true
        #
        #  The requestor wants only cover events.
        #
        include_non_cover = false
      elsif params.has_key?(:"!cover")
        any_params = true
        #
        #  The requestor wants to exclude cover events.
        #
        include_cover = false
      end
      if params[:start_date]
        any_params = true
        starts_on  = Date.parse(params[:start_date])
      end
      if params[:end_date]
        any_params = true
        ends_on    = Date.parse(params[:end_date])
      end
  #    Rails.logger.debug("include_cover = #{include_cover}.  include_non_cover = #{include_non_cover}.")
      if params[:categories]
        any_params = true
        #
        #  The requester wants to limit the request to certain categories
        #  of event.  Requests for non-existent categories will result in
        #  no events.
        #
        #  You can't select categories which aren't flagged as allowing
        #  ical downloads.
        #
        remove_category_names, customer_category_names =
          params[:categories].split(",").partition{|n| n[0] == "!"}
        #
        #  Calendar events used to be specified by event category,
        #  but now it's a property.  Provide a touch of reverse
        #  compatibility.
        #
        if (element_id == '0') && customer_category_names.include?("Calendar")
          calendar_element = Element.find_by(name: "Calendar")
          if calendar_element
            element_id = calendar_element.id.to_s
          end
        else
          customer_categories = customer_category_names.collect { |ccn|
            Eventcategory.find_by_name(ccn)
          }.compact.select {|cc| cc.publish}
          remove_categories = remove_category_names.collect { |rcn|
            Eventcategory.find_by_name(rcn[1..-1])
          }.compact
          #
          #  There is a slight danger that if the requestor specifies only
          #  invalid categories then we end up with an empty list, which
          #  would result in us sending events from *all* categories.
          #  Prevent this.
          #
          if customer_categories.size == 0
            customer_categories = nil
          end
        end
        #raise customer_categories.inspect
      end
      if element_id == '0'
        #
        #  Request for the breakthrough events.
        #
        categories =
          (customer_categories || Eventcategory.publish.schoolwide) - remove_categories
        if categories.empty?
          categories = Eventcategory.publish.schoolwide
        end
        dbevents = Event.events_on(starts_on,
                                   ends_on,
                                   categories)
        got_something = true
        prefix = "global"
        calendar_name = "School dates"
        calendar_description = "Abingdon school key dates"
      else
        element = Element.find_by_id(element_id)
        unless element
          staff = Staff.eager_load(:element).find_by_initials(params[:id].upcase)
          if staff
            element = staff.element
            by_initials = true
          end
        end
        if element
          if by_initials && !any_params
            #
            #  We fall back to old-style processing for reverse compatibility.
            #
            basic_categories = Eventcategory.publish
            extra_categories = Eventcategory.publish.schoolwide
            dbevents =
              (element.
                 commitments_on(startdate: starts_on,
                                enddate: ends_on,
                                eventcategory: basic_categories,
                                effective_date: Setting.current_era.starts_on).
                 firm.
                 includes(event: {elements: :entity}).collect {|c| c.event} +
               Event.events_on(starts_on, ends_on, extra_categories).
                     includes(elements: :entity)).uniq
            got_something = true
            prefix = staff.initials
            calendar_name = staff.initials
            calendar_description = "#{staff.name}'s timetable"
          else
            #
            #  Either specified by id number, or by initials but with some
            #  parameters.
            #
            categories =
              (customer_categories || Eventcategory.publish) - remove_categories
            if categories.empty?
              categories = Eventcategory.publish
            end
            selector =
              element.
                commitments_on(startdate:      starts_on,
                               enddate:        ends_on,
                               eventcategory:  categories,
                               effective_date: Setting.current_era.starts_on).firm
            if include_cover && !include_non_cover
              selector = selector.covering_commitment
            elsif include_non_cover && !include_cover
              selector = selector.non_covering_commitment
            end
            #
            #  Solved it.  I was trying to do too much work for Active Record.
            #  By explicitly loading the commitments and then the corresponding
            #  elements, I hid from AR the fact that it had now got the elements
            #  for the event.  My definition of an event includes the concept
            #  of a corresponding element (through the commitment) and that's
            #  how I subsequently access it, so that's how I need to load it.
            #
            dbevents =
              selector.includes(event: {elements: :entity}).collect {|c| c.event}
            got_something = true
            prefix = "E#{element.id}E"
            if include_non_cover
              calendar_name = element.short_name
            else
              calendar_name = "#{element.short_name}'s cover"
            end
            calendar_description = "#{element.name}'s events"
          end
        end
      end
      unless got_something
        #
        #  Invalid requests now get a useless file.
        #
        calendar_name = "Unknown"
        calendar_description = "Request was invalid"
        prefix = "INVALID"
        dbevents = []
      end
      generated_data = RiCal.Calendar do |cal|
        dtstamp = Time.zone.now
        cal.add_x_property("X-WR-CALNAME", calendar_name)
        cal.add_x_property("X-WR-CALDESC", calendar_description)
        dbevents.each do |dbevent|
          cal.event do |event|
            event.summary = dbevent.body
            if dbevent.all_day
              event.dtstart = dbevent.starts_at.to_date
              event.dtend   = dbevent.ends_at.to_date
            else
              event.dtstart = dbevent.starts_at
              event.dtend   = dbevent.ends_at
            end
            locations = dbevent.locations
            if locations.size > 0
              event.location = locations.collect {|l| l.friendly_name}.join(",")
            end
            event.uid = "e#{dbevent.id}@#{Setting.hostname}"
            event.dtstamp = dtstamp
#            event.created = dbevent.created_at
#            event.last_modified = dbevent.updated_at
          end
        end
      end.export
      IcalDataSet.new(prefix,
                      generated_data)
    end
    send_data(cal_data.data,
              :filename => "#{cal_data.prefix}.ics",
              :type => "application/ics")
  end

  def authorized?(action = action_name, resource = nil)
    (logged_in? && current_user.known?) ||
    action == 'ical'
  end

  private

  def populate_panel(panel, memberships, old_memberships, element, era)
    element.entity.display_columns.each do |col|
      case col
      when :dummy
        panel.add_column(:dummy, nil)
      when :direct_groups
        groups =
          memberships.select {|m| m.level == 1}.
                      collect {|m| m.group}.
                      select {|g| g.public?}.sort
        old_groups =
          old_memberships.select {|m| m.level == 1}.
                          collect {|m| m.group}.
                          select {|g| g.public?}.sort
        grouped_direct_groups = GroupSetHolder.new(groups, old_groups)
        panel.add_column(:direct_groups, grouped_direct_groups)
      when :indirect_groups
        indirect_groups =
          memberships.select {|m| m.level != 1}.
                      collect {|m| m.group}.
                      select {|g| g.public?}.sort.uniq
        grouped_indirect_groups = GroupSetHolder.new(indirect_groups)
        panel.add_column(:indirect_groups, grouped_indirect_groups)
      when :taught_groups
        panel.add_column(:taught_groups,
                         GroupSetHolder.new(
                           element.entity.tutorgroups.ofera(era) +
                           element.entity.groupstaught.ofera(era).sort))
      when :members
        panel.add_column(:members,
                         MemberSetHolder.new(element.entity.members))
      when :subject_teachers
        panel.add_column(:subject_teachers,
                         element.entity.staffs.current.sort)
      when :subject_groups
        teachinggroups = element.entity.teachinggroups.sort
        panel.add_column(:subject_groups,
                         GroupSet.new("#{teachinggroups.count} teaching set",
                                      teachinggroups))
      else
        Rails.logger.error("Don't know how to handle #{col} for display.")
      end
    end
  end
end
