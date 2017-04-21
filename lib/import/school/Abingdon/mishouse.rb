#
#  We have to modify ISAMS_BoardingHouse and ISAMS_Academic house
#  separately because although we are included *after* the original
#  definition, if we merely modify MIS_House then the inclusion of
#  Creator in the sub-classes over-rides our definition.
#
#  Arguably, for Abingdon we don't need to do ISAMS_BoardingHouse
#  because it doesn't have any.
#

class ISAMS_AcademicHouse

  def wanted
    !(/^APS / =~ self.name)
  end

end

class ISAMS_BoardingHouse

  def wanted
    !(/^APS / =~ self.name)
  end

end
