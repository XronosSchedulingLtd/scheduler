module ApplicationHelper

  #
  #  Passed true or false, will return an <img> tag for
  #  the appropriate icon, already wrapped up as html_safe.
  #
  def boolean_icon(value)
    "<img src=\"/images/#{ value ? "true16.png" : "false16.png" }\"/>".html_safe
  end

  #
  #  Called every time we want to display something, perhaps with a
  #  link.  Some users get links, others don't.  This handles that
  #  decision and returns appropriate text.
  #
  def be_linken(name, element)
    #
    #  It's just possible that we will get passed null as the element
    #  because some things are linked in without being active.  E.g.
    #  OTL uses non-existent staff for some Private Study periods.
    #
    if user_can_roam? && element
      link_to(h(name), element_path(element))
    else
      h(name)
    end
  end

  def be_hover_linken(title, name, element)
    if title
      "<span title=\"#{title}\">#{be_linken(name, element)}</span>"
    else
      be_linken(name, element)
    end
  end

  def title_text
    if known_user?
      Setting.title_text
    else
      Setting.public_title_text
    end
  end

  def single_flag(f, content)
    if content[:annotation]
      #
      #  Explicit annotation given.
      #
      annotation = content[:annotation]
    else
      #
      #  Can the model supply anything?
      #
      if f.object.respond_to?(:field_title_text)
        annotation = f.object.field_title_text(content[:field])
      else
        annotation = ""
      end
    end
    result = Array.new
    if content[:disabled]
      result << "    #{f.check_box(content[:field], disabled: true)}"
    else
      result << "    #{f.check_box(content[:field],
                                   title: annotation)}"
    end
    if content[:prompt]
      result << "    #{f.label(content[:field],
                               content[:prompt],
                               title: annotation)}"
    else
      result << "    #{f.label(content[:field],
                               title: annotation)}"
    end
    result.join("\n").html_safe
  end

  #
  #  Note - currently works properly only for user permission bits.
  #
  def single_tscb(f, parent, field, key, defaults)
    result = Array.new
    result << "<span class='tscb spaced-tscb' title='#{User.field_title_text(key)}'#{ defaults ? " data-default-value='#{defaults[key]}'" : ""}>"
    result << hidden_field_tag("#{parent.class.to_s.underscore}[#{field.to_s}][#{key.to_s}]",
                               parent[field][key],
                               size: 2,
                               class: 'tscb-field')
    result << "#{ f.label(PermissionFlags.nicer_text(key))}"
    result << "</span>"
    result.join("\n").html_safe
  end

  def flag_group(f, small_cols, med_cols, label, contents)
    result = Array.new
    result << "<div class='small-#{small_cols} medium-#{med_cols} columns'>"
    result << "  <label>#{label}</label>"
    contents.each_with_index do |content, i|
      result << single_flag(f, content)
      if (i + 1) % 3 == 0
        result << "<br/>"
      end
    end
    result << "</div>"
    result.join("\n").html_safe
  end

  def tscb_group(f, parent, field, small_cols, med_cols, label, keys, defaults = nil)
    result = Array.new
    result << "<div class='small-#{small_cols} medium-#{med_cols} columns tscb-zone'>"
    result << "  <label>#{label}</label>"
    keys.each_with_index do |key, i|
      result << single_tscb(f, parent, field, key, defaults)
      if (i + 1) % 3 == 0
        result << "<br/>"
      end
    end
    result << "</div>"
    result.join("\n").html_safe
  end

  #
  #  Take a piece of plain text, with line breaks, and convert it to
  #  the equivalent HTML with <br/> characters.  Escape any dangerous
  #  input, and flag the result as html_safe.
  #
  def preserve_line_breaks(text)
    h(text).gsub("\n", '<br/>').html_safe
  end

end
