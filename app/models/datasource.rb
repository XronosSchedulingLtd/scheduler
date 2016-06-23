class Datasource < ActiveRecord::Base
   validates :name, presence: true
   validates :name, uniqueness: true

   has_many :staffs, dependent: :nullify
   has_many :pupils, dependent: :nullify
   has_many :locationaliases, dependent: :nullify
   has_many :groups, dependent: :nullify

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
       la_count = 0
       group_count = 0
       Staff.all.each do |s|
         unless s.datasource
           s.datasource = ds
           s.save!
           staff_count += 1
         end
       end
       Pupil.all.each do |p|
         unless p.datasource
           p.datasource = ds
           p.save!
           pupil_count += 1
         end
       end
       Locationalias.all.each do |la|
         unless la.datasource
           if la.source_id != 0
             la.datasource = ds
             la.save!
             la_count += 1
           end
         end
       end
       Group.all.each do |g|
         if g.persona_type == "Teachinggrouppersona" ||
            g.persona_type == "Taggrouppersona"
           if g.persona.source_id && g.persona.source_id != 0
             unless g.datasource
               g.source_id = g.persona.source_id
               g.datasource = ds
               g.save!
               group_count += 1
             end
           end
         end
       end
       puts "Grabbed #{staff_count} staff, #{pupil_count} pupils, #{la_count} location aliases and #{group_count} groups."
       nil
     else
       puts "Can't find SchoolBase datasource."
     end
   end
end
