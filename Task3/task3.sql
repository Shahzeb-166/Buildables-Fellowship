-- 1. Create table queries 
CREATE TABLE dim_ps5_games(
 	game_sk SERIAL PRIMARY KEY,        -- Surrogate Key
    game_id INT NOT NULL,          
    title VARCHAR(255),
    genre VARCHAR(100),
    developer VARCHAR(100),
    price NUMERIC(10,2),
    ps_plus_included BOOLEAN,
    row_hash TEXT,                     -- Hash of all attributes
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);
CREATE TABLE stg_ps5_games(
	game_id INT NOT NULL,
    title VARCHAR(255),
    genre VARCHAR(100),
    developer VARCHAR(100),
    price NUMERIC(10,2),
    ps_plus_included BOOLEAN,
    row_hash TEXT					   -- Hash of all attributes
);

-- 2. Insret Data
INSERT INTO dim_ps5_games (game_id, title, genre, developer, price, ps_plus_included, row_hash, start_date)
VALUES
(1, 'Spider-Man 2', 'Action', 'Insomniac Games', 69.99, TRUE,
 md5('Spider-Man 2' || 'Action' || 'Insomniac Games' || 69.99::TEXT || TRUE::TEXT), NOW()),
(2, 'FC26', 'Sports', 'EA', 69.99, FALSE,
 md5('FC26' || 'Sports' || 'EA' || 69.99::TEXT || FALSE::TEXT), NOW()),
(3, 'WWE2K24', 'Sports', '2K Games', 49.99, TRUE,
 md5('WWE2K24' || 'Sports' || '2K Games' || 49.99::TEXT || TRUE::TEXT), NOW()),
(4, 'God of war:ragnarok', 'Action', 'Santa Monica Studio', 39.99, TRUE,
 md5('God of war:ragnarok' || 'Action' || 'Santa Monica Studio' || 39.99::TEXT || TRUE::TEXT), NOW()),
(5, 'Ratchet And Clank', 'Action', 'Insomniac Games', 20, TRUE,
 md5('Ratchet And Clank' || 'Action' || 'Insomniac Games' || 20::TEXT || TRUE::TEXT), NOW());

 SELECT * FROM dim_ps5_games;

 -- 3. Changing data in stg_ps5_games
 TRUNCATE TABLE stg_ps5_games;

INSERT INTO stg_ps5_games (game_id, title, genre, developer, price, ps_plus_included, row_hash)
VALUES
-- Changed: Spider-Man 2 price reduced
(1, 'Spider-Man 2', 'Action', 'Insomniac Games', 49.99, TRUE,
 md5('Spider-Man 2' || 'Action' || 'Insomniac Games' || 49.99 || TRUE)),

-- Changed: FC26 added to PS Plus
(2, 'FC26', 'Sports', 'EA', 69.99, TRUE,
 md5('FC26' || 'Sports' || 'EA' || 69.99::TEXT || TRUE::TEXT)),

-- New Game
(6, 'Battlefield 2042', 'FPS', 'EA', 79.99, TRUE,
 md5('Battlefield 2042' || 'FPS' || 'EA' || 79.99 || TRUE));

SELECT * FROM stg_ps5_games;

-- 4. Creaing SCDC2 logic
-- Drop if exists
DROP PROCEDURE IF EXISTS apply_scd2_updates();

CREATE OR REPLACE PROCEDURE apply_scd2_updates()
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. Expire old rows if the hash has changed
    UPDATE dim_ps5_games d
    SET end_date = NOW(),
        is_active = FALSE
    FROM stg_ps5_games s
    WHERE d.game_id = s.game_id
      AND d.is_active = TRUE
      AND d.row_hash <> s.row_hash;

    -- 2. Insert new rows (for changed and new games)
    INSERT INTO dim_ps5_games (
        game_id, title, genre, developer, price, ps_plus_included, row_hash, start_date
    )
    SELECT s.game_id, s.title, s.genre, s.developer, s.price, s.ps_plus_included, s.row_hash, NOW()
    FROM stg_ps5_games s
    LEFT JOIN dim_ps5_games d
      ON d.game_id = s.game_id
     AND d.row_hash = s.row_hash
     AND d.is_active = TRUE
    WHERE d.game_id IS NULL;
END;
$$;
CALL apply_scd2_updates();

SELECT * 
FROM dim_ps5_games 
ORDER BY game_id, start_date;



 