
class PendingSet

  def initialize(element)
    @element = element
    @pending = element.commitments.tentative.future.not_rejected.
               preload([:element, :event]).to_a
    @rejected = element.commitments.tentative.future.rejected.
                preload([:element, :event]).to_a
  end

  def empty?
    @pending.size == 0 && @rejected.size == 0
  end

  def report
    puts "Requests for #{@element.name}"
    @pending.each do |p|
      puts "  #{p.event.owners_initials} proposes \"#{p.event.body}\" on #{p.event.starts_at_text}."
    end
    @rejected.each do |p|
      puts "  #{p.event.owners_initials} wanted \"#{p.event.body}\" on #{p.event.starts_at_text}."
      puts "    Rejected by #{p.by_whom ? p.by_whom.name : "unknown"} - #{p.reason}."
    end
  end
end
