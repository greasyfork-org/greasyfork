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
    };
    xhr.send();
    event.preventDefault();
  });
}

window.addEventListener("DOMContentLoaded", hookUpAddLocalizedAdditionalInfo);
window.addEventListener("DOMContentLoaded", hookUpAddSyncedLocalizedAdditionalInfo);
