function setupEthicalAdsFallback() {
  if (typeof ethicalads === "undefined") {
    setTimeout(setupEthicalAdsFallback, 100);
    return;
  }
  ethicalads.wait.then((placements) => {
    if (placements.length > 0) {
      return;
    }

    var carbonPlaceholder = document.getElementById("_carbonads_js");
    if (!carbonPlaceholder) {
      return;
    }
    var carbonScript = document.createElement('script');
    carbonScript.type= 'text/javascript';
    carbonScript.src= carbonPlaceholder.getAttribute("data-src");
    carbonScript.setAttribute("id", carbonPlaceholder.getAttribute("id"));

    var parent = carbonPlaceholder.parentNode;
    parent.removeChild(carbonPlaceholder);
    parent.appendChild(carbonScript);
    parent.style.display = "block";

    var ethicalAdsElement = document.querySelector(".ethical-ads");
    ethicalAdsElement.parentNode.removeChild(ethicalAdsElement);
  })
}

window.addEventListener("DOMContentLoaded", setupEthicalAdsFallback);
