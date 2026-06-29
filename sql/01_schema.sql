-- ============================================================
-- Codyssey 코딩 학습 플랫폼 - 스키마 생성 스크립트
-- DB: MySQL 8.4
-- 테이블: category, member, course, enrollment (4개)
-- 1:N 관계: category→course, member→enrollment, course→enrollment
-- ============================================================

DROP DATABASE IF EXISTS codyssey;
CREATE DATABASE codyssey
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE codyssey;

-- ------------------------------------------------------------
-- 1. category (강의 카테고리) - 부모 테이블
-- ------------------------------------------------------------
CREATE TABLE category (
    id          INT             NOT NULL AUTO_INCREMENT,
    name        VARCHAR(50)     NOT NULL,
    description VARCHAR(255)    NULL,
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    UNIQUE KEY uq_category_name (name)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 2. member (회원)
-- ------------------------------------------------------------
CREATE TABLE member (
    id          INT             NOT NULL AUTO_INCREMENT,
    email       VARCHAR(100)    NOT NULL,
    nickname    VARCHAR(50)     NOT NULL,
    tier        VARCHAR(20)     NOT NULL DEFAULT 'FREE',
    joined_at   DATE            NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uq_member_email (email),
    CONSTRAINT chk_member_tier CHECK (tier IN ('FREE', 'PRO', 'ENTERPRISE'))
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 3. course (강의) - category 1:N course
-- ------------------------------------------------------------
CREATE TABLE course (
    id            INT             NOT NULL AUTO_INCREMENT,
    category_id   INT             NOT NULL,
    title         VARCHAR(200)    NOT NULL,
    instructor    VARCHAR(100)    NOT NULL,
    price         DECIMAL(10, 2)  NOT NULL DEFAULT 0.00,
    level         VARCHAR(20)     NOT NULL,
    published_at  DATE            NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_course_category
        FOREIGN KEY (category_id) REFERENCES category (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_course_level CHECK (level IN ('BEGINNER', 'INTERMEDIATE', 'ADVANCED'))
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- 4. enrollment (수강 신청) - member 1:N enrollment, course 1:N enrollment
-- ------------------------------------------------------------
CREATE TABLE enrollment (
    id            INT             NOT NULL AUTO_INCREMENT,
    member_id     INT             NOT NULL,
    course_id     INT             NOT NULL,
    enrolled_at   DATETIME        NOT NULL,
    progress_pct  TINYINT         NOT NULL DEFAULT 0,
    status        VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE',
    PRIMARY KEY (id),
    UNIQUE KEY uq_enrollment_member_course (member_id, course_id),
    CONSTRAINT fk_enrollment_member
        FOREIGN KEY (member_id) REFERENCES member (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id) REFERENCES course (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT chk_enrollment_progress CHECK (progress_pct BETWEEN 0 AND 100),
    CONSTRAINT chk_enrollment_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED'))
) ENGINE=InnoDB;
