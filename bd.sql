-- ======================================================================
-- SQL-файл структуры базы данных районного суда
-- Версия: 1.0
-- Дата создания: 2025-12-15
-- Автор: Пивень Алексей
-- ======================================================================

-- 1. Установка параметров базы данных
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- 2. Создание базы данных (если не существует)
CREATE DATABASE IF NOT EXISTS `court_system_db`
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_unicode_ci;

USE `court_system_db`;

-- ======================================================================
-- РАЗДЕЛ 1: СПРАВОЧНЫЕ ТАБЛИЦЫ (DICTIONARIES)
-- ======================================================================

-- 2.1. Справочник категорий дел
CREATE TABLE IF NOT EXISTS `dict_case_categories` (
    `category_id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор категории',
    `category_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Код категории (ГПК ст. 22, УПК ст. 31)',
    `category_name` VARCHAR(200) NOT NULL COMMENT 'Наименование категории',
    `legal_basis` VARCHAR(100) COMMENT 'Правовое основание (ГПК РФ, УПК РФ и т.д.)',
    `is_active` BOOLEAN DEFAULT TRUE COMMENT 'Активность категории',
    INDEX `idx_category_code` (`category_code`),
    INDEX `idx_category_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Справочник категорий дел';

-- 2.2. Справочник статусов дел
CREATE TABLE IF NOT EXISTS `dict_case_statuses` (
    `status_id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор статуса',
    `status_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Код статуса',
    `status_name` VARCHAR(100) NOT NULL COMMENT 'Наименование статуса',
    `description` TEXT COMMENT 'Описание статуса',
    INDEX `idx_status_code` (`status_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Справочник статусов дел';

-- 2.3. Справочник ролей участников
CREATE TABLE IF NOT EXISTS `dict_roles` (
    `role_id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор роли',
    `role_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Код роли',
    `role_name` VARCHAR(100) NOT NULL COMMENT 'Наименование роли',
    INDEX `idx_role_code` (`role_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Справочник ролей участников';

-- 2.4. Справочник типов документов
CREATE TABLE IF NOT EXISTS `dict_document_types` (
    `type_id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор типа',
    `type_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Код типа документа',
    `type_name` VARCHAR(200) NOT NULL COMMENT 'Наименование типа документа',
    `document_category` ENUM('Исковое заявление', 'Решение', 'Протокол', 'Ходатайство', 'Исполнительный документ', 'Прочее') NOT NULL COMMENT 'Категория документа',
    INDEX `idx_type_code` (`type_code`),
    INDEX `idx_document_category` (`document_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Справочник типов документов';

-- 2.5. Справочник типов судебных заседаний
CREATE TABLE IF NOT EXISTS `dict_session_types` (
    `type_id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор типа',
    `type_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Код типа заседания',
    `type_name` VARCHAR(100) NOT NULL COMMENT 'Наименование типа заседания',
    INDEX `idx_session_type_code` (`type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Справочник типов судебных заседаний';

-- 2.6. Справочник статусов исполнительных документов
CREATE TABLE IF NOT EXISTS `dict_enforcement_statuses` (
    `status_id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор статуса',
    `status_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Код статуса',
    `status_name` VARCHAR(100) NOT NULL COMMENT 'Наименование статуса',
    INDEX `idx_enforcement_status_code` (`status_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Справочник статусов исполнительных документов';

-- 2.7. Справочник типов движений дел
CREATE TABLE IF NOT EXISTS `dict_movement_types` (
    `movement_type_id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор типа движения',
    `movement_type_code` VARCHAR(20) NOT NULL UNIQUE COMMENT 'Код типа движения',
    `movement_type_name` VARCHAR(100) NOT NULL COMMENT 'Наименование типа движения',
    INDEX `idx_movement_type_code` (`movement_type_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Справочник типов движений дел';

-- ======================================================================
-- РАЗДЕЛ 2: ОСНОВНЫЕ ТАБЛИЦЫ (CORE ENTITIES)
-- ======================================================================

-- 3.1. Таблица физических лиц
CREATE TABLE IF NOT EXISTS `persons` (
    `person_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор физ. лица',
    `last_name` VARCHAR(100) NOT NULL COMMENT 'Фамилия',
    `first_name` VARCHAR(100) NOT NULL COMMENT 'Имя',
    `patronymic` VARCHAR(100) COMMENT 'Отчество',
    `birth_date` DATE COMMENT 'Дата рождения',
    `birth_place` VARCHAR(255) COMMENT 'Место рождения',
    `snils` CHAR(14) UNIQUE COMMENT 'СНИЛС (формат: XXX-XXX-XXX XX)',
    `inn` VARCHAR(12) UNIQUE COMMENT 'ИНН физ. лица/ИП',
    `passport_series` VARCHAR(4) COMMENT 'Серия паспорта',
    `passport_number` VARCHAR(6) COMMENT 'Номер паспорта',
    `passport_issued_by` TEXT COMMENT 'Кем выдан паспорт',
    `passport_issue_date` DATE COMMENT 'Дата выдачи паспорта',
    `registration_address` TEXT COMMENT 'Адрес регистрации',
    `actual_address` TEXT COMMENT 'Фактический адрес проживания',
    `phone_number` VARCHAR(20) COMMENT 'Контактный телефон',
    `email` VARCHAR(255) COMMENT 'Электронная почта',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления записи',

    -- Индексы
    INDEX `idx_persons_name` (`last_name`, `first_name`, `patronymic`),
    INDEX `idx_persons_birth` (`birth_date`),
    INDEX `idx_persons_inn_snils` (`inn`, `snils`),
    INDEX `idx_persons_passport` (`passport_series`, `passport_number`),

    -- Проверочные ограничения (для MySQL 8.0.16+)
    CONSTRAINT `chk_persons_birth_date`
        CHECK (`birth_date` IS NULL OR (`birth_date` <= CURDATE() AND `birth_date` >= '1900-01-01')),
    CONSTRAINT `chk_persons_email`
        CHECK (`email` IS NULL OR `email` LIKE '%_@_%._%'),
    CONSTRAINT `chk_persons_snils`
        CHECK (`snils` IS NULL OR `snils` REGEXP '^[0-9]{3}-[0-9]{3}-[0-9]{3} [0-9]{2}$'),
    CONSTRAINT `chk_persons_inn`
        CHECK (`inn` IS NULL OR
              ((CHAR_LENGTH(`inn`) = 12 AND `inn` REGEXP '^[0-9]{12}$') OR
               (CHAR_LENGTH(`inn`) = 10 AND `inn` REGEXP '^[0-9]{10}$'))),
    CONSTRAINT `chk_persons_passport_format`
        CHECK ((`passport_series` IS NULL AND `passport_number` IS NULL) OR
              (`passport_series` IS NOT NULL AND `passport_number` IS NOT NULL AND
               `passport_series` REGEXP '^[0-9]{4}$' AND `passport_number` REGEXP '^[0-9]{6}$'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Физические лица и ИП';

-- 3.2. Таблица юридических лиц
CREATE TABLE IF NOT EXISTS `legal_entities` (
    `legal_entity_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор юр. лица',
    `full_name` TEXT NOT NULL COMMENT 'Полное наименование',
    `short_name` VARCHAR(255) COMMENT 'Сокращенное наименование',
    `inn` VARCHAR(10) NOT NULL UNIQUE COMMENT 'ИНН',
    `kpp` VARCHAR(9) COMMENT 'КПП',
    `ogrn` VARCHAR(13) COMMENT 'ОГРН/ОГРНИП',
    `legal_address` TEXT NOT NULL COMMENT 'Юридический адрес',
    `actual_address` TEXT COMMENT 'Фактический адрес',
    `director_person_id` BIGINT COMMENT 'Руководитель (ссылка на физ. лицо)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',

    -- Внешние ключи
    FOREIGN KEY (`director_person_id`)
        REFERENCES `persons`(`person_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_legal_entities_name` (`short_name`),
    INDEX `idx_legal_entities_inn` (`inn`),
    INDEX `idx_legal_entities_ogrn` (`ogrn`),

    -- Проверочные ограничения
    CONSTRAINT `chk_legal_entities_inn`
        CHECK (`inn` REGEXP '^[0-9]{10}$'),
    CONSTRAINT `chk_legal_entities_kpp`
        CHECK (`kpp` IS NULL OR `kpp` REGEXP '^[0-9]{9}$'),
    CONSTRAINT `chk_legal_entities_ogrn`
        CHECK (`ogrn` IS NULL OR
              ((CHAR_LENGTH(`ogrn`) = 13 AND `ogrn` REGEXP '^[0-9]{13}$') OR
               (CHAR_LENGTH(`ogrn`) = 15 AND `ogrn` REGEXP '^[0-9]{15}$')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Юридические лица';

-- 3.3. Таблица сотрудников суда
CREATE TABLE IF NOT EXISTS `court_staff` (
    `staff_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор сотрудника',
    `person_id` BIGINT NOT NULL UNIQUE COMMENT 'Ссылка на физ. лицо',
    `position` ENUM('Судья', 'Помощник судьи', 'Секретарь суда', 'Секретарь судебного заседания', 'Работник канцелярии', 'Архивариус', 'Председатель суда') NOT NULL COMMENT 'Должность',
    `department` VARCHAR(100) COMMENT 'Отдел/структурное подразделение',
    `judge_id` VARCHAR(50) UNIQUE COMMENT 'Служебный номер судьи',
    `is_active` BOOLEAN DEFAULT TRUE COMMENT 'Статус активности',
    `employment_date` DATE COMMENT 'Дата приема на работу',
    `termination_date` DATE COMMENT 'Дата увольнения',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',

    -- Внешние ключи
    FOREIGN KEY (`person_id`)
        REFERENCES `persons`(`person_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_court_staff_position` (`position`, `is_active`),
    INDEX `idx_court_staff_department` (`department`),
    INDEX `idx_court_staff_active` (`is_active`),

    -- Проверочные ограничения
    CONSTRAINT `chk_court_staff_judge_id`
        CHECK ((`position` = 'Судья' AND `judge_id` IS NOT NULL) OR
               (`position` != 'Судья' AND `judge_id` IS NULL)),
    CONSTRAINT `chk_court_staff_dates`
        CHECK (`employment_date` IS NULL OR
               (`employment_date` <= CURDATE() AND `employment_date` >= '2000-01-01')),
    CONSTRAINT `chk_court_staff_termination_date`
        CHECK (`termination_date` IS NULL OR
               (`termination_date` <= CURDATE() AND
                `termination_date` >= `employment_date` AND
                `termination_date` >= '2000-01-01'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Сотрудники аппарата суда и судьи';

-- 3.4. Таблица судебных дел
CREATE TABLE IF NOT EXISTS `court_cases` (
    `case_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор дела',
    `case_number` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Уникальный номер дела (например, 2-1234/2024)',
    `category_id` INT NOT NULL COMMENT 'Категория дела',
    `status_id` INT NOT NULL COMMENT 'Статус дела',
    `init_date` DATE NOT NULL COMMENT 'Дата поступления',
    `summary` TEXT COMMENT 'Краткое описание/предмет спора',
    `result` TEXT COMMENT 'Результат рассмотрения',
    `result_date` DATE COMMENT 'Дата вынесения решения',
    `instance_number` INT DEFAULT 1 COMMENT 'Номер инстанции',
    `previous_case_id` BIGINT COMMENT 'Ссылка на предыдущее дело (при апелляции)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Дата обновления записи',

    -- Внешние ключи
    FOREIGN KEY (`category_id`)
        REFERENCES `dict_case_categories`(`category_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (`status_id`)
        REFERENCES `dict_case_statuses`(`status_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (`previous_case_id`)
        REFERENCES `court_cases`(`case_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_case_number` (`case_number`),
    INDEX `idx_cases_status` (`status_id`),
    INDEX `idx_cases_category` (`category_id`),
    INDEX `idx_cases_init_date` (`init_date`),
    INDEX `idx_cases_result_date` (`result_date`),
    INDEX `idx_cases_instance` (`instance_number`),

    -- Проверочные ограничения
    CONSTRAINT `chk_court_cases_init_date`
        CHECK (`init_date` <= CURDATE() AND `init_date` >= '2000-01-01'),
    CONSTRAINT `chk_court_cases_result_date`
        CHECK (`result_date` IS NULL OR
               (`result_date` <= CURDATE() AND
                `result_date` >= `init_date` AND
                `result_date` >= '2000-01-01')),
    CONSTRAINT `chk_court_cases_instance`
        CHECK (`instance_number` >= 1 AND `instance_number` <= 3),
    CONSTRAINT `chk_court_cases_number`
        CHECK (`case_number` REGEXP '^[0-9]+-[0-9]+/[0-9]{4}(-[А-Яа-яA-Z0-9-]*)?$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Судебные дела';

-- 3.5. Таблица участников дела (связующая таблица многие-ко-многим)
CREATE TABLE IF NOT EXISTS `case_participants` (
    `participant_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор участия',
    `case_id` BIGINT NOT NULL COMMENT 'Ссылка на дело',
    `person_id` BIGINT COMMENT 'Участник - физ. лицо',
    `legal_entity_id` BIGINT COMMENT 'Участник - юр. лицо',
    `role_id` INT NOT NULL COMMENT 'Роль в деле',
    `lawyer_certificate_number` VARCHAR(100) COMMENT 'Номер удостоверения адвоката',
    `representation_basis` VARCHAR(255) COMMENT 'Основание представительства',
    `represented_participant_id` BIGINT COMMENT 'Кого представляет (для адвокатов)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',

    -- Внешние ключи
    FOREIGN KEY (`case_id`)
        REFERENCES `court_cases`(`case_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`person_id`)
        REFERENCES `persons`(`person_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`legal_entity_id`)
        REFERENCES `legal_entities`(`legal_entity_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`role_id`)
        REFERENCES `dict_roles`(`role_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (`represented_participant_id`)
        REFERENCES `case_participants`(`participant_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_case_participants_case` (`case_id`),
    INDEX `idx_case_participants_person` (`person_id`),
    INDEX `idx_case_participants_legal` (`legal_entity_id`),
    INDEX `idx_case_participants_role` (`role_id`),
    INDEX `idx_case_participants_represented` (`represented_participant_id`),
    INDEX `idx_case_participants_lawyer_cert` (`lawyer_certificate_number`),

    -- Проверочные ограничения
    CONSTRAINT `chk_case_participants_type`
        CHECK ((`person_id` IS NOT NULL AND `legal_entity_id` IS NULL) OR
               (`person_id` IS NULL AND `legal_entity_id` IS NOT NULL)),
    CONSTRAINT `chk_case_participants_representation`
        CHECK ((`role_id` IN (SELECT `role_id` FROM `dict_roles` WHERE `role_code` IN ('ADVOKAT', 'PREDST')) AND `representation_basis` IS NOT NULL) OR
               (`role_id` NOT IN (SELECT `role_id` FROM `dict_roles` WHERE `role_code` IN ('ADVOKAT', 'PREDST')) AND `representation_basis` IS NULL)),
    CONSTRAINT `chk_case_participants_lawyer_cert`
        CHECK ((`role_id` = (SELECT `role_id` FROM `dict_roles` WHERE `role_code` = 'ADVOKAT') AND `lawyer_certificate_number` IS NOT NULL) OR
               (`role_id` != (SELECT `role_id` FROM `dict_roles` WHERE `role_code` = 'ADVOKАТ') AND `lawyer_certificate_number` IS NULL))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Роли участников в конкретном деле';

-- 3.6. Таблица для связи судьи и секретаря с делом
CREATE TABLE IF NOT EXISTS `case_staff` (
    `case_staff_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор связи',
    `case_id` BIGINT NOT NULL COMMENT 'Ссылка на дело',
    `judge_participant_id` BIGINT NOT NULL COMMENT 'Председательствующий судья',
    `secretary_participant_id` BIGINT COMMENT 'Секретарь судебного заседания',
    `assignment_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата назначения',
    `is_active` BOOLEAN DEFAULT TRUE COMMENT 'Активна ли связь',

    -- Внешние ключи
    FOREIGN KEY (`case_id`)
        REFERENCES `court_cases`(`case_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`judge_participant_id`)
        REFERENCES `case_participants`(`participant_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (`secretary_participant_id`)
        REFERENCES `case_participants`(`participant_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_case_staff_case` (`case_id`),
    INDEX `idx_case_staff_judge` (`judge_participant_id`),
    INDEX `idx_case_staff_secretary` (`secretary_participant_id`),
    INDEX `idx_case_staff_active` (`is_active`),

    -- Ограничения уникальности
    UNIQUE KEY `uk_active_case_staff` (`case_id`, `is_active`) COMMENT 'Только одна активная запись на дело'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Связь судьи и секретаря с делом';

-- 3.7. Таблица судебных заседаний
CREATE TABLE IF NOT EXISTS `court_sessions` (
    `session_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор заседания',
    `case_id` BIGINT NOT NULL COMMENT 'Ссылка на дело',
    `session_date` TIMESTAMP NOT NULL COMMENT 'Дата и время начала заседания',
    `room_number` VARCHAR(20) COMMENT 'Номер зала судебного заседания',
    `session_type_id` INT COMMENT 'Тип заседания',
    `result` VARCHAR(255) COMMENT 'Результат заседания',
    `recording_link` TEXT COMMENT 'Ссылка на аудиозапись',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',

    -- Внешние ключи
    FOREIGN KEY (`case_id`)
        REFERENCES `court_cases`(`case_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`session_type_id`)
        REFERENCES `dict_session_types`(`type_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_sessions_case` (`case_id`),
    INDEX `idx_sessions_date` (`session_date`),
    INDEX `idx_sessions_room` (`room_number`),
    INDEX `idx_sessions_type` (`session_type_id`),

    -- Проверочные ограничения
    CONSTRAINT `chk_court_sessions_date`
        CHECK (`session_date` >= '2000-01-01 00:00:00')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Судебные заседания';

-- 3.8. Таблица участников конкретных заседаний
CREATE TABLE IF NOT EXISTS `session_participants` (
    `session_participant_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор участия в заседании',
    `session_id` BIGINT NOT NULL COMMENT 'Ссылка на заседание',
    `case_participant_id` BIGINT NOT NULL COMMENT 'Ссылка на участника дела',
    `is_present` BOOLEAN DEFAULT TRUE COMMENT 'Присутствовал ли участник',
    `notes` TEXT COMMENT 'Примечания по участию',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',

    -- Внешние ключи
    FOREIGN KEY (`session_id`)
        REFERENCES `court_sessions`(`session_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`case_participant_id`)
        REFERENCES `case_participants`(`participant_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_session_participants_session` (`session_id`),
    INDEX `idx_session_participants_participant` (`case_participant_id`),
    INDEX `idx_session_participants_present` (`is_present`),

    -- Ограничения уникальности
    UNIQUE KEY `uk_session_participant` (`session_id`, `case_participant_id`) COMMENT 'Уникальность участника в заседании'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Участники конкретных заседаний';

-- 3.9. Таблица документов
CREATE TABLE IF NOT EXISTS `documents` (
    `document_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор документа',
    `case_id` BIGINT NOT NULL COMMENT 'Ссылка на дело',
    `internal_number` VARCHAR(100) COMMENT 'Внутренний номер документа в деле',
    `type_id` INT NOT NULL COMMENT 'Тип документа',
    `title` VARCHAR(500) NOT NULL COMMENT 'Название документа',
    `file_path` TEXT NOT NULL COMMENT 'Путь к файлу в системе хранения',
    `file_hash` VARCHAR(64) COMMENT 'SHA-256 хеш для контроля целостности',
    `mime_type` VARCHAR(100) COMMENT 'MIME-тип файла',
    `author_participant_id` BIGINT COMMENT 'Автор/подписант документа',
    `created_date` DATE NOT NULL COMMENT 'Дата создания документа',
    `received_date` DATE COMMENT 'Дата поступления в суд',
    `description` TEXT COMMENT 'Описание документа',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',

    -- Внешние ключи
    FOREIGN KEY (`case_id`)
        REFERENCES `court_cases`(`case_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`type_id`)
        REFERENCES `dict_document_types`(`type_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (`author_participant_id`)
        REFERENCES `case_participants`(`participant_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_documents_case` (`case_id`),
    INDEX `idx_documents_type` (`type_id`),
    INDEX `idx_documents_date` (`created_date`),
    INDEX `idx_documents_internal_number` (`internal_number`),
    INDEX `idx_documents_author` (`author_participant_id`),

    -- Проверочные ограничения
    CONSTRAINT `chk_documents_created_date`
        CHECK (`created_date` <= CURDATE() AND `created_date` >= '2000-01-01'),
    CONSTRAINT `chk_documents_received_date`
        CHECK (`received_date` IS NULL OR
               (`received_date` <= CURDATE() AND
                `received_date` >= `created_date` AND
                `received_date` >= '2000-01-01')),
    CONSTRAINT `chk_documents_title`
        CHECK (CHAR_LENGTH(`title`) >= 5),
    CONSTRAINT `chk_documents_file_path`
        CHECK (`file_path` LIKE '%.pdf' OR
               `file_path` LIKE '%.doc%' OR
               `file_path` LIKE '%.xls%' OR
               `file_path` LIKE '%.jpg' OR
               `file_path` LIKE '%.png' OR
               `file_path` LIKE '%.tif')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Документы, приобщенные к делу';

-- 3.10. Таблица исполнительных документов
CREATE TABLE IF NOT EXISTS `enforcement_documents` (
    `enforcement_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор',
    `document_id` BIGINT NOT NULL COMMENT 'Ссылка на документ-основание',
    `case_id` BIGINT NOT NULL COMMENT 'Ссылка на дело',
    `enforcement_type` ENUM('Исполнительный лист', 'Судебный приказ', 'Решение') NOT NULL COMMENT 'Тип исп. документа',
    `enforcement_number` VARCHAR(100) NOT NULL COMMENT 'Номер исп. документа',
    `issue_date` DATE NOT NULL COMMENT 'Дата выдачи',
    `bailiff_sent_date` DATE COMMENT 'Дата направления приставам',
    `completion_date` DATE COMMENT 'Дата исполнения',
    `status_id` INT NOT NULL COMMENT 'Статус исполнения',
    `amount` DECIMAL(15,2) COMMENT 'Сумма к взысканию',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',

    -- Внешние ключи
    FOREIGN KEY (`document_id`)
        REFERENCES `documents`(`document_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`case_id`)
        REFERENCES `court_cases`(`case_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`status_id`)
        REFERENCES `dict_enforcement_statuses`(`status_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_enforcement_case` (`case_id`),
    INDEX `idx_enforcement_status` (`status_id`),
    INDEX `idx_enforcement_date` (`issue_date`),
    INDEX `idx_enforcement_documents_number` (`enforcement_number`),
    INDEX `idx_enforcement_type` (`enforcement_type`),

    -- Проверочные ограничения
    CONSTRAINT `chk_enforcement_issue_date`
        CHECK (`issue_date` <= CURDATE() AND `issue_date` >= '2000-01-01'),
    CONSTRAINT `chk_enforcement_sent_date`
        CHECK (`bailiff_sent_date` IS NULL OR
               (`bailiff_sent_date` <= CURDATE() AND
                `bailiff_sent_date` >= `issue_date` AND
                `bailiff_sent_date` >= '2000-01-01')),
    CONSTRAINT `chk_enforcement_completion_date`
        CHECK (`completion_date` IS NULL OR
               (`completion_date` <= CURDATE() AND
                `completion_date` >= `issue_date` AND
                `completion_date` >= '2000-01-01')),
    CONSTRAINT `chk_enforcement_number`
        CHECK (`enforcement_number` REGEXP '^[0-9]{1,6}-[А-Яа-я]{2,3}$'),
    CONSTRAINT `chk_enforcement_amount`
        CHECK (`amount` IS NULL OR `amount` >= 0),

    -- Ограничения уникальности
    UNIQUE KEY `uk_enforcement_number` (`enforcement_number`, YEAR(`issue_date`)) COMMENT 'Уникальность номера в пределах года'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Исполнительные документы';

-- ======================================================================
-- РАЗДЕЛ 3: ВСПОМОГАТЕЛЬНЫЕ ТАБЛИЦЫ (AUXILIARY)
-- ======================================================================

-- 4.1. Таблица движений дел (журнал изменений)
CREATE TABLE IF NOT EXISTS `case_movements` (
    `movement_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор движения',
    `case_id` BIGINT NOT NULL COMMENT 'Ссылка на дело',
    `movement_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата и время события',
    `movement_type_id` INT NOT NULL COMMENT 'Тип события',
    `from_value` VARCHAR(255) COMMENT 'Предыдущее значение',
    `to_value` VARCHAR(255) COMMENT 'Новое значение',
    `staff_id` BIGINT COMMENT 'Сотрудник, выполнивший действие',
    `comments` TEXT COMMENT 'Комментарии к событию',

    -- Внешние ключи
    FOREIGN KEY (`case_id`)
        REFERENCES `court_cases`(`case_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`movement_type_id`)
        REFERENCES `dict_movement_types`(`movement_type_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (`staff_id`)
        REFERENCES `court_staff`(`staff_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_movements_case` (`case_id`),
    INDEX `idx_movements_date` (`movement_date`),
    INDEX `idx_movements_type` (`movement_type_id`),
    INDEX `idx_movements_staff` (`staff_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Журнал движений дел';

-- 4.2. Таблица судебных округов
CREATE TABLE IF NOT EXISTS `judicial_districts` (
    `district_id` INT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор округа',
    `district_name` VARCHAR(200) NOT NULL COMMENT 'Наименование округа',
    `region` VARCHAR(200) COMMENT 'Регион',
    `court_count` INT DEFAULT 0 COMMENT 'Количество судов в округе',
    `population` INT COMMENT 'Численность населения',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания записи',

    -- Индексы
    INDEX `idx_district_name` (`district_name`),
    INDEX `idx_district_region` (`region`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Судебные округа';

-- 4.3. Таблица для связи судей с судебными округами
CREATE TABLE IF NOT EXISTS `judge_districts` (
    `judge_district_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор связи',
    `judge_participant_id` BIGINT NOT NULL COMMENT 'Ссылка на судью как участника дела',
    `district_id` INT NOT NULL COMMENT 'Ссылка на округ',
    `assignment_date` DATE NOT NULL COMMENT 'Дата назначения в округ',
    `is_current` BOOLEAN DEFAULT TRUE COMMENT 'Текущее ли назначение',

    -- Внешние ключи
    FOREIGN KEY (`judge_participant_id`)
        REFERENCES `case_participants`(`participant_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    FOREIGN KEY (`district_id`)
        REFERENCES `judicial_districts`(`district_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_judge_districts_judge` (`judge_participant_id`),
    INDEX `idx_judge_districts_district` (`district_id`),
    INDEX `idx_judge_districts_current` (`is_current`),

    -- Ограничения уникальности
    UNIQUE KEY `uk_current_judge_district` (`judge_participant_id`, `is_current`) COMMENT 'Только одно текущее назначение на судью'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Связь судей с судебными округами';

-- 4.4. Таблица для журнала аудита системы
CREATE TABLE IF NOT EXISTS `system_audit_log` (
    `audit_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор аудита',
    `event_time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Время события',
    `user_name` VARCHAR(100) COMMENT 'Имя пользователя',
    `event_type` VARCHAR(50) COMMENT 'Тип события',
    `table_name` VARCHAR(100) COMMENT 'Имя таблицы',
    `record_id` BIGINT COMMENT 'ID измененной записи',
    `old_value` JSON COMMENT 'Старое значение',
    `new_value` JSON COMMENT 'Новое значение',
    `description` TEXT COMMENT 'Описание события',
    `ip_address` VARCHAR(45) COMMENT 'IP-адрес',

    -- Индексы
    INDEX `idx_audit_event_time` (`event_time`),
    INDEX `idx_audit_event_type` (`event_type`),
    INDEX `idx_audit_table` (`table_name`, `record_id`),
    INDEX `idx_audit_user` (`user_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Журнал аудита системы';

-- 4.5. Таблица для кэширования статистики
CREATE TABLE IF NOT EXISTS `statistics_cache` (
    `cache_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор кэша',
    `statistic_type` VARCHAR(100) NOT NULL COMMENT 'Тип статистики',
    `period_date` DATE NOT NULL COMMENT 'Дата периода',
    `category_id` INT COMMENT 'Категория дела',
    `judge_participant_id` BIGINT COMMENT 'Судья',
    `district_id` INT COMMENT 'Округ',
    `value_json` JSON NOT NULL COMMENT 'Значения статистики в JSON',
    `calculated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Время расчета',
    `expires_at` TIMESTAMP COMMENT 'Время истечения срока действия',

    -- Индексы
    INDEX `idx_stat_cache_type` (`statistic_type`, `period_date`),
    INDEX `idx_stat_cache_category` (`category_id`),
    INDEX `idx_stat_cache_judge` (`judge_participant_id`),
    INDEX `idx_stat_cache_district` (`district_id`),
    INDEX `idx_stat_cache_expires` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Кэш статистики';

-- 4.6. Таблица для архивных копий удаленных дел
CREATE TABLE IF NOT EXISTS `archived_cases` (
    `archive_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор архива',
    `original_case_id` BIGINT NOT NULL COMMENT 'Оригинальный ID дела',
    `case_number` VARCHAR(100) NOT NULL COMMENT 'Номер дела',
    `category_id` INT NOT NULL COMMENT 'Категория дела',
    `status_id` INT NOT NULL COMMENT 'Статус дела',
    `init_date` DATE NOT NULL COMMENT 'Дата поступления',
    `result_date` DATE COMMENT 'Дата вынесения решения',
    `summary` TEXT COMMENT 'Краткое описание',
    `result` TEXT COMMENT 'Результат рассмотрения',
    `judge_participant_id` BIGINT COMMENT 'Председательствующий судья',
    `archive_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата архивации',
    `archive_reason` VARCHAR(500) COMMENT 'Причина удаления',
    `archived_by_staff_id` BIGINT COMMENT 'Кто архивировал',
    `original_created_at` TIMESTAMP COMMENT 'Оригинальная дата создания',

    -- Внешние ключи
    FOREIGN KEY (`category_id`)
        REFERENCES `dict_case_categories`(`category_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (`status_id`)
        REFERENCES `dict_case_statuses`(`status_id`)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    FOREIGN KEY (`judge_participant_id`)
        REFERENCES `case_participants`(`participant_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    FOREIGN KEY (`archived_by_staff_id`)
        REFERENCES `court_staff`(`staff_id`)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_archived_case_number` (`case_number`),
    INDEX `idx_archived_original_id` (`original_case_id`),
    INDEX `idx_archived_date` (`archive_date`),
    INDEX `idx_archived_category` (`category_id`),
    INDEX `idx_archived_status` (`status_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Архивные копии удаленных дел';

-- 4.7. Таблица для архива участников дела
CREATE TABLE IF NOT EXISTS `archived_case_participants` (
    `archive_participant_id` BIGINT PRIMARY KEY AUTO_INCREMENT COMMENT 'Уникальный идентификатор архива участника',
    `original_participant_id` BIGINT NOT NULL COMMENT 'Оригинальный ID участника',
    `archive_case_id` BIGINT NOT NULL COMMENT 'Ссылка на архивное дело',
    `person_id` BIGINT COMMENT 'Физическое лицо',
    `legal_entity_id` BIGINT COMMENT 'Юридическое лицо',
    `role_id` INT NOT NULL COMMENT 'Роль в деле',
    `lawyer_certificate_number` VARCHAR(100) COMMENT 'Номер удостоверения адвоката',
    `representation_basis` VARCHAR(255) COMMENT 'Основание представительства',
    `created_at` TIMESTAMP COMMENT 'Оригинальная дата создания',
    `archived_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата архивации',

    -- Внешние ключи
    FOREIGN KEY (`archive_case_id`)
        REFERENCES `archived_cases`(`archive_id`)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- Индексы
    INDEX `idx_archived_participants_case` (`archive_case_id`),
    INDEX `idx_archived_participants_original` (`original_participant_id`),
    INDEX `idx_archived_participants_person` (`person_id`),
    INDEX `idx_archived_participants_legal` (`legal_entity_id`),
    INDEX `idx_archived_participants_role` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Архив участников дела';

-- ======================================================================
-- РАЗДЕЛ 4: ДОПОЛНИТЕЛЬНЫЕ ИНДЕКСЫ
-- ======================================================================

-- Индексы для быстрого поиска
CREATE INDEX `idx_unique_person_identity` ON `persons` (
    UPPER(TRIM(`last_name`)),
    UPPER(TRIM(`first_name`)),
    UPPER(TRIM(`patronymic`)),
    `birth_date`
) COMMENT 'Предотвращает создание дублей ФИО + дата рождения';

CREATE UNIQUE INDEX `idx_unique_passport` ON `persons` (`passport_series`, `passport_number`)
WHERE `passport_series` IS NOT NULL AND `passport_number` IS NOT NULL
COMMENT 'Уникальность паспортных данных';

CREATE UNIQUE INDEX `idx_unique_case_year` ON `court_cases` (`case_number`, YEAR(`init_date`))
COMMENT 'Уникальность номера дела в пределах года';

CREATE UNIQUE INDEX `idx_unique_document_in_case` ON `documents` (`case_id`, `internal_number`)
WHERE `internal_number` IS NOT NULL
COMMENT 'Уникальность внутреннего номера документа в деле';

CREATE UNIQUE INDEX `idx_unique_session_time_room` ON `court_sessions` (`session_date`, `room_number`)
WHERE `room_number` IS NOT NULL
COMMENT 'Предотвращение наложения заседаний по времени в одном зале';

CREATE UNIQUE INDEX `idx_unique_staff_position` ON `court_staff` (`person_id`, `position`, `department`)
WHERE `is_active` = TRUE
COMMENT 'Уникальность должности для активного сотрудника';

CREATE UNIQUE INDEX `idx_unique_lawyer_certificate` ON `case_participants` (`lawyer_certificate_number`)
WHERE `lawyer_certificate_number` IS NOT NULL
COMMENT 'Уникальность номера удостоверения адвоката';

-- Индексы для оптимизации аналитических запросов
CREATE INDEX `idx_cases_judge_date` ON `court_cases` (`judge_participant_id`, `init_date`, `result_date`);
CREATE INDEX `idx_participants_case_role` ON `case_participants` (`case_id`, `role_id`);
CREATE INDEX `idx_participants_person_role` ON `case_participants` (`person_id`, `role_id`);
CREATE INDEX `idx_participants_legal_role` ON `case_participants` (`legal_entity_id`, `role_id`);
CREATE INDEX `idx_cases_category_status_date` ON `court_cases` (`category_id`, `status_id`, `result_date`);
CREATE INDEX `idx_documents_case_type` ON `documents` (`case_id`, `type_id`);
CREATE INDEX `idx_cases_result_dates` ON `court_cases` (`result_date`, `init_date`);

-- ======================================================================
-- РАЗДЕЛ 5: ТРИГГЕРЫ
-- ======================================================================

DELIMITER $$

-- 5.1. Триггер для автоматического обновления updated_at в court_cases
CREATE TRIGGER `before_court_cases_update_timestamp`
BEFORE UPDATE ON `court_cases`
FOR EACH ROW
BEGIN
    SET NEW.`updated_at` = CURRENT_TIMESTAMP;
END$$

-- 5.2. Триггер для автоматического обновления updated_at в persons
CREATE TRIGGER `before_persons_update_timestamp`
BEFORE UPDATE ON `persons`
FOR EACH ROW
BEGIN
    SET NEW.`updated_at` = CURRENT_TIMESTAMP;
END$$

-- 5.3. Триггер для создания записи в журнале движений при изменении статуса дела
CREATE TRIGGER `after_case_status_update`
AFTER UPDATE ON `court_cases`
FOR EACH ROW
BEGIN
    IF OLD.`status_id` != NEW.`status_id` THEN
        INSERT INTO `case_movements` (
            `case_id`,
            `movement_type_id`,
            `from_value`,
            `to_value`
        ) VALUES (
            NEW.`case_id`,
            (SELECT `movement_type_id` FROM `dict_movement_types` WHERE `movement_type_code` = 'STATUS'),
            (SELECT `status_name` FROM `dict_case_statuses` WHERE `status_id` = OLD.`status_id`),
            (SELECT `status_name` FROM `dict_case_statuses` WHERE `status_id` = NEW.`status_id`)
        );
    END IF;
END$$

-- 5.4. Триггер для проверки корректности дат при вставке дела
CREATE TRIGGER `before_court_cases_insert`
BEFORE INSERT ON `court_cases`
FOR EACH ROW
BEGIN
    -- Проверка, что дата поступления не в будущем
    IF NEW.`init_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Дата поступления дела не может быть в будущем';
    END IF;

    -- Проверка даты результата
    IF NEW.`result_date` IS NOT NULL THEN
        IF NEW.`result_date` > CURDATE() THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Дата результата не может быть в будущем';
        END IF;

        IF NEW.`result_date` < NEW.`init_date` THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Дата результата не может быть раньше даты поступления';
        END IF;
    END IF;
END$$

-- 5.5. Триггер для проверки корректности дат при обновлении дела
CREATE TRIGGER `before_court_cases_update`
BEFORE UPDATE ON `court_cases`
FOR EACH ROW
BEGIN
    -- Проверка даты поступления
    IF NEW.`init_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Дата поступления дела не может быть в будущем';
    END IF;

    -- Проверка даты результата
    IF NEW.`result_date` IS NOT NULL THEN
        IF NEW.`result_date` > CURDATE() THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Дата результата не может быть в будущем';
        END IF;

        IF NEW.`result_date` < NEW.`init_date` THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Дата результата не может быть раньше даты поступления';
        END IF;
    END IF;
END$$

-- 5.6. Триггер для проверки дат документов
CREATE TRIGGER `before_documents_insert`
BEFORE INSERT ON `documents`
FOR EACH ROW
BEGIN
    DECLARE `case_init_date` DATE;

    -- Получение даты поступления дела
    SELECT `init_date` INTO `case_init_date`
    FROM `court_cases`
    WHERE `case_id` = NEW.`case_id`;

    -- Проверка, что дата создания документа не раньше даты поступления дела
    IF NEW.`created_date` < `case_init_date` THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Дата создания документа не может быть раньше даты поступления дела';
    END IF;

    -- Проверка, что дата поступления не в будущем
    IF NEW.`received_date` > CURDATE() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Дата поступления документа не может быть в будущем';
    END IF;
END$$

-- 5.7. Триггер для аудита изменений в таблице persons
CREATE TRIGGER `trg_audit_persons_update`
AFTER UPDATE ON `persons`
FOR EACH ROW
BEGIN
    INSERT INTO `system_audit_log` (
        `table_name`,
        `record_id`,
        `event_type`,
        `old_value`,
        `new_value`,
        `description`
    ) VALUES (
        'persons',
        OLD.`person_id`,
        'UPDATE',
        JSON_OBJECT(
            'last_name', OLD.`last_name`,
            'first_name', OLD.`first_name`,
            'patronymic', OLD.`patronymic`,
            'birth_date', OLD.`birth_date`,
            'snils', OLD.`snils`,
            'inn', OLD.`inn`,
            'phone', OLD.`phone_number`,
            'email', OLD.`email`
        ),
        JSON_OBJECT(
            'last_name', NEW.`last_name`,
            'first_name', NEW.`first_name`,
            'patronymic', NEW.`patronymic`,
            'birth_date', NEW.`birth_date`,
            'snils', NEW.`snils`,
            'inn', NEW.`inn`,
            'phone', NEW.`phone_number`,
            'email', NEW.`email`
        ),
        CONCAT('Изменение данных физического лица ID: ', OLD.`person_id`)
    );
END$$

DELIMITER ;

-- ======================================================================
-- РАЗДЕЛ 6: ЗАПОЛНЕНИЕ СПРАВОЧНЫХ ДАННЫХ
-- ======================================================================

-- 6.1. Заполнение справочника категорий дел
INSERT INTO `dict_case_categories` (`category_code`, `category_name`, `legal_basis`) VALUES
('GRAZHD', 'Гражданское дело', 'ГПК РФ, ст. 22'),
('UGOLOV', 'Уголовное дело', 'УПК РФ, ст. 31'),
('ADM_PRAV', 'Административное правонарушение', 'КоАП РФ'),
('ADM_ISK', 'Административное исковое заявление', 'КАС РФ'),
('APPEAL', 'Апелляционная жалоба', 'ГПК РФ гл. 39, УПК РФ гл. 45.1'),
('MIROVOY', 'Дело у мирового судьи', 'ФЗ "О мировых судьях"');

-- 6.2. Заполнение справочника статусов дел
INSERT INTO `dict_case_statuses` (`status_code`, `status_name`, `description`) VALUES
('POSTUP', 'Поступило', 'Дело зарегистрировано в канцелярии'),
('NAZNACH', 'Назначено к слушанию', 'Назначена дата первого заседания'),
('RASSMOTR', 'В рассмотрении', 'Дело находится в производстве'),
('OTLOZH', 'Отложено', 'Рассмотрение дела отложено'),
('PRIOST', 'Приостановлено', 'Производство по делу приостановлено'),
('RESHENO', 'Решено', 'По делу вынесено решение/приговор'),
('APELYAC', 'На апелляционном рассмотрении', 'Дело рассматривается в апелляции'),
('ZAVERSH', 'Завершено', 'Решение вступило в законную силу'),
('ARHIV', 'В архиве', 'Дело сдано в архив');

-- 6.3. Заполнение справочника ролей участников
INSERT INTO `dict_roles` (`role_code`, `role_name`) VALUES
('SUDYA', 'Судья'),
('SEKRET', 'Секретарь судебного заседания'),
('ISTEC', 'Истец'),
('OTVETCH', 'Ответчик'),
('OBVIN', 'Обвиняемый'),
('POTERP', 'Потерпевший'),
('SVIDET', 'Свидетель'),
('ADVOKAT', 'Адвокат'),
('PREDST', 'Представитель'),
('TRET_L', 'Третье лицо'),
('PRISYAZH', 'Присяжный заседатель'),
('EKS', 'Эксперт'),
('PEREVOD', 'Переводчик'),
('SUD_PRIS', 'Судебный пристав');

-- 6.4. Заполнение справочника типов документов
INSERT INTO `dict_document_types` (`type_code`, `type_name`, `document_category`) VALUES
('ISK_ZAIV', 'Исковое заявление', 'Исковое заявление'),
('OTZYV', 'Отзыв на иск', 'Прочее'),
('HODAT', 'Ходатайство', 'Ходатайство'),
('PROT_SZ', 'Протокол судебного заседания', 'Протокол'),
('RESHENIE', 'Решение суда', 'Решение'),
('PRIGOVOR', 'Приговор', 'Решение'),
('OPREDEL', 'Определение суда', 'Прочее'),
('APEL_ZHAL', 'Апелляционная жалоба', 'Прочее'),
('IS_POL_L', 'Исполнительный лист', 'Исполнительный документ'),
('SUD_PR', 'Судебный приказ', 'Исполнительный документ'),
('POSTANOV', 'Постановление', 'Прочее'),
('SPRAVKA', 'Справка по делу', 'Прочее');

-- 6.5. Заполнение справочника типов судебных заседаний
INSERT INTO `dict_session_types` (`type_code`, `type_name`) VALUES
('PODGOT', 'Подготовительное заседание'),
('OSNOV', 'Основное заседание'),
('POVTOR', 'Повторное заседание'),
('APELYAC', 'Апелляционное заседание'),
('ZAKRYT', 'Закрытое заседание');

-- 6.6. Заполнение справочника статусов исполнительных документов
INSERT INTO `dict_enforcement_statuses` (`status_code`, `status_name`) VALUES
('VYDAN', 'Выдан'),
('NAPRAV', 'Направлен приставам'),
('ISPOLN', 'Исполнен'),
('CHAST_ISP', 'Частично исполнен'),
('VOZVRAT', 'Возвращен'),
('PREKR', 'Прекращен');

-- 6.7. Заполнение справочника типов движений дел
INSERT INTO `dict_movement_types` (`movement_type_code`, `movement_type_name`) VALUES
('STATUS', 'Изменение статуса'),
('SUDYA', 'Изменение судьи'),
('SEKRET', 'Изменение секретаря'),
('PRIOST', 'Приостановление'),
('VOZOB', 'Возобновление'),
('OTLOZH', 'Отложение'),
('PERED', 'Передача в другой суд'),
('APELYAC', 'Направление в апелляцию');

-- ======================================================================
-- РАЗДЕЛ 7: НАЗНАЧЕНИЕ ПРАВ (ПРИМЕР)
-- ======================================================================

-- Создание пользователей с разными правами доступа
-- CREATE USER 'court_judge'@'localhost' IDENTIFIED BY 'secure_password';
-- CREATE USER 'court_secretary'@'localhost' IDENTIFIED BY 'secure_password';
-- CREATE USER 'court_archivist'@'localhost' IDENTIFIED BY 'secure_password';
-- CREATE USER 'court_analyst'@'localhost' IDENTIFIED BY 'secure_password';

-- Права для судьи
-- GRANT SELECT, INSERT, UPDATE ON `court_system_db`.`court_cases` TO 'court_judge'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON `court_system_db`.`documents` TO 'court_judge'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON `court_system_db`.`court_sessions` TO 'court_judge'@'localhost';
-- GRANT SELECT ON `court_system_db`.`persons` TO 'court_judge'@'localhost';
-- GRANT SELECT ON `court_system_db`.`case_participants` TO 'court_judge'@'localhost';

-- Права для секретаря
-- GRANT SELECT, INSERT, UPDATE ON `court_system_db`.`documents` TO 'court_secretary'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON `court_system_db`.`court_sessions` TO 'court_secretary'@'localhost';
-- GRANT SELECT, INSERT, UPDATE ON `court_system_db`.`session_participants` TO 'court_secretary'@'localhost';
-- GRANT SELECT, UPDATE ON `court_system_db`.`persons` TO 'court_secretary'@'localhost';

-- Права для архивариуса
-- GRANT SELECT, INSERT, UPDATE, DELETE ON `court_system_db`.`archived_cases` TO 'court_archivist'@'localhost';
-- GRANT SELECT, INSERT, UPDATE, DELETE ON `court_system_db`.`archived_case_participants` TO 'court_archivist'@'localhost';
-- GRANT EXECUTE ON PROCEDURE `court_system_db`.`sp_delete_case_safely` TO 'court_archivist'@'localhost';

-- Права для аналитика
-- GRANT SELECT ON `court_system_db`.`v_judge_rating` TO 'court_analyst'@'localhost';
-- GRANT SELECT ON `court_system_db`.`v_case_dynamics_monthly` TO 'court_analyst'@'localhost';
-- GRANT SELECT ON `court_system_db`.`v_category_negative_decisions` TO 'court_analyst'@'localhost';
-- GRANT EXECUTE ON PROCEDURE `court_system_db`.`sp_get_case_dynamics` TO 'court_analyst'@'localhost';
-- GRANT EXECUTE ON PROCEDURE `court_system_db`.`sp_compare_districts_performance` TO 'court_analyst'@'localhost';

-- FLUSH PRIVILEGES;

-- ======================================================================
-- РАЗДЕЛ 8: СОЗДАНИЕ ПРЕДСТАВЛЕНИЙ (VIEWS)
-- ======================================================================

-- 8.1. Представление для списка дел с участием лица
CREATE OR REPLACE VIEW `v_cases_by_participant` AS
SELECT
    cp.`participant_id`,
    cp.`case_id`,
    cc.`case_number`,
    cc.`init_date`,
    cc.`result_date`,
    dcc.`category_name`,
    dcs.`status_name`,
    CASE
        WHEN cp.`person_id` IS NOT NULL THEN
            CONCAT(p.`last_name`, ' ', p.`first_name`, ' ', COALESCE(p.`patronymic`, ''))
        ELSE le.`full_name`
    END as `participant_name`,
    CASE
        WHEN cp.`person_id` IS NOT NULL THEN 'Физическое лицо'
        ELSE 'Юридическое лицо'
    END as `participant_type`,
    dr.`role_name` as `role_in_case`
FROM `case_participants` cp
JOIN `court_cases` cc ON cp.`case_id` = cc.`case_id`
JOIN `dict_case_categories` dcc ON cc.`category_id` = dcc.`category_id`
JOIN `dict_case_statuses` dcs ON cc.`status_id` = dcs.`status_id`
JOIN `dict_roles` dr ON cp.`role_id` = dr.`role_id`
LEFT JOIN `persons` p ON cp.`person_id` = p.`person_id`
LEFT JOIN `legal_entities` le ON cp.`legal_entity_id` = le.`legal_entity_id`;

-- 8.2. Представление для дел судьи
CREATE OR REPLACE VIEW `v_cases_by_judge` AS
SELECT
    cp.`participant_id` as `judge_participant_id`,
    CONCAT(p.`last_name`, ' ', p.`first_name`, ' ', COALESCE(p.`patronymic`, '')) as `judge_name`,
    cc.`case_id`,
    cc.`case_number`,
    dcc.`category_name`,
    cc.`init_date`,
    cc.`result_date`,
    dcs.`status_name`,
    CASE
        WHEN cc.`result_date` IS NOT NULL AND cc.`init_date` IS NOT NULL
        THEN DATEDIFF(cc.`result_date`, cc.`init_date`)
        ELSE NULL
    END as `days_to_resolve`
FROM `case_participants` cp
JOIN `court_cases` cc ON cp.`case_id` = cc.`case_id`
JOIN `persons` p ON cp.`person_id` = p.`person_id`
JOIN `dict_roles` dr ON cp.`role_id` = dr.`role_id`
JOIN `dict_case_categories` dcc ON cc.`category_id` = dcc.`category_id`
JOIN `dict_case_statuses` dcs ON cc.`status_id` = dcs.`status_id`
WHERE dr.`role_code` = 'SUDYA';

-- 8.3. Представление для статистики по судьям
CREATE OR REPLACE VIEW `v_judge_statistics` AS
SELECT
    `judge_participant_id`,
    `judge_name`,
    COUNT(*) as `total_cases`,
    SUM(CASE WHEN `status_name` = 'Завершено' THEN 1 ELSE 0 END) as `completed_cases`,
    SUM(CASE WHEN `status_name` = 'Решено' THEN 1 ELSE 0 END) as `decided_cases`,
    AVG(`days_to_resolve`) as `avg_days_to_resolve`,
    MIN(`init_date`) as `first_case_date`,
    MAX(`init_date`) as `last_case_date`
FROM `v_cases_by_judge`
GROUP BY `judge_participant_id`, `judge_name`;

-- 8.4. Представление для рейтинга судей
CREATE OR REPLACE VIEW `v_judge_rating` AS
SELECT
    js.`judge_participant_id`,
    js.`judge_name`,
    js.`total_cases`,
    js.`completed_cases`,
    js.`decided_cases`,
    ROUND(js.`avg_days_to_resolve`, 2) as `avg_days_to_resolve`,
    CASE
        WHEN js.`total_cases` > 0
        THEN ROUND((js.`completed_cases` * 100.0 / js.`total_cases`), 2)
        ELSE 0
    END as `completion_rate`,
    RANK() OVER (ORDER BY js.`completed_cases` DESC) as `rank_by_completed`,
    RANK() OVER (ORDER BY js.`avg_days_to_resolve` ASC) as `rank_by_speed`
FROM `v_judge_statistics` js
WHERE js.`total_cases` >= 5;

-- 8.5. Представление для статистики по юридическим лицам
CREATE OR REPLACE VIEW `v_legal_entity_statistics` AS
SELECT
    le.`legal_entity_id`,
    le.`short_name` as `entity_name`,
    le.`inn`,
    dcc.`category_id`,
    dcc.`category_name`,
    COUNT(DISTINCT cc.`case_id`) as `total_cases`,
    SUM(CASE
        WHEN cp.`role_id` = (SELECT `role_id` FROM `dict_roles` WHERE `role_code` = 'ISTEC')
             AND cc.`result` LIKE '%удовлетворено%' THEN 1
        WHEN cp.`role_id` = (SELECT `role_id` FROM `dict_roles` WHERE `role_code` = 'OTVETCH')
             AND cc.`result` LIKE '%отказано%' THEN 1
        ELSE 0
    END) as `won_cases`,
    SUM(CASE
        WHEN cp.`role_id` = (SELECT `role_id` FROM `dict_roles` WHERE `role_code` = 'ISTEC')
             AND cc.`result` LIKE '%отказано%' THEN 1
        WHEN cp.`role_id` = (SELECT `role_id` FROM `dict_roles` WHERE `role_code` = 'OTVETCH')
             AND cc.`result` LIKE '%удовлетворено%' THEN 1
        ELSE 0
    END) as `lost_cases`
FROM `legal_entities` le
JOIN `case_participants` cp ON le.`legal_entity_id` = cp.`legal_entity_id`
JOIN `court_cases` cc ON cp.`case_id` = cc.`case_id`
JOIN `dict_case_categories` dcc ON cc.`category_id` = dcc.`category_id`
WHERE cc.`result_date` IS NOT NULL
GROUP BY le.`legal_entity_id`, le.`short_name`, le.`inn`, dcc.`category_id`, dcc.`category_name`;

-- 8.6. Представление для категорий с отрицательными решениями
CREATE OR REPLACE VIEW `v_category_negative_decisions` AS
SELECT
    dcc.`category_id`,
    dcc.`category_name`,
    COUNT(*) as `total_cases`,
    SUM(CASE WHEN cc.`result` LIKE '%отказано%' THEN 1 ELSE 0 END) as `negative_decisions`,
    SUM(CASE WHEN cc.`result` LIKE '%удовлетворено%' THEN 1 ELSE 0 END) as `positive_decisions`,
    ROUND(
        SUM(CASE WHEN cc.`result` LIKE '%отказано%' THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(COUNT(*), 0),
    2) as `negative_percentage`
FROM `court_cases` cc
JOIN `dict_case_categories` dcc ON cc.`category_id` = dcc.`category_id`
WHERE cc.`result_date` IS NOT NULL
  AND cc.`result` IS NOT NULL
GROUP BY dcc.`category_id`, dcc.`category_name`
HAVING `total_cases` >= 10;

-- 8.7. Представление для динамики дел по категориям
CREATE OR REPLACE VIEW `v_case_dynamics_monthly` AS
SELECT
    dcc.`category_id`,
    dcc.`category_name`,
    YEAR(cc.`init_date`) as `year`,
    MONTH(cc.`init_date`) as `month`,
    COUNT(*) as `cases_count`,
    COUNT(CASE WHEN cc.`result_date` IS NOT NULL THEN 1 END) as `resolved_cases`,
    AVG(DATEDIFF(COALESCE(cc.`result_date`, CURDATE()), cc.`init_date`)) as `avg_duration_days`
FROM `court_cases` cc
JOIN `dict_case_categories` dcc ON cc.`category_id` = dcc.`category_id`
WHERE cc.`init_date` >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)
GROUP BY dcc.`category_id`, dcc.`category_name`, YEAR(cc.`init_date`), MONTH(cc.`init_date`);

-- ======================================================================
-- РАЗДЕЛ 9: ХРАНИМЫЕ ПРОЦЕДУРЫ И ФУНКЦИИ
-- ======================================================================

DELIMITER $$

-- 9.1. Процедура для добавления физического лица с проверкой дублей
CREATE PROCEDURE `sp_add_person`(
    IN p_last_name VARCHAR(100),
    IN p_first_name VARCHAR(100),
    IN p_patronymic VARCHAR(100),
    IN p_birth_date DATE,
    IN p_passport_series VARCHAR(4),
    IN p_passport_number VARCHAR(6),
    IN p_snils CHAR(14),
    IN p_inn VARCHAR(12),
    OUT p_person_id BIGINT
)
BEGIN
    DECLARE existing_id BIGINT;

    -- Поиск существующей записи по ФИО и дате рождения
    IF p_birth_date IS NOT NULL THEN
        SELECT `person_id` INTO existing_id
        FROM `persons`
        WHERE UPPER(TRIM(`last_name`)) = UPPER(TRIM(p_last_name))
          AND UPPER(TRIM(`first_name`)) = UPPER(TRIM(p_first_name))
          AND (UPPER(TRIM(`patronymic`)) = UPPER(TRIM(p_patronymic))
               OR (`patronymic` IS NULL AND p_patronymic IS NULL))
          AND `birth_date` = p_birth_date
        LIMIT 1;
    END IF;

    -- Если не нашли по ФИО, ищем по паспорту
    IF existing_id IS NULL AND p_passport_series IS NOT NULL AND p_passport_number IS NOT NULL THEN
        SELECT `person_id` INTO existing_id
        FROM `persons`
        WHERE `passport_series` = p_passport_series
          AND `passport_number` = p_passport_number
        LIMIT 1;
    END IF;

    -- Если не нашли по паспорту, ищем по СНИЛС
    IF existing_id IS NULL AND p_snils IS NOT NULL THEN
        SELECT `person_id` INTO existing_id
        FROM `persons`
        WHERE `snils` = p_snils
        LIMIT 1;
    END IF;

    -- Если не нашли по СНИЛС, ищем по ИНН
    IF existing_id IS NULL AND p_inn IS NOT NULL THEN
        SELECT `person_id` INTO existing_id
        FROM `persons`
        WHERE `inn` = p_inn
        LIMIT 1;
    END IF;

    -- Если запись существует, возвращаем её ID
    IF existing_id IS NOT NULL THEN
        SET p_person_id = existing_id;
    ELSE
        -- Создаём новую запись
        INSERT INTO `persons` (
            `last_name`, `first_name`, `patronymic`, `birth_date`,
            `passport_series`, `passport_number`, `snils`, `inn`
        ) VALUES (
            p_last_name, p_first_name, p_patronymic, p_birth_date,
            p_passport_series, p_passport_number, p_snils, p_inn
        );

        SET p_person_id = LAST_INSERT_ID();
    END IF;
END$$

-- 9.2. Процедура для обновления контактных данных участника
CREATE PROCEDURE `sp_update_participant_contacts`(
    IN p_search_type VARCHAR(20),
    IN p_search_value VARCHAR(255),
    IN p_new_phone VARCHAR(20),
    IN p_new_email VARCHAR(255),
    IN p_new_address TEXT,
    OUT p_affected_rows INT,
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE v_person_id BIGINT;
    DECLARE v_full_name VARCHAR(300);

    -- Поиск лица по различным критериям
    CASE p_search_type
        WHEN 'id' THEN
            SELECT `person_id`, CONCAT(`last_name`, ' ', `first_name`, ' ', `patronymic`)
            INTO v_person_id, v_full_name
            FROM `persons`
            WHERE `person_id` = CAST(p_search_value AS UNSIGNED);

        WHEN 'passport' THEN
            SELECT `person_id`, CONCAT(`last_name`, ' ', `first_name`, ' ', `patronymic`)
            INTO v_person_id, v_full_name
            FROM `persons`
            WHERE CONCAT(`passport_series`, `passport_number`) = REPLACE(p_search_value, ' ', '');

        WHEN 'snils' THEN
            SELECT `person_id`, CONCAT(`last_name`, ' ', `first_name`, ' ', `patronymic`)
            INTO v_person_id, v_full_name
            FROM `persons`
            WHERE `snils` = p_search_value;

        WHEN 'inn' THEN
            SELECT `person_id`, CONCAT(`last_name`, ' ', `first_name`, ' ', `patronymic`)
            INTO v_person_id, v_full_name
            FROM `persons`
            WHERE `inn` = p_search_value;

        WHEN 'fio' THEN
            SET @last_name = SUBSTRING_INDEX(p_search_value, ' ', 1);
            SET @temp = SUBSTRING(p_search_value, CHAR_LENGTH(@last_name) + 2);
            SET @first_name = SUBSTRING_INDEX(@temp, ' ', 1);
            SET @patronymic = CASE
                WHEN CHAR_LENGTH(@temp) > CHAR_LENGTH(@first_name) + 1
                THEN SUBSTRING(@temp, CHAR_LENGTH(@first_name) + 2)
                ELSE NULL
            END;

            SELECT `person_id`, CONCAT(`last_name`, ' ', `first_name`, ' ', `patronymic`)
            INTO v_person_id, v_full_name
            FROM `persons`
            WHERE UPPER(TRIM(`last_name`)) = UPPER(TRIM(@last_name))
              AND UPPER(TRIM(`first_name`)) = UPPER(TRIM(@first_name))
              AND (UPPER(TRIM(`patronymic`)) = UPPER(TRIM(@patronymic))
                   OR (`patronymic` IS NULL AND @patronymic IS NULL))
            LIMIT 1;

        ELSE
            SET p_message = 'Неверный тип поиска. Допустимые значения: id, passport, snils, inn, fio';
            SET p_affected_rows = 0;
            RETURN;
    END CASE;

    -- Проверка, найдено ли лицо
    IF v_person_id IS NULL THEN
        SET p_message = CONCAT('Участник не найден по критерию: ', p_search_type, ' = ', p_search_value);
        SET p_affected_rows = 0;
        RETURN;
    END IF;

    -- Начало транзакции
    START TRANSACTION;

    -- Обновление данных
    UPDATE `persons`
    SET
        `phone_number` = CASE
            WHEN p_new_phone IS NOT NULL AND p_new_phone != ''
            THEN p_new_phone
            ELSE `phone_number`
        END,
        `email` = CASE
            WHEN p_new_email IS NOT NULL AND p_new_email != ''
            THEN p_new_email
            ELSE `email`
        END,
        `actual_address` = CASE
            WHEN p_new_address IS NOT NULL AND p_new_address != ''
            THEN p_new_address
            ELSE `actual_address`
        END,
        `updated_at` = CURRENT_TIMESTAMP
    WHERE `person_id` = v_person_id;

    -- Получение количества обновленных строк
    SET p_affected_rows = ROW_COUNT();

    -- Аудит изменения
    INSERT INTO `system_audit_log` (
        `event_type`,
        `table_name`,
        `record_id`,
        `old_value`,
        `new_value`,
        `description`
    ) VALUES (
        'CONTACT_UPDATE',
        'persons',
        v_person_id,
        JSON_OBJECT(
            'old_phone', (SELECT `phone_number` FROM `persons` WHERE `person_id` = v_person_id FOR UPDATE),
            'old_email', (SELECT `email` FROM `persons` WHERE `person_id` = v_person_id FOR UPDATE),
            'old_address', (SELECT `actual_address` FROM `persons` WHERE `person_id` = v_person_id FOR UPDATE)
        ),
        JSON_OBJECT(
            'new_phone', COALESCE(p_new_phone, 'не изменен'),
            'new_email', COALESCE(p_new_email, 'не изменен'),
            'new_address', COALESCE(p_new_address, 'не изменен')
        ),
        CONCAT('Обновление контактных данных участника: ', v_full_name)
    );

    -- Фиксация транзакции
    COMMIT;

    -- Формирование сообщения об успехе
    SET p_message = CONCAT(
        'Успешно обновлены контактные данные участника: ', v_full_name,
        '. Обновлено записей: ', p_affected_rows
    );
END$$

-- 9.3. Процедура для безопасного удаления дела
CREATE PROCEDURE `sp_delete_case_safely`(
    IN p_case_number VARCHAR(100),
    IN p_reason VARCHAR(500),
    IN p_staff_id BIGINT,
    OUT p_deleted_count INT,
    OUT p_backup_case_id BIGINT,
    OUT p_message VARCHAR(1000)
)
BEGIN
    DECLARE v_case_id BIGINT;
    DECLARE v_case_status VARCHAR(100);
    DECLARE v_judge_name VARCHAR(300);
    DECLARE v_backup_created BOOLEAN DEFAULT FALSE;

    -- Проверка существования дела
    SELECT
        cc.`case_id`,
        dcs.`status_name`,
        CONCAT(p.`last_name`, ' ', p.`first_name`, ' ', p.`patronymic`)
    INTO v_case_id, v_case_status, v_judge_name
    FROM `court_cases` cc
    JOIN `dict_case_statuses` dcs ON cc.`status_id` = dcs.`status_id`
    LEFT JOIN `case_participants` cp ON cc.`judge_participant_id` = cp.`participant_id`
    LEFT JOIN `persons` p ON cp.`person_id` = p.`person_id`
    WHERE cc.`case_number` = p_case_number;

    -- Если дело не найдено
    IF v_case_id IS NULL THEN
        SET p_message = CONCAT('Дело с номером ', p_case_number, ' не найдено');
        SET p_deleted_count = 0;
        SET p_backup_case_id = NULL;
        RETURN;
    END IF;

    -- Проверка статуса дела
    IF v_case_status NOT IN ('Завершено', 'В архиве') THEN
        SET p_message = CONCAT(
            'Дело ', p_case_number, ' имеет статус "', v_case_status,
            '". Удаление разрешено только для завершенных или архивных дел.'
        );
        SET p_deleted_count = 0;
        SET p_backup_case_id = NULL;
        RETURN;
    END IF;

    -- Начало транзакции
    START TRANSACTION;

    -- 1. Создание резервной копии
    INSERT INTO `archived_cases` (
        `original_case_id`,
        `case_number`,
        `category_id`,
        `status_id`,
        `init_date`,
        `result_date`,
        `summary`,
        `result`,
        `judge_participant_id`,
        `archive_reason`,
        `archived_by_staff_id`,
        `original_created_at`
    )
    SELECT
        `case_id`,
        `case_number`,
        `category_id`,
        `status_id`,
        `init_date`,
        `result_date`,
        `summary`,
        `result`,
        `judge_participant_id`,
        p_reason,
        p_staff_id,
        `created_at`
    FROM `court_cases`
    WHERE `case_id` = v_case_id;

    SET p_backup_case_id = LAST_INSERT_ID();
    SET v_backup_created = TRUE;

    -- 2. Архивирование участников дела
    INSERT INTO `archived_case_participants` (
        `original_participant_id`,
        `archive_case_id`,
        `person_id`,
        `legal_entity_id`,
        `role_id`,
        `lawyer_certificate_number`,
        `representation_basis`,
        `created_at`
    )
    SELECT
        `participant_id`,
        p_backup_case_id,
        `person_id`,
        `legal_entity_id`,
        `role_id`,
        `lawyer_certificate_number`,
        `representation_basis`,
        `created_at`
    FROM `case_participants`
    WHERE `case_id` = v_case_id;

    -- 3. Удаление связанных записей в правильном порядке
    DELETE FROM `session_participants`
    WHERE `session_id` IN (SELECT `session_id` FROM `court_sessions` WHERE `case_id` = v_case_id);

    DELETE FROM `court_sessions` WHERE `case_id` = v_case_id;
    DELETE FROM `enforcement_documents` WHERE `case_id` = v_case_id;
    DELETE FROM `case_movements` WHERE `case_id` = v_case_id;
    DELETE FROM `case_staff` WHERE `case_id` = v_case_id;

    -- Создание временной таблицы для файлов (для последующего удаления с диска)
    CREATE TEMPORARY TABLE IF NOT EXISTS `temp_deleted_files` AS
    SELECT `file_path`
    FROM `documents`
    WHERE `case_id` = v_case_id;

    DELETE FROM `documents` WHERE `case_id` = v_case_id;
    DELETE FROM `case_participants` WHERE `case_id` = v_case_id;

    -- 4. Удаление самого дела
    DELETE FROM `court_cases` WHERE `case_id` = v_case_id;

    -- Получаем общее количество удаленных записей
    SET p_deleted_count = ROW_COUNT();

    -- 5. Аудит удаления
    INSERT INTO `system_audit_log` (
        `event_type`,
        `table_name`,
        `record_id`,
        `old_value`,
        `new_value`,
        `description`,
        `staff_id`
    ) VALUES (
        'CASE_DELETED',
        'court_cases',
        v_case_id,
        JSON_OBJECT(
            'case_number', p_case_number,
            'status', v_case_status,
            'judge', v_judge_name
        ),
        NULL,
        CONCAT(
            'Удалено дело №', p_case_number,
            '. Причина: ', p_reason,
            ' (создана резервная копия ID: ', p_backup_case_id, ')'
        ),
        p_staff_id
    );

    -- Фиксация транзакции
    COMMIT;

    -- Формирование сообщения об успехе
    SET p_message = CONCAT(
        'Дело №', p_case_number, ' успешно удалено. ',
        'Удалено записей: ', p_deleted_count,
        '. Создана резервная копия ID: ', p_backup_case_id, '.',
        ' Рекомендуется проверить файлы на диске для ручного удаления.'
    );

    -- Очистка временной таблицы
    DROP TEMPORARY TABLE IF EXISTS `temp_deleted_files`;
END$$

-- 9.4. Процедура для добавления судебного документа
CREATE PROCEDURE `sp_add_judicial_document`(
    IN p_case_number VARCHAR(100),
    IN p_document_type_code VARCHAR(20),
    IN p_title VARCHAR(500),
    IN p_file_path TEXT,
    IN p_mime_type VARCHAR(100),
    IN p_judge_participant_id BIGINT,
    IN p_decision_date DATE,
    IN p_decision_text TEXT,
    IN p_received_date DATE,
    IN p_description TEXT,
    OUT p_document_id BIGINT,
    OUT p_message VARCHAR(500)
)
BEGIN
    DECLARE v_case_id BIGINT;
    DECLARE v_document_type_id INT;
    DECLARE v_internal_number VARCHAR(100);
    DECLARE v_judge_name VARCHAR(300);
    DECLARE v_case_status VARCHAR(100);

    -- Проверка существования дела
    SELECT cc.`case_id`, dcs.`status_name`
    INTO v_case_id, v_case_status
    FROM `court_cases` cc
    JOIN `dict_case_statuses` dcs ON cc.`status_id` = dcs.`status_id`
    WHERE cc.`case_number` = p_case_number;

    IF v_case_id IS NULL THEN
        SET p_message = CONCAT('Дело с номером ', p_case_number, ' не найдено');
        SET p_document_id = NULL;
        RETURN;
    END IF;

    -- Проверка статуса дела
    IF v_case_status NOT IN ('Поступило', 'Назначено к слушанию', 'В рассмотрении', 'Решено', 'Завершено') THEN
        SET p_message = CONCAT('Нельзя добавить документ в дело со статусом "', v_case_status, '"');
        SET p_document_id = NULL;
        RETURN;
    END IF;

    -- Проверка существования типа документа
    SELECT `type_id` INTO v_document_type_id
    FROM `dict_document_types`
    WHERE `type_code` = p_document_type_code;

    IF v_document_type_id IS NULL THEN
        SET p_message = CONCAT('Тип документа с кодом ', p_document_type_code, ' не найден');
        SET p_document_id = NULL;
        RETURN;
    END IF;

    -- Проверка, что указанный участник является судьей в этом деле
    SELECT CONCAT(p.`last_name`, ' ', p.`first_name`, ' ', p.`patronymic`)
    INTO v_judge_name
    FROM `case_participants` cp
    JOIN `persons` p ON cp.`person_id` = p.`person_id`
    WHERE cp.`participant_id` = p_judge_participant_id
      AND cp.`case_id` = v_case_id
      AND cp.`role_id` = (SELECT `role_id` FROM `dict_roles` WHERE `role_code` = 'SUDYA');

    IF v_judge_name IS NULL THEN
        SET p_message = 'Указанный участник не является судьей в данном деле';
        SET p_document_id = NULL;
        RETURN;
    END IF;

    -- Генерация внутреннего номера документа
    SELECT CONCAT(
        (SELECT COUNT(*) + 1 FROM `documents` WHERE `case_id` = v_case_id),
        '-',
        YEAR(CURRENT_DATE())
    ) INTO v_internal_number;

    -- Проверка даты решения
    IF p_decision_date > CURDATE() THEN
        SET p_message = 'Дата решения не может быть в будущем';
        SET p_document_id = NULL;
        RETURN;
    END IF;

    -- Начало транзакции
    START TRANSACTION;

    -- Вставка документа
    INSERT INTO `documents` (
        `case_id`,
        `internal_number`,
        `type_id`,
        `title`,
        `file_path`,
        `mime_type`,
        `author_participant_id`,
        `created_date`,
        `received_date`,
        `description`
    ) VALUES (
        v_case_id,
        v_internal_number,
        v_document_type_id,
        p_title,
        p_file_path,
        p_mime_type,
        p_judge_participant_id,
        COALESCE(p_decision_date, CURDATE()),
        p_received_date,
        CONCAT_WS('\n',
            p_description,
            CASE WHEN p_decision_text IS NOT NULL THEN CONCAT('Решение: ', p_decision_text) END
        )
    );

    SET p_document_id = LAST_INSERT_ID();

    -- Если это решение или приговор, обновляем информацию в деле
    IF p_document_type_code IN ('RESHENIE', 'PRIGOVOR', 'OPREDEL', 'POSTANOV') THEN
        UPDATE `court_cases`
        SET
            `result` = p_decision_text,
            `result_date` = p_decision_date,
            `updated_at` = CURRENT_TIMESTAMP
        WHERE `case_id` = v_case_id;

        -- Если дело было решено, меняем статус
        IF p_document_type_code IN ('RESHENIE', 'PRIGOVOR') THEN
            UPDATE `court_cases`
            SET `status_id` = (SELECT `status_id` FROM `dict_case_statuses` WHERE `status_code` = 'RESHENO')
            WHERE `case_id` = v_case_id;
        END IF;
    END IF;

    -- Аудит добавления документа
    INSERT INTO `system_audit_log` (
        `event_type`,
        `table_name`,
        `record_id`,
        `old_value`,
        `new_value`,
        `description`
    ) VALUES (
        'DOCUMENT_ADDED',
        'documents',
        p_document_id,
        NULL,
        JSON_OBJECT(
            'case_number', p_case_number,
            'document_type', (SELECT `type_name` FROM `dict_document_types` WHERE `type_id` = v_document_type_id),
            'title', p_title,
            'judge', v_judge_name,
            'decision_date', p_decision_date
        ),
        CONCAT('Добавлен судебный документ к делу №', p_case_number, '. Судья: ', v_judge_name)
    );

    -- Фиксация транзакции
    COMMIT;

    SET p_message = CONCAT(
        'Документ успешно добавлен. ID: ', p_document_id,
        '. Внутренний номер: ', v_internal_number,
        '. Судья: ', v_judge_name
    );
END$$

-- 9.5. Функция для проверки прав доступа сотрудника
CREATE FUNCTION `fn_check_staff_permission`(
    p_staff_id BIGINT,
    p_permission_type VARCHAR(50)
)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE v_position VARCHAR(100);
    DECLARE v_has_permission BOOLEAN DEFAULT FALSE;

    -- Получаем должность сотрудника
    SELECT `position` INTO v_position
    FROM `court_staff`
    WHERE `staff_id` = p_staff_id AND `is_active` = TRUE;

    -- Проверяем права в зависимости от должности
    CASE p_permission_type
        WHEN 'UPDATE_CONTACTS' THEN
            SET v_has_permission = v_position IN (
                'Судья', 'Помощник судьи', 'Работник канцелярии', 'Председатель суда'
            );

        WHEN 'DELETE_CASE' THEN
            SET v_has_permission = v_position IN ('Председатель суда', 'Архивариус');

        WHEN 'ADD_DOCUMENT' THEN
            SET v_has_permission = v_position IN (
                'Судья', 'Секретарь суда', 'Секретарь судебного заседания',
                'Работник канцелярии', 'Председатель суда'
            );

        WHEN 'ADD_ENFORCEMENT' THEN
            SET v_has_permission = v_position IN ('Судья', 'Помощник судьи', 'Председатель суда');

        ELSE
            SET v_has_permission = FALSE;
    END CASE;

    RETURN v_has_permission;
END$$

-- 9.6. Функция для расчета эффективности судьи
CREATE FUNCTION `fn_calculate_judge_efficiency`(
    p_judge_participant_id BIGINT,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_cases INT;
    DECLARE v_completed_cases INT;
    DECLARE v_avg_days DECIMAL(10,2);
    DECLARE v_efficiency DECIMAL(10,2);

    -- Получаем статистику судьи
    SELECT
        COUNT(*),
        SUM(CASE WHEN `result_date` IS NOT NULL THEN 1 ELSE 0 END),
        AVG(CASE WHEN `result_date` IS NOT NULL
                THEN DATEDIFF(`result_date`, `init_date`)
                ELSE NULL END)
    INTO v_total_cases, v_completed_cases, v_avg_days
    FROM `v_cases_by_judge`
    WHERE `judge_participant_id` = p_judge_participant_id
      AND (p_start_date IS NULL OR `init_date` >= p_start_date)
      AND (p_end_date IS NULL OR `init_date` <= p_end_date);

    -- Если нет данных
    IF v_total_cases = 0 THEN
        RETURN 0;
    END IF;

    -- Расчет эффективности: 70% за завершенность, 30% за скорость
    SET v_efficiency = (
        (v_completed_cases * 100.0 / v_total_cases) * 0.7 +
        (CASE
            WHEN v_avg_days <= 30 THEN 100
            WHEN v_avg_days <= 60 THEN 80
            WHEN v_avg_days <= 90 THEN 60
            WHEN v_avg_days <= 120 THEN 40
            WHEN v_avg_days <= 180 THEN 20
            ELSE 10
        END) * 0.3
    );

    RETURN ROUND(v_efficiency, 2);
END$$

DELIMITER ;

-- ======================================================================
-- РАЗДЕЛ 10: СОБЫТИЯ (EVENTS) ДЛЯ АВТОМАТИЧЕСКИХ ЗАДАЧ
-- ======================================================================

DELIMITER $$

-- 10.1. Событие для ежедневной проверки дублей
CREATE EVENT IF NOT EXISTS `e_daily_duplicate_check`
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '23:00:00')
COMMENT 'Ежедневная проверка дублирующихся записей'
DO
BEGIN
    -- Логирование начала проверки
    INSERT INTO `system_audit_log` (`event_type`, `description`)
    VALUES ('SYSTEM_MAINTENANCE', 'Начало ежедневной проверки дублирующихся записей');

    -- Проверка дублей физических лиц (упрощенный вариант)
    INSERT INTO `system_audit_log` (`event_type`, `description`)
    SELECT
        'DUPLICATE_CHECK',
        CONCAT('Потенциальный дубль: ', p1.`last_name`, ' ', p1.`first_name`, ' ', p1.`patronymic`)
    FROM `persons` p1
    INNER JOIN `persons` p2 ON
        p1.`person_id` < p2.`person_id` AND
        UPPER(TRIM(p1.`last_name`)) = UPPER(TRIM(p2.`last_name`)) AND
        UPPER(TRIM(p1.`first_name`)) = UPPER(TRIM(p2.`first_name`)) AND
        (UPPER(TRIM(p1.`patronymic`)) = UPPER(TRIM(p2.`patronymic`)) OR
         (p1.`patronymic` IS NULL AND p2.`patronymic` IS NULL)) AND
        p1.`birth_date` = p2.`birth_date`
    LIMIT 10; -- Ограничиваем количество записей для производительности
END$$

-- 10.2. Событие для обновления кэша статистики
CREATE EVENT IF NOT EXISTS `e_nightly_statistics_refresh`
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '02:00:00')
COMMENT 'Ежедневное обновление кэша статистики'
DO
BEGIN
    -- Очистка устаревшего кэша
    DELETE FROM `statistics_cache`
    WHERE `expires_at` < NOW();

    -- Кэширование статистики по судьям за последний месяц
    INSERT INTO `statistics_cache` (`statistic_type`, `period_date`, `judge_participant_id`, `value_json`, `expires_at`)
    SELECT
        'judge_monthly',
        LAST_DAY(CURDATE() - INTERVAL 1 MONTH),
        `judge_participant_id`,
        JSON_OBJECT(
            'total_cases', COUNT(*),
            'completed_cases', SUM(CASE WHEN `status_name` = 'Завершено' THEN 1 ELSE 0 END),
            'avg_duration', AVG(`days_to_resolve`)
        ),
        DATE_ADD(CURDATE(), INTERVAL 1 DAY)
    FROM `v_cases_by_judge`
    WHERE `init_date` >= LAST_DAY(CURDATE() - INTERVAL 1 MONTH) + INTERVAL 1 DAY - INTERVAL 1 YEAR
    GROUP BY `judge_participant_id`;

    -- Логирование завершения
    INSERT INTO `system_audit_log` (`event_type`, `description`)
    VALUES ('SYSTEM_MAINTENANCE', 'Завершено обновление кэша статистики');
END$$

DELIMITER ;

-- ======================================================================
-- РАЗДЕЛ 11: ФИНАЛЬНАЯ НАСТРОЙКА
-- ======================================================================

-- Включение планировщика событий
SET GLOBAL event_scheduler = ON;

-- Проверка целостности внешних ключей
SET FOREIGN_KEY_CHECKS = 1;

-- Создание пользователя по умолчанию (для разработки)
-- CREATE USER 'court_admin'@'localhost' IDENTIFIED BY 'Admin123!';
-- GRANT ALL PRIVILEGES ON `court_system_db`.* TO 'court_admin'@'localhost';
-- FLUSH PRIVILEGES;

-- ======================================================================
-- СООБЩЕНИЕ ОБ УСПЕШНОМ СОЗДАНИИ БАЗЫ ДАННЫХ
-- ======================================================================

SELECT 'База данных успешно создана!' as `Сообщение`,
       COUNT(*) as `Количество таблиц`
FROM information_schema.tables
WHERE table_schema = 'court_system_db';

-- ======================================================================
-- КОНЕЦ ФАЙЛА
-- ======================================================================