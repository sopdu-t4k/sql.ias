USE ias;

/*
Создать представление для отображения истории изменения статусов отчетов.
*/
CREATE OR REPLACE VIEW view_history 
AS 
	SELECT 
		sh.form_id, 
        s.name AS `status`, 
        u.login AS `user`, 
        DATE_FORMAT(sh.created_at, '%d.%m.%Y') AS `date`
	FROM 
		status_history sh
	JOIN 
		statuses s
	ON 
		sh.status_id = s.id
	JOIN 
		users u
	ON 
		sh.user_id = u.id
	ORDER BY 
		sh.created_at;

/*
Показать историю изменения статусов отчета организации с id = 19 за 1 квартал 2021 года.
*/
SELECT 
	`status`, `user`, `date` 
FROM 
	view_history 
WHERE 
	form_id = (
		SELECT id 
		FROM forms 
		WHERE org_id = 19 
		AND `quarter` = 1
		AND `year` = 2021 
    );

/*
Создать представление, отображающее к какой группе и подгруппе принадлежит каждая организация.
*/    
CREATE OR REPLACE VIEW view_org_groups 
AS
	SELECT 
		o.id AS org_id, 
		g.id AS group_id, 
        g.name AS group_name,
		pg.id AS parent_group_id,
        pg.name AS parent_group_name
	FROM 
		organizations o
	JOIN 
		org_group g
	ON 
		o.org_group_id = g.id
	JOIN 
		org_group pg
	ON 
		g.parent_org_group = pg.id;
        
/*
Показать количество всех отчетов в системе за 3 квартал 2021 года по группам организаций.
*/
SELECT 
	g.parent_group_name, 
	COUNT(*) AS cnt
FROM 
	forms f
JOIN 
	view_org_groups g
ON 
	f.org_id = g.org_id
WHERE 
	f.`quarter` = 3 AND f.`year` = 2021
GROUP BY 
	g.parent_group_id;
    
/*
Вывести рейтинг подгрупп организаций по количеству сданных отчетов за 2021 год среди стационарных больниц.
*/
SELECT 
	g.group_name, 
    COUNT(*) AS cnt
FROM 
	forms f
JOIN 
	view_org_groups g
ON 
	f.org_id = g.org_id
WHERE 
	g.parent_group_id = 1
	AND f.`year` = 2021
	AND f.status_id = 4
GROUP BY 
	g.group_id
ORDER BY 
	cnt DESC;
