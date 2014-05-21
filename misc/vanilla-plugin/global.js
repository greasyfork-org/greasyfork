// Change signout link to main site signout
$(document).ready(function() {
	var signoutLink = $('#Menu .SignOut a');
	signoutLink.attr('href', '/users/sign_out');
});
