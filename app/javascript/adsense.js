const waitForAdsenseLoad = (adsensePlacements) => {  
  return new Promise((resolve) => {
    const checkCondition = () => adsensePlacements.every(placement => placement.dataset['adsbygoogleStatus'] === 'done' && typeof placement.dataset['adStatus'] !== 'undefined')
    if (checkCondition()) {
      resolve(true)
      return
    }
    const checkInterval = setInterval(() => {
      if (checkCondition()) {
        clearInterval(checkInterval)
        resolve(true)
      }
    }, 100)
  })
}

export const allAdsenseUnfilled = () => {
  return new Promise(async (resolve) => {
    let adsensePlacements = Array.from(document.querySelectorAll('.adsbygoogle'))
    if (adsensePlacements.length == 0) {
      resolve(false)
      return
    }

    await waitForAdsenseLoad(adsensePlacements)

    console.log(adsensePlacements.map(placement => `Placement ID ${placement.id || '(no id)'} status: ${placement.dataset['adStatus']} dataset: ${JSON.stringify(placement.dataset)}`).join('\n'))
    resolve(adsensePlacements.every(placement => placement.dataset['adStatus'] === 'unfilled'))
  })
}
