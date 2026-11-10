-- ============================================================
-- E-Commerce Analytics Platform
-- Database: MySQL 8.0+
-- Script: 01_create_database.sql
-- Dataset: Brazilian E-Commerce Public Dataset by Olist
-- Description: Creates the database schema with utf8mb4 encoding
-- ============================================================

DROP DATABASE IF EXISTS ecommerce_analytics;

CREATE DATABASE ecommerce_analytics
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE ecommerce_analytics;

SELECT 'Database ecommerce_analytics created successfully.' AS status;
