class UserMailer < ActionMailer::Base
  default from: "abingdon@scheduler.org.uk"

  def cover_clash_email(clashes)
    #
    #  Each user who arranges cover gets a copy of the e-mail.
    #
    @clashes = clashes.sort
    @current_date = Time.zone.parse("2010-01-01")
    User.arranges_cover.each do |user|
      mail(to: user.email,
           subject: "Possible cover clashes")
    end
  end

end
