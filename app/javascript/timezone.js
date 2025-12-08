import onload from '~/onload'

const setHiddenTimeZoneInputs = function() {
  let timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone
  let inputs = document.querySelectorAll("input[name='tz']")
  inputs.forEach((input) => input.value ||= timeZone)
}

onload(setHiddenTimeZoneInputs);