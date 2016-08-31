#
#  Class for ISAMS Cover Manager Cover records.
#
#  Copyright (C) 2016 John Winters
#

class ISAMS_Cover

  #
  #  Until we see some real data from iSAMS I'm not sure exactly what
  #  significance to attach to these flags.  Adjust this function to
  #  suit your exact requirements.
  #
  #  If this function returns true then the cover commitment will appear
  #  in Scheduler.  If it doesn't then it won't.
  #
  def active
#    @visible && @enabled && @published
    @visible && @enabled
  end

end
