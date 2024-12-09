-- Create your tables, views, functions and procedures here!
CREATE SCHEMA destruction;
USE destruction;

-- Tables
CREATE TABLE players (
  player_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(30) NOT NULL,
  last_name VARCHAR(30) NOT NULL,
  email VARCHAR(50) NOT NULL
);

CREATE TABLE characters (
  character_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  player_id INT UNSIGNED NOT NULL,
  name VARCHAR(30) NOT NULL,
  level INT UNSIGNED NOT NULL,
  CONSTRAINT characters_fk_players
    FOREIGN KEY (player_id)
    REFERENCES players (player_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE winners (
  character_id INT UNSIGNED PRIMARY KEY NOT NULL,
  name VARCHAR(30) NOT NULL,
  CONSTRAINT winners_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE character_stats (
  character_id INT UNSIGNED PRIMARY KEY NOT NULL,
  health INT UNSIGNED NOT NULL,
  armor INT UNSIGNED NOT NULL,
  CONSTRAINT character_stats_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE teams (
  team_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  name VARCHAR(30) NOT NULL
);

CREATE TABLE team_members (
  team_member_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  team_id INT UNSIGNED NOT NULL,
  character_id INT UNSIGNED NOT NULL,
  CONSTRAINT team_members_fk_teams
    FOREIGN KEY (team_id)
    REFERENCES teams (team_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT team_members_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE items (
  item_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  name VARCHAR(30) NOT NULL,
  armor INT UNSIGNED NOT NULL,
  damage INT UNSIGNED NOT NULL
);

CREATE TABLE inventory (
  inventory_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  character_id INT UNSIGNED NOT NULL,
  item_id INT UNSIGNED NOT NULL,
  CONSTRAINT inventory_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT inventory_fk_items
    FOREIGN KEY (item_id)
    REFERENCES items (item_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE equipped (
  equipped_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  character_id INT UNSIGNED NOT NULL,
  item_id INT UNSIGNED NOT NULL,
  CONSTRAINT equipped_fk_characters
    FOREIGN KEY (character_id)
    REFERENCES characters (character_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT equipped_fk_items
    FOREIGN KEY (item_id)
    REFERENCES items (item_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

DELIMITER ;;

-- Function
CREATE FUNCTION armor_total(char_id INT UNSIGNED)
  RETURNS INT UNSIGNED
  DETERMINISTIC
  BEGIN
    DECLARE total_armor INT UNSIGNED;  -- Variable to hold the total armor value to return
    DECLARE base_armor INT UNSIGNED;   -- Variable to hold the characters base defence stat
    DECLARE equipped_armor INT UNSIGNED;  -- Variable to hold the total armor from a character's equipped items

    -- Selecting the character's armor stat into base_armor
    SELECT cs.armor INTO base_armor
      FROM characters c
        INNER JOIN character_stats cs
          ON c.character_id = cs.character_id
      WHERE c.character_id = char_id;

    -- Selecting the sum of a character's equipped item's armor into equipped_armor
    SELECT SUM(i.armor) INTO equipped_armor
      FROM characters c
        LEFT OUTER JOIN equipped e
          ON c.character_id = e.character_id
        LEFT OUTER JOIN items i
          ON i.item_id = e.item_id
      WHERE c.character_id = char_id;

    -- Checking if equipped armor is at least over 0 to prevent an instance of a character not having any equipped
    -- armor stats causing equipped_armor to equal null
    IF equipped_armor > 0 THEN
      SET total_armor = base_armor + equipped_armor;
    ELSE
      SET total_armor = base_armor;
    END IF;
      
    RETURN total_armor;
  END;;

DELIMITER ;
