$().ready(function() {
  $('form').validate({
    errorPlacement: function(error, element) {},
    highlight: function(element, errorClass, validClass) {
      $(element).addClass(errorClass).removeClass(validClass);
      $(element).parents('.clearfix').addClass(errorClass);
    },
    unhighlight: function(element, errorClass, validClass) {
      $(element).removeClass(errorClass).addClass(validClass);
      $(element).parents('.clearfix').removeClass(errorClass);
    }
  });
});
