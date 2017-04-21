class MIS_Staff
  def active
    !!(@email =~ /\@deanclose\.org\.uk$/)
  end

end

