module ElementsHelper
  COLUMN_TITLES = {
    direct_groups:   "Direct groups",
    indirect_groups: "Indirect groups"
  }

  def column_title(key)
    COLUMN_TITLES[key] || key.to_s.capitalize
  end

  #
  #  Produces one line of output to suit a particular group.  Always
  #  4 columns with the first one empty.  The contents of the others
  #  varies according to type of group.
  #
  #  Different types of groups combine the columns in different ways.
  #
  #  When displaying a teaching group for a pupil, we show who the
  #  teacher is; when displaying the same group for a teacher we show
  #  how large it is.
  #
  def group_line(g, for_staff)
    case g.persona_type
    when "Teachinggrouppersona"
      "<tr><td></td><td>#{
        g.name
      }</td><td>#{
        if g.subject
          g.subject.name
        else
          ""
        end
      }</td><td#{ for_staff ? " align=\"right\"" : ""}>#{
        if for_staff
          g.members.count
        else
          if g.staffs.size > 0
            g.staffs.collect {|s| s.initials}.join("<br/>")
          else
            ""
          end
        end
      }</td></tr>"
    else
      "<tr><td></td><td colspan=\"3\">#{
        g.name
      }</td></tr>"
    end
  end

  def render_group_set(gs)
    result = []
    result << "<tr><th>&bull;&nbsp;</th><th colspan=\"3\" align=\"left\">#{gs.type}</th></tr>"
    gs.each do |g|
      result << group_line(g, false)
    end
    result.join("\n")
  end

  def render_grouped_groups(gg)
    result = []
    result << "<table class=\"gg_table\">"
    if gg.empty?
      result << "<tr><td>&bull;&nbsp;</td><td>None</td></tr>"
    else
      gg.each do |gs|
        result << render_group_set(gs)
      end
    end
    result << "</table>"
    result.join("\n")
  end

  #
  #  These have less ancillary structure.  Just an array of groups.
  #
  def render_group_array(ga)
    result = []
    result << "<table class=\"gg_table\">"
    if ga.empty?
      result << "<tr><td>&bull;&nbsp;</td><td>None</td></tr>"
    else
      ga.each do |g|
        result << group_line(g, true)
      end
    end
    result << "</table>"
    result.join("\n")
  end

  def render_column_contents(key)
    result = []
    unless key == :dummy
      result << "<div class=\"panel\">"
      result << "<h3>#{column_title(key)}</h3>"
      case key
      when :able
        result << "Able"
      when :direct_groups
        result << render_grouped_groups(@grouped_direct_groups)
      when :indirect_groups
        result << render_grouped_groups(@grouped_indirect_groups)
      when :taught_groups
        result << render_group_array(@groupstaught)
      else
        result << "&bull; Don't know how to handle #{key}."
      end
      result << "</div>"
    end
    result.join("\n").html_safe
  end
end
