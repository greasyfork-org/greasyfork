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

function compareVersions(a, b) {
	if (a == b) {
		return 0;
	}
	var aParts = a.split('.');
	var bParts = b.split('.');
	for (var i = 0; i < aParts.length; i++) {
		if (typeof bParts[i] == "undefined") {
			// Something is more than nothing
			return 1;
		}
		if (aParts[i] > bParts[i]) {
			return 1;
		}
		if (aParts[i] < bParts[i]) {
			return -1;
		}
	}
	// At this point, all parts of A are equal to the corresponding part of B
	if (bParts.length > aParts.length) {
		return -1;
	}
	return 0;
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
