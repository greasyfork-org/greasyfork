import onload from '~/onload'

function hookUpAddLocalizedAdditionalInfo() {
  let button = document.getElementById("add-additional-info");
  if (!button) {
    return;
  }
  button.addEventListener("click", function(event) {
    // Get the next index to use
    let additionalInfos = document.querySelectorAll("textarea[name*='additional_info']");
    let lastAdditionalInfoNameParts = additionalInfos[additionalInfos.length - 1].id.split("-")
    let index = parseInt(lastAdditionalInfoNameParts[lastAdditionalInfoNameParts.length - 1], 10) + 1;

    let xhr = new XMLHttpRequest();
    xhr.overrideMimeType("text/html");
    xhr.open("get", buttonUrlWithIndex(button, index));
    xhr.onload = function() {
      let frag = document.createElement("div");
      frag.innerHTML = this.responseText;
      let elementToInsert = frag.firstElementChild;
      let container = button.parentNode.parentNode;
      container.insertBefore(elementToInsert, button.parentNode);
      // Make the preview button work
      markupPreview(elementToInsert.querySelector(".previewable"));
    };
    xhr.send();
    event.preventDefault();
  });
}

function hookUpAddSyncedLocalizedAdditionalInfo() {
  let button = document.getElementById("add-synced-additional-info");
  if (!button) {
    return;
  }
  button.addEventListener("click", function(event) {
    // Get the next index to use
    let additionalInfos = document.querySelectorAll("input[type='url'][name*='additional_info_sync']");
    let lastAdditionalInfoNameParts = additionalInfos[additionalInfos.length - 1].id.split("-")
    let index = parseInt(lastAdditionalInfoNameParts[lastAdditionalInfoNameParts.length - 1], 10) + 1;

    let xhr = new XMLHttpRequest();
    xhr.overrideMimeType("text/html");
    xhr.open("get", buttonUrlWithIndex(button, index));
    xhr.onload = function() {
      let frag = document.createElement("div");
      frag.innerHTML = this.responseText;
      button.parentNode.parentNode.insertBefore(frag.children[0], button.parentNode);
    };
    xhr.send();
    event.preventDefault();
  });
}

const buttonUrlWithIndex = function(button, index) {
  return `${button.dataset.formPath}${button.dataset.formPath.includes("?") ? "&" : "?"}index=${index}`
}

onload(hookUpAddLocalizedAdditionalInfo);
onload(hookUpAddSyncedLocalizedAdditionalInfo);
