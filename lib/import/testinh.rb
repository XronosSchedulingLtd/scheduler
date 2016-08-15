
class FirstClass
  DB_KEY_FIELD = [:source_id_str, :datasource_id]
  FIELDS_TO_CREATE = [:name, :era_id, :starts_on, :ends_on, :current]

  def report
    puts "Have #{self.class::FIELDS_TO_CREATE.size} fields to create."
    self.class::FIELDS_TO_CREATE.each do |field|
      puts field
    end
  end

  #
  #  You can call this only once in each sub-class for each identifier.
  #  It defines a new constant in the sub-class which will hide the
  #  one defined by the super-class, but contain all the values which
  #  it previously contained, plus a few more.
  #
  def self.more_fields(identifier, values)
    self.const_set(identifier,
                   self.superclass.const_get(identifier) + values)
  end

  def self.hello
    puts "Hello from FirstClass"
  end

end

class SecondClass < FirstClass
  DB_CLASS = :Taggroup
#  FIELDS_TO_CREATE =
#    self.superclass::FIELDS_TO_CREATE + [:owner_id, :make_public]
  more_fields(:FIELDS_TO_CREATE, [:owner_id, :make_public, :banana])

  def report2
    puts "Have #{FIELDS_TO_CREATE.size} fields to create."
    FIELDS_TO_CREATE.each do |field|
      puts field
    end
  end

end

class ThirdClass < SecondClass
  def woogle
    puts self.class.superclass::DB_KEY_FIELD.join(",")
  end

  def self.hello
    super
    puts "Hello from ThirdClass"
  end

end

FirstClass.new.report
SecondClass.new.report

SecondClass.new.report2

ThirdClass.new.woogle
ThirdClass.hello
