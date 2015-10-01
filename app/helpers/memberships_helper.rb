module MembershipsHelper
  def membership_entries_for(group, target_class, editing)
    memberships =
      group.memberships_on.select {|m| m.element.entity_type == target_class.to_s}
    if editing
      memberships.collect {|m|
        "<span#{
           m.inverse ? " class=\"excluded_member\"" : ""
         }>#{h(m.element.name)} #{
          link_to("&#215;".html_safe, m, method: :delete, remote: true)
        }</span>"
      }.join("<br/>").html_safe
    else
      memberships.collect {|m|
        "<span#{
          m.inverse ? " class=\"excluded_member\"" : ""
         }>#{h(m.element.name)}</span>"
      }.join("<br/>").html_safe
    end
  end

  def atomic_entries(atomic_membership, target_class)
    candidates = atomic_membership.select {
      |item| item.class == target_class
    }.sort
    if candidates.size > 50
      names =
        (candidates.first(50).collect{|item| h(item.element.name)} +
         ["... (and #{candidates.size - 50} more)"])
    else
      names = candidates.collect{|item| h(item.element.name)}
    end
    names.join("<br/>").html_safe
  end
end
