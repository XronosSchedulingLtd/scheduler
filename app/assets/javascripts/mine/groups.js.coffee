$(document).ready ->
  $('#group_name_field').focus()
  $('#group_name_field').select()
  $(".groupfind").submit( ->
    group_id = $('#group_id').val()
    if (group_id.length > 0)
      type = $('#which_finder').val()
      if (type == 'resource')
        extra = '&resource=true'
      else if (type == 'owned')
        extra = '&owned=true'
      else if (type == 'old_owned')
        extra = '&owned=true&historical=true'
      else if (type == 'deleted')
        extra = '&deleted=true'
      else
        extra = ''
      document.location.href = '/groups?group_id=' + group_id + extra
    return false
  )
