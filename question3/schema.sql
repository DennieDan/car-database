CREATE TABLE IF NOT EXISTS car_make (
  brand     VARCHAR(64),
  model     VARCHAR(64),
  capacity  INT NOT NULL CHECK (capacity > 0),
  PRIMARY KEY (brand, model)
);

CREATE TABLE IF NOT EXISTS car (
  plate       VARCHAR(8) PRIMARY KEY,
  color       VARCHAR(64) NOT NULL,
  brand       VARCHAR(64) NOT NULL,
  model       VARCHAR(64) NOT NULL,
  FOREIGN KEY (brand, model)
    REFERENCES car_make (brand, model)
    ON UPDATE CASCADE
    DEFERRABLE INITIALLY IMMEDIATE
);

CREATE TABLE IF NOT EXISTS customer (
  nric    CHAR(9) PRIMARY KEY,
  name    VARCHAR(256) NOT NULL,
  dob     DATE NOT NULL,
  license BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS prefer (
  nric    CHAR(9)
    REFERENCES customer (nric)
      ON UPDATE CASCADE
      DEFERRABLE INITIALLY IMMEDIATE,
  brand   VARCHAR(64),
  model   VARCHAR(64),
  FOREIGN KEY (brand, model)
    REFERENCES car_make (brand, model)
    ON UPDATE CASCADE
    DEFERRABLE INITIALLY IMMEDIATE,
  PRIMARY KEY (nric, brand, model)
);

CREATE TABLE IF NOT EXISTS rent (
  nric        CHAR(9) NOT NULL
    REFERENCES customer (nric)
      ON UPDATE CASCADE
      DEFERRABLE INITIALLY IMMEDIATE,
  plate       VARCHAR(8)
    REFERENCES car (plate)
      ON UPDATE CASCADE
      DEFERRABLE INITIALLY IMMEDIATE,
  start_date  DATE,
  end_date    DATE CHECK (end_date >= start_date),
  PRIMARY KEY (plate, start_date, end_date)
);

CREATE TABLE IF NOT EXISTS ride (
  plate       VARCHAR(8),
  start_date  DATE,
  end_date    DATE,
  passenger   CHAR(9) REFERENCES customer (nric)
    ON UPDATE CASCADE
    DEFERRABLE INITIALLY IMMEDIATE,
  FOREIGN KEY (plate, start_date, end_date)
    REFERENCES rent (plate, start_date, end_date)
    ON UPDATE CASCADE
    DEFERRABLE INITIALLY IMMEDIATE,
  PRIMARY KEY (plate, start_date, end_date, passenger)
);