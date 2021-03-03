"use strict";

if ($('.ahd-listing').length) {
  $(
    function() {
      var that = {};

      var by_subject_bit;
      var by_staff_bit;
      var show_template;
      var edit_template;

      function toggleVisibility() {
        if ($(this).hasClass('folded')) {
          $(this).slideDown();
          $(this).removeClass('folded');
        } else {
          $(this).slideUp();
          $(this).addClass('folded');
        }
      }

      function setVisible(thing) {
        if ($(thing).hasClass('folded')) {
          $(thing).slideDown();
          $(thing).removeClass('folded');
        }
      }

      function setHidden(thing) {
        if (!$(thing).hasClass('folded')) {
          $(thing).slideUp();
          $(thing).addClass('folded');
        }
      }

      function setThisVisible() {
        setVisible(this);
      }

      function setThisHidden() {
        setHidden(this);
      }

      function setTextHide() {
        $(this).text("Hide");
      }

      function setTextShow() {
        $(this).text("Show");
      }

      function clickHandler(event) {
        var button = event['currentTarget'];
        var existing_button_text = $(button).text()
        //
        //  An "Xxxx all" button?
        //
        var doing_all = /all$/.test(existing_button_text);
        var showing = /^Show/.test(existing_button_text);
        //
        //  Want the parent *row* of the current target.
        //
        var my_row = $(button).closest(".arow");
        var target = $(my_row).next();
        //
        //  Now the processing diverges a tiny bit.
        //
        if (doing_all) {
          //
          //  Then its next sibling.  This is a container for all the items
          //  which we are going to affect.
          //
          if (showing) {
            $(target).find('.foldable').each(setThisVisible);
            $(target).find('.toggle').each(setTextHide);
            $(button).text("Hide all");
          } else {
            $(target).find('.foldable').each(setThisHidden);
            $(target).find('.toggle').each(setTextShow);
            $(button).text("Show all");
          }
        } else {
          //
          //  We already have the item which we want to affect.
          //
          var thing = target[0];
          if (showing) {
            setVisible(thing);
            $(button).text("Hide");
          } else {
            setHidden(thing);
            $(button).text("Show");
          }
        }
      }

      function updateOK(data, textStatus, jqXHR) {
        var course_id = data.id;
        var minutes = data.minutes;

        //
        //  We apply the change to the relevant field in both
        //  tabs, but only need to revert the field in the active
        //  tab.
        //
        if (by_subject_bit.hasClass('active')) {
          var div = by_subject_bit.find('div.ahd-pupil-course-' + course_id);
          if (div.length) {
            $(div).html(show_template({mins: minutes}));
            $(div).click(minsClickHandler);
          }
          div = by_staff_bit.find('div.ahd-pupil-course-' + course_id + ' span');
          if (div.length) {
            div.text(minutes);
          }
        } else {
          var div = by_staff_bit.find('div.ahd-pupil-course-' + course_id);
          if (div.length) {
            $(div).html(show_template({mins: minutes}));
            $(div).click(minsClickHandler);
          }
          div = by_subject_bit.find('div.ahd-pupil-course-' + course_id + ' span');
          if (div.length) {
            div.text(minutes);
          }
        }
        $('.errors').html("");
      }

      function updateFailed(jqXHR, textStatus, errorThrown) {
        var json = jqXHR.responseJSON;
        var course_id = json.id;
        var subject_id = json.subject_id;
        var staff_id = json.staff_id;
        var errors = json.errors;

        var div;

        var text = errors.minutes[0];
        if (by_subject_bit.hasClass('active')) {
          div =
            by_subject_bit.find(
              'div#ahd-pupil-errors-u' + subject_id + 't' + staff_id);
        } else {
          div =
            by_staff_bit.find(
              'div#ahd-pupil-errors-t' + staff_id + 'u' + subject_id);
        }
        if (div.length) {
          div.text(text);
        }
      }

      function minsClickHandler(event) {
        var div = event['currentTarget'];
        //
        //  Need to disable click handler temporarily.
        //
        $(div).off('click');
        //
        //  There should be a span within this, which we are going to
        //  change to be an input field.
        //
        var org_contents = $(div).children('span').html();
        $(div).html(edit_template({mins: org_contents}));
        $(div).children('input').focus();
        //
        //  We will terminate input if the user presses Enter or Escape.
        //
        $(div).children('input').keyup(function(e) {
          if (e.key === 'Escape') {
            //
            //  Revert things to how they were.
            //
            var prev_value = $(e.target).data('prev-value');

            $(div).html(show_template({mins: prev_value}));
            $(div).click(minsClickHandler);
            return false;
          } else if (e.key == 'Enter') {
            //
            //  We need to send the new value up to the host.
            //
            var new_value = $(e.target).val();
            //
            //  And the ID of the record to be updated?
            //
            var id = $(e.target).parent().data('course-id');
            var prepared_data = JSON.stringify({
              ad_hoc_domain_pupil_course: {
                minutes: new_value
              }
            });
            $.ajax({
              url: '/ad_hoc_domain_pupil_courses/' + id,
              type: 'PATCH',
              context: this,
              dataType: 'json',
              contentType: 'application/json',
              data: prepared_data
            }).done(updateOK).
               fail(updateFailed);
            return false;
          } else {
            return true;
          }
        });
        //
        //  Likewise if we lose focus.
        //
        $(div).children('input').focusout(function(e) {
          //
          //  Revert things to how they were.
          //
          var prev_value = $(e.target).data('prev-value');

          $(div).html(show_template({mins: prev_value}));
          $(div).click(minsClickHandler);
        });
      }

      that.init = function() {
        by_subject_bit = $('#ahd-by-subject');
        by_staff_bit = $('#ahd-by-staff');
        //
        //  We use templates for modifying the contents of the
        //  mins span/field.
        //
        show_template = _.template($('#ahd-show-mins').html());
        edit_template = _.template($('#ahd-edit-mins').html());
        $('.toggle').click(clickHandler);
        $('.mins').click(minsClickHandler);

        //
        //  New single entry point for updates.
        //  Expects to be passed an array of objects to be actioned
        //  in order.  Each object has an "action" attribute to tell
        //  us what to do.
        //

        window.ahdUpdate = function(updates) {
          updates.forEach(function(update) {
            switch(update.action) {
              case 'show_error':
                $(update.selector).html(update.error_text);
                break;

              case 'show_pupil_error':
                //
                //  A pupil error goes in one of two places depending
                //  on which tab is active.
                //
                $('#ahd-by-subject.active #ahd-pupil-errors-u' + update.subject_id + 't' + update.staff_id).html(update.error_text);
                $('#ahd-by-staff.active #ahd-pupil-errors-t' + update.staff_id + 'u' + update.subject_id).html(update.error_text);
                break;

              case 'clear_errors':
                $('.errors').html("");
                break;

              case 'add_subject':
                //
                //  This affects only the "By subject" listing.
                //
                var html = $.parseHTML(update.html);
                $(html).find('.toggle').click(clickHandler);
                //
                //  And now insert.
                //
                var marker = $('div#ahd-subject-listing > div:nth-child(' + update.position + ')');
                if (marker.length === 0) {
                  marker = $('div#ahd-subject-listing > div:last-child');
                }
                marker.before(html);
                //
                //  Get rid of any placeholder
                //
                $('div#ahd-subject-listing div.arow.placeholder').remove();
                //
                //  And now a bit of tidying up.
                //
                var name_field = $('#ahd-by-subject.active #subject-element-name-c' + update.cycle_id);
                if (name_field.length) {
                  name_field.focus();
                  name_field.val('');
                }
                break;

              case 'add_staff':
                //
                //  This affects only the "By staff" listing.
                //
                var html = $.parseHTML(update.html);
                $(html).find('.toggle').click(clickHandler);
                //
                //  And now insert.
                //
                var marker = $('div#ahd-staff-listing > div:nth-child(' + update.position + ')');
                if (marker.length === 0) {
                  marker = $('div#ahd-staff-listing > div:last-child');
                }
                marker.before(html);
                //
                //  Get rid of any placeholder
                //
                $('div#ahd-staff-listing div.arow.placeholder').remove();
                //
                //  And now a bit of tidying up.  Do this only if the by_staff
                //  tab is currently active.
                //
                var name_field = $('#ahd-by-staff.active #staff-element-name-c' + update.cycle_id);
                if (name_field.length) {
                  name_field.focus();
                  name_field.val('');
                }
                break;

              case 'delete_subject':
                $('#ahd-subject-u' + update.subject_id).remove();
                break;

              case 'delete_staff':
                $('#ahd-staff-t' + update.staff_id).remove();
                break;

              case 'link_gone':
                //
                //  Need to delete the staff entry under the subject and
                //  the subject entry under the staff.
                //
                $('#ahd-nested-staff-u' +
                  update.subject_id +
                  't' +
                  update.staff_id).remove();
                $('#ahd-nested-subject-u' +
                  update.subject_id +
                  't' +
                  update.staff_id).remove();
                break;

              case 'update_subject_staff':
                //
                //  Update a top level subject listing by replacing its
                //  list of staff.
                //
                $('#ahd-subject-staff-u' + update.subject_id).
                  html(update.staff_listing);
                break;

              case 'update_staff_subjects':
                //
                //  Update a top level staff listing by replacing its
                //  list of subjects.
                //
                $('#ahd-staff-subject-t' + update.staff_id).
                  html(update.subject_listing);
                break;

              case 'update_staff_totals':
                var outer = '#ahd-staff-t' + update.staff_id;
                var string = outer + ' .num-subjects';
                var found = $(string);
                console.log({string});
                console.log({found});
                $(outer + ' .num-subjects').text(update.num_subjects);
                $(outer + ' .num-pupils').text(update.num_pupils);
                break;

              case 'update_subject_totals':
                var outer = '#ahd-subject-u' + update.subject_id;
                $(outer + ' .num-staff').text(update.num_staff);
                $(outer + ' .num-pupils').text(update.num_pupils);
                break;

              case 'new_pupil_listing':
                //
                //  Two places to make this appear.
                //
                var suffix = 'u' + update.subject_id + 't' + update.staff_id;
                var by_subject_selector = '#ahd-staff-pupils-' + suffix;
                var by_staff_selector = '#ahd-subject-pupils-' + suffix;


                $(by_subject_selector).html(update.pupil_listing);
                $(by_staff_selector).html(update.pupil_listing);
                //
                //  Re-activate minute clicking.
                //
                $(by_subject_selector).find('.mins').click(minsClickHandler);
                $(by_staff_selector).find('.mins').click(minsClickHandler);
                //
                //  And now one of those two should get the input focus,
                //  depending on which tab is active.
                //
                //  Need to move focus out slightly.
                //
                var by_subject_selector = '#ahd-nested-staff-' + suffix;
                var by_staff_selector = '#ahd-nested-subject-' + suffix;

                $('#ahd-by-staff.active ' + by_staff_selector + ' form input.pupil-name').val('');
                $('#ahd-by-staff.active ' + by_staff_selector + ' form input.pupil-name').focus();

                $('#ahd-by-subject.active ' + by_subject_selector + ' form input.pupil-name').val('');
                $('#ahd-by-subject.active ' + by_subject_selector + ' form input.pupil-name').focus();
                break;

              default:
                console.log("Unknown action - " + update.action);
                break;
            }
          });
        }
      };

      return that;
    }().init
  );
}

//
//  Set up sliders, even when not on our main page.
//
$('.ahd-slider').slider(
  {
    min: 0,
    max: 3,
    value: 2,
    slide: function(event, ui) {
      $('#copy-what').val(ui.value);
    }
  }
).slider('pips', {
  first: 'label',
  last: 'label',
  rest: 'label',
  labels: ["Nothing", "Subjects", "Staff", "Pupils"]});
