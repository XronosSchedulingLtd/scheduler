module AdHocDomainsHelper
  def ahd_row(
    id: nil,
    row_classes: [],
    prefix1: " ",
    prefix2: " ",
    prefix3: " ",
    text1: "",
    text2: "",
    text3: "",
    text4: "",
    classes1: [],
    classes2: [],
    classes3: [])

    #
    #  What we are aiming to produce here is fundamentally:
    #
    #  <div class='row'>
    #    <div class='leaf'>Subject text</div>
    #    <div class='leaf'>Staff text</div>
    #    <div class='leaf'>Pupil text</div>
    #  </div>
    #
    #
    result = []
    result << "<div class='#{(["row"] + row_classes).join(" ")}'#{ id ? " id='#{id}'" : ""}>"
    result << "  <div>#{prefix1}</div>"
    result << "  <div class='#{(["leaf"] + classes1).join(" ")}'>#{text1}</div>"
    result << "  <div>#{prefix2}</div>"
    result << "  <div class='#{(["leaf"] + classes2).join(" ")}'>#{text2}</div>"
    result << "  <div>#{prefix3}</div>"
    result << "  <div class='#{(["leaf"] + classes3).join(" ")}'>#{text3}</div>"
    result << "  <div>#{text4}</div>"
    result << "</div>"
    result.join("\n").html_safe
  end

  def ahd_form(model)
    case model
    when AdHocDomainSubject
      parent = model.ad_hoc_domain
      prefix = "subject"
      helper = autocomplete_subject_element_name_elements_path
      error_field_id = "ahd-subject-errors"
    when AdHocDomainStaff
      parent = model.ad_hoc_domain_subject
      prefix = "staff"
      helper = autocomplete_staff_element_name_elements_path
      error_field_id = "ahd-staff-errors-#{model.ad_hoc_domain_subject_id}"
    when AdHocDomainPupilCourse
      parent = model.ad_hoc_domain_staff
      prefix = "pupil"
      helper = autocomplete_pupil_element_name_elements_path
      error_field_id = "ahd-pupil-errors-#{model.ad_hoc_domain_staff_id}"
    end
    form_with(model: [parent, model], local: false) do |form|
      "<div class='errors' id='#{error_field_id}'></div>".html_safe +
      form.autocomplete_field(
        "#{prefix}_element_name",
        helper,
        'data-auto-focus' => true,
        id: "#{prefix}-element-name-#{parent.id}",
        id_element: "##{prefix}-element-id-#{parent.id}",
        placeholder: "Add #{prefix}") +
      form.hidden_field(
        "#{prefix}_element_id",
        id: "#{prefix}-element-id-#{parent.id}"
      )
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

end
