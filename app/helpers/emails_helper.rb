# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module EmailsHelper


  class EmailDeconstructor

    include Rails.application.routes.url_helpers

    MAXIMUM_FIELD_LENGTH = 25

    def initialize(message)
      @message = message
      @deconstructed = Mail.new(message.content)
    end

    def user_column
      result = ""
      user = @message.user
      if user && user.respond_to?(:name)
        name = h user.name
        if name.length > MAXIMUM_FIELD_LENGTH
          name = name[0, MAXIMUM_FIELD_LENGTH - 3] + "..."
        end
        result = "<a href='#{user_emails_path(user)}' title='#{user.name}'>#{name}</a>".html_safe
      end
      result
    end

    def to_column
      #
      #  Try to trim off our own e-mail domain
      #
      to_text = @message.to
      from_email_domain = Setting.from_email_domain
      unless from_email_domain.blank?
        to_text = to_text.sub(/@#{from_email_domain}\Z/, "@...")
      end
      #
      #  Still want to put a limit on the length.
      #
      if to_text.length > MAXIMUM_FIELD_LENGTH
        #
        #  Get rid of existing ellipsis if any.
        #
        to_text = to_text.chomp('...')[0, MAXIMUM_FIELD_LENGTH - 3] + "..."
      end
      "<span title='#{h @message.to}'>#{h to_text}</span>".html_safe
    end

    def subject_column
      subject_text = @message.subject
      if subject_text.length > MAXIMUM_FIELD_LENGTH
        subject_text = subject_text[0, MAXIMUM_FIELD_LENGTH - 3] + "..."
      end
      "<span title='#{h @message.subject}'>#{h subject_text}</span>".html_safe
    end

    def num_parts
      @deconstructed.parts.count
    end

    def parts_columns
      result = []
      @deconstructed.parts.each do |part|
        result << "<td>#{ content_type_description(part.content_type) }</td>"
      end
      result.join("\n").html_safe
    end

    private

    def content_type_description(content_type)
      case content_type
      when /\Atext\/plain/
        "Text"
      when /\Atext\/html/
        "HTML"
      else
        content_type
      end
    end

  end

  def get_deconstructor(message)
    emails_path
    EmailDeconstructor.new(message)
  end

end
