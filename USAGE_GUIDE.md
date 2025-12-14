# Руководство по использованию базы данных судебной системы

## Быстрый старт

### 1. Создание базы данных

```bash
mysql -u root -p < 01_create_database.sql
```

### 2. Загрузка тестовых данных

```bash
mysql -u root -p < 02_insert_initial_data.sql
```

### 3. Выполнение запросов

```bash
mysql -u root -p court_system < 03_queries.sql
```

---

## Примеры использования запросов

### Поиск дел участника

**По ID физического лица:**
```sql
-- В файле 03_queries.sql, раздел 5.1
-- Замените individual_id = 1 на нужный ID
```

**По ФИО:**
```sql
SELECT 
    cc.case_id,
    cc.case_number,
    cc.case_description,
    cc.filing_date,
    cc.status,
    pr.role_name AS participant_role
FROM court_cases cc
INNER JOIN case_participants_individuals cpi ON cc.case_id = cpi.case_id
INNER JOIN individuals i ON cpi.individual_id = i.individual_id
INNER JOIN participant_roles pr ON cpi.role_id = pr.role_id
WHERE i.last_name = 'Смирнов' 
  AND i.first_name = 'Иван';
```

### Статистика по судьям

**Среднее время рассмотрения:**
```sql
SELECT 
    CONCAT(j.last_name, ' ', j.first_name) AS judge_name,
    ROUND(AVG(DATEDIFF(cc.end_date, cc.start_date)), 2) AS avg_days
FROM judges j
INNER JOIN court_cases cc ON j.judge_id = cc.judge_id
WHERE cc.status = 'completed'
GROUP BY j.judge_id;
```

**Рейтинг судей:**
```sql
-- Выполните запрос из раздела 5.4 файла 03_queries.sql
```

---

## Операции с данными

### Добавление нового участника

```sql
-- См. раздел 6 в файле 04_dml_operations.sql
INSERT INTO individuals (
    last_name, first_name, middle_name, 
    date_of_birth, passport_series, passport_number, 
    phone, email, address
) VALUES (
    'Новое', 'Имя', 'Отчество',
    '1990-01-01', '4507', '789012',
    '+7-916-111-22-33', 'new@mail.ru', 'Адрес'
);
```

### Обновление контактов

```sql
-- По ID
UPDATE individuals
SET phone = '+7-916-999-88-77', email = 'new@mail.ru'
WHERE individual_id = 1;

-- По ФИО
UPDATE individuals
SET phone = '+7-916-888-77-66'
WHERE last_name = 'Смирнов' AND first_name = 'Иван';
```

### Добавление документа

```sql
INSERT INTO court_documents (
    case_id, document_number, document_type,
    judge_id, issue_date, decision_type, decision_text
) VALUES (
    1, 'DOC-009', 'Решение суда',
    1, CURDATE(), 'positive', 'Текст решения'
);
```

### Удаление дела

```sql
-- ВНИМАНИЕ: Удалит все связанные записи!
-- Сначала обновите статус
UPDATE court_cases
SET status = 'dismissed', end_date = CURDATE()
WHERE case_id = 1;

-- Затем удалите (если необходимо)
DELETE FROM court_cases WHERE case_id = 1;
```

---

## Часто используемые запросы

### Список всех дел судьи

```sql
SELECT 
    cc.case_number,
    cc.case_description,
    cc.status,
    cc.filing_date
FROM court_cases cc
WHERE cc.judge_id = 1
ORDER BY cc.filing_date DESC;
```

### Дела по категории

```sql
SELECT 
    cc.case_number,
    cc.case_description,
    cc.status
FROM court_cases cc
WHERE cc.category_id = 1;  -- Гражданские дела
```

### Участники дела

```sql
-- Физические лица
SELECT 
    CONCAT(i.last_name, ' ', i.first_name) AS name,
    pr.role_name AS role
FROM case_participants_individuals cpi
INNER JOIN individuals i ON cpi.individual_id = i.individual_id
INNER JOIN participant_roles pr ON cpi.role_id = pr.role_id
WHERE cpi.case_id = 1;

-- Юридические лица
SELECT 
    le.company_name AS name,
    pr.role_name AS role
FROM case_participants_legal_entities cple
INNER JOIN legal_entities le ON cple.legal_entity_id = le.legal_entity_id
INNER JOIN participant_roles pr ON cple.role_id = pr.role_id
WHERE cple.case_id = 1;
```

---

## Рекомендации

1. **Резервное копирование**: Регулярно создавайте резервные копии базы данных
   ```bash
   mysqldump -u root -p court_system > backup.sql
   ```

2. **Транзакции**: Используйте транзакции для сложных операций
   ```sql
   START TRANSACTION;
   -- ваши операции
   COMMIT;  -- или ROLLBACK;
   ```

3. **Индексы**: При работе с большими объемами данных проверяйте использование индексов
   ```sql
   EXPLAIN SELECT ...;
   ```

4. **Валидация**: Всегда проверяйте данные перед вставкой/обновлением

---

## Устранение проблем

### Ошибка дублирования ключа
- Проверьте UNIQUE ограничения
- Используйте INSERT IGNORE или ON DUPLICATE KEY UPDATE

### Ошибка внешнего ключа
- Убедитесь, что связанная запись существует
- Проверьте ON DELETE правила

### Ошибка CHECK ограничения
- Проверьте формат данных (даты, email, ИНН)
- Убедитесь, что даты не в будущем

