class Itemreport < ActiveRecord::Base
  belongs_to :concern

  #
  #  Build a URL to generate this report.
  #
  def url
    base = "/item/#{self.concern.element_id}/days"
    extras = Array.new
    extras << "compact" if self.compact
    extras << "duration" if self.duration
    extras << "mark_end" if self.mark_end
    extras << "locations" if self.locations
    extras << "staff" if self.staff
    extras << "pupils" if self.pupils
    extras << "periods" if self.periods
    extras << "breaks" if self.breaks
    extras << "suppress_empties" if self.suppress_empties
    if extras.size == 0
      base
    else
      base + "?" + extras.join("&")
    end
  end

end
