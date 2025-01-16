# Analyse des Ventes Amazon USA : Exploration et Insights

Dans le cadre de ce projet, j’ai analysé un ensemble de données comprenant plus de 20 000 données de ventes issus d’une plateforme e-commerce semblable à Amazon. L’objectif principal est d’explorer les comportements clients, d’évaluer les performances des produits et d’identifier les tendances de vente en utilisant PostgreSQL.

Ce projet m’a permis d’aborder des problématiques variées telles que l’analyse des revenus, la segmentation client et la gestion des stocks, tout en mettant l’accent sur le nettoyage des données, le traitement des valeurs manquantes et l’application de requêtes pour des besoins opérationnels.

Pour compléter cette analyse, un diagramme ERD a été réalisé afin d’illustrer la structure de la base de données et les liens entre les différentes tables.

## Configuration et Conception de la Base de Données

### Structure du Schéma


```sql 
-- Category table
Drop table if exists category;
CREATE TABLE category 
(
	category_id INT PRIMARY KEY,
	category_name VARCHAR (50)
);


-- Customers table
Drop table if exists customers;
CREATE TABLE customers 
(
	customer_id INT PRIMARY KEY,
	first_name VARCHAR (50),
	last_name VARCHAR (50),
	state VARCHAR (50),
	address VARCHAR (5) DEFAULT 'xxxx'
);


-- Sellers table
Drop table if exists sellers;
CREATE TABLE sellers 
(
	seller_id INT PRIMARY KEY,
	seller_name VARCHAR (50),
	origin VARCHAR(50)
);


-- product table
Drop table if exists products;
CREATE TABLE products
(
	product_id INT PRIMARY KEY,
	product_name VARCHAR (70),
	price FLOAT,
	cogs FLOAT,
	category_id INT, -- foreign key
	CONSTRAINT product_fk_category FOREIGN KEY (category_id) REFERENCES category(category_id)
);


-- Orders Table
Drop table if exists orders;
CREATE TABLE orders 
(
	order_id INT PRIMARY KEY,
	order_date DATE,
	customer_id INT, -- FK
	seller_id INT, -- FK
	order_status VARCHAR (25), 
	CONSTRAINT orders_fk_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
	CONSTRAINT orders_fk_seller_id FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);


-- Order_item table
Drop table if exists order_items;
CREATE TABLE order_items 
(
	order_item_id INT PRIMARY Key,
	order_id INT, -- FOREIGN KEY
	product_id INT,
	quantity INT,
	price_per_unit FLOAT,  
	CONSTRAINT order_item_fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id),
	CONSTRAINT order_item_fk_product_id FOREIGN KEY (product_id) REFERENCES products(product_id)
);


-- Payments table
Drop table if exists payments;
CREATE TABLE payments 
(
	payment_id INT PRIMARY KEY,
	order_id INT,  -- Foreign key
	payment_date DATE,
	payment_status VARCHAR (50),
	CONSTRAINT payment_fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- Shipping Table
Drop table if exists shipping;
CREATE TABLE shipping 
(
	shipping_id INT PRIMARY KEY,
	order_id INT,  -- FOREIGN KEY
	shipping_date DATE,
	return_date DATE,
	Shipping_providers VARCHAR (50),
	delivery_status VARCHAR (50),
	CONSTRAINT shipping_fk_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


-- Inventory Table
Drop table if exists inventory;
CREATE TABLE inventory
(
	inventory_id INT PRIMARY KEY,
	product_id INT, -- FK
	stock INT,
	warehouse_id INT,
	last_stock_date DATE,
	CONSTRAINT inventory_fk_product_id FOREIGN KEY (product_id) REFERENCES products(product_id)
);
```


## **Nettoyage des Données**

- **Suppression des doublons** : Les doublons présents dans les tables des clients et des commandes ont été identifiés et supprimés.
- **Gestion des valeurs manquantes** : Les valeurs nulles dans les champs critiques (par exemple, adresse client, statut de paiement) ont été remplies avec des valeurs par défaut ou traitées à l'aide de méthodes appropriées.

