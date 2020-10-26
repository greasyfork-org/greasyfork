(function() {

	function hookUpSelectAllCheckboxes() {
		function updateAllCheckboxSelection(selection) {
			var checkboxes = document.querySelectorAll("input[type='checkbox']");
			for (var i = 0; i < checkboxes.length; i++) {
				checkboxes[i].checked = selection;
			}
		}
		var selectAll = document.querySelector(".select-all");
		if (selectAll) {
			selectAll.addEventListener("click", function(event) { updateAllCheckboxSelection(true); event.preventDefault();});
			selectAll.style.display = "inline";
		}
		var selectNone = document.querySelector(".select-none");
		if (selectNone) {
			selectNone.addEventListener("click", function(event) { updateAllCheckboxSelection(false); event.preventDefault();});
			selectNone.style.display = "inline";
		}
	}

	function hookUpAddLocalizedAdditionalInfo() {
		var button = document.getElementById("add-additional-info");
		if (!button) {
			return;
		}
		button.addEventListener("click", function(event) {
			// Get the next index to use
			var additionalInfos = document.querySelectorAll("textarea[name*='additional_info']");
			var lastAdditionalInfoNameParts = additionalInfos[additionalInfos.length - 1].id.split("-")
			var index = parseInt(lastAdditionalInfoNameParts[lastAdditionalInfoNameParts.length - 1], 10) + 1;

			var xhr = new XMLHttpRequest();
			xhr.overrideMimeType("text/html");
			xhr.open("get", button.getAttribute("data-form-path") + "?index=" + index);
			xhr.onload = function() {
				var frag = document.createElement("div");
				frag.innerHTML = this.responseText;
				var elementToInsert = frag.firstChild;
				var container = button.parentNode.parentNode;
				container.insertBefore(elementToInsert, button.parentNode);
				// Make the preview button work
				markupPreview(elementToInsert.querySelector(".previewable"));
			};
			xhr.send();
			event.preventDefault();
		});
	}

	function hookUpAddSyncedLocalizedAdditionalInfo() {
		var button = document.getElementById("add-synced-additional-info");
		if (!button) {
			return;
		}
		button.addEventListener("click", function(event) {
			// Get the next index to use
			var additionalInfos = document.querySelectorAll("input[type='url'][name*='additional_info_sync']");
			var lastAdditionalInfoNameParts = additionalInfos[additionalInfos.length - 1].id.split("-")
			var index = parseInt(lastAdditionalInfoNameParts[lastAdditionalInfoNameParts.length - 1], 10) + 1;

			var xhr = new XMLHttpRequest();
			xhr.overrideMimeType("text/html");
			xhr.open("get", button.getAttribute("data-form-path") + "?index=" + index);
			xhr.onload = function() {
				var frag = document.createElement("div");
				frag.innerHTML = this.responseText;
				button.parentNode.parentNode.insertBefore(frag.children[0], button.parentNode);
				// Make the preview button work
				hookUpMarkupPreview();
			};
			xhr.send();
			event.preventDefault();
		});
	}

	function hookUpLocaleSwitcher() {
		document.getElementById("language-selector-locale").addEventListener("change", function(event) {
			var selectedOption = event.target.selectedOptions[0];
			if (selectedOption.value == "help") {
				location.href = event.target.getAttribute("data-translate-url");
			} else {
				location.href = selectedOption.getAttribute("data-language-url");
			}
		});
	}

	function init() {
		hookUpSelectAllCheckboxes();
		hookUpLocaleSwitcher();
		hookUpAddLocalizedAdditionalInfo();
		hookUpAddSyncedLocalizedAdditionalInfo();
	}
	
	window.addEventListener("DOMContentLoaded", init);
})();
