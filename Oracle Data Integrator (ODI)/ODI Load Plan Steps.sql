SELECT lp.LOAD_PLAN_NAME
  , lpstp.i_load_plan
  , lpstp.lp_step_name
  , lpstp.scen_name
  , lpstp.scen_version
  , lpstp.step_order
  , lpstp.lp_step_type
  , lpstp.ind_enabled
  , lpstp.i_lp_step
  , lpstp.par_i_lp_step
  , level as STEP_LEVEL
  ,SYS_CONNECT_BY_PATH(lp_step_name, '/') STEP_PATH
FROM
    PRDODI_ODI_REPO.snp_lp_step lpstp
join PRDODI_ODI_REPO.snp_load_plan lp
  on lpstp.i_load_plan=lp.i_load_plan
START WITH
    par_i_lp_step IS NULL
CONNECT BY
    PRIOR i_lp_step = par_i_lp_step
ORDER SIBLINGS BY
    step_order;
ORDER BY lp.LOAD_PLAN_NAME;
