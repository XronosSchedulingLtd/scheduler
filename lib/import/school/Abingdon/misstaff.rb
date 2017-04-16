class MIS_Staff
  def active
    !!(@email =~ /\@abingdon\.org\.uk$/)
  end

end

