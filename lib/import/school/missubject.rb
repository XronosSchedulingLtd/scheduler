class MIS_Subject
  def wanted
    /\(S\)/ =~ self.isams_name
  end

  def name
    @isams_name.gsub(" (S)", "")
  end

end
