Для каждого дня в таблицах orders и user_actions рассчитайте следующие показатели:

Выручку, полученную в этот день.
Выручку с заказов новых пользователей, полученную в этот день.
Долю выручки с заказов новых пользователей в общей выручке, полученной за этот день.
Долю выручки с заказов остальных пользователей в общей выручке, полученной за этот день.
Колонки с показателями назовите соответственно revenue, new_users_revenue, new_users_revenue_share, old_users_revenue_share. Колонку с датами назовите date. 

Все показатели долей необходимо выразить в процентах. При их расчёте округляйте значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию даты.

with first_day_order as (SELECT *
                         FROM   (SELECT *,
                                        rank() OVER (PARTITION BY user_id
                                                     ORDER BY time::date) as rnk
                                 FROM   user_actions) x
                         WHERE  rnk = 1
                            and order_id in (SELECT order_id
                                          FROM   user_actions
                                          GROUP BY order_id having count(*) < 2)), order_sum as (SELECT order_id,
                                                              creation_time,
                                                              sum(price) as total
                                                       FROM   (SELECT *,
                                                                      unnest(product_ids) as product_id
                                                               FROM   orders
                                                               WHERE  order_id in (SELECT order_id
                                                                                   FROM   courier_actions
                                                                                   WHERE  action = 'deliver_order')) o join products p
                                                               ON o.product_id = p.product_id
                                                       GROUP BY order_id, creation_time), new_users_revenue1 as (SELECT user_id,
                                                                 time::date as date,
                                                                 sum(total) as total
                                                          FROM   first_day_order fdo
                                                              LEFT JOIN order_sum os
                                                                  ON fdo.order_id = os.order_id
                                                          GROUP BY user_id, time::date), revenue as (SELECT creation_time::date as date,
                                                  sum(total) as revenue
                                           FROM   order_sum
                                           GROUP BY date), new_users_revenue as (SELECT date,
                                             sum(total) as new_users_revenue
                                      FROM   new_users_revenue1
                                      GROUP BY date), revenue_share as (SELECT r.date,
                                         r.revenue,
                                         nus.new_users_revenue,
                                         round((nus.new_users_revenue / r.revenue) * 100.0, 2) as new_users_revenue_share,
                                         round(((r.revenue - nus.new_users_revenue) / r.revenue) * 100.0,
                                               2) as old_users_revenue_share
                                  FROM   revenue r
                                      LEFT JOIN new_users_revenue nus
                                          ON r.date = nus.date)
SELECT date,
       revenue,
       new_users_revenue,
       new_users_revenue_share,
       old_users_revenue_share
FROM   revenue_share
ORDER BY date asc;
