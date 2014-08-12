<?php if (!defined('APPLICATION')) exit();

// Define the plugin:
$PluginInfo['GreasyFork'] = array(
	 'Name' => 'GreasyFork',
	 'Description' => 'Greasy Fork customizations',
	 'Version' => '1.0',
	 'Author' => "Jason Barnabe",
	 'RequiredApplications' => array('Vanilla' => '2.1'),
	 'AuthorEmail' => 'jason.barnabe@gmail.com',
	 'AuthorUrl' => 'https://greasyfork.org'
);

class GreasyForkPlugin extends Gdn_Plugin {

	# Link to main profile
	public function UserInfoModule_OnBasicInfo_Handler($Sender) {
		$UserModel = new UserModel();

		$UserModel->SQL
			->Select('u.ForeignUserKey', '', 'MainUserID')
			->From('UserAuthentication u')
			->Where('u.UserID', $Sender->User->UserID);

		$Row = $UserModel->SQL->Get()->FirstRow();
		echo '<dt><a href="/users/'.$Row->MainUserID.'">Greasy Fork Profile</a></dt><dd></dd>';
	}

	# Add CSS, JS, and link to main site
	public function Base_Render_Before($Sender) {
		$Sender->AddCssFile($this->GetResource('global.css', FALSE, FALSE));
		$Sender->AddCssFile('https://fonts.googleapis.com/css?family=Open+Sans');
		$Sender->AddJsFile($this->GetResource('global.js', FALSE, FALSE));
		if ($Sender->Menu) {
			$Sender->Menu->AddLink('Greasy Fork', T('Greasy Fork'), 'https://greasyfork.org/', FALSE, array('class' => 'HomeLink'));
			# added to config: $Configuration['Garden']['Menu']['Sort'] = ['Greasy Fork', 'Dashboard', 'Discussions'];
		}
		if ($this->onMainPage()) {
			$this->ShowFilterLinks($Sender);
		}
	}

	# Going to render our own category selector
	public function PostController_BeforeFormInputs_Handler($Sender) {
		$Sender->ShowCategorySelector = false;
	}

	# Our own category selector, with description
	public function PostController_BeforeBodyInput_Handler($Sender) {
		# If the script ID is passed in, it will be hardcoded to category 4.
		if ($this->ScriptIDPassed($Sender)) {
			return;
		}
		echo '<div class="P">';
		echo '<div class="Category">';
		echo $Sender->Form->Label('Category', 'CategoryID'), ' ';
		echo '<br>';
		$SelectedCategory = GetValue('CategoryID', $Sender->Category);
		foreach (CategoryModel::Categories() as $c) {
			# -1 is the root
			if ($c['CategoryID'] != -1) {
				#4 is Style Reviews, which should only by used when script id is passed (and skips this anyway) or by mods
				if ($c['CategoryID'] != 4 || Gdn::Session()->CheckPermission('Vanilla.Discussions.Edit')) {
					echo '<input name="CategoryID" id="category-'.$c['CategoryID'].'" type="radio" value="'.$c['CategoryID'].'"'.($SelectedCategory == $c['CategoryID'] ? ' checked' : '').'><label for="category-'.$c['CategoryID'].'">'.$c['Name'].' - '.$c['Description'].'</label><br>';
				}
			}
		}
		#echo $Sender->Form->CategoryDropDown('CategoryID', array('Value' => GetValue('CategoryID', $this->Category)));
		echo '</div>';
		echo '</div>';
	}

	private function ScriptIDPassed($Sender) {
		# Same logic as GetItemID in DiscussionAbout
		if (isset($Sender->Discussion) && is_numeric($Sender->Discussion->ScriptID)) {
			return $Sender->Discussion->ScriptID != '0';
		}
		if (isset($_REQUEST['script']) && is_numeric($_REQUEST['script'])) {
			return $_REQUEST['script'] != '0';
		}
		return false;
	}

	public function PostController_AfterDiscussionSave_Handler(&$Sender){
		$this->SendNotification($Sender, true);
	}

	public function PostController_AfterCommentSave_Handler(&$Sender){
		$this->SendNotification($Sender, false);
	}

