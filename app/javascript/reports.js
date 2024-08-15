import onload from '~/onload'

onload(() => {
  const buttons = document.querySelectorAll(".lazy-load-diff");
  buttons.forEach((button) => {
    button.addEventListener("click", (e) => {
      button.disabled = true
      button.dataset.originalText = button.textContent
      button.textContent = button.dataset.disableWith
      fetch(button.dataset.url).then((response) => replaceDiff(button, response))
    })
  })
})

async function replaceDiff(button, response) {
  let diffSection = button.closest('.report-diff')
  let html = await response.text()
  let doc = new DOMParser().parseFromString(html, "text/html")
  diffSection.replaceChild(doc.body.firstElementChild, diffSection.firstChild)
  button.textContent = button.dataset.originalText
  button.disabled = false
}
