/* =========================================================
   1. CREATE DATABASE
   ========================================================= */

CREATE DATABASE IF NOT EXISTS it_help;

USE it_help;


/* =========================================================
   2. CHECK TABLE
   ========================================================= */

SELECT *
FROM IT_Help_Desk_Case_Info
LIMIT 5;


/* =========================================================
   3. CREATE WORKING VIEW
   This converts both date formats into proper DATETIME.
   ========================================================= */

CREATE OR REPLACE VIEW case_data AS

SELECT
    Case_Id,
    Case_Type,
    Case_Area,
    Case_Severity,
    Case_Priority,
    `Service_Agent ID`,
    Agent_Training_Level,

    /* Convert Case Sent Time */

    CASE
        WHEN Case_sent_time LIKE '%/%'
        THEN STR_TO_DATE(
            Case_sent_time,
            '%m/%d/%Y %H:%i'
        )

        ELSE STR_TO_DATE(
            Case_sent_time,
            '%d-%m-%Y %H:%i:%s'
        )
    END AS Sent_Time,


    /* Convert Case Resolution Time */

    CASE
        WHEN Case_resolution_time LIKE '%/%'
        THEN STR_TO_DATE(
            Case_resolution_time,
            '%m/%d/%Y %H:%i'
        )

        ELSE STR_TO_DATE(
            Case_resolution_time,
            '%d-%m-%Y %H:%i:%s'
        )
    END AS Resolution_Time

FROM IT_Help_Desk_Case_Info;
/* =========================================================
   TASK 1
   Average Resolution Time for Each Agent
   ========================================================= */

SELECT

    `Service_Agent ID`,

    ROUND(
        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                Sent_Time,
                Resolution_Time
            ) / 60.0
        ),
        2
    ) AS Avg_Resolution_Hrs

FROM case_data

GROUP BY `Service_Agent ID`

ORDER BY Avg_Resolution_Hrs;


/* =========================================================
   TASK 2
   Agents with Above-Average Resolution Time
   ========================================================= */

WITH Agent_Average AS
(
    SELECT

        `Service_Agent ID`,

        AVG(
            TIMESTAMPDIFF(
                MINUTE,
                Sent_Time,
                Resolution_Time
            ) / 60.0
        ) AS Avg_Resolution_Hrs

    FROM case_data

    GROUP BY `Service_Agent ID`
),

Overall_Average AS
(
    SELECT
        AVG(Avg_Resolution_Hrs) AS Overall_Avg_Resolution_Hrs
    FROM Agent_Average
)

SELECT

    a.`Service_Agent ID`,

    ROUND(
        a.Avg_Resolution_Hrs,
        2
    ) AS Avg_Resolution_Hrs,

    ROUND(
        o.Overall_Avg_Resolution_Hrs,
        2
    ) AS Overall_Avg_Resolution_Hrs

FROM Agent_Average a

CROSS JOIN Overall_Average o

WHERE a.Avg_Resolution_Hrs >
      o.Overall_Avg_Resolution_Hrs

ORDER BY a.Avg_Resolution_Hrs DESC;


/* =========================================================
   TASK 3
   Overall SLA Compliance
   ========================================================= */

SELECT

    COUNT(*) AS Total_Cases,

    SUM(

        CASE

            WHEN
                TIMESTAMPDIFF(
                    MINUTE,
                    Sent_Time,
                    Resolution_Time
                ) / 60.0

                <=

                CASE
                    WHEN Case_Priority = '3_High'
                        THEN 4

                    WHEN Case_Priority = '2_Medium'
                        THEN 8

                    WHEN Case_Priority = '1_Low'
                        THEN 24

                    WHEN Case_Priority = '0_Unassigned'
                        THEN 72
                END

            THEN 1

            ELSE 0

        END

    ) AS SLA_Met_Cases,


    ROUND(

        100.0 *

        SUM(

            CASE

                WHEN
                    TIMESTAMPDIFF(
                        MINUTE,
                        Sent_Time,
                        Resolution_Time
                    ) / 60.0

                    <=

                    CASE
                        WHEN Case_Priority = '3_High'
                            THEN 4

                        WHEN Case_Priority = '2_Medium'
                            THEN 8

                        WHEN Case_Priority = '1_Low'
                            THEN 24

                        WHEN Case_Priority = '0_Unassigned'
                            THEN 72
                    END

                THEN 1

                ELSE 0

            END

        ) / COUNT(*),

        2

    ) AS SLA_Compliance_Pct

