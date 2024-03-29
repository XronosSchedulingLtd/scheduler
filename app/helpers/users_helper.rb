module UsersHelper

  def flag_setter(f, field, annotation, prompt = nil)
    result = Array.new
    result << "<div class='row collapse'>"
    result << "  <div class='small-3 columns'>"
    result << "    #{f.label(prompt ? prompt : field,
                             'class' => 'right inline')}"
    result << "  </div>"
    result << "  <div class='small-1 columns'>"
    result << "    #{f.check_box(field)}"
    result << "  </div>"
    result << "  <div class='small-8 columns annotation'>"
    result << annotation
    result << "  </div>"
    result << "</div>"
    result.join.html_safe
  end

end
