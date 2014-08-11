module CommitmentsHelper
  def commitment_entries_for(event, target_class, editing)
    commitments =
      event.commitments.select {|c| c.element.entity_type == target_class.to_s}
    if editing
      commitments.collect {|c| h(c.element.name) + " " + link_to("&#215;".html_safe, c, method: :delete, remote: true) }.join("<br/>").html_safe
    else
      commitments.collect {|c| h(c.element.name) }.join("<br/>").html_safe
    end
  end
end

