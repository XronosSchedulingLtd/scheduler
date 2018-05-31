
class Options

  attr_reader :dump_covers

  def more_defaults
    @dump_covers = false
  end

  def more_options(opts)
    opts.on("-d", "--dump-covers",
            "Dump our idea of the covers and exit") do |d|
      @dump_covers = d
    end

  end
end
