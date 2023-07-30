export function getTampermonkey() {
  return window.external?.Tampermonkey
}

export function getViolentmonkey() {
  return window.external?.Violentmonkey
}

export function canInstallUserJS() {
  return getTampermonkey() || getViolentmonkey()
}

export async function canInstallUserCSS() {
  if (localStorage.getItem('stylusDetected') === '1') {
    return true;
  }
  await new Promise(resolve => {
    window.stylusDetectedResolve = resolve;
    postMessage({ type: 'style-version-query', name: "whatever", namespace: "whatever", url: location.href }, location.origin);
    setTimeout(resolve, 200);
  });
  window.stylusDetectedResolve = null;
  return localStorage.getItem('stylusDetected') === '1';
}

window.addEventListener("message", function (event) {
  if (event.origin !== location.origin)
    return;

  if (event.data.type === "style-version") {
    localStorage.setItem('stylusDetected', '1');
    if (window.stylusDetectedResolve) window.stylusDetectedResolve();
  }

})
