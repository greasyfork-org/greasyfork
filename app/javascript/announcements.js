import onload from '~/onload'

function init() {
  var form = document.getElementById("announcement-dismiss");
  if (form) {
    form.addEventListener("ajax:success", function() {
      var container = form.parentNode;
      container.parentNode.removeChild(container);
    });
  }
}

onload(init)