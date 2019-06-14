"use strict";

if ($('#file-selector-dialog').length) {

  var file_dialog = function() {
    var that = {};
    var dialog;
    var oldPos;
    var currentlyOpen = false;

    function insertText(field, position, text) {
      var existingContents = field.val();
      var newContents = existingContents.substring(0, position) +
                        text +
                        existingContents.substring(position);
      field.val(newContents);
      field.caret(position + text.length);
    }

    function escapeMarkdown(string) {
      //
      //  Do some very basic escaping of a string to get correct
      //  Markdown
      //
      return string.replace(/_/g, '\\_');
    }

    function doSelect() {
      //
      //  We need to decide whether we are going to inject any text
      //  at all.  At the very least, the user must have put someting
      //  in the URL field.  Without that, we can do nothing at all.
      //
      //  Cases:
      //
      //  1. Just a URL.  Say, http://banana.com/
      //
      //  Inject "<http://banana.com/>"
      //
      //  We make no attempt to validate it.
      //
      //  2. A URL, plus a file name, but no text.
      //
      //  Inject "[file name](http://banana.com)"
      //
      //  3. A URL, plus text, regardless of file name.
      //
      //  Inject "[text](http://banana.com)"
      //
      //  Given text overrides the file name.
      //
      var textOfLink = $('#fsd-textoflink').val();
      var url = $('#fsd-url').val();
      var fileName = $('#fsd-filename').val();
      var textToInject = "";

      if (url.length) {
        if (textOfLink.length) {
          textToInject = "[" + textOfLink + "](" + url + ")";
        } else {
          if (fileName.length) {
            textToInject = "[" + escapeMarkdown(fileName) + "](" + url + ")";
          } else {
            textToInject = url;
          }
        }
      }

      dialog.dialog('close');
      currentlyOpen = false;
      if (oldPos !== null) {
        var contentsField = $('#note_contents');
        contentsField.focus().caret(oldPos);
        if (textToInject.length) {
          insertText(contentsField, oldPos, textToInject);
        }
      }
    }

    function fileClickHandler(event) {
      var target = event['target'];
      var nanoid = $(target).data('nanoid');
      if (nanoid.length) {
        $('#fsd-url').val('/user_files/' + nanoid);
      }

      var fileName = $(target).text();
      if (fileName.length) {
        $('#fsd-filename').val(fileName);
      }
    }

    function populateAndOpen(data, textStatus, jqXHR) {
      var list = $('#file-selector-dialog div#fsd-filelist');

      list.empty();
      data.forEach(function(item) {
        list.append('<span data-nanoid="' + item['nanoid'] + '">' + item['original_file_name'] + '</span> ');
      });
      //
      //  And set up click handlers for each of them.
      //
      list.find('span').click(fileClickHandler);
      //
      //  Remove any left-over content in our input fields from a
      //  possible previous invocation.
      //
      $('#fsd-textoflink').val('');
      $('#fsd-url').val('');
      $('#fsd-filename').val('');
      //
      //  And open it.
      //
      dialog.dialog('open');
      currentlyOpen = true;
    }

    that.init = function() {
      dialog = $('#file-selector-dialog').dialog({
        autoOpen: false,
        height: 600,
        width: 700,
        modal: true,
        buttons: {
          'Embed': doSelect,
          Cancel: function() {
            dialog.dialog('close');
            currentlyOpen = false;
            if (oldPos !== null) {
              $('#note_contents').focus().caret(oldPos);
            }
          }
        }
      });

      window.openFileDialogue = function(event) {
        var contentsField = $('#note_contents');
        //
        //  We have a problem here, in that we would like also to check
        //  whether the contents field had the focus before our dialogue
        //  opened.  The trouble is, it seems to lose the focus the
        //  instant the button is clicked, so using:
        //
        //  contentsField.is(':focus')
        //
        //  always returns false.
        //
        //  Unless I can think of a solution, we will operate on the
        //  principle of always returning focus to the input field, if
        //  it exists.
        //
        if (contentsField) {
          oldPos = contentsField.caret();
        } else {
          oldPos = null;
        }
        $.ajax({
          url: '/user_files',
          type: 'GET',
          context: this,
          contentType: 'application/json',
          dataType: 'json'
        }).done(populateAndOpen);
      }

      window.closeFileDialogue = function() {
        //
        //  If the Foundation modal closes whilst we are open, then we close
        //  too.
        //
        if (currentlyOpen) {
          dialog.dialog('close');
          currentlyOpen = false;
        }
      }

      $(document).on('closed', '[data-reveal]', window.closeFileDialogue);

    }

    return that;

  }();

$(file_dialog.init);
}
