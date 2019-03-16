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

  #
  #  Returns an appropriate path for listing pending items relating
  #  to the indicated element.  For most elements these will be concerns,
  #  but for ResourceGroups, these will be requests.
  #
  def owned_element_listing_path(element, pending = false)
    if element.entity.can_have_requests?
      if pending
        element_requests_path(element, pending: true)
      else
        element_requests_path(element)
      end
    else
      if pending
        element_commitments_path(element, pending: true)
      else
        element_commitments_path(element)
      end
    end
  end

  def li(text)
    "<li>#{text}</li>"
  end

  def dropdown(m, title_text, link = '#')
    m << "<li class='has-dropdown'>"
    m << link_to(title_text, link)
    m << "<ul class='dropdown'>"
    if block_given?
      yield
    end
    m << "</ul>"
    m << "</li>"
  end

  def li_link(m, title, link)
    m << li(link_to(title, link))
  end

  #
  #  Build the appropriate HTML for the menu for this user.
  #
  def menu_for(user)
    m = []
    dropdown(m, header_menu_text(user)) do
      if user.admin?
        dropdown(m, 'Admin') do
          li_link(m, 'E-mails', emails_path)
          dropdown(m, 'Models') do
            li_link(m, 'Data sources', datasources_path)
            li_link(m, 'Eras', eras_path)
            dropdown(m, 'Events', events_path) do
              li_link(m, 'Repeating', event_collections_path)
              dropdown(m, 'Categories', eventcategories_path) do
                li_link(m, 'Current', eventcategories_path(current: true))
                li_link(m, 'Deprecated', eventcategories_path(deprecated: true))
              end
              li_link(m, 'Sources', eventsources_path)
            end
            dropdown(m, 'Locations', locations_path) do
              li_link(m, 'Aliases', locationaliases_path)
              li_link(m, 'Owned', locations_path(owned: true))
            end
            li_link(m, 'Properties', properties_path)
            li_link(m, 'Pupils', pupils_path)
            li_link(m, 'Services', services_path)
            dropdown(m, 'Staff', staffs_path) do
              li_link(m, 'Active', staffs_path(active: true))
              li_link(m, 'Inactive', staffs_path(inactive: true))
            end
            li_link(m, 'Subjects', subjects_path)
            dropdown(m, 'Users', users_path) do
              li_link(m, 'Profiles', user_profiles_path)
            end
          end
          dropdown(m, 'Settings', settings_path) do
            li_link(m, 'Pre-requisites', pre_requisites_path)
          end
          li_link(m, 'Imports', imports_index_path)
          li_link(m, 'Day shape',
                  rota_template_type_rota_templates_path(
                    DayShapeManager.template_type))
        end
        dropdown(m, 'Groups', groups_path) do
          dropdown(m, 'All', groups_path) do
            li_link(m, 'Deleted', groups_path(deleted: true))
          end
          li_link(m, 'Mine', groups_path(mine: true))
          li_link(m, 'Resource', groups_path(resource: true))
          li_link(m, 'Tutor', tutorgroups_path)
        end
      elsif user.can_has_groups?
        li_link(m, 'Groups', groups_path)
      end
      if user.create_events?
        dropdown(m, events_menu_text(user), user_events_path(user)) do
          dropdown(m,
                   my_events_menu_text(user),
                   user_events_path(user, pending: true)) do
            li_link(m, 'All', user_events_path(user))
          end
          if user.admin?
            li_link(m, 'All', events_path)
          end
          user.owned_elements.each do |ce|
            dropdown(m,
                     controlled_element_menu_text(ce),
                     owned_element_listing_path(ce, true)) do
              li_link(m, 'All', owned_element_listing_path(ce))
            end
          end
        end
      end
      if user.can_find_free?
        li_link(m, 'Find free', new_freefinder_path)
      end
      if user.can_has_forms?
        li_link(m, 'Forms', user_forms_path)
      end
      if user.can_view_journal_for?(:events)
        dropdown(m, 'Journals', journals_path) do
          li_link(m, 'Current', journals_path(current: true))
          li_link(m, 'Deleted events', journals_path(deleted: true))
        end
      end
      if user.exams?
        dropdown(m, 'Invigilation') do
          li_link(m,
                  'Templates',
                  rota_template_type_rota_templates_path(
                    InvigilationManager.template_type))
          li_link(m, 'Cycles', exam_cycles_path)
          li_link(m, 'E-mails', new_notifier_path)
          li_link(m, 'Clashes', notifiers_path)
        end
      end
      m << "<li class='divider'>"
    end.join("\n").html_safe
  end

end
