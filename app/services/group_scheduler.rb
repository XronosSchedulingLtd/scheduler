# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2018 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

class GroupScheduler
  def initialize(group)
    @mygroup = group
  end

  #
  #  Provided initialisation parameters for FullCalendar in JSON form.
  #
  def fc_parameters_json
    #
    #  Where we need an identifying ID, we will always base it on the
    #  element id so they are reliably unique.
    #
    name = @mygroup.name
    resources = Array.new
    generate_resource_lines(resources, @mygroup)
    data = {
      resources: resources
    }
    data.to_json.html_safe
  end

  private

  def generate_resource_lines(resources, group)
    name = group.name
    if group.can_have_requests?
      resources << {
        id:         "R#{group.element.id}",
        parentName: name,
        title:      'Requests'
      }
    end
    group_members, other_members =
      group.members(nil, false).partition {|m| m.is_a? Group}
    other_members.each do |member|
      resources << {
        id:         "M#{member.element.id}",
        parentName: name,
        title:      member.name
      }
    end
    group_members.each do |gm|
      generate_resource_lines(resources, gm)
    end
  end

end
