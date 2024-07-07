function setupEthicalAdsFallback() {
  if (typeof window.ethicalads === "undefined") {
    setTimeout(setupEthicalAdsFallback, 100)
    return
  }
  window.ethicalads.wait.then((placements) => {
    if (placements.length > 0) {
      return
    }

    let placeholder = document.querySelector(".ea-fallback")
    if (!placeholder) {
      return
    }
    placeholder.classList.remove('ea-fallback')

    let element = document.createElement(placeholder.getAttribute('data-element-name'))
    placeholder.removeAttribute('data-element-name')

    Array.from(placeholder.attributes).forEach((attr) => element.setAttributeNode(attr.cloneNode(true)))

    let parent = placeholder.parentNode
    parent.removeChild(placeholder)
    parent.appendChild(element)
    parent.style.display = "block"

    let ethicalAdsElement = document.querySelector(".ethical-ads")
    ethicalAdsElement.parentNode.removeChild(ethicalAdsElement)
  })
}

window.addEventListener("DOMContentLoaded", setupEthicalAdsFallback)
