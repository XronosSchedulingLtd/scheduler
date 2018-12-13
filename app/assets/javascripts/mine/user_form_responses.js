"use strict";
//
//  And this is the code for filling in or displaying a form.
//
//  The same code is used for both edit and show functions, with
//  flags indicating different behaviour.
//
if ($('.user-form-response-area').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
//  I seem to be using a weird mix of JQuery and native DOM manipulation
//  calls.  This is probably a bad thing.  Perhaps I was experimenting
//  with using the native stuff.
//
var user_form_response = function() {
  var that = {};
  //
  //  Private variables for this module.
  //
  var responseArea;
  var responseField;
  var statusField;
  var serverForm;
  var readOnly;

  var copyEnteredData = function() {
    var elements = document.getElementById("user-form").elements
    var results = [];
    for (var i = 0; i < elements.length; i++) {
      var element = elements[i];
      if (element.type !== 'submit') {
        var desc = {}
        desc['id']      = element.id;
        desc['type']    = element.type;
        if (element.type === 'checkbox' || element.type === 'radio') {
          desc['checked'] = element.checked;
        } else {
          desc['value']   = element.value;
        }
        results.push(desc);
      }
    }
    var producedJSON = JSON.stringify(results);
    responseField.val(producedJSON);
  }

  var handleSave = function() {
    var userForm = $('#user-form');
    if (userForm[0].checkValidity()) {
      copyEnteredData();
      //
      //  It is in a sense a security risk that the status of the form
      //  is decided in the front end rather than the back end.  A
      //  malicious user could modify the code to mark a form as
      //  complete even though not all the required fields had been
      //  completed.
      //
      //  However, this doesn't actually buy the user anything.  The
      //  business of required fields is meant to make sure they don't
      //  forget anything.  If a user takes active steps to fail to
      //  fill in a field, then he or she is really just cutting off
      //  his/her nose to spite his/her face.
      //
      statusField.val('complete');
      serverForm.submit();
    } else {
      //
      //  This seems slightly dangerous, in that we don't really want this
      //  form to submit.  We have however already checked that it's
      //  invalid, so it shouldn't submit.
      //
      userForm.find(':submit').click();
    }
  }

  //
  //  This one doesn't check for validity, but also sets a flag to
  //  indicate that the form is not complete.
  //
  var handleSaveDraft = function() {
    copyEnteredData();
    statusField.val('partial');
    serverForm.submit();
  }

  that.init = function() {
    responseArea = $('.user-form-response-area');
    responseField = $('#user_form_response_form_data');
    statusField = $('#user_form_response_status');
    serverForm = $("form[class$=_user_form_response]");
    readOnly = responseArea.data("readonly");
//    console.log("Read only = " + that.readOnly);
    //
    //  Render the form with its default contents.
    //
    responseArea.formRender({
      dataType: 'json',
      formData: $('#user_form_response_definition').val()
    });
    //
    //  And now fill in with existing user data, if any.  If the
    //  response field is empty (e.g. because this is a completely
    //  new response) then the JSON parser will throw an error.
    //  In that case, just don't bother filling it in.
    //
    var suppliedJSON = responseField.val();
    if (suppliedJSON.length > 0) {
      try {
        var existingData = JSON.parse(suppliedJSON);
        for (var i = 0; i < existingData.length; i++) {
          var ed = existingData[i];
          var targetField = responseArea.find('#' + ed['id']);
          if (ed.type === "checkbox" || ed.type === "radio") {
            targetField.prop("checked", ed.checked);
          } else {
            targetField.val(ed['value']);
          }
        }
      }
      catch(err) {
        console.log("Trapped error: " + err);
      }
    }
    //
    //  May not want to let things be changed.
    //
    if (readOnly) {
      var elements = document.getElementById("user-form").elements
      for (var i = 0; i < elements.length; i++) {
        var element = elements[i];
        element.disabled = true;
      }
    }
    //
    //  There may be no save button, in which case this will do
    //  nothing.
    //
    $('#save-button').click(handleSave);
    $('#save-draft-button').click(handleSaveDraft);
  }

  return that;

}();

$(user_form_response.init);
}

