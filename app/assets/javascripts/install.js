(function() {
	function hookUpInstallPingers() {
		var installLink = document.querySelector(".install-link");
		if (!installLink) {
			return;
		}
		installLink.addEventListener("click", function(event) {
			if (installLink.getAttribute("data-is-previous-version") == "true") {
				if (!confirm("This is not the latest version of this script. If you install it, you will never be updated to a newer version. Install anyway?")) {
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
		postInstall.style.display = 'block';
	}

	function init() {
		hookUpInstallPingers();
	}

	window.addEventListener("DOMContentLoaded", init);
})();
