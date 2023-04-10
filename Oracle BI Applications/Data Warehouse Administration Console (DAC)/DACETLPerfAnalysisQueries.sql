--
-- Identify the most recent sucessful FULL ETL for execution plan ARQIVA All Modules Load
--
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT   IN
  ( SELECT DISTINCT W_ETL_RUN_STEP.RUN_WID
  FROM W_ETL_DEFN_RUN RUN2
  JOIN W_ETL_RUN_STEP
  ON W_ETL_RUN_STEP.RUN_WID  =RUN2.ROW_WID
  WHERE RUN2.ETL_DEFN_NAME   ='ARQIVA All Modules Load'
  AND RUN2.status_desc       ='Finished'
  AND W_ETL_RUN_STEP.run_mode='Source : INCREMENTAL Target : INCREMENTAL'
  )
ORDER BY W_ETL_DEFN_RUN.START_TS DESC;

--
-- Identify the most recent successful Incremental ETL for execution plan ARQIVA All Modules Load
--
WITH V AS (
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT   IN
  ( SELECT DISTINCT W_ETL_RUN_STEP.RUN_WID
  FROM W_ETL_DEFN_RUN RUN2
  JOIN W_ETL_RUN_STEP
  ON W_ETL_RUN_STEP.RUN_WID  =RUN2.ROW_WID
  WHERE RUN2.ETL_DEFN_NAME   ='ARQIVA All Modules Load'
  AND RUN2.status_desc       ='Finished'
  AND W_ETL_RUN_STEP.run_mode='Source : INCREMENTAL Target : INCREMENTAL'
  )
)
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT IN (SELECT RUN_WID FROM V)
ORDER BY W_ETL_DEFN_RUN.START_TS DESC
;

--
-- Identify your App Wid
--
SELECT DISTINCT app.row_wid,
  app.name
FROM w_etl_defn_run run ,
  w_etl_app app ,
  w_etl_defn_prm prm
WHERE prm.etl_defn_wid = run.etl_defn_wid
AND prm.app_wid        = app.row_wid
AND run.row_wid        = '73FE54458D60F226D35DC2EC4D553646' /*Unique ETL ID from the first query*/
;
--
-- Top Indexes build time for the selected ETL run
--
SELECT --ref_idx.tbl_name table_name ,
 -- ref_idx.idx_name ,
 DEF.NAME RUN_NAME,
 sdtl.name as step_name,
  sdtl.start_ts start_time ,
  sdtl.end_ts end_time ,
  EXTRACT(DAY FROM(sdtl.end_ts - sdtl.start_ts) DAY TO SECOND)
  || ' days '
  || EXTRACT(HOUR FROM(sdtl.end_ts - sdtl.start_ts) DAY TO SECOND)
  || ' hrs '
  || EXTRACT(MINUTE FROM(sdtl.end_ts - sdtl.start_ts) DAY TO SECOND)
  || ' min '
  || EXTRACT(SECOND FROM(sdtl.end_ts - sdtl.start_ts) DAY TO SECOND)
  || ' sec' idx_bld_time
FROM w_etl_defn_run def ,
  w_etl_run_step stp ,
  w_etl_run_sdtl sdtl 
  /*,
  (SELECT ind_ref.obj_wid ,
    ind.name idx_name ,
    tbl.name tbl_name
  FROM w_etl_index ind ,
    w_etl_obj_ref ind_ref ,
    w_etl_obj_ref tbl_ref ,
    w_etl_table tbl ,
    w_etl_app app
  WHERE ind_ref.obj_type   = 'W_ETL_INDEX'
  AND ind_ref.soft_del_flg = 'N'
  AND ind_ref.app_wid      = '5' --Your custom Execution Plan Name FROM the second query
  AND ind_ref.obj_wid      = ind.row_wid
  AND tbl_ref.obj_type     = 'W_ETL_TABLE'
  AND tbl_ref.soft_del_flg = 'N'
  AND tbl_ref.app_wid      = '5' --Your custom Execution Plan Name FROM the second query
  AND tbl_ref.obj_wid      = tbl.row_wid
  AND tbl_ref.obj_ref_wid  = ind.table_wid
  AND ind.app_wid          = app.row_wid
  AND ind.inactive_flg     = 'N'
  ) ref_idx */
