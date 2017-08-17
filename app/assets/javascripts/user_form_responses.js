"use strict";
//
//  And this is the code for filling in a form.
//
if ($('.user-form-response-area').length) {

//
//  Wrap everything in a function to avoid namespace pollution
//  Note that we invoke the function immediately.
//
var user_form_response = function() {
  var that = {};

  that.handleSave = function() {
    var userForm = $('#user-form');
    if (userForm[0].checkValidity()) {
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
      that.responseField.val(producedJSON);
      that.serverForm.submit();
    } else {
      //
      //  This seems slightly dangerous, in that we don't really want this
      //  form to submit.  We have however already checked that it's
      //  invalid, so it shouldn't submit.
      //
      userForm.find(':submit').click();
    }
  }

  that.init = function() {
    that.responseArea = $('.user-form-response-area');
    that.responseField = $('#user_form_response_form_data');
    that.serverForm = $("form[class$=_user_form_response]");
    //
    //  Render the form with its default contents.
    //
    that.responseArea.formRender({
      dataType: 'json',
      formData: $('#user_form_response_definition').val()
    });
    //
    //  And now fill in with existing user data, if any.  If the
    //  response field is empty (e.g. because this is a completely
    //  new response) then the JSON parser will throw an error.
    //  In that case, just don't bother filling it in.
    //
    var suppliedJSON = that.responseField.val();
    if (suppliedJSON.length > 0) {
      try {
        var existingData = JSON.parse(suppliedJSON);
        for (var i = 0; i < existingData.length; i++) {
          var ed = existingData[i];
          var targetField = that.responseArea.find('#' + ed['id']);
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
    $('#save-button').click(that.handleSave);
  }

  return that;

}();

$(user_form_response.init);
}

