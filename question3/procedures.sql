-- (b) Procedures
-- (1) rent_solo
CREATE OR REPLACE PROCEDURE rent_solo
	(IN car VARCHAR(8), IN customer CHAR(9),
	IN start_date DATE, IN end_date DATE)
AS
$$
BEGIN
	INSERT INTO rent VALUES (customer, car, start_date, end_date);
	EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred: %', SQLERRM;
        RAISE;
END
$$ LANGUAGE plpgsql;
-- (2) rent_group
CREATE OR REPLACE PROCEDURE rent_group
	(IN car VARCHAR(8), IN customer CHAR(9),
	IN start_date DATE, IN end_date DATE,
	IN passenger1 CHAR(9), IN passenger2 CHAR(9),
	IN passenger3 CHAR(9), IN passenger4 CHAR(9))
AS
$$
BEGIN
	INSERT INTO rent VALUES (customer, car, start_date, end_date);

	INSERT INTO ride VALUES (car, start_date, end_date, passenger1);
	INSERT INTO ride VALUES (car, start_date, end_date, passenger2);
	INSERT INTO ride VALUES (car, start_date, end_date, passenger3);
	INSERT INTO ride VALUES (car, start_date, end_date, passenger4);
	EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred: %', SQLERRM;
        RAISE;
END
$$ LANGUAGE plpgsql;
