module CommitmentsHelper

  def element_name_with_cover(commitment)
    result = h(commitment.element.name)
    if commitment.covering
      result = result +
                "<br/>&nbsp;&nbsp;(Covering ".html_safe +
                h(commitment.covering.element.name) +
                ")"
    end
    if commitment.covered
      result = result +
                "<br/>&nbsp;&nbsp;(Covered by ".html_safe +
                h(commitment.covered.element.name) +
                ")"
    end
    if commitment.rejected
      result = "<span class=\"rejected-commitment\">#{result}</span>"
    elsif commitment.tentative
      result = "<span class=\"tentative-commitment\">#{result}</span> <span class=\"commitment-yes\">Yes</span>/<span class=\"commitment-no\">No</span>"
    elsif commitment.constraining
      result = "<span class=\"constraining-commitment\">#{result}</span>"
    end
#    puts "Returning \"#{result}\"."
    result
  end

  def commitment_entries_for(event, target_class, editing)
    commitments =
      event.commitments.select {|c| c.element.entity_type == target_class.to_s}
    if editing
      result = commitments.collect {|c| element_name_with_cover(c) + " " + link_to("&#215;".html_safe, c, method: :delete, remote: true) }.join("<br/>").html_safe
#      puts "Result class = #{result.class}."
#      puts "Result = \"#{result}\"."
      result
    else
      commitments.collect {|c| element_name_with_cover(c) }.join("<br/>").html_safe
    end
  end
end

