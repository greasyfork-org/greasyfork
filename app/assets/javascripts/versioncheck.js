function getTampermonkey() {
	return new Promise(function(resolve, reject) {
		if (!window.external) {
			reject('Tampermonkey is not installed.');
			return;
		}
		if (window.external.Tampermonkey) {
			resolve(window.external.Tampermonkey);
			return;
		}
		window.setTimeout(function() {
			if (window.external.Tampermonkey) {
				resolve(window.external.Tampermonkey);
				return;
			}
			reject('Tampermonkey is not installed.');
		}, 1000);
	});
}

function getInstalledVersion(name, namespace) {
	return new Promise(function(resolve, reject) {
		getTampermonkey().then(function(tm) {
			tm.isInstalled(name, namespace, function(i) {
				if (i.installed) {
					resolve(i.version);
				} else {
					resolve(null);
				}
			});
		}, reject);
	});
}

// https://developer.mozilla.org/en/docs/Toolkit_version_format
function compareVersions(a, b) {
	if (a == b) {
		return 0;
	}
	var aParts = a.split('.');
	var bParts = b.split('.');
	for (var i = 0; i < aParts.length; i++) {
		var result = compareVersionPart(aParts[i], bParts[i]);
		if (result != 0) {
			return result;
		}
	}
	return 0;
}

function compareVersionPart(partA, partB) {
	var partAParts = parseVersionPart(partA);
	var partBParts = parseVersionPart(partB);
	for (var i = 0; i < partAParts.length; i++) {
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
	var partParts = /([0-9]*)([^0-9]*)([0-9]*)([^0-9]*)/.exec(part)
	return [
		partParts[1] ? parseInt(partParts[1]) : 0,
		partParts[2],
		partParts[3] ? parseInt(partParts[3]) : 0,
		partParts[4]
	];
}

function checkForUpdates(installButton) {
	var name = installButton.getAttribute("data-script-name");
	var namespace = installButton.getAttribute("data-script-namespace");
	var version = installButton.getAttribute("data-script-version");

	getInstalledVersion(name, namespace).then(function(installedVersion) {
		if (installedVersion == null) {
			// Not installed, do nothing
			return;
		}
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
	}).catch(function(error) {
		// Could not determine the installed version, assume it's not
		// installed and do nothing.
	});
}

document.addEventListener("DOMContentLoaded", function() {
	var installButton = document.querySelector(".install-link");
	if (!installButton) {
		return;
	}
	checkForUpdates(installButton);
});
