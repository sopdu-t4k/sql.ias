USE ias;

/*
Сделать не активной организацию с id = 15, а значит и всех ее пользователей.
*/
START TRANSACTION;
	UPDATE organizations
	SET is_active = 0
	WHERE id = 15;
	
	UPDATE users
	SET is_active = 0
	WHERE org_id = 15;
COMMIT;

/*
Внести новое значение поля формы отчета. 
Если значение уже есть в таблице, то его надо обновить, а если еще нет, то его надо добавить.
*/
DROP PROCEDURE IF EXISTS sp_save_value;
DELIMITER //
CREATE PROCEDURE sp_save_value(frm BIGINT, fld BIGINT, val VARCHAR(255))
BEGIN
	IF EXISTS(
		SELECT form_id 
        FROM fields_values 
        WHERE form_id = frm AND field_id = fld
    ) THEN
		UPDATE fields_values 
        SET value = val 
        WHERE form_id = frm AND field_id = fld;
    ELSE
		INSERT INTO fields_values 
        SET form_id = frm, field_id = fld, value = val;
    END IF;
END //
DELIMITER ;

CALL sp_save_value(33, 15, '3571');

/*
Изменить статус отчета организации с id = 6 за 2 квартал 2021 года на "принято".
*/
DROP PROCEDURE IF EXISTS sp_set_status;
DELIMITER //
CREATE PROCEDURE sp_set_status(id_org INT, qrt INT, yr YEAR, id_status INT, id_user INT, OUT tran_result varchar(200))
BEGIN
	DECLARE `_rollback` BIT DEFAULT 0;
	DECLARE code varchar(100);
	DECLARE error_string varchar(100); 
    DECLARE id_form INT;

	DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
	BEGIN
 		SET `_rollback` = 1;
 		GET stacked DIAGNOSTICS CONDITION 1
			code = RETURNED_SQLSTATE, error_string = MESSAGE_TEXT;
		SET tran_result = concat('Error occured. Code: ', code, '. Text: ', error_string);
	END;
    
	START TRANSACTION;
		SET id_form = (  -- находим id нужного отчета
			SELECT id 
			FROM forms 
			WHERE org_id = id_org 
			AND `quarter` = qrt 
			AND `year` = yr
        );
        
		UPDATE forms   -- меняем текущий статус отчета
        SET status_id = id_status 
        WHERE id = id_form;
        
		INSERT INTO status_history   -- делаем запись в таблице истории изменения статусов отчетов
		SET 
			form_id = id_form, 
			status_id = id_status, 
			user_id = id_user;
		
		IF `_rollback` THEN
			ROLLBACK;
		ELSE
			SET tran_result = 'Success';
			COMMIT;
		END IF;
END //
DELIMITER ;

CALL sp_set_status(6, 2, 2021, 4, 1, @tran_result);
SELECT @tran_result;

/*
Добавить проверку при изменении статуса отчета, чтобы новый статус был отличным от текущего.
*/
DROP TRIGGER IF EXISTS check_current_status;

DELIMITER //
CREATE TRIGGER check_current_status BEFORE UPDATE 
ON forms
FOR EACH ROW
BEGIN
	IF NEW.status_id = OLD.status_id THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Status has not changed!';
    END IF;
END //
DELIMITER ;

-- теперь не произойдет повторной записи в историю изменения статусов отчетов
CALL sp_set_status(6, 2, 2021, 4, 1, @tran_result);
SELECT @tran_result;

/*
При внесении нового отчета проверять корректность указания квартала.
*/
DROP TRIGGER IF EXISTS check_quarter_format;

DELIMITER //
CREATE TRIGGER check_quarter_format BEFORE INSERT
ON forms
FOR EACH ROW
BEGIN
	IF NEW.`quarter` NOT BETWEEN 1 AND 4 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid quarter format!';
    END IF;
END //
DELIMITER ;

INSERT INTO 
	forms (org_id, status_id, `quarter`, `year`)
VALUES 
	(9, 3, 5, 2021);
