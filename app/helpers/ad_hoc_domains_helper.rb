module AdHocDomainsHelper
  #
  #  A complete re-work, the idea being for the code to provide
  #  merely the textual contents.  All the formatting and positioning
  #  decisions should be handled in the stylesheets.
  #
  #  We expect keys like:
  #
  #    subject_head
  #    subject_delete
  #    subject
  #    subject_form
  #    staff_head
  #    staff_delete
  #    staff
  #    num_staff
  #    num_pupils
  #    ...
  #    pupil_...
  #    flipper
  #
  def ahd_row(row_id: nil, row_classes: [], contents: {})
    result = []
    result << "<div class='#{
        (["arow"] + row_classes).join(" ")
      }'#{
        row_id ? " id='#{row_id}'" : ""
      }>"
    contents.each do |key, data|
      #
      #  The caller may have supplied a hash in order to
      #  do clever things.
      #
      if data.is_a? Hash
        #
        #  It must have a :body.  Anything else goes in the
        #  heading.
        #
        extra = data.except(:body)
        if extra.empty?
          extra_text = ""
        else
          #
          #  May also have more classes specified.
          #
          classes = extra[:class]
          if classes
            more_classes = " #{classes}"
            extra = extra.except(:class)
          else
            more_classes = ""
          end
          extra_text =
            extra.to_a.collect {|arr| "#{arr[0]}='#{arr[1]}'"}.join(" ")
        end
        result << "<div class='#{tcc(key)}#{more_classes}' #{extra_text}>#{data[:body]}</div>"
      else
        #
        #  Otherwise just shove it in the contents.
        #
        result << "<div class='#{tcc(key)}'>#{data}</div>"
      end
    end
    result << "</div>"
    result.join("\n").html_safe
  end

  def ahd_form(model, peer_model = nil)
