// https://github.com/vanilla/addons/issues/93
// Change signout link to main site signout
$(document).ready(function() {
	var signoutLink = $('.SignOutWrap a');
	signoutLink.attr('href', '/users/sign_out');
});
