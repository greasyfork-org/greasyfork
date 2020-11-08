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
	}
	
	window.addEventListener("DOMContentLoaded", init);
})();
