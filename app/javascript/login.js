import onload from "~/onload";

// For some reason, the CSRF token generated in the form doesn't work. Maybe something to do with rendering through
// devise?
onload(() => {
  let form_csrf = document.querySelector('.external-login-form [name="authenticity_token"]')
  if (!form_csrf) {
    return
  }
  form_csrf.value = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
})
