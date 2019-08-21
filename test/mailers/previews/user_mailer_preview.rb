# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  #
  #  This is all a bit messy because it runs in the development database
  #  rather than the test database.  We therefore don't want to go
  #  creating new records.
  #
  #  The purpose of this code is merely to test the appearance of the
  #  e-mails, so we simply try to find some existing records which will
  #  do.
  #
  #  Sometimes this may not work and you'll get an error.
  #
  class CoverClash
    attr_reader :cover_commitment, :clashing_commitment

    def initialize(c1, c2)
      @cover_commitment = c1
      @clashing_commitment = c2
    end

    def to_partial_path
      'user_mailer/clash'
    end

  end

  def cover_clash_email
    c1 = Staff.current.first.element.commitments.covering_commitment.last
    c2 = Staff.current.first.element.commitments.first
    cc = CoverClash.new(c1, c2)
    UserMailer.cover_clash_email(User.first, [cc], [])
  end

end