## **Gestion des Valeurs Nulles** 

Les valeurs nulles ont été gérées en fonction de leur contexte :
- **Adresses des clients** : Les adresses manquantes ont été remplacées par des valeurs par défaut.
- **Statuts de paiement** : Les commandes avec des statuts de paiement nulls ont été classées comme "En attente".
- **Informations sur les expéditions** : Les dates de retour nulles ont été laissées telles quelles, car tous les envois ne sont pas retournés.


## Objectif

L'objectif principal de ce projet est de démontrer une maîtrise du SQL à travers des requêtes complexes répondant à des problématiques réelles du commerce électronique. L'analyse couvre divers aspects des opérations e-commerce, notamment :
- Le comportement des clients
- Les tendances de vente
- La gestion des stocks
- L'analyse des paiements et des expéditions
- Les prévisions et la performance des produits

## Identification des Problèmes d'Entreprise

1. Faible disponibilité des produits en raison d'un réapprovisionnement irrégulier.
2. Taux élevé de retours pour certaines catégories de produits.
3. Retards importants dans les expéditions et incohérences dans les délais de livraison.
4. Coûts élevés d'acquisition client combinés à un faible taux de rétention.


## **Résolution de Problèmes d’Entreprise**

<br>

**1. Top 10 produits par revenus**  
identification des 10 produits générant les plus hauts revenus.  
Inclure le nom du produit, la quantité totale vendue et la valeur totale des ventes.

```sql
-- Ajout d'une nouvelle colonne 'total_sale' à la table 'order_items'
ALTER TABLE order_items
ADD COLUMN total_sale FLOAT;

-- Mise à jour de la colonne 'total_sale' avec des valeurs calculées
UPDATE order_items
SET total_sale = quantity * price_per_unit;

-- Requête pour récupérer les 10 meilleurs produits par chiffre d'affaires total
SELECT 
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.total_sale) AS total_sales
FROM 
    order_items AS oi
JOIN 
    products AS p ON oi.product_id = p.product_id
GROUP BY 
    p.product_id, p.product_name
ORDER BY 
    total_sales DESC
LIMIT 10;

```
<br>

**2. Revenus total par Catégorie**  
Calcul des revenus totaux générés par chaque catégorie de produits.  
Défi : Inclure la contribution en pourcentage de chaque catégorie au revenu total

```sql
WITH total_quantity_sales AS (
    SELECT
        c.category_name, 
        c.category_id,
        SUM(oi.total_sale) AS total_sales,
        SUM(oi.quantity) AS total_quantity
    FROM 
        order_items AS oi
    JOIN 
        products AS p ON p.product_id = oi.product_id
    JOIN 
        category AS c ON c.category_id = p.category_id
    GROUP BY 
        c.category_name, c.category_id
    ORDER BY 
        total_sales DESC
) 
-- Calculate the percentage of sales for each category
SELECT 
    tqs.category_name, 
    tqs.category_id,
    tqs.total_sales,
    tqs.total_quantity,
    (tqs.total_sales * 100) / SUM(tqs.total_sales) OVER () AS percentage_sales
FROM 
    total_quantity_sales AS tqs;
```
<br>

**3. Valeur Moyenne des Commandes (AOV)**  
Calcul de la valeur moyenne des commandes pour chaque client.  
Défi : Inclure uniquement les clients ayant passé plus de 5 commandes.


```sql
SELECT
    orders.customer_id,
    customers.first_name, 
    customers.last_name, 
    SUM(total_sale) / COUNT(orders.order_id) AS AOV, -- Calcul de la valeur moyenne des commandes (AOV)
    COUNT(orders.order_id) AS total_count_orders -- Calcul du nombre total de commandes
FROM 
    orders
INNER JOIN customers ON customers.customer_id = orders.customer_id -- Jointure avec la table des clients
INNER JOIN order_items ON order_items.order_id = orders.order_id -- Jointure avec la table des articles de commande
GROUP BY 
    orders.customer_id, customers.first_name, customers.last_name -- Regroupement par client
HAVING 
    COUNT(orders.order_id) > 5 -- Filtrer les clients ayant plus de 5 commandes
ORDER BY 
    AOV DESC; -- Tri par valeur moyenne des commandes (AOV) décroissante

```
<br>


