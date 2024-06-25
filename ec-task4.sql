Для каждого дня недели в таблицах orders и user_actions рассчитайте следующие показатели:

Выручку на пользователя (ARPU).
Выручку на платящего пользователя (ARPPU).
Выручку на заказ (AOV).
При расчётах учитывайте данные только за период с 26 августа 2022 года по 8 сентября 2022 года включительно — так, чтобы в анализ попало одинаковое количество всех дней недели (ровно по два дня).

В результирующую таблицу включите как наименования дней недели (например, Monday), так и порядковый номер дня недели (от 1 до 7, где 1 — это Monday, 7 — это Sunday).

Колонки с показателями назовите соответственно arpu, arppu, aov. Колонку с наименованием дня недели назовите weekday, а колонку с порядковым номером дня недели weekday_number.

При расчёте всех показателей округляйте значения до двух знаков после запятой.

Результат должен быть отсортирован по возрастанию порядкового номера дня недели.

with count_users as (SELECT to_char(time, 'Day') as weekday,
                            date_part('isodow', time::date) as weekday_number,
                            count(distinct user_id) filter (WHERE time between '2022-08-26' and '2022-09-09' and order_id in (SELECT order_id
                                                                                                                       FROM   user_actions
                                                                                                                       GROUP BY order_id having count(*) < 2)) as paying_users, count(user_id) filter (
                     WHERE  time between '2022-08-26'
                        and '2022-09-09'
                        and order_id in (SELECT order_id
                                      FROM   user_actions
                                      GROUP BY order_id having count(*) < 2)) as orders, count(distinct user_id) filter (
                     WHERE  time between '2022-08-26'
                        and '2022-09-09') as users
                     FROM   user_actions
                     GROUP BY to_char(time, 'Day'), date_part('isodow', time::date)), revenue as (SELECT to_char(creation_time, 'Day') as weekday,
                                                                                    date_part('isodow', creation_time::date) as weekday_number,
                                                                                    sum(price) as revenue
                                                                             FROM   (SELECT *,
                                                                                            unnest(product_ids) as product_id
                                                                                     FROM   orders
                                                                                     WHERE  order_id in (SELECT order_id
                                                                                                         FROM   user_actions
                                                                                                         GROUP BY order_id having count(*) < 2)) o join products p
                                                                                     ON o.product_id = p.product_id
                                                                             WHERE  creation_time between '2022-08-26'
                                                                                and '2022-09-09'
                                                                             GROUP BY to_char(creation_time, 'Day'), date_part('isodow', creation_time::date))
SELECT cu.weekday,
       cu.weekday_number,
       round(r.revenue / cu.users, 2) as arpu,
       round(r.revenue / cu.paying_users, 2) as arppu,
       round(r.revenue / cu.orders, 2) as aov
FROM   count_users cu join revenue r
        ON cu.weekday = r.weekday and
           cu.weekday_number = r.weekday_number
ORDER BY cu.weekday_number;
