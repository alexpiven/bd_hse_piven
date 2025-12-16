## Отчёт по базе данных районного суда


### 1. Общая характеристика проекта

База данных `court_system_db` реализует информационную систему районного суда. В ней учитываются:

- **участники процессов**: физические и юридические лица, сотрудники суда;
- **судебные дела**: их категории, статусы, участники, заседания;
- **документы**: судебные акты, протоколы, исполнительные документы;
- **архив и аудит**: архив дел и участников, журнал системных операций;
- **аналитика**: статистика по судьям, категориям дел и судебным округам.

Скрипт для развёртывания БД: `bd_import.sql` (адаптирован под MySQL 8/9, включает создание БД, всех таблиц, ограничений, представлений, процедур, функций и событий в едином файле).

---

### 2. Структура базы данных

#### 2.1. Основные сущности

- **`persons`** — физические лица (граждане, ИП):
  - ключ: `person_id` (PK);
  - основные атрибуты: ФИО, дата и место рождения, паспортные данные, СНИЛС, ИНН, адреса и контакты;
  - уникальность: `snils`, `inn`, пара `passport_series`+`passport_number`.

- **`legal_entities`** — юридические лица:
  - ключ: `legal_entity_id` (PK);
  - атрибуты: полное/краткое наименование, ИНН, КПП, ОГРН, адреса;
  - связи: `director_person_id` → `persons.person_id`.

- **`court_staff`** — сотрудники суда:
  - ключ: `staff_id` (PK);
  - атрибуты: ссылка на физлицо, должность, отдел, служебный номер судьи, даты приёма/увольнения, флаг активности;
  - связи: `person_id` → `persons.person_id`.

- **`court_cases`** — судебные дела:
  - ключ: `case_id` (PK);
  - атрибуты: `case_number`, категория, статус, даты поступления и решения, краткое описание и результат, номер инстанции;
  - связи: `category_id` → `dict_case_categories`, `status_id` → `dict_case_statuses`, `previous_case_id` (самоссылка), `judge_participant_id` → `case_participants`.

- **`case_participants`** — участники дел (связь многие-ко-многим):
  - ключ: `participant_id` (PK);
  - атрибуты: ссылки на дело, физ/юрлицо, роль, данные об адвокате и представительстве;
  - связи: `case_id` → `court_cases`, `person_id` → `persons`, `legal_entity_id` → `legal_entities`, `role_id` → `dict_roles`.

- **`case_staff`** — назначенные на дело судья и секретарь:
  - ключ: `case_staff_id` (PK);
  - связи: `case_id` → `court_cases`, `judge_participant_id` и `secretary_participant_id` → `case_participants`;
  - уникальность активной записи по делу.

- **`court_sessions`** — судебные заседания:
  - ключ: `session_id` (PK);
  - связи: `case_id` → `court_cases`, `session_type_id` → `dict_session_types`.

- **`session_participants`** — участие конкретных лиц в заседаниях:
  - ключ: `session_participant_id` (PK);
  - связи: `session_id` → `court_sessions`, `case_participant_id` → `case_participants`.

- **`documents`** — документы по делу:
  - ключ: `document_id` (PK);
  - атрибуты: тип документа, внутр. номер, заголовок, путь к файлу, MIME‑тип, автор, даты создания и поступления;
  - связи: `case_id` → `court_cases`, `type_id` → `dict_document_types`, `author_participant_id` → `case_participants`.

- **`enforcement_documents`** — исполнительные документы:
  - ключ: `enforcement_id` (PK);
  - атрибуты: тип, номер, даты выдачи/направления/исполнения, сумма, статус исполнения;
  - связи: `document_id` → `documents`, `case_id` → `court_cases`, `status_id` → `dict_enforcement_statuses`.

#### 2.2. Вспомогательные сущности

- **`case_movements`** — журнал движений дел (смена статусов, судьи и др.).
- **`judicial_districts`** — судебные округа.
- **`judge_districts`** — назначения судей по округам.
- **`system_audit_log`** — журнал аудита изменений.
- **`statistics_cache`** — кэш предрасчитанной статистики.
- **`archived_cases`**, **`archived_case_participants`** — архив дел и их участников.

#### 2.3. Справочники

- **`dict_case_categories`** — категории дел.
- **`dict_case_statuses`** — статусы дел.
- **`dict_roles`** — роли участников.
- **`dict_document_types`** — типы документов.
- **`dict_session_types`** — типы заседаний.
- **`dict_enforcement_statuses`** — статусы исполнительных документов.
- **`dict_movement_types`** — типы движений дел.

#### 2.4. Индексы и нормализация

- **Нормализация**: все основные сущности разнесены по отдельным таблицам, справочники выделены, связи многие‑ко‑многим реализованы через `case_participants` и `session_participants`. 
- **Индексы**:
  - поисковые: по ФИО и дате рождения в `persons`, по статусу/категории/датам в `court_cases`, по типам и датам документов, по ролям участников и т.д.;
  - уникальные: паспортные данные, комбинация ФИО+дата рождения, номер дела+дата, внутр. номера документов, номера исполнительных документов и др.

