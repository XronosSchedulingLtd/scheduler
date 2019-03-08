# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class GroupScheduler
  def initialize(group)
    @mygroup = group
  end

  #
  #  Provided list of resources for FullCalendar
  #
  def fc_resources
    #
    #  Where we need an identifying ID, we will always base it on the
    #  element id so they are reliably unique.
    #
    name = @mygroup.name
    resources = Array.new
    generate_resource_lines(resources, @mygroup)
    resources
  end

  def fc_events(session, current_user, params)
    #
    #  We need to return both events attached to real resources, and
    #  requests attached to any groups.  They all go in a single array
    #  and FC will sort out displaying them against the right resource,
    #  provided we put the right resource id in each one.
    #
    events = Array.new
    ea = EventAssembler.new(session, current_user, params)
    generate_events(events, ea, @mygroup)
    events
  end

  private

  def generate_events(events, ea, group)
    name = group.name
    if group.can_have_requests?
      ea.requests_for(group).each do |e|
        events << e
      end
    end
    group_members, other_members =
      group.members(nil, false).partition {|m| m.is_a? Group}
    #
    #  Now the actual commitments for the immediate, non-group members
    #  of this group.
    #
    other_members.each do |member|
      ea.events_for(member).each do |e|
        events << e
      end
    end
    group_members.each do |gm|
      generate_events(events, ea, gm)
    end
  end

  def generate_resource_lines(resources, group)
    name = group.name
    if group.can_have_requests?
      data = {
        id:         group.element.id,
        parentName: name,
        title:      'Requests'
      }
      if group.element.preferred_colour
        data[:colour] = group.element.preferred_colour
      end
      resources << data
    end
    group_members, other_members =
      group.members(nil, false, false, true).partition {|m| m.is_a? Group}
    #
    #  We need sort only the resource lines.  The events will follow
    #  their resources around because they're identified by id.
    #
    other_members.sort.each do |member|
      resources << {
        id:         member.element.id,
        parentName: name,
        title:      member.name
      }
    end
    group_members.each do |gm|
      generate_resource_lines(resources, gm)
    end
  end

end
