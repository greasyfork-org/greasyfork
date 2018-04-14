(function() {
	function hookUpInstallPingers() {
		var installLink = document.querySelector(".install-link");
		if (!installLink) {
			return;
		}
		installLink.addEventListener("click", function(event) {
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

			setTimeout(showPostInstall, 2000);
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