FROM case_data;


/* =========================================================
   TASK 4
   Rank Agents by Average Resolution Time
   Fastest = Rank 1
   ========================================================= */

WITH Agent_Average AS
(
    SELECT

        `Service_Agent ID`,

        AVG(

            TIMESTAMPDIFF(
                MINUTE,
                Sent_Time,
                Resolution_Time
            ) / 60.0

        ) AS Avg_Resolution_Hrs

    FROM case_data

    GROUP BY `Service_Agent ID`
)

SELECT

    `Service_Agent ID`,

    ROUND(
        Avg_Resolution_Hrs,
        2
    ) AS Avg_Resolution_Hrs,

    RANK() OVER
    (
        ORDER BY Avg_Resolution_Hrs ASC
    ) AS Speed_Rank

FROM Agent_Average

ORDER BY Speed_Rank;


/* =========================================================
   TASK 5
   SLA Compliance Percentage per Priority
   Worst Compliance = Risk Rank 1
   ========================================================= */

WITH Priority_Data AS
(
    SELECT

        Case_Priority,

        100.0 *

        SUM(

            CASE

                WHEN

                    TIMESTAMPDIFF(
                        MINUTE,
                        Sent_Time,
                        Resolution_Time
                    ) / 60.0

                    <=

                    CASE

                        WHEN Case_Priority = '3_High'
                            THEN 4

                        WHEN Case_Priority = '2_Medium'
                            THEN 8

                        WHEN Case_Priority = '1_Low'
                            THEN 24

                        WHEN Case_Priority = '0_Unassigned'
                            THEN 72

                    END

                THEN 1

                ELSE 0

            END

        ) / COUNT(*) AS SLA_Compliance_Pct

    FROM case_data

    GROUP BY Case_Priority
)

SELECT

    Case_Priority,

    ROUND(
        SLA_Compliance_Pct,
        2
    ) AS SLA_Compliance_Pct,

    RANK() OVER
    (
        ORDER BY SLA_Compliance_Pct ASC
    ) AS Risk_Rank

FROM Priority_Data

ORDER BY Risk_Rank;


/* =========================================================
   TASK 6
   Month-over-Month Change in Average Resolution Time
   ========================================================= */

WITH Monthly_Data AS
(
    SELECT

        YEAR(Sent_Time) AS Year,

        MONTH(Sent_Time) AS Month,

        AVG(

            TIMESTAMPDIFF(
                MINUTE,
                Sent_Time,
                Resolution_Time
            ) / 60.0

        ) AS Avg_Resolution_Hrs

    FROM case_data

    GROUP BY

        YEAR(Sent_Time),
        MONTH(Sent_Time)
),

Monthly_With_Previous AS
(
    SELECT

        Year,
        Month,
        Avg_Resolution_Hrs,

        LAG(
            Avg_Resolution_Hrs
        ) OVER
        (
            ORDER BY Year, Month
        ) AS Prev_Month_Avg

    FROM Monthly_Data
)

SELECT

    Year,

    Month,

    ROUND(
        Avg_Resolution_Hrs,
        2
    ) AS Avg_Resolution_Hrs,

    ROUND(
        Prev_Month_Avg,
        2
    ) AS Prev_Month_Avg,

    ROUND(

        Avg_Resolution_Hrs -
        Prev_Month_Avg,

        2

    ) AS MoM_Change

FROM Monthly_With_Previous

ORDER BY Year, Month;


/* =========================================================
   TASK 7
   Case Type with Worst SLA Compliance Each Month
   ========================================================= */

