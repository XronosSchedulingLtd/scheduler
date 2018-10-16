module RequestsHelper
  def increment_link(request)
    link_to("+", increment_request_path(request), method: :put, remote: true)
  end

  def decrement_link(request)
    link_to("-", decrement_request_path(request), method: :put, remote: true)
  end

  def delete_link(request)
    link_to("&#215;".html_safe, request, method: :delete, remote: true)
  end

  def resource_requests_for(event, editing, user)
    requests = event.requests
    result = ["<ul class=\"no-bullet\">"]
    requests.each do |request|
      Rails.logger.debug("Request is an instance of #{request.class}")
      body =
        "#{truncate(request.element.name, length: 19)} (#{request.quantity})"
      if user
        #
        #  And any buttons?
        #
        if editing && user.can_delete?(request)
          body = "#{body} #{increment_link(request)} #{decrement_link(request)} #{delete_link(request)}"
        end
      end
      result << "<li>#{body}</li>"
    end
    result << "</ul>"
    result.join("\n").html_safe
  end
end
