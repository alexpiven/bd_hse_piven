# Отчёт по проектированию базы данных судебной системы

## 1. Определение таблиц и их атрибутов

База данных состоит из 12 таблиц, организованных в соответствии с принципами нормализации (3NF):

### Справочники (4 таблицы):
1. **judicial_districts** - Судебные округа
2. **case_categories** - Категории дел
3. **document_types** - Типы документов
4. **participant_roles** - Роли участников процесса

### Участники процесса (3 таблицы):
5. **individuals** - Физические лица
6. **legal_entities** - Юридические лица
7. **judges** - Судьи

### Дела и документы (5 таблиц):
8. **court_cases** - Судебные дела
9. **case_participants_individuals** - Участники дел (физические лица)
10. **case_participants_legal_entities** - Участники дел (юридические лица)
11. **court_documents** - Судебные документы
12. **case_decisions** - Решения по делам

Подробное описание всех таблиц, атрибутов и связей представлено в SQL-файле со структурой базы данных.

## 2. Нормализация данных

База данных приведена к третьей нормальной форме (3NF):
- Устранена избыточность данных через создание справочников
- Разделены физические и юридические лица
- Созданы связующие таблицы для участников дел
- Установлены первичные и внешние ключи
- Отношения между таблицами отражают реальные зависимости в судебном процессе

## 3. Ограничения на атрибуты

Реализованы следующие ограничения:

### Проверочные ограничения (CHECK):
- **Даты**: не могут быть в будущем, логические проверки (end_date >= start_date)
- **Email**: регулярные выражения для проверки формата
- **Телефоны**: формат +7XXXXXXXXXX или аналогичный
- **ИНН**: 10 или 12 цифр
- **Строки**: проверка на непустоту (LENGTH(TRIM(...)) > 0)
- **Диапазоны дат**: дата рождения не старше 120 лет, дата приема на работу не раньше даты рождения

### Ограничения уникальности (UNIQUE):
- Номера дел, судей, ИНН
- Комбинации паспортных данных
- Комбинации участников в делах (предотвращение дублирования ролей)

### Ограничения NOT NULL:
- Обязательные поля для критически важных данных (ФИО, даты, номера)

## 4. Механизмы предотвращения дублирования и некорректных данных

1. **UNIQUE ограничения** на ключевые поля и комбинации полей
2. **CHECK ограничения** для валидации форматов и значений
3. **Внешние ключи** с правильными ON DELETE/UPDATE правилами:
   - ON DELETE CASCADE для зависимых записей (документы, участники)
   - ON DELETE RESTRICT для основных сущностей (судьи, участники)
4. **Триггеры** для автоматического обновления временных меток
5. **ENUM** для ограничения значений статусов и типов решений

## 5. Запросы для извлечения информации

### 5.1. Вывод списка дел, в которых участвует определённое физическое или юридическое лицо

**Для физического лица (по ID):**
```sql
SELECT 
    cc.case_id, cc.case_number, cc.case_description,
    cc.filing_date, cc.status, pr.role_name AS participant_role,
    CONCAT(i.last_name, ' ', i.first_name, ' ', COALESCE(i.middle_name, '')) AS participant_name
FROM court_cases cc
INNER JOIN case_participants_individuals cpi ON cc.case_id = cpi.case_id
INNER JOIN individuals i ON cpi.individual_id = i.individual_id
INNER JOIN participant_roles pr ON cpi.role_id = pr.role_id
WHERE i.individual_id = 1
ORDER BY cc.filing_date DESC;
```

**Для юридического лица (по названию):**
```sql
SELECT 
    cc.case_id, cc.case_number, cc.case_description,
    cc.filing_date, cc.status, pr.role_name AS participant_role,
    le.company_name AS participant_name
FROM court_cases cc
INNER JOIN case_participants_legal_entities cple ON cc.case_id = cple.case_id
INNER JOIN legal_entities le ON cple.legal_entity_id = le.legal_entity_id
INNER JOIN participant_roles pr ON cple.role_id = pr.role_id
WHERE le.company_name LIKE '%Альфа%'
ORDER BY cc.filing_date DESC;
```

### 5.2. Вывод списка дел, над которыми работает конкретный судья

```sql
SELECT 
    cc.case_id, cc.case_number, cc.case_description,
    cc.filing_date, cc.start_date, cc.end_date, cc.status,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name
FROM court_cases cc
INNER JOIN judges j ON cc.judge_id = j.judge_id
WHERE j.judge_id = 1
ORDER BY cc.filing_date DESC;
```

