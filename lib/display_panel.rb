class DisplayPanel
  attr_reader :heading, :columns

  def initialize(index, heading, active, columns)
    @heading = heading
    @active  = active
    @columns = columns
    @index   = index
  end

  def panel_name
    "panel#{@index}"
  end
  
  def active?
    @active
  end
end


