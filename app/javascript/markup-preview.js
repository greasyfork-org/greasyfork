import onload from '~/onload'

/*
 *  <div class="previewable" data-markup-option-name="name-of-html-markdown-radios">
 *    <textarea></textarea>
 *  </div>
 */
window.markupPreview = function(p) {
  function getPreviewable(element) {
    while (element && element.className.indexOf("previewable") === -1) {
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
    return previewable.querySelector(".preview-tab").parentNode.className.indexOf("current") > -1;
  }

  function handlePreviewClick(event) {
    let previewable = getPreviewable(event.target);
    if (isOnPreviewTab(previewable)) {
      return;
    }
    updateContent(previewable);
    event.preventDefault();
  }

  function updateContent(previewable) {
    let selectedMarkup = previewable.closest("form").querySelector('input[name="' + previewable.getAttribute("data-markup-option-name") + '"]:checked').value;
    let url = previewable.getAttribute("data-preview-source") === "url";

    let xhr = new XMLHttpRequest();
    xhr.onload = function() {
      displayResult(previewable, xhr.responseText);
    }
    xhr.onerror = function() {
      displayResult(previewable, xhr.status);
    }
    xhr.open("POST", "/preview-markup");
    let params = new FormData();
    params.append("text", getTextElement(previewable).value);
    params.append("markup", selectedMarkup);
    params.append("url", String(url));
    params.append(document.querySelector("meta[name='csrf-param']").getAttribute("content"), document.querySelector("meta[name='csrf-token']").getAttribute("content"))
    xhr.send(params);
  }

  function displayResult(previewable, text) {
    let textElement = getTextElement(previewable);
    let resultElement = getResultElement(previewable);
    resultElement.innerHTML = text;
    // Need both not display: none to be able to their heights
    resultElement.style.display = "block";
    textElement.style.display = 'block'
    resultElement.style.height = "auto"
    resultElement.style.height = Math.max(textElement.clientHeight + getBorderHeight(textElement), resultElement.scrollHeight + getBorderHeight(resultElement)) + "px";
    if (textElement.style.display !== "none") {
      textElement.style.display = "none";
      updateTabUI(previewable, true);
    }
  }

  function getBorderHeight(el) {
    let computedStyle = getComputedStyle(el)
    return parseInt(computedStyle.borderTopWidth) + parseInt(computedStyle.borderBottomWidth)
  }

  function handleWriteClick(event) {
    let previewable = getPreviewable(event.target);
    let textElement = getTextElement(previewable);
    let resultElement = getResultElement(previewable);
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
    let tabToHide = previewable.querySelector(previewTab ? ".write-tab" : ".preview-tab");
    tabToHide.parentNode.classList.remove("current");
  }

  let tabs = document.createElement("div");
  tabs.className = "tabs";
  tabs.innerHTML = "<span class='current'><a class='write-tab'><span>" + p.getAttribute("data-write-label") + "</span></a></span> <span><a class='preview-tab'><span>" + p.getAttribute("data-preview-label") + "</span></a></span>";
  p.insertBefore(tabs, p.firstChild);

  let results = document.createElement("div");
  results.className = "preview-results user-content";
  results.style.display = "none";
  p.appendChild(results);

  p.querySelector(".preview-tab").addEventListener("click", handlePreviewClick);
  p.querySelector(".write-tab").addEventListener("click", handleWriteClick);

  Array.prototype.forEach.call(document.querySelectorAll('input[name="' + p.getAttribute("data-markup-option-name") + '"]'), function(markupOption) {
    markupOption.addEventListener("change", function() { handleMarkupChange(p) });
  });
}

onload(() => Array.prototype.forEach.call(document.querySelectorAll(".previewable"), markupPreview))