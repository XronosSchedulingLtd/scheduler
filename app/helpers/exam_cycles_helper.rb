module ExamCyclesHelper
  #
  #  Generate HTML for a selector for selecting a rota template.
  #
  def template_selector_text
    rts = RotaTemplate.all.sort
    result = []
    result << "<select class='inputrtname'>"
    result << "<option value="">Please select</option>"
    rts.each do |rt|
      result << "<option value='#{ rt.id }'>#{ rt.name }</option>"
    end
    result << "</select>"
    result.join.html_safe
  end
end
