import onload from '~/onload'

onload(() => {
  const opener = document.querySelector('.mobile-nav-opener')
  const menu = document.querySelector('#mobile-nav nav')
  if (!opener || !menu) {
    return
  }

  if (!menu.id) {
    menu.id = 'mobile-nav-menu'
  }

  const siteLabel = document.querySelector('#site-name-text h1')?.textContent.trim()
  opener.setAttribute('role', 'button')
  opener.setAttribute('tabindex', '0')
  opener.setAttribute('aria-controls', menu.id)
  opener.setAttribute('aria-expanded', 'false')
  if (siteLabel) {
    opener.setAttribute('aria-label', siteLabel)
  }

  const setExpanded = (expanded) => {
    menu.classList.toggle('collapsed', !expanded)
    opener.setAttribute('aria-expanded', expanded.toString())
  }

  const toggle = () => setExpanded(opener.getAttribute('aria-expanded') !== 'true')
  opener.addEventListener('click', toggle)
  opener.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && opener.getAttribute('aria-expanded') === 'true') {
      event.preventDefault()
      setExpanded(false)
      return
    }
    if (event.key !== 'Enter' && event.key !== ' ') {
      return
    }
    event.preventDefault()
    toggle()
  })
  menu.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') {
      return
    }
    event.preventDefault()
    setExpanded(false)
    opener.focus()
  })
})
