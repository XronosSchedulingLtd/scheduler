#
# Xronos Scheduler - structured scheduling program.
# Copyright (C) 2009-2016 John Winters
# See COPYING and LICENCE in the root directory of the application
# for more information.
#

class Datasource < ApplicationRecord
   validates :name, presence: true
   validates :name, uniqueness: true

   has_many :staffs, dependent: :nullify
   has_many :pupils, dependent: :nullify
   has_many :ad_hoc_domains, dependent: :nullify
   has_many :subjects, dependent: :nullify
   has_many :locationaliases, dependent: :nullify
   has_many :groups, dependent: :nullify

   def <=>(other)
     self.name <=> other.name
   end

   def can_destroy?
     self.staffs.count == 0 &&
       self.pupils.count == 0 &&
       self.subjects.count == 0 &&
       self.ad_hoc_domains.count == 0
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
       tug_count = 0
       teg_count = 0
       ohg_count = 0
       tag_count = 0
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
         #
         #  Tutor group personae never had a source id, but they
         #  still came from SB.
         #
         #  We will assume that if the datasource has been set,
         #  then any necessary copying of the source_id has been
         #  done too.
         #
         if g.persona_type == "Teachinggrouppersona" ||
            g.persona_type == "Taggrouppersona" ||
            g.persona_type == "Otherhalfgrouppersona" ||
            g.persona_type == "Tutorgrouppersona"
           #
           #  One which might need work.  Check it has not already been
           #  done.
           #
           unless g.datasource
             #
             #  Not already done.
             #
             g.datasource = ds
             #
             #  Tutor groups had no source_id with SB.
             #
             unless g.persona_type == "Tutorgrouppersona"
               if g.persona.source_id && g.persona.source_id != 0
                 g.source_id = g.persona.source_id
               end
             end
             g.save!
             group_count += 1
             case g.persona_type
             when "Teachinggrouppersona"
               teg_count += 1
             when "Taggrouppersona"
               tag_count += 1
             when "Otherhalfgrouppersona"
               ohg_count += 1
             when "Tutorgrouppersona"
               tug_count += 1
             end
           end
         end
       end
       puts "Grabbed #{staff_count} staff, #{pupil_count} pupils, #{la_count} location aliases and #{group_count} groups."
       puts "#{tug_count} tutor, #{teg_count} teaching, #{ohg_count} other half and #{tag_count} tag groups."
       nil
     else
       puts "Can't find SchoolBase datasource."
     end
   end
end
