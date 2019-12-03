"use strict";

//
//  This module is quite unusual in that it does nothing until explicitly
//  called on.  All it does is provide a globally visible method as
//  an entry point.
//

window.cloningRowHandler = function () {
  var that = {};

  var our_template;
  var next_index;
  var cloner_instances;
  var initial_body;
  var initial_date;

  var addClickHandler = function() {
    var template_data = {};
    template_data['index'] = next_index;
    template_data['initialdate'] = initial_date;
    template_data['initialbody'] = initial_body;
    cloner_instances.append(our_template(template_data));
    //
    //  And need to prime both the date field and the remover.
    //
    var new_row = cloner_instances.children().last();
    enableDeleteButton(next_index, new_row);
    new_row.find('.datepicker').datepicker( { dateFormat: "dd/mm/yy", stepMinute: 5 })
    next_index += 1;
  }

  var deleter = function(e) {
    e.data.remove();
  }

  var enableDeleteButton = function(index, element) {
    $(element).find('img.remover').click(element, deleter);
  }

  that.init = function() {
    //
    //  This function is called blindly when the dialogue box opens.
    //  It's up to us to check whether we're actually needed.
    //
    cloner_instances = $('#cloner-instances');
    if (cloner_instances.length) {
      //
      //  We're on.  Activate the adding button.
      //
      $('#cloner-add-button').click(addClickHandler);
      //
      //  And each of the deleting buttons.
      //
      $('.cloner-row').each(enableDeleteButton);
      //
      //  Load our template.
      //
      our_template = _.template($('#clone-date-template').html());
      //
      //  And prime our data.
      //
      next_index = parseInt($('#event_cloner_num_instances').val());
      initial_date = $('#event_cloner_original_date').val();
      //
      //  It's possible that the body text may contain surprising
      //  characters which would interfere with its use as a
      //  parameter to our template.  In particular, an apostrophe
      //  will cause it to be truncated.  Escape it to prevent
      //  this happening.
      //
      initial_body = _.escape($('#event_cloner_original_description').val());
    }
  }
  return that;
}();

