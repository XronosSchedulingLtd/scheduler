"use strict";

//
//  Are we on the right page?  If not, do nothing.
//
if ($('#freedatepicker').length &&
    $('#ff-buttons-2').length) {
  var fdp2 = function() {
    var period_definitions;
    var date_field;
    var start_time_field;
    var end_time_field;
    var target_div;
    var that = {};

    function buttonClicked(item)  {
      start_time_field.val($(this).data('start'));
      end_time_field.val($(this).data('end'));
    };

    function htmlFor(item, index) {
      return "<li class='zfbutton tiny period-selector' data-start='" +
             item[0] +
             "' data-end='" +
             item[1] +
             "' title='" +
             item[0] +
             " to " +
             item[1] +
             "'>" +
             index +
             "</li>";
    };

    function createButtonsForDate() {
      var dayNo = new Date($('#freedatepicker').val()).getDay();
      var newContents = [];
      newContents.push("<ul class='zfbutton-group round'>");
      if (period_definitions[dayNo].length > 0) {
        period_definitions[dayNo].forEach( function(item, index) {
          newContents.push(htmlFor(item, index));
        });
      } else {
        newContents.push("<li class='zfbutton tiny'>None on this day</li>");
      }
      newContents.push("</ul>");
      target_div.html(newContents.join(' '));
      target_div.find('.period-selector').click(buttonClicked)
    };

    that.init = function() {
      date_field = $('#freedatepicker');
      date_field.datepicker({
        showOtherMonths: true,
        selectOtherMonths: true,
        dateFormat: 'yy-mm-dd'
      });
      //
      //  Periods may not be defined.  If not, still provide fallback
      //  functionality.
      //
      var period_definitions_div = $('#period-definitions');
      if (period_definitions_div.length) {
        period_definitions = JSON.parse(period_definitions_div.html());
        start_time_field = $('#freefinder_start_time_text');
        end_time_field = $('#freefinder_end_time_text');
        target_div = $('#ff-buttons-2');
        createButtonsForDate();
        date_field.on("change", createButtonsForDate);
      }

    };
    return that;
  }();

  $(fdp2.init);
}
