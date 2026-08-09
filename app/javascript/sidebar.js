import onload from '~/onload'

function addKeyboardActivation(element, action) {
  element.addEventListener('keydown', (event) => {
    if (event.key !== 'Enter' && event.key !== ' ') {
      return
    }
    event.preventDefault()
    action()
  })
}

onload(() => {
  const sidebar = document.querySelector('.sidebar')
  const openButton = document.querySelector('.open-sidebar')
  const closeButton = document.querySelector('.close-sidebar')
  if (!sidebar || !openButton || !closeButton) {
    return
  }

  if (!sidebar.id) {
    sidebar.id = 'listing-options-sidebar'
  }

  const label = closeButton.querySelector('.sidebar-title')?.textContent.trim()
  for (const control of [openButton, closeButton]) {
    control.setAttribute('role', 'button')
    control.setAttribute('tabindex', '0')
    control.setAttribute('aria-controls', sidebar.id)
    control.setAttribute('aria-expanded', 'false')
    if (label && !control.hasAttribute('aria-label')) {
      control.setAttribute('aria-label', label)
    }
  }

  const setExpanded = (expanded) => {
    sidebar.classList.toggle('collapsed', !expanded)
    openButton.classList.toggle('sidebar-collapsed', !expanded)
    openButton.setAttribute('aria-expanded', expanded.toString())
    closeButton.setAttribute('aria-expanded', expanded.toString())
    if (expanded) {
      closeButton.focus()
    } else {
      openButton.focus()
    }
  }

  const openSidebar = () => setExpanded(true)
  const closeSidebar = () => setExpanded(false)

  openButton.addEventListener('click', openSidebar)
  closeButton.addEventListener('click', closeSidebar)
  addKeyboardActivation(openButton, openSidebar)
  addKeyboardActivation(closeButton, closeSidebar)
  sidebar.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') {
      return
    }
    event.preventDefault()
    closeSidebar()
  })
})
