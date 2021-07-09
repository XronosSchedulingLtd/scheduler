json.extract! @ad_hoc_domain_pupil_course, :id, :minutes
json.staff_id @ad_hoc_domain_staff.id
json.staff_total mins_to_str(@ad_hoc_domain_staff.total_mins)
json.subject_id @ad_hoc_domain_subject.id
json.subject_total mins_to_str(@ad_hoc_domain_subject.total_mins)
