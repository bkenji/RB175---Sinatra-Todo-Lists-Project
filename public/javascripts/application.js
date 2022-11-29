$(function() {

  $(".delete").on("click", function(event) {
   event.preventDefault();
   event.stopPropagation();

    if (confirm("Are you sure you want to go ahead? This cannot be undone.")) {
      var item = $(this);

      var request = $.ajax({
        url: item.attr("action"),
        method: item.attr("method"),
      });

      request.done(function(data, textStatus, jqXHR) {
        if (jqXHR.status === 204) {
          item.parent("li").remove()
          $(".flash_message").html(" <div class='flash success'> <p> Todo item deleted. </p></div>")
        } else if (jqXHR.status === 200) {
          document.location = data;
        }
      });
    }
  });
    // no `else` branch necessary, since lines 4 and 5 already halt the event.
});