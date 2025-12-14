-- =====================================================
-- ОПЕРАЦИИ ДОБАВЛЕНИЯ, ОБНОВЛЕНИЯ И УДАЛЕНИЯ ДАННЫХ
-- =====================================================

USE court_system;

-- =====================================================
-- 6. Добавление записи о новом участнике дела с персональными данными
-- =====================================================

-- Добавление нового физического лица
INSERT INTO individuals (
    last_name, 
    first_name, 
    middle_name, 
    date_of_birth, 
    passport_series, 
    passport_number, 
    phone, 
    email, 
    address
) VALUES (
    'Кузнецов',
    'Андрей',
    'Викторович',
    '1991-03-25',
    '4506',
    '678901',
    '+7-916-666-77-88',
    'kuznetsov@mail.ru',
    'г. Москва, ул. Садовая, д. 5, кв. 10'
);

-- Получение ID только что добавленного участника
SET @new_individual_id = LAST_INSERT_ID();

-- Добавление участника в дело (например, в дело с ID = 4)
INSERT INTO case_participants_individuals (
    case_id,
    individual_id,
    role_id,
    joined_date,
    notes
) VALUES (
    4,  -- ID дела
    @new_individual_id,
    (SELECT role_id FROM participant_roles WHERE role_name = 'истец'),
    CURDATE(),
    'Новый участник дела'
);

-- Добавление нового юридического лица
INSERT INTO legal_entities (
    company_name,
    inn,
    ogrn,
    legal_address,
    actual_address,
    phone,
    email,
    director_name
) VALUES (
    'ООО "Зета"',
    '7705678901',
    '1027705678901',
    'г. Москва, ул. Садовая, д. 10',
    'г. Москва, ул. Садовая, д. 10',
    '+7-495-666-77-88',
    'info@zeta.ru',
    'Кузнецов Андрей Викторович'
);

SET @new_legal_entity_id = LAST_INSERT_ID();

-- Добавление юридического лица в дело
INSERT INTO case_participants_legal_entities (
    case_id,
    legal_entity_id,
    role_id,
    joined_date,
    notes
) VALUES (
    4,  -- ID дела
    @new_legal_entity_id,
    (SELECT role_id FROM participant_roles WHERE role_name = 'ответчик'),
    CURDATE(),
    'Новое юридическое лицо в деле'
);

-- =====================================================
-- 7.1. Обновление контактных данных участника судебного процесса
-- =====================================================

-- Обновление по ID
UPDATE individuals
SET 
    phone = '+7-916-999-88-77',
    email = 'newemail@mail.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE individual_id = 1;

-- Обновление по ФИО
UPDATE individuals
SET 
    phone = '+7-916-888-77-66',
    email = 'updated@mail.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE last_name = 'Смирнов'
  AND first_name = 'Иван'
  AND (middle_name = 'Петрович' OR middle_name IS NULL);

-- Обновление по паспортным данным
UPDATE individuals
SET 
    phone = '+7-916-777-66-55',
    email = 'bypassport@mail.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE passport_series = '4502'
  AND passport_number = '234567';

-- Обновление контактных данных юридического лица
UPDATE legal_entities
SET 
    phone = '+7-495-999-88-77',
    email = 'newinfo@alpha.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE legal_entity_id = 1;

-- Обновление по названию компании
UPDATE legal_entities
SET 
    phone = '+7-495-888-77-66',
    email = 'updated@beta.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE company_name = 'ООО "Бета"';

-- Обновление по ИНН
UPDATE legal_entities
SET 
    phone = '+7-495-777-66-55',
    email = 'byinn@gamma.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE inn = '7812345678';

-- =====================================================
-- 7.2. Удаление записи о деле, которое было закрыто или снято с рассмотрения
-- =====================================================

-- ВАЖНО: Благодаря ON DELETE CASCADE, все связанные записи будут удалены автоматически:
-- - case_participants_individuals
-- - case_participants_legal_entities
-- - court_documents
-- - case_decisions

-- Перед удалением можно проверить связанные данные
SELECT 
    'Участники (физические лица)' AS table_name,
    COUNT(*) AS records_count
FROM case_participants_individuals
WHERE case_id = 1
UNION ALL
SELECT 
    'Участники (юридические лица)' AS table_name,
    COUNT(*) AS records_count
FROM case_participants_legal_entities
WHERE case_id = 1
UNION ALL
SELECT 
    'Документы' AS table_name,
    COUNT(*) AS records_count
