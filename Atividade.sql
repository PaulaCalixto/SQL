-- Preencher valores nulos com 'NAN'
DO $$
DECLARE
    rec record;
BEGIN
    FOR rec IN 
        SELECT * FROM information_schema.columns WHERE TABLE_NAME = 'netflix_titles' AND TABLE_SCHEMA = 'public' AND DATA_TYPE = 'character varying'
    LOOP
        EXECUTE 'UPDATE netflix_titles SET ' || rec.column_name || ' = NULLIF(' || rec.column_name || ', '''') WHERE ' || rec.column_name || ' IS NULL';
    END LOOP;
END
$$;

-- Normalizar a coluna CAST
CREATE TABLE cast_table AS (
    SELECT show_id, UNNEST(STRING_TO_ARRAY(cast, ', ')) AS cast_member
    FROM netflix_titles
);

-- Normalizar a coluna listed_in
CREATE TABLE genre_table AS (
    SELECT show_id, UNNEST(STRING_TO_ARRAY(listed_in, ', ')) AS genre
    FROM netflix_titles
);

-- Normalizar a coluna date_added
CREATE TABLE date_table AS (
    SELECT 
        show_id,
        TO_CHAR(date_added, 'DD') AS day,
        TO_CHAR(date_added, 'MM') AS month,
        TO_CHAR(date_added, 'YY') AS year,
        TO_CHAR(date_added, 'YYYY-MM-DD') AS iso_date_1,
        TO_CHAR(date_added, 'YYYY/MM/DD') AS iso_date_2,
        TO_CHAR(date_added, 'YYMMDD') AS iso_date_3,
        TO_CHAR(date_added, 'YYYYMMDD') AS iso_date_4
    FROM netflix_titles
);

-- Normalizar a coluna duration
CREATE TABLE time_table AS (
    SELECT 
        show_id,
        title,
        type,
        CASE
            WHEN type = 'Movie' THEN COALESCE(NULLIF(SUBSTRING(duration, 1, POSITION(' ' IN duration)-1)::INTEGER, 0), 0) * 60
            WHEN type = 'TV Show' THEN COALESCE(NULLIF(SUBSTRING(duration, 1, POSITION(' ' IN duration)-1)::INTEGER, 0), 0) * 10 * 60
        END AS minutes
    FROM netflix_titles
);

-- Normalizar a coluna country
CREATE TABLE country_table AS (
    SELECT show_id, UNNEST(STRING_TO_ARRAY(country, ', ')) AS country
    FROM netflix_titles
);

-- Adicionar a coluna last_name_director
CREATE TABLE director_table AS (
    SELECT 
        show_id,
        title,
        type,
        director,
        SUBSTRING(director, POSITION(' ' IN director)+1) || ', ' || SUBSTRING(director, 1, POSITION(' ' IN director)-1) AS last_name_director
    FROM netflix_titles
);

-- Consultas de negócio

-- 1. Qual o filme de duração máxima em minutos?
SELECT title, minutes
FROM time_table
WHERE type = 'Movie'
ORDER BY minutes DESC
LIMIT 1;
-- RESPOSTA: Black Mirror: Bandersnatch, 312 min

-- 2. Qual o filme de duração mínima em minutos?
SELECT title, minutes
FROM time_table
WHERE type = 'Movie'
ORDER BY minutes
LIMIT 1;
-- RESPOSTA: Silent, 3 min

-- 3. Qual a série de duração máxima em minutos?
SELECT title, minutes
FROM time_table
WHERE type = 'TV Show'
ORDER BY minutes DESC
LIMIT 1;
-- RESPOSTA: Grey's Anatomy, 10200 min

-- 4. Qual a série de duração mínima em minutos?
SELECT title, minutes
FROM time_table
WHERE type = 'TV Show'
ORDER BY minutes
LIMIT 1;
-- RESPOSTA: 1793 Series

-- 5. Qual a média de tempo de duração dos filmes?
SELECT AVG(minutes) AS average_movie_duration
FROM time_table
WHERE type = 'Movie';
-- RESPOSTA: 99 min

-- 6. Qual a média de tempo de duração das séries?
SELECT AVG(minutes) AS average_tv_show_duration
FROM time_table
WHERE type = 'TV Show';
-- RESPOSTA: 1058 min

-- 7. Qual a lista de filmes em que o ator Leonardo DiCaprio participa?
SELECT title
FROM netflix_titles
WHERE cast LIKE '%Leonardo DiCaprio%' AND type = 'Movie';
-- As tabelas não foram exibidas, houve problema no download.

-- 8. Quantas vezes o ator Tom Hanks apareceu nas telas do Netflix?
SELECT COUNT(*)
FROM netflix_titles
WHERE cast LIKE '%Tom Hanks%';
-- RESPOSTA: 8

-- 9. Quantas produções, séries e filmes brasileiros, já foram ao ar no Netflix?
SELECT COUNT(*)
FROM netflix_titles
WHERE country LIKE '%Brazil%';
-- RESPOSTA: 77

-- 10. Quantos filmes americanos já foram para o ar no Netflix?
SELECT COUNT(*)
FROM netflix_titles
WHERE country LIKE '%United States%' AND type = 'Movie';
-- RESPOSTA: 2058

-- 11. Procure a lista de conteúdos que tenha como temática a Segunda Guerra Mundial (WWII)?
SELECT title
FROM netflix_titles
WHERE description LIKE '%WWII%' OR title LIKE '%WWII%';

-- 12. Conte o número de produções dos países que apresentaram conteúdos no Netflix?
SELECT country, COUNT(*) AS production_count
FROM netflix_titles
GROUP BY country
ORDER BY production_count DESC;
