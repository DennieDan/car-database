BEGIN;

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
('S7890123G', 'Grace', '1994-11-30', TRUE);

-- Test Case 1: Overlapping dates for car rental
-- Try to rent the same car ('plate') with overlapping dates
-- Rent Car 1 (Assuming the car exists in the database)
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S1234567A', 'CAR1234', '2025-04-01', '2025-04-05');

-- This should fail as the car 'CAR1234' is already rented between '2025-04-01' and '2025-04-05'
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S2345678B', 'CAR1234', '2025-04-03', '2025-04-07');

-- Test Case 2: Overlapping passenger dates for two different cars
-- Try to insert a passenger ('nric') in overlapping rentals on different cars
-- Rent Car 1 and Car 2
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S3456789C', 'CAR1235', '2025-04-10', '2025-04-15');
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S3456789C', 'CAR1236', '2025-04-12', '2025-04-17');

-- This should fail as 'S3456789C' is overlapping with rentals for two cars

-- Test Case 3: Number of passengers exceeds the capacity
-- Assuming 'CAR1234' has a capacity of 4
-- Insert passengers for this rental (Exceeds capacity)
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S4567890D', 'CAR1234', '2025-05-01', '2025-05-10');
INSERT INTO ride (plate, start_date, end_date, passenger)
VALUES ('CAR1234', '2025-05-01', '2025-05-10', 'S5678901E'),
       ('CAR1234', '2025-05-01', '2025-05-10', 'S6789012F'),
       ('CAR1234', '2025-05-01', '2025-05-10', 'S7890123G'),
       ('CAR1234', '2025-05-01', '2025-05-10', 'S8901234H'),
       ('CAR1234', '2025-05-01', '2025-05-10', 'S9012345I'); -- Should fail, too many passengers

-- Test Case 4: No drivers (Passenger without a driver’s license)
-- Assuming that passengers must have a driver’s license (license = TRUE)
-- Insert a rental without any passenger having a driver's license
INSERT INTO rent (nric, plate, start_date, end_date) 
VALUES ('S2345678B', 'CAR1234', '2025-06-01', '2025-06-05');

-- This should fail if there are no passengers with a driver's license
INSERT INTO ride (plate, start_date, end_date, passenger)
VALUES ('CAR1234', '2025-06-01', '2025-06-05', 'S2345678B'),  -- No driver's license for this passenger
       ('CAR1234', '2025-06-01', '2025-06-05', 'S6789012F');  -- No driver's license for this passenger

ROLLBACK;
