-- Create your tables, views, functions and procedures here!
CREATE SCHEMA social;
USE social;

-- TABLES

CREATE TABLE users (
  user_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(30) NOT NULL,
  last_name VARCHAR(30) NOT NULL,
  email VARCHAR(50) NOT NULL,
  created_on TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE sessions (
  session_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  created_on TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_on TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW(),
  CONSTRAINT sessions_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE friends (
  user_friend_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  friend_id INT UNSIGNED NOT NULL,
  CONSTRAINT friends_fk_user_id
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT friends_fk_friend_if
    FOREIGN KEY (friend_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE posts (
  post_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  created_on TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_on TIMESTAMP NOT NULL DEFAULT NOW() ON UPDATE NOW(),
  content VARCHAR(100) NOT NULL,
  CONSTRAINT posts_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE notifications (
  notification_id INT UNSIGNED PRIMARY KEY NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL,
  post_id INT UNSIGNED NOT NULL,
  CONSTRAINT notifications_fk_users
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT notifications_fk_posts
    FOREIGN KEY (post_id)
    REFERENCES posts (post_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
);

CREATE TABLE meta (
  `key` VARCHAR(30) PRIMARY KEY NOT NULL,
  value INT UNSIGNED
);

INSERT INTO meta
  (`key`, value)
VALUES
  ('last_post_id', NULL);

DELIMITER ;;

-- TRIGGERS

-- Trigger to update meta data
CREATE TRIGGER post_added
  AFTER INSERT ON posts
  FOR EACH ROW
BEGIN
  UPDATE meta SET value = NEW.post_id WHERE `key` = 'last_post_id';
END;;


-- Creates a notification for all users anytime a user is added
CREATE TRIGGER user_added
  AFTER INSERT ON users
  FOR EACH ROW
BEGIN
  DECLARE next_user_id INT UNSIGNED;
  DECLARE last_post_id INT UNSIGNED;
  DECLARE row_not_found TINYINT DEFAULT FALSE;

  -- Cursor to grab all user ids
  DECLARE all_users_ids_cursor CURSOR FOR
    SELECT user_id
      FROM users;

  DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET row_not_found = TRUE;

  -- Creating a post stating a new user has joined
  INSERT INTO posts
    (user_id, content)
  VALUES
    (NEW.user_id, CONCAT(NEW.first_name, ' ', NEW.last_name, ' just joined!'));

  -- Using the meta data to retrieve the new post's id
  SELECT value INTO last_post_id
    FROM meta WHERE `key` = 'last_post_id';

  -- Looping through each user's id and creating a notification for them for
  -- the new post about a user joining
  OPEN all_users_ids_cursor;
  all_users_loop : LOOP
    
    FETCH all_users_ids_cursor INTO next_user_id;
    IF row_not_found THEN
      LEAVE all_users_loop;
    END IF;

    INSERT INTO notifications
      (user_id, post_id)
    VALUES
      (next_user_id, last_post_id);

  END LOOP all_users_loop;
  CLOSE all_users_ids_cursor;
END;;

-- EVENTS

CREATE EVENT disconnect_inactive_sessions
  ON SCHEDULE EVERY 10 SECOND
DO
BEGIN
  DELETE FROM sessions WHERE updated_on < DATE_SUB(NOW(), INTERVAL 2 HOUR);
END;;

-- PROCEDURES

CREATE PROCEDURE add_post(IN user_id_var INT UNSIGNED, IN content_var VARCHAR(100))
BEGIN
  DECLARE next_friend_id INT UNSIGNED;
  DECLARE last_post_id INT UNSIGNED;
  DECLARE row_not_found TINYINT DEFAULT FALSE;

  -- Cursor to grab user's friend's ids
  DECLARE friend_ids_cursor CURSOR FOR
    SELECT friend_id
      FROM friends
    WHERE user_id = user_id_var;

  DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET row_not_found = TRUE;

  INSERT INTO posts
    (user_id, content)
  VALUES
    (user_id_var, content_var);

  SELECT value INTO last_post_id
    FROM meta WHERE `key` = 'last_post_id';

  OPEN friend_ids_cursor;
  friend_notification_loop : LOOP

    FETCH friend_ids_cursor INTO next_friend_id;
    IF row_not_found THEN
      LEAVE friend_notification_loop;
    END IF;

    INSERT INTO notifications
      (user_id, post_id)
    VALUES
      (next_friend_id, last_post_id);

  END LOOP friend_notification_loop;
END;;

DELIMITER ;
