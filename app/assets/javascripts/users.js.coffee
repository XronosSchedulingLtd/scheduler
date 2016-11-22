$(document).ready ->
  $(".userfind").submit( ->
    if ($("#user_id").val().length > 0)
      document.location.href = '/users/' + $("#user_id").val()
    return false
  )
