class String
  def &(other)
    difference = other.to_str.each_char.with_index.find { |ch, idx|
      self[idx].nil? or ch != self[idx].chr
    }
    difference ? self[0, difference.last] : self
  end

  def wrap(width = 78)
    self.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
  end

  def indent(spaces = 2)
    padding = " " * spaces
    padding + self.gsub("\n", "\n#{padding}").rstrip
  end
end
