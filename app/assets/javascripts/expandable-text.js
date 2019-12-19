(function() {

  function init() {
    var expandable = document.getElementById("script-applies-to");
    if (!expandable) {
      return;
    }
    // Use a multiple of line height to prevent partially displayed lines
    var height = parseInt(getComputedStyle(expandable).height, 10);
    var lineHeight = parseInt(getComputedStyle(expandable).lineHeight, 10) || parseInt(getComputedStyle(expandable).fontSize, 10);
    // Matching the number of metas on the other side
    var lines = 8;
    var maxAllowedHeight = lineHeight * lines;
    if (height <= maxAllowedHeight) {
      return;
    }

    expandable.style.overflow = "hidden";
    expandable.parentNode.style.position = "relative";

    function toggle(andScroll) {
      if (expandable.style.height == "auto" || expandable.style.height == "") {
        expandable.style.height = maxAllowedHeight + "px";
        span.removeChild(span.firstChild);
        span.appendChild(document.createTextNode(expandable.getAttribute("data-show-more-text")))
        if (andScroll) {
          setTimeout(function() {expandable.scrollIntoView()}, 10);
        }
      } else {
        expandable.style.height = "auto";
        span.removeChild(span.firstChild);
        span.appendChild(document.createTextNode(expandable.getAttribute("data-show-less-text")));
      }
    }

    var span = document.createElement("span");
    span.className = "expander";
    span.style.position = "absolute";
    span.style.right = "0";
    span.style.marginTop = "-" + lineHeight + "px";
    span.appendChild(document.createTextNode(expandable.getAttribute("data-show-more-text")));
    span.addEventListener("click", function(){toggle(true)});
    expandable.parentNode.appendChild(span);
    toggle(false);
  }

  window.addEventListener("DOMContentLoaded", init);
})();