#    Rails.logger.debug("Entering ahd_form")
#    Rails.logger.debug("model: #{model.inspect}")
#    Rails.logger.debug("peer_model: #{peer_model.inspect}")
    mins_field = false
    case model
    when AdHocDomainSubject
      parent = peer_model ? peer_model : model.ad_hoc_domain_cycle
      prefix = "subject"
      helper = autocomplete_subject_element_name_elements_path
      id_suffix = parent.id_suffix
    when AdHocDomainStaff
      parent = peer_model ? peer_model : model.ad_hoc_domain_cycle
      prefix = "staff"
      helper = autocomplete_staff_element_name_elements_path
      id_suffix = parent.id_suffix
    when AdHocDomainPupilCourse
      parent = model.ad_hoc_domain_subject_staff
      prefix = "pupil"
      helper = autocomplete_pupil_element_name_elements_path
      #
      #  The suffix here gets quite interesting.  It must be unique
      #  across the whole page.  Each member of staff may have several;
      #  each subject may have several, and indeed each pairing (staff
      #  and subject) will have two.
      #
      #  We take the peer as coming last, so if our peer is a subject
      #  we end up with: tNNuNN, whilst if our peer is a member of
      #  staff we get instead uNNtNN.
      #
      subject = parent.ad_hoc_domain_subject
      staff = parent.ad_hoc_domain_staff
      if peer_model.is_a? AdHocDomainSubject
        id_suffix = "#{staff.id_suffix}#{subject.id_suffix}"
      else
        id_suffix = "#{subject.id_suffix}#{staff.id_suffix}"
      end

      mins_field = true
      step = parent.
             ad_hoc_domain_subject.
             ad_hoc_domain_cycle.
             ad_hoc_domain.
             mins_step
    else
      Rails.logger.debug("Dunno")
    end

    form_with(model: [parent, model], local: false) do |form|
      result = []
      result << "<div class='errors' id='ahd-#{prefix}-errors-#{id_suffix}'></div>"
      if mins_field
        result << "<div class='sub-grid'>"
      end
      result << form.autocomplete_field(
        "#{prefix}_element_name",
        helper,
        'data-auto-focus' => true,
        id: "#{prefix}-element-name-#{id_suffix}",
        id_element: "##{prefix}-element-id-#{id_suffix}",
        placeholder: "Add #{prefix}",
        class: 'pupil-name')
      result << form.hidden_field(
        "#{prefix}_element_id",
        id: "#{prefix}-element-id-#{id_suffix}")
      if mins_field
        result << form.number_field(:minutes, step: step, class: 'pupil-mins')
        result << form.submit("Add", class: 'pupil-add zfbutton tiny teensy')
        result << "</div>"
      end
      result.join("\n").html_safe
    end
  end

  def ahd_new_staff_form(ad_hoc_domain_cycle, peer_model = nil)
    ahd_form(
      AdHocDomainStaff.new({ ad_hoc_domain_cycle: ad_hoc_domain_cycle }),
      peer_model
    )
  end

  def ahd_new_subject_form(ad_hoc_domain_cycle, peer_model = nil)
    ahd_form(
      AdHocDomainSubject.new({ ad_hoc_domain_cycle: ad_hoc_domain_cycle }),
      peer_model
    )
  end

  def ahd_new_pupil_form(ad_hoc_domain_subject_staff, peer)
    ahd_form(
      AdHocDomainPupilCourse.new({
        ad_hoc_domain_subject_staff: ad_hoc_domain_subject_staff
      }),
      peer)
  end

  def ahd_deletion_prompt(model)
    case model
    when AdHocDomainSubject
      "Deleting this link to the subject \"#{model.subject_name}\" will remove all the corresponding entries for students and teachers of the subject.  Continue?"
    when AdHocDomainStaff
      "Deleting this link to the staff member \"#{model.staff_name}\" will remove all the corresponding entries for his or her students of the subject.  Continue?"
    when AdHocDomainSubjectStaff
      "This will remove the connection between staff member \"#{model.ad_hoc_domain_staff.staff_name}\" and the subject \"#{model.ad_hoc_domain_subject.subject_name}\"."
    when AdHocDomainPupilCourse
      "Deleting this link to the pupil \"#{model.pupil_name}\" will not delete the pupil, but will stop any further lessons being scheduled."
    else
      "Are you sure?"
    end
  end

  def ahd_deletion_link(model, peer = nil)
    if peer
      #
      #  We want to delete the connection between two - must be a subject
      #  and a staff, but might be specified either way around.
      #
      if model.is_a?(AdHocDomainStaff) && peer.is_a?(AdHocDomainSubject)
        staff = model
        subject = peer
      elsif model.is_a?(AdHocDomainSubject) && peer.is_a?(AdHocDomainStaff)
        staff = peer
        subject = mdel
      else
        #
        #  Erroneous call.
        #
        staff = nil
      end
      if staff
        linker = AdHocDomainSubjectStaff.find_by(
          ad_hoc_domain_subject_id: subject.id,
          ad_hoc_domain_staff_id: staff.id)
        if linker
          link_to("&#215;".html_safe,
                  linker,
                  method: :delete,
                  data: {
                    confirm: ahd_deletion_prompt(model)
                  },
                  remote: true)
        else
          "YY"
        end
      else
        "XX"
      end
    else
      link_to("&#215;".html_safe,
              model,
              method: :delete,
              data: {
                confirm: ahd_deletion_prompt(model)
              },
              remote: true)
    end
  end

  def ahd_availability_link(ahd_staff)
    link_to("Availability",
            edit_availability_ad_hoc_domain_staff_path(ahd_staff))
  end

  def ahd_error_texts(model)
    result = []
    result << "<ul>"
    model.errors.messages.values.each do |message_set|
      message_set.each do |message|
        result << "<li>#{message}</li>"
      end
    end
    result << "</ul>"
    result.join("\n").html_safe
  end

  def ahd_toggle(text)
    link_to(text, '#', class: "toggle")
  end

  def ahd_tab_header(key, text, active)
    "<li class='tab-title#{ active ? " active" : ""}'><a href='##{be_hyphen(key)}'>#{text}</a></li>".html_safe
  end

  def ahd_tab(key, active)
    "class='content#{ active ? " active" : ""}' id='#{be_hyphen(key)}'".html_safe
  end

  #
  #  Turn a set of several lines into a chunk, wrapped up with
  #  { and }.  This is a separate step because here we don't want commas.
  #
  def bechunk(contents)
    result = []
    result << "{"
    result << contents
    result << "}"
    result.join("\n")
  end

  #
  #  Generates a JavaScript snippet to send back to the front end.
  #
  def ahd_update_subject_inner(subject)
    result = []
    result << "action: 'update_subject_staff'"
    result << "subject_id: #{subject.id}"
    result << "staff_listing: '#{ j(
                 render(
                   partial: 'ad_hoc_domain_subjects/subject_inner',
                   object: subject)) }'"
    bechunk(result.join(",\n")).html_safe
  end

  def ahd_update_staff_inner(staff)
    result = []
    result << "action: 'update_staff_subjects'"
    result << "staff_id: #{staff.id}"
    result << "subject_listing: '#{ j(
                 render(
                   partial: 'ad_hoc_domain_staffs/staff_inner',
                   object: staff)) }'"
    bechunk(result.join(",\n")).html_safe
  end

  def ahd_staff_totals(staff)
    result = []
    result << "action: 'update_staff_totals'"
    result << "staff_id: #{staff.id}"
    result << "num_subjects: '#{staff.num_subjects_text}'"
    result << "num_pupils: '#{staff.num_pupils_text}'"
    result << "num_mins: '#{mins_to_str(staff.total_mins)}'"
    bechunk(result.join(",\n")).html_safe
  end

  def ahd_subject_totals(subject)
    result = []
    result << "action: 'update_subject_totals'"
    result << "subject_id: #{subject.id}"
    result << "num_staff: '#{subject.num_staff_text}'"
    result << "num_pupils: '#{subject.num_pupils_text}'"
    result << "num_mins: '#{mins_to_str(subject.total_mins)}'"
    bechunk(result.join(",\n")).html_safe
  end

  def ahd_update_totals(*things)
    result = []
    things.each do |thing|
      case thing
      when AdHocDomainSubject
        result << ahd_subject_totals(thing)
      when AdHocDomainStaff
        result << ahd_staff_totals(thing)
      end
    end
    result.join(",\n").html_safe
  end

  #
  #  Update all the indicated things (subjects or staff) on screen, doing
  #  both their header totals and their body text.
  #
  def ahd_update(*things)
    result = []
    things.each do |thing|
      case thing
      when AdHocDomainSubject
        result << ahd_update_subject_inner(thing)
        result << ahd_subject_totals(thing)
      when AdHocDomainStaff
        result << ahd_update_staff_inner(thing)
        result << ahd_staff_totals(thing)
      end
    end
    result.join(",\n").html_safe
  end

  private

  def be_hyphen(key)
    key.to_s.gsub("_", "-")
  end

end
