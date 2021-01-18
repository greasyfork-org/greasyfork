class JsExecutor
  class << self
    def extract_urls(code)
      urls = Set.new
      return urls unless code

      context = MiniRacer::Context.new(timeout: 500, max_memory: 20_000_000)
      context.attach 'greasyforkSetLogger', lambda { |property, value|
        urls << value if URL_SETTERS.include?(property.join('.'))
      }
      context.attach 'greasyforkFunctionLogger', lambda { |property, first_arg|
        urls << first_arg if URL_FUNCTIONS.include?(property.join('.'))
      }

      begin
        context.eval("#{proxy_code}\n#{code}")
      rescue MiniRacer::Error
        # puts code
        # puts e.backtrace.select{|bt| bt.start_with?('JavaScript') }
        # raise e
      end

      urls
    end

    def proxy_code
      js = <<~JS
        function GreasyforkProxy(reference) {
          return new Proxy(function() {}, {
            get: function(obj, prop) {
              switch(prop) {
                case 'setTimeout':
                case 'setInterval':
                  return function() { arguments[0](); }
                case 'addEventListener':
                  return function() { arguments[1](new GreasyforkProxy(['(event)'])); }
                case Symbol.toPrimitive:
                  return function(hint) {
                    switch(hint) {
                      case 'number':
                        return 12;
                      case 'string':
                        return 'twelve';
                      default:
                        return null;
                    }
                  }
              }
              return new GreasyforkProxy(reference.concat(prop));
            },
            set: function(obj, prop, val) {
              if (typeof val == 'string') {
                greasyforkSetLogger(reference.concat(prop), val);
              }
              return true;
            },
            apply: function(target, thisArg, argumentsList) {
              if (typeof argumentsList[0] == 'string') {
                greasyforkFunctionLogger(reference, argumentsList[0]);
              }
              return new GreasyforkProxy(reference);
            }
          });
        };

        window = new GreasyforkProxy(['window']);
      JS
      js + TOP_LEVEL_MEMBERS.map { |tlm| "#{tlm} = window.#{tlm};" }.join("\n")
    end
  end

  URL_SETTERS = %w[window.location window.location.href].to_set
  URL_FUNCTIONS = %w[window.open window.location.assign window.location.replace GM_openInTab].to_set
  TOP_LEVEL_MEMBERS = %w[close stop focus blur open alert confirm prompt print postMessage captureEvents releaseEvents getSelection getComputedStyle matchMedia moveTo moveBy resizeTo resizeBy scroll scrollTo scrollBy requestAnimationFrame cancelAnimationFrame getDefaultComputedStyle scrollByLines scrollByPages sizeToContent updateCommands find dump setResizable requestIdleCallback cancelIdleCallback btoa atob setTimeout clearTimeout setInterval clearInterval queueMicrotask createImageBitmap fetch self name history customElements locationbar menubar personalbar scrollbars statusbar toolbar status closed event frames length opener parent frameElement navigator external screen innerWidth innerHeight scrollX pageXOffset scrollY pageYOffset screenLeft screenTop screenX screenY outerWidth outerHeight performance mozInnerScreenX mozInnerScreenY devicePixelRatio scrollMaxX scrollMaxY fullScreen ondevicemotion ondeviceorientation onabsolutedeviceorientation ondeviceproximity onuserproximity ondevicelight InstallTrigger sidebar crypto onabort onblur onfocus onauxclick oncanplay oncanplaythrough onchange onclick onclose oncontextmenu oncuechange ondblclick ondrag ondragend ondragenter ondragexit ondragleave ondragover ondragstart ondrop ondurationchange onemptied onended onformdata oninput oninvalid onkeydown onkeypress onkeyup onload onloadeddata onloadedmetadata onloadend onloadstart onmousedown onmouseenter onmouseleave onmousemove onmouseout onmouseover onmouseup onwheel onpause onplay onplaying onprogress onratechange onreset onresize onscroll onseeked onseeking onselect onshow onstalled onsubmit onsuspend ontimeupdate onvolumechange onwaiting onselectstart ontoggle onpointercancel onpointerdown onpointerup onpointermove onpointerout onpointerover onpointerenter onpointerleave ongotpointercapture onlostpointercapture onmozfullscreenchange onmozfullscreenerror onanimationcancel onanimationend onanimationiteration onanimationstart ontransitioncancel ontransitionend ontransitionrun ontransitionstart onwebkitanimationend onwebkitanimationiteration onwebkitanimationstart onwebkittransitionend onerror speechSynthesis onafterprint onbeforeprint onbeforeunload onhashchange onlanguagechange onmessage onmessageerror onoffline ononline onpagehide onpageshow onpopstate onrejectionhandled onstorage onunhandledrejection onunload localStorage origin crossOriginIsolated isSecureContext indexedDB caches sessionStorage document location top properties addEventListener removeEventListener dispatchEvent GM_openInTab].to_set
end
