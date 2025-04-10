-- (a) Triggers
-- (1) Same car cannot be rented on 2 different rent with overlapping dates
DROP TRIGGER IF EXISTS no_overlapping_rent ON rent;
DROP FUNCTION IF EXISTS check_overlapping_rent();

CREATE OR REPLACE FUNCTION check_overlapping_rent()
RETURNS TRIGGER AS $$
DECLARE
	overlapping_count INT;
BEGIN
	SELECT COUNT(*) INTO overlapping_count
	FROM rent r
	WHERE r.plate = NEW.plate
	  AND r.ctid <> NEW.ctid  -- avoid comparing with itself
	  AND (
	    NEW.start_date BETWEEN r.start_date AND r.end_date OR
	    NEW.end_date BETWEEN r.start_date AND r.end_date OR
	    r.start_date <= NEW.start_date AND r.end_date >= NEW.end_date
	  );

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
DROP TRIGGER IF EXISTS a_no_overlapping_passenger ON ride;
DROP FUNCTION IF EXISTS check_overlapping_passenger();

CREATE OR REPLACE FUNCTION check_overlapping_passenger()
RETURNS TRIGGER AS $$
DECLARE
	overlapping_count INT;
BEGIN
	SELECT COUNT(*)
	INTO overlapping_count
	FROM ride r
	WHERE r.passenger = NEW.passenger 
		AND r.ctid <> NEW.ctid  -- avoid comparing with itself
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
DROP TRIGGER IF EXISTS b_passenger_capacity ON ride;
DROP FUNCTION IF EXISTS check_passenger_capacity();

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
BEFORE INSERT OR UPDATE ON ride
FOR EACH ROW
EXECUTE FUNCTION check_passenger_capacity();	

-- (4) At least one passenger has license
DROP TRIGGER IF EXISTS c_driver ON ride;
DROP FUNCTION IF EXISTS check_driver();

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
FOR EACH ROW 
EXECUTE FUNCTION check_driver();
