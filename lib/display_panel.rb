class DisplayPanel

  class DisplayColumn
    attr_reader :type, :contents

    def initialize(type, contents)
      @type     = type
      @contents = contents
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
end


