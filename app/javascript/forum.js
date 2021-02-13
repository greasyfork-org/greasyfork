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
  let htmlFormat = replyForm.querySelector("[name='comment[text_markup]']:checked, [name='message[content_markup]']:checked").value == 'html'
  let text = getSelectedText(comment, htmlFormat)
  let replyInput = replyForm.querySelector("#comment_text, #message_content")
  let prependWhitespace = replyInput.value != "" && !replyInput.value.endsWith("\n")
  replyInput.value += (prependWhitespace ? "\n\n" : "") + blockquoteText(text, htmlFormat) + "\n\n"
  replyInput.focus()
}

function blockquoteText(text, htmlFormat) {
  if (htmlFormat) {
    return "<blockquote>" + text + "</blockquote>"
  }
  // Two spaces after allow us to have single line breaks
  return text.split("\n").map(value => "> " + value + "  ").join("\n")
}

function getSelectedText(comment, htmlFormat) {
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
  if (htmlFormat) {
    return quoted.innerHTML.trim()
  }
  // At this point we're converting HTML to Markdown. Don't care about any elements except blockquote.
  let frag = quoted.cloneNode(true)
  for (let blockquote of Array.from(frag.querySelectorAll("blockquote")).reverse()) {
    blockquote.parentNode.insertBefore(document.createTextNode(blockquoteText(blockquote.innerText, htmlFormat)), blockquote)
    blockquote.parentNode.removeChild(blockquote);
  }
  return frag.innerText.trim()
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
  let forumLocale = document.getElementById("discussion-locale")
  if (forumLocale) {
    forumLocale.addEventListener("change", function() {
      if (this.selectedOptions[0] && this.selectedOptions[0].hasAttribute("data-url")) {
        location.href = this.selectedOptions[0].getAttribute("data-url")
      }
    })
  }
}
window.addEventListener("DOMContentLoaded", init);
