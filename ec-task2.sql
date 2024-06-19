Для каждого дня в таблицах orders и user_actions рассчитайте следующие показатели:

Выручку на пользователя (ARPU) за текущий день.
Выручку на платящего пользователя (ARPPU) за текущий день.
Выручку с заказа, или средний чек (AOV) за текущий день.
Колонки с показателями назовите соответственно arpu, arppu, aov. Колонку с датами назовите date. 

При расчёте всех показателей округляйте значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию даты. 

with count_users as (SELECT time::date as date,
                            count(distinct user_id) filter(WHERE order_id in (SELECT order_id
                                                                       FROM   user_actions
                                                                       GROUP BY order_id having count(*) < 2)) as paying_users, count(user_id) filter(
                     WHERE  order_id in (SELECT order_id
                                         FROM   user_actions
                                         GROUP BY order_id having count(*) < 2)) as orders, count(distinct user_id) as users
                     FROM   user_actions
                     GROUP BY time::date), revenue as (SELECT creation_time::date as date,
                                         sum(price) as revenue
                                  FROM   (SELECT *,
                                                 unnest(product_ids) as product_id
                                          FROM   orders
                                          WHERE  order_id in (SELECT order_id
                                                              FROM   user_actions
                                                              GROUP BY order_id having count(*) < 2)) o join products p
                                          ON o.product_id = p.product_id
                                  GROUP BY creation_time::date)
SELECT r.date,
       round(revenue/users, 2) as arpu,
       round(revenue/paying_users, 2) as arppu,
       round(revenue/orders, 2) as aov
FROM   revenue r join count_users cu
        ON r.date = cu.date
ORDER BY 1
