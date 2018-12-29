document.addEventListener("DOMContentLoaded", function() {
  document.querySelector(".close-sidebar").addEventListener("click", function() {
    document.querySelector(".sidebar").classList.add("collapsed");
    document.querySelector(".open-sidebar").classList.add("sidebar-collapsed");
  });
  document.querySelector(".open-sidebar").addEventListener("click", function() {
    document.querySelector(".sidebar").classList.remove("collapsed");
    document.querySelector(".open-sidebar").classList.remove("sidebar-collapsed");
  });
});
