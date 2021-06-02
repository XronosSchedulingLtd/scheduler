"use strict";

//
//  Do nothing at all unless we are on the right page.
//
if ($('#editing-allocation').length && $('#allocation-data').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
var editing_allocation = function() {

  //
  //================================================================
  //
  //  Datastore and subsidiary items.
  //
  //================================================================
  //
  //  The raw timetable is nearly good enough but we want to add
  //  some helper methods.
  //

  var makeTimetable = function(pupil_id, mine) {

    that = mine.timetables[pupil_id];
    //
    //  A raw timetable may belong to more than one PupilCourse
    //  but needs enhancing only once.
    //
    if (!that['entriesOn']) {
      that.entriesOn = function(date) {
        var week = mine.weeks[date.format('YYYY-MM-DD')];
        var wday = date.day();
        var week_entries = this[week];

        if (week_entries) {
          var entries = week_entries[wday];
          if (entries) {
            return entries;
          }
        }
        return [];
      };
    }

    return that;
  };

  var makePupilCourse = function(pc, mine) {
    var that = {};

    that.pcid      = pc.pcid;
    that.pupil_id  = pc.pupil_id;
    that.mins      = pc.mins;
    that.name      = pc.name;
    that.subject   = pc.subject;
    that.timetable = makeTimetable(that.pupil_id, mine);
    return that;
  };

  var makePupilCourses = function(spec, mine) {
    var current;
    var i;
    var that = {};

    //
    //  We're turning an array into a hash.
    //
    for (i = 0; i < spec.pcs.length; i++) {
      current = spec.pcs[i]
      that[current.pcid] = makePupilCourse(current, mine);
    }
    return that;
  };

  var makeAllocation = function(starts_at, ends_at, pcid, mine) {
    var that = {
      starts_at: starts_at,
      ends_at:   ends_at,
      pcid:      pcid 
    };

    that.adjustDuration = function(event) {
      this.ends_at = event.end;
    };

    that.adjustTiming = function(event) {
      //
      //  Note that it is possible to drag an event onto a completely
      //  different day, in which case the "allocations" object needs
      //  to update its structures.
      //
      var old_date = this.starts_at.format("YYYY-MM-DD");
      var new_date;

      this.starts_at = event.start;
      new_date = this.starts_at.format("YYYY-MM-DD");
      this.ends_at = event.end;
      //
      //  Only worried about a change in date.
      //
      if (old_date !== new_date) {
        mine.dateChanged(this, old_date, new_date);
      }
    };

    that.overlapsLesson = function(lesson) {
      //
      //  Does this allocation overlap time-wise with the given lesson.
      //  We have already established that they are on the same day.
      //  Our allocation has two moment objects giving its timing,
      //  but the timetable entry is purely textual.
      //
      var lesson_starts_at;
      var lesson_ends_at;
      var textual_date = this.starts_at.format("YYYY-MM-DD ");

      lesson_starts_at = moment(textual_date + lesson.b);
      lesson_ends_at   = moment(textual_date + lesson.e);
      //
      //  It's easiest to work out the right test if you think about
      //  the opposite.
      //
      if (this.ends_at <= lesson_starts_at ||
          this.starts_at >= lesson_ends_at) {
        return false;
      } else {
        return true;
      }
    };

    return that;
  };

  var makeAllocations = function(spec, mine) {
    //
    //  We're handling a list of existing allocations sent down from
    //  the host.
    //
    var allocated = spec.allocated;
    var i;
    var allocations = [];
    //
    //  Store allocations by week number.  An array of arrays.
    //
    var by_week = [];
    //
    //  And by date.  An object containing arrays, indexed by
    //  date in the form "YYYY-MM-DD".
    //
    var by_date = {};
    var that = {};

    //
    //  Need moment, moment, integer.
    //
    that.add = function(starts_at, ends_at, pcid) {
      var week_no = mine.weekOf(starts_at);
      var entry = makeAllocation(starts_at, ends_at, pcid, mine);

      allocations.push(entry);
      if (by_week[week_no]) {
        by_week[week_no].push(entry);
      } else {
        by_week[week_no] = [entry];
      }
      var key = starts_at.format("YYYY-MM-DD");
      if (by_date[key]) {
        by_date[key].push(entry);
      } else {
        by_date[key] = [entry];
      }
    };

    for (i = 0; i < allocated.length; i++) {
      that.add(
        moment(allocated[i].starts_at),
        moment(allocated[i].ends_at),
        allocated[i].pcid
      );
    }
   
    //
    //  We add a function to the "mine" object so that our
    //  allocations can call us back.
    //
    mine.dateChanged = function(allocation, old_date, new_date) {
      //
      //  A date can change within a week, but not currently to a
      //  new week.
      //
      var coming_from = by_date[old_date];
      var going_to = by_date[new_date];

      if (coming_from && Array.isArray(coming_from)) {
        var index = coming_from.indexOf(allocation);
        if (index > -1) {
          coming_from.splice(index, 1);
        }
        //
        //  This may be our first allocation on the new date.
        //
        if (going_to && Array.isArray(going_to)) {
          going_to.push(allocation);
        } else {
          by_date[new_date] = [allocation];
        }
      }
    };

    that.inWeek = function(week) {
      var result;

      result = by_week[week];
      if (result) {
        return result;
      } else {
        return [];
      }
    };

    that.byDate = function(date, pcid) {
      //
      //  Find an existing allocation on a given date and matching
      //  a pcid.
      //
      var result = null;

      var candidates = by_date[date.format("YYYY-MM-DD")];
      if (candidates) {
        result =
          candidates.find(function(entry) { return entry.pcid === pcid });
      }
      return result;
    };

    that.byWeek = function(date, pcid) {
      //
      //  Slightly fuzzier version of the previous.  Given a PCID
      //  and a date, look for an allocation in the same week.
      //
      var result = null;

      var candidates = by_week[mine.weekOf(date)];
      if (candidates) {
        result =
          candidates.find(function(entry) { return entry.pcid === pcid });
      }
      return result;
    };

    that.all = function() {
      //
      //  Return an array of all our allocations.
      //
      return allocations;
    };


    return that;
  };

  var makeWeekOf = function(spec) {
    //
    //  Return a function which can calculate a week number given
    //  a textual date or a moment object.
    //
    //  Note that we really need to know only the start date to do
    //  this.
    //
    var start_date = moment(spec.starts);
    var sunday = moment(start_date).subtract(start_date.day(), "days");

    var calculator = function(date) {
      var delta = moment(date).diff(sunday, 'days');
      return Math.floor(delta / 7);
    };
    return calculator;
  };

  //
  //  An object to hold the complete data set sent down for one
  //  teacher's allocation.
  //
  //  The idea is that we take the raw data sent by the host and
  //  store it in a form convenient for front-end manipulation.
  //
  //  We can also generate a data stream to send back to the host
  //  to update its variables.
  //

  var makeLoadings = function(pcs, mine) {
    //
    //  Within "mine" we expect to find the existing allocations and
    //  timetables.
    //
    //  Wherever we have a blank in our data structure, that means the
    //  loading is 0.
    //
    //  We do an initial calculation of all the loadings now, then we
    //  expect to be informed every time an allocation is changed.
    //
    //  Note that we want to do the calculation once for each pupil,
    //  which is not the same as once for each pupil course.  One pupil may
    //  have more than one course.
    //
    var that = {};

    var i, j;
    var allocation;
    var pc;
    var loadings_by_pid = {};
    var date;
    var lesson, lessons;
    var loadings;

    var allocations = mine.allocations.all();

    for (i = 0; i < allocations.length; i++) {
      allocation = allocations[i];
      pc = pcs[allocation.pcid];
      //
      //  Now need to find all timetable lessons which clash with this
      //  allocation.
      //
      lessons = pc.timetable.entriesOn(moment(allocation.starts_at));
      for (j = 0; j < lessons.length; j++) {
        lesson = lessons[j];
        if (allocation.overlapsLesson(lesson)) {
          //
          //  Find existing loadings for this pupil.  Create a new
          //  object if not there.
          //
          loadings = (loadings_by_pid[pc.pupil_id] ||= {});
          if (loadings[lesson.s] === undefined) {
            loadings[lesson.s] = 1;
          } else {
            loadings[lesson.s] = loadings[lesson.s] + 1;
          }
        }
      }
    }

    that.loadingOf = function(sid, pid) {
      //
      //  Given a subject id and a pupil id, give the pupil's current
      //  loading for that subject - i.e. the number of allocations which
      //  he has already which clash with a lesson in that subject.
      //
      var loadings = loadings_by_pid[pid];
      if (loadings) {
        var loading = loadings[sid];
        if (loading) {
          return loading;
        }
      }
      //return Math.floor(Math.random() * 7);
      return 0;
    }

    return that;
  }

  var makeDataset = function(spec) {
    //
    //  Stuff private to this object is saved in local variables.
    //  Stuff shared with our sub-components goes in "mine".
    //  Stuff we publicize goes in "that".
    //
    var that = {};
    var mine = {};

    //
    //  Things needed by our subsidiary objects.
    //
    mine.weekOf      = makeWeekOf(spec);
    mine.weeks       = spec.weeks;
    mine.timetables  = spec.timetables;
    mine.allocations = makeAllocations(spec, mine);
    //
    //  Private things which we want to keep.
    //
    var id         = spec.id;
    var staff_id   = spec.staff_id;
    var name       = spec.name;
    var start_date = moment(spec.starts);
    var end_date   = moment(spec.ends);  // Exclusive
    var view_date  = moment(spec.starts);
    //
    //  Things which are already provided in a convenient form we simply
    //  store.
    //
    var availables = spec.availables;
    //
    //  To start with, no PupilCourse is current.
    //
    var current = 0;
    //
    //  Who wants to know about interesting changes?
    //
    var listeners = [];

    var tellListeners = function(datechange = false) {
      var i;

      for (i = 0; i < listeners.length; i++) {
        var current = listeners[i];
        //
        //  If it's a datechange then only those who explicitly asked for
        //  the notification get it.
        //
        if (!datechange || current.dates) {
          if (current.context) {
            current.callback.apply(current.context, []);
          } else {
            current.callback();
          }
        }
      }
    };

    //
    //  Whilst other things are tweaked to make them easier to manipulate.
    //
    var pcs        = makePupilCourses(spec, mine);

    //
    //  And calculate the current loading for each of our pupils.
    //
    that.loadings = makeLoadings(pcs, mine);

    that.subjects = spec.subjects;

    //
    //  And now we add public methods.
    //
    //  When is this teacher available on the indicated date?
    //
    that.availablesOn = function(date) {
      var wday = date.day();
      return _.select(availables, function(entry) {
        return entry.wday === wday;
      });
    };

    //
    //  Find the pupil timetable for a given pcid.
    //
    that.timetableForPupil = function(pcid) {
      var pc = pcs[pcid];
      if (pc) {
        var timetable = pc.timetable;
        if (timetable) {
          return timetable;
        }
      }
      //
      //  Can't find.  Return a blank timetable.
      //
      return {A: [], B: []};
    };

    //
    //  What is the duration (in minutes) of the indicated
    //  Pupil Course.
    //
    that.durationOf = function(pcid) {
      var pc = pcs[pcid];
      if (pc) {
        return pc.mins;
      } else {
        return 0;
      }
    };

    that.pupilName = function(pcid) {
      var pc = pcs[pcid];

      if (pc) {
        return pc.name;
      }
      return "Unknown";

    };

    that.pupilId = function(pcid) {
      var pc = pcs[pcid];

      if (pc) {
        return pc.pupil_id;
      } else {
        return 0;
      }
    };

    that.addAllocation = function(starts_at, ends_at, pcid) {
      mine.allocations.add(starts_at, ends_at, pcid);
      tellListeners();
    };

    that.allocationByDate = function(date, pcid) {
      return mine.allocations.byDate(date, pcid);
    };

    that.allocationByWeek = function(date, pcid) {
      return mine.allocations.byWeek(date, pcid);
    };

    that.allocationsInWeek = function(date) {
      //
      //  Given a single date, find all allocations in that week.
      //
      var week = mine.weekOf(date);
      return mine.allocations.inWeek(week);
    };

    that.unallocatedInWeek = function(date) {
      //
      //  Given a single date, find all unallocated PupilCourses
      //  in that week.
      //
      var week = mine.weekOf(date);
      var allocations = mine.allocations.inWeek(week);
      var allocated_pcids = allocations.map(function(a) { return a.pcid });

      var result = [];
      for (var pcid in pcs) {
        if (pcs.hasOwnProperty(pcid)) {
          if (!allocated_pcids.includes(parseInt(pcid))) {
            result.push(pcs[pcid]);
          }
        }
      }
      return result;
    };

    that.unallocatedInCurrentWeek = function() {
      return that.unallocatedInWeek(view_date);
    };

    that.addListener = function(callback, context, dates = false) {
      listeners.push({callback: callback, context: context, dates: dates});
    };

    that.setCurrent = function(pcid) {
      var old_val = current;

      current = pcid;
      if (current !== old_val) {
        tellListeners();
      }
    };

    that.setViewDate = function(date) {
      view_date = moment(date);
      tellListeners(true);
    };

    that.getCurrent = function() {
      return current;
    };

    that.startsForFC = function() {
      return start_date.format("YYYY-MM-DD");
    };

    that.endsForFC = function() {
      return end_date.format("YYYY-MM-DD");
    };

    var saveDone = function() {
      console.log("Save succeeded.");
    };

    var saveFailed = function() {
      console.log("Save failed.");
    };

    that.doSave = function(event) {
      event.preventDefault();
      $.ajax({
        url: '/ad_hoc_domain_staffs/' + staff_id + '/ad_hoc_domain_allocations/' + id + '/save',
        type: 'PATCH',
        context: this,
        dataType: 'json',
        contentType: 'application/json',
        data: JSON.stringify({allocations: mine.allocations.all()})
      }).done(saveDone).
         fail(saveFailed);
    };

    return that;
  };

  //
  //================================================================
  //
  //  Global (within my module) variables.
  //
  //================================================================
  //

  var that = {};

  var calDiv = $('#editing-allocation');
  var myData = $('#allocation-data');
  var dataset;

  var fcParams = {
    schedulerLicenseKey: 'GPL-My-Project-Is-Open-Source',
    currentTimezone: 'Europe/London',
    timeFormat: 'H:mm',
    header: {
      left: 'prev,next',
      center: 'title',
      right: null
    },
    views: {
      week: {
        columnFormat: 'ddd D/M',
        titleFormat: 'Do MMM, YYYY'
      }
    },
    defaultView: "agendaWeek",
    eventOrder: "sort_by",
    snapDuration: "00:05",
    minTime: "07:00",
    maxTime: "18:30",
    scrollTime: "08:00",
    allDaySlot: false,
    selectable: true,
    selectHelper: true,
    eventRender: tweakWidth,
    //
    //  These two refer to dropping things from outside on my
    //  calendar.
    //
    droppable: true,
    drop: entryDropped,
    //
    //  And these two are for moving events around within the
    //  calendar.
    //
    eventDrop: eventDropped,
    eventResize: eventResized
  };

  //
  //================================================================
  //
  //  FullCalendar-related stuff.
  //
  //================================================================
  //

  function tweakWidth(event, element) {
    //
    //  This needs making more specific.  Want to tweak the student
    //  timetable events (which should be first in the sort order)
    //  only.
    //
    if (element.hasClass("fc-time-grid-event") && (event.timetable === 1)) {
      element.css("margin-right", "20px");
    }
  }

  function entryDropped(startsAt, jsEvent, ui) {
    //
    //  "this" is the object which was dropped.  A student allocation
    //  has been dropped onto our calendar.
    //
    //  If we simply add an item to the array and set it back,
    //  no change event is triggered because it's the same
    //  pointer as it was before.  Thus need to clone the
    //  array and set the new clone back.
    //
    var pcid = $(this).data('pcid');

    dataset.addAllocation(
      startsAt,
      moment(startsAt).add(dataset.durationOf(pcid), 'minutes'),
      pcid);
  }

  function eventDropped(event, delta, revertFunc) {
    //
    //  This is for when someone has moved an existing allocation
    //  in the calendar.
    //
    //  It's slightly more entertaining because they can be dragged
    //  from day to day within a week.
    //
    var allocation = dataset.allocationByWeek(event.start, event.pcid);
    if (allocation) {
      allocation.adjustTiming(event);
    } else {
      //
      //  Can't find it.  Revert.
      //
      revertFunc();
    }
  }

  function eventResized(event, delta, revertFunc) {
    //
    //  And this one is for when they have changed the duration of
    //  an existing event.
    //
    var allocation = dataset.allocationByDate(event.start, event.pcid);
    if (allocation) {
      allocation.adjustDuration(event);
    } else {
      //
      //  Can't find it.  Revert.
      //
      revertFunc();
    }
  }

  function serverResponded() {
  }

  function generateEvents(start, end, timezone, callback) {
    var i;
    var events = [];
    var entry;
    var loading;
    var colour;

    var colours = [   //   R    G    B
      '#329653',      //  50, 150,  83
      '#467D43',      //  70, 125,  67
      '#5A6433',      //  90, 100,  51
      '#6E4B23',      // 110,  75,  35
      '#823213',      // 130,  50,  19
      '#961903',      // 150,  25,   3
      '#ff0000'       // Very red
    ];

    for (var date = moment(start); date.isBefore(end); date.add(1, 'days')) {
      //
      //  Does our model know about any background events which we can
      //  shove in?
      //
      var availables = dataset.availablesOn(date);
      for (i = 0; i < availables.length; i++) {
        entry = availables[i];
        events.push({
          start: date.format('YYYY-MM-DD') + ' ' + entry.starts_at,
          end: date.format('YYYY-MM-DD') + ' ' + entry.ends_at,
          rendering: 'background'
        });
      }
    }
    var currentlyShowing = dataset.getCurrent();
    if (currentlyShowing !== 0) {
      //
      //  Try to show a student's calendar.
      //
      var timetable = dataset.timetableForPupil(currentlyShowing);
      if (timetable) {
        //
        //  We have a pointer to the student's timetable.  Now need
        //  to process each of the requested dates.
        //
        for (var date = moment(start);
             date.isBefore(end);
             date.add(1, 'days')) {
          var entries = timetable.entriesOn(date);
          if (entries) {
            //
            //  We finally have an array of entries.  Each of these
            //  should add one event to our display.
            //
            entries.forEach(function(entry) {
              loading =
                dataset.loadings.loadingOf(
                  entry.s,
                  dataset.pupilId(currentlyShowing));
              if (loading >= colours.length) {
                loading = colours.length - 1;
              }
              colour = colours[loading];
              events.push({
                title: dataset.subjects[entry.s],
                start: date.format('YYYY-MM-DD') + ' ' + entry.b,
                end: date.format('YYYY-MM-DD') + ' ' + entry.e,
                color: colour,
                timetable: 1,
                sort_by: "A"
              });
              // Amber '#d4a311'
              // Red   '#db4335'
            });
          }
        }
      }
    }
    var allocated = dataset.allocationsInWeek(start);
    if (allocated) {
      allocated.forEach(function(alloc) {
        var starts_at = alloc.starts_at;
        if ((starts_at >= start) && (starts_at < end)) {
          events.push({
            title: dataset.pupilName(alloc.pcid),
            start: starts_at.format('YYYY-MM-DD HH:mm'),
            end: alloc.ends_at.format('YYYY-MM-DD HH:mm'),
            timetable: 0,
            sort_by: "B",
            pcid: alloc.pcid,
            editable: true
          });
        }
      });
    }
    callback(events);
    dataset.setViewDate(start);
  }

  //
  //  Called when our allocation has noticed a change.  We are particularly
  //  interested in the current pupil.
  //
  function checkChange() {
    calDiv.fullCalendar('refetchEvents');
  }

  //
  //================================================================
  //
  //  View for the side panel.
  //
  //================================================================
  //

  //  I propose to use the View for the bits where we need to do the
  //  drawing, but keep FullCalendar mostly outside it.  It can do its
  //  own drawing.  The view will however trigger FC to refetch its events
  //  when something interesting happens.
  //
  var AllocationView = Backbone.View.extend({
    el: '#pending-allocations',
    template: _.template($('#an-allocation').html()),
    highlighting: 0,
    initialize: function(options) {
      dataset.addListener(this.checkChanges, this, true);
    },
    clicked: function(event) {
      var button = event['currentTarget'];
      var pcid = $(button).data('pcid');
      dataset.setCurrent(pcid);
    },
    checkChanges: function() {
      var toHighlight = dataset.getCurrent();
      this.highlighting = toHighlight;
      this.render();
    },
    render: function() {
      //
      //  Cancel draggability of any existing items.
      //
      this.$el.find('.single-allocation').each(function(index) {
        if ($(this).data('ui-draggable')) {
          $(this).draggable("destroy");
        }
      });
      //
      //  Set up our new list.
      //
      var texts = [];
      var that = this;
      var extraClass;
      var unallocated = dataset.unallocatedInCurrentWeek();
      for (var i = 0; i < unallocated.length; i++) {
        var item = unallocated[i];

        if (item.pcid === that.highlighting) {
          extraClass = " selected";
        } else {
          extraClass = "";
        }
        texts.push(that.template({
          extra_class: extraClass,
          pcid: item.pcid,
          pupil_id: item.pupil_id,
          pupil: item.name,
          subject: item.subject
        }));
      }
      this.$el.html(
        texts.join(" ")
      );
      //
      //  And make selected draggable.
      //
      this.$el.find('.single-allocation.selected').each(function(index) {
        $(this).draggable({
          revert: true,
          cursorAt: { top: 0 },
          zIndex: 10,
          revertDuration: 0
        });
      });
      this.$el.find('.single-allocation').each(function(index) {
        $(this).click(that.clicked);
      });
    }
  });

  //
  //================================================================
  //
  //  Initialisation entry point.
  //
  //================================================================
  //

  that.init = function() {
    //
    //  We have already checked that our master parent division
    //  exists, otherwise we wouldn't be running at all.
    //
    var json_data = myData.text();
    var data = JSON.parse(json_data);
    //
    //  The allocation variable is defined globally in this module.
    //
    dataset = makeDataset(data);

    //
    //  Now we need some info from the model to set up our
    //  parameters to pass to FullCalendar.
    //
    fcParams.defaultDate = dataset.startsForFC();
    fcParams.validRange = {
      start: dataset.startsForFC(),
      end:   dataset.endsForFC()
    };
    fcParams.events = generateEvents;
    calDiv.fullCalendar(fcParams);
    //
    //  And a view to handle the LHS bit.
    //
    var av = new AllocationView();
    av.render();
    //
    //  And we need to do things to the Calendar if the current
    //  attribute changes.
    //
    dataset.addListener(checkChange);
    //
    //  Handle clicks on our save button.
    //
    $('#save-button').click(dataset.doSave);
  }

  return that;

}();

//
//  Once the DOM is ready, get our code to initialise itself.
//
$(editing_allocation.init);

}
