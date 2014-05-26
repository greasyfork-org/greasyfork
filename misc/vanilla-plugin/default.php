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
		$Sender->AddJsFile($this->GetResource('global.js', FALSE, FALSE));
		if ($Sender->Menu) {
			$Sender->Menu->AddLink('Greasy Fork', T('Greasy Fork'), 'https://greasyfork.org/', FALSE, array('class' => 'HomeLink'));
			# added to config: $Configuration['Garden']['Menu']['Sort'] = ['Greasy Fork', 'Dashboard', 'Discussions'];
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
}
