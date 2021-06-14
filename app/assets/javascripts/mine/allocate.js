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
  //  Things to help with manipulating times and shifts
  //
  //================================================================
  //

  //
  //  A helper function to convert a Moment object to a number
  //  of minutes since midnight, ignoring any DST issues.  We
  //  want 09:00 to be 540 minutes after midnight regardless.
  //
  var toMins = function(a_moment) {
    var bits = a_moment.format('HH:mm').split(':');
    var mins = (parseInt(bits[0], 10) * 60) + parseInt(bits[1], 10);
    return mins;
  };

  var pad = function(input) {
    //
    //  Leading zeroes are stupidly difficult in JavaScript.
    //
    return ('0' + input).slice(-2);
  };

  var to_time = function(mins) {
    var hours = Math.floor(mins / 60);
    var minutes = mins % 60;
    return pad(hours) + ':' + pad(minutes);
  };

  //
  //  A period of time from b_mins after midnight to e_mins
  //  after midnight.  Inclusive start, exclusive end.  e_mins
  //  must be larger than b_mins.
  //
  var makeShift = function(b_mins, e_mins) {

    var that = {};

    that.includes = function(instant) {
      //
      //  instant is also expressed as minutes after midnight.
      //
      return b_mins <= instant && instant < e_mins;
    };

    that.starts_at = function(instant) {
      //
      //  Is this when we start at?
      //
      return b_mins === instant;
    }

    that.ends_at = function(instant) {
      //
      //  Is this when we end at?
      //
      return e_mins === instant;
    }

    that.starts_before = function(instant) {
      //
      //  Do we start before the indicated time.
      //
      return b_mins < instant;
    }

    that.starts_after = function(instant) {
      //
      //  Do we start after the indicated time.
      //
      return b_mins > instant;
    }

    that.ends_before = function(instant) {
      //
      //  Do we end after the indicated time.
      //
      return e_mins < instant;
    }

    that.ends_after = function(instant) {
      //
      //  Do we end after the indicated time.
      //
      return e_mins > instant;
    }

    //
    //  abuts returns true if one starts as the other ends.
    //
    that.abuts = function(other) {
      return other.starts_at(e_mins) || other.ends_at(b_mins);
    };

    that.coterminates = function(other) {
      //
      //  Starts or ends at precisely the same time.
      //
      return other.starts_at(b_mins) || other.ends_at(e_mins);
    };

    that.overlaps = function(other) {
      //
      //  Shares at least one common time.  May be just an instant,
      //  but must be internal as end times are exclusive.  If two
      //  shifts abut then they do not overlap.
      //
      return other.ends_after(b_mins) && other.starts_before(e_mins);
    };

    that.avoids = function(other) {
      return !that.overlaps(other);
    };

    that.within = function(ob_mins, oe_mins) {
      //
      //  Do we lie entirely within the indicated time.
      //
      return b_mins >= ob_mins && e_mins <= oe_mins;
    };

    that.contains = function(other) {
      return other.within(b_mins, e_mins);
    };

    that.equals = function(other) {
      return other.starts_at(b_mins) && other.ends_at(e_mins);
    };

    that.duration = function() {
      //
      //  Give duration in minutes.
      //
      return e_mins - b_mins;
    };

    that.shiftBefore = function(new_b_mins) {
      //
      //  Create a new shift immediately before ourselves with the
      //  indicated new_b_mins value.
      //
      return makeShift(new_b_mins, b_mins);
    };

    that.shiftAfter = function(new_e_mins) {
      //
      //  Create a new shift immediately after ourselves with the
      //  indicated new_e_mins value.
      //
      return makeShift(e_mins, new_e_mins);
    };

    that.minsAfter = function(other) {
      //
      //  How many minutes after the indicated object do we start?
      //
      return other.gapBefore(b_mins);
    };

    that.minsBefore = function(other) {
      //
      //  How many minutes before the indicated object do we end?
      //
      return other.gapAfter(e_mins);
    };

    that.subtract = function(other, do_yield) {
      if (this.overlaps(other)) {
        if (!other.contains(this)) {
          //
          //  There should be something left.
          //
          if (other.starts_after(b_mins)) {
            //
            //  We start first.  Keep our early part.
            //
            do_yield(other.shiftBefore(b_mins));
          }
          if (other.ends_before(e_mins)) {
            //
            //  We end second.  Keep our late part.
            //
            do_yield(other.shiftAfter(e_mins));
          }
        }
      } else {
        do_yield(this);
      }
    };

    that.startMomentOn = function(date) {
      //
      //  Passed a moment giving a date, pass pack another moment
      //  with when we would start on that date.
      //
      return moment(date.format("YYYY-MM-DD ") + to_time(b_mins));
    };

    that.format = function() {
      //
      //  Want to produce something of the form "HH:MM - HH:MM".
      //
      return to_time(b_mins) + " - " + to_time(e_mins) + " (" + b_mins + " - " + e_mins + ")";
    };

    return that;
  };


  var makeTimeSlot = function(b_text, e_text) {
    var bits;
    
    bits = b_text.split(':');
    var b_mins = (parseInt(bits[0], 10) * 60) + parseInt(bits[1], 10);
    bits = e_text.split(':');
    var e_mins = (parseInt(bits[0], 10) * 60) + parseInt(bits[1], 10);
    var that = makeShift(b_mins, e_mins);

    return that;
  };

  //
  //  Make an instant object.  We still go via text to avoid issues
  //  with DST.  We are interested in mins since midnight on a *normal*
  //  day.
  //
  var makeInstant = function(a_moment) {
    var mins = toMins(a_moment);

    var that = {};

    //
    //  We emulate a Shift just enough that some of its functions
    //  will work.
    //

    that.within = function(ob_mins, oe_mins) {
      //
      //  Do we lie entirely within the indicated time.
      //  Note that if we are the last moment of the slot
      //  then we don't.
      //
      return mins >= ob_mins && mins < oe_mins;
    };

    //
    //  By how much are we *before* given_mins?  Answer may be negative
    //  if we are not before.
    //
    that.gapBefore = function(given_mins) {
      return given_mins - mins;
    };

    that.gapAfter = function(given_mins) {
      return mins - given_mins;
    };

    that.format = function() {
      //
      //  Want to produce something of the form "HH:MM".
      //
      return to_time(mins);
    };

    that.mins = function() {
      return mins;
    };

    return that;
  };

  var makeTimeSlotSet = function(b_text, e_text) {
    //
    //  A TimeSlotSet only ever represents an ordered set of non-overlapping
    //  time slots.
    //
    //  Start with an array of just one slot.
    //
    var slots = [makeTimeSlot(b_text, e_text)];

    var doRemove = function(slot) {
      var working;
      var current;
      var that = this;

      //
      //  Subtract a time_slot from the space which we occupy, splitting
      //  things as necessary.
      //
      if (slot.duration !== 0) {
        working = this.slice();
        this.length = 0;
        while (current = working.shift()) {
          if (current.overlaps(slot)) {
            //
            //  We might end up chopping current into two parts.
            //
            current.subtract(slot, function(remains) {
              that.push(remains);
            });
          } else {
            this.push(current);
          }
        }
      }
    };

    var doContainingFor = function(instant, duration) {
      //
      //  Go through our time slots looking for one which both
      //  contains instant and is at least duration long.
      //
      //  Return null if not found.
      //
      var current;
      var i;

      for (i = 0; i < this.length; i++) {
        current = this[i];
        if (current.contains(instant) &&
            current.duration() >= duration) {
          return current;
        }
      }
      return null;
    };

    var doAfterFor = function(instant, duration) {
      //
      //  Go through our time slots looking for one which is
      //  after instant and is at least duration long.
      //
      //  Return null if not found.
      //
      var current;
      var i;

      for (i = 0; i < this.length; i++) {
        current = this[i];
        if (current.starts_after(instant.mins()) &&
            current.duration() >= duration) {
          return current;
        }
      }
      return null;
    };

    var doLastingFor = function(duration) {
      //
      //  Go through our time slots looking for one which is
      //  after instant and is at least duration long.
      //
      //  Return null if not found.
      //
      var current;
      var i;

      for (i = 0; i < this.length; i++) {
        current = this[i];
        if (current.duration() >= duration) {
          return current;
        }
      }
      return null;
    };

    var doDup = function() {
      var new_slots;

      new_slots = this.slice();
      new_slots.remove = doRemove;
      new_slots.dup = doDup;
      new_slots.containingFor = doContainingFor;
      new_slots.afterFor = doAfterFor;
      new_slots.lastingFor = doLastingFor;
      return new_slots;
    };

    slots.remove = doRemove;
    slots.dup = doDup;
    slots.containingFor = doContainingFor;
    slots.afterFor = doAfterFor;
    slots.lastingFor = doLastingFor;

    return slots;
  };


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
  //  A note on the storage of times.  If stored in a Moment object
  //  then they are stored with DST set as appropriate.  If stored
  //  as text then they are in current local time.
  //
  //  During periods of DST, FC returns them as Moment objects but
  //  with DST *not* set.  (Not sure how it does this.)  Thus when
  //  it should return 12:30 DST, it returns 12:30 GMT, but the object
  //  still formats as "12:30".
  //

  var massageFcTiming = function(t) {
    //
    //  There seems to be a slight bijou bugette in FullCalendar
    //  in that although it provides us with a Moment object containing
    //  the event's start time, it ignores DST.  Thus if an event is
    //  due to start at 12:30 BST, the object coming from FC has
    //  it as 12:30 GMT (13:30 BST).
    //
    //  Interestingly though, although the Moment object contains
    //  the date, if you ask it to format the time it gives it as 12:30.
    //  Must be some setting within the object turning DST off completely.
    //
    //  It only hurts when we start doing comparison of Moment objects.
    //
    //  We cope by converting to text and then back again.  The newly
    //  created moment object then has DST switched on as appropriate.
    //
    //  I believe that if the FC bugette is fixed at a later date,
    //  this approach will continue to work.
    //

    return moment(t.format("YYYY-MM-DD HH:mm"));
  };

  var makeTimetable = function(pupil_id, mine) {

    var that = mine.timetables[pupil_id];
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
      this.ends_at = massageFcTiming(event.end);
      mine.recalculatePupilCourse(pcid);
    };

    that.adjustTiming = function(event) {
      //
      //  Note that it is possible to drag an event onto a completely
      //  different day, in which case the "allocations" object needs
      //  to update its structures.
      //
      var old_date = this.starts_at.format("YYYY-MM-DD");
      var new_date;

      this.starts_at = massageFcTiming(event.start);
      new_date = this.starts_at.format("YYYY-MM-DD");
      this.ends_at = massageFcTiming(event.end);
      //
      //  Only worried about a change in date.
      //
      if (old_date !== new_date) {
        mine.dateChanged(this, old_date, new_date);
      }
      mine.recalculatePupilCourse(pcid);
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

    that.shift = function() {
      //
      //  Return the timing of this allocation as a shift.
      //
      return makeShift(toMins(this.starts_at), toMins(this.ends_at));
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
    var doAdd = function(starts_at, ends_at, pcid) {
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

    //
    //  Externally visible version which forces a recalculation.
    //
    that.add = function(starts_at, ends_at, pcid) {
      doAdd(starts_at, ends_at, pcid);
      mine.recalculatePupilCourse(pcid);
    };

    for (i = 0; i < allocated.length; i++) {
      doAdd(
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

    that.onDate = function(date) {
      //
      //  Return all the allocations on a given date.
      //  Return an empty array if none found.
      //
      var result = by_date[date.format("YYYY-MM-DD")];
      if (!result) {
        result = [];
      }
      return result;
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
          loadings = loadings_by_pid[pc.pupil_id];
          if (!loadings) {
            loadings = (loadings_by_pid[pc.pupil_id] = {});
          }
          if (loadings[lesson.s] === undefined) {
            loadings[lesson.s] = 1;
          } else {
            loadings[lesson.s] = loadings[lesson.s] + 1;
          }
        }
      }
    }

    that.recalculateLoadingOf = function(pid) {
      //
      //  Something has changed for the indicated pupil.  Recalculate
      //  his or her loading.  Note that said pupil may have one
      //  or more PupilCourses.
      //
      var allocations = mine.allocations.all();

      //
      //  New blank record for this pupil.
      //
      var new_loadings = {};
      var i,j;

      for (i = 0; i < allocations.length; i++) {
        allocation = allocations[i];
        pc = pcs[allocation.pcid];
        if (pc.pupil_id === pid) {
          //
          //  Now need to find all timetable lessons which clash with this
          //  allocation.
          //
          lessons = pc.timetable.entriesOn(moment(allocation.starts_at));
          for (j = 0; j < lessons.length; j++) {
            lesson = lessons[j];
            if (allocation.overlapsLesson(lesson)) {
              if (new_loadings[lesson.s] === undefined) {
                new_loadings[lesson.s] = 1;
              } else {
                new_loadings[lesson.s] = new_loadings[lesson.s] + 1;
              }
            }
          }
        }
      }
      //
      //  And replace the old record for this pupil.
      //
      loadings_by_pid[pid] = new_loadings;
    };

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

  var makeMinsOfDay = function(textual) {
    //
    //  We are very fussy.  We accept NN:NN, and not much else.
    //  (One digit in each half is OK.)
    //
    var bits = textual.split(':');

    return (parseInt(bits[0], 10) * 60) + parseInt(bits[1], 10);
  }

  var makeAvailable = function(available, mine) {
    //
    //  It is just possible that an allocation cycle could straddle
    //  the change into or out of DST.  We therefore need to be careful
    //  to ensure that all our conversions between textual and Moment
    //  representation occur for the same actual date.  If we did them
    //  for different dates then one could be in DST and the other not
    //  and then comparisons would all go wrong.
    //
    //  We can however convert textual versions naively to
    //  "minutes since midnight", which will give us all we need.  Don't
    //  need to worry about DST, provided we can convert back and get the
    //  same textual representation again.
    //
    //  Normally 08:00 is 480 minutes after midnight (8 * 60).
    //  On the day DST starts, it is only 420 minutes after midnight
    //  (because the clocks jumped forward).  However, as long as
    //  we always convert 08:00 to 480 and always convert 480 to 08:00
    //  we don't have a problem.
    //
    var start_mins   = makeMinsOfDay(available.starts_at);
    var end_mins     = makeMinsOfDay(available.ends_at);
    var start_string = available.starts_at;
    var end_string   = available.ends_at;
    var wday         = available.wday;

    var slots = makeTimeSlotSet(available.starts_at, available.ends_at);

    var that = makeTimeSlot(available.starts_at, available.ends_at);

    that.happensOn = function(required_wday) {
      return required_wday === wday;
    };

    that.startsAtOn = function(date) {
      return date.format('YYYY-MM-DD ') + start_string;
    };

    that.endsAtOn = function(date) {
      return date.format('YYYY-MM-DD ') + end_string;
    };

    that.asSlotSet = function() {
      //
      //  Don't give the caller our original because he will only go
      //  and mess with it.
      //
      return slots.dup();
    };

    return that;
  };

  var makeAvailables = function(spec, mine) {
    var result = [];
    for (var i = 0; i < spec.availables.length; i++) {
      result.push(makeAvailable(spec.availables[i]));
    }

    result.on = function(date) {
      var wday = date.day();
      return _.select(this, function(entry) {
        return entry.happensOn(wday);
      });
    };

    result.bestFit = function(when) {
      //
      //  Find the best "available" slot for an indicated date and
      //  time, passed as a moment object.
      //
      //  If there are no available slots at all on that day then
      //  we return null, otherwise we will return the one containing
      //  the indicated time, or the one nearest.
      //
      var slot;

      var candidates = result.on(when);
      var instant = makeInstant(when);
      var best;
      var delta;
      var i;

      if (candidates && candidates.length > 0) {
        //
        //  Go first for one which actually contains the time.
        //
        slot =
          candidates.find(function(entry) { return entry.contains(instant) });
        if (!slot) {
          //
          //  Go for nearest slot after, or if none then the nearest
          //  slot before.
          //
          best = 2000;  // More than there are minutes in a day.
          for (i = 0; i < candidates.length; i++) {
            delta = candidates[i].minsAfter(instant);
            if (delta >= 0 && delta < best) {
              slot = candidates[i];
              best = delta;
            }
          }
          if (!slot) {
            for (i = 0; i < candidates.length; i++) {
              delta = candidates[i].minsBefore(instant);
              if (delta >= 0 && delta < best) {
                slot = candidates[i];
                best = delta;
              }
            }
          }
        }
        return slot;
      } else {
        return null;
      }
    };

    return result;
  };

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
    that.availables = makeAvailables(spec, mine);

    //
    //  To start with, no PupilCourse is current.
    //
    var current = 0;
    //
    //  Who wants to know about interesting changes?
    //
    var listeners = [];

    var tellListeners = function(datechange) {
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
    //  What is the duration (in minutes) of the indicated
    //  Pupil Course.
    //
    var durationOf = function(pcid) {
      var pc = pcs[pcid];
      if (pc) {
        return pc.mins;
      } else {
        return 0;
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

    mine.recalculatePupilCourse = function(pcid) {
      var pc = pcs[pcid];

      if (pc) {
        that.loadings.recalculateLoadingOf(pc.pupil_id);
        tellListeners(false);
      }
    };

    that.subjects = spec.subjects;

    //
    //  And now we add public methods.
    //
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

    that.addAllocation = function(starts_at, pcid) {
      //
      //  We are passed starts_at (a Moment) which came from
      //  FullCalendar, plus a pcid.  We take the requested
      //  starts_at as merely indicative.  We will jiggle things
      //  a bit to try to make the new allocation fit in well.
      //
      //  Firstly, find the relevant availability slot.
      //
      var duration = durationOf(pcid);
      var existing;
      var ends_at;
      var existing_shifts;
      var free_times;
      var i;
      var instant;
      var selected;

      var slot = that.availables.bestFit(starts_at);
      if (slot) {
        //
        //  We've found the teacher's best availability slot.  Now,
        //  how much of it is already taken up?
        //
        existing = mine.allocations.onDate(starts_at);
        //
        //  The above will find all allocations, not just those which overlap
        //  but it doesn't matter.
        //
        existing_shifts = existing.map(function(a) { return a.shift(); });

        free_times = slot.asSlotSet();
        for (i = 0; i < existing_shifts.length; i++) {
          free_times.remove(existing_shifts[i]);
        }
        //
        //  We now have a list (possibly empty) of free times within
        //  the indicated availability slot.  We need to choose which
        //  of these to use.
        //
        //  Go for the one containing our time, if it's big enough.
        //  Otherwise go for the first subsequent one which is big enough.
        //  Otherwise go for the first one which is big enough.
        //
        instant = makeInstant(starts_at);
        selected = free_times.containingFor(instant, duration);
        if (!selected) {
          selected = free_times.afterFor(instant, duration);
        }
        if (!selected) {
          selected = free_times.lastingFor(duration);
        }
        if (selected) {
          //
          //  Put it at the start of this gap.
          //
          starts_at = selected.startMomentOn(starts_at);
        }
      }
      ends_at = moment(starts_at).add(duration, 'minutes');
      mine.allocations.add(starts_at, ends_at, pcid);
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

    that.addListener = function(callback, context, dates) {
      listeners.push({callback: callback, context: context, dates: dates});
    };

    that.setCurrent = function(pcid) {
      var old_val = current;

      current = pcid;
      if (current !== old_val) {
        tellListeners(false);
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

    //var able = makeTimeSlotSet("09:00", "15:00");
    //var baker = makeTimeSlot("12:15", "13:30");

    //able.remove(baker);

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
      right: 'agendaWeek,agendaDay'
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
//    if (element.hasClass("fc-time-grid-event") && (event.timetable === 1)) {
//      element.css("margin-right", "20px");
//    }
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

    //
    //  There seems to be a slight bijou bugette in FullCalendar
    //  in that although it provides us with a Moment object containing
    //  the event's start time, it ignores DST.  Thus if an event is
    //  due to start at 12:30 BST, the object coming from FC has
    //  it as 12:30 GMT (13:30 BST).
    //
    //  It only hurts when we start doing comparison of Moment objects.
    //
    //  We cope by converting to text and then back again.
    //
    var starts_at = massageFcTiming(startsAt);
    //
    //  We now know the time at which the new allocation has been dropped
    //  but we need to exercise a bit of intelligence about how exactly
    //  to interpret this.
    //
    dataset.addAllocation(starts_at, pcid);
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
      var availables = dataset.availables.on(date);
      for (i = 0; i < availables.length; i++) {
        entry = availables[i];
        events.push({
          start: entry.startsAtOn(date),
          end: entry.endsAtOn(date),
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
    dataset.addListener(checkChange, null, false);
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
