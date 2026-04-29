# STRUCTURE DE LA BASE MYSQL (D'APRÈS SCHEMA_NEXA.SQL)
-- Tables principales
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    phone VARCHAR(20),
    registration_date DATE,
    city VARCHAR(50),
    loyalty_score DECIMAL(5,2) # max 5 chiffres au total, max 2 chiffres apres la virgule
);
-- Tables principales
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    phone VARCHAR(20),
    registration_date DATE,
    city VARCHAR(50),
    loyalty_score DECIMAL(5,2)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id VARCHAR(50),
    order_date DATETIME,
    delivery_time_min INT,
    status VARCHAR(20),
    total_amount_xaf DECIMAL(10,2),
    city VARCHAR(50),
    product_category VARCHAR(50),
    courier_id INT
);

CREATE TABLE couriers (
    courier_id INT PRIMARY KEY,
    name VARCHAR(100),
    city VARCHAR(50),
    hire_date DATE
);


-- COMMANDES ORPHELINES (SANS CLIENTS CORRESPONDANT)
-- Commandes sans client valide
SELECT 
    o.order_id,
    o.customer_id,
    o.order_date,
    o.total_amount_xaf
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;
SELECT COUNT(*) AS nb_commandes_orphelines 
FROM orders AS o 
LEFT JOIN customers AS c ON o.customer_id = c.customer_id 
WHERE c.customer_id IS NULL; 

-- Compter combien de commandes orphelines existent 
SELECT COUNT(*) AS nb_commandes_orphelines 
FROM orders AS o 
LEFT JOIN customers AS c ON o.customer_id = c.customer_id 
WHERE c.customer_id IS NULL;

-- montants négatifs ou nuls
-- Commandes avec montant invalide
SELECT
    order_id,
    customer_id,
    order_date,
    total_amount_xaf,
    status,
    city,
    CASE
        WHEN total_amount_xaf IS NULL THEN 'Montant NULL'
        WHEN total_amount_xaf = 0    THEN 'Montant zero'
        WHEN total_amount_xaf < 0    THEN 'Montant negatif'
    END AS type_anomalie
FROM orders
WHERE total_amount_xaf IS NULL
   OR total_amount_xaf <= 0
ORDER BY total_amount_xaf;

-- Résumé
SELECT
    SUM(CASE WHEN total_amount_xaf IS NULL THEN 1 ELSE 0 END) AS montants_null,
    SUM(CASE WHEN total_amount_xaf = 0    THEN 1 ELSE 0 END)  AS montants_zero,
    SUM(CASE WHEN total_amount_xaf < 0    THEN 1 ELSE 0 END)  AS montants_negatifs
FROM orders;


-- doublons dans custumer  
-- Clients dupliqués (même nom + téléphone)
SELECT 
    c1.customer_id      AS id_1, 
    c2.customer_id      AS id_2, 
    c1.name, 
    c1.city, 
    c1.phone            AS tel_1, 
    c2.phone            AS tel_2 
FROM customers AS c1 
INNER JOIN customers AS c2 
    ON  LOWER(TRIM(c1.name)) = LOWER(TRIM(c2.name)) 
    AND LOWER(TRIM(c1.city)) = LOWER(TRIM(c2.city)) 
    AND c1.customer_id < c2.customer_id  -- évite les doublons symétriques 
ORDER BY c1.name

-- Compter uniquement le nombre total de paires de doublons
SELECT COUNT(*) AS nb_paires_doublons
FROM customers AS c1
INNER JOIN customers AS c2
    ON LOWER(TRIM(c1.name)) = LOWER(TRIM(c2.name))
    AND LOWER(TRIM(c1.city)) = LOWER(TRIM(c2.city))
    AND c1.customer_id < c2.customer_id; 

-- RÉSUMÉ FINAL PARTIE I
SELECT
    'Commandes totales'                AS indicateur,
    COUNT(*)                           AS valeur
FROM orders
UNION ALL
SELECT 'Commandes orphelines',
    COUNT(*)
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL
UNION ALL
SELECT 'Montants <= 0',
    COUNT(*) FROM orders WHERE total_amount_xaf <= 0
UNION ALL
SELECT 'delivery_time_min NULL',
    COUNT(*) FROM orders WHERE delivery_time_min IS NULL
UNION ALL
SELECT 'product_category NULL',
    COUNT(*) FROM orders WHERE product_category IS NULL
UNION ALL
SELECT 'Clients totaux',
    COUNT(*) FROM customers
UNION ALL
SELECT 'Clients doublons (téléphone)',
    COUNT(*) FROM (
        SELECT RIGHT(REGEXP_REPLACE(phone,'[^0-9]',''),9) p
        FROM customers
        GROUP BY p HAVING COUNT(*) > 1
    ) t
UNION ALL
SELECT 'loyalty_score hors [0-100]',
    COUNT(*) FROM customers WHERE loyalty_score < 0 OR loyalty_score > 100;


