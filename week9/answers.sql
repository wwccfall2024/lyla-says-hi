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
