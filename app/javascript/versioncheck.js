import {getTampermonkey, getViolentmonkey} from "./managers";

function getInstalledVersion(name, namespace) {
  return new Promise(function(resolve, reject) {
    let tm = getTampermonkey()
    if (tm) {
      tm.isInstalled(name, namespace, function (i) {
        if (i.installed) {
          resolve(i.version);
        } else {
          resolve(null);
        }
      });
      return;
    }

    let vm = getViolentmonkey();
    if (vm) {
      vm.isInstalled(name, namespace).then(resolve);
      return;
    };

    reject()
  });
}

// https://developer.mozilla.org/en/docs/Toolkit_version_format
function compareVersions(a, b) {
  if (a == b) {
    return 0;
  }
  let aParts = a.split('.');
  let bParts = b.split('.');
  for (let i = 0; i < aParts.length; i++) {
    let result = compareVersionPart(aParts[i], bParts[i]);
    if (result != 0) {
      return result;
    }
  }
  return 0;
}

function compareVersionPart(partA, partB) {
  let partAParts = parseVersionPart(partA);
  let partBParts = parseVersionPart(partB);
  for (let i = 0; i < partAParts.length; i++) {
    // "A string-part that exists is always less than a string-part that doesn't exist"
    if (partAParts[i].length > 0 && partBParts[i].length == 0) {
      return -1;
    }
    if (partAParts[i].length == 0 && partBParts[i].length > 0) {
      return 1;
    }
    if (partAParts[i] > partBParts[i]) {
      return 1;
    }
    if (partAParts[i] < partBParts[i]) {
      return -1;
    }
  }
  return 0;
}

// It goes number, string, number, string. If it doesn't exist, then
// 0 for numbers, empty string for strings.
function parseVersionPart(part) {
  if (!part) {
    return [0, "", 0, ""];
  }
  let partParts = /([0-9]*)([^0-9]*)([0-9]*)([^0-9]*)/.exec(part)
  return [
    partParts[1] ? parseInt(partParts[1]) : 0,
    partParts[2],
    partParts[3] ? parseInt(partParts[3]) : 0,
    partParts[4]
  ];
}

function handleInstallResult(installButton, installedVersion, version) {
  if (installedVersion == null) {
    // Not installed, do nothing
    return;
  }

  installButton.removeAttribute("data-ping-url")

  switch (compareVersions(installedVersion, version)) {
    // Upgrade
    case -1:
      installButton.textContent = installButton.getAttribute("data-update-label");
      break;
    // Downgrade
    case 1:
      installButton.textContent = installButton.getAttribute("data-downgrade-label");
      break;
    // Equal
    case 0:
      installButton.textContent = installButton.getAttribute("data-reinstall-label");
      break;
  }

}

function checkForUpdatesJS(installButton, retry) {
  let name = installButton.getAttribute("data-script-name");
  let namespace = installButton.getAttribute("data-script-namespace");
  let version = installButton.getAttribute("data-script-version");

  getInstalledVersion(name, namespace).then(function(installedVersion) {
    handleInstallResult(installButton, installedVersion, version);
  }, function() {
    if (retry) {
      setTimeout(function() { checkForUpdatesJS(installButton, false) }, 1000);
    }
  }).catch(function(error) {
    // Could not determine the installed version, assume it's not
    // installed and do nothing.
  });
}

function checkForUpdatesCSS(installButton) {
  let name = installButton.getAttribute("data-script-name");
  let namespace = installButton.getAttribute("data-script-namespace");
  postMessage({ type: 'style-version-query', name: name, namespace: namespace, url: location.href }, location.origin);
}

// Response from Stylus
window.addEventListener("message", function(event) {
  if (event.origin !== "https://greasyfork.org" && event.origin !== "https://sleazyfork.org")
    return;

  if (event.data.type != "style-version")
    return;

  let installButton = document.querySelector(".install-link[data-install-format=css]");
  if (installButton == null)
    return;

  let version = installButton.getAttribute("data-script-version");

  let installedVersion = event.data.version;

  handleInstallResult(installButton, installedVersion, version);
}, false);

document.addEventListener("DOMContentLoaded", function() {
  let installButtonJS = document.querySelector(".install-link[data-install-format=js]");
  if (installButtonJS) {
    checkForUpdatesJS(installButtonJS, true);
  }
  let installButtonCSS = document.querySelector(".install-link[data-install-format=css]");
  if (installButtonCSS) {
    checkForUpdatesCSS(installButtonCSS);
  }
});
