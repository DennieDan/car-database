CREATE TABLE IF NOT EXISTS car_makes (
	brand VARCHAR(255),
	model VARCHAR(255),
	capacity int NOT NULL,
	PRIMARY KEY (brand, model),
	CHECK (capacity > 0)
);

CREATE TABLE IF NOT EXISTS cars (
	license_plate CHAR(8),
	brand VARCHAR(255) NOT NULL,
	model VARCHAR(255) NOT NULL,
	colour VARCHAR(40) NOT NULL,
	PRIMARY KEY (license_plate),
	FOREIGN KEY (brand, model) REFERENCES car_makes(brand, model) ON UPDATE CASCADE DEFERRABLE,
	CHECK(license_plate ~ '^S[A-HJ-NP-Z]{2}[1-9][0-9]{3}[A-EG-HJ-MPR-UXY-Z]$')
	-- License plate format is enforced using a CHECK constraint with a regex.
);

CREATE TABLE IF NOT EXISTS customers (
    nric CHAR(9),
    has_driving_license BOOLEAN NOT NULL,
    name VARCHAR(255) NOT NULL,
    date_of_birth DATE NOT NULL,
    brand VARCHAR(255) NOT NULL,
    model VARCHAR(255) NOT NULL,
	CHECK (nric ~ '^[STFGM]\d{7}[A-Z]$'),
	-- NRIC format is enforced using a CHECK constraint with a regex.
	PRIMARY KEY (nric),
	FOREIGN KEY (brand, model) REFERENCES car_makes(brand, model) ON UPDATE CASCADE DEFERRABLE
);

CREATE TABLE IF NOT EXISTS rentals (
    nric CHAR(9) NOT NULL,
    license_plate char(8) NOT NULL,
	start_date DATE NOT NULL,
	end_date DATE NOT NULL,
	rental_id SERIAL PRIMARY KEY,
	FOREIGN KEY (nric) REFERENCES customers(nric) ON UPDATE CASCADE DEFERRABLE,
	FOREIGN KEY (license_plate) REFERENCES cars(license_plate) ON UPDATE CASCADE DEFERRABLE,
	CHECK (start_date <= end_date),
	UNIQUE (license_plate, start_date),
	UNIQUE (license_plate, end_date)
	-- 1. Constraint: A car with the same license plate must be rented by one customer at a time 
	-- (overlapping rental periods are not allowed)
	-- + The UNIQUE constraints help prevent exact duplicate rental periods, but do not 
	-- + fully prevent overlapping rentals.
	-- + A more complete solution would require an EXCLUDE constraint or trigger, as every time 
	-- + before inserting a new rental, we need a trigger to query the current table for any 
	-- + overlapping cases, if there are overlapping, we raise an exception that stops the insertion.
);

CREATE TABLE IF NOT EXISTS passengers (
    nric CHAR(9),
    rental_id INTEGER,
    PRIMARY KEY (nric, rental_id),
    FOREIGN KEY (rental_id) REFERENCES rentals (rental_id) ON DELETE CASCADE DEFERRABLE,
	FOREIGN KEY (nric) REFERENCES customers (nric) ON UPDATE CASCADE DEFERRABLE
	-- 2. Total passengers < car_makes(capacity)
	-- This cannot be enforced using simple SQL constraints, as it requires counting passengers per rental 
	-- and comparing that count to the car's capacity.
	-- It needs trigger to implement this check which not be implemented here.

	-- 3. At least one passenger has a license
	-- This cannot be enforced using a simple SQL constraint because constraints are applied per row,
	-- while this condition (ensuring at least one passenger has a license) involves checking multiple rows.
	-- A trigger is required to enforce it which not be implemented here.

	-- 4. If the passenger is not renting any car, then the passenger should not appear in the passenger table
	-- This is enforced by FOREIGN KEY constraint on rental_id.
);