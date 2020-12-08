$(document).ready ->
  new Clipboard('.clip-button').on('success', (e) ->
    $(".copied-text:not(.invisible)").addClass("invisible")
    $(e.trigger).parents(".ical-row").find(".copied-text").removeClass("invisible")
  )
