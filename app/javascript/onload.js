export default function onload(func) {
  document.documentElement.addEventListener("turbo:load", func)
}