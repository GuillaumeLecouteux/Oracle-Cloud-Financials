SELECT * FROM W_ETL_DEFN_RUN ORDER BY last_upd DESC ;
SELECT def.name                                                                     AS JOB_NAME ,
  TO_CHAR(to_date(ROUND((def.end_ts - def.start_ts)*24*3600),'sssss'),'hh24:mi:ss') AS JOB_DURATION ,
  STP.depth                                                                         AS STEP_depth,
  STP.STEP_NAME                                                                     AS STEP_NAME,
  sdtl.seq_num                                                                      AS SUBTASK_SEQ,
  SDTL.name                                                                         AS subtask_name,
  SDTL.TYPE_CD,
  SDTL.status_cd,
  SDTL.sucess_rows,
  sdtl.failed_rows,
  sdtl.read_thruput,
  sdtl.write_thruput,
  sdtl.num_retries
FROM W_ETL_DEFN_RUN DEF ,
  W_ETL_RUN_STEP STP ,
  W_ETL_RUN_SDTL SDTL
WHERE DEF.ROW_WID     =STP.RUN_WID
AND SDTL.RUN_STEP_WID = STP.ROW_WID
AND def.name          =:JOB_NAME
  /* e.g ARQIVA All Modules Load: ETL Run - 2013-06-07 14:00:00.024 */
ORDER BY STP.depth,
  stp.step_name,
  sdtl.seq_num ;