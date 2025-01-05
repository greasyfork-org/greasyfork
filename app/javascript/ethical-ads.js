import onload from '~/onload'

function setupEthicalAdsFallback() {
  if (typeof window.ethicalads === "undefined") {
    setTimeout(setupEthicalAdsFallback, 100)
    return
  }
  window.ethicalads.wait.then((placements) => {
    if (typeof gtag !== 'undefined') {
      gtag('event', 'EthicalAds placement', {
        'ea_campaign_type': placements[0]?.response?.campaign_type || '(none)',
      });
    }

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

    if (placeholder.dataset['parentId']) {
      let createdParent = document.createElement('div')
      createdParent.id = placeholder.dataset['parentId']
      createdParent.appendChild(element)
      element = createdParent
    }

    parent.insertBefore(element, placeholder)
    parent.removeChild(placeholder)
    parent.style.display = "block"

    let ethicalAdsElement = document.querySelector(".ethical-ads")
    ethicalAdsElement.parentNode.removeChild(ethicalAdsElement)
  })
}

onload(setupEthicalAdsFallback)
