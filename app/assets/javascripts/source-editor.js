window.addEventListener("DOMContentLoaded", function() {
  var enableRadio = document.querySelector('input.enable-source-editor');

  if (!enableRadio) {
    return;
  }

  var aceEditor = null;

  function handleChange(e) {
    var textboxId = e.target.getAttribute("data-related-editor");
    var textbox = document.getElementById(textboxId);
    var language = e.target.getAttribute("data-editor-language");
    if (e.target.checked) {
      textbox.style.display = "none";
      var div = document.createElement("div");
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
              "-W064": false
            }]);
          }
        }
      });
      aceEditor.getSession().setMode("ace/mode/" + language);
      /*$('#ace-editor').resizable({
        resize: function(event, ui) { aceEditor.resize(false); }
      });*/
    } else {
      var editorElement = document.getElementById("ace-editor");
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

  // Switching between editor and textarea
  enableRadio.addEventListener("change", handleChange);

  function getParentForm(element) {
    while (element && element.tagName.toLowerCase() != "form") {
      element = element.parentNode;
    }
    return element;
  }

  // Submitting form - set the textarea to the editor's value
  function handleSubmit(e) {
    var editorElement = document.getElementById("ace-editor");
    if (editorElement) {
      var textboxId = enableRadio.getAttribute("data-related-editor");
      var textbox = document.getElementById(textboxId);
      textbox.value = aceEditor.getSession().getValue();
    }
  }

  var parentForm = getParentForm(enableRadio);
  parentForm.addEventListener('submit', handleSubmit);
  // When there's a recaptcha the submit event doesn't happen.
  var recaptchaSubmit = parentForm.querySelector('.g-recaptcha');
  if (recaptchaSubmit) {
    recaptchaSubmit.addEventListener('click', handleSubmit);
  }

  // Page load
  
  // This is hidden for JS-off users.
  enableRadio.parentNode.style.display = "inline";
  handleChange({target: enableRadio});
});
