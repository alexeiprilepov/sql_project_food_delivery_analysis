SELECT
    date,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY
                date
        ) / SUM(new_users) OVER (
            ORDER BY
                date
        ),
        2
    ) AS running_arpu,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY
                date
        ) / SUM(new_paying_users) OVER (
            ORDER BY
                date
        ),
        2
    ) AS running_arppu,
    ROUND(
        SUM(revenue) OVER (
            ORDER BY
                date
        ) / SUM(orders) OVER (
            ORDER BY
                date
        ),
        2
    ) AS running_aov
FROM
    (
        SELECT
            date,
            revenue,
            orders,
            new_users,
            new_paying_users
        FROM
            (
                SELECT
                    date,
                    SUM(price) AS revenue,
                    COUNT(DISTINCT order_id) AS orders
                FROM
                    (
                        SELECT
                            DATE (creation_time) AS date,
                            UNNEST(product_ids) AS product_id,
                            order_id
                        FROM
                            orders
                        WHERE
                            order_id NOT IN (
                                SELECT
                                    order_id
                                FROM
                                    user_actions
                                WHERE
                                    ACTION = 'cancel_order'
                            )
                    ) t1
                    JOIN products USING (product_id)
                GROUP BY
                    date
            ) t2
            LEFT JOIN (
                SELECT
                    date,
                    COUNT(user_id) AS new_users
                FROM
                    (
                        SELECT
                            user_id,
                            MIN(TIME::date) AS date
                        FROM
                            user_actions
                        GROUP BY
                            user_id
                    ) t3
                GROUP BY
                    date
            ) t4 USING (date)
            LEFT JOIN (
                SELECT
                    date,
                    COUNT(user_id) AS new_paying_users
                FROM
                    (
                        SELECT
                            user_id,
                            MIN(TIME::date) AS date
                        FROM
                            user_actions
                        WHERE
                            order_id NOT IN (
                                SELECT
                                    order_id
                                FROM
                                    user_actions
                                WHERE
                                    ACTION = 'cancel_order'
                            )
                        GROUP BY
                            user_id
                    ) t5
                GROUP BY
                    date
            ) t6 USING (date)
    ) t7
ORDER BY
    date;