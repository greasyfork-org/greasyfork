// Add data-submit-anchor to make a form submit to an anchor of your choosing.
window.addEventListener("DOMContentLoaded", function() {

  function getParentForm(element) {
    while (element && element.tagName.toLowerCase() != "form") {
      element = element.parentNode;
    }
    return element;
  }

  Array.prototype.forEach.call(document.querySelectorAll("[data-submit-anchor]"), function(dsa) {
    dsa.addEventListener("click", function(e) {
      var form = getParentForm(e.target);
      if (form == null) {
        return;
      }
      form.setAttribute("action", form.getAttribute("action").split("#")[0] + "#" + e.target.getAttribute("data-submit-anchor"));
    });
  });
});