#### 2.5. Форматы и типы атрибутов (полная справка по полям)

Ниже приведено детальное описание атрибутов всех основных таблиц: типы данных, ожидаемый формат, ключевые ограничения и назначение.

##### 2.5.1. `persons` — физические лица

| Поле                  | Тип          | Формат / пример                         | Ограничения / комментарий                                     |
|-----------------------|-------------|-----------------------------------------|----------------------------------------------------------------|
| `person_id`           | BIGINT PK   | `1`                                     | AUTO_INCREMENT, первичный ключ                                |
| `last_name`           | VARCHAR(100)| `Иванов`                                | NOT NULL, Фамилия; кириллица/латиница                         |
| `first_name`          | VARCHAR(100)| `Иван`                                  | NOT NULL, Имя                                                 |
| `patronymic`          | VARCHAR(100)| `Иванович` / NULL                       | Отчество, может быть NULL                                     |
| `birth_date`          | DATE        | `1980-01-15`                            | CHECK: `>= '1900-01-01' AND <= '2099-12-31'`                  |
| `birth_place`         | VARCHAR(255)| `г. Москва`                             | Место рождения                                                |
| `snils`               | CHAR(14)    | `123-456-789 00`                        | Уникальный, CHECK по шаблону `XXX-XXX-XXX YY`                 |
| `inn`                 | VARCHAR(12) | `770000000000`                          | Уникальный, 10–12 цифр                                        |
| `passport_series`     | VARCHAR(4)  | `4501`                                  | 4 цифры                                                       |
| `passport_number`     | VARCHAR(6)  | `123456`                                | 6 цифр, уникально в паре с серией                             |
| `passport_issued_by`  | VARCHAR(255)| `ОУФМС России по г. Москве`             | Орган, выдавший паспорт                                       |
| `passport_issue_date` | DATE        | `2000-01-20`                            | Дата выдачи, в разумном диапазоне                             |
| `registration_address`| VARCHAR(500)| `г. Москва, ул. Ленина, д. 1, кв. 10`   | Адрес регистрации                                             |
| `actual_address`      | VARCHAR(500)| `г. Москва, ...`                        | Фактический адрес                                             |
| `phone_number`        | VARCHAR(20) | `+7-900-123-45-67`                      | CHECK по шаблону телефона                                     |
| `email`               | VARCHAR(255)| `user@example.com`                      | CHECK по простому REGEXP e‑mail                               |
| `created_at`          | TIMESTAMP   |                                         | DEFAULT CURRENT_TIMESTAMP                                     |
| `updated_at`          | TIMESTAMP   |                                         | Обновляется триггером при изменениях                          |

##### 2.5.2. `legal_entities` — юридические лица

| Поле                 | Тип          | Пример                                              | Ограничения / комментарий                 |
|----------------------|-------------|------------------------------------------------------|------------------------------------------|
| `legal_entity_id`    | BIGINT PK   | `1`                                                  | AUTO_INCREMENT                           |
| `full_name`          | VARCHAR(500)| `Общество с ограниченной ответственностью "Альфа"`   | Полное наименование, NOT NULL            |
| `short_name`         | VARCHAR(255)| `ООО "Альфа"`                                        | Краткое наименование, NOT NULL           |
| `inn`                | VARCHAR(12) | `7701000001`                                         | Уникальный ИНН                           |
| `kpp`                | VARCHAR(9)  | `770101001`                                          | КПП, 9 цифр                              |
| `ogrn`               | VARCHAR(13) | `1027700000001`                                      | ОГРН, 13 цифр                            |
| `legal_address`      | VARCHAR(500)| `г. Москва, ул. Тверская, д. 1`                      | Юридический адрес                        |
| `actual_address`     | VARCHAR(500)|                                                      | Фактический адрес                        |
| `director_person_id` | BIGINT FK   |                                                      | FK → `persons.person_id`                 |
| `created_at`         | TIMESTAMP   |                                                      | DEFAULT CURRENT_TIMESTAMP                |

##### 2.5.3. `court_staff` — сотрудники суда

| Поле               | Тип                 | Пример             | Комментарий                                        |
|--------------------|--------------------|--------------------|----------------------------------------------------|
| `staff_id`         | BIGINT PK          | `1`                | AUTO_INCREMENT                                     |
| `person_id`        | BIGINT FK          |                    | FK → `persons.person_id`                           |
| `position`         | ENUM / TINYINT     | `1` (Судья)        | Должность: Судья, Секретарь, Помощник и др.       |
| `department`       | VARCHAR(255)       | `Гражданский отдел`| Подразделение                                      |
| `judge_id`         | VARCHAR(50)        | `JUDGE-001`        | Внутренний идентификатор судьи                     |
| `employment_date`  | DATE               |                    | Дата приёма                                       |
| `termination_date` | DATE / NULL        |                    | Дата увольнения (при наличии)                      |
| `is_active`        | BOOLEAN            | TRUE/FALSE         | Признак активности                                 |
| `created_at`       | TIMESTAMP          |                    | DEFAULT CURRENT_TIMESTAMP                          |

