/*
* Repertoire incremental form validation via ajax
*
* Requires the JQuery Form plugin (http://www.malsup.com/jquery/form/)
* 
* Copyright (c) 2009 MIT Hyperstudio
* Christopher York, 03/2009
* Revised 06/2009
*/

(function($) {
  //
  // Usage:
  //
  // Invoke ajaxValidate on the form to be incrementally validated.  On the server side,
  //   your validation method should accept the same parameters as the form's actual submit method,
  //   and return a JSON hash of errors in the form { field_name: [error1, error2, ...]}; or 'true' if the 
  //   entire form validates.  By default, the plugin only enables the submit button when every
  //   field is valid.
  //
  // Basic Example:
  //
  //   Only the url for the validation webservice is required.
  //
  //   $('#my form').ajaxValidate({ url: '/validate_user' })
  //
  // Example with options:
  //
  //   $('#my form').ajaxValidate({
  //     url:      '/validate_user',                                         /* validation webservice url */
  //     disable:  false,                                                    /* allow submit for invalid forms */
  //     feedback: '#validation_feedback',                                   /* put feedback in a special div rather than per field */
  //     delegate: { 'user[password_confirmation]': 'user[password]' }       /* validate password whenever confirmation changes */
  //     initialize: true                                                    /* validate all fields on form load */
  //   })
  //
  // Also, you can configure the format of the error html by redefining ajaxValidate.format.  To use the default styling,
  //   link to the rep.ajax-validate.css file and associated assets.
  //
  // Note that input fields are identified by the 'name' attribute rather than id or class, for consistency
  //   with form-processing code on the server side.  So if your form looks like:
  //
  // <form method="post" action="/users">
  //   <div>Email:<input type="text" name="user[email]"/><div class='validate'/></div>
  //   <div>Password:<input type="password" name="user[password]"/><div class='validate'/></div>
  //   <div>Confirm:<input type="password" name="user[confirm_password]"/><div class='validate'/></div>
  //   <div style="clear:both"><input type="submit"/></div>
  // </form>
  //
  // Your validation web service should return JSON keyed to the text fields' name attributes:
  //
  // { 'user[email]': [ 'Email has already been taken by another user', 'Email must be in mit.edu domain' ], ... }
  //
  // One special case to ease usability: When the user hovers over the submit button in preparation to submit, the
  //    validator runs if the input is disabled.  This handles a common case where the user has filled the final field
  //    but not moved cursor focus.  Disabling is done via javascript rather than html, since some browsers swallow
  //    all events for disabled inputs.
  // 
  $.fn.ajaxValidate = function($$options) {
    // plugin defaults + options
    var $settings = $.extend({}, $.fn.ajaxValidate.defaults, $$options);
    return this.each(function() {
      var $form = $(this);
      // element specific options
      var o = $.meta ? $.extend({}, $settings, $form.data()) : $settings;
      // initialize and setup submit button
      initialize($form, o, false);
      // install event handlers to validate single fields when they lose focus
      $form.find(':input').blur(function() {
        // determine if field delegates to another and locate the feedback element
        var field = canonical_field($form, $(this), o);
        // remove existing feedback during server activity
        field.$feedback.empty();
        // core operation: submit form via ajax and update field feedback with formatted errors
        validate_form($form, field.$feedback, o, function(data) {
          disabled = data !== true
    	    set_disabled($form, data !== true, o);
      	  set_feedback(field.$feedback, data[field.name], o);
        });
      });
      
      // handle disabling form and submit button
      if (o.disable) {
        var $submit = $form.find(o.disable);
        
        // only allow submit if button not disabled
        $form.submit(function() {
          var disabled = $submit.hasClass('disabled');
          var $validate = $form.find('.validate');
          if (disabled) {
            $validate.fadeOut(function() { $validate.fadeIn() });
          }
          return !disabled;
        });
        
        // validate entire form when user hovers on disabled button
        $submit.mouseover(function() {
          initialize($form, o, true);
        });
      };      
    });
  };

  //
  // format errors.  pass in an array of strings, or true/undefined if there are no errors
  //
  $.fn.ajaxValidate.format = function(errors, opts) {
    if (undefined != errors || true == errors) {
      return '<ul class="error">' + $.map(errors, function(e) { return ('<li>' + e + '</li>'); }).join('') + '</ul>';
    } else {
      return '<ul class="pass"></ul>'
    }
  };

  //
  // option defaults
  //
  $.fn.ajaxValidate.defaults = {
    initialize:    false,                    /* validate all fields' initial values when form loads */
    feedback:      '~ .validate',            /* jquery selector for error feedback element, relative to the field it monitors */
    disable:       ':input[type=submit]',     /* Disable submit button until form validates: supply selector or false */
    type:          'POST',                   /* HTTP verb to use when calling web service */
    delegate:      {},                       /* delegate validation of one field to another */
    spinner:       'spinner',                /* css class to add to feedback during ajax processing */
  };

  // internal helper functions
  
  // pre-flight validation for all fields
  function initialize($form, opts, force) {
    validate_form($form, $form, opts, function(data) {
      set_disabled($form, data != true, opts);
      if (opts.initialize || force) {
        $form.find(':input').each(function() {
          var field = canonical_field($form, $(this), opts);
          set_feedback(field.$feedback, data[field.name], opts);
        });
      }
    });
  }

  // submit validation info to web service while displaying spinner
  function validate_form($form, $feedback_elem, opts, callback) {
    $feedback_elem.addClass(opts.spinner);
    // submit the form contents to the validation web service
    $form.ajaxSubmit({
  	  url: opts.url,
  	  type: opts.type,
  	  dataType: 'json',
    	beforeSend: function(xhr) { xhr.setRequestHeader("Accept", "application/json") }, /* JQuery uses wrong content type header */
  	  success: function(data) {
  	    // remove spinner and yield result to callback
    	  $feedback_elem.removeClass(opts.spinner);
    	  callback(data);
  	  } 
  	});    
  }
  
  function canonical_field($form, $field, opts) {
    // determine name of field to validate (this is the datamapper model attribute)
    var field_name = $field.attr('name');
    // handle fields whose validation delegates to another
    if (opts.delegate[field_name] != undefined) {
      field_name = opts.delegate[field_name];
      $field     = $form.find(':input[name="' + field_name +'"]');
    }
    // determine element to display error feedback
    var $feedback_elem = $field.find(opts.feedback);
    // collect info on field that is being validated
    return { name: field_name, $input: $field, $feedback: $feedback_elem }
  }
  
  function set_disabled($form, status, opts) {
    // enable/disable submit button, if option selected
    if (opts.disable) {
      if (status) $form.find(opts.disable).addClass('disabled');
      else $form.find(opts.disable).removeClass('disabled');
    }
  }

  function set_feedback($elem, errors, opts) {
    // render error markup and update feedback element
    markup = $.fn.ajaxValidate.format(errors, opts);
    $elem.html(markup);
  }
})(jQuery);