**4. Tendance des Ventes Mensuelle**  
Identification des ventes totales mensuelles de l'année écoulée.
Défi : Afficher la tendance des ventes, regroupée par mois, en incluant les ventes du mois courant et du mois précédent.



```sql
-- CTE Affichant les ventes mensuelles pour les 12 derniers mois
WITH schedule AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS year, 
        EXTRACT(MONTH FROM order_date) AS months, 
        ROUND(SUM(order_items.total_sale)::NUMERIC, 2) AS total_sales -- Calcul des ventes totales arrondies à 2 décimales
    FROM orders
    INNER JOIN order_items ON order_items.order_id = orders.order_id 
    WHERE order_date >= CURRENT_DATE - INTERVAL '1 year' -- Filtrer les données pour la dernière année
    GROUP BY months, year 
    ORDER BY total_sales DESC 
)
-- Calcul des ventes totales pour le mois précédent
SELECT 
    year,
    months, 
    total_sales,
    LAG(total_sales) OVER (ORDER BY year, months) AS last_month_sales -- Ventes totales du mois précédent
FROM schedule
ORDER BY year, months; -- Trier par année et mois

```
<br>

**5. Catégories les Moins Vendues par État US**  
Identifiez la catégorie de produit la moins vendue pour chaque État.
Défi : Inclure les ventes totales de cette catégorie dans chaque État.


```sql
-- CTE calculant le classement des ventes par catégorie de produits par état
WITH classement_produits AS (
    SELECT
        customers.state,
        category.category_name,
        category.category_id,
        SUM(total_sale) AS total_sales,
        RANK() OVER(PARTITION BY customers.state ORDER BY SUM(total_sale) ASC) AS rank -- Classement des catégories par état (du moins vendu au plus vendu)
    FROM order_items 
    JOIN products ON products.product_id = order_items.product_id 
    JOIN category ON category.category_id = products.category_id 
    INNER JOIN orders ON orders.order_id = order_items.order_id 
    INNER JOIN customers ON customers.customer_id = orders.customer_id 
    GROUP BY customers.state, category.category_name, category.category_id 
    ORDER BY state, total_sales ASC 
)

-- Affichage uniquement des catégories de produits les moins vendues par état
SELECT *
FROM classement_produits
WHERE rank = 1; -- Filtrer uniquement les catégories ayant le rang 1 (les moins vendues)

```
<br>


**6. Valeur Vie Client (VVC)**  
Calcul de la valeur totale des commandes passées par chaque client au cours de sa vie.  
Defi : Classement des clients en fonction de leur CLTV.


```sql
-- Sélection des clients avec leur VVC et leur classement
SELECT
    orders.customer_id,
    customers.first_name, 
    customers.last_name,
    ROUND(SUM(total_sale)::decimal, 2) AS CLTV, -- Calcul du VVC arrondi à 2 décimales
    DENSE_RANK() OVER (ORDER BY SUM(total_sale) DESC) AS cx_ranking -- Classement des clients basé sur leur CCV
FROM orders
    INNER JOIN customers ON customers.customer_id = orders.customer_id 
    INNER JOIN order_items ON order_items.order_id = orders.order_id 
GROUP BY 
    orders.customer_id, 
    customers.first_name, 
    customers.last_name 
ORDER BY 
    CLTV DESC; 
```
<br>


**7. Prévisions de Vente par Catégorie**  
Prévision des ventes totales par catégorie pour le prochain mois en fonction de la tendance des 6 derniers mois. 

