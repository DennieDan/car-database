-- (a) Triggers
-- (1) Same car cannot be rented on 2 different rent with overlapping dates
CREATE OR REPLACE FUNCTION check_overlapping_rent()
RETURNS TRIGGER AS $$
DECLARE
	overlapping_count INT;
BEGIN
	SELECT COUNT(*)
	INTO overlapping_count
	FROM rent r
	WHERE r.plate = NEW.plate 
		AND ((NEW.start_date BETWEEN r.start_date AND r.end_date)
			OR (NEW.end_date BETWEEN r.start_date AND r.end_date)
			OR (r.start_date <= NEW.start_date AND r.end_date >= NEW.end_date));

	IF overlapping_count > 0 THEN
		RAISE EXCEPTION 'Overlapping rent of car %', NEW.plate;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER no_overlapping_rent
BEFORE INSERT OR UPDATE ON rent
FOR EACH ROW
EXECUTE FUNCTION check_overlapping_rent();

-- (2) overlapping passenger
CREATE OR REPLACE FUNCTION check_overlapping_passenger()
RETURNS TRIGGER AS $$
DECLARE
	overlapping_count INT;
BEGIN
	SELECT COUNT(*)
	INTO overlapping_count
	FROM ride r
	WHERE r.passenger = NEW.passenger 
		AND ((NEW.start_date BETWEEN r.start_date AND r.end_date)
			OR (NEW.end_date BETWEEN r.start_date AND r.end_date)
			OR (r.start_date <= NEW.start_date AND r.end_date >= NEW.end_date));

	IF overlapping_count > 0 THEN
		RAISE EXCEPTION 'Overlapping rent of passenger %', NEW.passenger;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER a_no_overlapping_passenger
BEFORE INSERT OR UPDATE ON ride
FOR EACH ROW
EXECUTE FUNCTION check_overlapping_passenger();

-- (3) number of passenger is less than or equal to the capacity
CREATE OR REPLACE FUNCTION check_passenger_capacity()
RETURNS TRIGGER AS $$
DECLARE
	_capacity INT;
	passenger_count INT;
BEGIN
	SELECT cm.capacity INTO _capacity
	FROM car c, car_make cm
	WHERE c.brand = cm.brand AND c.model = cm.model
	AND c.plate = NEW.plate;

	SELECT COUNT(*) INTO passenger_count
	FROM ride r
	WHERE r.plate = NEW.plate 
	AND r.start_date = NEW.start_date AND r.end_date = NEW.end_date;

	IF (passenger_count + 1) > _capacity THEN
		RAISE EXCEPTION 'Passenger count exceeds the car capacity';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE TRIGGER b_passenger_capacity
BEFORE INSERT ON ride
FOR EACH ROW
EXECUTE FUNCTION check_passenger_capacity();

-- DROP TRIGGER a_passenger_capacity ON ride;	

-- (4) At least one passenger has license
CREATE OR REPLACE FUNCTION check_driver()
RETURNS TRIGGER AS $$
DECLARE
	driver_count INT;
BEGIN
	SELECT COUNT(*) INTO driver_count
	FROM customer c, ride r
	WHERE c.nric = r.passenger
	AND r.plate = NEW.plate
	AND r.start_date = NEW.start_date AND r.end_date = NEW.end_date
	AND c.license = TRUE;

	IF driver_count < 1 THEN
		RAISE EXCEPTION 'There must be at least 1 passenger with driving license on the ride.';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;
CREATE CONSTRAINT TRIGGER c_driver
AFTER INSERT OR UPDATE ON ride
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_driver();

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

	INSERT INTO rider VALUES (car, start_date, end_date, passenger1);
	INSERT INTO rider VALUES (car, start_date, end_date, passenger2);
	INSERT INTO rider VALUES (car, start_date, end_date, passenger3);
	INSERT INTO rider VALUES (car, start_date, end_date, passenger4);
	EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error occurred: %', SQLERRM;
        RAISE;
END
$$ LANGUAGE plpgsql;