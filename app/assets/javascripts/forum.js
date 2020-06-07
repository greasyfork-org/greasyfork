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
    let subscribeLink = document.querySelector(".discussion-subscribe");
    if (subscribeLink) {
      subscribeLink.addEventListener("ajax:success", function(event) {
        let subscribeContainer = document.querySelector(".discussion-subscription-links");
        subscribeContainer.classList.add("discussion-subscribed");
        subscribeContainer.classList.remove("discussion-not-subscribed");
      });
    }
    let unsubscribeLink = document.querySelector(".discussion-unsubscribe");
    if (unsubscribeLink) {
      unsubscribeLink.addEventListener("ajax:success", function(event) {
        let subscribeContainer = document.querySelector(".discussion-subscription-links");
        subscribeContainer.classList.add("discussion-not-subscribed");
        subscribeContainer.classList.remove("discussion-subscribed");
      });
    }
  }
  window.addEventListener("DOMContentLoaded", init);
})();
