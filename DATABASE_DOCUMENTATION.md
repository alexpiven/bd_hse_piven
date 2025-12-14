# Документация по структуре базы данных судебной системы

## Общее описание

База данных спроектирована для управления информационными потоками в судебной системе. Она обеспечивает нормализованное хранение данных о судебных процессах, участниках, документах и решениях.

## Принципы проектирования

1. **Нормализация**: База данных приведена к третьей нормальной форме (3NF)
2. **Целостность данных**: Использованы внешние ключи с каскадными операциями
3. **Ограничения**: Применены CHECK-ограничения для валидации данных
4. **Индексация**: Созданы индексы для оптимизации запросов

---

## Описание таблиц

### 1. judicial_districts (Судебные округа)

Хранит информацию о судебных округах.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `district_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `district_name` | VARCHAR(255) | Название округа | NOT NULL, UNIQUE |
| `region` | VARCHAR(255) | Регион | NOT NULL |
| `address` | TEXT | Адрес округа | - |
| `created_at` | TIMESTAMP | Дата создания записи | DEFAULT CURRENT_TIMESTAMP |

**Связи:**
- Один-ко-многим с таблицей `judges` (судьи работают в округе)
- Один-ко-многим с таблицей `court_cases` (дела рассматриваются в округе)

**Индексы:**
- PRIMARY KEY на `district_id`
- UNIQUE на `district_name`

---

### 2. case_categories (Категории дел)

Хранит категории судебных дел.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `category_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `category_name` | VARCHAR(255) | Название категории | NOT NULL, UNIQUE |
| `description` | TEXT | Описание категории | - |
| `created_at` | TIMESTAMP | Дата создания записи | DEFAULT CURRENT_TIMESTAMP |

**Связи:**
- Один-ко-многим с таблицей `court_cases` (каждое дело относится к категории)

**Индексы:**
- PRIMARY KEY на `category_id`
- UNIQUE на `category_name`

---

### 3. individuals (Физические лица)

Хранит персональные данные физических лиц - участников судебных процессов.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `individual_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `last_name` | VARCHAR(100) | Фамилия | NOT NULL |
| `first_name` | VARCHAR(100) | Имя | NOT NULL |
| `middle_name` | VARCHAR(100) | Отчество | - |
| `date_of_birth` | DATE | Дата рождения | NOT NULL, CHECK (<= CURDATE()) |
| `passport_series` | VARCHAR(10) | Серия паспорта | - |
| `passport_number` | VARCHAR(20) | Номер паспорта | - |
| `phone` | VARCHAR(20) | Телефон | - |
| `email` | VARCHAR(255) | Электронная почта | CHECK (формат email) |
| `address` | TEXT | Адрес проживания | - |
| `created_at` | TIMESTAMP | Дата создания записи | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Дата обновления записи | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

**Связи:**
- Многие-ко-многим с таблицей `court_cases` через `case_participants_individuals`

**Ограничения:**
- UNIQUE на комбинацию (`passport_series`, `passport_number`)
- CHECK: дата рождения не может быть в будущем
- CHECK: email должен соответствовать формату

**Индексы:**
- PRIMARY KEY на `individual_id`
- INDEX на (`last_name`, `first_name`, `middle_name`)
- INDEX на (`passport_series`, `passport_number`)

---

### 4. legal_entities (Юридические лица)

Хранит информацию о юридических лицах - участниках судебных процессов.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `legal_entity_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `company_name` | VARCHAR(255) | Название компании | NOT NULL |
| `inn` | VARCHAR(20) | ИНН | UNIQUE, CHECK (10 или 12 цифр) |
| `ogrn` | VARCHAR(20) | ОГРН | - |
| `legal_address` | TEXT | Юридический адрес | - |
| `actual_address` | TEXT | Фактический адрес | - |
| `phone` | VARCHAR(20) | Телефон | - |
| `email` | VARCHAR(255) | Электронная почта | CHECK (формат email) |
| `director_name` | VARCHAR(255) | ФИО директора | - |
| `created_at` | TIMESTAMP | Дата создания записи | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Дата обновления записи | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

**Связи:**
- Многие-ко-многим с таблицей `court_cases` через `case_participants_legal_entities`

**Ограничения:**
- UNIQUE на `inn`
- CHECK: ИНН должен содержать 10 или 12 цифр
- CHECK: email должен соответствовать формату

**Индексы:**
- PRIMARY KEY на `legal_entity_id`
- INDEX на `company_name`
- INDEX на `inn`

---

### 5. judges (Судьи)

