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
  if (localStorage.getItem('stylusDetected') == '1') {
    return true;
  }

  let messageListener;

  await new Promise(resolve => {
    messageListener = function(event) {
      if (event.origin !== location.origin)
        return;
  
      if (event.data.type != "style-version")
        return;
  
      localStorage.setItem('stylusDetected', '1')
  
      resolve();
    };
    window.addEventListener("message", messageListener, false);
    postMessage({ type: 'style-version-query', name: "whatever", namespace: "whatever", url: location.href }, location.origin);
    setTimeout(resolve, 200);
  });

  window.removeEventListener("message", messageListener, false);
  return localStorage.getItem('stylusDetected') == '1';
}
