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

	// on user input element:
	// class = previewable
	// data-markup-option-name = the name of the radio buttons for selecting markup
	// data-preview-activate-id = the id of the button to activate the preview
	// data-preview-result-id = the id of the div to place the results
	function hookUpMarkupPreview() {
		$(".previewable").each(function(index, previewable) {
			var previewable = $(this);
			var markupOptions = $('input:radio[name="' + previewable.attr("data-markup-option-name") + '"]');
			var result = $("#" + previewable.attr("data-preview-result-id"));

			var button = $("#" + previewable.attr("data-preview-activate-id"));
			button.show();
			button.click(function() {
				var selectedMarkup = $('input:radio[name="' + previewable.attr("data-markup-option-name") + '"]:checked').val();
				$.ajax({
					type: "POST",
					url: "/preview-markup",
					data: {
						text: previewable.val(),
						markup: selectedMarkup
					},
					success: function(data) {
						result.html(data);
						result.slideDown();
						// scroll to it if it's not at all visible
						if (result.offset().top > $(window).scrollTop() + $(window).height()) {
							$('html, body').animate({
								scrollTop: result.offset().top
							}, 2000);
						}
					},
					error: function(data) {
						alert(data);
						return false;
					}
				})
				return false;
			});

			// close when anything changed
			markupOptions.click(function() {
				result.slideUp();
			});
			previewable.bind('input', function() {
				result.slideUp();
			});
		});
	}

	function init() {
		hookUpSelectAllCheckboxes();
		hookUpInstallPingers();
		hookUpMarkupPreview();
	}
	
	window.addEventListener("DOMContentLoaded", init);
})();
