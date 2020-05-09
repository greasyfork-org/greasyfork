(function() {
  function init() {
    for (let link of document.querySelectorAll(".edit-comment")) {
      link.addEventListener("click", function(event) {
        event.preventDefault()
        document.getElementById(link.getAttribute("data-comment-container")).classList.add("edit-comment-mode");
      });
    }
    for (let link of document.querySelectorAll(".cancel-edit-comment")) {
      link.addEventListener("click", function(event) {
        event.preventDefault()
        document.getElementById(link.getAttribute("data-comment-container")).classList.remove("edit-comment-mode");
      });
    }
  }
  window.addEventListener("DOMContentLoaded", init);
})();
