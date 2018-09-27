
module GroupsHelper

  def autocomplete_path(which_finder)
    case which_finder
    when :resource
      autocomplete_resourcegroup_element_name_elements_path
    when :mine
      autocomplete_my_group_element_name_elements_path
    else
      autocomplete_group_element_name_elements_path
    end
  end

end
