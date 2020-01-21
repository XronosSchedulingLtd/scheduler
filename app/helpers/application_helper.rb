#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2020 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

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

  def tscb_group(f,
                 parent,
                 field,
                 small_cols,
                 med_cols,
                 label,
                 keys,
                 defaults = nil,
                 extra_text = nil)
    result = Array.new
    result << "<div class='small-#{small_cols} medium-#{med_cols} columns tscb-zone'>"
    result << "  <label>#{label}</label>"
    keys.each_with_index do |key, i|
      result << single_tscb(f, parent, field, key, defaults)
      if (i + 1) % 3 == 0
        result << '<br/>'
      end
    end
    if extra_text
      unless result.last == '<br/>'
        result << '<br/>'
      end
      result << extra_text
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

  class MenuMaker < Array

    include ActionView::Helpers::UrlHelper

    def dropdown(title_text, link = '#')
      self << "<li class='has-dropdown'>"
      self << link_to(title_text, link)
      self << "<ul class='dropdown'>"
      if block_given?
        yield
      end
      self << "</ul>"
      self << "</li>"
    end

    def item(title, link, method = :get)
      self << "<li>#{link_to(title, link, method: method)}</li>"
    end

    def result
      self.join("\n").html_safe
    end

  end

  #
  #  Build the appropriate HTML for the menu for this user.
  #
  def menu_for(user)
    m = MenuMaker.new
    m.dropdown(header_menu_text(user)) do
      if user.known?
        if user.admin?
          m.dropdown('Admin') do
            m.item('E-mails', emails_path)
            m.dropdown('Models') do
              m.item('Data sources', datasources_path)
              m.item('Eras', eras_path)
              m.dropdown('Events', events_path) do
                m.item('Repeating', event_collections_path)
                m.dropdown('Categories', eventcategories_path) do
                  m.item('Current', eventcategories_path(current: true))
                  m.item('Deprecated', eventcategories_path(deprecated: true))
                end
                m.item('Sources', eventsources_path)
              end
              m.dropdown('Locations', locations_path) do
                m.item('Tree view', tree_locations_path)
                m.item('Aliases', locationaliases_path)
                m.item('Owned', locations_path(owned: true))
              end
              m.item('Properties', properties_path)
              m.item('Pupils', pupils_path)
              m.item('Services', services_path)
              m.dropdown('Staff', staffs_path) do
                m.item('Active', staffs_path(active: true))
                m.item('Inactive', staffs_path(inactive: true))
              end
              m.item('Subjects', subjects_path)
              m.dropdown('Users', users_path) do
                m.item('Profiles', user_profiles_path)
              end
            end
            m.dropdown('Settings', settings_path) do
              m.item('Pre-requisites', pre_requisites_path)
            end
            m.item('Imports', imports_index_path)
            m.item('Day shape',
                    rota_template_type_rota_templates_path(
                      DayShapeManager.template_type))
          end
          m.dropdown('Groups', groups_path) do
            m.dropdown('All', groups_path) do
              m.item('Deleted', groups_path(deleted: true))
            end
            m.item('Mine', groups_path(mine: true))
            m.item('Resource', groups_path(resource: true))
            m.item('Tutor', tutorgroups_path)
          end
        elsif user.can_has_groups?
          m.item('Groups', groups_path)
        end
        if user.resource_owner?
          m.dropdown('Allocate') do
            user.owned_resources.each do |owned|
              m.item(owned.name, schedule_group_path(owned.entity))
            end
          end
        end
        if user.create_events?
          m.dropdown(events_menu_text(user), user_events_path(user)) do
            m.dropdown(my_events_menu_text(user),
                       user_events_path(user, pending: true)) do
              m.item('All', user_events_path(user))
            end
            if user.admin?
              m.item('All', events_path)
            end
            user.owned_elements.each do |ce|
              m.dropdown(controlled_element_menu_text(ce),
                         owned_element_listing_path(ce, true)) do
                m.item('All', owned_element_listing_path(ce))
              end
            end
          end
        end
        if user.can_find_free?
          m.item('Find free', new_freefinder_path)
        end
        if user.can_has_forms?
          m.item('Forms', user_forms_path)
        end
        if user.can_has_files?
          m.item('Files', user_user_files_path(user))
        end
        if user.can_view_journal_for?(:events)
          m.dropdown('Journals', journals_path) do
            m.item('Current', journals_path(current: true))
            m.item('Deleted events', journals_path(deleted: true))
          end
        end
        if user.exams?
          m.dropdown('Invigilation') do
            m.item('Templates',
                      rota_template_type_rota_templates_path(
                        InvigilationManager.template_type))
            m.item('Cycles', exam_cycles_path)
            m.item('E-mails', new_notifier_path)
            m.item('Clashes', notifiers_path)
          end
        end
      end
      if user_can_revert?
        m.item('Revert su', '/sessions/revert', :put)
      end
    end
    m.result
  end

end
