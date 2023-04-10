WITH v AS
  /* DAC ETL Execution Plan Heuristics Execution Detail.sql */
  (SELECT def.name AS JOB_NAME ,
    STP.depth,
    STP.STEP_NAME,
    sdef.row_wid AS step_wid,
    sdtl.seq_num,
    SDTL.name AS subtask_name,
    SDTL.TYPE_CD,
    SDTL.status_cd,
    SDTL.sucess_rows,
    tbl.name     AS table_name,
    ptbl.type_cd AS table_type
  FROM W_ETL_DEFN_RUN DEF
  JOIN W_ETL_RUN_STEP STP
  ON DEF.ROW_WID =STP.RUN_WID
  JOIN W_ETL_RUN_SDTL SDTL
  ON SDTL.RUN_STEP_WID = STP.ROW_WID
  JOIN w_etl_obj_ref r
  ON stp.step_wid = r.obj_wid
  AND r.app_wid   ='5'
  JOIN w_etl_step sdef
  ON r.obj_ref_wid = sdef.ROW_WID
  LEFT OUTER JOIN W_ETL_STEP_TBL ptbl
  ON ptbl.step_wid = r.obj_ref_wid
    AND ptbl.sub_type_cd ='Primary'
  LEFT OUTER JOIN w_etl_table tbl
  ON ptbl.table_wid = tbl.row_wid
  AND SDTL.TYPE_CD    ='Informatica'
  WHERE def.name    ='ARQIVA All Modules Load: ETL Run - 2013-06-10 18:00:00.018'
    /* to replace by the execution plan name to be queried;
    run to get the latest runs: SELECT * FROM W_ETL_DEFN_RUN ORDER BY last_upd DESC
    */

  )
SELECT v.JOB_NAME ,
  v.DEPTH ,
  v.STEP_NAME ,
  v.SEQ_NUM ,
  v.SUBTASK_NAME ,
  v.TYPE_CD ,
  v.STATUS_CD ,
  v.SUCESS_ROWS  AS success_rows ,
  v.TABLE_NAME   AS SOURCE_TABLE ,
  vs.STEP_NAME   AS source_step ,
  vs.sucess_rows AS source_success_rows ,
  h.value        AS heuristic
FROM v
LEFT OUTER JOIN v vs
ON v.table_name  = vs.table_name
AND vs.table_type='Source'
AND vs.TYPE_CD   ='Informatica'
AND v.TYPE_CD    ='Informatica'
JOIN w_etl_step_prop h
ON h.step_wid      =v.step_wid
AND h.name         ='Heuristics'
WHERE v.table_type ='Source'
ORDER BY v.depth,
  v.step_name,
  v.seq_num ;