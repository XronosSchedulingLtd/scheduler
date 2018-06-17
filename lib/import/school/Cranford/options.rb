class Options
  alias_method :old_more_defaults, :more_defaults

  def more_defaults
    old_more_defaults
    #
    #  This saves having to add these on the command line.
    #
    @cover      = true
  end
end
