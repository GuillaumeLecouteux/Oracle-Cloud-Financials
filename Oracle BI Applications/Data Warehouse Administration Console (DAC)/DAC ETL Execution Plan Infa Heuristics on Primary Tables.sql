--SELECT * FROM W_ETL_DEFN_RUN ORDER BY last_upd DESC ;

with v as (
SELECT def.name AS JOB_NAME ,
  STP.depth,
  STP.STEP_NAME,
  sdef.row_wid as step_wid,
  sdtl.seq_num,
  SDTL.name AS subtask_name,
  SDTL.TYPE_CD,
  SDTL.status_cd,
  SDTL.sucess_rows,
  tbl.name AS table_name,
  ptbl.type_cd as table_type
FROM W_ETL_DEFN_RUN DEF ,
  W_ETL_RUN_STEP STP ,
  W_ETL_RUN_SDTL SDTL ,
  w_etl_step sdef ,
  W_ETL_STEP_TBL ptbl ,
  w_etl_table tbl
WHERE DEF.ROW_WID     =STP.RUN_WID
AND SDTL.RUN_STEP_WID = STP.ROW_WID
AND SDTL.TYPE_CD      ='Informatica'
AND stp.step_wid      = sdef.row_wid
AND ptbl.step_wid     = sdef.ROW_WID
AND ptbl.table_wid    = tbl.row_wid
AND def.name          ='ARQIVA All Modules Load: ETL Run - 2013-06-07 14:00:00.024'
  /* e.g ARQIVA All Modules Load: ETL Run - 2013-06-07 14:00:00.024 */
AND ptbl.sub_type_cd='Primary'
)
SELECT v.JOB_NAME
,v.DEPTH
,v.STEP_NAME
,v.SEQ_NUM
,v.SUBTASK_NAME
,v.TYPE_CD
,v.STATUS_CD
,v.SUCESS_ROWS AS success_rows
,v.TABLE_NAME as SOURCE_TABLE
,vs.STEP_NAME as source_step
,vs.sucess_rows as source_success_rows
, h.value as heuristic
from v
join v vs
on v.table_name = vs.table_name
and vs.table_type='Source'
left outer join w_etl_step_prop h
on h.step_wid=v.step_wid
and h.name='Heuristics'
WHERE v.status_cd    = 'Not Executed'
AND v.table_type    ='Source'
ORDER BY v.depth,
  v.step_name,
  v.seq_num ; 
  
  
select *
from w_etl_heuristic;
minus 
select step_name from W_ETL_RUN_STEP;