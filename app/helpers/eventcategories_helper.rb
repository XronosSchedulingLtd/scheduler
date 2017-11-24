module EventcategoriesHelper
  def boolean_icon(value)
    if value
      icon = "true16.png"
    else
      icon = "false16.png"
    end
    "<img src=\"/images/#{icon}\"/>".html_safe
  end
end
