# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2019 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.

module EmailsHelper


  class EmailDeconstructor

    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper

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
        #
        #  The association is polymorphic, and it's just possible
        #  we might end up with something else.
        #
        if user.instance_of?(User)
          result = "<a href='#{user_emails_path(user)}' title='#{user.name}'>#{name}</a>".html_safe
        else
          result = "<span title='#{user.name}'>#{name}</span>".html_safe
        end
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

    #
    #  The Mail library provides a different interface depending on
    #  whether or not the original email is multi-part.  We hide
    #  that a bit and make our interface the same.  A non-multi-part
    #  message is portrayed as having just one part.
    #
    #  Logical, no?
    #
    def num_parts
      if @deconstructed.multipart?
        @deconstructed.parts.count
      else
        1
      end
    end

    def parts_columns
      result = []
      if @deconstructed.multipart?
        @deconstructed.parts.each_with_index do |part, i|
          result << "<td>#{ parts_link(part, i) }</td>"
        end
      else
        #
        #  It has only a single part, but we fib a bit.
        #
        result << "<td>#{ parts_link(@deconstructed, 0) }</td>"
        result << "<td></td>"
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

    def parts_link(part, i)
      link_to(content_type_description(part.content_type),
              email_path(@message, part_no: i),
              'data-reveal-id' => 'eventModal',
              'data-reveal-ajax' => true )
    end

  end

  def get_deconstructor(message)
    EmailDeconstructor.new(message)
  end

end
