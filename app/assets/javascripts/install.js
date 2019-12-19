(function() {
  function onInstallClick(event) {
    var installLink = event.target;
    if (installLink.getAttribute("data-is-previous-version") == "true") {
      if (!confirm(installLink.getAttribute("data-previous-version-warning"))) {
        event.preventDefault();
        return;
      }
    }
    var xhr = new XMLHttpRequest();
    xhr.open("POST", event.target.getAttribute("data-ping-url"), true);
    xhr.overrideMimeType("text/plain");
    xhr.send();

    // Give time for the ping request to happen.
    setTimeout(function() {
      location.href = installLink.href;
    }, 100);

    setTimeout(showPostInstall, 2000);

    event.preventDefault();
  }

  function hookUpInstallPingers() {
    var installLinks = document.querySelectorAll(".install-link");
    installLinks.forEach(function(installLink) {
      installLink.addEventListener("click", onInstallClick);
    });
  }

  function showPostInstall() {
    var postInstall = document.querySelector(".post-install");
    if (!postInstall) {
      return;
    }
    postInstall.style.display = 'flex';
  }

  function init() {
    hookUpInstallPingers();
  }

  window.addEventListener("DOMContentLoaded", init);
})();
