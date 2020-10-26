document.addEventListener("DOMContentLoaded", function() {
  if (document.querySelector(".close-sidebar")) {
    document.querySelector(".close-sidebar").addEventListener("click", function() {
      document.querySelector(".sidebar").classList.add("collapsed");
      document.querySelector(".open-sidebar").classList.add("sidebar-collapsed");
    });
  }
  if (document.querySelector(".open-sidebar")) {
    document.querySelector(".open-sidebar").addEventListener("click", function() {
      document.querySelector(".sidebar").classList.remove("collapsed");
      document.querySelector(".open-sidebar").classList.remove("sidebar-collapsed");
    });
  }
});
