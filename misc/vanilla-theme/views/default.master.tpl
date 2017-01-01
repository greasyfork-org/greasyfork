<!DOCTYPE html>
<html>
<head>
  {asset name="Head"}
</head>
<body id="{$BodyID}" class="{$BodyClass}">
   <div id="Frame">
      <div class="Head" id="Head">
         <div class="Row">
			{assign var=locale value=$smarty.get.locale|default:'en'}
            <div id="site-name">
				<a href="/{$locale}/">{logo}</a>
				<div id="site-name-text">
					<h1><a href="/{$locale}/">Greasy Fork</a></h1>
					<p class="subtitle">Shined up real nice.</p>
				</div>
			</div>
			<ul id="nav-user-info">
				{profile_link}
				{if $User.SignedIn}
					[ {signinout_link} ]
				{else}
					<!-- js connect sign in should go here -->
				{/if}
				<li>
					<select id="language-selector-locale" name="locale">
						<option value="ar" {if $locale == 'ar'}selected{/if}>العَرَبِيةُ (ar)</option>
						<option value="bg" {if $locale == 'bg'}selected{/if}>Български (bg)</option>
						<option value="cs" {if $locale == 'cs'}selected{/if}>Čeština (cs)</option>
						<option value="da" {if $locale == 'da'}selected{/if}>Dansk (da)</option>
						<option value="de" {if $locale == 'de'}selected{/if}>Deutsch (de)</option>
						<option value="el" {if $locale == 'el'}selected{/if}>Ελληνικά (el)</option>
						<option value="en" {if $locale == 'en'}selected{/if}>English (en)</option>
						<option value="es" {if $locale == 'es'}selected{/if}>Español (es)</option>
						<option value="fi" {if $locale == 'fi'}selected{/if}>Suomi (fi)</option>
						<option value="fr" {if $locale == 'fr'}selected{/if}>Français (fr)</option>
						<option value="fr-CA" {if $locale == 'fr-CA'}selected{/if}>Français canadien (fr-CA)</option>
						<option value="he" {if $locale == 'he'}selected{/if}>עברית (he)</option>
						<option value="hu" {if $locale == 'hu'}selected{/if}>Magyar (hu)</option>
						<option value="id" {if $locale == 'id'}selected{/if}>Bahasa Indonesia (id)</option>
						<option value="it" {if $locale == 'it'}selected{/if}>Italiano (it)</option>
						<option value="ja" {if $locale == 'ja'}selected{/if}>日本語 (ja)</option>
						<option value="ko" {if $locale == 'ko'}selected{/if}>한국어 (ko)</option>
						<option value="nb" {if $locale == 'nb'}selected{/if}>Bokmål (nb)</option>
						<option value="nl" {if $locale == 'nl'}selected{/if}>Nederlands (nl)</option>
						<option value="pl" {if $locale == 'pl'}selected{/if}>Polski (pl)</option>
						<option value="pt-BR" {if $locale == 'pt-BR'}selected{/if}>Português do Brasil (pt-BR)</option>
						<option value="ro" {if $locale == 'ro'}selected{/if}>Română (ro)</option>
						<option value="ru" {if $locale == 'ru'}selected{/if}>Русский (ru)</option>
						<option value="sk" {if $locale == 'sk'}selected{/if}>Slovenčina (sk)</option>
						<option value="sv" {if $locale == 'sv'}selected{/if}>Svenska (sv)</option>
						<option value="tr" {if $locale == 'tr'}selected{/if}>Türkçe (tr)</option>
						<option value="uk" {if $locale == 'uk'}selected{/if}>Українська (uk)</option>
						<option value="vi" {if $locale == 'vi'}selected{/if}>Tiếng Việt (vi)</option>
						<option value="zh-CN" {if $locale == 'zh-CN'}selected{/if}>简体中文 (zh-CN)</option>
						<option value="zh-TW" {if $locale == 'zh-TW'}selected{/if}>繁體中文 (zh-TW)</option>
						<option value="help">Help us translate!</option>
					</select>
					{literal}
					<script>
						document.getElementById("language-selector-locale").addEventListener("change", function(event) {
							var selectedOption = event.target.selectedOptions[0];
							if (selectedOption.value == "help") {
								location.href = "https://github.com/JasonBarnabe/greasyfork/wiki/Translating-Greasy-Fork";
							} else {
								var pathStart = location.href.indexOf("/forum");
								location.href = "/" + selectedOption.value + location.href.substring(pathStart);
							}
						});
					</script>
					{/literal}
				</li>
			</ul>
            <ul class="SiteMenu">
				<li class="scripts-index-link"><a href="/{$smarty.get.locale|default:'en'}/scripts/">{t c="layouts.application.script_list" d="Scripts"}</a></li>
				<li class="forum-link"><a href="/{$smarty.get.locale|default:'en'}/forum/">{t c="layouts.application.forum" d="Forum"}</a></li>
				<li class="help-link"><a href="/{$smarty.get.locale|default:'en'}/help/">{t c="layouts.application.help" d="Help"}</a></li>
				<li class="nav-search">
					<form id="script-search" action="/{$smarty.get.locale|default:'en'}/scripts/search">
						<input type="search" name="q"><input class="search-submit" type="submit" value="🔎">
					</form>
				</li>
            </ul>
         </div>
      </div>
      <div id="Body">
         <div class="Row">
            <div class="Column PanelColumn" id="Panel">
               {module name="MeModule"}
               {asset name="Panel"}
               <div class="SiteSearch">{searchbox}</div>
            </div>
            <div class="Column ContentColumn" id="Content">{asset name="Content"}</div>
         </div>
      </div>
      <div id="Foot">
         <div class="Row">
            <a href="{vanillaurl}" class="PoweredByVanilla" title="Community Software by Vanilla Forums">Powered by Vanilla</a>
            {asset name="Foot"}
         </div>
      </div>
   </div>
   {event name="AfterBody"}

   <script>
      {literal}
         (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
         (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
         m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
         })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

         ga('create', 'UA-48197018-3', 'auto');
         ga('send', 'pageview');
      {/literal}
   </script>

</body>
</html>