-- PARTIE 2 Utilisez les CTEs (Common Table Expressions) pour calculer le chiffre d'affaires mensuel par ville sur 
-- les 12 derniers mois. 

SELECT 
    DATE_FORMAT(STR_TO_DATE(order_date, '%d/%m/%Y %H:%i'), '%Y-%m') AS mois,
    CASE 
        WHEN UPPER(TRIM(city)) LIKE '%DOUALA%' THEN 'Douala'
        WHEN UPPER(TRIM(city)) LIKE '%YAOUNDE%' OR UPPER(TRIM(city)) LIKE '%YAOUNDÉ%' THEN 'Yaoundé'
        WHEN UPPER(TRIM(city)) LIKE '%BAFOUSSAM%' THEN 'Bafoussam'
        ELSE 'Autre'
    END AS ville,
    SUM(total_amount_xaf) AS chiffre_affaires_xaf
FROM orders
WHERE STR_TO_DATE(order_date, '%d/%m/%Y %H:%i') >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
  AND total_amount_xaf > 0
  AND status NOT IN ('annulé', 'annule', 'cancelled', 'en_cours')
GROUP BY mois, ville
ORDER BY mois DESC, chiffre_affaires_xaf DESC;



-- PARTIE 3  Implémentez des fonctions de fenêtrage (RANK, LAG) pour identifier les livreurs dont le temps de 
-- livraison moyen s'est dégradé sur les 3 derniers mois

WITH livraisons_filtrees AS (
    SELECT 
        courier_id,
        DATE_FORMAT(order_date, '%Y-%m') AS mois,
        delivery_time_min
    FROM orders
    WHERE order_date BETWEEN '2025-01-01' AND '2025-12-31'
      AND status = 'livré'
      AND delivery_time_min IS NOT NULL
      AND delivery_time_min BETWEEN 5 AND 180   -- on exclut les aberrants (<5 min ou >3h)
),
moyennes_mensuelles AS (
    SELECT 
        courier_id,
        mois,
        COUNT(*) AS nb_livraisons,
        AVG(delivery_time_min) AS avg_delivery_time
    FROM livraisons_filtrees
    GROUP BY courier_id, mois
    HAVING COUNT(*) >= 2   -- besoin d'au moins 2 livraisons dans le mois pour une moyenne fiable
),
comparaison AS (
    SELECT 
        courier_id,
        mois,
        nb_livraisons,
        avg_delivery_time,
        LAG(avg_delivery_time) OVER (PARTITION BY courier_id ORDER BY mois) AS prev_month_avg,
        (avg_delivery_time - LAG(avg_delivery_time) OVER (PARTITION BY courier_id ORDER BY mois)) AS degradation_min
    FROM moyennes_mensuelles
)
SELECT 
    courier_id,
    mois,
    nb_livraisons,
    ROUND(avg_delivery_time, 1) AS temps_moyen_min,
    ROUND(prev_month_avg, 1) AS mois_precedent_min,
    ROUND(degradation_min, 1) AS delta_min,
    CASE 
        WHEN degradation_min > 10 THEN 'DÉGRADATION SÉVÈRE'
        WHEN degradation_min BETWEEN 5 AND 10 THEN 'DÉGRADATION LÉGÈRE'
        WHEN degradation_min BETWEEN -5 AND 5 THEN 'STABLE'
        WHEN degradation_min < -5 THEN 'AMÉLIORATION'
        ELSE 'N/A'
    END AS tendance,
    RANK() OVER (ORDER BY degradation_min DESC) AS degradation_rank
FROM comparaison
WHERE degradation_min IS NOT NULL   -- on ignore le premier mois (pas de comparaison)
ORDER BY degradation_min DESC
LIMIT 20;


-- PARTIE 4  Créez une vue SQL v_order_kpis qui centralise les indicateurs clés : taux de livraison à temps, panier 
-- moyen, taux d'annulation — par ville et par mois. 

