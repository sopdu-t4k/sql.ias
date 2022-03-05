USE ias;

/*
Вывести все показатели и поля, которые нужны для их расчета.
*/
SELECT 
	id param_id, 
	'Показатель' title, 
	name, 
	unit 
FROM 
	parameters
UNION
(SELECT 
	s.param_id, 
	'Поле' title, 
	f.name, 
	f.unit 
FROM 
	structure s
JOIN 
	fields f ON s.field_id = f.id)
ORDER BY 
	param_id, title;
    
/*
Сколько всего значений полей нужно для расчета каждого показателя?
*/
SELECT 
	s.param_id, 
	p.name, 
	COUNT(*) cnt_fields 
FROM 
	structure s
JOIN 
	parameters p 
ON 
	s.param_id = p.id
GROUP BY 
	s.param_id;
    
/*
Какие организации заполнили отчеты за все кварталы 2021 года?
*/
SELECT 
	o.name
FROM 
	forms f
JOIN 
	organizations o
ON 
	f.org_id = o.id
WHERE 
	f.`year` = 2021
GROUP BY 
	o.id
HAVING 
	COUNT(*) = 4;
    
/*
У скольки организаций не сдан или не принят отчет за 1 квартал 2021 года?
*/
SELECT 
	COUNT(*) cnt
FROM 
	organizations o
LEFT JOIN 
	(
	SELECT org_id, status_id 
	FROM forms 
	WHERE `quarter` = 1 
    AND `year` = 2021 
    AND status_id IN (3, 4)
	) f
ON 
	o.id = f.org_id
WHERE 
	f.status_id IS NULL;
    
/*
У какой организации наибольшая сумма расходов за 4 квартал 2021 года?
*/
SELECT 
	o.name, 
	v.value
FROM 
	fields_values v
JOIN 
	forms f
ON 
	f.id = v.form_id
JOIN 
	organizations o
ON 
	f.org_id = o.id
WHERE 
	v.field_id = 2
	AND f.`quarter` = 4
	AND f.`year` = 2021
ORDER BY
	CAST(v.value AS UNSIGNED) DESC
LIMIT 1;

/*
Вывести все отчеты, в которых заполнены все поля.
*/
SELECT 
	form_id
FROM 
	fields_values 
GROUP BY 
	form_id
HAVING COUNT(*) = (
	SELECT COUNT(*) 
	FROM fields 
	WHERE is_active = 1
);

/*
Вывести значения всех полей формы отчета с id = 12.
*/
SELECT 
	f.id, 
	f.name, 
	fv.value, 
	f.unit
FROM 
	fields f
LEFT JOIN 
	(
		SELECT field_id, value 
		FROM fields_values 
		WHERE form_id = 12
    ) fv
ON 
	f.id = fv.field_id
WHERE 
	f.is_active = 1;
