module Enumerable
  #
  #  Won't be needed once we move to Ruby 2.7
  #
  unless self.method_defined?(:tally)
    def tally
      self.inject(Hash.new(0)) { |result, value|
        result[value] += 1
        result
      }
    end
  end
end