Хранит информацию о судьях.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `judge_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `last_name` | VARCHAR(100) | Фамилия | NOT NULL |
| `first_name` | VARCHAR(100) | Имя | NOT NULL |
| `middle_name` | VARCHAR(100) | Отчество | - |
| `date_of_birth` | DATE | Дата рождения | NOT NULL, CHECK (<= CURDATE()) |
| `judge_number` | VARCHAR(50) | Номер судьи | UNIQUE |
| `district_id` | INT | ID округа | NOT NULL, FOREIGN KEY |
| `position` | VARCHAR(255) | Должность | - |
| `phone` | VARCHAR(20) | Телефон | - |
| `email` | VARCHAR(255) | Электронная почта | CHECK (формат email) |
| `hire_date` | DATE | Дата приема на работу | NOT NULL, CHECK (<= CURDATE()) |
| `created_at` | TIMESTAMP | Дата создания записи | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Дата обновления записи | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

**Связи:**
- Многие-к-одному с таблицей `judicial_districts` (судья работает в округе)
- Один-ко-многим с таблицей `court_cases` (судья рассматривает дела)
- Один-ко-многим с таблицей `court_documents` (судья выдает документы)
- Один-ко-многим с таблицей `case_decisions` (судья принимает решения)

**Ограничения:**
- FOREIGN KEY на `district_id` → `judicial_districts(district_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- UNIQUE на `judge_number`
- CHECK: дата рождения не может быть в будущем
- CHECK: дата приема на работу не может быть в будущем

**Индексы:**
- PRIMARY KEY на `judge_id`
- INDEX на (`last_name`, `first_name`, `middle_name`)

---

### 6. court_cases (Судебные дела)

Хранит информацию о судебных делах.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `case_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `case_number` | VARCHAR(100) | Номер дела | NOT NULL, UNIQUE |
| `category_id` | INT | ID категории | NOT NULL, FOREIGN KEY |
| `judge_id` | INT | ID судьи | NOT NULL, FOREIGN KEY |
| `district_id` | INT | ID округа | NOT NULL, FOREIGN KEY |
| `case_description` | TEXT | Описание дела | - |
| `filing_date` | DATE | Дата подачи иска | NOT NULL, CHECK (<= CURDATE()) |
| `start_date` | DATE | Дата начала рассмотрения | CHECK (>= filing_date) |
| `end_date` | DATE | Дата окончания рассмотрения | CHECK (>= start_date или filing_date) |
| `status` | ENUM | Статус дела | NOT NULL, DEFAULT 'pending' |
| `created_at` | TIMESTAMP | Дата создания записи | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Дата обновления записи | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

**Возможные значения статуса:**
- `pending` - Ожидает рассмотрения
- `in_progress` - В процессе рассмотрения
- `completed` - Завершено
- `closed` - Закрыто
- `dismissed` - Снято с рассмотрения

**Связи:**
- Многие-к-одному с таблицей `case_categories` (дело относится к категории)
- Многие-к-одному с таблицей `judges` (дело рассматривает судья)
- Многие-к-одному с таблицей `judicial_districts` (дело рассматривается в округе)
- Один-ко-многим с таблицей `case_participants_individuals` (участники - физические лица)
- Один-ко-многим с таблицей `case_participants_legal_entities` (участники - юридические лица)
- Один-ко-многим с таблицей `court_documents` (документы по делу)
- Один-к-одному с таблицей `case_decisions` (решение по делу)

**Ограничения:**
- FOREIGN KEY на `category_id` → `case_categories(category_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- FOREIGN KEY на `judge_id` → `judges(judge_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- FOREIGN KEY на `district_id` → `judicial_districts(district_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- CHECK: дата подачи не может быть в будущем
- CHECK: дата начала >= даты подачи
- CHECK: дата окончания >= даты начала или даты подачи

**Индексы:**
- PRIMARY KEY на `case_id`
- UNIQUE на `case_number`
- INDEX на `status`
- INDEX на (`filing_date`, `start_date`, `end_date`)

---

### 7. participant_roles (Роли участников)

Справочник ролей участников судебного процесса.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `role_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `role_name` | VARCHAR(50) | Название роли | NOT NULL, UNIQUE |
| `description` | TEXT | Описание роли | - |

**Возможные значения ролей:**
- `истец` - Лицо, подавшее иск
- `ответчик` - Лицо, к которому предъявлен иск
- `адвокат` - Представитель одной из сторон
- `третье_лицо` - Лицо, имеющее интерес в исходе дела
- `свидетель` - Лицо, дающее показания

**Связи:**
- Один-ко-многим с таблицей `case_participants_individuals`
- Один-ко-многим с таблицей `case_participants_legal_entities`

**Индексы:**
- PRIMARY KEY на `role_id`
- UNIQUE на `role_name`

---

### 8. case_participants_individuals (Участники дел - физические лица)

Связующая таблица между делами и физическими лицами.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `participation_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `case_id` | INT | ID дела | NOT NULL, FOREIGN KEY |
| `individual_id` | INT | ID физического лица | NOT NULL, FOREIGN KEY |
| `role_id` | INT | ID роли | NOT NULL, FOREIGN KEY |
| `joined_date` | DATE | Дата присоединения к делу | NOT NULL, DEFAULT CURDATE(), CHECK (<= CURDATE()) |
| `notes` | TEXT | Примечания | - |

**Связи:**
- Многие-к-одному с таблицей `court_cases` (участник в деле)
- Многие-к-одному с таблицей `individuals` (физическое лицо)
- Многие-к-одному с таблицей `participant_roles` (роль участника)

**Ограничения:**
- FOREIGN KEY на `case_id` → `court_cases(case_id)` (ON DELETE CASCADE, ON UPDATE CASCADE)
- FOREIGN KEY на `individual_id` → `individuals(individual_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- FOREIGN KEY на `role_id` → `participant_roles(role_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- UNIQUE на комбинацию (`case_id`, `individual_id`, `role_id`) - одно лицо не может иметь одну роль в одном деле дважды
- CHECK: дата присоединения не может быть в будущем

**Индексы:**
- PRIMARY KEY на `participation_id`
- INDEX на `individual_id`
- INDEX на `case_id`
- UNIQUE на (`case_id`, `individual_id`, `role_id`)

---

### 9. case_participants_legal_entities (Участники дел - юридические лица)

Связующая таблица между делами и юридическими лицами.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `participation_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `case_id` | INT | ID дела | NOT NULL, FOREIGN KEY |
| `legal_entity_id` | INT | ID юридического лица | NOT NULL, FOREIGN KEY |
| `role_id` | INT | ID роли | NOT NULL, FOREIGN KEY |
| `joined_date` | DATE | Дата присоединения к делу | NOT NULL, DEFAULT CURDATE(), CHECK (<= CURDATE()) |
| `notes` | TEXT | Примечания | - |

**Связи:**
- Многие-к-одному с таблицей `court_cases` (участник в деле)
- Многие-к-одному с таблицей `legal_entities` (юридическое лицо)
- Многие-к-одному с таблицей `participant_roles` (роль участника)

**Ограничения:**
- FOREIGN KEY на `case_id` → `court_cases(case_id)` (ON DELETE CASCADE, ON UPDATE CASCADE)
- FOREIGN KEY на `legal_entity_id` → `legal_entities(legal_entity_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- FOREIGN KEY на `role_id` → `participant_roles(role_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- UNIQUE на комбинацию (`case_id`, `legal_entity_id`, `role_id`)
- CHECK: дата присоединения не может быть в будущем

**Индексы:**
- PRIMARY KEY на `participation_id`
- INDEX на `legal_entity_id`
- INDEX на `case_id`
- UNIQUE на (`case_id`, `legal_entity_id`, `role_id`)

---

### 10. court_documents (Судебные документы)

Хранит информацию о судебных документах, выданных в рамках дел.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `document_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `case_id` | INT | ID дела | NOT NULL, FOREIGN KEY |
| `document_number` | VARCHAR(100) | Номер документа | NOT NULL |
| `document_type` | VARCHAR(100) | Тип документа | NOT NULL |
| `judge_id` | INT | ID судьи | NOT NULL, FOREIGN KEY |
| `issue_date` | DATE | Дата выдачи | NOT NULL, CHECK (<= CURDATE()) |
| `decision_type` | ENUM | Тип решения | NOT NULL |
| `decision_text` | TEXT | Текст решения | - |
| `created_at` | TIMESTAMP | Дата создания записи | DEFAULT CURRENT_TIMESTAMP |
| `updated_at` | TIMESTAMP | Дата обновления записи | DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP |

**Возможные значения типа решения:**
- `positive` - Положительное
- `negative` - Отрицательное
- `partial` - Частичное
- `dismissed` - Отклонено
- `other` - Прочее

**Связи:**
- Многие-к-одному с таблицей `court_cases` (документ относится к делу)
- Многие-к-одному с таблицей `judges` (документ выдан судьей)

**Ограничения:**
- FOREIGN KEY на `case_id` → `court_cases(case_id)` (ON DELETE CASCADE, ON UPDATE CASCADE)
- FOREIGN KEY на `judge_id` → `judges(judge_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- UNIQUE на комбинацию (`case_id`, `document_number`) - уникальный номер документа в рамках дела
- CHECK: дата выдачи не может быть в будущем

**Индексы:**
- PRIMARY KEY на `document_id`
- INDEX на `case_id`
- INDEX на `judge_id`
- INDEX на `issue_date`
- UNIQUE на (`case_id`, `document_number`)

---

### 11. case_decisions (Решения по делам)

Хранит финальные решения по судебным делам.

| Атрибут | Тип | Описание | Ограничения |
|---------|-----|----------|-------------|
| `decision_id` | INT | Первичный ключ | AUTO_INCREMENT, PRIMARY KEY |
| `case_id` | INT | ID дела | NOT NULL, UNIQUE, FOREIGN KEY |
| `decision_date` | DATE | Дата принятия решения | NOT NULL, CHECK (<= CURDATE()) |
| `decision_type` | ENUM | Тип решения | NOT NULL |
| `decision_text` | TEXT | Текст решения | - |
| `judge_id` | INT | ID судьи | NOT NULL, FOREIGN KEY |
| `created_at` | TIMESTAMP | Дата создания записи | DEFAULT CURRENT_TIMESTAMP |

**Возможные значения типа решения:**
- `satisfied` - Удовлетворено
- `rejected` - Отклонено
- `partially_satisfied` - Удовлетворено частично
- `dismissed` - Снято с рассмотрения
- `settled` - Урегулировано

**Связи:**
- Один-к-одному с таблицей `court_cases` (одно решение на одно дело)
- Многие-к-одному с таблицей `judges` (решение принято судьей)

**Ограничения:**
- FOREIGN KEY на `case_id` → `court_cases(case_id)` (ON DELETE CASCADE, ON UPDATE CASCADE)
- FOREIGN KEY на `judge_id` → `judges(judge_id)` (ON DELETE RESTRICT, ON UPDATE CASCADE)
- UNIQUE на `case_id` - одно дело может иметь только одно решение
- CHECK: дата решения не может быть в будущем

**Индексы:**
- PRIMARY KEY на `decision_id`
- UNIQUE на `case_id`
- INDEX на `decision_date`
- INDEX на `decision_type`

---

## Диаграмма связей (ER-диаграмма)

```
judicial_districts (1) ────< (N) judges
judicial_districts (1) ────< (N) court_cases
case_categories (1) ────< (N) court_cases
judges (1) ────< (N) court_cases
judges (1) ────< (N) court_documents
judges (1) ────< (N) case_decisions

court_cases (1) ────< (N) case_participants_individuals
individuals (1) ────< (N) case_participants_individuals
participant_roles (1) ────< (N) case_participants_individuals

court_cases (1) ────< (N) case_participants_legal_entities
legal_entities (1) ────< (N) case_participants_legal_entities
participant_roles (1) ────< (N) case_participants_legal_entities

court_cases (1) ────< (N) court_documents
court_cases (1) ────< (1) case_decisions
```

---

## Механизмы предотвращения дублирования и некорректных данных

### 1. Ограничения уникальности (UNIQUE)
- Номера дел (`court_cases.case_number`)
- Номера судей (`judges.judge_number`)
- ИНН юридических лиц (`legal_entities.inn`)
- Комбинации паспортных данных (`individuals.passport_series`, `passport_number`)
- Комбинации участников в делах (предотвращение дублирования ролей)

### 2. Проверочные ограничения (CHECK)
- Даты не могут быть в будущем
- Логические проверки дат (end_date >= start_date)
- Формат email адресов
- Формат ИНН (10 или 12 цифр)

### 3. Внешние ключи (FOREIGN KEY)
- Обеспечивают ссылочную целостность
- ON DELETE CASCADE для зависимых записей (документы, участники)
- ON DELETE RESTRICT для основных сущностей (судьи, участники)

### 4. Ограничения NOT NULL
- Обязательные поля для критически важных данных

---

## Индексы для оптимизации

Индексы созданы для следующих полей:
- Первичные ключи (автоматически)
- Внешние ключи
- Часто используемые в поиске поля (ФИО, номера документов, даты)
- Комбинации полей для сложных запросов

---

## Примечания по использованию

1. **Каскадное удаление**: При удалении дела автоматически удаляются все связанные записи (участники, документы, решения)

2. **Обновление данных**: Используйте транзакции при сложных операциях обновления

3. **Валидация**: Все ограничения проверяются на уровне БД, но рекомендуется также валидировать данные на уровне приложения

4. **Производительность**: Для больших объемов данных может потребоваться дополнительная оптимизация индексов

