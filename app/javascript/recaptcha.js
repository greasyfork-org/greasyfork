var submitInvisibleRecaptchaForm = function(event) {
  document.getElementById("new_user").submit();
};
var submitInvisibleRecaptchaFormScriptVersion = function(event) {
  document.getElementById("new_script_version").submit();
};
var submitInvisibleRecaptchaFormScriptSet = function(event) {
  document.getElementById("save-indicator").value = "1";
  document.getElementById("new_script_set").submit();
};
var submitInvisibleRecaptchaDiscussionForm = function(event) {
  document.getElementById("new-discussion").submit();
};
var submitInvisibleRecaptchaScriptDiscussionForm = function(event) {
  document.getElementById("new-script-discussion").submit();
}