FROM court_documents
WHERE case_id = 1
UNION ALL
SELECT 
    'Решения' AS table_name,
    COUNT(*) AS records_count
FROM case_decisions
WHERE case_id = 1;

-- Удаление дела (все связанные записи удалятся автоматически)
-- ВНИМАНИЕ: Это необратимая операция!
-- DELETE FROM court_cases WHERE case_id = 1;

-- Безопасное удаление: сначала обновляем статус, затем удаляем
-- Обновление статуса дела перед удалением
UPDATE court_cases
SET 
    status = 'dismissed',
    end_date = CURDATE(),
    updated_at = CURRENT_TIMESTAMP
WHERE case_id = 1;

-- Затем можно удалить (раскомментировать при необходимости)
-- DELETE FROM court_cases WHERE case_id = 1 AND status = 'dismissed';

-- =====================================================
-- 7.3. Добавление записи о новом судебном документе
-- =====================================================

-- Добавление нового судебного документа
INSERT INTO court_documents (
    case_id,
    document_number,
    document_type,
    judge_id,
    issue_date,
    decision_type,
    decision_text
) VALUES (
    4,  -- ID дела
    'DOC-006',  -- Номер документа
    'Постановление',  -- Тип документа
    1,  -- ID судьи
    CURDATE(),  -- Дата выдачи
    'positive',  -- Тип решения
    'Постановление о принятии иска к производству'  -- Текст решения
);

-- Добавление документа с автоматическим определением судьи из дела
INSERT INTO court_documents (
    case_id,
    document_number,
    document_type,
    judge_id,
    issue_date,
    decision_type,
    decision_text
)
SELECT 
    5,  -- ID дела
    'DOC-007',
    'Определение',
    cc.judge_id,  -- Судья из дела
    CURDATE(),
    'other',
    'Определение о назначении экспертизы'
FROM court_cases cc
WHERE cc.case_id = 5;

-- Добавление документа с проверкой существования дела
INSERT INTO court_documents (
    case_id,
    document_number,
    document_type,
    judge_id,
    issue_date,
    decision_type,
    decision_text
)
SELECT 
    6,
    'DOC-008',
    'Решение суда',
    cc.judge_id,
    CURDATE(),
    'partial',
    'Решение принято частично'
FROM court_cases cc
WHERE cc.case_id = 6
  AND NOT EXISTS (
      SELECT 1 
      FROM court_documents cd 
      WHERE cd.case_id = 6 
        AND cd.document_number = 'DOC-008'
  );

-- =====================================================
-- ДОПОЛНИТЕЛЬНЫЕ ПОЛЕЗНЫЕ ОПЕРАЦИИ
-- =====================================================

-- Добавление решения по делу
INSERT INTO case_decisions (
    case_id,
    decision_date,
    decision_type,
    decision_text,
    judge_id
)
SELECT 
    4,
    CURDATE(),
    'satisfied',
    'Иск удовлетворен полностью. Взыскать с ответчика сумму в размере 1000000 рублей.',
    cc.judge_id
FROM court_cases cc
WHERE cc.case_id = 4
  AND NOT EXISTS (
      SELECT 1 
      FROM case_decisions cd 
      WHERE cd.case_id = 4
  );

-- Обновление статуса дела при добавлении решения
UPDATE court_cases
SET 
    status = 'completed',
    end_date = CURDATE(),
    updated_at = CURRENT_TIMESTAMP
WHERE case_id = 4
  AND EXISTS (
      SELECT 1 
      FROM case_decisions cd 
      WHERE cd.case_id = 4
  );

-- Добавление нового судьи
INSERT INTO judges (
    last_name,
    first_name,
    middle_name,
    date_of_birth,
    judge_number,
    district_id,
    position,
    phone,
    email,
    hire_date
) VALUES (
    'Соколов',
    'Владимир',
    'Андреевич',
    '1979-04-12',
    'JUDGE-006',
    1,
    'Судья',
    '+7-495-456-78-90',
    'sokolov@court.ru',
    CURDATE()
);

-- Добавление нового дела
INSERT INTO court_cases (
    case_number,
    category_id,
    judge_id,
    district_id,
    case_description,
    filing_date,
    start_date,
    status
) VALUES (
    'ГК-2024-005',
    1,  -- Гражданские дела
    1,  -- Судья
    1,  -- Округ
    'Исковое заявление о возмещении морального вреда',
    CURDATE(),
    DATE_ADD(CURDATE(), INTERVAL 15 DAY),
    'pending'
);

