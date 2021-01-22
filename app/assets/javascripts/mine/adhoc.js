"use strict";

if ($('.ahd-listing').length) {
  $(
    function() {
      var that = {};

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
        var my_row = $(button).closest(".row");
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

      that.init = function() {
        $('.toggle').click(clickHandler);

        window.updateTotals = function(subject_id, num_staff, num_pupils) {
          var target_row = $('div#ahd-subject-' + subject_id);
          $(target_row).find('.num-staff').text(num_staff + ' staff');
          $(target_row).find('.num-pupils').text(num_pupils + ' pupils');
        }

        //
        //  We will use the CSS convention of indexing from 1 (nasty).
        //
        window.insertSubjectAt = function(text, index, owner_id) {
          //
          //  We convert the provided text to being an HTML element
          //  before we insert it so we can attach the click handler.
          //
          var html = $.parseHTML(text);
          $(html).find('.toggle').click(clickHandler);
          //
          //  And now insert.
          //
          var marker = $('div#ahd-subject-listing > div:nth-child(' + index + ')');
          if (marker.length === 0) {
            marker = $('div#ahd-subject-listing > div:last-child');
          }
          marker.before(html);
          //
          //  And now a bit of tidying up.
          //
          var name_field = $('#subject-element-name-' + owner_id);
          name_field.focus();
          name_field.val('');
          $('#ahd-subject-errors').html("");
        }
      };

      return that;
    }().init
  );

}
