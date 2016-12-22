module ElementsHelper
  COLUMN_TITLES = {
    subject_teachers: "Teachers",
    subject_groups: "Teaching groups"
  }

  def column_title(column)
    if column.type == :general
      column.title
    else
      COLUMN_TITLES[column.type] || column.type.to_s.capitalize
    end
  end

  #
  #  Called every time we want to display something, perhaps with a
  #  link.  Some users get links, others don't.  This handles that
  #  decision and returns appropriate text.
  #
  def be_linken(name, element)
    #
    #  It's just possible that we will get passed null as the element
    #  because some things are linked in without being active.  E.g.
    #  OTL uses non-existent staff for some Private Study periods.
    #
    if can_roam? && element
      link_to(h(name), element_path(element))
    else
      h(name)
    end
  end

  def be_hover_linken(title, name, element)
    if title
      "<span title=\"#{title}\">#{be_linken(name, element)}</span>"
    else
      be_linken(name, element)
    end
  end

  #
  #  I'd really like to get the object itself to do this, but the
  #  way Rails structures dependencies it isn't really possible.
  #
  def render_general_column_entry(entry)
    result = []
    if entry.subtitle
      result <<
        "<tr><th>&bull;&nbsp;</th><th colspan=\"3\" align=\"left\">#{
          entry.subtitle
        }</th></tr>"
    end
    entry.rows.each do |row|
      #
      #  Each row is represented by something between, at its simplest:
      #
      #  <tr>
      #    <td></td>
      #    <td></td>
      #    <td></td>
      #    <td></td>
      #  </tr>
      #
      #  and
      #
      #  <tr>
      #    <td></td>
      #    <td colspan="3" alignment="right">
      #      <span title="hover_text>
      #        <a href="/elements/99">
      #          Able Baker
      #        </a>
      #      </span>
      #      <br/>
      #      <span title="more_hover_text>
      #        <a href="/elements/101">
      #          Charlie Farlie
      #        </a>
      #      </span>
      #    </td>
      #  </tr>
      #
      #  Note that there should be a total of 4 effective columns the
      #  first of which is reserved for the bullet in the heading row.
      #
      result << "<tr><td></td>"
        row.each_cell do |cell|
          result <<
            "<td#{
              cell.width == 1 ? "" : " colspan=\"#{cell.width}\""}#{
              cell.alignment ? " align=\"#{cell.alignment}\"" : ""}>#{
              cell.collect { |item|
                be_hover_linken(item.hover_text,
                                item.body,
                                item.element) }.join("<br/>")}</td>"
        end
      result << "</tr>"
    end
    result.join("\n")
  end

  def render_general_column(column)
    result = []
    if column.preamble
      result << column.preamble
    end
    result << "<table class=\"gg_table\">"
    if column.empty?
      result << "<tr><td>&bull;&nbsp;</td><td>None</td></tr>"
    else
      column.entries.each do |entry|
        result << render_general_column_entry(entry)
      end
    end
    result << "</table>"
    if column.postamble
      result << column.postamble
    end
    result.join("\n")
  end

  def render_column_contents(column)
    result = []
    unless column.type == :dummy
      result << "<div class=\"panel\">"
      result << "<h3>#{column_title(column)}</h3>"
      case column.type
      when :general
        result << render_general_column(column)
      else
        result << "&bull; Don't know how to handle #{column.type}."
      end
      result << "</div>"
    end
    result.join("\n").html_safe
  end
end
