class UserMailer < ActionMailer::Base
  default from: "abingdon@scheduler.org.uk"

  def cover_clash_email(user, clashes, oddities)
    @clashes = clashes.sort
    @oddities = oddities.sort
    @current_clash_date_html  = Time.zone.parse("2010-01-01")
    @current_clash_date_txt   = Time.zone.parse("2010-01-01")
    @current_oddity_date_html = Time.zone.parse("2010-01-01")
    @current_oddity_date_txt  = Time.zone.parse("2010-01-01")
    mail(to: user.email,
         subject: "Possible cover issues")
  end

end
