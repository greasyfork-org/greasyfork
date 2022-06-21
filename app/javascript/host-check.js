let allowedHosts = document.documentElement.dataset.allowedHosts
if (allowedHosts) {
  if (!allowedHosts.split(' ').find(host => host == location.host)) {
    location.href = 'https://greasyfork.org' + location.pathname + location.search
  }
}