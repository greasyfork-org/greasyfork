import onload from '~/onload'

const updateLibraryControlsVisibility = () => {
  let scriptLibraryRadio = document.getElementById('script_script_type_3')
  if (!scriptLibraryRadio) {
    return
  }
  document.getElementById("script-library-inputs").hidden = !scriptLibraryRadio.checked
}

const setupLibraryControls = () => {
  updateLibraryControlsVisibility()
  document.querySelectorAll('input[name="script[script_type]"]').forEach((el) => el.addEventListener('change', updateLibraryControlsVisibility))
}

onload(setupLibraryControls)