##### 2.5.4. `court_cases` — судебные дела

| Поле                 | Тип          | Пример        | Комментарий                                                             |
|----------------------|-------------|--------------|-------------------------------------------------------------------------|
| `case_id`            | BIGINT PK   | `1`          | AUTO_INCREMENT                                                          |
| `case_number`        | VARCHAR(100)| `2-1234/2024`| Уникальный номер дела, шаблон `N-NNNN/YYYY`                             |
| `category_id`        | INT FK      |              | FK → `dict_case_categories.category_id`                                 |
| `status_id`          | INT FK      |              | FK → `dict_case_statuses.status_id`                                     |
| `previous_case_id`   | BIGINT FK   | NULL/ID      | Самоссылка на предыдущее дело (апелляция и т.п.)                        |
| `init_date`          | DATE        | `2024-01-10` | Дата поступления, CHECK по диапазону                                    |
| `result_date`        | DATE        | `2024-03-15` | Дата окончания, `>= init_date`, может быть NULL                         |
| `summary`            | VARCHAR(1000)| Краткое описание| Описание сути спора, NOT NULL                                        |
| `result`             | VARCHAR(1000)| `Исковые требования удовлетворено ...` | Текст результата                   |
| `instance_number`    | TINYINT     | `1`          | Номер инстанции (1, 2, 3 …)                                            |
| `judge_participant_id`| BIGINT FK  |              | FK → `case_participants.participant_id` (роль судьи)                    |
| `created_at`         | TIMESTAMP   |              | DEFAULT CURRENT_TIMESTAMP                                               |
| `updated_at`         | TIMESTAMP   |              | Обновляется триггером                                                   |

##### 2.5.5. `case_participants` — участники дел

| Поле               | Тип        | Комментарий                                                   |
|--------------------|-----------|----------------------------------------------------------------|
| `participant_id`   | BIGINT PK | AUTO_INCREMENT                                                 |
| `case_id`          | BIGINT FK | FK → `court_cases.case_id`                                    |
| `person_id`        | BIGINT FK | FK → `persons.person_id`, NULL для чисто юридических лиц      |
| `legal_entity_id`  | BIGINT FK | FK → `legal_entities.legal_entity_id`, NULL для физлиц        |
| `role_id`          | INT FK    | FK → `dict_roles.role_id` (ISTEC, OTVETCH, SVIDETEL и др.)    |
| `representative_id`| BIGINT FK | (опционально) представитель                                 |
| `created_at`       | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP                                     |

##### 2.5.6. `case_staff` — назначенные судья и секретарь

| Поле                   | Тип        | Комментарий                                               |
|------------------------|-----------|------------------------------------------------------------|
| `case_staff_id`        | BIGINT PK | AUTO_INCREMENT                                             |
| `case_id`              | BIGINT FK | FK → `court_cases.case_id`                                |
| `judge_participant_id` | BIGINT FK | FK → `case_participants.participant_id` (судья)           |
| `secretary_participant_id`| BIGINT FK | FK → `case_participants.participant_id` (секретарь)  |
| `assignment_date`      | DATE      | Дата назначения                                            |
| `is_active`            | BOOLEAN   | Только одна активная запись на дело                        |

##### 2.5.7. `court_sessions` — судебные заседания

| Поле            | Тип          | Комментарий                                             |
|-----------------|-------------|----------------------------------------------------------|
| `session_id`    | BIGINT PK   | AUTO_INCREMENT                                           |
| `case_id`       | BIGINT FK   | FK → `court_cases.case_id`                              |
| `session_type_id`| INT FK     | FK → `dict_session_types.type_id`                       |
| `session_date`  | TIMESTAMP   | Дата/время заседания, CHECK: не раньше 2000‑01‑01       |
| `room_number`   | VARCHAR(50) | Номер зала                                               |
| `created_at`    | TIMESTAMP   | DEFAULT CURRENT_TIMESTAMP                                |

##### 2.5.8. `session_participants` — участники заседаний

| Поле                  | Тип        | Комментарий                                      |
|-----------------------|-----------|---------------------------------------------------|
| `session_participant_id`| BIGINT PK| AUTO_INCREMENT                                   |
| `session_id`          | BIGINT FK | FK → `court_sessions.session_id`                 |
| `case_participant_id` | BIGINT FK | FK → `case_participants.participant_id`          |
| `is_present`          | BOOLEAN   | Признак присутствия                              |
| `notes`               | TEXT      | Примечания                                       |
| `created_at`          | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP                        |

##### 2.5.9. `documents` — документы по делу

