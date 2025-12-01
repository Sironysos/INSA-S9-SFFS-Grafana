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

CREATE TABLE position (
    id SERIAL,
    latitude FLOAT,
    longitude FLOAT,
    PRIMARY KEY (id),
    FOREIGN KEY (id) REFERENCES pingouin(id)
);

CREATE TABLE couples (
    id SERIAL,
    parent1_id INT REFERENCES pingouin(id),
    parent2_id INT REFERENCES pingouin(id),
    PRIMARY KEY (id)
);


COPY pingouin(species, island, culmen_length_mm, culmen_depth_mm, flipper_length_mm, body_mass_g, sex) 
FROM '/docker-entrypoint-initdb.d/penguins_size.csv' with (format csv, null 'NA', DELIMITER ',', HEADER);



CREATE OR REPLACE FUNCTION rand_range(min FLOAT, max FLOAT)
RETURNS FLOAT AS $$
BEGIN
  RETURN min + (max - min) * random();
END;
$$ LANGUAGE plpgsql IMMUTABLE;




CREATE OR REPLACE FUNCTION insert_random_penguin()
RETURNS VOID AS $$
DECLARE
    sp TEXT;
    isl TEXT;
    cul_len FLOAT;
    cul_dep FLOAT;
    flip_len INT;
    body INT;
    sx TEXT;
BEGIN
    -- Tirage de l'espèce selon proportions approximatives
    SELECT species INTO sp FROM (
        VALUES ('Adelie'), ('Adelie'), ('Adelie'),        -- ~44%
               ('Chinstrap'), ('Chinstrap'),              -- ~18%
               ('Gentoo'), ('Gentoo'), ('Gentoo'), ('Gentoo')  -- ~38%
    ) AS t(species)
    ORDER BY random() LIMIT 1;

    -- Détermination des îles selon l'espèce
    IF sp = 'Adelie' THEN
        SELECT island INTO isl FROM (VALUES ('Torgersen'), ('Biscoe'), ('Dream')) AS t(island)
        ORDER BY random() LIMIT 1;
    ELSIF sp = 'Chinstrap' THEN
        isl := 'Dream';
    ELSE
        isl := 'Biscoe';
    END IF;

    -- Valeurs réalistes selon l'espèce
    IF sp = 'Adelie' THEN
        cul_len := rand_range(33, 46);
        cul_dep := rand_range(15, 22);
        flip_len := floor(rand_range(172, 210));
        body := floor(rand_range(2850, 4775));
    ELSIF sp = 'Chinstrap' THEN
        cul_len := rand_range(42, 59);
        cul_dep := rand_range(16, 21);
        flip_len := floor(rand_range(178, 212));
        body := floor(rand_range(2700, 4800));
    ELSE -- Gentoo
        cul_len := rand_range(40, 60);
        cul_dep := rand_range(13, 18);
        flip_len := floor(rand_range(203, 231));
        body := floor(rand_range(3950, 6300));
    END IF;

    -- Sexe (10% de valeurs NULL comme dans le dataset)
    SELECT sx INTO sx FROM (
        VALUES ('MALE'), ('FEMALE'), ('MALE'), ('FEMALE'), (NULL)
    ) AS t(sex)
    ORDER BY random() LIMIT 1;

    -- Insertion
    INSERT INTO pingouin(species, island, culmen_length_mm, culmen_depth_mm,
                         flipper_length_mm, body_mass_g, sex)
    VALUES (sp, isl, cul_len, cul_dep, flip_len, body, sx);
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  FOR i IN 1..1000000 LOOP
    PERFORM insert_random_penguin();
  END LOOP;
END;
$$;





INSERT INTO position(id, latitude, longitude)
SELECT 
    id,
    48.117 + ((random() * 2) - 1) * 0.01 AS latitude,
    -1.677 + ((random() * 2) - 1) * 0.01 AS longitude
FROM pingouin
WHERE id <= 69;

WITH clusters AS (
    SELECT row_number() OVER () AS cluster_id, *
    FROM (
        VALUES
            (-82.5, -160.0),
            (-66.0,  140.0),
            (-64.0,  -62.0),
            (-75.0,  -45.0),
            (-74.0, -110.0),
            (-90.0,    0.0)
    ) AS t(lat, lon)
),
p2 AS (
    SELECT p.id,
           ((p.id % 6) + 1) AS cluster_id
    FROM pingouin p
    WHERE p.id > 69
)
INSERT INTO position(id, latitude, longitude)
SELECT p2.id,
       c.lat + (random()*0.5 - 0.25),
       c.lon + (random()*0.5 - 0.25)
FROM p2
JOIN clusters c USING(cluster_id);




INSERT INTO couples (parent1_id, parent2_id)
SELECT
    p1.id AS parent1_id,
    p2.id AS parent2_id
FROM (
    SELECT id, row_number() OVER (ORDER BY random()) AS rn
    FROM pingouin
) p1
JOIN (
    SELECT id, row_number() OVER (ORDER BY random()) AS rn
    FROM pingouin
) p2
ON p1.rn = p2.rn + 1
WHERE p1.rn % 2 = 0;


