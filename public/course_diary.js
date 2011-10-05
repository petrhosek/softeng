$().ready(function() {
  $('.element').parent('li').hover(function() {
    $(this).addClass('highlighted');
  }, function() {
    $(this).removeClass('highlighted')
  });
  $('form').validate();
});
