
class MIS_House

  def wanted
    !(/^APS / =~ self.name)
  end
end
