require 'erb'
include ERB::Util

class DisplayPanel

  class DisplayColumn
    attr_reader :type, :contents

    def initialize(type, contents)
      @type     = type
      @contents = contents
    end
  end

  #
  #  Normally, each cell of the table which we create contains
  #  one item, but it is just possible for there to be more
  #  than one.  In that case it is up to the display code how they are
  #  displayed, but typically they will all go in the same table
  #  cell with <br/> separating them.
  #
  class GDCItem
    attr_reader :body, :element, :hover_text

    def initialize(body, element = nil, hover_text = nil)
      @body = body
      @element = element
      @hover_text = hover_text
    end
  end

  #
  #  A cell is an array of items, possibly empty.
  #
  class GDCCell < Array

    attr_reader :width, :alignment

    def initialize(width, alignment = nil)
      super()
      @width = width
      @alignment = alignment
    end

  end

  #
  #  One row in a GDC Entry
  #
  class GDCRow
    #
    #  Should be called with one or more numbers, which add up to 3.
    #
    #    GDCRow.new(3)
    #    GDCRow.new(1,2)
    #    GDCRow.new(1,1,1)
    #
    #  These give the number of columns for each <td> to span.
    #
    def initialize(*params)
      unless params.inject(0, :+) == 3
        raise "Total columns in GDCRow must be 3."
      end
      @num_columns = params.count
      @cells = Array.new(@num_columns, nil)
      @widths = params.collect {|p| p}
      @blank_cell = GDCCell.new(1)
    end

    #
    #  Columns are indexed from 0.
    #  Note that only the first invocation for a cell will affect
    #  the cell's alignment.
    #
    def set_contents(
      column,
      text,
      element = nil,
      hover_text = nil,
      alignment = nil)

      if column < 0 || column >= @num_columns
        raise "Out of range column index #{column}"
      end
      unless @cells[column]
        @cells[column] = GDCCell.new(@widths[column], alignment)
      end
      @cells[column] << GDCItem.new(text, element, hover_text)
    end

    def each_cell
      @cells.each do |cell|
        if cell
          yield cell
        else
          #
          #  Nothing has been set, so supply enough to display a blank.
          #
          yield @blank_cell
        end
      end
    end

    #
    #  Several bits of code want to create GDCRows of the same
    #  general format, so move the code here.
    #
    def self.for_member(m)
      if m.instance_of?(Pupil)
        gdcr = self.new(2, 1)
        gdcr.set_contents(0, m.name, m.element)
        if m.tutorgroup
          gdcr.set_contents(1, m.tutorgroup_name, m.tutorgroup.element)
        else
          gdcr.set_contents(1, m.tutorgroup_name)
        end
      elsif m.instance_of?(Staff)
        gdcr = self.new(2, 1)
        gdcr.set_contents(0, m.name, m.element)
        gdcr.set_contents(1, m.initials, m.element)
      else
        gdcr = self.new(3)
        gdcr.set_contents(0, m.name, m.element)
      end
      gdcr
    end

  end

  #
  #  One entry (with sub-title) in a general display column.
  #
  class GDCEntry

    attr_reader :rows, :subtitle

    def initialize(subtitle)
      @subtitle = subtitle
      @rows = []
    end

    def <<(row)
      @rows << row
    end

  end

  class GeneralDisplayColumn < DisplayColumn

    attr_accessor :preamble, :postamble
    attr_reader :title, :entries

    #
    #  This one has more generic display code.  The work is done
    #  earlier.
    #
    def initialize(title)
      super(:general, nil)
      @title = title
      @preamble = nil
      @postamble = nil
      @entries = []
    end

    def <<(entry)
      @entries << entry
    end

    def empty?
      @entries.size == 0
    end

  end

  attr_reader :heading, :columns

  def initialize(index, heading, active)
    @heading = heading
    @active  = active
    @index   = index
    @columns = Array.new
  end

  def panel_name
    "panel#{@index}"
  end
  
  def active?
    @active
  end

  def add_column(type, contents)
    @columns << DisplayColumn.new(type, contents)
  end

  def add_general_column(column)
    @columns << column
  end
end


