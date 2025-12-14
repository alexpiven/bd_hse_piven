-- =====================================================
-- Создание базы данных для судебной системы
-- =====================================================

-- Создание базы данных
CREATE DATABASE IF NOT EXISTS court_system
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE court_system;

-- =====================================================
-- Таблица: Судебные округа
-- =====================================================
CREATE TABLE judicial_districts (
    district_id INT PRIMARY KEY AUTO_INCREMENT,
    district_name VARCHAR(255) NOT NULL UNIQUE,
    region VARCHAR(255) NOT NULL,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_district_name CHECK (LENGTH(TRIM(district_name)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Категории дел
-- =====================================================
CREATE TABLE case_categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_category_name CHECK (LENGTH(TRIM(category_name)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Физические лица (участники процесса)
-- =====================================================
CREATE TABLE individuals (
    individual_id INT PRIMARY KEY AUTO_INCREMENT,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    passport_series VARCHAR(10),
    passport_number VARCHAR(20),
    phone VARCHAR(20),
    email VARCHAR(255),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_birth_date CHECK (date_of_birth <= CURDATE()),
    CONSTRAINT chk_email_format CHECK (email IS NULL OR email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_passport_unique UNIQUE (passport_series, passport_number),
    INDEX idx_name (last_name, first_name, middle_name),
    INDEX idx_passport (passport_series, passport_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Юридические лица
-- =====================================================
CREATE TABLE legal_entities (
    legal_entity_id INT PRIMARY KEY AUTO_INCREMENT,
    company_name VARCHAR(255) NOT NULL,
    inn VARCHAR(20) UNIQUE,
    ogrn VARCHAR(20),
    legal_address TEXT,
    actual_address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    director_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_inn_format CHECK (inn IS NULL OR LENGTH(inn) IN (10, 12)),
    CONSTRAINT chk_email_format CHECK (email IS NULL OR email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    INDEX idx_company_name (company_name),
    INDEX idx_inn (inn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Судьи
-- =====================================================
CREATE TABLE judges (
    judge_id INT PRIMARY KEY AUTO_INCREMENT,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    judge_number VARCHAR(50) UNIQUE,
    district_id INT NOT NULL,
    position VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(255),
    hire_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_judge_birth_date CHECK (date_of_birth <= CURDATE()),
    CONSTRAINT chk_judge_hire_date CHECK (hire_date <= CURDATE()),
    CONSTRAINT chk_judge_email_format CHECK (email IS NULL OR email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT fk_judge_district FOREIGN KEY (district_id) 
        REFERENCES judicial_districts(district_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_judge_name (last_name, first_name, middle_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Судебные дела
-- =====================================================
CREATE TABLE court_cases (
    case_id INT PRIMARY KEY AUTO_INCREMENT,
    case_number VARCHAR(100) NOT NULL UNIQUE,
    category_id INT NOT NULL,
    judge_id INT NOT NULL,
    district_id INT NOT NULL,
    case_description TEXT,
    filing_date DATE NOT NULL,
    start_date DATE,
    end_date DATE,
    status ENUM('pending', 'in_progress', 'completed', 'closed', 'dismissed') 
        DEFAULT 'pending' NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_filing_date CHECK (filing_date <= CURDATE()),
    CONSTRAINT chk_start_date CHECK (start_date IS NULL OR start_date >= filing_date),
    CONSTRAINT chk_end_date CHECK (
        end_date IS NULL OR 
        (start_date IS NOT NULL AND end_date >= start_date) OR
        (start_date IS NULL AND end_date >= filing_date)
    ),
    CONSTRAINT fk_case_category FOREIGN KEY (category_id) 
        REFERENCES case_categories(category_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_case_judge FOREIGN KEY (judge_id) 
        REFERENCES judges(judge_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_case_district FOREIGN KEY (district_id) 
        REFERENCES judicial_districts(district_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_case_number (case_number),
    INDEX idx_case_status (status),
    INDEX idx_case_dates (filing_date, start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Роли участников в делах
-- =====================================================
CREATE TABLE participant_roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    CONSTRAINT chk_role_name CHECK (role_name IN ('истец', 'ответчик', 'адвокат', 'третье_лицо', 'свидетель'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Участники дел (связь дел с физическими лицами)
-- =====================================================
CREATE TABLE case_participants_individuals (
    participation_id INT PRIMARY KEY AUTO_INCREMENT,
    case_id INT NOT NULL,
    individual_id INT NOT NULL,
    role_id INT NOT NULL,
    joined_date DATE NOT NULL DEFAULT (CURDATE()),
    notes TEXT,
    CONSTRAINT chk_joined_date CHECK (joined_date <= CURDATE()),
    CONSTRAINT fk_participant_case FOREIGN KEY (case_id) 
        REFERENCES court_cases(case_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_participant_individual FOREIGN KEY (individual_id) 
        REFERENCES individuals(individual_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_participant_role FOREIGN KEY (role_id) 
        REFERENCES participant_roles(role_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uk_case_individual_role UNIQUE (case_id, individual_id, role_id),
    INDEX idx_participant_individual (individual_id),
    INDEX idx_participant_case (case_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Участники дел (связь дел с юридическими лицами)
-- =====================================================
CREATE TABLE case_participants_legal_entities (
    participation_id INT PRIMARY KEY AUTO_INCREMENT,
    case_id INT NOT NULL,
    legal_entity_id INT NOT NULL,
    role_id INT NOT NULL,
    joined_date DATE NOT NULL DEFAULT (CURDATE()),
    notes TEXT,
    CONSTRAINT chk_legal_joined_date CHECK (joined_date <= CURDATE()),
    CONSTRAINT fk_legal_participant_case FOREIGN KEY (case_id) 
        REFERENCES court_cases(case_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_legal_participant_entity FOREIGN KEY (legal_entity_id) 
        REFERENCES legal_entities(legal_entity_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_legal_participant_role FOREIGN KEY (role_id) 
        REFERENCES participant_roles(role_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uk_legal_case_entity_role UNIQUE (case_id, legal_entity_id, role_id),
    INDEX idx_legal_participant_entity (legal_entity_id),
    INDEX idx_legal_participant_case (case_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Судебные документы
-- =====================================================
CREATE TABLE court_documents (
    document_id INT PRIMARY KEY AUTO_INCREMENT,
    case_id INT NOT NULL,
    document_number VARCHAR(100) NOT NULL,
    document_type VARCHAR(100) NOT NULL,
    judge_id INT NOT NULL,
    issue_date DATE NOT NULL,
    decision_type ENUM('positive', 'negative', 'partial', 'dismissed', 'other') 
        NOT NULL,
    decision_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_document_date CHECK (issue_date <= CURDATE()),
    CONSTRAINT fk_document_case FOREIGN KEY (case_id) 
        REFERENCES court_cases(case_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_document_judge FOREIGN KEY (judge_id) 
        REFERENCES judges(judge_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uk_case_document_number UNIQUE (case_id, document_number),
    INDEX idx_document_case (case_id),
    INDEX idx_document_judge (judge_id),
    INDEX idx_document_date (issue_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- Таблица: Решения по делам
-- =====================================================
CREATE TABLE case_decisions (
    decision_id INT PRIMARY KEY AUTO_INCREMENT,
    case_id INT NOT NULL UNIQUE,
    decision_date DATE NOT NULL,
    decision_type ENUM('satisfied', 'rejected', 'partially_satisfied', 'dismissed', 'settled') 
        NOT NULL,
    decision_text TEXT,
    judge_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_decision_date CHECK (decision_date <= CURDATE()),
    CONSTRAINT fk_decision_case FOREIGN KEY (case_id) 
        REFERENCES court_cases(case_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_decision_judge FOREIGN KEY (judge_id) 
        REFERENCES judges(judge_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_decision_date (decision_date),
    INDEX idx_decision_type (decision_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

