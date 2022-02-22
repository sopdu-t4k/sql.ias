DROP DATABASE IF EXISTS ias;
CREATE DATABASE ias;
USE ias;

DROP TABLE IF EXISTS org_group;
CREATE TABLE org_group (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
    name VARCHAR(255) NOT NULL,
    abbrev VARCHAR(100),
    parent_org_group INT UNSIGNED,
    FOREIGN KEY (parent_org_group) REFERENCES org_group(id) ON UPDATE NO ACTION ON DELETE NO ACTION
);

DROP TABLE IF EXISTS organizations;
CREATE TABLE organizations (
	id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    org_group_id INT UNSIGNED,
    is_active TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    FOREIGN KEY (org_group_id) REFERENCES org_group(id) ON UPDATE CASCADE ON DELETE SET NULL
);

DROP TABLE IF EXISTS users;
CREATE TABLE users (
	id SERIAL PRIMARY KEY,
    login VARCHAR(100) NOT NULL UNIQUE,
    password_hash varchar(100),
    firstname VARCHAR(100),
    lastname VARCHAR(100),
    email VARCHAR(100),
    phone BIGINT,
    org_id BIGINT UNSIGNED,
    is_admin TINYINT(1) UNSIGNED NOT NULL DEFAULT 0,
    is_active TINYINT(1) UNSIGNED NOT NULL DEFAULT 1,
    FOREIGN KEY (org_id) REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX users_login_idx(login)
);

DROP TABLE IF EXISTS parameters;
CREATE TABLE parameters (
	id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    unit VARCHAR(45),
    sequence INT DEFAULT 0,
    is_active TINYINT(1) UNSIGNED NOT NULL DEFAULT 1
);

DROP TABLE IF EXISTS fields;
CREATE TABLE fields (
	id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type ENUM('number', 'date', 'checkbox', 'text') DEFAULT NULL,
    unit VARCHAR(45),
    min_val BIGINT UNSIGNED,
    max_val BIGINT UNSIGNED,
    is_active TINYINT(1) UNSIGNED NOT NULL DEFAULT 1
);

DROP TABLE IF EXISTS structure;
CREATE TABLE structure (
	param_id BIGINT UNSIGNED NOT NULL,
	field_id BIGINT UNSIGNED NOT NULL,
    sequence INT DEFAULT 0,
	PRIMARY KEY (param_id, field_id),
    FOREIGN KEY (param_id) REFERENCES parameters(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (field_id) REFERENCES fields(id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS statuses;
CREATE TABLE statuses (
	id INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
    name VARCHAR(255) NOT NULL
);

DROP TABLE IF EXISTS forms;
CREATE TABLE forms (
	id SERIAL PRIMARY KEY,
    org_id BIGINT UNSIGNED NOT NULL,
    status_id INT UNSIGNED,
    `quarter` TINYINT(1) UNSIGNED NOT NULL,
    `year` YEAR NOT NULL,
    created_at DATETIME DEFAULT NOW(),
    UNIQUE (org_id, `quarter`, `year`),
    FOREIGN KEY (org_id) REFERENCES organizations(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES statuses(id) ON UPDATE CASCADE ON DELETE SET NULL,
    INDEX forms_org_id_idx(org_id)
);

DROP TABLE IF EXISTS fields_values;
CREATE TABLE fields_values (
	form_id BIGINT UNSIGNED NOT NULL,
	field_id BIGINT UNSIGNED NOT NULL,
    `value` VARCHAR(255) NOT NULL,
    PRIMARY KEY (form_id, field_id),
    FOREIGN KEY (form_id) REFERENCES forms(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (field_id) REFERENCES fields(id) ON UPDATE CASCADE ON DELETE CASCADE
);

DROP TABLE IF EXISTS status_history;
CREATE TABLE status_history (
	form_id BIGINT UNSIGNED NOT NULL,
    status_id INT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED,
    created_at DATETIME DEFAULT NOW(),
    PRIMARY KEY (form_id, status_id, created_at),
    FOREIGN KEY (form_id) REFERENCES forms(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (status_id) REFERENCES statuses(id) ON UPDATE CASCADE ON DELETE NO ACTION,
    FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE SET NULL
);
