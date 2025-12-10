import onload from '~/onload'
import { allAdsenseUnfilled } from '~/adsense'

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

    if (placements.length == 0) {
      switchToEaFallback()
    }
  })
}

const switchToEaFallback = function() {
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
}
window.switchToEaFallback = switchToEaFallback

const fallbackAdsenseToEa = async () => {
  let unfilled = await allAdsenseUnfilled()
  if (!unfilled) {
    console.log("At least one AdSense ad was filled; not falling back to EthicalAds.")
    return
  }

  console.log("All AdSense ads were unfilled; falling back to EthicalAds.")
  let script = document.createElement('script')
  script.onload = function () {
    ethicalads.load()
  }
  script.src = 'https://media.ethicalads.io/media/client/ethicalads.min.js'
  document.head.appendChild(script)

  document.querySelector('[data-ea-manual="true"]').closest('.ad-ea').style.display = "block"
  document.querySelectorAll('.adsbygoogle').forEach((adSenseAd) => { adSenseAd.remove() })
}

const fallbackAdsenseToEaIfAvailable = () => {
  if (document.querySelector('[data-ea-manual="true"]')) {
    fallbackAdsenseToEa()
  }
}

onload(setupEthicalAdsFallback)
onload(fallbackAdsenseToEaIfAvailable)