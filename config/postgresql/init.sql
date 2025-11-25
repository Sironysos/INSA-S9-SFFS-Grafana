-- Create the test database (run as a superuser or a user that can create DBs)
\connect db;

CREATE TABLE pingouin (
  id SERIAL,
  species VARCHAR(50),
  island VARCHAR(50),
  culmen_length_mm FLOAT,
  culmen_depth_mm FLOAT,
  flipper_length_mm INTEGER,
  body_mass_g INTEGER,
  sex VARCHAR(10),
  PRIMARY KEY (id)
);

COPY pingouin(species, island, culmen_length_mm, culmen_depth_mm, flipper_length_mm, body_mass_g, sex)
FROM 'penguins_size.csv'
DELIMITER ','
CSV HEADER;
