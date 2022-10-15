document.addEventListener("DOMContentLoaded", async () => {
  if (document.querySelector(".remove-attachments, .user-screenshots")) {
    const { Luminous, LuminousGallery } = await import('luminous-lightbox');
    document.querySelectorAll(".remove-attachments, .user-screenshots").forEach((el) => {
      let imageLinks = el.querySelectorAll("a")
      switch (imageLinks.length) {
        case 0:
          break;
        case 1:
          new Luminous(imageLinks[0]);
          break;
        default:
          new LuminousGallery(imageLinks);
      }
    })
  }
})
