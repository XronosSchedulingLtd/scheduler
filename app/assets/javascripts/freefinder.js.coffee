$(document).ready ->
  $('#freedatepicker').datepicker
    showOtherMonths: true
    selectOtherMonths: true
    dateFormat: 'yy-mm-dd'
  $('.period-selector').click(window.handlePeriodClick)

window.handlePeriodClick = (item) ->
  #
  #  These should be coming from the database, but hardcoded for now.
  #
  day_names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  monFriTimes =
    "1":
      start_time: "09:00"
      end_time:   "09:50"
    "2":
      start_time: "09:55"
      end_time:   "10:45"
    "3":
      start_time: "11:10"
      end_time:   "12:05"
    "4":
      start_time: "12:10"
      end_time:   "13:05"
    "5":
      start_time: "13:10"
      end_time:   "13:55"
    "6":
      start_time: "14:00"
      end_time:   "14:55"
    "7":
      start_time: "15:00"
      end_time:   "15:55"
    "8":
      start_time: "16:00"
      end_time:   "17:00"
  tueThuTimes =
    "1":
      start_time: "09:00"
      end_time:   "09:50"
    "2":
      start_time: "09:55"
      end_time:   "10:45"
    "3":
      start_time: "11:10"
      end_time:   "12:05"
    "4":
      start_time: "12:10"
      end_time:   "13:05"
    "5":
      start_time: "13:10"
      end_time:   "13:40"
    "6":
      start_time: "13:45"
      end_time:   "14:40"
    "7":
      start_time: "14:45"
      end_time:   "15:40"
    "8":
      start_time: "15:45"
      end_time:   "17:00"
  wedTimes =
    "1":
      start_time: "09:00"
      end_time:   "09:50"
    "2":
      start_time: "09:55"
      end_time:   "10:45"
    "3":
      start_time: "11:10"
      end_time:   "12:05"
    "4":
      start_time: "12:10"
      end_time:   "13:05"
    "5":
      start_time: "13:05"
      end_time:   "14:00"
    "6":
      start_time: "14:05"
      end_time:   "14:35"
    "7":
      start_time: "14:40"
      end_time:   "15:55"
    "8":
      start_time: "16:00"
      end_time:   "17:00"
  period_times =
    "Mon": monFriTimes
    "Tue": tueThuTimes
    "Wed": wedTimes
    "Thu": tueThuTimes
    "Fri": monFriTimes

  #
  #  If at any point we fail to look something up, we just give up and
  #  do nothing.
  #
  dayname = day_names[(new Date($('#freedatepicker').val())).getDay()]
  day_slot = period_times[dayname]
  if day_slot
    period_data = day_slot[$(this).data("period-no")]
    if period_data
      $('#freefinder_start_time_text').val(period_data['start_time'])
      $('#freefinder_end_time_text').val(period_data['end_time'])
