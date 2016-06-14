class Datasource < ActiveRecord::Base
   validates :name, presence: true
   validates :name, uniqueness: true

   has_many :staffs, dependent: :nullify
   has_many :pupils, dependent: :nullify

   def <=>(other)
     self.name <=> other.name
   end

   def can_destroy?
     self.staffs.count == 0 && self.pupils.count == 0
   end

   #
   #  A maintenance method to take ownership of existing resources.
   #
   def self.land_grab
     ds = Datasource.find_by(name: "SchoolBase")
     if ds
       staff_count = 0
       pupil_count = 0
       Staff.all.each do |s|
         s.datasource = ds
         s.save!
         staff_count += 1
       end
       Pupil.all.each do |p|
         p.datasource = ds
         p.save!
         pupil_count += 1
       end
       puts "Grabbed #{staff_count} staff and #{pupil_count} pupils."
       nil
     else
       puts "Can't find SchoolBase datasource."
     end
   end
end
