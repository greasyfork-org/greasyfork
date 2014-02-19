// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

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

	function hookUpInstallPingers() {
		var installLink = document.querySelector(".install-link");
		if (!installLink) {
			return;
		}
		installLink.addEventListener("click", function(event) {
			var xhr = new XMLHttpRequest();
			xhr.open("POST", event.target.getAttribute("data-ping-url"), false);
			xhr.send();
		});
	}

	function init() {
		hookUpSelectAllCheckboxes();
		hookUpInstallPingers();
	}
	
	window.addEventListener("DOMContentLoaded", init);
})();