| Поле                  | Тип          | Пример                                  | Комментарий                                                  |
|-----------------------|-------------|-----------------------------------------|--------------------------------------------------------------|
| `document_id`         | BIGINT PK   |                                         | AUTO_INCREMENT                                               |
| `case_id`             | BIGINT FK   |                                         | FK → `court_cases.case_id`                                  |
| `internal_number`     | VARCHAR(100)| `1-2024`                                | Внутренний номер документа в рамках дела                    |
| `type_id`             | INT FK      |                                         | FK → `dict_document_types.type_id`                          |
| `title`               | VARCHAR(500)| `Решение суда ...`                      | NOT NULL, CHECK: длина ≥ 5                                  |
| `file_path`           | TEXT        | `/storage/cases/2-1234-2024/1.pdf`      | NOT NULL, CHECK по расширениям (`.pdf/.doc/.xls/.jpg/...`)  |
| `file_hash`           | VARCHAR(64) |                                         | SHA‑256, 64 hex‑символа                                     |
| `mime_type`           | VARCHAR(100)| `application/pdf`                       | MIME‑тип                                                     |
| `author_participant_id`| BIGINT FK  |                                         | FK → `case_participants.participant_id`                     |
| `created_date`        | DATE        |                                         | Дата создания, CHECK по диапазону                           |
| `received_date`       | DATE        |                                         | Дата поступления, `>= created_date`                         |
| `description`         | TEXT        |                                         | Свободное описание                                          |
| `created_at`          | TIMESTAMP   |                                         | DEFAULT CURRENT_TIMESTAMP                                   |

##### 2.5.10. `enforcement_documents` — исполнительные документы

| Поле                 | Тип                                   | Комментарий                                       |
|----------------------|--------------------------------------|--------------------------------------------------|
| `enforcement_id`     | BIGINT PK                           | AUTO_INCREMENT                                   |
| `document_id`        | BIGINT FK                           | FK → `documents.document_id`                     |
| `case_id`            | BIGINT FK                           | FK → `court_cases.case_id`                       |
| `enforcement_type`   | ENUM('Исполнительный лист','Судебный приказ','Решение') | Тип исп. документа |
| `enforcement_number` | VARCHAR(100)                        | Номер исполнительного документа                  |
| `issue_date`         | DATE                                | Дата выдачи                                      |
| `bailiff_sent_date`  | DATE / NULL                         | Дата направления приставам                       |
| `execution_date`     | DATE / NULL                         | Дата фактического исполнения                     |
| `amount`             | DECIMAL(18,2)                       | Сумма взыскания                                  |
| `status_id`          | INT FK                              | FK → `dict_enforcement_statuses.status_id`       |

##### 2.5.11. Вспомогательные таблицы

**`case_movements`** — журнал изменений по делам  
Основные поля:  
- `movement_id` BIGINT PK — идентификатор записи;  
- `case_id` BIGINT FK — дело;  
- `movement_type_id` INT FK → `dict_movement_types`;  
- `old_value`/`new_value` TEXT — прежнее и новое значение (обычно статус);  
- `movement_date` DATE — дата изменения;  
- `staff_id` BIGINT FK → `court_staff.staff_id`;  
- `notes` TEXT — комментарий.

**`judicial_districts`** — судебные округа  
- `district_id` BIGINT PK;  
- `district_name` VARCHAR(255) — наименование;  
- `region` VARCHAR(255) — регион/субъект РФ.

**`judge_districts`** — назначения судей по округам  
- `judge_district_id` BIGINT PK;  
- `judge_participant_id` BIGINT FK → `case_participants.participant_id`;  
- `district_id` BIGINT FK → `judicial_districts.district_id`;  
- `assignment_date` DATE;  
- `is_current` BOOLEAN.

**`statistics_cache`** — кэш агрегированной статистики  
- `stat_id` BIGINT PK;  
- `statistic_type` VARCHAR(50) — `judge_monthly`, `category_monthly` и т.п.;  
- `period_date` DATE — конец периода (обычно месяц);  
- `category_id` INT FK (опционально);  
- `judge_participant_id` BIGINT FK (опционально);  
- `district_id` BIGINT FK → `judicial_districts`;  
- `value_json` JSON — агрегаты (`total_cases`, `completed_cases`, `avg_duration_days`);  
- `calculated_at`/`expires_at` DATETIME.

**`system_audit_log`** — журнал аудита  
- `audit_id` BIGINT PK;  
- `event_type` ENUM('INSERT','UPDATE','DELETE');  
- `table_name` VARCHAR(100);  
- `record_id` BIGINT;  
- `old_value`/`new_value` JSON/TEXT;  
- `description` VARCHAR(1000);  
- `user_id` BIGINT NULL;  
- `staff_id` BIGINT FK → `court_staff`;  
- `created_at` TIMESTAMP.

**`archived_cases`** / **`archived_case_participants`** — архив  
Структура аналогична `court_cases` и `case_participants`, но используется для хранения удалённых (архивированных) записей, с дополнительными полями аудита (дата архивации, причина, инициатор).

##### 2.5.12. Справочники (`dict_*`)

Все справочники имеют простую структуру: идентификатор, код (если нужен) и человекочитаемое имя.

**`dict_case_categories`**  
- `category_id` INT PK;  
- `category_code` VARCHAR(50) — технический код;  
- `category_name` VARCHAR(255) — название категории (Гражданское дело, Уголовное дело, …).

