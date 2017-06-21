class StaffMailer < ActionMailer::Base
  default from: "from@example.com"

  def upcoming_invigilation_email(
    staff,
    slots,
    extra_text,
    reply_handlers = nil)

    parameters = Hash.new
    @slots = slots
    @extra_text = extra_text

    parameters[:to]      = staff.email
    parameters[:from]    = Setting.from_email_address
    parameters[:subject] = "Invigilation"
    if reply_handlers
      if reply_handlers.respond_to?(:each)
        reply_to = reply_handlers.collect {|rh| rh.email}.join(",")
      else
        reply_to = reply_handlers.email
      end
      parameters[:reply_to] = reply_to
    end
    mail(parameters)
  end
end