```sql
-- Calcul des ventes mensuelles sur les 6 derniers mois par catégorie
WITH monthly_sales AS (
    SELECT
        c.category_id, 
        c.category_name,
        DATE_TRUNC('month', o.order_date) AS sales_month,
        SUM(oi.total_sale) AS total_sales 
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id 
    JOIN products AS p ON oi.product_id = p.product_id 
    JOIN category AS c ON p.category_id = c.category_id 
    WHERE o.order_date >= CURRENT_DATE - INTERVAL '6 months' 
    GROUP BY c.category_id, c.category_name, sales_month 
)
-- Étape 2 : Calcul des ventes mensuelles moyennes et prévisions
SELECT 
    category_id, 
    category_name, 
    ROUND(AVG(total_sales)::numeric, 2) AS avg_monthly_sales, 
    ROUND(AVG(total_sales)::numeric * 1.05, 2) AS predicted_sales_next_month -- Prévision des ventes pour le mois prochain (+5%)
FROM monthly_sales
GROUP BY category_id, category_name
ORDER BY predicted_sales_next_month DESC;

```
<br>


**8. Retards de Livraison**  
Identification des commandes dont la date d'expédition est postérieure de plus de 3 jours à la date de commande.  
Défi : Inclure les détails des clients, des commandes et du prestataire de livraison.


```sql
-- Requête pour identifier les retards de livraison (plus de 3 jours après la date de commande)
SELECT
    shipping.order_id, 
    customers.first_name, 
    customers.last_name,
    orders.order_date,
    shipping.shipping_date, 
    shipping.shipping_providers
FROM shipping
INNER JOIN orders ON orders.order_id = shipping.order_id
INNER JOIN customers ON customers.customer_id = orders.customer_id
WHERE shipping.shipping_date > orders.order_date + INTERVAL '3 days';
```  
  <br>


**10. Meilleurs Vendeurs**  
Identification des 5 meilleurs vendeurs par valeur totale des ventes.  
Défi : Inclure les commandes réussies et échouées, et afficher leur pourcentage de commandes réussies.


```sql
-- CTE calculant les ventes totales, le nombre total de commandes et le nombre de commandes réussies par vendeur
WITH sales_per_seller AS (
    SELECT 
        seller_id,
        ROUND(SUM(total_sale)::numeric, 2) AS total_sales, -- Calcul du total des ventes
        COUNT(*) AS total_orders, -- Calcul du nombre total de commandes
        COUNT(*) FILTER (WHERE payments.payment_status = 'Payment Successed') AS successful_orders -- Commandes réussies
    FROM order_items
    INNER JOIN orders ON orders.order_id = order_items.order_id
    INNER JOIN payments ON payments.order_id = orders.order_id
    GROUP BY seller_id
    ORDER BY total_sales DESC
)
-- Calcul du pourcentage de commandes réussies et récupération des informations du vendeur
SELECT 
    sp.seller_id, 
    s.seller_name, 
    sp.total_sales, 
    sp.total_orders, 
    sp.successful_orders,
    ROUND((sp.successful_orders * 100.0 / sp.total_orders)::numeric, 2) AS success_rate -- Pourcentage de commandes réussies
FROM sales_per_seller sp
INNER JOIN sellers s ON s.seller_id = sp.seller_id
ORDER BY sp.total_sales DESC 
LIMIT 5; 

 ```
 <br>


**11. Marge de Bénéfice des Produits**  
Calcul de la marge de bénéfice pour chaque produit.  
Défi : Classer les produits par leur marge de bénéfice, de la plus élevée à la plus basse.
*/

```sql
-- Sélection des produits avec leur marge bénéficiaire et classement
SELECT
    product_id, 
    product_name, 
    total_sales,
    total_cost, 
    pourcentage_profit_margin,
    DENSE_RANK() OVER (ORDER BY pourcentage_profit_margin DESC) AS product_ranking -- Classement des produits par marge bénéficiaire
FROM (
    -- Sous-requête calculant les marges bénéficiaires par produit
    SELECT 
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.quantity * p.price)::numeric, 2) AS total_sales,
        ROUND(SUM(oi.quantity * p.cogs)::numeric, 2) AS total_cost,
        ROUND(
            SUM(oi.quantity * p.price - (oi.quantity * p.cogs)) 
            / SUM(oi.quantity * p.price) * 100, 
            2
        ) AS pourcentage_profit_margin -- Marge bénéficiaire en pourcentage
    FROM order_items AS oi
    JOIN products AS p ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
) AS t1
ORDER BY pourcentage_profit_margin DESC; 

```
<br>


