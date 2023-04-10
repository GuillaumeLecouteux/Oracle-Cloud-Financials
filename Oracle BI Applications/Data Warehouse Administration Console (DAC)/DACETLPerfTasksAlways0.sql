--
-- Informatica tasks that always return 0 rows
--
WITH V2 AS (
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
--AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
--AND w_etl_defn_run.status_desc    ='Finished'
--AND W_ETL_DEFN_RUN.ROW_WID NOT IN (SELECT RUN_WID FROM V)
--and row_wid='2FB1A4ACD4E74304D3B1ECF62F8572F'
ORDER BY W_ETL_DEFN_RUN.START_TS DESC
)
SELECT SDTL.name
, SUM(SDTL.sucess_rows)
, SUM(SDTL.failed_rows)
, COUNT(1)
, round(max(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS MAX_MINUTES
, round(avg(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS AVG_MINUTES
, round(min(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS MIN_MINUTES
FROM W_ETL_DEFN_RUN DEF ,
  W_ETL_RUN_STEP STP ,
  W_ETL_RUN_SDTL SDTL ,
  V2
WHERE DEF.ROW_WID     =STP.RUN_WID
AND SDTL.RUN_STEP_WID = STP.ROW_WID
AND SDTL.TYPE_CD      = 'Informatica'
AND def.row_wid       =V2.RUN_WID /*Unique ETL ID from the first query*/
GROUP BY SDTL.name
HAVING  SUM(SDTL.sucess_rows) = 0
AND SUM(SDTL.failed_rows) = 0
ORDER BY 1
 ;