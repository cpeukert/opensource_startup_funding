#standardSQL
CREATE TABLE mygithub.event_types_month_login AS
SELECT r.type, COUNT(*) AS count, _TABLE_SUFFIX AS date, l.login AS login FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login GROUP BY type, date, login;

#standardSQL
CREATE TABLE mygithub.readme_login AS
SELECT r.type, r.payload, _TABLE_SUFFIX AS date, l.login AS login FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND payload LIKE '%README.md%';

#standardSQL
CREATE TABLE mygithub.repos_month_login AS
SELECT COUNT(DISTINCT(repo.id)) AS count, _TABLE_SUFFIX AS date, l.login AS login  FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login GROUP BY date, login;

#standardSQL
CREATE TABLE mygithub.repo_activity AS
SELECT r.repo.name AS reponame, r.type, _TABLE_SUFFIX AS date, l.login AS login FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login;

#standardSQL
CREATE TABLE mygithub.external_repo_activity AS
SELECT COUNT(*) AS count, r.type AS type, _TABLE_SUFFIX AS date, l.login AS login FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND r.repo.name NOT LIKE CONCAT('%', l.login, '%') AND r.repo.name LIKE '%/%' AND r.repo.name NOT LIKE '/' GROUP BY type, date, login;

#standardSQL
CREATE TABLE mygithub.external_repo_activity_detail AS
SELECT COUNT(*) AS count, r.type AS type, _TABLE_SUFFIX AS date, l.login AS login, r.repo.name AS repo FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND r.repo.name NOT LIKE CONCAT('%', l.login, '%') AND r.repo.name LIKE '%/%' AND r.repo.name NOT LIKE '/' GROUP BY type, date, login, repo;

#standardSQL
CREATE TABLE mygithub.internal_repo_activity AS
SELECT COUNT(*) AS count, r.type AS type, _TABLE_SUFFIX AS date, l.login AS login FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND (r.repo.name LIKE CONCAT('%', l.login, '%') OR r.repo.name NOT LIKE '%/%')  GROUP BY type, date, login;

#standardSQL
CREATE TABLE mygithub.internal_repo_activity_detail AS
SELECT COUNT(*) AS count, r.type AS type, _TABLE_SUFFIX AS date, l.login AS login, r.repo.name AS repo FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND (r.repo.name LIKE CONCAT('%', l.login, '%') OR r.repo.name NOT LIKE '%/%') GROUP BY type, date, login, repo;

#standardSQL
CREATE TABLE mygithub.external_repo_activity_detail AS
SELECT COUNT(*) AS count, r.type AS type, _TABLE_SUFFIX AS date, l.login AS login, r.repo.name AS repo FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND r.repo.name NOT LIKE CONCAT('%', l.login, '%') AND r.repo.name NOT LIKE '/' GROUP BY type, date, login, repo;

#standardSQL
CREATE TABLE mygithub.external_repo_activity AS
SELECT COUNT(*) AS count, r.type AS type, _TABLE_SUFFIX AS date, l.login AS login FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND r.repo.name NOT LIKE CONCAT('%', l.login, '%') GROUP BY type, date, login;

#standardSQL
CREATE TABLE mygithub.internal_repo_activity AS
SELECT COUNT(*) AS count, r.type AS type, _TABLE_SUFFIX AS date, l.login AS login FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND r.repo.name LIKE CONCAT('%', l.login, '%') GROUP BY type, date, login;

#standardSQL
CREATE TABLE mygithub.external_repo_activity_detail AS
SELECT COUNT(*) AS count, r.type AS type, _TABLE_SUFFIX AS date, l.login AS login, r.repo.name AS repo FROM `githubarchive.month.*` r,
`mygithub.cb_match_logins` l WHERE r.actor.login=l.login AND r.repo.name NOT LIKE CONCAT('%', l.login, '%') AND r.repo.name NOT LIKE '/' GROUP BY type, date, login, repo;

