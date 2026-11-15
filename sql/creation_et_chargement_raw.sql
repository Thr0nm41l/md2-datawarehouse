-- Partie 1 : création de la base, des schémas et chargement de la couche RAW

-- Équivalent PostgreSQL du script Snowflake demandé.
-- Exécution (depuis la racine du dépôt, pour que le chemin du CSV soit valide) :
-- psql -U postgres -d postgres -f sql/01_creation_et_chargement_raw.sql
-- Le script est rejouable : il recrée la table RAW et la recharge entièrement.

\set ON_ERROR_STOP on

-- 1. Base de données
-- CREATE DATABASE ne supporte pas IF NOT EXISTS : on génère l'ordre seulement
-- si la base n'existe pas encore, puis on l'exécute avec \gexec.
SELECT 'CREATE DATABASE superstore_db'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'superstore_db')\gexec

\connect superstore_db

-- 2. Schémas de l'architecture médaillon
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS silver;
CREATE SCHEMA IF NOT EXISTS gold;

-- 3. Table RAW.SALES
-- La couche RAW conserve le fichier source à l'identique : noms de colonnes
-- d'origine et toutes les valeurs en texte. Le typage, le renommage et le
-- nettoyage sont faits par dbt dans la couche SILVER.
DROP TABLE IF EXISTS raw.sales;

CREATE TABLE raw.sales (
    "Row ID"        text,
    "Order ID"      text,
    "Order Date"    text,
    "Ship Date"     text,
    "Ship Mode"     text,
    "Customer ID"   text,
    "Customer Name" text,
    "Segment"       text,
    "Country"       text,
    "City"          text,
    "State"         text,
    "Postal Code"   text,
    "Region"        text,
    "Product ID"    text,
    "Category"      text,
    "Sub-Category"  text,
    "Product Name"  text,
    "Sales"         text,
    "Quantity"      text,
    "Discount"      text,
    "Profit"        text,
    _loaded_at      timestamptz NOT NULL DEFAULT now(),
    _source_file    text        NOT NULL DEFAULT 'superstore.csv'
);

COMMENT ON TABLE raw.sales IS
    'Superstore Sales (Kaggle vivek468/superstore-dataset-final), chargé tel quel depuis data/superstore.csv';

-- Import du CSV. Le fichier Kaggle est encodé en Windows-1252 (il contient des
-- espaces insécables 0xA0 dans certains noms de produits) : on le précise pour
-- que PostgreSQL le convertisse correctement en UTF-8.
\copy raw.sales ("Row ID", "Order ID", "Order Date", "Ship Date", "Ship Mode", "Customer ID", "Customer Name", "Segment", "Country", "City", "State", "Postal Code", "Region", "Product ID", "Category", "Sub-Category", "Product Name", "Sales", "Quantity", "Discount", "Profit") FROM 'data/superstore.csv' WITH (FORMAT csv, HEADER true, ENCODING 'WIN1252')

-- 4. Vérifications
-- Nombre de lignes chargées (attendu : 9 994).
SELECT count(*) AS nb_lignes FROM raw.sales;

-- Échantillon des données.
SELECT "Row ID", "Order ID", "Order Date", "Ship Date", "Customer ID",
       "Segment", "Region", "Category", "Product Name",
       "Sales", "Quantity", "Discount", "Profit"
FROM raw.sales
ORDER BY "Row ID"::int
LIMIT 10;
