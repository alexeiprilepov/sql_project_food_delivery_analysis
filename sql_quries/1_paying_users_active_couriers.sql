SELECT
    date,
    paying_users,
    active_couriers,
    ROUND(
        paying_users::DECIMAL / COALESCE(
            (
                new_users + SUM(new_users) OVER (
                    ROWS BETWEEN UNBOUNDED PRECEDING
                    AND 1 PRECEDING
                )
            ),
            new_users
        ) * 100,
        2
    ) AS paying_users_share,
    ROUND(
        active_couriers::DECIMAL / COALESCE(
            (
                new_couriers + SUM(new_couriers) OVER (
                    ROWS BETWEEN UNBOUNDED PRECEDING
                    AND 1 PRECEDING
                )
            ),
            new_couriers
        ) * 100,
        2
    ) AS active_couriers_share
FROM
    (
        SELECT
            DATE (TIME) AS date,
            COUNT(DISTINCT user_id) AS paying_users
        FROM
            user_actions
        WHERE
            order_id IN (
                SELECT DISTINCT
                    order_id
                FROM
                    courier_actions
                WHERE
                    order_id NOT IN (
                        SELECT
                            order_id
                        FROM
                            user_actions
                        WHERE
                            ACTION = 'cancel_order'
                    )
            )
        GROUP BY
            date
    ) t1
    JOIN (
        SELECT
            DATE (TIME) AS date,
            COUNT(DISTINCT courier_id) AS active_couriers
        FROM
            courier_actions
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
            date
    ) t2 USING (date)
    JOIN (
        SELECT
            date,
            COUNT(DISTINCT user_id) AS new_users,
            COUNT(DISTINCT courier_id) AS new_couriers
        FROM
            (
                SELECT
                    user_id,
                    MIN(TIME)::DATE AS date
                FROM
                    user_actions
                GROUP BY
                    user_id
            ) t3
            JOIN (
                SELECT
                    courier_id,
                    MIN(TIME)::DATE AS date
                FROM
                    courier_actions
                GROUP BY
                    courier_id
            ) t4 USING (date)
        GROUP BY
            date
    ) t5 USING (date)
ORDER BY
    date;