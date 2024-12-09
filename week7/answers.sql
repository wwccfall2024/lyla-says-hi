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

-- FUNCTION
CREATE FUNCTION armor_total(char_id INT UNSIGNED)
  RETURNS INT UNSIGNED
  DETERMINISTIC
  BEGIN
    DECLARE total_armor INT UNSIGNED;
    DECLARE base_armor INT UNSIGNED;
    DECLARE equipped_armor INT UNSIGNED;

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


-- PROCEDURES
CREATE PROCEDURE attack(IN id_of_char_attacked INT UNSIGNED, IN id_of_item_used INT UNSIGNED)
  BEGIN
    DECLARE total_armor INT UNSIGNED;
    DECLARE item_damage INT UNSIGNED;
    DECLARE dmg_after_armor INT UNSIGNED;
    DECLARE starting_health INT UNSIGNED;

    -- Getting the total armor value of the target
    SET total_armor = armor_total(id_of_char_attacked);

    -- Getting the damage of the item used to attack
    SELECT i.damage INTO item_damage
      FROM items i
      WHERE i.item_id = id_of_item_used;

    -- Calculating what the damage should be
    SET dmg_after_armor = item_damage - total_armor;

    -- Getting the starting health of the target
    SELECT health INTO starting_health
      FROM character_stats cs
      WHERE character_id = id_of_char_attacked;

    -- Either killing and dropping the target from the tables or reducing their health as appropriate
    IF dmg_after_armor > starting_health THEN
      DELETE FROM characters WHERE character_id = id_of_char_attacked;
    ELSEIF dmg_after_armor > 0 THEN
      UPDATE character_stats
        SET health = starting_health - dmg_after_armor
        WHERE character_id = id_of_char_attacked;
    END IF;
  END;;


CREATE PROCEDURE equip(IN inven_id INT UNSIGNED)
  BEGIN
    DECLARE char_id INT UNSIGNED;
    DECLARE itm_id INT UNSIGNED;

    -- Grabbing character_id and item_item
    SELECT i.character_id, i.item_id INTO char_id, itm_id
      FROM inventory i
      WHERE i.inventory_id = inven_id;

    -- Adding item to character's equipped equipment
    INSERT INTO equipped
      (character_id, item_id)
    VALUES
      (char_id, itm_id);

    -- Removing item from character's inventory
    DELETE FROM inventory WHERE inventory_id = inven_id;
  END;;


CREATE PROCEDURE unequip(IN equip_id INT UNSIGNED)
  BEGIN
    DECLARE char_id INT UNSIGNED;
    DECLARE itm_id INT UNSIGNED;

    -- Grabbing character_id and item_item
    SELECT e.character_id, e.item_id INTO char_id, itm_id
      FROM equipped e
      WHERE e.equipped_id = equip_id;

    -- Adding item to character's inventory
    INSERT INTO inventory
      (character_id, item_id)
    VALUES
      (char_id, itm_id);

    -- Removing item from character's equipped equipment
    DELETE FROM equipped WHERE equipped_id = equip_id;
  END;;


CREATE PROCEDURE set_winners(IN winning_team_id INT UNSIGNED)
  BEGIN
    DECLARE char_id INT UNSIGNED;
    DECLARE char_name VARCHAR(30);
    DECLARE row_not_found TINYINT DEFAULT FALSE;

    -- Creating cursor to hold the winning team's info
    DECLARE winning_team_cursor CURSOR FOR
      SELECT c.character_id, c.name
        FROM characters c
          LEFT OUTER JOIN team_members tm
            ON c.character_id = tm.character_id
          LEFT OUTER JOIN teams t
            ON tm.team_id = t.team_id
        WHERE t.team_id = winning_team_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET row_not_found = TRUE;
  
    -- Clearing table of previous winners
    DELETE FROM winners;

    -- Using cursor and loop to feed the winners into the winners table
    OPEN winning_team_cursor;
    winning_team_loop : LOOP

      FETCH winning_team_cursor INTO char_id, char_name;
      IF row_not_found THEN
        LEAVE winning_team_loop;
      END IF;

      INSERT INTO winners
        (character_id, name)
      VALUES
        (char_id, char_name);
      
    END LOOP winning_team_loop;
    CLOSE winning_team_cursor;
    
  END;;

DELIMITER ;
