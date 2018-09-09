class String
  def &(other)
    difference = other.to_str.each_char.with_index.find { |ch, idx|
      self[idx].nil? or ch != self[idx].chr
    }
    difference ? self[0, difference.last] : self
  end
end
