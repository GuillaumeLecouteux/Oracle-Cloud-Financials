select ldg.name as ledger_name,
ldg.period_set_name as period_set_name,
glbal.currency_code as currency_code,
ldg.currency_code as ledger_currency_code,
glbal.code_combination_id as code_combination_id,
gcc.segment1 as segment1_code,
gcc.segment2 as segment2_code,
gcc.segment3 as segment3_code,
gcc.segment4 as segment4_code,
gcc.segment5 as segment5_code,
gcc.segment6 as segment6_code,
substr(gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,1,gcc.segment1),1,250) as segment1_desc,
substr(gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,2,gcc.segment2),1,250) as segment2_desc,
substr(gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,3,gcc.segment3),1,250) as segment3_desc,
substr(gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,4,gcc.segment4),1,250) as segment4_desc,
substr(gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,5,gcc.segment5),1,250) as segment5_desc,
substr(gl_flexfields_pkg.get_description_sql( gcc.chart_of_accounts_id,6,gcc.segment6),1,250) as segment6_desc,
case when glbal.currency_code=ldg.currency_code and glbal.translated_flag is null
then nvl(glbal.begin_balance_dr_beq, 0) - nvl(glbal.begin_balance_cr_beq,0)
else nvl(glbal.begin_balance_dr,0) - nvl(glbal.begin_balance_cr,0) 
end as opening_entered_balance,
(nvl(case when glbal.currency_code=ldg.currency_code and glbal.translated_flag is null
then nvl(glbal.period_net_dr_beq, 0) - nvl(glbal.period_net_cr_beq,0)
else nvl(glbal.period_net_dr,0)      - nvl(glbal.period_net_cr,0) 
end,0)) as entered_period_net,
case when glbal.currency_code=ldg.currency_code and glbal.translated_flag is null
then nvl(glbal.begin_balance_dr_beq,0)  - nvl(glbal.begin_balance_cr_beq,0) + nvl( glbal.period_net_dr_beq,0) - nvl(glbal.period_net_cr_beq,0)
else nvl(glbal.begin_balance_dr,0) - nvl(glbal.begin_balance_cr, 0) + nvl(glbal.period_net_dr,0) - nvl(glbal.period_net_cr,0)
end as closing_entered_balance,
(nvl(glbal.begin_balance_dr_beq, 0) - nvl(glbal.begin_balance_cr_beq,0)) as opening_accounted_balance,
(nvl(glbal.period_net_dr_beq, 0) - nvl(glbal.period_net_cr_beq,0)) as accounted_period_net,
(nvl(glbal.begin_balance_dr_beq,0)  - nvl(glbal.begin_balance_cr_beq,0) + nvl( glbal.period_net_dr_beq,0) - nvl(glbal.period_net_cr_beq,0)) as closing_accounted_balance,
glbal.period_name as period_name,
glbal.translated_flag as translated_balance_status,
glbal.last_update_date as last_update_date
from gl_balances glbal
join gl_ledgers ldg
on ldg.ledger_id = glbal.ledger_id
join gl_code_combinations gcc
on gcc.code_combination_id = glbal.code_combination_id
join gl_periods gp
on ldg.period_set_name              = gp.period_set_name
and glbal.period_name               = gp.period_name
where glbal.actual_flag = 'A'
and (glbal.period_name in (:p_period_name))
and (ldg.name in nvl(:p_ledger, ldg.name))
