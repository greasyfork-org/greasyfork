import onload from '~/onload'

onload(() => {
  let wrapLines = document.getElementById("wrap-lines")
  if (!wrapLines) {
    return
  }

  wrapLines.addEventListener('change', (event) => changeWrap(event.target))
  changeWrap(wrapLines)
})

const changeWrap = (checkbox) => {
  let prettyPrint = document.querySelector('.code-container .prettyprint')
  if (!prettyPrint) {
    return
  }
  let wrap = checkbox.checked
  prettyPrint.classList.toggle('wrap', wrap)
}