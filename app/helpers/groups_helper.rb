
module GroupsHelper

  def autocomplete_path(which_finder)
    case which_finder
    when :resource
      autocomplete_resourcegroup_name_groups_path
    when :owned
      autocomplete_owned_group_name_groups_path
    when :old_owned
      autocomplete_old_owned_group_name_groups_path
    when :deleted
      autocomplete_old_group_name_groups_path
    else
      autocomplete_group_name_groups_path
    end
  end

end
