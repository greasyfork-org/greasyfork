let allowedHosts = document.documentElement.dataset.allowedHosts
if (allowedHosts) {
  if (!allowedHosts.split(' ').find(host => host == location.hostname)) {
    location.href = 'https://greasyfork.org' + location.pathname + location.search
  }
}
