module UserProfilesHelper
  def icon_for(user_profile, key)
    if user_profile.permissions[key] == PermissionFlags::PERMISSION_YES
      "/images/true16.png"
    else
      "/images/false16.png"
    end
  end
end
