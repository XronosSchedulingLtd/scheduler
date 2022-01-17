"use strict";

if ($('#ahd-allocation-table').length) {
  $(
    function() {
      var that = {};

      function clickHandler(event) {
        if ($(this).hasClass('disabled')) {
          event.preventDefault();
          return false;
        } else {
          $('.automatic-button').addClass('disabled');
          $(this).text("Please wait");
          return true;
        }
      }

      that.init = function() {
        $('.automatic-button').click(clickHandler);

        window.updateCycleStats = function(id, percentage, todo, score) {
          $('.automatic-button').removeClass('disabled').text('Automatic');
          $('#ad-percent-' + id).text(percentage);
          $('#ad-todo-' + id).text(todo);
          $('#ad-score-' + id).text(score);
        }
      }

      return that;

    }().init
  );
}