	private function SendNotification($Sender, $IsDiscussion) {
		$Session = Gdn::Session();

		# don't send on edit
		if ($Sender->RequestMethod == 'editdiscussion' || $Sender->RequestMethod == 'editcomment') {
			return;
		}

		# discussion info
		$UserName = $Session->User->Name;
		$DiscussionID = $Sender->EventArguments['Discussion']->DiscussionID;
		$DiscussionName = $Sender->EventArguments['Discussion']->Name;
		$ScriptID = $Sender->EventArguments['Discussion']->ScriptID;

		# no script - do nothing
		if (!isset($ScriptID) || !is_numeric($ScriptID)) {
			return;
		}

		# look up the user we might e-mail
		$DiscussionModel = new DiscussionModel();
		$prefix = $DiscussionModel->SQL->Database->DatabasePrefix;
		$DiscussionModel->SQL->Database->DatabasePrefix = '';
		$UserInfo = $DiscussionModel->SQL->Select('u.author_email_notification_type_id, u.email, u.name, s.name script_name, u.id, ua.UserID forum_user_id')
			->From('scripts s')
			->Join('users u', 's.user_id = u.id')
			->Join('GDN_UserAuthentication ua', 'ua.ForeignUserKey = u.id')
			->Where('s.id', $ScriptID)
			->Get()->NextRow(DATASET_TYPE_ARRAY);
		$DiscussionModel->SQL->Database->DatabasePrefix = $prefix;

		$NotificationPreference = $UserInfo['author_email_notification_type_id'];

		# 1: no notifications
		# 2: new discussions
		# 3: new discussions and comments

		# no notifications
		if ($NotificationPreference != 2 && $NotificationPreference != 3) {
			return;
		}

		# discussions only
		if ($NotificationPreference == 2 && !$IsDiscussion) {
			return;
		}

		# don't self-notify
		if ($UserInfo['forum_user_id'] == $Session->User->UserID) {
			return;
		}

		$NotificationEmail = $UserInfo['email'];
		$NotificationName = $UserInfo['name'];
		$ScriptName = $UserInfo['script_name'];
		if ($IsDiscussion) {
			$ActivityHeadline = $UserName.' started a discussion on '.$ScriptName;
		} else {
			$ActivityHeadline = $UserName.' commented on a discussion about '.$ScriptName;
		}
		$UserId = $UserInfo['id'];
		$AccountUrl = 'https://greasyfork.org/users/'.$UserId;

		$Email = new Gdn_Email();
		$Email->Subject(sprintf(T('[%1$s] %2$s'), Gdn::Config('Garden.Title'), $ActivityHeadline));
		$Email->To($NotificationEmail, $NotificationName);
		if ($IsDiscussion) {
			$Email->Message(sprintf("%s started a discussion '%s' on your script '%s'. Check it out: %s\n\nYou can change your notification settings on your Greasy Fork account page at %s", $UserName, $DiscussionName, $ScriptName, Url('/discussion/'.$DiscussionID.'/'.Gdn_Format::Url($DiscussionName), TRUE), $AccountUrl));
		} else {
			$Email->Message(sprintf("%s commented on the discussion '%s' on your script '%s'. Check it out: %s\n\nYou can change your notification settings on your Greasy Fork account page at %s", $UserName, $DiscussionName, $ScriptName, Url('/discussion/'.$DiscussionID.'/'.Gdn_Format::Url($DiscussionName), TRUE), $AccountUrl));
		}

		#print_r($Email);
		#die;

		try {
			$Email->Send();
		} catch (Exception $ex) {
			# report but keep going
			echo $ex;
		}

	}

	private function shouldFilterReviews() {
		return $this->GetUserMeta(Gdn::Session()->UserID, 'FilterReviews', false, true);
	}

	private function onMainPage() {
		if (isset($_REQUEST['script']) || isset($_REQUEST['script_author'])) {
			return false;
		}
		#return false;
		// i can't find a better way to detect this.
		foreach (debug_backtrace() as $i) {
			#echo $i['class'].':'.$i['function']."\n";
			# we don't want to do this for...
			if ((isset($i['class']) && ($i['class'] == 'BookmarkedModule' // bookmarks in the sidebar
			|| $i['class'] == 'CategoriesController' // category listings
			|| $i['class'] == 'ParticipatedPlugin')) // participated
			|| $i['function'] == 'GetAnnouncements' // announcements
			|| $i['function'] == 'Bookmarked' // bookmarks listings
			|| $i['function'] == 'Mine' // my discussions
			|| $i['function'] == 'ProfileController_Discussions_Create' // profile discussion list
			) {
				return false;
			}
		}
		return true;
	}

	// Update the query for the filter
	public function DiscussionModel_BeforeGet_Handler($Sender) {
		if ($this->onMainPage() && $this->shouldFilterReviews()) {
			$prefix = $Sender->SQL->Database->DatabasePrefix;
			$Sender->SQL->Database->DatabasePrefix = '';
			$Sender->SQL->Where('d.ScriptID IS NULL');
			$Sender->SQL->Database->DatabasePrefix = $prefix;
		}
	}

	// Update the pager for the filter
	public function DiscussionsController_BeforeBuildPager_Handler($Sender) {
		if ($this->onMainPage() && $this->shouldFilterReviews()) {
			$DiscussionModel = new DiscussionModel();
			$prefix = $DiscussionModel->SQL->Database->DatabasePrefix;
			$DiscussionModel->SQL->Database->DatabasePrefix = '';
			$DiscussionModel->SQL->Select('d.DiscussionID', 'count', 'CountDiscussions')
				->From('GDN_Discussion d')
				->Where('d.ScriptID IS NULL');
			$DiscussionModel->SQL->Database->DatabasePrefix = $prefix;
			$Row = $DiscussionModel->SQL->Get()->FirstRow();
			$Sender->SetData('CountDiscussions', $Row->CountDiscussions);
		}
	}

	// Update the user's filter setting
	public function ProfileController_SetReviewFilter_Create($Sender, $Args = array()) {
		// Check intent
		if (isset($Args[1]))
			Gdn::Session()->ValidateTransientKey($Args[1]);
		else
			Redirect($_SERVER['HTTP_REFERER']);

		if (isset($Args[0])) {
			if (CheckPermission('Garden.SignIn.Allow')) {
				$this->SetUserMeta(Gdn::Session()->UserID, 'FilterReviews', $Args[0] == 'true');
			}
		}

		// Back from whence we came
		Redirect($_SERVER['HTTP_REFERER']);
	 }

	// UI to update filter setting
	public function ShowFilterLinks($Sender) {
		// Not in Dashboard
		// Block guests until guest sessions are restored
		if ($Sender->MasterView == 'admin' || !CheckPermission('Garden.SignIn.Allow'))
			return;

		$FilterOn = $this->shouldFilterReviews();
		$Url = 'profile/setreviewfilter/'.($FilterOn ? 'false' : 'true').'/'.Gdn::Session()->TransientKey();
		$Link = Wrap(Anchor(($FilterOn ? 'Show script reviews' : 'Hide script reviews'), $Url), 'span', array('class' => 'ReviewFilterOption'));
		$FilterLinks = Wrap($Link, 'div', array('class' => 'ReviewFilterOptions'));
		$Sender->AddAsset('Content', $FilterLinks, 'ReviewFilter');
	}

}
