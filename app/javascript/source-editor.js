let aceEditor = null;

window.addEventListener("DOMContentLoaded", async () => {
  let enableRadio = document.querySelector('input.enable-source-editor');

  if (!enableRadio) {
    return;
  }

  // Switching between editor and textarea
  enableRadio.addEventListener("change", handleChange);

  let parentForm = getParentForm(enableRadio);
  parentForm.addEventListener('submit', handleSubmit);
  // When there's a recaptcha the submit event doesn't happen.
  let recaptchaSubmit = parentForm.querySelector('.g-recaptcha');
  if (recaptchaSubmit) {
    recaptchaSubmit.addEventListener('click', handleSubmit);
  }

  // Page load
  
  // This is hidden for JS-off users.
  enableRadio.parentNode.style.display = "inline";
  handleChange({target: enableRadio});
});

function getParentForm(element) {
  while (element && element.tagName.toLowerCase() !== "form") {
    element = element.parentNode;
  }
  return element;
}

async function handleChange(e) {
  let textboxId = e.target.getAttribute("data-related-editor");
  let textbox = document.getElementById(textboxId);
  let language = e.target.getAttribute("data-editor-language");
  if (e.target.checked) {
    let ace = await import('ace-builds')
    textbox.style.display = "none";
    let div = document.createElement("div");
    div.id = "ace-editor";
    div.appendChild(document.createTextNode(textbox.value));
    div.style.height = getComputedStyle(textbox).height;
    textbox.parentNode.insertBefore(div, textbox.nextSibling);
    aceEditor = ace.edit("ace-editor");
    // Disable the "Missing 'new' prefix when invoking a constructor." warning - this gets triggered for GM_ functions.
    aceEditor.session.on('changeMode', function(e, session){
      if ("ace/mode/javascript" === session.getMode().$id) {
        if (!!session.$worker) {
          session.$worker.send("setOptions", [{
            'esversion': 6,
            "-W064": false
          }]);
        }
      }
    });
    if (language === 'css') {
      await import('ace-builds/src-noconflict/mode-css')
      let cssWorkerUrl = await import("ace-builds/src-noconflict/worker-css?url");
      ace.config.setModuleUrl('ace/mode/css_worker', cssWorkerUrl.default)
      aceEditor.getSession().setMode("ace/mode/css");
    } else {
      await import('ace-builds/src-noconflict/mode-javascript')
      let jsWorkerUrl = await import("ace-builds/src-noconflict/worker-javascript?url");
      ace.config.setModuleUrl('ace/mode/javascript_worker', jsWorkerUrl.default)
      aceEditor.getSession().setMode("ace/mode/javascript");
    }
    /*$('#ace-editor').resizable({
      resize: function(event, ui) { aceEditor.resize(false); }
    });*/
  } else {
    let editorElement = document.getElementById("ace-editor");
    if (editorElement) {
      textbox.value = aceEditor.getSession().getValue();
      textbox.style.display = "block";
      textbox.style.height = getComputedStyle(editorElement).height;
      editorElement.parentNode.removeChild(editorElement);
      aceEditor.destroy();
      aceEditor = null;
    }
  }
}

// Submitting form - set the textarea to the editor's value
function handleSubmit() {
  let editorElement = document.getElementById("ace-editor");
  if (editorElement) {
    let textboxId = document.querySelector('input.enable-source-editor').getAttribute("data-related-editor");
    let textbox = document.getElementById(textboxId);
    textbox.value = aceEditor.getSession().getValue();
  }
}
