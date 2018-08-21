module LocationsHelper

  def display_name_with_edit_links(location)
    display_aliases = location.display_aliases.sort
    (
      [location.name] +
      display_aliases.collect {|da|
        link_to(da.name, edit_locationalias_path(da))
      }
    ).join(" / ").html_safe
  end

  def other_aliases_edit_links(location)
    location.other_aliases.collect { |locationalias|
      link_to(locationalias.name, edit_locationalias_path(locationalias))
    }.join("<br/>").html_safe
  end

end
