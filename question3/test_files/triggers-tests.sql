-- Instructions: Each test case in this file should be run separately
-- In other words: Run statement by statement, Run Transaction by Transaction
-- Data Preparation (Done after creating the schemas)
BEGIN;
-- Clean up previous test data (if any)
DELETE FROM ride;
DELETE FROM rent;
DELETE FROM customer;
DELETE FROM car;
DELETE FROM car_make;

INSERT INTO car_make (brand, model, capacity) VALUES
('Toyota', 'Corolla', 4),   -- Car with capacity 4
('Honda', 'Civic', 4),      -- Car with capacity 4
('Ford', 'Fiesta', 4);      -- Car with capacity 4

INSERT INTO car (plate, color, brand, model) VALUES
('CAR1234', 'Red', 'Toyota', 'Corolla'),
('CAR1235', 'Blue', 'Honda', 'Civic'),
('CAR1236', 'Green', 'Ford', 'Fiesta');

INSERT INTO customer (nric, name, dob, license) VALUES
('S1234567A', 'Alice', '1985-05-01', TRUE),
('S2345678B', 'Bob', '1990-06-15', FALSE),
('S3456789C', 'Charlie', '1987-08-25', TRUE),
('S4567890D', 'David', '1992-09-10', TRUE),
('S5678901E', 'Eva', '1988-12-11', TRUE),
('S6789012F', 'Frank', '1995-02-23', FALSE),
('S7890123G', 'Grace', '1994-11-30', TRUE),
('S3456789D', 'Mark', '2000-03-22', FALSE);
COMMIT;

-- Test 1: Test trigger (1)
-- Test case 1
BEGIN;
DO $$
BEGIN
  RAISE NOTICE 'TEST 1: Overlapping rental dates for same car...';

  -- First rental: Should succeed
  INSERT INTO rent (nric, plate, start_date, end_date) 
  VALUES ('S1234567A', 'CAR1234', '2025-04-01', '2025-04-05');

  -- Second rental: Should FAIL due to date overlap
  BEGIN
    INSERT INTO rent (nric, plate, start_date, end_date) 
    VALUES ('S2345678B', 'CAR1234', '2025-04-03', '2025-04-07');

    -- If no error is thrown, trigger failed
    RAISE EXCEPTION 'TEST 1 FAILED: Overlapping rental was allowed.';
  EXCEPTION
    WHEN others THEN
      RAISE NOTICE 'TEST 1 PASSED: Overlapping rental correctly blocked.';
  END;

END $$;
ROLLBACK;

-- Test 2: Test Trigger (2)
-- Test case Preparation: Rent Car 1 and Car 2
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S6789012F', 'CAR1235', '2025-04-10', '2025-04-15');
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S3456789C', 'CAR1236', '2025-04-15', '2025-04-17');

-- Test Case 2: Overlapping passenger dates for two different cars - Should FAIL
-- Try to insert a passenger ('nric') in overlapping rentals on different cars
INSERT INTO ride (plate, start_date, end_date, passenger)
VALUES ('CAR1235', '2025-04-10', '2025-04-15', 'S5678901E');
INSERT INTO ride (plate, start_date, end_date, passenger)
VALUES ('CAR1236', '2025-04-15', '2025-04-17', 'S5678901E');


-- Test 3: Test Trigger (3) - Number of passengers exceeds the capacity
-- Test Case 3.1: Should FAIL
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S4567890D', 'CAR1234', '2025-05-01', '2025-05-10');
INSERT INTO ride (plate, start_date, end_date, passenger)
VALUES ('CAR1234', '2025-05-01', '2025-05-10', 'S5678901E'),
       ('CAR1234', '2025-05-01', '2025-05-10', 'S6789012F'),
       ('CAR1234', '2025-05-01', '2025-05-10', 'S7890123G'),
       ('CAR1234', '2025-05-01', '2025-05-10', 'S1234567A'),
       ('CAR1234', '2025-05-01', '2025-05-10', 'S3456789D');

-- Test Case 3.2: Test with transaction - Should FAIL
BEGIN; -- Test with transaction
	INSERT INTO rent (nric, plate, start_date, end_date) 
	VALUES ('S4567890D', 'CAR1234', '2022-05-01', '2022-05-10');
	INSERT INTO ride (plate, start_date, end_date, passenger)
	VALUES ('CAR1234', '2022-05-01', '2022-05-10', 'S5678901E'),
	       ('CAR1234', '2022-05-01', '2022-05-10', 'S6789012F'),
	       ('CAR1234', '2022-05-01', '2022-05-10', 'S7890123G'),
	       ('CAR1234', '2022-05-01', '2022-05-10', 'S1234567A');
	INSERT INTO ride (plate, start_date, end_date, passenger)
	VALUES ('CAR1234', '2022-05-01', '2022-05-10', 'S3456789D');
COMMIT;

-- Run this after seeing the Exception raised from the previous Transaction
-- to abort the current transaction
ROLLBACK;

-- Test 4: Test Trigger (4) 
-- Test case 4.1: This should pass as there is at least 1 driver
BEGIN; -- start of transaction (should PASS)
	INSERT INTO rent (nric, plate, start_date, end_date) 
	VALUES ('S2345678B', 'CAR1234', '2025-06-01', '2025-06-05');
	INSERT INTO ride (plate, start_date, end_date, passenger)
	VALUES ('CAR1234', '2025-06-01', '2025-06-05', 'S3456789D'),  -- No driver's license for this passenger
	       ('CAR1234', '2025-06-01', '2025-06-05', 'S6789012F');  -- No driver's license for this passenger
	
	INSERT INTO ride (plate, start_date, end_date, passenger)
	VALUES ('CAR1234', '2025-06-01', '2025-06-05', 'S3456789C');
COMMIT;

-- Test case 4.2: This should pass as there is at least 1 driver
BEGIN; -- start of transaction (should FAIL)

	-- First INSERT for rent table
	INSERT INTO rent (nric, plate, start_date, end_date) 
	VALUES ('S3456789C', 'CAR1234', '2022-06-01', '2022-06-05');
	
	-- Insert into ride table with invalid passengers (No driver's license for passengers)
	INSERT INTO ride (plate, start_date, end_date, passenger)
	VALUES 
	    ('CAR1234', '2022-06-01', '2022-06-05', 'S3456789D'),  -- No driver's license for this passenger
	    ('CAR1234', '2022-06-01', '2022-06-05', 'S6789012F');  -- No driver's license for this passenger
	
	-- Insert a valid passenger
	INSERT INTO ride (plate, start_date, end_date, passenger)
	VALUES ('CAR1234', '2025-06-01', '2025-06-05', 'S2345678B');  -- Assuming this passenger is valid

COMMIT; -- commit transaction
-- Run this after seeing the Exception raised from the previous Transaction
-- to abort the current transaction
ROLLBACK;
