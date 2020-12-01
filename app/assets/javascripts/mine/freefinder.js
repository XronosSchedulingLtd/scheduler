"use strict";

//
//  This code is for the "find free times" page.
//
if ($('#fft-results').length) {
  $(
    function() {

      var that = {};

      var mins_needed;

      function openEventModal(event) {
        event.preventDefault();
        var url = $(this).attr('href');
        var target = event.target;
        //
        //  Do we have an ff-slide-container as a peer to our target object?
        //
        var slide_container = $(target).siblings('.ff-slidecontainer');
        if (slide_container.length) {
          var slider = slide_container.find('.ff-slider');
          var value = slider.slider('option', 'value');
          var slots = $(slider).prop('ff-slots');
          var slot = slots[value];
          if (slot) {
            //
            //  It seems we have an explicitly chosen time.  We want to
            //  overwrite the starts_at and ends_at parameters in our
            //  URL string with freshly calculated values.
            //
            var encodedURL = new URL(url, window.location.href);
            var date = $(slider).data('date');
            var ends_at = slot.clone().add(mins_needed, 'minutes');
            encodedURL.searchParams.set(
              'starts_at',
              date + ' ' + slot.format('HH:mm'));
            encodedURL.searchParams.set(
              'ends_at',
              date + ' ' + ends_at.format('HH:mm'));
            url = encodedURL.toString();
          }
        }

        $('#eventModal').foundation('reveal',
                                    'open',
                                    url);
      }

      function makeLabel(start_time, mins_needed) {
        var slot_end = start_time.clone().add(mins_needed, 'minutes');

        return start_time.format('HH:mm') +
               '-' +
               slot_end.format('HH:mm');
      }

      function generateLabels(slots, mins_needed) {
        var result = [];
        slots.forEach(function(slot) {
          result.push(makeLabel(slot, mins_needed));
        });
        return result;
      }

      //
      //  Work out what all our slot start times will be for a given
      //  entry.
      // 
      function generateSlots(start_time, end_time, mins_needed, step) {
        //
        //  We will set up our array of times to be on multiples of the
        //  step, plus possibly an extra one at each end.  Thus if
        //  we have worked out a 15 minute step, and we want a 35 minute
        //  slot, and the available time is from 08:20 - 11:10 our
        //  offerings would be:
        //
        //  08:20 - 08:55   Unaligned
        //  08:30 - 09:05
        //  08:45 - 09:20
        //  09:00 - 09:35
        //  09:15 - 09:50
        //  09:30 - 10:05
        //  09:45 - 10:20
        //  10:00 - 10:35
        //  10:15 - 10:50
        //  10:30 - 11:05
        //  10:35 - 11:10   Unaligned
        //
        //  Note that this case gets an unaligned slot at each end.
        //  Others may have one or neither of these.
        //
        //  As an extreme case, you might have no aligned slots at all.
        //
        //  Want 60 mins.  63 mins available, from 10:01 - 11:04.  Step
        //  is 5 mins.
        //
        //  10:01 - 11:01
        //  10:04 - 11:04
        //
        //  This is very extreme - not sure it's even possible to create
        //  the circumstance - but the code should cope.
        //
        var result = [];
        //
        //  Of necessity, the first slot will always be the start time.
        //
        result.push(start_time.clone());
        //
        //  And the last one will always be step minutes before end_time.
        //  It's possible that the last one is also the first one, in
        //  which case we do no more.
        //
        var last_one = end_time.clone();
        last_one.subtract(mins_needed, 'minutes');
        if (last_one.isAfter(start_time)) {
          //
          //  Now find all the exact multiples of step minutes
          //  after midnight which lie between those two.
          //
          var midnight = start_time.clone().startOf('day');
          var minutes = start_time.diff(midnight, 'minutes');
          //
          //  Work out how many whole steps we are after midnight, then
          //  go one more.  If we were exactly on a step we will get the
          //  next one.
          //
          var base = Math.floor(minutes / step);
          var working = midnight.clone().add((base + 1) * step, 'minutes');
          while (working.isBefore(last_one)) {
            result.push(working.clone());
            working.add(step, 'minutes');
          }
          result.push(last_one);
        }
        return result
      }

      function setUpSlider(index, element) {
        //
        //  Need the start and end time for this entry, and thus
        //  the available duration.
        //
        //  I tried to use the value of the slider as the number
        //  of minutes of delay but realised that that doesn't work
        //  with the end adjusted slots which may not be aligned.
        //  Hence the slider goes from 0 to num_slots - 1
        //

        var selector = $(element);

        //
        //  These will create date/time objects with the
        //  date being today, but it doesn't hurt because
        //  all we are going to use is the time component.
        //
        var start_time = moment(selector.data('start-time'), 'hh:mm');
        var end_time = moment(selector.data('end-time'), 'hh:mm');
        var duration = moment.duration(end_time.diff(start_time)).asMinutes();

        var slack = duration - mins_needed;

        //
        //  Now how many steps we use (and the size of the steps)
        //  depends on how much slack there is.
        //
        //  We are aiming for about 10 steps (can be 11).
        //
        //  Less than one hour - 5 min steps
        //  Less than two hours - 10 min steps
        //  Less than three hours - 15 min steps
        //  Less than six hours - 30 min steps
        //  Less than twelve hours - 60 min steps
        //
        var step;
        if (slack < 60) {
          step = 5;
        } else if (slack < 120) {
          step = 10;
        } else if (slack < 180) {
          step = 15;
        } else if (slack < 360) {
          step = 30;
        } else if (slack < 720) {
          step = 60;
        } else {
          step = 120;
        }
        var slots = generateSlots(start_time, end_time, mins_needed, step);
        //
        //  Now construct suitable labels.
        //
        var labels = generateLabels(slots, mins_needed);
        //
        //  Save these for when we get clicked later.
        //
        selector.prop('ff-slots', slots);
        //
        //  And activate the slider
        //
        $(element).slider(
          {
            min: 0,
            max: slots.length - 1
          }
        ).slider(
          "pips",
          {
            first: 'pip',
            last: 'pip'
          }
        ).slider(
          "float",
          {
            labels: labels
          }
        );
      }

      that.init = function() {
        mins_needed = $('#fft-results').data('mins-needed');
        $('.ff-booking').click(openEventModal);
        //
        //  Do we have any results on display?  If so, set up the sliders.
        //
        $('.ff-slider').each(setUpSlider);
      }

      return that;
    }().init
  );
}

