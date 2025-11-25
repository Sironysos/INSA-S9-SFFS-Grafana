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







CREATE OR REPLACE FUNCTION random_penguin_latlon(
    OUT lat FLOAT,
    OUT lon FLOAT
)
AS $$
DECLARE
    zone INT := floor(random()*5) + 1;  -- 1 à 5
BEGIN
    CASE zone
        WHEN 1 THEN   -- Péninsule Antarctique
            lat := rand_range(-64, -60);
            lon := rand_range(-65, -55);

        WHEN 2 THEN   -- Îles Shetland du Sud
            lat := rand_range(-63, -61);
            lon := rand_range(-62, -57);

        WHEN 3 THEN   -- Géorgie du Sud
            lat := rand_range(-55, -53);
            lon := rand_range(-39, -35);

        WHEN 4 THEN   -- Îles Falklands
            lat := rand_range(-53, -51);
            lon := rand_range(-61, -58);

        WHEN 5 THEN   -- Terre Adélie
            lat := rand_range(-68, -65);
            lon := rand_range(135, 146);
    END CASE;
END;
$$ LANGUAGE plpgsql;



WITH rennais AS (
    SELECT id
    FROM pingouin
    ORDER BY id
    LIMIT 69
)
INSERT INTO position(id, latitude, longitude)
SELECT id,
       48.117 + rand_range(-0.005, 0.005),   -- Rennes (≈ ISEN)
       -1.677 + rand_range(-0.005, 0.005)
FROM rennais;


WITH rest AS (
    SELECT p.id
    FROM pingouin p
    LEFT JOIN position pos ON p.id = pos.id
    WHERE pos.id IS NULL
)
INSERT INTO position(id, latitude, longitude)
SELECT id,
       (random_penguin_latlon()).lat,
       (random_penguin_latlon()).lon
FROM rest;

