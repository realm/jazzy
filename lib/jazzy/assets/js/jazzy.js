// On doc load, toggle the URL hash discussion if present
$(document).ready(function() {
  var linkToHash = $('a[href="' + window.location.hash +'"]');
  linkToHash.trigger("click");
});
// On x-instance-method click, toggle its discussion and animate token.marginLeft
$(".x-instance-method").click(function() {
  var animationDuration = 300;
  var tokenOffset = "15px";
  var original = $(this).css('marginLeft') == tokenOffset;
  $(this).animate({'margin-left':original ? "0px" : tokenOffset}, animationDuration);
  $content = $(this).parent().parent().next();
  $content.slideToggle(animationDuration);
});