### 5.3. Вычисление среднего времени рассмотрения дел для каждого судьи

```sql
SELECT 
    j.judge_id,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name,
    COUNT(cc.case_id) AS completed_cases,
    ROUND(AVG(DATEDIFF(cc.end_date, COALESCE(cc.start_date, cc.filing_date))), 2) AS avg_days_to_complete
FROM judges j
INNER JOIN court_cases cc ON j.judge_id = cc.judge_id
WHERE cc.status = 'completed' AND cc.end_date IS NOT NULL
GROUP BY j.judge_id, j.last_name, j.first_name, j.middle_name
ORDER BY avg_days_to_complete;
```

### 5.4. Рейтинг судей по количеству успешно завершённых дел

```sql
SELECT 
    j.judge_id,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name,
    COUNT(cc.case_id) AS total_completed_cases,
    COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') THEN 1 END) AS successful_cases,
    ROUND(COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') THEN 1 END) * 100.0 / COUNT(cc.case_id), 2) AS success_rate_percent
FROM judges j
INNER JOIN court_cases cc ON j.judge_id = cc.judge_id
LEFT JOIN case_decisions cd ON cc.case_id = cd.case_id
WHERE cc.status = 'completed'
GROUP BY j.judge_id, j.last_name, j.first_name, j.middle_name
ORDER BY successful_cases DESC, success_rate_percent DESC;
```

### 5.5. Список судей, рассмотревших более определённого количества дел за последний год

```sql
SELECT 
    j.judge_id,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name,
    COUNT(cc.case_id) AS cases_count
FROM judges j
INNER JOIN court_cases cc ON j.judge_id = cc.judge_id
WHERE cc.filing_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
  AND cc.status = 'completed'
GROUP BY j.judge_id, j.last_name, j.first_name, j.middle_name
HAVING COUNT(cc.case_id) > 3
ORDER BY cases_count DESC;
```

### 5.6. Список юридических лиц, выигравших большинство своих дел по определённой категории

```sql
SELECT 
    le.legal_entity_id, le.company_name, cat.category_name,
    COUNT(cc.case_id) AS total_cases,
    COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') 
               AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
          THEN 1 END) AS won_cases,
    ROUND(COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') 
                     AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
                THEN 1 END) * 100.0 / COUNT(cc.case_id), 2) AS win_rate_percent
FROM legal_entities le
INNER JOIN case_participants_legal_entities cple ON le.legal_entity_id = cple.legal_entity_id
INNER JOIN court_cases cc ON cple.case_id = cc.case_id
INNER JOIN case_categories cat ON cc.category_id = cat.category_id
LEFT JOIN case_decisions cd ON cc.case_id = cd.case_id
WHERE cat.category_id = 1 AND cc.status = 'completed'
  AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец')
GROUP BY le.legal_entity_id, le.company_name, cat.category_id, cat.category_name
HAVING COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') 
                  AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
             THEN 1 END) > COUNT(CASE WHEN cd.decision_type IN ('rejected', 'dismissed') 
                                       AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
                                  THEN 1 END)
ORDER BY win_rate_percent DESC;
```

### 5.7. Определение категорий дел, по которым чаще всего принимаются отрицательные решения

```sql
SELECT 
    cat.category_id, cat.category_name,
    COUNT(cc.case_id) AS total_cases,
    COUNT(CASE WHEN cd.decision_type IN ('rejected', 'dismissed') THEN 1 END) AS negative_decisions,
    ROUND(COUNT(CASE WHEN cd.decision_type IN ('rejected', 'dismissed') THEN 1 END) * 100.0 / COUNT(cc.case_id), 2) AS negative_rate_percent
FROM case_categories cat
INNER JOIN court_cases cc ON cat.category_id = cc.category_id
LEFT JOIN case_decisions cd ON cc.case_id = cd.case_id
WHERE cc.status = 'completed'
GROUP BY cat.category_id, cat.category_name
HAVING COUNT(cc.case_id) > 0
ORDER BY negative_decisions DESC, negative_rate_percent DESC;
```

### 5.8. Список физических лиц, выигравших все свои дела, и судей, рассмотревших эти дела

