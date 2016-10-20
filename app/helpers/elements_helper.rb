module ElementsHelper
  COLUMN_TITLES = {
    direct_groups:   "Direct groups",
    indirect_groups: "Indirect groups",
    taught_groups: "Groups taught",
    subject_teachers: "Teachers",
    subject_groups: "Teaching groups"
  }

  def column_title(key)
    COLUMN_TITLES[key] || key.to_s.capitalize
  end

  #
  #  Called every time we want to display something, perhaps with a
  #  link.  Some users get links, others don't.  This handles that
  #  decision and returns appropriate text.
  #
  def be_linken(name, element)
    if can_roam?
      link_to(name, element_path(element))
    else
      name
    end
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
        be_linken(g.name, g.element)
      }</td><td>#{
        if g.subject
          be_linken(g.subject.name, g.subject.element)
        else
          ""
        end
      }</td><td#{ for_staff ? " align=\"right\"" : ""}>#{
        if for_staff
          g.members.count
        else
          if g.staffs.size > 0
            g.staffs.collect {|s| be_linken(s.initials, s.element)}.join("<br/>")
          else
            ""
          end
        end
      }</td></tr>"
    else
      "<tr><td></td><td colspan=\"3\">#{
        be_linken(g.name, g.element)
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
  def render_group_array(ga, empty_text = "None")
    result = []
    result << "<table class=\"gg_table\">"
    if ga.empty?
      result << "<tr><td>&bull;&nbsp;</td><td>#{empty_text}</td></tr>"
    else
      ga.each do |g|
        result << group_line(g, true)
      end
    end
    result << "</table>"
    result.join("\n")
  end

  def member_line(m)
    if m.instance_of?(Pupil)
      "<tr><td></td><td>#{
        be_linken(m.name, m.element)
      }</td><td>#{
        if m.tutorgroup
          be_linken(m.tutorgroup_name, m.tutorgroup.element)
        else
          m.tutorgroup_name
        end
      }</td></tr>"
    elsif m.instance_of?(Staff)
      "<tr><td></td><td>#{
        be_linken(m.name, m.element)
      }</td><td>#{
        be_linken(m.initials, m.element)
      }</td></tr>"
    else
      "<tr><td></td><td colspan=\"2\">#{ be_linken(m.name, m.element) }</td></tr>"
    end
  end

  def render_member_set(ms)
    result = []
    result << "<tr><th>&bull;&nbsp;</th><th colspan=\"2\" align=\"left\">#{ms.type}</th></tr>"
    ms.each do |m|
      result << member_line(m)
    end
    result.join("\n")
  end

  #
  #  What we should be passed here is a MemberSetHolder, which is
  #  a kind of array, with added information.
  #
  def render_membership(msh)
    result = []
    result << "<table class=\"gg_table\">"
    if msh.empty?
      result << "<tr><td>&bull;&nbsp;</td><td>None</td></tr>"
    else
      msh.each do |ms|
        result << render_member_set(ms)
      end
    end
    result << "</table>"
    result.join("\n")
  end

  #
  #  Or if we have simply an array of some kind(s) of members.
  #
  def render_member_list(list)
    result = []
    result << "<table class=\"gg_table\">"
    if list.empty?
      result << "<tr><td>&bull;&nbsp;</td><td>None</td></tr>"
    else
      list.each do |member|
        result << member_line(member)
      end
    end
    result << "</table>"
    result.join("\n")
  end

  def render_column_contents(column)
    result = []
    unless column.type == :dummy
      result << "<div class=\"panel\">"
      result << "<h3>#{column_title(column.type)}</h3>"
      case column.type
      when :direct_groups
        result << render_grouped_groups(column.contents)
      when :indirect_groups
        result << render_grouped_groups(column.contents)
      when :taught_groups
        result << render_group_array(column.contents, "Not recorded")
      when :subject_teachers
        result << render_member_list(column.contents)
      when :subject_groups
        result << render_group_array(column.contents)
      when :members
        result << render_membership(column.contents)
      else
        result << "&bull; Don't know how to handle #{column.type}."
      end
      result << "</div>"
    end
    result.join("\n").html_safe
  end
end
