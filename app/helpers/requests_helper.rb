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

  def resource_requests_for(event, editing, user, amended_request_id = 0)
    requests = event.requests
    result = ["<ul class=\"no-bullet\">"]
    requests.each do |request|
      body =
        "#{truncate(request.element.name, length: 19)} (#{request.quantity})"
      if request.id == amended_request_id
        body =
          "<span class='flashme'>#{body}</span>"
      end
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

  def confirmation_button_or_message(request)
    if request.reconfirmable?
      if request.reconfirmed?
        "Confirmed"
      else
        link_to("Do confirm",
                reconfirm_request_path(request),
                method: :put,
                class: 'zfbutton teensy tiny button-link')
      end
    else
      ""
    end
  end

  def request_cancel_button(request)
    link_to("Cancel",
            request,
            method: :delete,
            data: { confirm: "Are you sure you want to cancel this request completely?" },
            class: 'zfbutton teensy tiny button-link')

  end

end
