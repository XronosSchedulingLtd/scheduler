$(document).ready ->
  $('#group_name_field').focus()
  $('#group_name_field').select()
  $(".groupfind").submit( ->
    if ($("#element_id").val().length > 0)
      type = $('#which_finder').val()
      if (type == 'resource')
        extra = '&resource=true'
      else
        extra = ''
      document.location.href = '/groups?element_id=' + $("#element_id").val() + extra
    return false
  )
