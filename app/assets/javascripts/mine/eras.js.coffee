# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $('.datepicker').datepicker
    dateFormat: "dd/mm/yy"
  $('.datetimepicker').datetimepicker
    dateFormat: "dd/mm/yy"
    stepMinute: 5
