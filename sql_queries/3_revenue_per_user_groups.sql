SELECT
    date,
    revenue,
    new_users_revenue,
    ROUND(new_users_revenue / revenue * 100, 2) AS new_users_revenue_share,
    ROUND((revenue - new_users_revenue) / revenue * 100, 2) AS old_users_revenue_share
FROM
    (
        SELECT
            first_order_date AS date,
            revenue,
            SUM(new_revenue) AS new_users_revenue
        FROM
            (
                SELECT
                    first_order_date,
                    SUM(price) AS new_revenue
                FROM
                    (
                        SELECT
                            DATE (creation_time) AS date,
                            UNNEST(product_ids) AS product_id,
                            order_id,
                            user_id
                        FROM
                            orders
                            LEFT JOIN user_actions USING (order_id)
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
                    LEFT JOIN products USING (product_id)
                    LEFT JOIN (
                        SELECT
                            user_id,
                            MIN(DATE (TIME)) AS first_order_date
                        FROM
                            user_actions
                        GROUP BY
                            user_id
                    ) t2 USING (user_id)
                WHERE
                    date = first_order_date
                GROUP BY
                    first_order_date
            ) t3
            LEFT JOIN (
                SELECT
                    date,
                    SUM(price) AS revenue
                FROM
                    (
                        SELECT
                            DATE (creation_time) AS date,
                            UNNEST(product_ids) AS product_id
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
                    ) t4
                    LEFT JOIN products USING (product_id)
                GROUP BY
                    date
            ) t5 ON first_order_date = t5.date
        GROUP BY
            first_order_date,
            revenue
    ) t6
GROUP BY
    date,
    revenue,
    new_users_revenue
ORDER BY
    date;