-- =====================================================
-- SQL ЗАПРОСЫ ДЛЯ ВЫПОЛНЕНИЯ ТРЕБУЕМЫХ ОПЕРАЦИЙ
-- =====================================================

USE court_system;

-- =====================================================
-- 5.1. Вывод списка дел, в которых участвует определённое физическое или юридическое лицо
-- =====================================================

-- Для физического лица (по ID)
SELECT 
    cc.case_id,
    cc.case_number,
    cc.case_description,
    cc.filing_date,
    cc.status,
    pr.role_name AS participant_role,
    CONCAT(i.last_name, ' ', i.first_name, ' ', COALESCE(i.middle_name, '')) AS participant_name
FROM court_cases cc
INNER JOIN case_participants_individuals cpi ON cc.case_id = cpi.case_id
INNER JOIN individuals i ON cpi.individual_id = i.individual_id
INNER JOIN participant_roles pr ON cpi.role_id = pr.role_id
WHERE i.individual_id = 1  -- Заменить на нужный ID
ORDER BY cc.filing_date DESC;

-- Для физического лица (по ФИО)
SELECT 
    cc.case_id,
    cc.case_number,
    cc.case_description,
    cc.filing_date,
    cc.status,
    pr.role_name AS participant_role,
    CONCAT(i.last_name, ' ', i.first_name, ' ', COALESCE(i.middle_name, '')) AS participant_name
FROM court_cases cc
INNER JOIN case_participants_individuals cpi ON cc.case_id = cpi.case_id
INNER JOIN individuals i ON cpi.individual_id = i.individual_id
INNER JOIN participant_roles pr ON cpi.role_id = pr.role_id
WHERE i.last_name = 'Смирнов' 
  AND i.first_name = 'Иван'
  AND (i.middle_name = 'Петрович' OR i.middle_name IS NULL)
ORDER BY cc.filing_date DESC;

-- Для юридического лица (по ID)
SELECT 
    cc.case_id,
    cc.case_number,
    cc.case_description,
    cc.filing_date,
    cc.status,
    pr.role_name AS participant_role,
    le.company_name AS participant_name
FROM court_cases cc
INNER JOIN case_participants_legal_entities cple ON cc.case_id = cple.case_id
INNER JOIN legal_entities le ON cple.legal_entity_id = le.legal_entity_id
INNER JOIN participant_roles pr ON cple.role_id = pr.role_id
WHERE le.legal_entity_id = 1  -- Заменить на нужный ID
ORDER BY cc.filing_date DESC;

-- Для юридического лица (по названию)
SELECT 
    cc.case_id,
    cc.case_number,
    cc.case_description,
    cc.filing_date,
    cc.status,
    pr.role_name AS participant_role,
    le.company_name AS participant_name
FROM court_cases cc
INNER JOIN case_participants_legal_entities cple ON cc.case_id = cple.case_id
INNER JOIN legal_entities le ON cple.legal_entity_id = le.legal_entity_id
INNER JOIN participant_roles pr ON cple.role_id = pr.role_id
WHERE le.company_name LIKE '%Альфа%'
ORDER BY cc.filing_date DESC;

-- =====================================================
-- 5.2. Вывод списка дел, над которыми работает конкретный судья
-- =====================================================

SELECT 
    cc.case_id,
    cc.case_number,
    cc.case_description,
    cc.filing_date,
    cc.start_date,
    cc.end_date,
    cc.status,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name
FROM court_cases cc
INNER JOIN judges j ON cc.judge_id = j.judge_id
WHERE j.judge_id = 1  -- Заменить на нужный ID
ORDER BY cc.filing_date DESC;

-- По ФИО судьи
SELECT 
    cc.case_id,
    cc.case_number,
    cc.case_description,
    cc.filing_date,
    cc.start_date,
    cc.end_date,
    cc.status,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name
FROM court_cases cc
INNER JOIN judges j ON cc.judge_id = j.judge_id
WHERE j.last_name = 'Иванов' 
  AND j.first_name = 'Петр'
ORDER BY cc.filing_date DESC;

-- =====================================================
-- 5.3. Вычисление среднего времени рассмотрения дел для каждого судьи
-- =====================================================

SELECT 
    j.judge_id,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name,
    COUNT(cc.case_id) AS total_cases,
    COUNT(CASE WHEN cc.end_date IS NOT NULL THEN 1 END) AS completed_cases,
    ROUND(AVG(DATEDIFF(cc.end_date, cc.start_date)), 2) AS avg_days_to_complete
FROM judges j
LEFT JOIN court_cases cc ON j.judge_id = cc.judge_id
WHERE cc.end_date IS NOT NULL AND cc.start_date IS NOT NULL
GROUP BY j.judge_id, j.last_name, j.first_name, j.middle_name
ORDER BY avg_days_to_complete;

-- Альтернативный вариант (учитывает только завершенные дела)
SELECT 
    j.judge_id,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name,
    COUNT(cc.case_id) AS completed_cases,
    ROUND(AVG(DATEDIFF(cc.end_date, COALESCE(cc.start_date, cc.filing_date))), 2) AS avg_days_to_complete
FROM judges j
INNER JOIN court_cases cc ON j.judge_id = cc.judge_id
WHERE cc.status = 'completed' 
  AND cc.end_date IS NOT NULL
GROUP BY j.judge_id, j.last_name, j.first_name, j.middle_name
ORDER BY avg_days_to_complete;

-- =====================================================
-- 5.4. Рейтинг судей по количеству успешно завершённых дел
-- =====================================================

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