WITH
dates_converties AS (
    SELECT
        o.order_id,
        o.city,
        o.status,
        o.total_amount_xaf,
        o.delivery_time_min,
        o.customer_id,
        REPLACE(o.order_date, '/', '-') AS date_normalisee,
        o.order_date AS date_originale,
        CASE 
            WHEN LOWER(TRIM(city)) IN ('douala','doula','douala ','DOUALA')   THEN 'douala' 
            WHEN LOWER(TRIM(city)) IN ('yaoundé','yaounde','yaoundé ','yaounde ') THEN 'yaoundé' 
            WHEN LOWER(TRIM(city)) IN ('bafoussam','bafoussam ','BAFOUSSAM')  THEN 'bafoussam' 
            ELSE 'autre' 
        END AS ville
    FROM orders o
    WHERE o.order_date IS NOT NULL
),
dates_valides AS (
    SELECT
        order_id,
        status,
        total_amount_xaf,
        delivery_time_min,
        customer_id,
        ville,  -- ← colonne ajoutée ici
        COALESCE(
            STR_TO_DATE(date_normalisee, '%Y-%m-%d %H:%i:%s'),
            STR_TO_DATE(date_normalisee, '%Y-%m-%d %H:%i'),
            STR_TO_DATE(date_normalisee, '%Y-%m-%d'),
            STR_TO_DATE(date_normalisee, '%d-%m-%Y %H:%i'),
            STR_TO_DATE(date_normalisee, '%d-%m-%Y'),
            STR_TO_DATE(date_normalisee, '%m-%d-%Y %H:%i'),
            STR_TO_DATE(date_normalisee, '%m-%d-%Y'),
            STR_TO_DATE(date_originale, '%d %M %Y'),
            STR_TO_DATE(date_originale, '%e %M %Y'),
            STR_TO_DATE(date_originale, '%d-%M-%Y'),
            STR_TO_DATE(date_originale, '%M %d, %Y')
        ) AS order_date_converted
    FROM dates_converties
)
SELECT
    dv.ville,
    DATE_FORMAT(dv.order_date_converted, '%Y-%m') AS mois,
    COUNT(*) AS nb_commandes_total,
    SUM(CASE WHEN dv.status NOT IN ('annulé', 'en_cours') THEN 1 ELSE 0 END) AS nb_commandes_finalisees,
    ROUND(SUM(CASE WHEN dv.status NOT IN ('annulé', 'en_cours') AND dv.total_amount_xaf > 0 THEN dv.total_amount_xaf ELSE 0 END), 0) AS ca_xaf,
    ROUND(AVG(CASE WHEN dv.status NOT IN ('annulé', 'en_cours') AND dv.total_amount_xaf > 0 THEN dv.total_amount_xaf END), 0) AS panier_moyen_xaf,
    ROUND(SUM(CASE WHEN dv.status = 'livré' THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(CASE WHEN dv.status NOT IN ('annulé', 'en_cours') THEN 1 ELSE 0 END), 0), 1) AS taux_livraison_temps_pct,
    ROUND(SUM(CASE WHEN dv.status = 'en_retard' THEN 1 ELSE 0 END) * 100.0 / NULLIF(SUM(CASE WHEN dv.status NOT IN ('annulé', 'en_cours') THEN 1 ELSE 0 END), 0), 1) AS taux_retard_pct,
    ROUND(SUM(CASE WHEN dv.status = 'annulé' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(*), 0), 1) AS taux_annulation_pct,
    ROUND(AVG(CASE WHEN dv.delivery_time_min IS NOT NULL AND dv.status IN ('livré', 'en_retard') THEN dv.delivery_time_min END), 1) AS tps_livraison_moyen_min
FROM dates_valides dv
INNER JOIN customers c ON dv.customer_id = c.customer_id
WHERE dv.order_date_converted IS NOT NULL
GROUP BY dv.ville, DATE_FORMAT(dv.order_date_converted, '%Y-%m')
ORDER BY mois, dv.ville;


-- PARTIE 5 Optimisez vos requêtes : analysez les plans d'exécution (EXPLAIN) pour au moins 2 de vos requêtes et 
-- proposez les index adaptés.


-- 1. Supprimer les anciens index (pour éviter les erreurs)
DROP INDEX idx_orders_customer_id ON orders;
DROP INDEX idx_orders_date ON orders;
DROP INDEX idx_orders_city ON orders;
DROP INDEX idx_orders_city_date ON orders;
DROP INDEX idx_orders_courier ON orders;
DROP INDEX idx_customers_phone ON customers;

-- 2. EXPLAIN de la requête des commandes orphelines
EXPLAIN
SELECT o.order_id, o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 3. EXPLAIN de la requête du CA mensuel
EXPLAIN
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS mois,
    city,
    SUM(total_amount_xaf) AS ca_total
FROM orders
WHERE total_amount_xaf > 0
  AND order_date >= '2025-01-01'
GROUP BY mois, city;

-- 4. Créer les index
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_city ON orders(city);
CREATE INDEX idx_orders_city_date ON orders(city, order_date);
CREATE INDEX idx_orders_courier ON orders(courier_id);
CREATE INDEX idx_customers_phone ON customers(phone);

-- 5. Refaire les EXPLAIN après index (mêmes requêtes)
EXPLAIN
SELECT o.order_id, o.customer_id
FROM orders o
LEFT JOIN customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

EXPLAIN
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS mois,
    city,
    SUM(total_amount_xaf) AS ca_total
FROM orders
WHERE total_amount_xaf > 0
  AND order_date >= '2025-01-01' 
GROUP BY mois, city;

-- Version plus efficace pour trouver les commandes orphelines
EXPLAIN
SELECT order_id, customer_id
FROM orders
WHERE customer_id NOT IN (SELECT customer_id FROM customers WHERE customer_id IS NOT NULL);