**`dict_case_statuses`**  
- `status_id` INT PK;  
- `status_code` VARCHAR(50);  
- `status_name` VARCHAR(255) — например: В производстве, Завершено, Приостановлено.

**`dict_roles`**  
- `role_id` INT PK;  
- `role_code` VARCHAR(50) — `ISTEC`, `OTVETCH`, `POT`, `SVID`, `SUDJA` и др.;  
- `role_name` VARCHAR(255) — человекочитаемое название роли.

**`dict_document_types`**  
- `type_id` INT PK;  
- `type_code` VARCHAR(50) — `ISK_ZAIV`, `RESHENIE`, `PRIGOVOR`, `PROT_SZ` и др.;  
- `type_name` VARCHAR(255).

**`dict_session_types`**  
- `type_id` INT PK;  
- `type_code` VARCHAR(50);  
- `type_name` VARCHAR(255) — предварительное заседание, основное заседание и т.п.

**`dict_enforcement_statuses`**  
- `status_id` INT PK;  
- `status_code` VARCHAR(50);  
- `status_name` VARCHAR(255) — выдан, направлен приставам, исполнен, прекращён и др.

**`dict_movement_types`**  
- `movement_type_id` INT PK;  
- `movement_code` VARCHAR(50);  
- `movement_name` VARCHAR(255) — изменение статуса, смена судьи, передача по подсудности и др.

---

### 3. Целостность данных

- **CHECK‑ограничения**: корректность диапазонов дат (используется статическая дата '2099-12-31' вместо `CURDATE()` для совместимости с MySQL 8/9), форматов СНИЛС, ИНН, паспорта, допустимость расширений файлов, минимальная длина заголовка документа.
- **Внешние ключи**: каскадное удаление зависимых записей (`case_participants`, `court_sessions`, `documents` и др.), `SET NULL` и `RESTRICT` там, где это отражает реальный бизнес‑процесс.
- **Триггеры**:
  - авто‑обновление `updated_at` в `persons` и `court_cases`;
  - проверка согласованности дат дел и документов при вставке/обновлении;
  - запись изменений статуса дела в `case_movements`;
  - логирование изменений лиц в `system_audit_log`.
- **Предотвращение дублей**:
  - составные индексы и уникальные ключи;
  - процедура `sp_add_person` с поиском по ФИО+дата рождения, паспорту, СНИЛС, ИНН;
  - событие `e_daily_duplicate_check`, которое пишет потенциальные дубли в журнал аудита.

---

### 4. Хранимые процедуры, функции и события

- **`sp_add_person`** — добавление физического лица с проверкой дублей по нескольким критериям.
- **`sp_update_participant_contacts`** — обновление контактов участника по id, паспорту, СНИЛС, ИНН или ФИО.
- **`sp_delete_case_safely`** — безопасное удаление дела с созданием записей в `archived_cases` и `archived_case_participants` и записью в `system_audit_log`. Процедура упрощена для совместимости с MySQL 8/9: убрана проверка статуса дела перед удалением, что позволяет архивировать дела в любом статусе.
- **`sp_add_judicial_document`** — добавление судебного документа, генерация внутреннего номера, обновление статуса и результата дела. Процедура упрощена: убрана проверка статуса дела перед добавлением документа, что позволяет добавлять документы к делам в любом статусе. Сохранены проверки существования дела, типа документа и участника-судьи.
- **`fn_check_staff_permission`** — проверка прав сотрудника по его роли и типу операции.
- **`fn_calculate_judge_efficiency`** — вычисление интегральной эффективности судьи по завершённости и срокам рассмотрения дел.
- **События**:
  - `e_daily_duplicate_check` — ежедневный поиск возможных дублей в `persons`;
  - `e_nightly_statistics_refresh` — ночное обновление статистики судей в `statistics_cache`.

---

### 5. Представления и примерные запросы по критериям

Ниже приведены связи критериев из задания с представлениями/процедурами и **примерными SQL‑запросами**.

#### 5.1. Список дел, в которых участвует определённое лицо

- **Реализация**: представление `v_cases_by_participant`.

```sql
SELECT *
FROM v_cases_by_participant
WHERE participant_id = 123; -- или фильтр по case_id / ФИО
```

**Пример результата:**
```
participant_id | case_number | category_name    | status_name | participant_name      | role_in_case
---------------|-------------|------------------|-------------|----------------------|-------------
1              | 2-1/2023    | Гражданское дело | Завершено   | Иванов Иван Иванович | Судья
```

#### 5.2. Список дел, над которыми работает конкретный судья

- **Реализация**: представление `v_cases_by_judge`.

```sql
SELECT *
FROM v_cases_by_judge
WHERE judge_participant_id = 456;
```

**Пример результата:**
```
judge_name            | case_number | category_name    | init_date   | result_date | status_name | days_to_resolve
----------------------|-------------|------------------|-------------|-------------|-------------|----------------
Иванов Иван Иванович  | 2-1/2023    | Гражданское дело | 2023-01-10  | 2023-03-15  | Завершено   | 64
```