WITH Monthly_Type AS
(
    SELECT

        YEAR(Sent_Time) AS Year,

        MONTH(Sent_Time) AS Month,

        Case_Type,

        100.0 *

        SUM(

            CASE

                WHEN

                    TIMESTAMPDIFF(
                        MINUTE,
                        Sent_Time,
                        Resolution_Time
                    ) / 60.0

                    <=

                    CASE

                        WHEN Case_Priority = '3_High'
                            THEN 4

                        WHEN Case_Priority = '2_Medium'
                            THEN 8

                        WHEN Case_Priority = '1_Low'
                            THEN 24

                        WHEN Case_Priority = '0_Unassigned'
                            THEN 72

                    END

                THEN 1

                ELSE 0

            END

        ) / COUNT(*) AS SLA_Compliance_Pct

    FROM case_data

    GROUP BY

        YEAR(Sent_Time),
        MONTH(Sent_Time),
        Case_Type
),

Ranked_Data AS
(
    SELECT

        Year,
        Month,
        Case_Type,
        SLA_Compliance_Pct,

        RANK() OVER
        (

            PARTITION BY Year, Month

            ORDER BY SLA_Compliance_Pct ASC

        ) AS Monthly_Rank

    FROM Monthly_Type
)

SELECT

    Year,
    Month,
    Case_Type,

    ROUND(
        SLA_Compliance_Pct,
        2
    ) AS SLA_Compliance_Pct,

    Monthly_Rank

FROM Ranked_Data

WHERE Monthly_Rank = 1

ORDER BY Year, Month;


/* =========================================================
   TASK 8
   Running Total of Cases Resolved Each Month
   ========================================================= */

WITH Monthly_Data AS
(
    SELECT

        YEAR(Resolution_Time) AS Year,

        MONTH(Resolution_Time) AS Month,

        COUNT(*) AS Monthly_Resolved_Cases

    FROM case_data

    WHERE Resolution_Time IS NOT NULL

    GROUP BY

        YEAR(Resolution_Time),
        MONTH(Resolution_Time)
)

SELECT

    Year,

    Month,

    Monthly_Resolved_Cases,

    SUM(
        Monthly_Resolved_Cases
    ) OVER
    (
        ORDER BY Year, Month
    ) AS Running_Total

FROM Monthly_Data

ORDER BY Year, Month;


/* =========================================================
   TASK 9
   Top 5 Agents by Volume Per Week
   ========================================================= */

WITH Agent_Total AS
(
    SELECT

        `Service_Agent ID`,

        COUNT(*) AS Total_Cases

    FROM case_data

    GROUP BY `Service_Agent ID`

    ORDER BY Total_Cases DESC

    LIMIT 5
),

Weekly_Data AS
(
    SELECT

        c.`Service_Agent ID`,

        YEARWEEK(
            c.Sent_Time,
            1
        ) AS Week_Number,

        COUNT(*) AS Cases_Handled

    FROM case_data c

    INNER JOIN Agent_Total a

        ON c.`Service_Agent ID`
        = a.`Service_Agent ID`

    GROUP BY

        c.`Service_Agent ID`,

        YEARWEEK(
            c.Sent_Time,
            1
        )
)

SELECT

    `Service_Agent ID`,

    Week_Number,

    Cases_Handled

FROM Weekly_Data

ORDER BY

    Week_Number,

    Cases_Handled DESC;


/* =========================================================
   TASK 10
   Impact of Case Severity on Resolution Time and SLA
   ========================================================= */

SELECT

    Case_Severity,

    ROUND(

        AVG(

            TIMESTAMPDIFF(
                MINUTE,
                Sent_Time,
                Resolution_Time
            ) / 60.0

        ),

        2

    ) AS Avg_Resolution_Hrs,


    ROUND(

        100.0 *

        SUM(

            CASE

                WHEN

                    TIMESTAMPDIFF(
                        MINUTE,
                        Sent_Time,
                        Resolution_Time
                    ) / 60.0

                    <=

                    CASE

                        WHEN Case_Priority = '3_High'
                            THEN 4

                        WHEN Case_Priority = '2_Medium'
                            THEN 8

                        WHEN Case_Priority = '1_Low'
                            THEN 24

                        WHEN Case_Priority = '0_Unassigned'
                            THEN 72

                    END

                THEN 1

                ELSE 0

            END

        ) / COUNT(*),

        2

    ) AS SLA_Compliance_Pct

FROM case_data

GROUP BY Case_Severity

ORDER BY Case_Severity DESC;