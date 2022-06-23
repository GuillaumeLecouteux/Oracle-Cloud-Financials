SELECT slr.LOAD_PLAN_NAME AS LOAD_PLAN_NAME
, slr.i_lp_inst AS load_PLAN_INSTANCE
, slog.i_lp_inst
, slog.i_lp_step
, slog.nb_run as RUN_NUMBER
, slog.start_date as step_start_date
, slog.end_date as step_end_date
, case when slog.status in ('D','E') then round((slog.end_date-slog.start_date) * 3600 * 24,2) end as  step_duration_in_sec
, case when slog.status in ('D','E') then round((slog.end_date-slog.start_date) * 60 * 24,2) end as  step_duration_in_min
, DECODE(slog.status, 'D', 'Success', 'E', 'Error', 'Q', 'Queued', 'W', 'Waiting', 'M', 'Warning', 'R', 'Running','A','Done in Previous Run',slog.status) as step_status
, slog.return_code
, slog.i_txt_mess
, slog.sess_no
, slog.nb_row
, slog.nb_ins
, slog.nb_upd
, slog.nb_del
, slog.nb_err
, slog.error_message
, lpstp.lp_step_name
  , lpstp.scen_name
  , lpstp.scen_version
  , lpstp.step_order
  , lpstp.lp_step_type
  , lpstp.ind_enabled
  , lpstp.par_i_lp_step
FROM PRDODI_ODI_REPO.snp_lpi_step_log slog
JOIN PRDODI_ODI_REPO.snp_lpi_run slr
  ON slog.i_lp_inst = slr.i_lp_inst
  and slr.NB_RUN =slog.NB_RUN
JOIN PRDODI_ODI_REPO.snp_lp_step lpstp
  on lpstp.i_lp_step = slog.i_lp_step
ORDER BY SLR.START_DATE DESC, slog.start_date desc
;