```sql
SELECT 
    i.individual_id,
    CONCAT(i.last_name, ' ', i.first_name, ' ', COALESCE(i.middle_name, '')) AS individual_name,
    COUNT(DISTINCT cc.case_id) AS total_cases,
    COUNT(DISTINCT CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') 
                        AND cpi.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
                   THEN cc.case_id END) AS won_cases,
    GROUP_CONCAT(DISTINCT CONCAT(j.last_name, ' ', j.first_name) SEPARATOR ', ') AS judges_names
FROM individuals i
INNER JOIN case_participants_individuals cpi ON i.individual_id = cpi.individual_id
INNER JOIN court_cases cc ON cpi.case_id = cc.case_id
INNER JOIN judges j ON cc.judge_id = j.judge_id
LEFT JOIN case_decisions cd ON cc.case_id = cd.case_id
WHERE cc.status = 'completed'
  AND cpi.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец')
GROUP BY i.individual_id, i.last_name, i.first_name, i.middle_name
HAVING COUNT(DISTINCT cc.case_id) = COUNT(DISTINCT CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') 
                                                         AND cpi.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
                                                    THEN cc.case_id END)
  AND COUNT(DISTINCT cc.case_id) > 0
ORDER BY total_cases DESC;
```

### 5.9. Отслеживание динамики количества дел по категориям за разные периоды

**По месяцам:**
```sql
SELECT 
    cat.category_name,
    DATE_FORMAT(cc.filing_date, '%Y-%m') AS period,
    COUNT(cc.case_id) AS cases_count
FROM case_categories cat
INNER JOIN court_cases cc ON cat.category_id = cc.category_id
WHERE cc.filing_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY cat.category_id, cat.category_name, DATE_FORMAT(cc.filing_date, '%Y-%m')
ORDER BY period DESC, cases_count DESC;
```

**По кварталам:**
```sql
SELECT 
    cat.category_name,
    CONCAT(YEAR(cc.filing_date), '-Q', QUARTER(cc.filing_date)) AS period,
    COUNT(cc.case_id) AS cases_count
FROM case_categories cat
INNER JOIN court_cases cc ON cat.category_id = cc.category_id
WHERE cc.filing_date >= DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
GROUP BY cat.category_id, cat.category_name, YEAR(cc.filing_date), QUARTER(cc.filing_date)
ORDER BY period DESC, cases_count DESC;
```

### 5.10. Определение судебных округов с наиболее эффективными показателями рассмотрения дел

```sql
SELECT 
    jd.district_id, jd.district_name, jd.region,
    COUNT(cc.case_id) AS total_cases,
    COUNT(CASE WHEN cc.status = 'completed' THEN 1 END) AS completed_cases,
    ROUND(AVG(CASE WHEN cc.end_date IS NOT NULL AND cc.start_date IS NOT NULL 
               THEN DATEDIFF(cc.end_date, cc.start_date) END), 2) AS avg_days_to_complete,
    ROUND(COUNT(CASE WHEN cc.status = 'completed' THEN 1 END) * 100.0 / COUNT(cc.case_id), 2) AS completion_rate_percent,
    ROUND(COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') THEN 1 END) * 100.0 / 
          NULLIF(COUNT(CASE WHEN cc.status = 'completed' THEN 1 END), 0), 2) AS satisfaction_rate_percent
FROM judicial_districts jd
INNER JOIN court_cases cc ON jd.district_id = cc.district_id
LEFT JOIN case_decisions cd ON cc.case_id = cd.case_id
WHERE cc.filing_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY jd.district_id, jd.district_name, jd.region
HAVING COUNT(cc.case_id) > 0
ORDER BY completion_rate_percent DESC, avg_days_to_complete ASC, satisfaction_rate_percent DESC;
```

## 6. Добавление записи о новом участнике дела

### Добавление физического лица с персональными данными:

```sql
INSERT INTO individuals (
    last_name, first_name, middle_name, date_of_birth,
    passport_series, passport_number, phone, email, address
) VALUES (
    'Кузнецов', 'Андрей', 'Викторович', '1991-03-25',
    '4506', '678901', '+79166667788', 'kuznetsov@mail.ru',
    'г. Москва, ул. Садовая, д. 5, кв. 10'
);

SET @new_individual_id = LAST_INSERT_ID();

INSERT INTO case_participants_individuals (
    case_id, individual_id, role_id, joined_date, notes
) VALUES (
    4, @new_individual_id,
    (SELECT role_id FROM participant_roles WHERE role_name = 'истец'),
    CURDATE(), 'Новый участник дела'
);
```

### Добавление юридического лица:

