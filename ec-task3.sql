По таблицам orders и user_actions для каждого дня рассчитайте следующие показатели:

Накопленную выручку на пользователя (Running ARPU).
Накопленную выручку на платящего пользователя (Running ARPPU).
Накопленную выручку с заказа, или средний чек (Running AOV).
Колонки с показателями назовите соответственно running_arpu, running_arppu, running_aov. Колонку с датами назовите date. 

При расчёте всех показателей округляйте значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию даты. 

Поля в результирующей таблице: date, running_arpu, running_arppu, running_aov

with revenue as (SELECT creation_time::date as date,
                        sum(sum(price)) OVER(ORDER BY creation_time::date) as revenue
                 FROM   (SELECT *,
                                unnest(product_ids) as product_id
                         FROM   orders
                         WHERE  order_id in (SELECT order_id
                                             FROM   user_actions
                                             GROUP BY order_id having count(*) < 2)) o join products p
                         ON o.product_id = p.product_id
                 GROUP BY creation_time::date), orders as (SELECT time::date as date,
                                                 sum(count(user_id) filter(WHERE order_id in (SELECT order_id
                                                                                       FROM   user_actions
                                                                                       GROUP BY order_id having count(*) < 2)))
                                          OVER(
                                          ORDER BY time::date) as orders
                                          FROM   user_actions
                                          GROUP BY time::date), pay_users as (SELECT date,
                                           sum(count(*)) OVER(ORDER BY date) as paying_users
                                    FROM   (SELECT user_id,
                                                   min(time::date) as date
                                            FROM   user_actions
                                            WHERE  order_id in (SELECT order_id
                                                                FROM   user_actions
                                                                GROUP BY order_id having count(*) < 2)
                                            GROUP BY user_id) x
                                    GROUP BY date), users as (SELECT date,
                                 sum(count(*)) OVER(ORDER BY date) as users
                          FROM   (SELECT user_id,
                                         min(time::date) as date
                                  FROM   user_actions
                                  GROUP BY user_id) x
                          GROUP BY date), users_count as (SELECT o.date,
                                       orders,
                                       paying_users,
                                       users
                                FROM   orders o
                                    LEFT JOIN pay_users pu
                                        ON o.date = pu.date
                                    LEFT JOIN users u
                                        ON u.date = pu.date)
SELECT r.date,
       round(revenue/users, 2) as running_arpu,
       round(revenue/paying_users, 2) as running_arppu,
       round(revenue/orders, 2) as running_aov
FROM   revenue r join users_count uc
        ON r.date = uc.date
ORDER BY 1
