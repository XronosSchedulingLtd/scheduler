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
      @widths = params.collect {|p| p}
      @columns = Array.new(@num_columns, "")
      @elements = Array.new(@num_columns, nil)
      @hover_texts = Array.new(@num_columns, nil)
      @alignments = Array.new(@num_columns, nil)
    end

    #
    #  Columns are indexed from 0.
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
      @columns[column] = text
      @elements[column] = element
      @hover_texts[column] = hover_text
      @alignments[column] = alignment
    end

    def each_item
      @columns.each_with_index do |col, i|
        yield col, @widths[i], @elements[i], @hover_texts[i], @alignments[i]
      end
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


