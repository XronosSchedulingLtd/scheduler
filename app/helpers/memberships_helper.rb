module MembershipsHelper
  def membership_entries_for(group, target_class, editing)
    memberships =
      group.inclusions_on.select {|m| m.element.entity_type == target_class.to_s}
    if editing
      memberships.collect {|m| h(m.element.name) + " " + link_to("&#215;".html_safe, m, method: :delete, remote: true) }.join("<br/>").html_safe
    else
      memberships.collect {|m| h(m.element.name) }.join("<br/>").html_safe
    end
  end
end
