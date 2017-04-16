class MIS_Subject
  def wanted
    #
    #  Sometimes the prep school use the agreed convention of putting
    #  (P) on the end of their subject names, and sometimes they put
    #  "APS " on the beginning.
    #
    #  I can't really complain - our guys aren't consistent either.
    #
    !((/\(P\)/ =~ self.isams_name) || (/^APS / =~ self.isams_name))
  end

  def name
    @isams_name.gsub(" (S)", "")
  end

end
