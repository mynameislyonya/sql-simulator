Для каждого товара, представленного в таблице products, за весь период времени в таблице orders рассчитайте следующие показатели:

Суммарную выручку, полученную от продажи этого товара за весь период.
Долю выручки от продажи этого товара в общей выручке, полученной за весь период.
Колонки с показателями назовите соответственно revenue и share_in_revenue. Колонку с наименованиями товаров назовите product_name.

Долю выручки с каждого товара необходимо выразить в процентах. При её расчёте округляйте значения до двух знаков после запятой.

Товары, округлённая доля которых в выручке составляет менее 0.5%, объедините в общую группу с названием «ДРУГОЕ» (без кавычек), просуммировав округлённые доли этих товаров.

Результат должен быть отсортирован по убыванию выручки от продажи товара.

with t as (SELECT p.name ,
                  sum(price) as revenue,
                  round((sum(price)/sum(sum(price)) OVER())*100, 2) as share_in_revenue
           FROM   (SELECT *,
                          unnest(product_ids) as product_id
                   FROM   orders) o join products p
                   ON o.product_id = p.product_id
           WHERE  order_id in (SELECT order_id
                               FROM   user_actions
                               GROUP BY 1 having count(*) < 2)
           GROUP BY p.name)
SELECT new_c as product_name,
       sum(revenue) as revenue,
       sum(share_in_revenue) as share_in_revenue
FROM   (SELECT *,
               case when share_in_revenue < 0.5 then 'ДРУГОЕ'
                    else name end as new_c
        FROM   t) x
GROUP BY new_c
ORDER BY 2 desc
