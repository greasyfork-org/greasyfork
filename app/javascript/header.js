import onload from '~/onload'

let toggleMobileNav = () => { document.querySelector("#mobile-nav nav").classList.toggle("collapsed") }

onload(() => document.querySelector(".mobile-nav-opener")?.addEventListener("click", toggleMobileNav))
