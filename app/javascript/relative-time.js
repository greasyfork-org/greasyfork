import {RelativeTimeElement} from '@github/time-elements';

class GFRelativeTimeElement extends RelativeTimeElement {
  getLang() {
    return document.documentElement.getAttribute("lang")
  }

  // Don't show "on... ", show a localized date.
  // https://github.com/github/time-elements/issues/120
  getFormattedDate() {
    let v = super.getFormattedDate();
    if (v.startsWith('on ')) {
      return (new Date(this.getAttribute("datetime"))).toLocaleDateString(this.getLang());
    }
    return v;
  }

  // Show a localized title based on the document language, not the browser language.
  // https://github.com/github/time-elements/issues/143
  getFormattedTitle() {
    return (new Date(this.getAttribute("datetime"))).toLocaleString(this.getLang());
  }
}

// Chrome seems to require this fire later, otherwise we duplicated dates.
document.addEventListener(("DOMContentLoaded"), function() {
  if (!window.customElements.get('gf-relative-time')) {
    window.GFRelativeTimeElement = GFRelativeTimeElement;
    window.customElements.define('gf-relative-time', GFRelativeTimeElement);
  }
});