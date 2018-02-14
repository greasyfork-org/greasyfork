-- Public stuff

DROP TABLE IF EXISTS greasyfork_public.allowed_requires;
CREATE TABLE greasyfork_public.allowed_requires LIKE greasyfork.allowed_requires;
INSERT INTO greasyfork_public.allowed_requires SELECT * FROM greasyfork.allowed_requires;

DROP TABLE IF EXISTS greasyfork_public.author_email_notification_types;
CREATE TABLE greasyfork_public.author_email_notification_types LIKE greasyfork.author_email_notification_types;
INSERT INTO greasyfork_public.author_email_notification_types SELECT * FROM greasyfork.author_email_notification_types;

DROP TABLE IF EXISTS greasyfork_public.browsers;
CREATE TABLE greasyfork_public.browsers LIKE greasyfork.browsers;
INSERT INTO greasyfork_public.browsers SELECT * FROM greasyfork.browsers;

DROP TABLE IF EXISTS greasyfork_public.licenses;
CREATE TABLE greasyfork_public.licenses LIKE greasyfork.licenses;
INSERT INTO greasyfork_public.licenses SELECT * FROM greasyfork.licenses;

DROP TABLE IF EXISTS greasyfork_public.locale_contributors;
CREATE TABLE greasyfork_public.locale_contributors LIKE greasyfork.locale_contributors;
INSERT INTO greasyfork_public.locale_contributors SELECT * FROM greasyfork.locale_contributors;

DROP TABLE IF EXISTS greasyfork_public.locales;
CREATE TABLE greasyfork_public.locales LIKE greasyfork.locales;
INSERT INTO greasyfork_public.locales SELECT * FROM greasyfork.locales;

DROP TABLE IF EXISTS greasyfork_public.roles;
CREATE TABLE greasyfork_public.roles LIKE greasyfork.roles;
INSERT INTO greasyfork_public.roles SELECT * FROM greasyfork.roles;

DROP TABLE IF EXISTS greasyfork_public.schema_migrations;
CREATE TABLE greasyfork_public.schema_migrations LIKE greasyfork.schema_migrations;
INSERT INTO greasyfork_public.schema_migrations SELECT * FROM greasyfork.schema_migrations;

DROP TABLE IF EXISTS greasyfork_public.script_delete_types;
CREATE TABLE greasyfork_public.script_delete_types LIKE greasyfork.script_delete_types;
INSERT INTO greasyfork_public.script_delete_types SELECT * FROM greasyfork.script_delete_types;

DROP TABLE IF EXISTS greasyfork_public.script_sync_sources;
CREATE TABLE greasyfork_public.script_sync_sources LIKE greasyfork.script_sync_sources;
INSERT INTO greasyfork_public.script_sync_sources SELECT * FROM greasyfork.script_sync_sources;

DROP TABLE IF EXISTS greasyfork_public.script_sync_types;
CREATE TABLE greasyfork_public.script_sync_types LIKE greasyfork.script_sync_types;
INSERT INTO greasyfork_public.script_sync_types SELECT * FROM greasyfork.script_sync_types;

DROP TABLE IF EXISTS greasyfork_public.script_types;
CREATE TABLE greasyfork_public.script_types LIKE greasyfork.script_types;
INSERT INTO greasyfork_public.script_types SELECT * FROM greasyfork.script_types;

-- Users

DROP TABLE IF EXISTS greasyfork_public.users;
CREATE TABLE greasyfork_public.users LIKE greasyfork.users;
INSERT INTO greasyfork_public.users (id, email, name, profile, profile_markup) SELECT id, CONCAT('user', id, '@greasyfork.invalid'), name, profile, profile_markup FROM greasyfork.users;

DROP TABLE IF EXISTS greasyfork_public.roles_users;
CREATE TABLE greasyfork_public.roles_users LIKE greasyfork.roles_users;
INSERT INTO greasyfork_public.roles_users SELECT * FROM greasyfork.roles_users;

-- Script-specific stuff

DROP TABLE IF EXISTS greasyfork_public.scripts;
CREATE TABLE greasyfork_public.scripts LIKE greasyfork.scripts;
INSERT INTO greasyfork_public.scripts (id, user_id, created_at, updated_at, daily_installs, total_installs, code_updated_at, script_type_id, license_text, license_id, support_url, locale_id, fan_score, namespace, contribution_url, contribution_amount, default_name, good_ratings, ok_ratings, bad_ratings, version) SELECT scripts.id, scripts.user_id, scripts.created_at, scripts.updated_at, scripts.daily_installs, scripts.total_installs, scripts.code_updated_at, scripts.script_type_id, scripts.license_text, scripts.license_id, scripts.support_url, scripts.locale_id, scripts.fan_score, scripts.namespace, scripts.contribution_url, scripts.contribution_amount, scripts.default_name, scripts.good_ratings, scripts.ok_ratings, scripts.bad_ratings, scripts.version FROM greasyfork.scripts JOIN greasyfork.users ON user_id = users.id WHERE (scripts.approve_redistribution OR (scripts.approve_redistribution IS NULL AND users.approve_redistribution)) AND script_delete_type_id IS NULL;

