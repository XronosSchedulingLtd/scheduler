class MIS_Staff
  def construct_email(forename, surname)
    "#{forename[0].downcase}#{surname.downcase}@cranfordhouse.net"
  end
end
