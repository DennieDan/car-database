BEGIN;

-- Clean up previous test data (if any)
DELETE FROM ride;
DELETE FROM rent;
DELETE FROM customer;
DELETE FROM car;
DELETE FROM car_make;

-- Insert test data
INSERT INTO car_make (brand, model, capacity) VALUES
('Toyota', 'Camry', 4);

INSERT INTO car (plate, color, brand, model) VALUES
('ABC123', 'Red', 'Toyota', 'Camry');  -- Capacity = 4

INSERT INTO customer (nric, name, dob, license) VALUES
('S1234567A', 'Alice', '1990-01-01', TRUE),   -- Has license
('S7654321B', 'Bob', '1995-05-05', FALSE),    -- No license
('S1111111C', 'Charlie', '2000-10-10', TRUE), -- Has license
('S0987654C', 'Alex', '2000-06-10', TRUE),    -- Has license
('S7654321D', 'Deo', '1995-02-05', FALSE),    -- No license
('S2345678C', 'John', '1998-08-12', FALSE),   -- No license
('S3456789D', 'Mark', '2000-03-22', FALSE);    -- No license

COMMIT;

-- TEST 1: rent_solo (Valid Case)
BEGIN;
DO $$
BEGIN
  RAISE NOTICE 'TEST 1: rent_solo (valid)...';
  CALL rent_solo('ABC123', 'S1234567A', '2023-01-01', '2023-01-05');
  
  -- Verify the rental and passenger (customer is the only passenger)
  PERFORM 1 FROM rent 
  WHERE plate = 'ABC123' AND nric = 'S1234567A' 
    AND start_date = '2023-01-01' AND end_date = '2023-01-05';
  
  IF FOUND THEN
    RAISE NOTICE 'TEST 1 PASSED: rent_solo succeeded.';
  ELSE
    RAISE EXCEPTION 'TEST 1 FAILED: rent_solo did not insert data.';
  END IF;
END $$;
ROLLBACK;

-- TEST 2: rent_solo (Overlapping Rental - Should Fail)
BEGIN;
DO $$
BEGIN
  -- First rental (valid)
  CALL rent_solo('ABC123', 'S1234567A', '2023-01-01', '2023-01-05');
  
  -- Attempt overlapping rental
  RAISE NOTICE 'TEST 2: rent_solo (overlapping dates - expected to fail)...';
  CALL rent_solo('ABC123', 'S7654321B', '2023-01-03', '2023-01-07');
  RAISE NOTICE 'TEST 2 FAILED: Overlapping rental was incorrectly allowed.';
EXCEPTION
  WHEN others THEN
    RAISE NOTICE 'TEST 2 PASSED: Overlapping rental blocked.';
END $$;
ROLLBACK;

-- TEST 3: rent_group (Valid Case)
BEGIN;
DO $$
BEGIN
  RAISE NOTICE 'TEST 3: rent_group (valid)...';
  -- Rent Toyota Camry (capacity = 4) with 4 passengers (1 driver)
  CALL rent_group(
    'ABC123',                   -- Car plate
    'S1234567A',                -- Customer (driver)
    '2023-02-01', '2023-02-05', -- Dates
    'S1234567A',                -- Passenger 1 (driver)
    'S7654321B',                -- Passenger 2 (no license)
    'S1111111C',                -- Passenger 3 (has license)
    'S0987654C'                 -- Passenger 4 (has license)
  );
  
  -- Verify rental and passengers
  PERFORM 1 FROM rent 
  WHERE plate = 'ABC123' AND nric = 'S1234567A';
  
  IF FOUND THEN
    RAISE NOTICE 'TEST 3 PASSED: rent_group succeeded.';
  ELSE
    RAISE EXCEPTION 'TEST 3 FAILED: rent_group did not insert data.';
  END IF;
END $$;
ROLLBACK;

-- TEST 4: rent_group (Invalid Case - call multiple times, one call is invalid - Rollback)
BEGIN;
DO $$
BEGIN
  RAISE NOTICE 'TEST 4: rent_group (one valid, one invalid)...';

  -- First rental: VALID (should succeed)
  CALL rent_group(
    'ABC123',                   -- Car plate
    'S1234567A',                -- Customer (driver)
    '2023-02-01', '2023-02-05',
    'S1234567A',                -- Passenger 1 (driver)
    'S7654321B',                -- Passenger 2 (no license)
    'S1111111C',                -- Passenger 3 (has license)
    'S0987654C'                 -- Passenger 4 (has license)
  );

  -- Second rental: INVALID (should fail due to all passengers without license)
  BEGIN
    CALL rent_group(
      'ABC123',
      'S1234567A',
      '2023-02-01', '2023-02-05',
      'S7654321B',
      'S7654321D',
      'S2345678C',
      'S3456789D'
    );
    
    -- If we get here, it means the call did NOT fail (unexpected)
    RAISE EXCEPTION 'TEST 4 FAILED: Invalid rent_group call was allowed.';
    
  EXCEPTION
    WHEN others THEN
      RAISE NOTICE 'TEST 4: Invalid rent_group call correctly raised an exception.';
  END;

  -- Check if the valid rental was inserted
  PERFORM 1 FROM rent 
  WHERE plate = 'ABC123' AND nric = 'S1234567A';

  IF FOUND THEN
    RAISE NOTICE 'TEST 4 PASSED: Valid rent_group inserted, invalid one rejected.';
  ELSE
    RAISE EXCEPTION 'TEST 4 FAILED: Valid rent_group not inserted.';
  END IF;

END $$;
ROLLBACK;