/*
 *  <div class="previewable" data-markup-option-name="name-of-html-markdown-radios">
 *    <textarea></textarea>
 *  </div>
 */
window.markupPreview = function(p) {
  function getMarkupOptions(previewable) {
    return document.querySelectorAll('input[type=radio][name="' + previewable.getAttribute("data-markup-option-name") + '"]');
  }

  function getPreviewable(element) {
    while (element && element.className.indexOf("previewable") == -1) {
      element = element.parentNode;
    }
    return element;
  }

  function getTextElement(previewable) {
    return previewable.querySelector("textarea");
  }

  function getResultElement(previewable) {
    return previewable.querySelector(".preview-results");
  }

  function isOnPreviewTab(previewable) {
    return previewable.querySelector(".preview-tab").className.indexOf("current") > -1;
  }

  function handlePreviewClick(event) {
    var previewable = getPreviewable(event.target);
    if (isOnPreviewTab(previewable)) {
      return;
    }
    updateContent(previewable);
    event.preventDefault();
  }

  function updateContent(previewable) {
    var markupOptions = getMarkupOptions(previewable);
    var selectedMarkup = previewable.closest("form").querySelector('input[name="' + previewable.getAttribute("data-markup-option-name") + '"]:checked').value;
    var url = previewable.getAttribute("data-preview-source") == "url";

    var xhr = new XMLHttpRequest();
    xhr.onload = function() {
      displayResult(previewable, xhr.responseText);
    }
    xhr.onerror = function() {
      displayResult(previewable, xhr.status);
    }
    xhr.open("POST", "/preview-markup");
    var params = new FormData();
    params.append("text", getTextElement(previewable).value);
    params.append("markup", selectedMarkup);
    params.append("url", url);
    params.append(document.querySelector("meta[name='csrf-param']").getAttribute("content"), document.querySelector("meta[name='csrf-token']").getAttribute("content"))
    xhr.send(params);
  }

  function displayResult(previewable, text) {
    var textElement = getTextElement(previewable);
    var resultElement = getResultElement(previewable);
    resultElement.innerHTML = text;
    if (textElement.style.display != "none") {
      resultElement.style.height = textElement.clientHeight + "px";
      resultElement.style.display = "block";
      textElement.style.display = "none";
      updateTabUI(previewable, true);
    }
  }

  function handleWriteClick(event) {
    var previewable = getPreviewable(event.target);
    var textElement = getTextElement(previewable);
    var resultElement = getResultElement(previewable);
    resultElement.style.display = "none";
    textElement.style.display = "block";
    updateTabUI(previewable, false);
  }

  function handleMarkupChange(previewable) {
    if (isOnPreviewTab(previewable)) {
      updateContent(previewable);
    }
  }

  function updateTabUI(previewable, previewTab) {
    previewable.querySelector(previewTab ? ".preview-tab" : ".write-tab").parentNode.classList.add("current");
    var tabToHide = previewable.querySelector(previewTab ? ".write-tab" : ".preview-tab");
    tabToHide.parentNode.classList.remove("current");
  }

  var tabs = document.createElement("div");
  tabs.className = "tabs";
  tabs.innerHTML = "<span class='current'><a class='write-tab'><span>" + p.getAttribute("data-write-label") + "</span></a></span> <span><a class='preview-tab'><span>" + p.getAttribute("data-preview-label") + "</span></a></span>";
  p.insertBefore(tabs, p.firstChild);

  var results = document.createElement("div");
  results.className = "preview-results user-content";
  results.style.display = "none";
  p.appendChild(results);

  p.querySelector(".preview-tab").addEventListener("click", handlePreviewClick);
  p.querySelector(".write-tab").addEventListener("click", handleWriteClick);

  Array.prototype.forEach.call(document.querySelectorAll('input[name="' + p.getAttribute("data-markup-option-name") + '"]'), function(markupOption) {
    markupOption.addEventListener("change", function() { handleMarkupChange(p) });
  });
}

window.addEventListener("DOMContentLoaded", function() {
  Array.prototype.forEach.call(document.querySelectorAll(".previewable"), markupPreview);
});