```sql
INSERT INTO legal_entities (
    company_name, inn, ogrn, legal_address, actual_address,
    phone, email, director_name
) VALUES (
    'ООО "Зета"', '7705678901', '1027705678901',
    'г. Москва, ул. Садовая, д. 10', 'г. Москва, ул. Садовая, д. 10',
    '+74956667788', 'info@zeta.ru', 'Кузнецов Андрей Викторович'
);
```

## 7. Операции обновления и удаления

### 7.1. Обновление контактных данных участника

**По идентификационным данным (ID):**
```sql
UPDATE individuals
SET phone = '+79169998877', email = 'newemail@mail.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE individual_id = 1;
```

**По ФИО:**
```sql
UPDATE individuals
SET phone = '+79168887766', email = 'updated@mail.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE last_name = 'Смирнов' AND first_name = 'Иван'
  AND (middle_name = 'Петрович' OR middle_name IS NULL);
```

**По паспортным данным:**
```sql
UPDATE individuals
SET phone = '+79167776655', email = 'bypassport@mail.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE passport_series = '4502' AND passport_number = '234567';
```

**Для юридического лица по ИНН:**
```sql
UPDATE legal_entities
SET phone = '+74957776655', email = 'byinn@gamma.ru',
    updated_at = CURRENT_TIMESTAMP
WHERE inn = '7812345678';
```

### 7.2. Удаление записи о деле

**Безопасное удаление с проверкой статуса:**
```sql
-- Сначала обновляем статус
UPDATE court_cases
SET status = 'dismissed', end_date = CURDATE(),
    updated_at = CURRENT_TIMESTAMP
WHERE case_id = 1;

-- Затем удаляем (все связанные записи удалятся автоматически благодаря CASCADE)
DELETE FROM court_cases 
WHERE case_id = 1 AND status = 'dismissed';
```

**Примечание:** Благодаря ON DELETE CASCADE, при удалении дела автоматически удаляются все связанные записи:
- Участники дел (физические и юридические лица)
- Судебные документы
- Решения по делам

### 7.3. Добавление записи о новом судебном документе

```sql
INSERT INTO court_documents (
    case_id, document_type_id, document_number, judge_id,
    issue_date, decision_type, decision_text
) VALUES (
    4, 1, 'DOC-006', 1, CURDATE(), 'positive',
    'Постановление о принятии иска к производству'
);
```

**С автоматическим определением судьи из дела:**
```sql
INSERT INTO court_documents (
    case_id, document_type_id, document_number, judge_id,
    issue_date, decision_type, decision_text
)
SELECT 
    5, 2, 'DOC-007', cc.judge_id, CURDATE(), 'other',
    'Определение о назначении экспертизы'
FROM court_cases cc
WHERE cc.case_id = 5;
```

## 8. Документация по структуре базы данных

### Описание таблиц

Полное описание всех таблиц, их атрибутов, типов данных, ограничений и связей представлено в SQL-файле со структурой базы данных (`database_structure.sql`).

### Основные связи между таблицами:

- **judicial_districts** → **judges** (один-ко-многим)
- **judicial_districts** → **court_cases** (один-ко-многим)
- **case_categories** → **court_cases** (один-ко-многим)
- **judges** → **court_cases** (один-ко-многим)
- **judges** → **court_documents** (один-ко-многим)
- **judges** → **case_decisions** (один-ко-многим)
- **court_cases** → **case_participants_individuals** (один-ко-многим)
- **court_cases** → **case_participants_legal_entities** (один-ко-многим)
- **court_cases** → **court_documents** (один-ко-многим)
- **court_cases** → **case_decisions** (один-к-одному)
- **individuals** → **case_participants_individuals** (один-ко-многим)
- **legal_entities** → **case_participants_legal_entities** (один-ко-многим)
- **participant_roles** → **case_participants_individuals** (один-ко-многим)
- **participant_roles** → **case_participants_legal_entities** (один-ко-многим)
- **document_types** → **court_documents** (один-ко-многим)

### Механизмы обеспечения целостности данных:

1. **Первичные ключи** на всех таблицах
2. **Внешние ключи** с каскадными операциями
3. **CHECK ограничения** для валидации
4. **UNIQUE ограничения** для предотвращения дублирования
5. **Триггеры** для автоматического обновления временных меток
6. **Индексы** для оптимизации запросов

---

**Дата создания:** 2024  
**Версия:** 2.0 (Улучшенная)

