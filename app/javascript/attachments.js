import highlight from './highlight'

function handlePaste(e) {
  let fileInput = this.closest("form").querySelector("input[type=file][name*=attachments]")
  if (!fileInput) {
    return;
  }
  let accept = fileInput.getAttribute("accept").split(",")
  let uploadableFiles = Array.from(e.clipboardData.files).filter(f => accept.includes(f.type))
  if (uploadableFiles.length == 0) {
    return;
  }
  let list = new DataTransfer();
  for (let file of fileInput.files) {
    list.items.add(file);
  }
  for (let file of uploadableFiles) {
    list.items.add(file);
  }
  fileInput.files = list.files;
  highlight(fileInput)
}

function init() {
  for (let textarea of document.querySelectorAll(".previewable textarea")) {
    textarea.addEventListener("paste", handlePaste);
  }
}

window.addEventListener("DOMContentLoaded", init);