WHERE def.row_wid     = stp.run_wid
AND def.row_wid       ='73FE54458D60F226D35DC2EC4D553646' /*Unique ETL ID from the first query*/
AND sdtl.run_step_wid = stp.row_wid
AND sdtl.type_cd      = 'Create Index'
--AND sdtl.index_wid    = ref_idx.obj_wid
ORDER BY sdtl.end_ts - sdtl.start_ts DESC ;
--
-- Top Table Stats computing time for the selected ETL run
--
SELECT DEF.NAME RUN_NAME,
  STP.STEP_NAME ,
  SDTL.name as table_name,
  SDTL.END_TS,SDTL.START_TS,
  EXTRACT(DAY FROM (SDTL.END_TS - SDTL.START_TS) DAY TO SECOND )
  ||' days '
  || EXTRACT(HOUR FROM (SDTL.END_TS - SDTL.START_TS) DAY TO SECOND )
  ||' hrs '
  || EXTRACT(MINUTE FROM (SDTL.END_TS - SDTL.START_TS) DAY TO SECOND )
  ||' min '
  || EXTRACT(SECOND FROM (SDTL.END_TS - SDTL.START_TS) DAY TO SECOND )
  ||' sec' TBL_STATS_TIME
FROM W_ETL_DEFN_RUN DEF ,
  W_ETL_RUN_STEP STP ,
  W_ETL_RUN_SDTL SDTL 
 -- ,  W_ETL_TABLE TBL
WHERE DEF.ROW_WID     =STP.RUN_WID
AND DEF.ROW_WID       ='73FE54458D60F226D35DC2EC4D553646' /*Unique ETL ID from the first query*/
AND SDTL.RUN_STEP_WID = STP.ROW_WID
AND SDTL.TYPE_CD      = 'Analyze Table'
--AND SDTL.TABLE_WID    = TBL.ROW_WID
ORDER BY SDTL.END_TS - SDTL.START_TS DESC;
--
-- Top Informatica jobs for the selected ETL run
--
SELECT SDTL.NAME SESSION_NAME ,
  SDTL.SUCESS_ROWS ,
  STP.FAILED_ROWS ,
  SDTL.READ_THRUPUT ,
  SDTL.WRITE_THRUPUT ,
  EXTRACT(DAY FROM (SDTL.END_TS - SDTL.START_TS) DAY TO SECOND )
  ||' days '
  || EXTRACT(HOUR FROM (SDTL.END_TS - SDTL.START_TS) DAY TO SECOND )
  ||' hrs '
  || EXTRACT(MINUTE FROM (SDTL.END_TS - SDTL.START_TS) DAY TO SECOND )
  ||' min '
  || EXTRACT(SECOND FROM (SDTL.END_TS - SDTL.START_TS) DAY TO SECOND )
  ||' sec' INFA_RUN_TIME
FROM W_ETL_DEFN_RUN DEF ,
  W_ETL_RUN_STEP STP ,
  W_ETL_RUN_SDTL SDTL
WHERE DEF.ROW_WID=STP.RUN_WID
and DEF.ROW_WID ='73FE54458D60F226D35DC2EC4D553646' /*Unique ETL ID from the first query*/
AND SDTL.RUN_STEP_WID = STP.ROW_WID
AND SDTL.TYPE_CD      = 'Informatica'
ORDER BY SDTL.END_TS - SDTL.START_TS DESC;



