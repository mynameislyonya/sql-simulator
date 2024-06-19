Задача 1.
Начнём с выручки — наиболее общего показателя, который покажет, какой доход приносит наш сервис.

Задание:

Для каждого дня в таблице orders рассчитайте следующие показатели:

Выручку, полученную в этот день.
Суммарную выручку на текущий день.
Прирост выручки, полученной в этот день, относительно значения выручки за предыдущий день.
Колонки с показателями назовите соответственно revenue, total_revenue, revenue_change. Колонку с датами назовите date.

Прирост выручки рассчитайте в процентах и округлите значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию даты.

with t as (SELECT creation_time,
                  order_id,
                  unnest(product_ids) as product_id
           FROM   orders
           WHERE  order_id in (SELECT order_id
                               FROM   courier_actions
                               WHERE  action = 'deliver_order'))
SELECT *,
       sum(revenue) OVER(ORDER BY date) as total_revenue,
       round(((revenue-lag(revenue) OVER(ORDER BY date))::decimal/(lag(revenue) OVER(ORDER BY date))::decimal)*100,
             2) as revenue_change
FROM   (SELECT creation_time::date as date,
               sum(price) as revenue
        FROM   t
            LEFT JOIN products p
                ON t.product_id = p.product_id
        GROUP BY creation_time::date) x
ORDER BY 1
