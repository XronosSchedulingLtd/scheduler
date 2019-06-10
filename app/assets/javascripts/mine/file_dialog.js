"use strict";

if ($('#file-selector-dialog').length) {

  var file_dialog = function() {
    var that = {};
    var dialog;

    function do_select() {
    }
    that.init = function() {
      dialog = $('#file-selector-dialog').dialog({
        autoOpen: false,
        height: 400,
        width: 350,
        modal: true,
        buttons: {
          'Embed': do_select,
          Cancel: function() {
            dialog.dialog('close');
          }
        }
      });

      window.openFileDialogue = function(event) {
        var oldPos = $('#note_contents').caret();
        dialog.dialog('open');
        $('#note_contents').caret(oldPos);
      }

    }

    return that;

  }();

$(file_dialog.init);
}
