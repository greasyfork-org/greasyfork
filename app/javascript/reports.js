window.addEventListener("load", () => {
  const buttons = document.querySelectorAll(".lazy-load-diff");
  buttons.forEach((button) => {
    button.parentNode.addEventListener("ajax:success", (e) => {
      let diffSection = button.closest('.report-diff')
      diffSection.replaceChild(e.detail[0].firstChild, diffSection.firstChild)
    });
  });
});