#### 5.3. Средняя продолжительность рассмотрения дел судьёй

- **Реализация**: `v_judge_statistics` или функция `fn_calculate_judge_efficiency`.

```sql
SELECT judge_participant_id,
       judge_name,
       avg_days_to_resolve
FROM v_judge_statistics
WHERE judge_participant_id = 456;
```

**Пример результата:**
```
judge_participant_id | judge_name           | total_cases | completed_cases | avg_days_to_resolve
---------------------|----------------------|-------------|-----------------|--------------------
1                    | Иванов Иван Иванович | 1           | 1               | 64.00
```

#### 5.4. Рейтинг судей по количеству рассмотренных дел

- **Реализация**: `v_judge_rating`.

```sql
SELECT judge_name,
       total_cases,
       completed_cases,
       completion_rate,
       rank_by_completed
FROM v_judge_rating
ORDER BY rank_by_completed;
```

**Пример результата:**
```
judge_name           | total_cases | completed_cases | completion_rate | rank_by_completed
---------------------|-------------|-----------------|-----------------|------------------
[ФИО судьи]          | [число]     | [число]         | [процент]       | [ранг]
```

**Примечание**: Представление фильтрует судей с менее чем 5 завершенными делами. При наличии достаточного количества данных возвращает рейтинг судей.

#### 5.5. Судьи, рассмотревшие N дел за последний год

- **Реализация**: запрос по `v_cases_by_judge`.

```sql
SELECT judge_participant_id,
       judge_name,
       COUNT(*) AS cases_last_year
FROM v_cases_by_judge
WHERE init_date >= CURDATE() - INTERVAL 1 YEAR
GROUP BY judge_participant_id, judge_name
HAVING COUNT(*) >= 50; -- порог N
```

**Пример результата:**
```
judge_participant_id | judge_name           | cases_last_year
---------------------|----------------------|----------------
[ID]                 | [ФИО судьи]          | [количество дел]
```

**Примечание**: При снижении порога N до 1-2 запрос возвращает результаты. Текущие данные содержат дела за 2024 год, но распределены между разными судьями.

#### 5.6. Лица, выигравшие большинство своих дел по категории

**5.6.1. Физические лица, выигравшие большинство своих дел по категории:**
- **Реализация**: запрос по `court_cases`, `case_participants`, `dict_roles`, `dict_case_categories`, `persons`.

```sql
SELECT p.person_id,
       CONCAT(p.last_name, ' ', p.first_name, ' ', COALESCE(p.patronymic, '')) AS person_name,
       dcc.category_name,
       SUM(CASE WHEN cc.result LIKE '%удовлетворено%' THEN 1 ELSE 0 END) AS won,
       COUNT(*) AS total
FROM court_cases cc
JOIN dict_case_categories dcc ON cc.category_id = dcc.category_id
JOIN case_participants cp ON cp.case_id = cc.case_id
JOIN dict_roles dr ON cp.role_id = dr.role_id
JOIN persons p ON cp.person_id = p.person_id
WHERE dr.role_code = 'ISTEC'
  AND cc.result_date IS NOT NULL
GROUP BY p.person_id, person_name, dcc.category_name
HAVING won > total / 2;
```

**Пример результата:**
```
person_id | person_name        | category_name    | won | total
----------|--------------------|------------------|-----|------
26        | Орлов Александр    | Гражданское дело | 9   | 9
28        | Захаров Никита     | Гражданское дело | 4   | 4
2         | Петров Петр        | Гражданское дело | 3   | 3
29        | Зайцева Анастасия  | Гражданское дело | 3   | 3
27        | Макарова Дарья     | Гражданское дело | 3   | 3
```

**5.6.2. Юридические лица, выигравшие большинство своих дел по категории:**
- **Реализация**: запрос по представлению `v_legal_entity_statistics` или напрямую по таблицам.

```sql
SELECT entity_name,
       inn,
       category_name,
       won_cases,
       total_cases,
       ROUND(won_cases * 100.0 / total_cases, 2) AS win_percentage
FROM v_legal_entity_statistics
WHERE won_cases > total_cases / 2
ORDER BY win_percentage DESC, total_cases DESC;
```

**Пример результата:**
```
entity_name      | inn        | category_name                    | won_cases | total_cases | win_percentage
-----------------|------------|----------------------------------|-----------|-------------|----------------
ООО "Гамма"      | 7703000003 | Гражданское дело                 | 1         | 1           | 100.00
ООО "Эпсилон"    | 7705000005 | Гражданское дело                 | 1         | 1           | 100.00
ООО "Эпсилон"    | 7705000005 | Административное правонарушение  | 1         | 1           | 100.00
ООО "Эта"        | 7802000007 | Гражданское дело                 | 1         | 1           | 100.00
ООО "Йота"       | 7706000009 | Гражданское дело                 | 1         | 1           | 100.00
```

