class StaffMailer < ActionMailer::Base
  default from: "from@example.com"

  def upcoming_invigilation_email(staff, slots, extra_text)
    @slots = slots
    @extra_text = extra_text
    mail(to: staff.email,
         from: Setting.from_email_address,
         subject: "Invigilation")
  end
end
