import sha1 from 'js-sha1';
import MicroModal from 'micromodal';
import { canInstallUserJS, canInstallUserCSS } from "./managers";
const { detect } = require('detect-browser');

function onInstallClick(event) {
  event.preventDefault();
  doInstallProcess(event.target)
}

async function doInstallProcess(installLink) {
  await detectCanInstall(installLink) &&
    await showPreviousVersionWarning(installLink) &&
    await showAntifeatureWarning() &&
    await doInstall(installLink) &&
    showPostInstall();
}

async function detectCanInstall(installLink) {
  let installTypeJS = installLink.getAttribute("data-install-format") == 'js';
  if (installTypeJS) {
    if (localStorage.getItem('manualOverrideInstallJS') == '1' || canInstallUserJS()) {
      return true;
    }
  } else if (localStorage.getItem('manualOverrideInstallCSS') == '1' || await canInstallUserCSS()) {
    return true;
  }
  return installationHelpFunction(installTypeJS)(installLink)
}

function installationHelpFunction(js) {
  return async function showInstallationHelpJS(installLink) {
    let browserType = detect().name
    let modal = document.getElementById(js ? "installation-instructions-modal-js" : "installation-instructions-modal-css")
    switch (browserType) {
      case 'firefox':
      case 'chrome':
      case 'opera':
      case 'safari':
        modal.classList.add("installation-instructions-modal-" + browserType)
        break;
      default:
        modal.classList.add("installation-instructions-modal-other")
    }
    let bypassLink = modal.querySelector(".installation-instructions-modal-content-bypass a")
    bypassLink.setAttribute("href", installLink.getAttribute("href"))
    return new Promise(resolve => {
      bypassLink.addEventListener("click", function (event) {
        resolve(true)
        localStorage.setItem(js ? 'manualOverrideInstallJS' : 'manualOverrideInstallCSS', '1')
        MicroModal.close(modal.id)
        event.preventDefault()
      })
      MicroModal.show(modal.id, {
        onClose: modal => resolve(false)
      })
    })
  }
}

async function showPreviousVersionWarning(installLink) {
  return new Promise(resolve => {
    if (installLink.getAttribute("data-is-previous-version") == "true") {
      if (!confirm(installLink.getAttribute("data-previous-version-warning"))) {
        resolve(false)
        return;
      }
    }
    resolve(true)
  })
}

async function showAntifeatureWarning() {
  return new Promise((resolve) => {
    if (document.getElementById("preinstall-modal")) {
      MicroModal.show('preinstall-modal', {
        onClose: function (modal, button, event) {
          if (event.target.hasAttribute("data-micromodal-accept")) {
            resolve(true)
          } else {
            resolve(false)
          }
        }
      });
      return;
    }
    resolve(true)
  })
}

async function doInstall(installLink) {
  return new Promise((resolve) => {
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
        resolve(true)
      }, 100);
    } else {
     location.href = installLink.href;
      resolve(true)
    }
  })
}

function onInstallMouseOver(event) {
  let url = event.target.getAttribute("data-ping-url");
  if (!url.endsWith('&mo=1')) {
    event.target.setAttribute("data-ping-url", url + (url.includes('?') ? '&' : '?') + "mo=1");
  }
}

function showPostInstall() {
  setTimeout(function() {
    let postInstall = document.querySelector(".post-install");
    if (!postInstall) {
      return;
    }
    postInstall.style.display = 'flex';
  }, 2000);
}

function init() {
  document.querySelectorAll(".install-link").forEach(function(installLink) {
    installLink.addEventListener("click", onInstallClick);
    installLink.addEventListener("mouseover", onInstallMouseOver);
  });
}

window.addEventListener("DOMContentLoaded", init);
