<?php if (!defined('APPLICATION')) exit();

// Define the plugin:
$PluginInfo['GreasyFork'] = array(
   'Name' => 'GreasyFork',
   'Description' => 'Greasy Fork customizations',
   'Version' => '1.0',
   'Author' => "Jason Barnabe",
   'AuthorEmail' => 'jason.barnabe@gmail.com',
   'AuthorUrl' => 'https://greasyfork.org'
);

class GreasyForkPlugin extends Gdn_Plugin {

	public function PostController_BeforeFormInputs_Handler($Sender) {
		if ($this->getScriptID($Sender)) {
			$Sender->AddCssFile($this->GetResource('post.css', FALSE, FALSE));
			#$Sender->CategoryData = array('4' => 4);
			$cd = CategoryModel::Categories();
			$Sender->Category = $cd['4'];
		} else {
			# render our own category selector, see PostController_BeforeBodyInput_Handler
			$Sender->ShowCategorySelector = false;
		}
	}

	public function PostController_BeforeBodyInput_Handler($Sender) {
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
						echo '<input name="Discussion/CategoryID" id="category-'.$c['CategoryID'].'" type="radio" value="'.$c['CategoryID'].'"'.($SelectedCategory == $c['CategoryID'] ? ' checked' : '').'><label for="category-'.$c['CategoryID'].'">'.$c['Name'].' - '.$c['Description'].'</label><br>';
					}
				}
			}
			#echo $Sender->Form->CategoryDropDown('CategoryID', array('Value' => GetValue('CategoryID', $this->Category)));
			echo '</div>';
		echo '</div>';
	}

	public function DiscussionModel_BeforeSaveDiscussion_Handler($Sender) {
		# unset a category of -1, which is what class.discussionmodel.php does
		if ($Sender->EventArguments['FormPostValues']['CategoryID'] == -1) {
			$Sender->EventArguments['FormPostValues']['CategoryID'] = null;
		}
		#$Sender->Validation->ApplyRule('CategoryID', 'Required');

		# Handle empty string ScriptID
		if ($Sender->EventArguments['FormPostValues']['ScriptID'] == '') {
			$Sender->EventArguments['FormPostValues']['ScriptID'] = null;
		}
	}

	public function PostController_DiscussionFormOptions_Handler($Sender) {
		# rating
		if ($this->getScriptID($Sender)) {
			$ScriptName = $this->getScriptName($Sender);
			$Sender->EventArguments['Options'] .= '<div class="Rating">Rate <i>'.htmlspecialchars($ScriptName).'</i>:'.$Sender->Form->RadioList('Rating', array(
				'0' => '<img src="/images/circle-blue.png" alt=""> No rating (just a question or comment)',
				'1' => '<img src="/images/report.png" alt=""> Report script (malware, stolen code, or other bad things requiring moderator review)',
				'2' => '<img src="/images/circle-red.png" alt=""> Bad (doesn\'t work)',
				'3' => '<img src="/images/circle-yellow.png" alt=""> OK (works, but could use improvement)',
				'4' => '<img src="/images/circle-green.png" alt=""> Good (works well)',
			)).'</div>';
			if (!isset($Sender->Discussion)) {
				# add script name to title
				$Sender->EventArguments['Options'] .= '<script>document.getElementById("DiscussionForm").getElementsByTagName("h1")[0].innerHTML += " about <i>'.htmlspecialchars($ScriptName).'</i>"</script>';
			}
		}

		# script id
		if (Gdn::Session()->CheckPermission('Vanilla.Discussions.Edit')) {
			$Sender->EventArguments['Options'] .= "<p>Script ID: <input type='text' name='Discussion/ScriptID' value='".htmlspecialchars($this->getScriptID($Sender))."'></p>";
		}	else if ($this->getScriptID($Sender)) {
			$Sender->EventArguments['Options'] .= "<input type='hidden' name='Discussion/ScriptID' value='".htmlspecialchars($this->getScriptID($Sender))."'>";
		}
	}

	public function DiscussionsController_BeforeBuildPager_Handler($Sender) {
		if (is_numeric($_REQUEST['Discussion/ScriptAuthorID'])) {

			$DiscussionModel = new DiscussionModel();

			$prefix = $DiscussionModel->SQL->Database->DatabasePrefix;
			$DiscussionModel->SQL->Database->DatabasePrefix = '';

      		$DiscussionModel->SQL
	         ->Select('d.DiscussionID', 'count', 'CountDiscussions')
	         ->Select('users.name', '', 'Name')
	         ->From('GDN_Discussion d')
			 ->Join('scripts scripts', 'd.ScriptID = scripts.id', 'left')
			 ->Join('users users', 'users.id = scripts.user_id', 'inner')
             ->Where('scripts.user_id', $_REQUEST['Discussion/ScriptAuthorID']);

			$DiscussionModel->SQL->Database->DatabasePrefix = $prefix;

			$Row = $DiscussionModel->SQL->Get()->FirstRow();
			$User = $Row->Name;
			$Sender->SetData('CountDiscussions', $Row->CountDiscussions);

			$Sender->Head->AddRss(Url('/discussions/feed.rss?Discussion/ScriptAuthorID='.$_REQUEST['Discussion/ScriptAuthorID'], TRUE), 'Discussions on Scripts by '.$User);
			$Sender->Head->Title('Discussions on Scripts by '.$User);
		} else if (is_numeric($_REQUEST['Discussion/ScriptID'])) {

			$DiscussionModel = new DiscussionModel();

			$prefix = $DiscussionModel->SQL->Database->DatabasePrefix;
			$DiscussionModel->SQL->Database->DatabasePrefix = '';

      		$DiscussionModel->SQL
	         ->Select('d.DiscussionID', 'count', 'CountDiscussions')
	         ->Select('scripts.name', '', 'Name')
	         ->From('GDN_Discussion d')
			 ->Join('scripts scripts', 'd.ScriptID = scripts.id', 'left')
             ->Where('scripts.id', $_REQUEST['Discussion/ScriptID']);

			$DiscussionModel->SQL->Database->DatabasePrefix = $prefix;

			$Row = $DiscussionModel->SQL->Get()->FirstRow();
			$Script = $Row->Name;
			$Sender->SetData('CountDiscussions', $Row->CountDiscussions);

			$Sender->Head->AddRss(Url('/discussions/feed.rss?Discussion/ScriptID='.$_REQUEST['Discussion/ScriptID'], TRUE), 'Discussions on '.$User);
			$Sender->Head->Title('Discussions on '.$Script);
		} else if ($this->shouldFilterReviews()) {
			// if we're the default discussions view, we'll block script reviews.
			$DiscussionModel = new DiscussionModel();

			$prefix = $DiscussionModel->SQL->Database->DatabasePrefix;
			$DiscussionModel->SQL->Database->DatabasePrefix = '';

      		$DiscussionModel->SQL
	         ->Select('d.DiscussionID', 'count', 'CountDiscussions')
	         ->From('GDN_Discussion d')
             ->Where('d.CategoryID <>', 4);

			$DiscussionModel->SQL->Database->DatabasePrefix = $prefix;

			$Row = $DiscussionModel->SQL->Get()->FirstRow();
			$Sender->SetData('CountDiscussions', $Row->CountDiscussions);
		}

	}

	public function DiscussionsController_AfterBuildPager_Handler($Sender) {
		if (is_numeric($_REQUEST['Discussion/ScriptAuthorID'])) {
			$Sender->SetData('_PagerUrl', $Sender->Data('_PagerUrl').'?Discussion/ScriptAuthorID='.$_REQUEST['Discussion/ScriptAuthorID']);
		} else if (is_numeric($_REQUEST['Discussion/ScriptID'])) {
			$Sender->SetData('_PagerUrl', $Sender->Data('_PagerUrl').'?Discussion/ScriptID='.$_REQUEST['Discussion/ScriptID']);
		}
  }

	public function DiscussionController_BeforeDiscussion_Handler($Sender) {
		$Sender->AddCssFile($this->GetResource('discussion.css', FALSE, FALSE));
		if (isset($Sender->Discussion->ScriptID) && $Sender->Discussion->ScriptID != 0) {
			echo '<div class="Tabs HeadingTabs DiscussionTabs">';
			echo 'About: <a href="/scripts/'.$Sender->Discussion->ScriptID.'">'.htmlspecialchars($Sender->Discussion->ScriptName).'</a>';
			echo ' '.$this->getRatingImage($Sender->Discussion->Rating);
			echo '</div>';
		}
		echo $Sender->Pager->ToString('more');
	}

	public function DiscussionModel_BeforeGet_Handler($Sender) {
		if (is_numeric($_REQUEST['BlockCategory'])) {
			$Sender->SQL->Where('d.CategoryID <>', $_REQUEST['BlockCategory']);
		}
	}

	private function getRatingImage($Rating) {
		switch ($Rating) {
			case 1:
				return '<img src="/images/report.png" alt="">';
			case 2:
				return '<img src="/images/circle-red.png" alt="">';
			case 3:
				return '<img src="/images/circle-yellow.png" alt="">';
			case 4:
				return '<img src="/images/circle-green.png" alt="">';
		}
		return null;
	}

	public function DiscussionModel_AfterDiscussionSummaryQuery_Handler($Sender) {
		$prefix = $Sender->SQL->Database->DatabasePrefix;
		$Sender->SQL->Database->DatabasePrefix = '';
		$Sender->SQL->Join('scripts scripts', 'd.ScriptID = scripts.id', 'left');
		$Sender->SQL->Select('scripts.name', '', 'ScriptName');
		if (is_numeric($_REQUEST['Discussion/ScriptAuthorID'])) {
			$Sender->SQL->Where('scripts.user_id', $_REQUEST['Discussion/ScriptAuthorID']);
		} else if (is_numeric($_REQUEST['Discussion/ScriptID'])) {
			$Sender->SQL->Where('scripts.id', $_REQUEST['Discussion/ScriptID']);
		} else {
			// if we're the default discussions view, we'll block script reviews.
			if ($this->shouldFilterReviews()) {
				$Sender->SQL->Where('d.CategoryID <>', 4);
			}
		}
		$Sender->SQL->Database->DatabasePrefix = $prefix;
	}
	
	private function shouldFilterReviews() {
		return false;
		// i can't find a better way to detect this.
		foreach (debug_backtrace() as $i) {
			// echo $i['class'].':'.$i['function']."\n";
			# we don't want to do this for...
			if ($i['class'] == 'BookmarkedModule' // bookmarks in the sidebar
				|| $i['function'] == 'GetAnnouncements' // announcements
				|| $i['class'] == 'CategoriesController' // category listings
				|| $i['function'] == 'Bookmarked' // bookmarks listings
				|| $i['function'] == 'Mine' // my discussions
				|| $i['class'] == 'ParticipatedPlugin' // participated
				|| $i['function'] == 'ProfileController_Discussions_Create' // profile discussion list
				) {
				return false;
			}
		}
		return true;
	}

	public function DiscussionModel_BeforeGetID_Handler($Sender) {
		$prefix = $Sender->SQL->Database->DatabasePrefix;
		$Sender->SQL->Database->DatabasePrefix = '';
		$Sender->SQL->Join('scripts scripts', 'd.ScriptID = scripts.id', 'left');
		$Sender->SQL->Select('scripts.name', '', 'ScriptName');
		$Sender->SQL->Database->DatabasePrefix = $prefix;
	}

	public function DiscussionsController_AfterDiscussionTitle_Handler($Sender) {
		$Discussion = $Sender->EventArguments['Discussion'];
		if (is_numeric($Discussion->ScriptID) && $Discussion->ScriptID != 0) {
			$Sender->AddCssFile($this->GetResource('list.css', FALSE, FALSE));
			echo '<span class="Title">- '.htmlspecialchars($Discussion->ScriptName).' '.$this->getRatingImage($Discussion->Rating).'</span>';
		}
	}

	public function UserInfoModule_OnBasicInfo_Handler($Sender) {
		#echo '<dt><a href="https://greasyfork.org/users/show_by_forum_id/'.$Sender->User->UserID.'">Main Profile</a></dt><dd></dd>';
	}

	public function CategoriesController_AfterDiscussionTitle_Handler($Sender) {
		$this->DiscussionsController_AfterDiscussionTitle_Handler($Sender);
	}

	public function Structure() {
		$Structure = Gdn::Structure();
		$Structure->Table('Discussion')->Column('ScriptID', 'int');
		#$Structure->Table('Discussion')->Column('Rating', 'int');
	}

	public function Setup() {
		$this->Structure();
	}

	private function getScriptID($Sender) {
		if (is_numeric($Sender->Discussion->ScriptID)) {
			if ($Sender->Discussion->ScriptID == '0') {
				return null;
			}
			return $Sender->Discussion->ScriptID; 
		}
		if (is_numeric($_REQUEST['Discussion/ScriptID'])) {
			if ($_REQUEST['Discussion/ScriptID'] == '0') {
				return null;
			}
			return $_REQUEST['Discussion/ScriptID'];
		}
		return null;
	}

	private function getScriptName($Sender) {
		$ScriptID = $this->getScriptID($Sender);
		$Results = $Sender->Database->Query('SELECT name ScriptName FROM scripts WHERE id = '.$ScriptID)->Result('DATASET_TYPE_ARRAY');
		return $Results[0]->ScriptName;
	}

	public function Base_Render_Before($Sender) {
		$Sender->AddCssFile($this->GetResource('global.css', FALSE, FALSE));
		$Sender->AddJsFile($this->GetResource('global.js', FALSE, FALSE));
		if ($Sender->Menu) {
			$Sender->Menu->AddLink('Greasy Fork', T('Greasy Fork'), 'https://greasyfork.org/', FALSE, array('class' => 'HomeLink'));
			# added to config: $Configuration['Garden']['Menu']['Sort'] = ['Greasy Fork', 'Dashboard', 'Discussions'];
		}
	}

}