**Пример результата:**
entity_name      | inn        | category_name                    | won_cases | total_cases | win_percentage
-----------------|------------|----------------------------------|-----------|-------------|----------------
ООО "Гамма"      | 7703000003 | Гражданское дело                 | 1         | 1           | 100.00
ООО "Эпсилон"    | 7705000005 | Гражданское дело                 | 1         | 1           | 100.00
ООО "Эпсилон"    | 7705000005 | Административное правонарушение  | 1         | 1           | 100.00
ООО "Эта"        | 7802000007 | Гражданское дело                 | 1         | 1           | 100.00
ООО "Йота"       | 7706000009 | Гражданское дело                 | 1         | 1           | 100.00
```

Альтернативный запрос напрямую по таблицам:
```sql
SELECT le.legal_entity_id,
       le.short_name AS entity_name,
       le.inn,
       dcc.category_name,
       SUM(CASE
           WHEN cp.role_id = (SELECT role_id FROM dict_roles WHERE role_code = 'ISTEC')
                AND cc.result LIKE '%удовлетворено%' THEN 1
           WHEN cp.role_id = (SELECT role_id FROM dict_roles WHERE role_code = 'OTVETCH')
                AND cc.result LIKE '%отказано%' THEN 1
           ELSE 0
       END) AS won_cases,
       COUNT(DISTINCT cc.case_id) AS total_cases
FROM legal_entities le
JOIN case_participants cp ON le.legal_entity_id = cp.legal_entity_id
JOIN court_cases cc ON cp.case_id = cc.case_id
JOIN dict_case_categories dcc ON cc.category_id = dcc.category_id
WHERE cc.result_date IS NOT NULL
GROUP BY le.legal_entity_id, le.short_name, le.inn, dcc.category_name
HAVING won_cases > COUNT(DISTINCT cc.case_id) / 2;
```

#### 5.7. Категории дел с наибольшим количеством неудачных исходов

- **Реализация**: представление `v_category_negative_decisions`.

```sql
SELECT *
FROM v_category_negative_decisions
ORDER BY negative_percentage DESC
LIMIT 10;
```

**Пример результата:**
```
category_name              | total_cases | negative_decisions | positive_decisions | negative_percentage
---------------------------|-------------|-------------------|-------------------|--------------------
Гражданское дело           | 56          | 0                 | 49                | 0.00
Уголовное дело             | 12          | 0                 | 9                 | 0.00
```

#### 5.8. Лица, выигравшие все свои дела, и судьи по этим делам

- **Реализация**: запрос по `court_cases`, `case_participants`, `v_cases_by_judge`.

```sql
WITH person_stats AS (
    SELECT cp.person_id,
           COUNT(*) AS total_cases,
           SUM(CASE WHEN cc.result LIKE '%удовлетворено%' THEN 1 ELSE 0 END) AS won_cases
    FROM court_cases cc
    JOIN case_participants cp ON cp.case_id = cc.case_id
    JOIN dict_roles dr ON cp.role_id = dr.role_id
    WHERE dr.role_code = 'ISTEC'
      AND cc.result_date IS NOT NULL
    GROUP BY cp.person_id
    HAVING won_cases = total_cases
)
SELECT ps.person_id,
       CONCAT(p.last_name, ' ', p.first_name, ' ', COALESCE(p.patronymic, '')) AS person_name,
       vj.judge_name,
       cc.case_number
FROM person_stats ps
JOIN case_participants cp ON cp.person_id = ps.person_id
JOIN court_cases cc ON cc.case_id = cp.case_id
JOIN v_cases_by_judge vj ON vj.case_id = cc.case_id
JOIN persons p ON p.person_id = ps.person_id;
```

**Пример результата:**
```
person_id | person_name        | judge_name            | case_number
----------|--------------------|----------------------|------------
4         | Козлова Мария      | Иванов Иван Иванович  | 2-1/2023
26        | Орлов Александр    | Иванов Иван Иванович  | 2-1/2023
27        | Макарова Дарья     | Иванов Иван Иванович  | 2-1/2023
10        | Павлова Ольга      | Сидоров Сидор Сидорович | 2-2/2023
28        | Захаров Никита     | Сидоров Сидор Сидорович | 2-2/2023
```

#### 5.9. Динамика дел по категориям за периоды

- **Реализация**: представление `v_case_dynamics_monthly`.

```sql
SELECT category_name,
       year,
       month,
       cases_count,
       resolved_cases,
       avg_duration_days
FROM v_case_dynamics_monthly
WHERE year BETWEEN 2021 AND 2024
ORDER BY category_name, year, month;
```

**Пример результата:**
```
category_name        | year | month | cases_count | resolved_cases | avg_duration_days
---------------------|------|-------|-------------|----------------|------------------
[Название категории] | [год]| [мес] | [число]     | [число]        | [дни]
```

**Примечание**: Представление возвращает динамику по месяцам. При наличии данных за разные месяцы возвращает статистику по каждому периоду.

#### 5.10. Судебные округа с лучшей статистикой по категориям

- **Реализация**: данные `judicial_districts`, `statistics_cache` (тип `judge_monthly` или `category_monthly`).

```sql
SELECT jdist.district_id,
       jdist.district_name,
       dcc.category_name,
       AVG(JSON_EXTRACT(sc.value_json, '$.completed_cases')) AS avg_completed_cases,
       AVG(JSON_EXTRACT(sc.value_json, '$.avg_duration_days')) AS avg_duration_days
