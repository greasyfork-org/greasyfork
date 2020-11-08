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

window.addEventListener("DOMContentLoaded", hookUpLocaleSwitcher);
