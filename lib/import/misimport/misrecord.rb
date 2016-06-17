#
#  The basic class from which all the data import classes derive.
#  Anything common to all types of record goes here.
#
class MIS_Record

  #
  #  Note that this code gets run just once as the class is being
  #  defined.  It defines class variables for use later.
  #
  #  We specifically want class variables, so they will be available
  #  to sub-classes.
  #
  current_mis = Setting.current_mis
  if current_mis && !current_mis.empty?
    primary_datasource = Datasource.find_by(name: current_mis)
    if primary_datasource
      @@primary_datasource_id = primary_datasource.id
    else
      raise "Current mis - #{current_mis} - is not defined as a data source."
    end
  else
    raise "Current MIS is not configured - aborting."
  end
  #
  #  We don't have to have a previous MIS.
  #
  previous_mis = Setting.previous_mis
  if previous_mis && !previous_mis.empty?
    secondary_datasource = Datasource.find_by(name: previous_mis)
    if secondary_datasource
      @@secondary_datasource_id = secondary_datasource.id
    else
      raise "Previous mis - #{previous_mis} - is not defined as a data source."
    end
  end

  #
  #  If you define initialize again in a sub-class, don't forget to call
  #  super
  #
  def initialize(*params)
    @dbrecord = nil
    @belongs_to_era = nil
    @checked_dbrecord = false
    @element_id = nil
  end

  #
  #  Compares selected fields in a database record and a memory record,
  #  and updates any which differ.  If anything is changed, then saves
  #  the record back to the database.  Gives the calling code a chance
  #  to add changes too.
  #
  def check_and_update(extras = nil)
    #
    #  For this first reference, we call the dbrecord method, rather than
    #  accessing the instance variable directly.  This is in order to cause
    #  it to be initialised if it isn't already.
    #
    return false unless dbrecord
    changed = false
    self.class.const_get(:FIELDS_TO_UPDATE).each do |field_name|
      if @dbrecord.send(field_name) != self.instance_variable_get("@#{field_name}")
        puts "Field #{field_name} differs for #{self.name}"
        puts "d/b: \"#{@dbrecord.send(field_name)}\" IS: \"#{self.instance_variable_get("@#{field_name}")}\""
#        @dbrecord[field_name] = self.instance_variable_get("@#{field_name}")
#                entry.send("#{attr_name}=", row[column_hash[attr_name]])
         @dbrecord.send("#{field_name}=",
                        self.instance_variable_get("@#{field_name}"))
        changed = true
      end
    end
    if extras
      #
      #  extras should be a hash of additional things to change.
      #
      extras.each do |key, value|
        dbvalue = @dbrecord.send("#{key}")
        if dbvalue != value
          puts "Field #{key} differs for #{self.name}"
          puts "d/b: \"#{dbvalue}\"  IS: \"#{value}\""
          @dbrecord.send("#{key}=", value)
          changed = true
        end
      end
    end
    if changed
      if @dbrecord.save
        true
      else
        puts "Failed to save #{self.class} record #{self.name}"
        false
      end
    else
      false
    end
  end

  def save_to_db(extras = nil)
    if dbrecord
      puts "Attempt to re-create d/b record of type #{self.class.const_get(:DB_CLASS)} for #{self.source_id}"
      false
    else
      newrecord = self.class.const_get(:DB_CLASS).new
      key_field = self.class.const_get(:DB_KEY_FIELD)
      if key_field.instance_of?(Array)
        key_field.each do |kf|
          newrecord.send("#{kf}=",
                         self.send("#{kf}"))
        end
      else
        newrecord.send("#{key_field}=",
                       self.send("#{key_field}"))
      end
      self.class.const_get(:FIELDS_TO_CREATE).each do |field_name|
         newrecord.send("#{field_name}=",
                        self.instance_variable_get("@#{field_name}"))
      end
      if extras
        extras.each do |key, value|
          newrecord.send("#{key}=", value)
        end
      end
      if newrecord.save
        newrecord.reload
        @dbrecord = newrecord
        @belongs_to_era = newrecord.respond_to?(:era)
        @checked_dbrecord = true
        true
      else
        puts "Failed to create d/b record of type #{self.class.const_get(:DB_CLASS)} for #{self.source_id}"
        false
      end
    end
  end

  def dbrecord
    #
    #  Don't keep checking the database if it isn't there.
    #
    unless @checked_dbrecord
      @checked_dbrecord = true
      db_class = self.class.const_get(:DB_CLASS)
      #
      #  Does this particular database record hang off an era?
      #
      @belongs_to_era = db_class.new.respond_to?(:era)
      key_field = self.class.const_get(:DB_KEY_FIELD)
      find_hash = Hash.new
      if key_field.instance_of?(Array)
        key_field.each do |kf|
          find_hash[kf] = self.send("#{kf}")
        end
      else
        if key_field == :source_id
          find_hash[:datasource_id] = @@primary_datasource_id
        end
        find_hash[key_field] = self.send("#{key_field}")
      end
      if @belongs_to_era
        find_hash[:era_id] = self.instance_variable_get("@era_id")
      end
#      puts "Trying: #{find_hash.inspect}"
      @dbrecord =
        db_class.find_by(find_hash)
      unless @dbrecord
        #
        #  Didn't find it that way.  It may be possible to do
        #  it a slightly different way.
        #
        if key_field == :source_id
          find_hash = Hash.new
          find_hash[:datasource_id] = @@secondary_datasource_id
          find_hash[key_field] = self.send("#{key_field}", true)
          if @belongs_to_era
            find_hash[:era_id] = self.instance_variable_get("@era_id")
          end
#          puts "Trying: #{find_hash.inspect}"
          @dbrecord =
            db_class.find_by(find_hash)
          if @dbrecord
            #
            #  To make things as transparent as possible to the
            #  calling code, we're going to fix this now.
            #
            @dbrecord.source_id = self.send("#{key_field}")
            @dbrecord.datasource_id =
              self.class.instance_variable_get("@primary_datasource_id")
            @dbrecord.save!
            @dbrecord.reload
          end
        end
      end
    end
    @dbrecord
  end

  #
  #  A defensive (and cached) way to get this item's element id.
  #
  def element_id
    unless @element_id
      dbr = dbrecord
      if dbr
        #
        #  Special processing needed for locations.
        #
        if dbr.class == Locationalias
          if dbr.location
            if dbr.location.element
              @element_id = dbr.location.element.id
            end
          end
        else
          if dbr.element
            @element_id = dbr.element.id
          end
        end
      end
    end
    @element_id
  end

end