FROM statistics_cache sc
JOIN judicial_districts jdist ON sc.district_id = jdist.district_id
LEFT JOIN dict_case_categories dcc ON sc.category_id = dcc.category_id
WHERE sc.statistic_type IN ('judge_monthly', 'category_monthly')
  AND sc.district_id IS NOT NULL
GROUP BY jdist.district_id, jdist.district_name, dcc.category_id, dcc.category_name
ORDER BY avg_completed_cases DESC, avg_duration_days ASC;
```

**Пример результата:**
```
district_id | district_name                                    | category_name | avg_completed_cases | avg_duration_days
------------|--------------------------------------------------|---------------|---------------------|-------------------
12          | Центральный судебный округ Ленинградской области | NULL          | 1.00                | 110.00
22          | Центральный судебный округ Пермского края        | NULL          | 1.00                | 154.67
16          | Центральный судебный округ Ростовской области    | NULL          | 1.00                | 185.00
15          | Центральный судебный округ Краснодарского края   | NULL          | 1.00                | 203.00
4           | Восточный судебный округ г. Москвы               | NULL          | 1.00                | 208.00
```

#### 5.11. Добавление нового участника процесса

- **Реализация**: процедура `sp_add_person`.

```sql
CALL sp_add_person(
    'Иванов', 'Иван', 'Иванович', '1980-01-01',
    '1234', '567890', '123-456-789 00', '770000000000',
    @new_person_id
);
SELECT @new_person_id AS new_person_id;
```

**Пример результата:**
```
@new_person_id
--------------
31
```

**Примечание**: Процедура проверяет наличие участника по ФИО+дата рождения, паспорту, СНИЛС или ИНН. Если участник существует, возвращает его ID, иначе создает новую запись. При использовании паспортных данных, СНИЛС или ИНН работает без проблем с collation.

#### 5.12. Обновление контактной информации участника

- **Реализация**: процедура `sp_update_participant_contacts`.

```sql
CALL sp_update_participant_contacts(
    'id',           -- или 'passport', 'snils', 'inn', 'fio'
    '123',          -- значение поиска
    '+7-900-000-00-00',
    'user@example.com',
    'г. Москва, ул. Пример, д. 1',
    @affected_rows,
    @msg
);
SELECT @affected_rows AS affected_rows, @msg AS message;
```

**Пример результата:**
```
@affected_rows | @message
---------------|------------------------------------------
1              | Контактные данные обновлены успешно
```

**Примечание**: Процедура поддерживает поиск по типу: 'id', 'fio', 'passport', 'snils', 'inn'. Обновляет телефон, email и адрес участника.

#### 5.13. Удаление дела с учётом всех связей

- **Реализация**: процедура `sp_delete_case_safely`. Процедура позволяет архивировать и удалять дела в любом статусе (проверка статуса была упрощена для совместимости с MySQL 8/9).

```sql
CALL sp_delete_case_safely(
    '2-1234/2024',              -- номер дела
    'Тестовое удаление',        -- причина
    1,                          -- staff_id инициатора
    @deleted_count,
    @backup_case_id,
    @msg
);
SELECT @deleted_count, @backup_case_id, @msg;
```

**Пример результата:**
```
@deleted_count | @backup_case_id | @message
---------------|-----------------|------------------------------------------
15             | 1               | Дело №2-123/2024 удалено, архив ID: 1
```

**Примечание**: Процедура архивирует дело в `archived_cases`, участников в `archived_case_participants`, удаляет все связанные записи (документы, заседания и т.д.) и записывает операцию в `system_audit_log`.

#### 5.14. Добавление записи о судебном решении или документе

- **Реализация**: процедура `sp_add_judicial_document`.

```sql
CALL sp_add_judicial_document(
    '2-1234/2024',       -- номер дела
    'RESHENIE',          -- код типа документа
    'Решение суда',
    '/storage/cases/2-1234-2024/reshenie.pdf',
    'application/pdf',
    456,                 -- judge_participant_id
    '2024-05-20',        -- дата решения
    'Исковые требования удовлетворены полностью',
    '2024-05-21',        -- дата поступления
    'Решение по существу спора',
    @doc_id,
    @doc_msg
);
SELECT @doc_id AS document_id, @doc_msg AS message;
```

**Пример результата:**
```
@document_id | @message
-------------|------------------------------------------
51           | Документ успешно добавлен к делу №2-123/2024
```

**Примечание**: Процедура создает документ в таблице `documents`, генерирует внутренний номер, обновляет статус и результат дела (если это решение/приговор), и записывает операцию в `system_audit_log`.
