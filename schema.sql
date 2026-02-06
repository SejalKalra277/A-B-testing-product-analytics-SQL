-- =====================================================
-- Schema for A/B Testing & Product Analytics Project
-- =====================================================

CREATE DATABASE IF NOT EXISTS ab_test_portfolio;
USE ab_test_portfolio;

-- -----------------------
-- Users table
-- -----------------------
CREATE TABLE users (
  user_id INT PRIMARY KEY,
  experiment_group VARCHAR(20) NOT NULL,
  signup_time DATETIME NOT NULL,
  country CHAR(2) NOT NULL,
  device VARCHAR(20) NOT NULL
);

-- -----------------------
-- Events table
-- -----------------------
CREATE TABLE events (
  event_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  event_type VARCHAR(30) NOT NULL,
  event_time DATETIME NOT NULL,
  CONSTRAINT fk_events_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  INDEX idx_events_user_time (user_id, event_time),
  INDEX idx_events_type_time (event_type, event_time)
);

-- -----------------------
-- Purchases table
-- -----------------------
CREATE TABLE purchases (
  purchase_id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  purchase_time DATETIME NOT NULL,
  CONSTRAINT fk_purchases_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  INDEX idx_purchases_user_time (user_id, purchase_time)
);
