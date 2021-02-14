export default function highlight(element) {
  element.style.transition = "background-color 3s"
  element.classList.add('highlight')
  setTimeout(() => element.classList.remove('highlight'), 3000)
}
