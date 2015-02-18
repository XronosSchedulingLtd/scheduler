class UserMailer < ActionMailer::Base
  default from: "abingdon@scheduler.org.uk"

  def cover_clash_email(user, clashes, oddities)
    @clashes = clashes.sort
    @oddities = oddities.sort
    @current_date = Time.zone.parse("2010-01-01")
    mail(to: user.email,
         subject: "Possible cover issues")
  end

end
