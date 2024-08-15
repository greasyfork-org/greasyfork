import onload from '~/onload'

function makeExpandable(expandable) {
  // Use a multiple of line height to prevent partially displayed lines
  let height = parseInt(getComputedStyle(expandable).height)
  let lineHeight = 18 // This depends on waiting for the font to load - expandable.firstElementChild.getBoundingClientRect().height

  let lines = 4
  let maxAllowedHeight = lineHeight * lines
  if (height <= maxAllowedHeight) {
    return
  }

  expandable.parentNode.style.position = "relative"
  expandable.style.height = maxAllowedHeight + "px"

  let rtl = getComputedStyle(document.documentElement).direction == 'rtl'
  let narrowMode = document.documentElement.clientWidth <= 600

  function toggle() {
    if (expandable.classList.contains('expanded')) {
      if (narrowMode) {
        expandable.style.height = maxAllowedHeight + "px"
      } else {
        expandable.style.marginInlineEnd = ""
        span.style.marginInlineEnd = ""
      }
      span.removeChild(span.firstChild)
      span.appendChild(document.createTextNode("+"))
      expandable.classList.remove('expanded')
      expandable.classList.add('collapsed')
    } else {
      if (narrowMode) {
        expandable.style.height = "auto"
      } else {
        let widthConstraint = document.querySelector('.width-constraint')
        let availableWidth = rtl ? (widthConstraint.getBoundingClientRect().left - expandable.getBoundingClientRect().left + 40) : (widthConstraint.getBoundingClientRect().right - expandable.getBoundingClientRect().right - 40)

        expandable.style.marginInlineEnd = "-" + availableWidth + "px"
        span.style.marginInlineEnd = "-" + availableWidth + "px"
      }
      span.removeChild(span.firstChild)
      span.appendChild(document.createTextNode("-"))
      expandable.classList.add('expanded')
      expandable.classList.remove('collapsed')
    }
  }

  let span = document.createElement("span")
  span.className = "expander"
  span.appendChild(document.createTextNode("+"))
  span.addEventListener("click", toggle)
  expandable.insertAdjacentElement('afterend', span)
  expandable.classList.add('expanded')
  toggle()
}

onload(() => { document.querySelectorAll('.expandable').forEach(makeExpandable) })
