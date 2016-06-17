IsamsField = Struct.new(:selector, :attr_name, :target_type)

module Creator
  def self.included(parent)
    parent.extend ClassMethods
    parent::REQUIRED_FIELDS.each do |field|
      attr_accessor field[:attr_name]
    end
  end

  #
  #  Default to true.  May well be over-ridden in the class.
  #
  def wanted
    true
  end

  #
  #  Likewise, may well be over-ridden.
  #
  def adjust
  end

  #
  #  I could just call this function initialize, but give it a slightly
  #  different name so that the includer can add more processing before or
  #  after our work.
  #
  def do_initialize(entry)
    self.class::REQUIRED_FIELDS.each do |field|
      attr_name = field[:attr_name]
      if field[:selector] == "Id"
        #
        #  Special case.  This one comes through as an attribute and
        #  is always numeric.
        #
        self.send("#{attr_name}=", entry.attribute("Id").value.to_i)
      else
        contents = entry.at_css(field[:selector])
        if contents
          if field[:target_type] == :string
            self.send("#{attr_name}=", contents.text)
          else
            self.send("#{attr_name}=", contents.text.to_i)
          end
        else
          #
          #  For ease of processing, missing strings are taken as
          #  empty strings, but missing values are set as nil.
          #
          if field[:target_type] == :string
            self.send("#{attr_name}=", "")
          else
            self.send("#{attr_name}=", nil)
          end
        end
      end
    end
  end

  module ClassMethods
    def slurp(data)
      results = Array.new
      entries = data.css(self::SELECTOR)
      if entries && entries.size > 0
        entries.each do |entry|
          rec = self.new(entry)
          rec.adjust
          if rec.wanted
            results << rec
          end
        end
      else
        puts "Unable to find entries using selector \"#{self::SELECTOR}\"."
      end
      results
    end
  end
end
