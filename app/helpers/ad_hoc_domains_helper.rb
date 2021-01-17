module AdHocDomainsHelper
  def ahd_row(
    row_classes: [],
    prefix1: " ",
    prefix2: " ",
    prefix3: " ",
    text1: "",
    text2: "",
    text3: "",
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
    result << "<div class='#{(["row"] + row_classes).join(" ")}'>"
    result << "  <div>#{prefix1}</div>"
    result << "  <div class='#{(["leaf"] + classes1).join(" ")}'>#{text1}</div>"
    result << "  <div>#{prefix2}</div>"
    result << "  <div class='#{(["leaf"] + classes2).join(" ")}'>#{text2}</div>"
    result << "  <div>#{prefix3}</div>"
    result << "  <div class='#{(["leaf"] + classes3).join(" ")}'>#{text3}</div>"
    result << "</div>"
    result.join("\n").html_safe
  end

  def ahd_form(model)
    case model
    when AdHocDomainSubject
      parent = model.ad_hoc_domain
      prefix = "subject"
      helper = autocomplete_subject_element_name_elements_path
    when AdHocDomainStaff
      parent = model.ad_hoc_domain_subject
      prefix = "staff"
      helper = autocomplete_staff_element_name_elements_path
    when AdHocDomainPupilCourse
      parent = model.ad_hoc_domain_staff
      prefix = "pupil"
      helper = autocomplete_pupil_element_name_elements_path
    end
    form_with(model: [parent, model], local: false) do |form|
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

  def ahd_deletion_link(model, prompt)
    link_to("&#215;".html_safe,
            model,
            method: :delete,
            data: {
              confirm: prompt
            },
            remote: true)
  end

end