-- =====================================================
-- 5.5. Список судей, рассмотревших более определённого количества дел за последний год
-- =====================================================

SELECT 
    j.judge_id,
    CONCAT(j.last_name, ' ', j.first_name, ' ', COALESCE(j.middle_name, '')) AS judge_name,
    COUNT(cc.case_id) AS cases_count
FROM judges j
INNER JOIN court_cases cc ON j.judge_id = cc.judge_id
WHERE cc.filing_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
  AND cc.status = 'completed'
GROUP BY j.judge_id, j.last_name, j.first_name, j.middle_name
HAVING COUNT(cc.case_id) > 3  -- Заменить на нужное количество
ORDER BY cases_count DESC;

-- =====================================================
-- 5.6. Список юридических лиц, выигравших большинство своих дел по определённой категории
-- =====================================================

SELECT 
    le.legal_entity_id,
    le.company_name,
    cc.category_id,
    cat.category_name,
    COUNT(cc.case_id) AS total_cases,
    COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') 
               AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
          THEN 1 END) AS won_cases,
    COUNT(CASE WHEN cd.decision_type IN ('rejected', 'dismissed') 
               AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
          THEN 1 END) AS lost_cases,
    ROUND(COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') 
                     AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
                THEN 1 END) * 100.0 / COUNT(cc.case_id), 2) AS win_rate_percent
FROM legal_entities le
INNER JOIN case_participants_legal_entities cple ON le.legal_entity_id = cple.legal_entity_id
INNER JOIN court_cases cc ON cple.case_id = cc.case_id
INNER JOIN case_categories cat ON cc.category_id = cat.category_id
LEFT JOIN case_decisions cd ON cc.case_id = cd.case_id
WHERE cat.category_id = 1  -- Заменить на нужную категорию (1 = Гражданские дела)
  AND cc.status = 'completed'
  AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец')
GROUP BY le.legal_entity_id, le.company_name, cc.category_id, cat.category_name
HAVING COUNT(CASE WHEN cd.decision_type IN ('satisfied', 'partially_satisfied') 
                  AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
             THEN 1 END) > COUNT(CASE WHEN cd.decision_type IN ('rejected', 'dismissed') 
                                       AND cple.role_id = (SELECT role_id FROM participant_roles WHERE role_name = 'истец') 
                                  THEN 1 END)
ORDER BY win_rate_percent DESC;

-- =====================================================
-- 5.7. Определение категорий дел, по которым чаще всего принимаются отрицательные решения
-- =====================================================

SELECT 
    cat.category_id,
    cat.category_name,
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

-- =====================================================
-- 5.8. Список физических лиц, выигравших все свои дела, и судей, рассмотревших эти дела
-- =====================================================

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

-- =====================================================
-- 5.9. Отслеживание динамики количества дел по категориям за разные периоды
-- =====================================================

-- По месяцам
SELECT 
    cat.category_name,
    DATE_FORMAT(cc.filing_date, '%Y-%m') AS period,
    COUNT(cc.case_id) AS cases_count
FROM case_categories cat
INNER JOIN court_cases cc ON cat.category_id = cc.category_id
WHERE cc.filing_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY cat.category_id, cat.category_name, DATE_FORMAT(cc.filing_date, '%Y-%m')
ORDER BY period DESC, cases_count DESC;

-- По кварталам
SELECT 
    cat.category_name,
    CONCAT(YEAR(cc.filing_date), '-Q', QUARTER(cc.filing_date)) AS period,
    COUNT(cc.case_id) AS cases_count
FROM case_categories cat
INNER JOIN court_cases cc ON cat.category_id = cc.category_id
WHERE cc.filing_date >= DATE_SUB(CURDATE(), INTERVAL 2 YEAR)
GROUP BY cat.category_id, cat.category_name, YEAR(cc.filing_date), QUARTER(cc.filing_date)
ORDER BY period DESC, cases_count DESC;

-- По годам
SELECT 
    cat.category_name,
    YEAR(cc.filing_date) AS period,
    COUNT(cc.case_id) AS cases_count
FROM case_categories cat
INNER JOIN court_cases cc ON cat.category_id = cc.category_id
GROUP BY cat.category_id, cat.category_name, YEAR(cc.filing_date)
ORDER BY period DESC, cases_count DESC;

-- =====================================================
-- 5.10. Определение судебных округов с наиболее эффективными показателями рассмотрения дел
-- =====================================================

SELECT 
    jd.district_id,
    jd.district_name,
    jd.region,
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

-- Сравнение эффективности по категориям дел
SELECT 
    jd.district_id,
    jd.district_name,
    cat.category_name,
    COUNT(cc.case_id) AS cases_count,
    ROUND(AVG(CASE WHEN cc.end_date IS NOT NULL AND cc.start_date IS NOT NULL 
               THEN DATEDIFF(cc.end_date, cc.start_date) END), 2) AS avg_days_to_complete,
    ROUND(COUNT(CASE WHEN cc.status = 'completed' THEN 1 END) * 100.0 / COUNT(cc.case_id), 2) AS completion_rate
FROM judicial_districts jd
INNER JOIN court_cases cc ON jd.district_id = cc.district_id
INNER JOIN case_categories cat ON cc.category_id = cat.category_id
WHERE cc.filing_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
GROUP BY jd.district_id, jd.district_name, cat.category_id, cat.category_name
HAVING COUNT(cc.case_id) >= 2
ORDER BY cat.category_name, avg_days_to_complete ASC;

