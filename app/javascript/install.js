import sha1 from 'js-sha1';
import MicroModal from 'micromodal';

function onInstallClick(event) {
  event.preventDefault();

  let installLink = event.target;
  if (installLink.getAttribute("data-is-previous-version") == "true") {
    if (!confirm(installLink.getAttribute("data-previous-version-warning"))) {
      return;
    }
  }

  if (document.getElementById("preinstall-modal")) {
    MicroModal.show('preinstall-modal', {
      onClose: function (modal, button, event) {
        if (event.target.hasAttribute("data-micromodal-accept")) {
          doInstall(installLink);
        }
      }
    });
    return;
  }

  doInstall(installLink);
}

function doInstall(installLink) {
  let pingUrl = installLink.getAttribute("data-ping-url")

  if (pingUrl) {
    let ping_key = sha1(installLink.getAttribute("data-ip-address") + installLink.getAttribute("data-script-id") + installLink.getAttribute("data-ping-key"));
    let xhr = new XMLHttpRequest();
    xhr.open("POST", pingUrl + (pingUrl.includes('?') ? '&' : '?') + "ping_key=" + encodeURIComponent(ping_key), true);
    xhr.overrideMimeType("text/plain");
    xhr.send();

    // Give time for the ping request to happen.
    setTimeout(function () {
      location.href = installLink.href;
    }, 100);
  } else {
    location.href = installLink.href;
  }

  setTimeout(showPostInstall, 2000);
}

function onInstallMouseOver(event) {
  let url = event.target.getAttribute("data-ping-url");
  if (!url.endsWith('&mo=1')) {
    event.target.setAttribute("data-ping-url", url + (url.includes('?') ? '&' : '?') + "mo=1");
  }
}

function showPostInstall() {
  let postInstall = document.querySelector(".post-install");
  if (!postInstall) {
    return;
  }
  postInstall.style.display = 'flex';
}

function init() {
  document.querySelectorAll(".install-link").forEach(function(installLink) {
    installLink.addEventListener("click", onInstallClick);
    installLink.addEventListener("mouseover", onInstallMouseOver);
  });
}

window.addEventListener("DOMContentLoaded", init);
