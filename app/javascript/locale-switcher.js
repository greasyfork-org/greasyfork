import onload from '~/onload'

let switchLocale = function(event) {
  let selectedOption = event.target.selectedOptions[0];
  if (selectedOption.value == "help") {
    location.href = event.target.getAttribute("data-translate-url");
  } else {
    location.href = selectedOption.getAttribute("data-language-url");
  }
}

onload(() => { document.querySelectorAll(".language-selector-locale").forEach((lsl) => { lsl.addEventListener("change", switchLocale) }) });
