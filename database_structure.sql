-- =====================================================
-- УЛУЧШЕННАЯ ВЕРСИЯ: Создание базы данных для судебной системы
-- Объединяет лучшие практики из всех вариантов
-- =====================================================

-- Создание базы данных
CREATE DATABASE IF NOT EXISTS court_system
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE court_system;

-- =====================================================
-- СПРАВОЧНИКИ (улучшено из варианта ogh)
-- =====================================================

-- Таблица: Судебные округа
CREATE TABLE judicial_districts (
    district_id INT PRIMARY KEY AUTO_INCREMENT,
    district_name VARCHAR(255) NOT NULL UNIQUE,
    region VARCHAR(255) NOT NULL,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_district_name CHECK (LENGTH(TRIM(district_name)) > 0),
    CONSTRAINT chk_district_region CHECK (LENGTH(TRIM(region)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Категории дел
CREATE TABLE case_categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_category_name CHECK (LENGTH(TRIM(category_name)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Типы документов (добавлено из варианта ogh)
CREATE TABLE document_types (
    document_type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(255) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_document_type_name CHECK (LENGTH(TRIM(type_name)) > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Роли участников
CREATE TABLE participant_roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_role_name CHECK (role_name IN ('истец', 'ответчик', 'адвокат', 'третье_лицо', 'свидетель'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- УЧАСТНИКИ ПРОЦЕССА
-- =====================================================

-- Таблица: Физические лица
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
    CONSTRAINT chk_individual_last_name CHECK (LENGTH(TRIM(last_name)) > 0),
    CONSTRAINT chk_individual_first_name CHECK (LENGTH(TRIM(first_name)) > 0),
    CONSTRAINT chk_birth_date CHECK (
        date_of_birth <= CURDATE() AND
        date_of_birth >= DATE_SUB(CURDATE(), INTERVAL 120 YEAR)
    ),
    CONSTRAINT chk_email_format CHECK (
        email IS NULL OR 
        email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
    ),
    CONSTRAINT chk_phone_format CHECK (
        phone IS NULL OR 
        phone REGEXP '^[+]?[0-9]{10,15}$'
    ),
    CONSTRAINT chk_passport_unique UNIQUE (passport_series, passport_number),
    INDEX idx_individual_name (last_name, first_name, middle_name),
    INDEX idx_individual_passport (passport_series, passport_number),
    INDEX idx_individual_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Юридические лица
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
    CONSTRAINT chk_legal_company_name CHECK (LENGTH(TRIM(company_name)) > 0),
    CONSTRAINT chk_inn_format CHECK (inn IS NULL OR LENGTH(inn) IN (10, 12)),
    CONSTRAINT chk_email_format CHECK (
        email IS NULL OR 
        email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
    ),
    CONSTRAINT chk_phone_format CHECK (
        phone IS NULL OR 
        phone REGEXP '^[+]?[0-9]{10,15}$'
    ),
    INDEX idx_legal_company_name (company_name),
    INDEX idx_legal_inn (inn)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Судьи
CREATE TABLE judges (
    judge_id INT PRIMARY KEY AUTO_INCREMENT,
    last_name VARCHAR(100) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    judge_number VARCHAR(50) UNIQUE NOT NULL,
    district_id INT NOT NULL,
    position VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(255),
    hire_date DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_judge_last_name CHECK (LENGTH(TRIM(last_name)) > 0),
    CONSTRAINT chk_judge_first_name CHECK (LENGTH(TRIM(first_name)) > 0),
    CONSTRAINT chk_judge_birth_date CHECK (
        date_of_birth <= CURDATE() AND
        date_of_birth >= DATE_SUB(CURDATE(), INTERVAL 80 YEAR)
    ),
    CONSTRAINT chk_judge_hire_date CHECK (
        hire_date <= CURDATE() AND
        hire_date >= date_of_birth
    ),
    CONSTRAINT chk_judge_email_format CHECK (
        email IS NULL OR 
        email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'
    ),
    CONSTRAINT chk_judge_phone_format CHECK (
        phone IS NULL OR 
        phone REGEXP '^[+]?[0-9]{10,15}$'
    ),
    CONSTRAINT fk_judge_district FOREIGN KEY (district_id) 
        REFERENCES judicial_districts(district_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_judge_name (last_name, first_name, middle_name),
    INDEX idx_judge_number (judge_number),
    INDEX idx_judge_district (district_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- СУДЕБНЫЕ ДЕЛА И ДОКУМЕНТЫ
-- =====================================================

-- Таблица: Судебные дела
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
    CONSTRAINT chk_case_number CHECK (LENGTH(TRIM(case_number)) > 0),
    CONSTRAINT chk_filing_date CHECK (
        filing_date <= CURDATE() AND
        filing_date >= DATE_SUB(CURDATE(), INTERVAL 50 YEAR)
    ),
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
    INDEX idx_case_category (category_id),
    INDEX idx_case_judge (judge_id),
    INDEX idx_case_district (district_id),
    INDEX idx_case_status (status),
    INDEX idx_case_dates (filing_date, start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Участники дел (физические лица)
CREATE TABLE case_participants_individuals (
    participation_id INT PRIMARY KEY AUTO_INCREMENT,
    case_id INT NOT NULL,
    individual_id INT NOT NULL,
    role_id INT NOT NULL,
    joined_date DATE NOT NULL DEFAULT (CURDATE()),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
    INDEX idx_participant_case (case_id),
    INDEX idx_participant_role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Участники дел (юридические лица)
CREATE TABLE case_participants_legal_entities (
    participation_id INT PRIMARY KEY AUTO_INCREMENT,
    case_id INT NOT NULL,
    legal_entity_id INT NOT NULL,
    role_id INT NOT NULL,
    joined_date DATE NOT NULL DEFAULT (CURDATE()),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
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
    INDEX idx_legal_participant_case (case_id),
    INDEX idx_legal_participant_role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Судебные документы (улучшено с использованием справочника)
CREATE TABLE court_documents (
    document_id INT PRIMARY KEY AUTO_INCREMENT,
    case_id INT NOT NULL,
    document_type_id INT NOT NULL,
    document_number VARCHAR(100) NOT NULL,
    judge_id INT NOT NULL,
    issue_date DATE NOT NULL,
    decision_type ENUM('positive', 'negative', 'partial', 'dismissed', 'other') 
        NOT NULL,
    decision_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_document_number CHECK (LENGTH(TRIM(document_number)) > 0),
    CONSTRAINT chk_document_date CHECK (
        issue_date <= CURDATE() AND
        issue_date >= DATE_SUB(CURDATE(), INTERVAL 50 YEAR)
    ),
    CONSTRAINT fk_document_case FOREIGN KEY (case_id) 
        REFERENCES court_cases(case_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_document_type FOREIGN KEY (document_type_id) 
        REFERENCES document_types(document_type_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_document_judge FOREIGN KEY (judge_id) 
        REFERENCES judges(judge_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uk_case_document_number UNIQUE (case_id, document_number),
    INDEX idx_document_case (case_id),
    INDEX idx_document_type (document_type_id),
    INDEX idx_document_judge (judge_id),
    INDEX idx_document_date (issue_date),
    INDEX idx_document_decision (decision_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Таблица: Решения по делам
CREATE TABLE case_decisions (
    decision_id INT PRIMARY KEY AUTO_INCREMENT,
    case_id INT NOT NULL UNIQUE,
    decision_date DATE NOT NULL,
    decision_type ENUM('satisfied', 'rejected', 'partially_satisfied', 'dismissed', 'settled') 
        NOT NULL,
    decision_text TEXT,
    judge_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_decision_date CHECK (
        decision_date <= CURDATE() AND
        decision_date >= DATE_SUB(CURDATE(), INTERVAL 50 YEAR)
    ),
    CONSTRAINT fk_decision_case FOREIGN KEY (case_id) 
        REFERENCES court_cases(case_id) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_decision_judge FOREIGN KEY (judge_id) 
        REFERENCES judges(judge_id) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_decision_case (case_id),
    INDEX idx_decision_date (decision_date),
    INDEX idx_decision_type (decision_type),
    INDEX idx_decision_judge (judge_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =====================================================
-- ТРИГГЕРЫ ДЛЯ АВТОМАТИЧЕСКОГО ОБНОВЛЕНИЯ (из варианта nbp, адаптировано для MySQL)
-- =====================================================

DELIMITER //

CREATE TRIGGER update_individuals_updated_at
BEFORE UPDATE ON individuals
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER update_legal_entities_updated_at
BEFORE UPDATE ON legal_entities
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER update_judges_updated_at
BEFORE UPDATE ON judges
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER update_court_cases_updated_at
BEFORE UPDATE ON court_cases
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

CREATE TRIGGER update_court_documents_updated_at
BEFORE UPDATE ON court_documents
FOR EACH ROW
BEGIN
    SET NEW.updated_at = CURRENT_TIMESTAMP;
END//

DELIMITER ;