**12. Analyse des Retours**  
Question : Analysez les produits ayant les taux de retour les plus élevés et détectez les raisons potentielles

```sql
-- Agrégation des données pour calculer le taux de retour par produit
WITH return_rates AS (
    SELECT
        p.product_id,
        p.product_name, 
        COUNT(*) AS total_orders,
        SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS total_returns,
        ROUND(
            SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric 
            / COUNT(*)::numeric * 100, 
            2
        ) AS return_rate
    FROM orders AS o
    JOIN order_items AS oi ON o.order_id = oi.order_id
    JOIN products AS p ON oi.product_id = p.product_id
    GROUP BY p.product_id, p.product_name
)

SELECT 
    rr.product_id,
    rr.product_name,
    rr.total_orders, 
    rr.total_returns, 
    rr.return_rate, 
    CASE 
        WHEN rr.return_rate > 30 THEN 'Investigate' -- Action : Investiguer si le taux de retour dépasse 30%
        ELSE 'Normal' -- Action : Aucune mesure particulière requise
    END AS action_required 
FROM return_rates AS rr
ORDER BY rr.return_rate DESC; 

```
<br>

**13. Analyse de Churn des Clients**  
Identification les clients "inactifs", n'ayant pas commandé depuis 6 mois et estimation de leur probabilité de churn en fonction de leur fréquence d'achat 

```sql
-- Calcul de la différence entre les dates de commande pour chaque client
WITH order_differences AS (
    SELECT 
        customer_id,
        order_date,
        LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS previous_order_date,
        DATE_PART('day', order_date::timestamp 
             - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)::timestamp) AS days_between_orders
    FROM orders
),

-- Calcul de l'activité des clients
customer_activity AS (
    SELECT 
        customer_id,
        MAX(order_date) AS last_order_date,       -- Dernière date de commande
        COUNT(*) AS total_orders,                -- Nombre total de commandes
        AVG(days_between_orders) AS avg_days_between_orders -- Moyenne des jours entre commandes
    FROM order_differences
    GROUP BY customer_id
)

-- Analyse des risques de churn
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    ca.last_order_date,                         
    ca.total_orders,                            
    ca.avg_days_between_orders,                 
    CASE 
        WHEN CURRENT_DATE - ca.last_order_date > COALESCE(ca.avg_days_between_orders, 180) 
        THEN 'High Risk'                        -- Risque élevé si inactivité prolongée
        ELSE 'Low Risk'                         -- Faible risque si l'activité est régulière
    END AS churn_risk                           
FROM customers AS c
LEFT JOIN customer_activity AS ca 
    ON c.customer_id = ca.customer_id
WHERE CURRENT_DATE - ca.last_order_date > 180; 

```
<br>

**14. Identification des clients à fort taux de retour**  
Classificqtion des client ayant effectué plus de 5 retours comme "Haut taux de retour", et ceux ayant fait moins de 5 retour comme "Bas taux de retour".  
Défi : Lister l'ID client, le nom, le total des commandes et le nombre total de retours.


```sql
-- IdentificTION les clients ayant effectué des retours et compte le nombre de commandes retournées par client
WITH returned_orders AS (
    SELECT
        orders.customer_id,
        customers.last_name,
        COUNT(*) AS count_returned_orders
    FROM orders
    LEFT JOIN customers ON customers.customer_id = orders.customer_id
    WHERE orders.order_status = 'Returned' -- Filtre uniquement les commandes retournées
    GROUP BY orders.customer_id, customers.last_name
)

-- Classe les clients en 2 catégories et compte le nombre total de commandes
SELECT 
    returned_orders.customer_id,
    returned_orders.last_name,
    returned_orders.count_returned_orders, 
    COUNT(orders.order_id) AS total_orders,
    CASE 
        WHEN returned_orders.count_returned_orders > 5 THEN 'Fort taux de retour' 
        ELSE 'Taux de retour normal' 
    END AS category -- Catégorisation des clients selon leur taux de retour
FROM returned_orders
INNER JOIN orders ON returned_orders.customer_id = orders.customer_id
GROUP BY returned_orders.customer_id, returned_orders.last_name, returned_orders.count_returned_orders;

```
<br>


