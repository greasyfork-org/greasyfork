
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `GDN_AccessToken`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_AccessToken` (
  `AccessTokenID` int(11) NOT NULL AUTO_INCREMENT,
  `Token` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `UserID` int(11) NOT NULL,
  `Type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Scope` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateInserted` timestamp NOT NULL DEFAULT current_timestamp(),
  `InsertUserID` int(11) DEFAULT NULL,
  `InsertIPAddress` varbinary(16) NOT NULL,
  `DateExpires` timestamp NOT NULL DEFAULT current_timestamp(),
  `Attributes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`AccessTokenID`),
  UNIQUE KEY `UX_AccessToken` (`Token`),
  KEY `IX_AccessToken_UserID` (`UserID`),
  KEY `IX_AccessToken_Type` (`Type`),
  KEY `IX_AccessToken_DateExpires` (`DateExpires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Activity`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Activity` (
  `ActivityID` int(11) NOT NULL AUTO_INCREMENT,
  `CommentActivityID` int(11) DEFAULT NULL,
  `ActivityTypeID` int(11) NOT NULL,
  `NotifyUserID` int(11) NOT NULL DEFAULT 0,
  `ActivityUserID` int(11) DEFAULT NULL,
  `RegardingUserID` int(11) DEFAULT NULL,
  `Photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `HeadlineFormat` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Story` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Format` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Route` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RecordType` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RecordID` int(11) DEFAULT NULL,
  `CountComments` int(11) NOT NULL DEFAULT 0,
  `InsertUserID` int(11) DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  `DateUpdated` datetime NOT NULL,
  `Notified` tinyint(4) NOT NULL DEFAULT 0,
  `Emailed` tinyint(4) NOT NULL DEFAULT 0,
  `Data` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`ActivityID`),
  KEY `FK_Activity_CommentActivityID` (`CommentActivityID`),
  KEY `FK_Activity_InsertUserID` (`InsertUserID`),
  KEY `IX_Activity_Notify` (`NotifyUserID`,`Notified`),
  KEY `IX_Activity_Recent` (`NotifyUserID`,`DateUpdated`),
  KEY `IX_Activity_Feed` (`NotifyUserID`,`ActivityUserID`,`DateUpdated`),
  KEY `IX_Activity_DateUpdated` (`DateUpdated`)
) ENGINE=InnoDB AUTO_INCREMENT=126090 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_ActivityComment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_ActivityComment` (
  `ActivityCommentID` int(11) NOT NULL AUTO_INCREMENT,
  `ActivityID` int(11) NOT NULL,
  `Body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `Format` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `InsertUserID` int(11) NOT NULL,
  `DateInserted` datetime NOT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  PRIMARY KEY (`ActivityCommentID`),
  KEY `FK_ActivityComment_ActivityID` (`ActivityID`)
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_ActivityType`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_ActivityType` (
  `ActivityTypeID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AllowComments` tinyint(4) NOT NULL DEFAULT 0,
  `ShowIcon` tinyint(4) NOT NULL DEFAULT 0,
  `ProfileHeadline` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `FullHeadline` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RouteCode` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Notify` tinyint(4) NOT NULL DEFAULT 0,
  `Public` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`ActivityTypeID`)
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_AnalyticsLocal`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_AnalyticsLocal` (
  `TimeSlot` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Views` int(11) DEFAULT NULL,
  `EmbedViews` int(11) DEFAULT NULL,
  UNIQUE KEY `UX_AnalyticsLocal` (`TimeSlot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Attachment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Attachment` (
  `AttachmentID` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ForeignID` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ForeignUserID` int(11) NOT NULL,
  `Source` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SourceID` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `SourceURL` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Attributes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  `InsertUserID` int(11) NOT NULL,
  `InsertIPAddress` varbinary(16) NOT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  `UpdateUserID` int(11) DEFAULT NULL,
  `UpdateIPAddress` varbinary(16) DEFAULT NULL,
  PRIMARY KEY (`AttachmentID`),
  KEY `IX_Attachment_ForeignID` (`ForeignID`),
  KEY `FK_Attachment_ForeignUserID` (`ForeignUserID`),
  KEY `FK_Attachment_InsertUserID` (`InsertUserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Ban`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Ban` (
  `BanID` int(11) NOT NULL AUTO_INCREMENT,
  `BanType` enum('IPAddress','Name','Email') COLLATE utf8mb4_unicode_ci NOT NULL,
  `BanValue` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Notes` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CountUsers` int(10) unsigned NOT NULL DEFAULT 0,
  `CountBlockedRegistrations` int(10) unsigned NOT NULL DEFAULT 0,
  `InsertUserID` int(11) NOT NULL,
  `DateInserted` datetime NOT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  `UpdateUserID` int(11) DEFAULT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  `UpdateIPAddress` varbinary(16) DEFAULT NULL,
  PRIMARY KEY (`BanID`),
  UNIQUE KEY `UX_Ban` (`BanType`,`BanValue`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Category` (
  `CategoryID` int(11) NOT NULL AUTO_INCREMENT,
  `ParentCategoryID` int(11) DEFAULT NULL,
  `TreeLeft` int(11) DEFAULT NULL,
  `TreeRight` int(11) DEFAULT NULL,
  `Depth` int(11) NOT NULL DEFAULT 0,
  `CountCategories` int(11) NOT NULL DEFAULT 0,
  `CountDiscussions` int(11) NOT NULL DEFAULT 0,
  `CountAllDiscussions` int(11) NOT NULL DEFAULT 0,
  `CountComments` int(11) NOT NULL DEFAULT 0,
  `CountAllComments` int(11) NOT NULL DEFAULT 0,
  `LastCategoryID` int(11) NOT NULL DEFAULT 0,
  `DateMarkedRead` datetime DEFAULT NULL,
  `AllowDiscussions` tinyint(4) NOT NULL DEFAULT 1,
  `Archived` tinyint(4) NOT NULL DEFAULT 0,
  `CanDelete` tinyint(4) NOT NULL DEFAULT 1,
  `Name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `UrlCode` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Sort` int(11) DEFAULT NULL,
  `CssClass` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `PermissionCategoryID` int(11) NOT NULL DEFAULT -1,
  `PointsCategoryID` int(11) NOT NULL DEFAULT 0,
  `HideAllDiscussions` tinyint(4) NOT NULL DEFAULT 0,
  `DisplayAs` enum('Categories','Discussions','Flat','Heading','Default') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Discussions',
  `InsertUserID` int(11) NOT NULL,
  `UpdateUserID` int(11) DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  `DateUpdated` datetime NOT NULL,
  `LastCommentID` int(11) DEFAULT NULL,
  `LastDiscussionID` int(11) DEFAULT NULL,
  `LastDateInserted` datetime DEFAULT NULL,
  `AllowedDiscussionTypes` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DefaultDiscussionType` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `AllowFileUploads` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`CategoryID`),
  KEY `FK_Category_InsertUserID` (`InsertUserID`),
  KEY `FK_Category_ParentCategoryID` (`ParentCategoryID`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Comment` (
  `CommentID` int(11) NOT NULL AUTO_INCREMENT,
  `DiscussionID` int(11) NOT NULL,
  `InsertUserID` int(11) DEFAULT NULL,
  `UpdateUserID` int(11) DEFAULT NULL,
  `DeleteUserID` int(11) DEFAULT NULL,
  `Body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `Format` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateInserted` datetime DEFAULT NULL,
  `DateDeleted` datetime DEFAULT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  `UpdateIPAddress` varbinary(16) DEFAULT NULL,
  `Flag` tinyint(4) NOT NULL DEFAULT 0,
  `Score` float DEFAULT NULL,
  `Attributes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`CommentID`),
  KEY `FK_Comment_InsertUserID` (`InsertUserID`),
  KEY `IX_Comment_1` (`DiscussionID`,`DateInserted`),
  KEY `IX_Comment_DateInserted` (`DateInserted`),
  KEY `IX_Comment_Score` (`Score`),
  FULLTEXT KEY `TX_Comment` (`Body`)
) ENGINE=MyISAM AUTO_INCREMENT=155899 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Conversation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Conversation` (
  `ConversationID` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ForeignID` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Subject` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Contributors` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `FirstMessageID` int(11) DEFAULT NULL,
  `InsertUserID` int(11) NOT NULL,
  `DateInserted` datetime DEFAULT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  `UpdateUserID` int(11) NOT NULL,
  `DateUpdated` datetime NOT NULL,
  `UpdateIPAddress` varbinary(16) DEFAULT NULL,
  `CountMessages` int(11) NOT NULL DEFAULT 0,
  `CountParticipants` int(11) NOT NULL DEFAULT 0,
  `LastMessageID` int(11) DEFAULT NULL,
  `RegardingID` int(11) DEFAULT NULL,
  PRIMARY KEY (`ConversationID`),
  KEY `FK_Conversation_FirstMessageID` (`FirstMessageID`),
  KEY `FK_Conversation_InsertUserID` (`InsertUserID`),
  KEY `FK_Conversation_DateInserted` (`DateInserted`),
  KEY `FK_Conversation_UpdateUserID` (`UpdateUserID`),
  KEY `IX_Conversation_RegardingID` (`RegardingID`),
  KEY `IX_Conversation_Type` (`Type`)
) ENGINE=InnoDB AUTO_INCREMENT=3063 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_ConversationMessage`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_ConversationMessage` (
  `MessageID` int(11) NOT NULL AUTO_INCREMENT,
  `ConversationID` int(11) NOT NULL,
  `Body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `Format` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `InsertUserID` int(11) DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  PRIMARY KEY (`MessageID`),
  KEY `FK_ConversationMessage_ConversationID` (`ConversationID`),
  KEY `FK_ConversationMessage_InsertUserID` (`InsertUserID`)
) ENGINE=InnoDB AUTO_INCREMENT=12934 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Discussion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Discussion` (
  `DiscussionID` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ForeignID` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CategoryID` int(11) NOT NULL,
  `InsertUserID` int(11) NOT NULL,
  `UpdateUserID` int(11) DEFAULT NULL,
  `FirstCommentID` int(11) DEFAULT NULL,
  `LastCommentID` int(11) DEFAULT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `Format` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Tags` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CountComments` int(11) NOT NULL DEFAULT 0,
  `CountBookmarks` int(11) DEFAULT NULL,
  `CountViews` int(11) NOT NULL DEFAULT 1,
  `Closed` tinyint(4) NOT NULL DEFAULT 0,
  `Announce` tinyint(4) NOT NULL DEFAULT 0,
  `Sink` tinyint(4) NOT NULL DEFAULT 0,
  `DateInserted` datetime NOT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  `UpdateIPAddress` varbinary(16) DEFAULT NULL,
  `DateLastComment` datetime DEFAULT NULL,
  `LastCommentUserID` int(11) DEFAULT NULL,
  `Score` float DEFAULT NULL,
  `Attributes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RegardingID` int(11) DEFAULT NULL,
  `ScriptID` int(11) DEFAULT NULL,
  `Rating` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`DiscussionID`),
  KEY `IX_Discussion_Type` (`Type`),
  KEY `IX_Discussion_ForeignID` (`ForeignID`),
  KEY `FK_Discussion_CategoryID` (`CategoryID`),
  KEY `FK_Discussion_InsertUserID` (`InsertUserID`),
  KEY `IX_Discussion_DateLastComment` (`DateLastComment`),
  KEY `IX_Discussion_RegardingID` (`RegardingID`),
  KEY `IX_Discussion_DateInserted` (`DateInserted`),
  KEY `IX_Discussion_CategoryPages` (`CategoryID`,`DateLastComment`),
  KEY `IX_Discussion_CategoryInserted` (`CategoryID`,`DateInserted`),
  KEY `index_GDN_Discussion_on_ScriptID` (`ScriptID`),
  FULLTEXT KEY `TX_Discussion` (`Name`,`Body`)
) ENGINE=MyISAM AUTO_INCREMENT=82912 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Draft`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Draft` (
  `DraftID` int(11) NOT NULL AUTO_INCREMENT,
  `DiscussionID` int(11) DEFAULT NULL,
  `CategoryID` int(11) DEFAULT NULL,
  `InsertUserID` int(11) NOT NULL,
  `UpdateUserID` int(11) NOT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Tags` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Closed` tinyint(4) NOT NULL DEFAULT 0,
  `Announce` tinyint(4) NOT NULL DEFAULT 0,
  `Sink` tinyint(4) NOT NULL DEFAULT 0,
  `Body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `Format` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`DraftID`),
  KEY `FK_Draft_DiscussionID` (`DiscussionID`),
  KEY `FK_Draft_CategoryID` (`CategoryID`),
  KEY `FK_Draft_InsertUserID` (`InsertUserID`)
) ENGINE=InnoDB AUTO_INCREMENT=110553 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Flag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Flag` (
  `DiscussionID` int(11) DEFAULT NULL,
  `InsertUserID` int(11) NOT NULL,
  `InsertName` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AuthorID` int(11) NOT NULL,
  `AuthorName` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ForeignURL` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ForeignID` int(11) NOT NULL,
  `ForeignType` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Comment` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `DateInserted` datetime NOT NULL,
  KEY `FK_Flag_InsertUserID` (`InsertUserID`),
  KEY `FK_Flag_ForeignURL` (`ForeignURL`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Invitation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Invitation` (
  `InvitationID` int(11) NOT NULL AUTO_INCREMENT,
  `Email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RoleIDs` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `InsertUserID` int(11) DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  `AcceptedUserID` int(11) DEFAULT NULL,
  `DateAccepted` datetime DEFAULT NULL,
  `DateExpires` datetime DEFAULT NULL,
  PRIMARY KEY (`InvitationID`),
  UNIQUE KEY `UX_Invitation_code` (`Code`),
  KEY `FK_Invitation_InsertUserID` (`InsertUserID`),
  KEY `IX_Invitation_Email` (`Email`),
  KEY `IX_Invitation_userdate` (`InsertUserID`,`DateInserted`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Log` (
  `LogID` int(11) NOT NULL AUTO_INCREMENT,
  `Operation` enum('Delete','Edit','Spam','Moderate','Pending','Ban','Error') COLLATE utf8mb4_unicode_ci NOT NULL,
  `RecordType` enum('Discussion','Comment','User','Registration','Activity','ActivityComment','Configuration','Group','Event') COLLATE utf8mb4_unicode_ci NOT NULL,
  `TransactionLogID` int(11) DEFAULT NULL,
  `RecordID` int(11) DEFAULT NULL,
  `RecordUserID` int(11) DEFAULT NULL,
  `RecordDate` datetime NOT NULL,
  `RecordIPAddress` varbinary(16) DEFAULT NULL,
  `InsertUserID` int(11) NOT NULL,
  `DateInserted` datetime NOT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  `OtherUserIDs` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  `ParentRecordID` int(11) DEFAULT NULL,
  `CategoryID` int(11) DEFAULT NULL,
  `Data` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CountGroup` int(11) DEFAULT NULL,
  PRIMARY KEY (`LogID`),
  KEY `IX_Log_RecordType` (`RecordType`),
  KEY `IX_Log_RecordID` (`RecordID`),
  KEY `IX_Log_RecordIPAddress` (`RecordIPAddress`),
  KEY `IX_Log_ParentRecordID` (`ParentRecordID`),
  KEY `FK_Log_CategoryID` (`CategoryID`),
  KEY `IX_Log_Operation` (`Operation`),
  KEY `IX_Log_RecordUserID` (`RecordUserID`),
  KEY `IX_Log_DateInserted` (`DateInserted`)
) ENGINE=InnoDB AUTO_INCREMENT=40054 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Media`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Media` (
  `MediaID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Type` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Size` int(11) NOT NULL,
  `Active` tinyint(4) NOT NULL DEFAULT 1,
  `ImageWidth` smallint(5) unsigned DEFAULT NULL,
  `ImageHeight` smallint(5) unsigned DEFAULT NULL,
  `ThumbWidth` smallint(5) unsigned DEFAULT NULL,
  `ThumbHeight` smallint(5) unsigned DEFAULT NULL,
  `ThumbPath` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `StorageMethod` varchar(24) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'local',
  `Path` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `InsertUserID` int(11) NOT NULL,
  `DateInserted` datetime NOT NULL,
  `ForeignID` int(11) DEFAULT NULL,
  `ForeignTable` varchar(24) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`MediaID`),
  KEY `IX_Media_Foreign` (`ForeignID`,`ForeignTable`),
  KEY `IX_Media_InsertUserID` (`InsertUserID`)
) ENGINE=InnoDB AUTO_INCREMENT=12693 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Message`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Message` (
  `MessageID` int(11) NOT NULL AUTO_INCREMENT,
  `Content` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `Format` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `AllowDismiss` tinyint(4) NOT NULL DEFAULT 1,
  `Enabled` tinyint(4) NOT NULL DEFAULT 1,
  `Application` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Controller` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Method` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CategoryID` int(11) DEFAULT NULL,
  `IncludeSubcategories` tinyint(4) NOT NULL DEFAULT 0,
  `AssetTarget` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `CssClass` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Sort` int(11) DEFAULT NULL,
  PRIMARY KEY (`MessageID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Permission` (
  `PermissionID` int(11) NOT NULL AUTO_INCREMENT,
  `RoleID` int(11) NOT NULL DEFAULT 0,
  `JunctionTable` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `JunctionColumn` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `JunctionID` int(11) DEFAULT NULL,
  `Garden.Settings.Manage` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Settings.View` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.SignIn.Allow` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Applicants.Manage` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Users.Add` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Users.Edit` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Users.Delete` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Users.Approve` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Activity.Delete` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Activity.View` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Profiles.View` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Profiles.Edit` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Moderation.Manage` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Curation.Manage` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.PersonalInfo.View` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.AdvancedNotifications.Allow` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Community.Manage` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Tokens.Add` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Uploads.Add` tinyint(4) NOT NULL DEFAULT 0,
  `Conversations.Moderation.Manage` tinyint(4) NOT NULL DEFAULT 0,
  `Conversations.Conversations.Add` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Discussions.View` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Discussions.Add` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Discussions.Edit` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Discussions.Announce` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Discussions.Sink` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Discussions.Close` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Discussions.Delete` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Comments.Add` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Comments.Edit` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Comments.Delete` tinyint(4) NOT NULL DEFAULT 0,
  `Plugins.Attachments.Upload.Allow` tinyint(4) NOT NULL DEFAULT 0,
  `Plugins.Attachments.Download.Allow` tinyint(4) NOT NULL DEFAULT 0,
  `Garden.Email.View` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Approval.Require` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Comments.Me` tinyint(4) NOT NULL DEFAULT 0,
  `Plugins.Flagging.Notify` tinyint(4) NOT NULL DEFAULT 0,
  `Vanilla.Tagging.Add` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`PermissionID`),
  KEY `FK_Permission_RoleID` (`RoleID`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Photo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Photo` (
  `PhotoID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `InsertUserID` int(11) DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  PRIMARY KEY (`PhotoID`),
  KEY `FK_Photo_InsertUserID` (`InsertUserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Regarding`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Regarding` (
  `RegardingID` int(11) NOT NULL AUTO_INCREMENT,
  `Type` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `InsertUserID` int(11) NOT NULL,
  `DateInserted` datetime NOT NULL,
  `ForeignType` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ForeignID` int(11) NOT NULL,
  `OriginalContent` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ParentType` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ParentID` int(11) DEFAULT NULL,
  `ForeignURL` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Comment` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `Reports` int(11) DEFAULT NULL,
  PRIMARY KEY (`RegardingID`),
  KEY `FK_Regarding_Type` (`Type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Role`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Role` (
  `RoleID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Type` enum('guest','unconfirmed','applicant','member','moderator','administrator') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Sort` int(11) DEFAULT NULL,
  `Deletable` tinyint(4) NOT NULL DEFAULT 1,
  `CanSession` tinyint(4) NOT NULL DEFAULT 1,
  `PersonalInfo` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`RoleID`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Session` (
  `SessionID` char(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `UserID` int(11) NOT NULL DEFAULT 0,
  `DateInserted` datetime NOT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  `DateExpires` datetime DEFAULT NULL,
  `Attributes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`SessionID`),
  KEY `IX_Session_DateExpires` (`DateExpires`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Spammer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Spammer` (
  `UserID` int(11) NOT NULL,
  `CountSpam` smallint(5) unsigned NOT NULL DEFAULT 0,
  `CountDeletedSpam` smallint(5) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_Tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_Tag` (
  `TagID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `FullName` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `ParentTagID` int(11) DEFAULT NULL,
  `InsertUserID` int(11) DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  `CategoryID` int(11) NOT NULL DEFAULT -1,
  `CountDiscussions` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`TagID`),
  UNIQUE KEY `UX_Tag` (`Name`,`CategoryID`),
  KEY `IX_Tag_Type` (`Type`),
  KEY `FK_Tag_InsertUserID` (`InsertUserID`),
  KEY `IX_Tag_FullName` (`FullName`),
  KEY `FK_Tag_ParentTagID` (`ParentTagID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_TagDiscussion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_TagDiscussion` (
  `TagID` int(11) NOT NULL,
  `DiscussionID` int(11) NOT NULL,
  `CategoryID` int(11) NOT NULL,
  `DateInserted` datetime NOT NULL,
  PRIMARY KEY (`TagID`,`DiscussionID`),
  KEY `IX_TagDiscussion_CategoryID` (`CategoryID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_User`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_User` (
  `UserID` int(11) NOT NULL AUTO_INCREMENT,
  `Name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Password` varbinary(100) NOT NULL,
  `HashMethod` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Photo` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Title` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Location` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `About` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ShowEmail` tinyint(4) NOT NULL DEFAULT 0,
  `Gender` enum('u','m','f') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'u',
  `CountVisits` int(11) NOT NULL DEFAULT 0,
  `CountInvitations` int(11) NOT NULL DEFAULT 0,
  `CountNotifications` int(11) DEFAULT NULL,
  `InviteUserID` int(11) DEFAULT NULL,
  `DiscoveryText` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Preferences` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Permissions` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Attributes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateSetInvitations` datetime DEFAULT NULL,
  `DateOfBirth` datetime DEFAULT NULL,
  `DateFirstVisit` datetime DEFAULT NULL,
  `DateLastActive` datetime DEFAULT NULL,
  `LastIPAddress` varbinary(16) DEFAULT NULL,
  `AllIPAddresses` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateInserted` datetime NOT NULL,
  `InsertIPAddress` varbinary(16) DEFAULT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  `UpdateIPAddress` varbinary(16) DEFAULT NULL,
  `HourOffset` int(11) NOT NULL DEFAULT 0,
  `Score` float DEFAULT NULL,
  `Admin` tinyint(4) NOT NULL DEFAULT 0,
  `Confirmed` tinyint(4) NOT NULL DEFAULT 1,
  `Verified` tinyint(4) NOT NULL DEFAULT 0,
  `Banned` tinyint(4) NOT NULL DEFAULT 0,
  `Deleted` tinyint(4) NOT NULL DEFAULT 0,
  `Points` int(11) NOT NULL DEFAULT 0,
  `CountUnreadConversations` int(11) DEFAULT NULL,
  `CountDiscussions` int(11) DEFAULT NULL,
  `CountUnreadDiscussions` int(11) DEFAULT NULL,
  `CountComments` int(11) DEFAULT NULL,
  `CountDrafts` int(11) DEFAULT NULL,
  `CountBookmarks` int(11) DEFAULT NULL,
  PRIMARY KEY (`UserID`),
  KEY `FK_User_Name` (`Name`),
  KEY `IX_User_Email` (`Email`),
  KEY `IX_User_DateLastActive` (`DateLastActive`),
  KEY `IX_User_DateInserted` (`DateInserted`)
) ENGINE=InnoDB AUTO_INCREMENT=145813 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserAuthentication`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserAuthentication` (
  `ForeignUserKey` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ProviderKey` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `UserID` int(11) NOT NULL,
  PRIMARY KEY (`ForeignUserKey`,`ProviderKey`),
  KEY `FK_UserAuthentication_UserID` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserAuthenticationNonce`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserAuthenticationNonce` (
  `Nonce` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Token` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`Nonce`),
  KEY `IX_UserAuthenticationNonce_Timestamp` (`Timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserAuthenticationProvider`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserAuthenticationProvider` (
  `AuthenticationKey` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `AuthenticationSchemeAlias` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Name` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `URL` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `AssociationSecret` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `AssociationHashMethod` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `AuthenticateUrl` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RegisterUrl` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `SignInUrl` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `SignOutUrl` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `PasswordUrl` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ProfileUrl` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Attributes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Active` tinyint(4) NOT NULL DEFAULT 1,
  `IsDefault` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`AuthenticationKey`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserAuthenticationToken`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserAuthenticationToken` (
  `Token` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ProviderKey` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ForeignUserKey` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `TokenSecret` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `TokenType` enum('request','access') COLLATE utf8mb4_unicode_ci NOT NULL,
  `Authorized` tinyint(4) NOT NULL,
  `Timestamp` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `Lifetime` int(11) NOT NULL,
  PRIMARY KEY (`Token`,`ProviderKey`),
  KEY `IX_UserAuthenticationToken_Timestamp` (`Timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserCategory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserCategory` (
  `UserID` int(11) NOT NULL,
  `CategoryID` int(11) NOT NULL,
  `DateMarkedRead` datetime DEFAULT NULL,
  `Followed` tinyint(4) NOT NULL DEFAULT 0,
  `Unfollow` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`UserID`,`CategoryID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserComment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserComment` (
  `UserID` int(11) NOT NULL,
  `CommentID` int(11) NOT NULL,
  `Score` float DEFAULT NULL,
  `DateLastViewed` datetime DEFAULT NULL,
  PRIMARY KEY (`UserID`,`CommentID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserConversation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserConversation` (
  `UserID` int(11) NOT NULL,
  `ConversationID` int(11) NOT NULL,
  `CountReadMessages` int(11) NOT NULL DEFAULT 0,
  `LastMessageID` int(11) DEFAULT NULL,
  `DateLastViewed` datetime DEFAULT NULL,
  `DateCleared` datetime DEFAULT NULL,
  `Bookmarked` tinyint(4) NOT NULL DEFAULT 0,
  `Deleted` tinyint(4) NOT NULL DEFAULT 0,
  `DateConversationUpdated` datetime DEFAULT NULL,
  PRIMARY KEY (`UserID`,`ConversationID`),
  KEY `FK_UserConversation_LastMessageID` (`LastMessageID`),
  KEY `IX_UserConversation_Inbox` (`UserID`,`Deleted`,`DateConversationUpdated`),
  KEY `FK_UserConversation_ConversationID` (`ConversationID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserDiscussion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserDiscussion` (
  `UserID` int(11) NOT NULL,
  `DiscussionID` int(11) NOT NULL,
  `Score` float DEFAULT NULL,
  `CountComments` int(11) NOT NULL DEFAULT 0,
  `DateLastViewed` datetime DEFAULT NULL,
  `Dismissed` tinyint(4) NOT NULL DEFAULT 0,
  `Bookmarked` tinyint(4) NOT NULL DEFAULT 0,
  `Participated` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`UserID`,`DiscussionID`),
  KEY `FK_UserDiscussion_DiscussionID` (`DiscussionID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserIP`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserIP` (
  `UserID` int(11) NOT NULL,
  `IPAddress` varbinary(16) NOT NULL,
  `DateInserted` datetime NOT NULL,
  `DateUpdated` datetime NOT NULL,
  PRIMARY KEY (`UserID`,`IPAddress`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserMerge`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserMerge` (
  `MergeID` int(11) NOT NULL AUTO_INCREMENT,
  `OldUserID` int(11) NOT NULL,
  `NewUserID` int(11) NOT NULL,
  `DateInserted` datetime NOT NULL,
  `InsertUserID` int(11) NOT NULL,
  `DateUpdated` datetime DEFAULT NULL,
  `UpdateUserID` int(11) DEFAULT NULL,
  `Attributes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`MergeID`),
  KEY `FK_UserMerge_OldUserID` (`OldUserID`),
  KEY `FK_UserMerge_NewUserID` (`NewUserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserMergeItem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserMergeItem` (
  `MergeID` int(11) NOT NULL,
  `Table` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Column` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `RecordID` int(11) NOT NULL,
  `OldUserID` int(11) NOT NULL,
  `NewUserID` int(11) NOT NULL,
  KEY `FK_UserMergeItem_MergeID` (`MergeID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserMeta`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserMeta` (
  `UserID` int(11) NOT NULL,
  `Name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `Value` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`UserID`,`Name`),
  KEY `IX_UserMeta_Name` (`Name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserPoints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserPoints` (
  `SlotType` enum('d','w','m','y','a') COLLATE utf8mb4_unicode_ci NOT NULL,
  `TimeSlot` datetime NOT NULL,
  `Source` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Total',
  `CategoryID` int(11) NOT NULL DEFAULT 0,
  `UserID` int(11) NOT NULL,
  `Points` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`SlotType`,`TimeSlot`,`Source`,`CategoryID`,`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_UserRole`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_UserRole` (
  `UserID` int(11) NOT NULL,
  `RoleID` int(11) NOT NULL,
  PRIMARY KEY (`UserID`,`RoleID`),
  KEY `IX_UserRole_RoleID` (`RoleID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_contentDraft`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_contentDraft` (
  `draftID` int(11) NOT NULL AUTO_INCREMENT,
  `recordType` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `recordID` int(11) DEFAULT NULL,
  `parentRecordID` int(11) DEFAULT NULL,
  `attributes` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `insertUserID` int(11) NOT NULL,
  `dateInserted` datetime NOT NULL,
  `updateUserID` int(11) NOT NULL,
  `dateUpdated` datetime NOT NULL,
  PRIMARY KEY (`draftID`),
  KEY `IX_contentDraft_recordType` (`recordType`),
  KEY `IX_contentDraft_insertUserID` (`insertUserID`),
  KEY `IX_contentDraft_record` (`recordType`,`recordID`),
  KEY `IX_contentDraft_parentRecord` (`recordType`,`parentRecordID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_reaction`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_reaction` (
  `reactionID` int(11) NOT NULL AUTO_INCREMENT,
  `reactionOwnerID` int(11) NOT NULL,
  `recordID` int(11) NOT NULL,
  `reactionValue` int(11) NOT NULL,
  `insertUserID` int(11) NOT NULL,
  `dateInserted` datetime NOT NULL,
  PRIMARY KEY (`reactionID`),
  KEY `IX_reaction_reactionOwnerID` (`reactionOwnerID`),
  KEY `IX_reaction_insertUserID` (`insertUserID`),
  KEY `IX_reaction_record` (`reactionOwnerID`,`recordID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `GDN_reactionOwner`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `GDN_reactionOwner` (
  `reactionOwnerID` int(11) NOT NULL AUTO_INCREMENT,
  `ownerType` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reactionType` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `recordType` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `insertUserID` int(11) NOT NULL,
  `dateInserted` datetime NOT NULL,
  PRIMARY KEY (`reactionOwnerID`),
  UNIQUE KEY `UX_reactionOwner` (`ownerType`,`reactionType`,`recordType`),
  KEY `IX_reactionOwner_ownerType` (`ownerType`),
  KEY `IX_reactionOwner_reactionType` (`reactionType`),
  KEY `IX_reactionOwner_recordType` (`recordType`),
  KEY `IX_reactionOwner_insertUserID` (`insertUserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `active_storage_attachments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `active_storage_attachments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `record_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `record_id` bigint(20) NOT NULL,
  `blob_id` bigint(20) NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_active_storage_attachments_uniqueness` (`record_type`,`record_id`,`name`,`blob_id`),
  KEY `index_active_storage_attachments_on_blob_id` (`blob_id`),
  CONSTRAINT `fk_rails_c3b3935057` FOREIGN KEY (`blob_id`) REFERENCES `active_storage_blobs` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=244154 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `active_storage_blobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `active_storage_blobs` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `filename` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `metadata` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `byte_size` bigint(20) NOT NULL,
  `checksum` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `service_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_active_storage_blobs_on_key` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=41277 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `active_storage_variant_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `active_storage_variant_records` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `blob_id` bigint(20) NOT NULL,
  `variation_digest` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_active_storage_variant_records_uniqueness` (`blob_id`,`variation_digest`),
  CONSTRAINT `fk_rails_993965df05` FOREIGN KEY (`blob_id`) REFERENCES `active_storage_blobs` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14900 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `akismet_submissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `akismet_submissions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `item_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` bigint(20) NOT NULL,
  `akismet_params` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `result_spam` tinyint(1) NOT NULL,
  `result_blatant` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_akismet_submissions_on_item_type_and_item_id` (`item_type`,`item_id`)
) ENGINE=InnoDB AUTO_INCREMENT=27552 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `allowed_requires`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `allowed_requires` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pattern` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `antifeatures`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `antifeatures` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `locale_id` int(11) DEFAULT NULL,
  `antifeature_type` int(11) NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_antifeatures_on_script_id` (`script_id`),
  KEY `index_antifeatures_on_locale_id` (`locale_id`),
  CONSTRAINT `fk_rails_c675f8b4ef` FOREIGN KEY (`locale_id`) REFERENCES `locales` (`id`),
  CONSTRAINT `fk_rails_c7c5a097dc` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=59 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ar_internal_metadata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ar_internal_metadata` (
  `key` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `value` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `author_email_notification_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `author_email_notification_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `authors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `authors` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_authors_on_script_id_and_user_id` (`script_id`,`user_id`),
  KEY `fk_rails_46e884287b` (`user_id`),
  CONSTRAINT `fk_rails_46e884287b` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_899bcb69f5` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=110750 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `banned_email_hashes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `banned_email_hashes` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `email_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `deleted_at` datetime NOT NULL,
  `banned_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_banned_email_hashes_on_email_hash` (`email_hash`)
) ENGINE=InnoDB AUTO_INCREMENT=7941 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `blocked_script_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocked_script_codes` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `pattern` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `public_reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `private_reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `serious` tinyint(1) NOT NULL DEFAULT 0,
  `originating_script_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_6f37f4eb64` (`originating_script_id`),
  CONSTRAINT `fk_rails_6f37f4eb64` FOREIGN KEY (`originating_script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=72 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `blocked_script_texts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocked_script_texts` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `text` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `public_reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `private_reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `result` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `blocked_script_urls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `blocked_script_urls` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `public_reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `private_reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prefix` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `browsers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `browsers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `discussion_id` bigint(20) NOT NULL,
  `poster_id` int(11) NOT NULL,
  `text` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `text_markup` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'html',
  `edited_at` datetime DEFAULT NULL,
  `first_comment` tinyint(1) NOT NULL DEFAULT 0,
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by_user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_comments_on_discussion_id` (`discussion_id`),
  KEY `index_comments_on_poster_id` (`poster_id`),
  CONSTRAINT `fk_rails_750d1a8a36` FOREIGN KEY (`discussion_id`) REFERENCES `discussions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=187738 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `compatibilities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `compatibilities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `browser_id` int(11) NOT NULL,
  `compatible` tinyint(1) NOT NULL,
  `comments` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_compatibilities_on_script_id` (`script_id`),
  KEY `fk_rails_d7eb310317` (`browser_id`),
  CONSTRAINT `fk_rails_94fd31c3c7` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_d7eb310317` FOREIGN KEY (`browser_id`) REFERENCES `browsers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4845 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `conversation_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conversation_subscriptions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `conversation_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_conversation_subscriptions_on_conversation_id_and_user_id` (`conversation_id`,`user_id`),
  KEY `index_conversation_subscriptions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_40481fba1d` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_b595b1fca2` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=1997 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `conversations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conversations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `stat_last_message_date` datetime DEFAULT NULL,
  `stat_last_poster_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1020 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `conversations_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `conversations_users` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `conversation_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_fa156dfe4c` (`conversation_id`),
  CONSTRAINT `fk_rails_fa156dfe4c` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2039 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `daily_install_counts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `daily_install_counts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `ip` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `install_date` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_daily_install_counts_on_script_id_and_ip` (`script_id`,`ip`)
) ENGINE=InnoDB AUTO_INCREMENT=168102119 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `daily_update_check_counts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `daily_update_check_counts` (
  `script_id` int(11) NOT NULL,
  `update_date` datetime NOT NULL,
  `ip` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  UNIQUE KEY `update_script_id_and_ip` (`script_id`,`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `disallowed_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `disallowed_attributes` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `attribute_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pattern` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `object_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `disallowed_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `disallowed_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `pattern` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `originating_script_id` int(11) DEFAULT NULL,
  `slow_ban` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=97 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `discussion_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discussion_categories` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `category_key` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `moderators_only` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `discussion_reads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discussion_reads` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `discussion_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `read_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_discussion_reads_on_user_id_and_discussion_id` (`user_id`,`discussion_id`),
  KEY `index_discussion_reads_on_discussion_id` (`discussion_id`),
  CONSTRAINT `fk_rails_07825bdb9c` FOREIGN KEY (`discussion_id`) REFERENCES `discussions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_6fafaad5e9` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=652350 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `discussion_subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discussion_subscriptions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `discussion_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_discussion_subscriptions_on_discussion_id_and_user_id` (`discussion_id`,`user_id`),
  KEY `index_discussion_subscriptions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_fa31029900` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_feaa602412` FOREIGN KEY (`discussion_id`) REFERENCES `discussions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28273 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `discussions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `discussions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `poster_id` int(11) NOT NULL,
  `script_id` int(11) DEFAULT NULL,
  `rating` int(11) DEFAULT NULL,
  `stat_reply_count` int(11) NOT NULL DEFAULT 0,
  `stat_last_reply_date` datetime DEFAULT NULL,
  `stat_last_replier_id` int(11) DEFAULT NULL,
  `migrated_from` int(11) DEFAULT NULL,
  `discussion_category_id` int(11) NOT NULL,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `deleted_by_user_id` int(11) DEFAULT NULL,
  `akismet_spam` tinyint(1) DEFAULT NULL,
  `akismet_blatant` tinyint(1) DEFAULT NULL,
  `review_reason` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `stat_first_comment_id` int(11) DEFAULT NULL,
  `locale_id` int(11) DEFAULT NULL,
  `report_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_discussions_on_poster_id` (`poster_id`),
  KEY `fk_rails_a52537835c` (`script_id`),
  KEY `index_discussions_on_stat_last_reply_date` (`stat_last_reply_date`),
  KEY `index_discussions_on_migrated_from` (`migrated_from`),
  KEY `index_discussions_on_locale_id` (`locale_id`),
  CONSTRAINT `fk_rails_a52537835c` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=77316 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `identities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `identities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `provider` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `uid` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `syncing` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_identities_on_uid_and_provider` (`uid`,`provider`),
  KEY `fk_rails_5373344100` (`user_id`),
  CONSTRAINT `fk_rails_5373344100` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=206251 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `install_counts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `install_counts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `install_date` date NOT NULL,
  `installs` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_install_counts_on_script_id_and_install_date` (`script_id`,`install_date`)
) ENGINE=InnoDB AUTO_INCREMENT=11608934 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `licenses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `licenses` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `code` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(250) COLLATE utf8mb4_unicode_ci NOT NULL,
  `url` varchar(250) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=344 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `locale_contributors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `locale_contributors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `locale_id` int(11) NOT NULL,
  `transifex_user_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_locale_contributors_on_locale_id` (`locale_id`)
) ENGINE=InnoDB AUTO_INCREMENT=454535 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `locales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `locales` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rtl` tinyint(1) NOT NULL DEFAULT 0,
  `detect_language_code` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `english_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `native_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ui_available` tinyint(1) NOT NULL DEFAULT 0,
  `percent_complete` int(11) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `localized_script_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `localized_script_attributes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `locale_id` int(11) NOT NULL,
  `attribute_key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value_markup` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `attribute_value` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `attribute_default` tinyint(1) NOT NULL,
  `sync_identifier` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sync_source_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_localized_script_attributes_on_script_id` (`script_id`),
  KEY `index_localized_script_attributes_on_locale_id` (`locale_id`)
) ENGINE=InnoDB AUTO_INCREMENT=1073000 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `localized_script_version_attributes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `localized_script_version_attributes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_version_id` int(11) NOT NULL,
  `locale_id` int(11) NOT NULL,
  `attribute_key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value_markup` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `attribute_value` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `attribute_default` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_localized_script_version_attributes_on_script_version_id` (`script_version_id`),
  KEY `index_localized_script_version_attributes_on_locale_id` (`locale_id`),
  CONSTRAINT `fk_rails_5dffd65780` FOREIGN KEY (`script_version_id`) REFERENCES `script_versions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=359573 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `mentions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `mentions` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `mentioning_item_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mentioning_item_id` bigint(20) NOT NULL,
  `user_id` int(11) NOT NULL,
  `text` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `mention_mentioning` (`mentioning_item_type`,`mentioning_item_id`,`user_id`),
  KEY `fk_rails_1b711e94aa` (`user_id`),
  CONSTRAINT `fk_rails_1b711e94aa` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1211 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `messages` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `conversation_id` bigint(20) NOT NULL,
  `poster_id` int(11) NOT NULL,
  `content` varchar(10000) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_markup` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'html',
  PRIMARY KEY (`id`),
  KEY `index_messages_on_poster_id` (`poster_id`),
  KEY `fk_rails_7f927086d2` (`conversation_id`),
  CONSTRAINT `fk_rails_7f927086d2` FOREIGN KEY (`conversation_id`) REFERENCES `conversations` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2215 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `moderator_actions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `moderator_actions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `script_id` int(11) DEFAULT NULL,
  `moderator_id` int(11) NOT NULL,
  `action` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `private_reason` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `report_id` bigint(20) DEFAULT NULL,
  `script_report_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_982b48b755` (`report_id`),
  KEY `fk_rails_de8c1b0dd2` (`script_report_id`),
  KEY `index_moderator_actions_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_982b48b755` FOREIGN KEY (`report_id`) REFERENCES `reports` (`id`) ON DELETE SET NULL,
  CONSTRAINT `fk_rails_de8c1b0dd2` FOREIGN KEY (`script_report_id`) REFERENCES `script_reports` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=46001 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `redirect_service_domains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `redirect_service_domains` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `domain` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reports` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `item_type` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `item_id` bigint(20) NOT NULL,
  `reason` varchar(25) COLLATE utf8mb4_unicode_ci NOT NULL,
  `explanation` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reporter_id` int(11) DEFAULT NULL,
  `result` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `auto_reporter` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `explanation_markup` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'html',
  `script_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reference_script_id` int(11) DEFAULT NULL,
  `rebuttal` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rebuttal_by_user_id` int(11) DEFAULT NULL,
  `moderator_notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_reports_on_item_type_and_item_id` (`item_type`,`item_id`),
  KEY `index_reports_on_reporter_id` (`reporter_id`),
  KEY `index_reports_on_result` (`result`),
  CONSTRAINT `fk_rails_c4cb6e6463` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=8048 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `roles_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles_users` (
  `user_id` int(11) NOT NULL,
  `role_id` int(11) NOT NULL,
  KEY `index_roles_users_on_user_id` (`user_id`),
  KEY `index_roles_users_on_role_id` (`role_id`),
  CONSTRAINT `fk_rails_e2a7142459` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `schema_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `schema_migrations` (
  `version` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `screenshots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `screenshots` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `screenshot_file_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `screenshot_content_type` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `screenshot_file_size` int(11) DEFAULT NULL,
  `screenshot_updated_at` datetime DEFAULT NULL,
  `caption` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=23776 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `screenshots_script_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `screenshots_script_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `screenshot_id` int(11) DEFAULT NULL,
  `script_version_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_screenshots_script_versions_on_screenshot_id` (`screenshot_id`),
  KEY `index_screenshots_script_versions_on_script_version_id` (`script_version_id`),
  CONSTRAINT `fk_rails_9fecbc9bb1` FOREIGN KEY (`script_version_id`) REFERENCES `script_versions` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=212878 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_applies_tos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_applies_tos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `site_application_id` int(11) NOT NULL,
  `tld_extra` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_script_applies_tos_on_script_id` (`script_id`),
  CONSTRAINT `fk_script_applies_tos_script_id` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=833806 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_applies_tos_bak`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_applies_tos_bak` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `text` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `domain` tinyint(1) NOT NULL,
  `tld_extra` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_script_applies_tos_on_script_id` (`script_id`)
) ENGINE=InnoDB AUTO_INCREMENT=574023 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `code_hash` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_script_codes_on_code_hash` (`code_hash`)
) ENGINE=InnoDB AUTO_INCREMENT=1035968 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=COMPRESSED;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_delete_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_delete_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_invitations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_invitations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `invited_user_id` int(11) NOT NULL,
  `expires_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_rails_f52d98b0ef` (`script_id`),
  KEY `fk_rails_55c05503c1` (`invited_user_id`),
  CONSTRAINT `fk_rails_55c05503c1` FOREIGN KEY (`invited_user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_f52d98b0ef` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=313 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_reports`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_reports` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `created_at` datetime NOT NULL,
  `script_id` int(11) NOT NULL,
  `reference_script_id` int(11) DEFAULT NULL,
  `details` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `additional_info` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rebuttal` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `report_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `reporter_id` int(11) DEFAULT NULL,
  `result` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `moderator_note` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `auto_reporter` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_script_reports_on_script_id` (`script_id`),
  KEY `index_script_reports_on_reference_script_id` (`reference_script_id`),
  KEY `fk_rails_8cb0f3e455` (`reporter_id`),
  CONSTRAINT `fk_rails_6107f26e1e` FOREIGN KEY (`reference_script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_70bdd3688c` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_8cb0f3e455` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=7084 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_set_automatic_set_inclusions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_set_automatic_set_inclusions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) NOT NULL,
  `script_set_automatic_type_id` int(11) NOT NULL,
  `value` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `exclusion` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_script_set_automatic_set_inclusions_on_parent_id` (`parent_id`),
  KEY `ssasi_script_set_automatic_type_id` (`script_set_automatic_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=9187 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_set_automatic_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_set_automatic_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_set_script_inclusions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_set_script_inclusions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) NOT NULL,
  `child_id` int(11) NOT NULL,
  `exclusion` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_script_set_script_inclusions_on_parent_id` (`parent_id`),
  KEY `index_script_set_script_inclusions_on_child_id` (`child_id`)
) ENGINE=InnoDB AUTO_INCREMENT=425979 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_set_set_inclusions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_set_set_inclusions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parent_id` int(11) NOT NULL,
  `child_id` int(11) NOT NULL,
  `exclusion` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_script_set_set_inclusions_on_parent_id` (`parent_id`),
  KEY `index_script_set_set_inclusions_on_child_id` (`child_id`)
) ENGINE=InnoDB AUTO_INCREMENT=479 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_sets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_sets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `favorite` tinyint(1) NOT NULL DEFAULT 0,
  `default_sort` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_script_sets_on_user_id` (`user_id`),
  CONSTRAINT `fk_rails_faace970e1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=446297 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_similarities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_similarities` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `other_script_id` int(11) NOT NULL,
  `similarity` decimal(4,3) NOT NULL,
  `checked_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_script_similarities_on_script_id_and_other_script_id` (`script_id`,`other_script_id`),
  KEY `fk_rails_3fba862a5b` (`other_script_id`),
  CONSTRAINT `fk_rails_3fba862a5b` FOREIGN KEY (`other_script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_rails_a0ca33ef1d` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=39424601 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_sync_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_sync_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_types` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `short_name` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `script_versions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `script_versions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `changelog` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `changelog_markup` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'text',
  `version` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `script_code_id` int(11) NOT NULL,
  `rewritten_script_code_id` int(11) NOT NULL,
  `not_js_convertible_override` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_script_versions_on_script_id` (`script_id`),
  KEY `index_script_versions_on_script_code_id` (`script_code_id`),
  KEY `index_script_versions_on_rewritten_script_code_id` (`rewritten_script_code_id`),
  CONSTRAINT `fk_script_versions_script_id` FOREIGN KEY (`script_id`) REFERENCES `scripts` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=905623 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `scripts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `scripts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `daily_installs` int(11) NOT NULL DEFAULT 0,
  `total_installs` int(11) NOT NULL DEFAULT 0,
  `code_updated_at` datetime NOT NULL,
  `script_type_id` int(11) NOT NULL DEFAULT 1,
  `script_sync_type_id` int(11) DEFAULT NULL,
  `script_sync_source_id` int(11) DEFAULT NULL,
  `sync_identifier` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sync_error` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_attempted_sync_date` datetime DEFAULT NULL,
  `last_successful_sync_date` datetime DEFAULT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT 1,
  `license_text` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `license_id` int(11) DEFAULT NULL,
  `script_delete_type_id` int(11) DEFAULT NULL,
  `locked` tinyint(1) NOT NULL DEFAULT 0,
  `support_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `locale_id` int(11) DEFAULT NULL,
  `fan_score` decimal(3,1) NOT NULL DEFAULT 0.0,
  `namespace` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `delete_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contribution_url` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contribution_amount` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `default_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `good_ratings` int(11) DEFAULT 0,
  `ok_ratings` int(11) DEFAULT 0,
  `bad_ratings` int(11) DEFAULT 0,
  `replaced_by_script_id` int(11) DEFAULT NULL,
  `version` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sensitive` tinyint(1) NOT NULL DEFAULT 0,
  `not_adult_content_self_report_date` datetime DEFAULT NULL,
  `permanent_deletion_request_date` datetime DEFAULT NULL,
  `promoted` tinyint(1) NOT NULL DEFAULT 0,
  `promoted_script_id` int(11) DEFAULT NULL,
  `adsense_approved` tinyint(1) DEFAULT NULL,
  `page_views` int(11) NOT NULL DEFAULT 0,
  `has_syntax_error` tinyint(1) NOT NULL DEFAULT 0,
  `language` varchar(3) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'js',
  `css_convertible_to_js` tinyint(1) NOT NULL DEFAULT 0,
  `not_js_convertible_override` tinyint(1) NOT NULL DEFAULT 0,
  `review_state` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'not_required',
  `deleted_at` datetime DEFAULT NULL,
  `consecutive_bad_ratings_at` datetime DEFAULT NULL,
  `marked_adult_by_user_id` int(11) DEFAULT NULL,
  `self_deleted` tinyint(1) NOT NULL DEFAULT 0,
  `sync_attempt_count` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `index_scripts_on_delta` (`delta`),
  KEY `index_scripts_on_script_delete_type_id` (`script_delete_type_id`),
  KEY `index_scripts_on_script_type_id` (`script_type_id`),
  KEY `fk_rails_f98f8b875c` (`promoted_script_id`),
  KEY `index_scripts_on_promoted` (`promoted`),
  KEY `index_scripts_on_review_state` (`review_state`),
  CONSTRAINT `fk_rails_f98f8b875c` FOREIGN KEY (`promoted_script_id`) REFERENCES `scripts` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=422455 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sensitive_sites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sensitive_sites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_sensitive_sites_on_domain` (`domain`)
) ENGINE=InnoDB AUTO_INCREMENT=326 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `site_applications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `site_applications` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `text` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `domain` tinyint(1) NOT NULL,
  `blocked` tinyint(1) NOT NULL DEFAULT 0,
  `blocked_message` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=57569 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `spammy_email_domains`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `spammy_email_domains` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `domain` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `block_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_spammy_email_domains_on_domain` (`domain`)
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `syntax_highlighted_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `syntax_highlighted_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `html` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_syntax_highlighted_codes_on_script_id` (`script_id`)
) ENGINE=InnoDB AUTO_INCREMENT=376096 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `test_update_counts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `test_update_counts` (
  `script_id` int(11) NOT NULL,
  `update_date` datetime NOT NULL,
  `ip` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  UNIQUE KEY `update_script_id_and_ip` (`script_id`,`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `update_check_counts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `update_check_counts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `script_id` int(11) NOT NULL,
  `update_check_date` date NOT NULL,
  `update_checks` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_update_check_counts_on_script_id_and_update_check_date` (`script_id`,`update_check_date`)
) ENGINE=InnoDB AUTO_INCREMENT=41390608 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `encrypted_password` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT '',
  `reset_password_token` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `reset_password_sent_at` datetime DEFAULT NULL,
  `remember_created_at` datetime DEFAULT NULL,
  `sign_in_count` int(11) NOT NULL DEFAULT 0,
  `current_sign_in_at` datetime DEFAULT NULL,
  `last_sign_in_at` datetime DEFAULT NULL,
  `current_sign_in_ip` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_sign_in_ip` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `profile` varchar(10000) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `profile_markup` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'html',
  `webhook_secret` varchar(128) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `author_email_notification_type_id` int(11) NOT NULL DEFAULT 1,
  `remember_token` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `locale_id` int(11) DEFAULT NULL,
  `show_ads` tinyint(1) NOT NULL DEFAULT 1,
  `preferred_markup` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'html',
  `show_sensitive` tinyint(1) DEFAULT 0,
  `delete_confirmation_key` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `delete_confirmation_expiry` datetime DEFAULT NULL,
  `confirmation_token` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `confirmed_at` datetime DEFAULT NULL,
  `confirmation_sent_at` datetime DEFAULT NULL,
  `unconfirmed_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `disposable_email` tinyint(1) DEFAULT NULL,
  `trusted_reports` tinyint(1) NOT NULL DEFAULT 0,
  `announcements_seen` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `canonical_email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `discussions_read_since` datetime DEFAULT NULL,
  `subscribe_on_discussion` tinyint(1) NOT NULL DEFAULT 1,
  `subscribe_on_comment` tinyint(1) NOT NULL DEFAULT 1,
  `subscribe_on_conversation_starter` tinyint(1) NOT NULL DEFAULT 1,
  `subscribe_on_conversation_receiver` tinyint(1) NOT NULL DEFAULT 1,
  `banned_at` datetime DEFAULT NULL,
  `email_domain` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `session_token` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `filter_locale_default` tinyint(1) NOT NULL DEFAULT 1,
  `notify_on_mention` tinyint(1) NOT NULL DEFAULT 0,
  `stats_script_count` int(11) NOT NULL DEFAULT 0,
  `stats_script_total_installs` int(11) NOT NULL DEFAULT 0,
  `stats_script_daily_installs` int(11) NOT NULL DEFAULT 0,
  `stats_script_fan_score` decimal(6,1) NOT NULL DEFAULT 0.0,
  `stats_script_ratings` int(11) NOT NULL DEFAULT 0,
  `stats_script_last_created` datetime DEFAULT NULL,
  `stats_script_last_updated` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_email` (`email`),
  UNIQUE KEY `index_users_on_name` (`name`),
  UNIQUE KEY `index_users_on_reset_password_token` (`reset_password_token`),
  UNIQUE KEY `index_users_on_confirmation_token` (`confirmation_token`),
  UNIQUE KEY `index_users_on_remember_token` (`remember_token`),
  KEY `index_users_on_canonical_email` (`canonical_email`),
  KEY `index_users_on_email_domain_and_current_sign_in_ip_and_banned_at` (`email_domain`,`current_sign_in_ip`,`banned_at`)
) ENGINE=InnoDB AUTO_INCREMENT=742244 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

INSERT INTO `schema_migrations` (version) VALUES
('20140210194333'),
('20140210201355'),
('20140210210818'),
('20140212200545'),
('20140213030915'),
('20140213154328'),
('20140218015725'),
('20140218035558'),
('20140218044928'),
('20140222031705'),
('20140223211028'),
('20140223211251'),
('20140224024436'),
('20140224190926'),
('20140228202404'),
('20140301023544'),
('20140303205828'),
('20140309034738'),
('20140312161418'),
('20140403164807'),
('20140403165132'),
('20140427175448'),
('20140427181626'),
('20140427190525'),
('20140516191703'),
('20140517030310'),
('20140517030415'),
('20140517032450'),
('20140527020017'),
('20140527025707'),
('20140603174709'),
('20140603181415'),
('20140603201729'),
('20140606195925'),
('20140607025106'),
('20140607211930'),
('20140609024421'),
('20140630020229'),
('20140630170345'),
('20140701173021'),
('20140708163921'),
('20140713032842'),
('20140714161558'),
('20140730161636'),
('20140730210516'),
('20140804220508'),
('20140805184624'),
('20140806021501'),
('20140812164821'),
('20140813034638'),
('20140902024802'),
('20140902025842'),
('20140903045757'),
('20140915144425'),
('20140919234605'),
('20140923191610'),
('20140929194450'),
('20140930020648'),
('20141009170654'),
('20141010195747'),
('20141022153200'),
('20141022182214'),
('20141023152338'),
('20141027032358'),
('20141028182853'),
('20141029230333'),
('20141104035027'),
('20141105153539'),
('20141110212050'),
('20141111001158'),
('20141124211518'),
('20141130174613'),
('20141212034724'),
('20141228021319'),
('20141229190455'),
('20141231195332'),
('20141231212718'),
('20150119041433'),
('20150127001642'),
('20150131052722'),
('20150211170950'),
('20150221013413'),
('20150307234007'),
('20150316170754'),
('20150422175935'),
('20150506143413'),
('20150517190053'),
('20150518042510'),
('20150609015435'),
('20150729023212'),
('20150805015952'),
('20150810231014'),
('20150906031141'),
('20150910005124'),
('20150929023046'),
('20161106004629'),
('20161218203329'),
('20170109030916'),
('20170109233217'),
('20170317235450'),
('20171014004054'),
('20171209214548'),
('20171223173317'),
('20180203220802'),
('20180222031153'),
('20180506054543'),
('20180506151937'),
('20180519011340'),
('20180531002815'),
('20180603023711'),
('20180622231059'),
('20181110222109'),
('20190131020341'),
('20190131022248'),
('20190302205639'),
('20190302205715'),
('20190303012524'),
('20190316005137'),
('20190317022326'),
('20190323211921'),
('20190330015535'),
('20190331213941'),
('20190519231037'),
('20190520005220'),
('20190706015520'),
('20190706020932'),
('20190706021911'),
('20190706022139'),
('20190714021359'),
('20190714234716'),
('20190902205455'),
('20190910235346'),
('20191002004430'),
('20191002005748'),
('20191013004547'),
('20191118025439'),
('20191118031654'),
('20191207032221'),
('20191220163134'),
('20191225180112'),
('20191225180515'),
('20191226213624'),
('20191226220007'),
('20191228011034'),
('20200101005408'),
('20200101013842'),
('20200101030644'),
('20200101203938'),
('20200103021449'),
('20200104202749'),
('20200106011534'),
('20200112155750'),
('20200112162130'),
('20200122030130'),
('20200216204021'),
('20200222033044'),
('20200308010644'),
('20200308024143'),
('20200308042042'),
('20200308042133'),
('20200310225042'),
('20200314010547'),
('20200315221243'),
('20200315221318'),
('20200316000339'),
('20200404022305'),
('20200412164034'),
('20200501203543'),
('20200501204556'),
('20200502005533'),
('20200504010752'),
('20200510183902'),
('20200512022035'),
('20200514004501'),
('20200601021359'),
('20200604020122'),
('20200605225727'),
('20200606184728'),
('20200607012451'),
('20200630024246'),
('20200630025057'),
('20200630025140'),
('20200630025619'),
('20200630025650'),
('20200630025853'),
('20200701171225'),
('20200701175829'),
('20200706015413'),
('20200706015446'),
('20200706015815'),
('20200715013441'),
('20200730003009'),
('20200804032917'),
('20200806021345'),
('20200812003620'),
('20200812232744'),
('20200814215855'),
('20200815014738'),
('20200815014922'),
('20200815020841'),
('20200818014737'),
('20200818021213'),
('20200823013703'),
('20200824013239'),
('20200828200844'),
('20200907200035'),
('20200907200130'),
('20200910021353'),
('20200910021433'),
('20200910023621'),
('20200912211814'),
('20200918221428'),
('20200919012810'),
('20201019005046'),
('20201021010617'),
('20201026003811'),
('20201026004235'),
('20201027010717'),
('20201031192108'),
('20201105015427'),
('20201108022746'),
('20201108034727'),
('20201108041036'),
('20201124014943'),
('20201129210520'),
('20201212204837'),
('20201212204838'),
('20201220200700'),
('20201220204528'),
('20201228020920'),
('20201230012028'),
('20210109202918'),
('20210123022226'),
('20210123022257'),
('20210213213755'),
('20210213222917'),
('20210214165054'),
('20210214193805'),
('20210216014727'),
('20210221225945'),
('20210221233018'),
('20210222030536'),
('20210223233743'),
('20210228215935'),
('20210301011817'),
('20210303004355'),
('20210425201410'),
('20210506145933'),
('20210506151411'),
('20210520013942'),
('20210606234319');


