function discussionSubscribe(event) {
  let subscribeContainer = document.querySelector(".discussion-subscription-links");
  subscribeContainer.classList.add("discussion-subscribed");
  subscribeContainer.classList.remove("discussion-not-subscribed");
}

function discussionUnsubscribe(event) {
  let subscribeContainer = document.querySelector(".discussion-subscription-links");
  subscribeContainer.classList.add("discussion-not-subscribed");
  subscribeContainer.classList.remove("discussion-subscribed");
}

function quoteComment(event) {
  event.preventDefault()
  let comment = event.target.closest(".comment")
  let replyForm = document.getElementById("post-reply")
  let htmlFormat = replyForm.querySelector("[name='comment[text_markup]']:checked").value == 'html'
  let text = getSelectedText(comment)
  if (htmlFormat) {
    text = "<blockquote>" + text + "</blockquote>\n\n"
  } else {
    // Two spaces after allow us to have single line breaks
    text = text.split("\n").map(value => "> " + value + "  ").join("\n") + "\n\n"
  }
  let replyInput = replyForm.querySelector("#comment_text")
  replyInput.value += text
  replyInput.focus()
}

function getSelectedText(comment) {
  let quoted = comment.querySelector(".user-content")
  let selection = window.getSelection()
  let startSelection = null;
  let endSelection;
  if (selection.type == 'Range') {
    startSelection = selection.anchorNode;
    if (startSelection && startSelection.nodeType != Node.ELEMENT_NODE) {
      startSelection = startSelection.parentElement;
    }
    endSelection = selection.focusNode;
    if (endSelection && endSelection.nodeType != Node.ELEMENT_NODE) {
      endSelection = endSelection.parentElement;
    }
    if (startSelection.closest(".user-content") == quoted && endSelection.closest(".user-content") == quoted) {
      return selection.toString().trim()
    }
  }
  return quoted.textContent.trim()
}

function init() {
  for (let link of document.querySelectorAll(".edit-comment")) {
    link.addEventListener("click", function(event) {
      event.preventDefault()
      document.getElementById(link.getAttribute("data-comment-container")).classList.add("edit-comment-mode");
    });
  }
  for (let link of document.querySelectorAll(".cancel-edit-comment")) {
    link.addEventListener("click", function(event) {
      event.preventDefault()
      document.getElementById(link.getAttribute("data-comment-container")).classList.remove("edit-comment-mode");
    });
  }
  let subscribeLink = document.querySelector(".discussion-subscribe");
  if (subscribeLink) {
    subscribeLink.addEventListener("ajax:success", discussionSubscribe);
  }
  let unsubscribeLink = document.querySelector(".discussion-unsubscribe");
  if (unsubscribeLink) {
    unsubscribeLink.addEventListener("ajax:success", discussionUnsubscribe);
  }
  for (let link of document.querySelectorAll(".quote-comment")) {
    link.addEventListener("click", quoteComment);
  }

}
window.addEventListener("DOMContentLoaded", init);
