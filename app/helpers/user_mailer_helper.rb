module UserMailerHelper

  #
  #  These next two provide things in the form expected by Rails's link_to
  #  method.
  #
  def schedulers_protocol
    "#{Setting.protocol_prefix}://"
  end

  def schedulers_host
    "#{Setting.dns_domain_name}#{Setting.port_no}"
  end

  #
  #  And this is for my own fixed link.
  #
  def schedulers_url
    "#{Setting.protocol_prefix}://#{Setting.dns_domain_name}#{Setting.port_no}/"
  end

  #
  #  And do some of the more complicated link construction.
  #
  def mailer_scheduler_link(event, text = "See event in Scheduler")
    link_to(
      text,
      schedule_show_url(
        date: event.jump_date_text,
        my_events: true,
        protocol: schedulers_protocol,
        host: schedulers_host
      ),
      class: "zfbutton tiny radius button-link"
    )
  end

  def mailer_user_events_link(user, text = "View my pending events")
    link_to(text,
            user_events_url(user,
                            pending: true,
                            protocol: schedulers_protocol,
                            host: schedulers_host),
           class: "zfbutton tiny radius button-link")
  end

  def mailer_pending_requests_link(user, text = "View pending requests")
    link_to(text,
            user_requests_url(user,
                              pending: true,
                              protocol: schedulers_protocol,
                              host: schedulers_host),
           class: "zfbutton tiny radius button-link")
  end

  def mailer_mail_to_link(email, name, subject = nil)
    options = {
      class: "zfbutton tiny radius button-link"
    }
    if subject
      options[:subject] = subject
    end
    mail_to(email, "Email #{name}", options)
  end

  def mailer_resource_link(text, element)
    link_to(
      text,
      element_commitments_url(
        element,
        pending: true,
        protocol: schedulers_protocol,
        host: schedulers_host
      ),
      class: "zfbutton tiny radius button-link"
    )
  end

  #
  #  Construct a suitable subject line.
  #
  def mailer_subject(event)
    "Re: \"#{event.body}\" on #{event.start_date_text}"
  end
end
