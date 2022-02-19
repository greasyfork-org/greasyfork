const { detect } = require('detect-browser');

function init() {
  if (!document.querySelector(".browser-list")) {
    return
  }

  let listToShow
  switch (detect().os) {
    case 'Android OS':
      listToShow = 'android-browser-list'
      break
    case 'iOS':
      listToShow = 'ios-browser-list'
      break
    default:
      listToShow = 'desktop-browser-list'
  }
  switchList(listToShow)

  document.querySelectorAll("[data-for]").forEach((el) => el.addEventListener('click', () => { switchList(el.getAttribute('data-for')) }))
}

function switchList(listId) {
  let browserLists = document.querySelectorAll(".browser-list")
  browserLists.forEach((el) => el.style.display = 'none')
  document.getElementById(listId).style.display = 'block'

  document.querySelectorAll('.browser-list-selector-active').forEach((el) => el.classList.remove('browser-list-selector-active'))
  document.querySelector("[data-for='" + listId + "']").classList.add('browser-list-selector-active')
}

window.addEventListener("DOMContentLoaded", init);
