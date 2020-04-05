window.addEventListener("codefund", function(evt) {
  console.log("codefund event: " + evt.detail);
  if (evt.detail.status !== 'ok' || evt.detail.house) {
    var carbonPlaceholder = document.getElementById("_carbonads_js");
    // No Carbon on the page, or this has already run.
    if (!carbonPlaceholder || carbonPlaceholder.nodeName == 'SCRIPT') {
      return;
    }

    var codefundElement = document.getElementById("codefund");
    if (codefundElement) {
      codefundElement.parentNode.removeChild(codefundElement);
    }

    var carbonScript = document.createElement('script');
    carbonScript.type = 'text/javascript';
    carbonScript.src = carbonPlaceholder.getAttribute("data-src");
    carbonScript.setAttribute("id", carbonPlaceholder.getAttribute("id"));

    var parent = carbonPlaceholder.parentNode;
    parent.removeChild(carbonPlaceholder);
    parent.appendChild(carbonScript);
    parent.style.display = "block";
  }
});