**15. Top 10 des Produits avec la Plus Forte Baisse de revenus**  
Identification des 10 produits ayant le ratio de baisse de revenus le plus élevé entre 2022 et 2023.  
Défi : Retourner l'ID produit, le nom du produit, le nom de la catégorie, les revenus de 2022 et 2023, et le ratio de baisse de revenus en pourcentage.  
Note : Ratio de baisse = (revenus_2023 - revenus_2022) / revenus_2022 * 100
*/

```sql
-- CTE pour calculer le montant total des ventes pour 2022
WITH totalsales_2022 AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(total_sale) AS sales2022 
    FROM order_items oi
    INNER JOIN orders o ON o.order_id = oi.order_id
    INNER JOIN products p ON p.product_id = oi.product_id
    INNER JOIN category c ON c.category_id = p.category_id
    WHERE EXTRACT(YEAR FROM o.order_date) = 2022 
    GROUP BY p.product_id, c.category_name, p.product_name
),

-- CTE pour calculer le montant total des ventes pour 2023
totalsales_2023 AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(total_sale) AS sales2023 
    FROM order_items oi
    INNER JOIN orders o ON o.order_id = oi.order_id
    INNER JOIN products p ON p.product_id = oi.product_id
    INNER JOIN category c ON c.category_id = p.category_id
    WHERE EXTRACT(YEAR FROM o.order_date) =
    GROUP BY p.product_id, c.category_name, p.product_name
)

-- Calcul du ratio de diminution des ventes entre 2022 et 2023
SELECT 
    t22.product_id,
    t22.product_name,
    t22.category_name,
    t22.sales2022, 
    t23.sales2023, 
    ROUND((t23.sales2023 - t22.sales2022)::numeric / t22.sales2022::numeric * 100, 2) AS Decrease_ratio -- Ratio de diminution
FROM totalsales_2022 t22
INNER JOIN totalsales_2023 t23 ON t22.product_id = t23.product_id
WHERE t22.sales2022 > t23.sales2023 -- Filtre les produits avec des ventes en baisse
ORDER BY Decrease_ratio
LIMIT 10; 

```
<br>


**16. Procédure stockée**   
Développement d'une fonction qui met à jour automatiquement le stock dans la table d'inventaire à chaque vente.  
Dès qu'un nouvel enregistrement de vente est ajouté, la quantité vendue doit être déduite du stock disponible correspondant dans l'inventaire.



## **Résultats d'Apprentissage**

Ce projet m'a permis de :
- Concevoir et implémenter un schéma de base de données normalisé.
- Nettoyer et prétraiter des ensembles de données réels pour l'analyse.
- Utiliser des techniques SQL avancées, notamment les fonctions de fenêtre, les sous-requêtes et les jointures et procédures stockées.
- Réaliser une analyse approfondie des données commerciales à l'aide de SQL.
- Optimiser les performances des requêtes et gérer efficacement de grands ensembles de données.


## **Conclusion**

Ce projet SQL avancé démontre avec succès ma capacité à résoudre des problématiques réelles du commerce électronique à l'aide de requêtes structurées. De l'amélioration de la rétention client à l'optimisation des stocks et de la logistique, ce projet fournit des insights précieux sur les défis opérationnels et leurs solutions.

En réalisant ce projet, j'ai acquis une compréhension approfondie de l'utilisation de SQL pour résoudre des problèmes de données complexes et soutenir la prise de décision en entreprise.
