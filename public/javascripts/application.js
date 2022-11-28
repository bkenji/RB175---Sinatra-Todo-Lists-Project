$(function() {

  $(".delete").on("click", function(event) {
    if (confirm("Are you sure you want to proceed? This cannot be undone.")) {
    } else {
      event.preventDefault();
      event.stopPropagation();
    }
  });
});