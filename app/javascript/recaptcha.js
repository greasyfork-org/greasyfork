window.submitInvisibleRecaptchaForm = function(event) {
  document.getElementById("new_user").submit();
};
window.submitInvisibleRecaptchaFormScriptVersion = function(event) {
  document.getElementById("new_script_version").submit();
};
window.submitInvisibleRecaptchaFormScriptSet = function(event) {
  document.getElementById("save-indicator").value = "1";
  document.getElementById("new_script_set").submit();
};
window.submitInvisibleRecaptchaDiscussionForm = function(event) {
  document.getElementById("new-discussion").submit();
};
window.submitInvisibleRecaptchaScriptDiscussionForm = function(event) {
  document.getElementById("new-script-discussion").submit();
}
