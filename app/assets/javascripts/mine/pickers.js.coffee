#
#  Code to initialize datepickers and datetimepickers throughout the
#  application.
#
$(document).ready ->
  $('.datepicker').datepicker
    dateFormat: "dd/mm/yy"
  $('.datetimepicker').datetimepicker
    dateFormat: "dd/mm/yy"
    stepMinute: 5