--
-- Top Indexes build time for all successful incremental ETL
--
WITH V AS (
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT   IN
  ( SELECT DISTINCT W_ETL_RUN_STEP.RUN_WID
  FROM W_ETL_DEFN_RUN RUN2
  JOIN W_ETL_RUN_STEP
  ON W_ETL_RUN_STEP.RUN_WID  =RUN2.ROW_WID
  WHERE RUN2.ETL_DEFN_NAME   ='ARQIVA All Modules Load'
  AND RUN2.status_desc       ='Finished'
  AND W_ETL_RUN_STEP.run_mode='Source : INCREMENTAL Target : INCREMENTAL'
  )
)
, V2 AS (
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT IN (SELECT RUN_WID FROM V)
ORDER BY W_ETL_DEFN_RUN.START_TS DESC
)
SELECT --ref_idx.tbl_name table_name ,
 -- ref_idx.idx_name ,
  sdtl.name as step_name,
  round(max(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS MAX_MINUTES,
  round(avg(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS AVG_MINUTES,
  round(min(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS MIN_MINUTES
FROM w_etl_defn_run def ,
  w_etl_run_step stp ,
  w_etl_run_sdtl sdtl,
  V2
WHERE def.row_wid     = stp.run_wid
AND def.row_wid       =V2.RUN_WID /*Unique ETL ID from the first query*/
AND sdtl.run_step_wid = stp.row_wid
AND sdtl.type_cd      = 'Create Index'
GROUP BY  sdtl.name
ORDER BY AVG_MINUTES DESC ;


--
-- Top Table Stats computing time for all successful incremental ETL
--
WITH V AS (
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT   IN
  ( SELECT DISTINCT W_ETL_RUN_STEP.RUN_WID
  FROM W_ETL_DEFN_RUN RUN2
  JOIN W_ETL_RUN_STEP
  ON W_ETL_RUN_STEP.RUN_WID  =RUN2.ROW_WID
  WHERE RUN2.ETL_DEFN_NAME   ='ARQIVA All Modules Load'
  AND RUN2.status_desc       ='Finished'
  AND W_ETL_RUN_STEP.run_mode='Source : INCREMENTAL Target : INCREMENTAL'
  )
)
, V2 AS (
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT IN (SELECT RUN_WID FROM V)
ORDER BY W_ETL_DEFN_RUN.START_TS DESC
)
SELECT SDTL.name as table_name,
  round(max(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS MAX_MINUTES,
  round(avg(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS AVG_MINUTES,
  round(min(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS MIN_MINUTES
FROM W_ETL_DEFN_RUN DEF ,
  W_ETL_RUN_STEP STP ,
  W_ETL_RUN_SDTL SDTL ,
  V2
WHERE DEF.ROW_WID     =STP.RUN_WID
AND SDTL.RUN_STEP_WID = STP.ROW_WID
AND SDTL.TYPE_CD      = 'Analyze Table'
AND def.row_wid       =V2.RUN_WID /*Unique ETL ID from the first query*/
GROUP BY  sdtl.name
ORDER BY AVG_MINUTES DESC ;


--
-- Top Informatica jobs for all successful incremental ETL
--
WITH V AS (
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT   IN
  ( SELECT DISTINCT W_ETL_RUN_STEP.RUN_WID
  FROM W_ETL_DEFN_RUN RUN2
  JOIN W_ETL_RUN_STEP
  ON W_ETL_RUN_STEP.RUN_WID  =RUN2.ROW_WID
  WHERE RUN2.ETL_DEFN_NAME   ='ARQIVA All Modules Load'
  AND RUN2.status_desc       ='Finished'
  AND W_ETL_RUN_STEP.run_mode='Source : INCREMENTAL Target : INCREMENTAL'
  )
)
, V2 AS (
SELECT
  W_ETL_DEFN_RUN.START_TS,
  W_ETL_DEFN_RUN.ROW_WID AS RUN_WID,
  W_ETL_DEFN_RUN.NAME
FROM W_ETL_DEFN_RUN
WHERE W_ETL_DEFN_RUN.ETL_DEFN_NAME='ARQIVA All Modules Load'
AND w_etl_defn_run.total_steps    =w_etl_defn_run.succ_steps
AND w_etl_defn_run.status_desc    ='Finished'
AND W_ETL_DEFN_RUN.ROW_WID NOT IN (SELECT RUN_WID FROM V)
ORDER BY W_ETL_DEFN_RUN.START_TS DESC
)
SELECT SDTL.name as task_name,
  round(max(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS MAX_MINUTES,
  round(avg(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS AVG_MINUTES,
  round(min(sdtl.end_ts - sdtl.start_ts)*24*60,2) AS MIN_MINUTES
FROM W_ETL_DEFN_RUN DEF ,
  W_ETL_RUN_STEP STP ,
  W_ETL_RUN_SDTL SDTL ,
  V2
WHERE DEF.ROW_WID     =STP.RUN_WID
AND SDTL.RUN_STEP_WID = STP.ROW_WID
AND SDTL.TYPE_CD      = 'Informatica'
AND def.row_wid       =V2.RUN_WID /*Unique ETL ID from the first query*/
GROUP BY  sdtl.name
ORDER BY AVG_MINUTES DESC ;