DROP TABLE IF EXISTS greasyfork_public.compatibilities;
CREATE TABLE greasyfork_public.compatibilities LIKE greasyfork.compatibilities;
INSERT INTO greasyfork_public.compatibilities SELECT compatibilities.* FROM greasyfork.compatibilities JOIN greasyfork_public.scripts ON scripts.id = script_id;

DROP TABLE IF EXISTS greasyfork_public.install_counts;
CREATE TABLE greasyfork_public.install_counts LIKE greasyfork.install_counts;
INSERT INTO greasyfork_public.install_counts SELECT install_counts.* FROM greasyfork.install_counts JOIN greasyfork_public.scripts ON scripts.id = script_id;

DROP TABLE IF EXISTS greasyfork_public.localized_script_attributes;
CREATE TABLE greasyfork_public.localized_script_attributes LIKE greasyfork.localized_script_attributes;
INSERT INTO greasyfork_public.localized_script_attributes SELECT localized_script_attributes.* FROM greasyfork.localized_script_attributes JOIN greasyfork_public.scripts ON scripts.id = script_id;

DROP TABLE IF EXISTS greasyfork_public.script_applies_tos;
CREATE TABLE greasyfork_public.script_applies_tos LIKE greasyfork.script_applies_tos;
INSERT INTO greasyfork_public.script_applies_tos SELECT greasyfork.script_applies_tos.* FROM greasyfork.script_applies_tos JOIN greasyfork_public.scripts ON scripts.id = script_id;

DROP TABLE IF EXISTS greasyfork_public.site_applications;
CREATE TABLE greasyfork_public.site_applications LIKE greasyfork.site_applications;
INSERT INTO greasyfork_public.site_applications SELECT DISTINCT greasyfork.site_applications.* FROM greasyfork.site_applications JOIN greasyfork_public.script_applies_tos ON site_application_id = site_applications.id;

DROP TABLE IF EXISTS greasyfork_public.script_versions;
CREATE TABLE greasyfork_public.script_versions LIKE greasyfork.script_versions;
INSERT INTO greasyfork_public.script_versions SELECT greasyfork.script_versions.* FROM greasyfork.script_versions JOIN greasyfork_public.scripts ON scripts.id = script_id;

DROP TABLE IF EXISTS greasyfork_public.syntax_highlighted_codes;
CREATE TABLE greasyfork_public.syntax_highlighted_codes LIKE greasyfork.syntax_highlighted_codes;
INSERT INTO greasyfork_public.syntax_highlighted_codes SELECT syntax_highlighted_codes.* FROM greasyfork.syntax_highlighted_codes JOIN greasyfork_public.scripts ON scripts.id = script_id;

DROP TABLE IF EXISTS greasyfork_public.update_check_counts;
CREATE TABLE greasyfork_public.update_check_counts LIKE greasyfork.update_check_counts;
INSERT INTO greasyfork_public.update_check_counts SELECT update_check_counts.* FROM greasyfork.update_check_counts JOIN greasyfork_public.scripts ON scripts.id = script_id;

-- Script-version-specific stuff

DROP TABLE IF EXISTS greasyfork_public.localized_script_version_attributes;
CREATE TABLE greasyfork_public.localized_script_version_attributes LIKE greasyfork.localized_script_version_attributes;
INSERT INTO greasyfork_public.localized_script_version_attributes SELECT localized_script_version_attributes.* FROM greasyfork.localized_script_version_attributes JOIN greasyfork_public.script_versions ON script_version_id = script_versions.id;

DROP TABLE IF EXISTS greasyfork_public.script_codes;
CREATE TABLE greasyfork_public.script_codes LIKE greasyfork.script_codes;
INSERT INTO greasyfork_public.script_codes SELECT DISTINCT script_codes.* FROM greasyfork.script_codes JOIN greasyfork_public.script_versions ON script_codes.id = script_code_id OR script_codes.id = rewritten_script_code_id;

DROP TABLE IF EXISTS greasyfork_public.screenshots;
CREATE TABLE greasyfork_public.screenshots LIKE greasyfork.screenshots;
INSERT INTO greasyfork_public.screenshots SELECT DISTINCT screenshots.* FROM greasyfork.screenshots JOIN greasyfork.screenshots_script_versions ON screenshot_id = screenshots.id JOIN greasyfork_public.script_versions ON script_version_id = script_versions.id;

DROP TABLE IF EXISTS greasyfork_public.screenshots_script_versions;
CREATE TABLE greasyfork_public.screenshots_script_versions LIKE greasyfork.screenshots_script_versions;
INSERT INTO greasyfork_public.screenshots_script_versions SELECT screenshots_script_versions.* FROM greasyfork.screenshots_script_versions JOIN greasyfork_public.script_versions ON script_version_id = script_versions.id;
