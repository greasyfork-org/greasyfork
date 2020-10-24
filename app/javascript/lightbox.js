import { Luminous, LuminousGallery } from 'luminous-lightbox';

document.addEventListener("DOMContentLoaded", () => {
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
})
