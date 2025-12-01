import sha1 from 'js-sha1';
import { canInstallUserJS, canInstallUserCSS } from "./managers";
import onload from '~/onload'

function onInstallClick(event) {
  event.preventDefault();
  doInstallProcess(event.target)
}

async function doInstallProcess(installLink) {
  await detectCanInstall(installLink) &&
    await showPreviousVersionWarning(installLink) &&
    await showAntifeatureWarning() &&
    await doInstall(installLink) &&
    showPostInstall(installLink);
}

async function detectCanInstall(installLink) {
  let installTypeJS = installLink.getAttribute("data-install-format") === 'js';
  if (installTypeJS) {
    if (localStorage.getItem('manualOverrideInstallJS') === '1' || canInstallUserJS()) {
      return true;
    }
  } else if (localStorage.getItem('manualOverrideInstallCSS') === '1' || await canInstallUserCSS()) {
    return true;
  }
  return installationHelpFunction(installTypeJS)(installLink)
}

function installationHelpFunction(js) {
  return async function showInstallationHelpJS(installLink) {
    const { detect } = await import('detect-browser')
    let browserType = detect().name
    let modal = document.getElementById(js ? "installation-instructions-modal-js" : "installation-instructions-modal-css")
    switch (browserType) {
      case 'firefox':
      case 'chrome':
      case 'opera':
      case 'safari':
      case 'edge':
        modal.classList.add("installation-instructions-modal-" + browserType)
        break;
      default:
        modal.classList.add("installation-instructions-modal-other")
    }
    let bypassLink = modal.querySelector(".installation-instructions-modal-content-bypass a")
    bypassLink.setAttribute("href", installLink.getAttribute("href"))
    return new Promise(resolve => {
      bypassLink.addEventListener("click", function (event) {
        localStorage.setItem(js ? 'manualOverrideInstallJS' : 'manualOverrideInstallCSS', '1')
        event.preventDefault()
        modal.close("continue")
      })
      modal.addEventListener('close', (event) => { resolve(modal.returnValue == 'continue') })
      modal.showModal()
    })
  }
}

async function showPreviousVersionWarning(installLink) {
  return new Promise(resolve => {
    if (installLink.getAttribute("data-is-previous-version") === "true") {
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
    let preinstallModal = document.getElementById("preinstall-modal");
    if (!preinstallModal) {
      resolve(true)
      return
    }

    preinstallModal.addEventListener('close', (event) => { resolve(preinstallModal.returnValue == 'continue')})
    preinstallModal.showModal()
  })
}

async function doInstall(installLink) {
  return new Promise((resolve) => {
    let pingUrl = installLink.getAttribute("data-ping-url")

    if (pingUrl) {
      try {
        let pingKey = sha1(installLink.getAttribute("data-ip-address") + installLink.getAttribute("data-script-id") + installLink.getAttribute("data-ping-key"));
        let fullPingUrl = pingUrl + (pingUrl.includes('?') ? '&' : '?') + "ping_key=" + encodeURIComponent(pingKey)
        navigator.sendBeacon(fullPingUrl)

        gtag('event', 'Script install', {
          'event_label': installLink.getAttribute('data-script-id'),
          'script_id': installLink.getAttribute('data-script-id'),
          'value': 1
        });
      } catch (ex) {
        // Oh well, don't die.
        console.log(ex)
      }
    }

    location.href = installLink.href;
    resolve(true)
  })
}

function onInstallMouseOver(event) {
  let url = event.target.getAttribute("data-ping-url");
  let now = new Date()
  let moValue = sha1('4' + now.getUTCFullYear().toString() + (now.getUTCMonth() + 1).toString() + now.getUTCDate().toString() + now.getUTCHours().toString())
  if (url && !/[&?]mo=.+$/.test(url)) {
    event.target.setAttribute("data-ping-url", url + (url.includes('?') ? '&' : '?') + "mo=" + moValue);
  }
}

function showPostInstall(installLink) {
  setTimeout(() => location.href = installLink.dataset.postInstallUrl, 2000);
}

function init() {
  document.querySelectorAll(".install-link").forEach(function(installLink) {
    installLink.addEventListener("click", onInstallClick);
    installLink.addEventListener("mouseover", onInstallMouseOver);
    installLink.addEventListener("touchstart", onInstallMouseOver);
  })
  initializeModalButtons()
}

const initializeModalButtons = () => {
  document.querySelectorAll('.modal__cancel').forEach((el) => {
    el.addEventListener('click', (e) => {
      const modal = el.closest('dialog');
      modal.close();
    })
  })
  document.querySelectorAll('.modal__accept').forEach((el) => {
    el.addEventListener('click', (e) => {
      const modal = el.closest('dialog');
      modal.close('continue');
    })
  })
}

onload(init);
