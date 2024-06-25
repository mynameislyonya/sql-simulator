Для каждого дня в таблицах orders и courier_actions рассчитайте следующие показатели:

Выручку, полученную в этот день.
Затраты, образовавшиеся в этот день.
Сумму НДС с продажи товаров в этот день.
Валовую прибыль в этот день (выручка за вычетом затрат и НДС).
Суммарную выручку на текущий день.
Суммарные затраты на текущий день.
Суммарный НДС на текущий день.
Суммарную валовую прибыль на текущий день.
Долю валовой прибыли в выручке за этот день (долю п.4 в п.1).
Долю суммарной валовой прибыли в суммарной выручке на текущий день (долю п.8 в п.5).
Колонки с показателями назовите соответственно revenue, costs, tax, gross_profit, total_revenue, total_costs, total_tax, total_gross_profit, gross_profit_ratio, total_gross_profit_ratio

Колонку с датами назовите date.

Долю валовой прибыли в выручке необходимо выразить в процентах, округлив значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию даты.

with order_sum as (SELECT order_id,
                          creation_time,
                          sum(price) as total
                   FROM   (SELECT *,
                                  unnest(product_ids) as product_id
                           FROM   orders
                           WHERE  order_id in (SELECT order_id
                                               FROM   courier_actions
                                               WHERE  action = 'deliver_order')) o join products p
                           ON o.product_id = p.product_id
                   GROUP BY order_id, creation_time), revenue as (SELECT creation_time::date as date,
                                                      sum(total) as revenue
                                               FROM   order_sum
                                               GROUP BY date), couriers_payment as(SELECT time,
                                           sum(total) as total_c
                                    FROM   (SELECT *,
                                                   case when extract(month
                                            FROM   time::date) = 8 and cnt >= 5 then cnt*150+400 when extract(month
                                            FROM   time::date) = 8 and cnt <= 5 then cnt*150 when extract(month
                                            FROM   time::date) = 9 and cnt >= 5 then cnt*150+500 when extract(month
                                            FROM   time::date) = 9 and cnt <= 5 then cnt*150 end as total
                                            FROM   (SELECT time::date,
                                                           courier_id,
                                                           count(order_id) as cnt
                                                    FROM   courier_actions
                                                    WHERE  action = 'deliver_order'
                                                    GROUP BY time::date, courier_id)x)y
                                    GROUP BY time), order_payment as (SELECT time,
                                         case when extract(month
                                  FROM   time::date) = 8 then cnt*140 + 120000 when extract(month
                                  FROM   time::date) = 9 then cnt*115 + 150000 end as total_o
                                  FROM   (SELECT time::date,
                                                 count(order_id) as cnt
                                          FROM   courier_actions
                                          WHERE  order_id in (SELECT order_id
                                                              FROM   courier_actions
                                                              WHERE  action = 'deliver_order')
                                             and action = 'accept_order'
                                          GROUP BY time::date) x), payment as (SELECT cp.time as date,
                                            total_o+total_c as payment
                                     FROM   couriers_payment cp
                                         LEFT JOIN order_payment op
                                             ON cp.time = op.time
                                     ORDER BY 1), tax as (SELECT creation_time::date as date,
                            sum(tax) as tax
                     FROM   (SELECT *,
                                    case when name in ('сахар', 'сухарики', 'сушки', 'семечки', 'масло льняное', 'виноград',
                                                       'масло оливковое', 'арбуз', 'батон', 'йогурт', 'сливки',
                                                       'гречка', 'овсянка', 'макароны', 'баранина', 'апельсины',
                                                       'бублики', 'хлеб', 'горох', 'сметана', 'рыба копченая', 'мука',
                                                       'шпроты', 'сосиски', 'свинина', 'рис', 'масло кунжутное',
                                                       'сгущенка', 'ананас', 'говядина', 'соль', 'рыба вяленая',
                                                       'масло подсолнечное', 'яблоки', 'груши', 'лепешка', 'молоко',
                                                       'курица', 'лаваш', 'вафли', 'мандарины') then round ((price / 110 * 10), 2)
                                         else round ((price / 120 * 20), 2) end as tax
                             FROM   (SELECT *,
                                            unnest(product_ids) as product_id
                                     FROM   orders
                                     WHERE  order_id in (SELECT order_id
                                                         FROM   courier_actions
                                                         WHERE  action = 'deliver_order')) o join products p
                                     ON o.product_id = p.product_id) x
                     GROUP BY creation_time::date)
SELECT r.date,
       revenue,
       payment as costs,
       tax,
       revenue - payment- tax as gross_profit,
       sum(revenue) OVER(ORDER BY r.date) as total_revenue,
       sum(payment) OVER(ORDER BY r.date) as total_costs,
       sum(tax) OVER(ORDER BY r.date) as total_tax ,
       sum(revenue - payment- tax) OVER(ORDER BY r.date) as total_gross_profit,
       round((revenue - payment- tax)/revenue*100, 2) as gross_profit_ratio,
       round(sum(revenue - payment- tax) OVER(ORDER BY r.date)/sum(revenue) OVER(ORDER BY r.date) * 100,
             2) as total_gross_profit_ratio
FROM   revenue r
    LEFT JOIN payment p
        ON r.date = p.date
    LEFT JOIN tax t
        ON p.date = t.date
ORDER BY 1
