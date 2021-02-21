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
          extra_text =
            extra.to_a.collect {|arr| "#{arr[0]}='#{arr[1]}'"}.join(" ")
        end
        result << "<div class='#{tcc(key)}' #{extra_text}>#{data[:body]}</div>"
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
    mins_field = false
    case model
    when AdHocDomainSubject
      Rails.logger.debug("Doing AdHocDomainSubject")
      parent = model.ad_hoc_domain_cycle
      prefix = "subject"
      helper = autocomplete_subject_element_name_elements_path
      if peer_model
        error_field_id = "ahd-subject-errors-t#{peer_model.id}"
        id_suffix = "t#{peer_model.id}"
      else
        error_field_id = "ahd-subject-errors"
        id_suffix = "c#{parent.id}"
      end
      form_model = [parent, model]
    when AdHocDomainStaff
      Rails.logger.debug("Doing AdHocDomainStaff")
      parent = model.ad_hoc_domain_cycle
      Rails.logger.debug(parent.inspect)
      prefix = "staff"
      helper = autocomplete_staff_element_name_elements_path
      if peer_model
        error_field_id = "ahd-staff-errors-u#{peer_model.id}"
        id_suffix = "u#{peer_model.id}"
      else
        error_field_id = "ahd-staff-errors"
        id_suffix = "c#{parent.id}"
      end
      form_model = [parent, model]
    when AdHocDomainPupilCourse
      Rails.logger.debug("Doing AdHocDomainPupilCourse")
      parent = model.ad_hoc_domain_staff
      prefix = "pupil"
      helper = autocomplete_pupil_element_name_elements_path
      id_suffix = "u#{model.ad_hoc_domain_subject_id}t#{model.ad_hoc_domain_staff_id}"
      error_field_id = "ahd-pupil-errors-#{id_suffix}"

      mins_field = true
      step = model.
             ad_hoc_domain_staff.
             ad_hoc_domain_cycle.
             ad_hoc_domain.
             mins_step
      form_model = [model.ad_hoc_domain_subject, model.ad_hoc_domain_staff, model]
    else
      Rails.logger.debug("Dunno")
    end

    form_with(model: form_model, local: false) do |form|
      result = []
      result << "<div class='errors' id='#{error_field_id}'></div>"
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
      if peer_model
        result << form.hidden_field(:peer_id)
      end
      result.join("\n").html_safe
    end
  end

  def ahd_deletion_prompt(model)
    case model
    when AdHocDomainSubject
      "Deleting this link to the subject \"#{model.subject_name}\" will remove all the corresponding entries for students and teachers of the subject.  Continue?"
    when AdHocDomainStaff
      "Deleting this link to the staff member \"#{model.staff_name}\" will remove all the corresponding entries for his or her students of the subject.  Continue?"
    when AdHocDomainPupilCourse
      "Deleting this link to the pupil \"#{model.pupil_name}\" will not delete the pupil, but will stop any further lessons being scheduled."
    else
      "Are you sure?"
    end
  end

  def ahd_deletion_link(model)
    link_to("&#215;".html_safe,
            model,
            method: :delete,
            data: {
              confirm: ahd_deletion_prompt(model)
            },
            remote: true)
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

  private

  def be_hyphen(key)
    key.to_s.gsub("_", "-")
  end

end
