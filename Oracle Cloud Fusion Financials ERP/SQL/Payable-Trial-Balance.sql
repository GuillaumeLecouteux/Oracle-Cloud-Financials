WITH get_schedule_count
     AS (SELECT Count(1) Schedule_Count,
                invoice_id
         FROM   ap_payment_schedules_all
         GROUP  BY invoice_id),
     get_invoice_due_date
     AS (SELECT Max(due_date) AS DUE_DATE,
                invoice_id
         FROM   ap_payment_schedules_all
         GROUP  BY invoice_id),
     ap_tb
     AS (SELECT To_date(:as_of_date, 'DD-MM-YYYY')
                as_of_date,
                xtb.invoice_id
                invoice_id,
                xtb.trx_currency_code,
                l.name                                                   AS
                ledger_name,
                l.currency_code                                          AS
                   LEDGER_CURR_CODE,
                SUM(Nvl(xtb.entered_cr, 0) - Nvl(xtb.entered_dr, 0))
                trx_amount_due,
                SUM(Nvl(xtb.accounted_cr, 0) - Nvl(xtb.accounted_dr, 0))
                amount_due
         FROM   ap_trial_balances xtb,-- xla_trial_balances xtb,
                ap_invoices_all apa,
                gl_ledgers l
         WHERE  xtb.ledger_id = l.ledger_id
                AND xtb.accounting_date <= To_date(:as_of_date, 'DD-MM-YYYY')
                AND apa.invoice_id = xtb.invoice_id
         GROUP  BY xtb.invoice_id,
                   xtb.trx_currency_code,
                   l.name,
                   l.currency_code
         HAVING SUM(Nvl(xtb.accounted_cr, 0) - Nvl(xtb.accounted_dr, 0)) <> 0),
     ap_inv
     AS (SELECT hou.name
                organisation,
                Nvl(v.vendor_name, party_name)                           AS
                vendor_name,
                v.segment1
                vendor_number,
                I.invoice_id,
                i.invoice_num,
                i.invoice_date,
                i.description,
                i.payment_status_flag,
                gsc.schedule_count
                SCH_PAY_COUNT,
                gidd.due_date                                            AS
                DUE_DATE,
                Ceil(To_date(:as_of_date, 'dd-mm-yyyy') - gidd.due_date)
                DAYS_DUE,
                invoice_amount,
                base_amount,
                total_tax_amount,
                invoice_amount - total_tax_amount                        AS
                   INVOICE_NET_AMOUNT,
                exchange_rate
                   ,
                (SELECT PayablesLookup.displayed_field
                 FROM   ap_lookup_codes PayablesLookup
                 WHERE  PayablesLookup.lookup_type = 'INVOICE TYPE'
                        AND I.invoice_type_lookup_code =
                            PayablesLookup.lookup_code(+))
                                            INVOICE_TYPE
         FROM   ap_invoices_all i,
                poz_suppliers_v v,-- ap_suppliers v,
                hr_all_organization_units_tl hou,
                hz_parties HP,
                get_schedule_count gsc,
                get_invoice_due_date gidd
         WHERE  i.vendor_id = v.vendor_id (+)
                AND i.party_id = hp.party_id (+)
                AND hou.organization_id = i.org_id
                AND gsc.invoice_id (+) = i.invoice_id
                AND gidd.invoice_id (+) = i.invoice_id),
     year_end_rate
     AS (SELECT r.from_currency,
                r.to_currency,
                r.conversion_rate
         FROM   gl_daily_rates r
                join gl_periods p
                  ON p.end_date = r.conversion_date
         WHERE  conversion_type = :conversion_type
                AND p.period_set_name = :period_set_name
                AND p.entered_period_name = '12'
                AND To_date(:as_of_date, 'DD-MM-YYYY') BETWEEN
                    p.year_start_date AND p.end_date)
SELECT To_char(ap_tb.as_of_date, 'DD-MM-YYYY') As_Of_Date,
       ap_inv.vendor_name,
       ap_inv.vendor_number,
       ap_inv.invoice_num,
       ap_inv.invoice_type,
       Replace(Replace(To_char(ap_inv.description), Chr(13), ' '), Chr(10), ' ')
                                               description,
       ap_inv.organisation,
       To_char(ap_inv.due_date, 'DD-MM-YYYY')  due_date,
       ap_inv.sch_pay_count,
       ap_inv.days_due,
       trx_currency_code                       AS trx_currency,
       invoice_amount,
       total_tax_amount,
       exchange_rate,
       invoice_amount * exchange_rate,
       trx_amount_due,
       CASE
         WHEN ap_tb.trx_currency_code = ap_tb.ledger_curr_code THEN 1
         ELSE year_end_rate.conversion_rate
       END                                     AS year_end_rate,
       ap_tb.ledger_curr_code                  AS functional_currency,
       ap_tb.amount_due,
       Round(ap_tb.amount_due * CASE
                                  WHEN invoice_amount = 0 THEN 0
                                  ELSE invoice_net_amount / invoice_amount
                                END, 2)        AS net_amount_due,
       Round(ap_tb.amount_due * CASE
                                  WHEN invoice_amount = 0 THEN 0
                                  ELSE total_tax_amount / invoice_amount
                                END, 2)        AS tax_amount_due,
       CASE
         WHEN To_date(ap_inv.due_date) > To_date(as_of_date)
               OR ap_inv.sch_pay_count > 1 THEN Round(ap_tb.amount_due, 2)
         ELSE NULL
       END                                     CURRENT_BUCKET,
       CASE
         WHEN To_date(ap_inv.due_date) > To_date(as_of_date)
               OR ap_inv.sch_pay_count > 1 THEN Round(
         ap_tb.amount_due * CASE
                              WHEN invoice_amount = 0 THEN 0
                              ELSE invoice_net_amount / invoice_amount
                            END, 2)
         ELSE NULL
       END                                     CURRENT_BUCKET_NET,
       CASE
         WHEN To_date(ap_inv.due_date) > To_date(as_of_date)
               OR ap_inv.sch_pay_count > 1 THEN Round(
         ap_tb.amount_due * CASE
                              WHEN invoice_amount = 0 THEN 0
                              ELSE total_tax_amount / invoice_amount
                            END, 2)
         ELSE NULL
       END                                     CURRENT_BUCKET_TAX,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) >= 0
              AND ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) <= 30
              AND ap_inv.sch_pay_count = 1 THEN Round(ap_tb.amount_due, 2)
         ELSE NULL
       END                                     DAYS30_BUCKET,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) >= 0
              AND ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) <= 30
              AND ap_inv.sch_pay_count = 1 THEN Round(
         ap_tb.amount_due * CASE
                              WHEN invoice_amount = 0 THEN 0
                              ELSE invoice_net_amount / invoice_amount
                            END, 2)
         ELSE NULL
       END                                     DAYS30_BUCKET_NET,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) >= 0
              AND ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) <= 30
              AND ap_inv.sch_pay_count = 1 THEN Round(
         ap_tb.amount_due * CASE
                              WHEN invoice_amount = 0 THEN 0
                              ELSE total_tax_amount / invoice_amount
                            END, 2)
         ELSE NULL
       END                                     DAYS30_BUCKET_TAX,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) > 30
              AND ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) <= 60
              AND ap_inv.sch_pay_count = 1 THEN Round(ap_tb.amount_due, 2)
         ELSE NULL
       END                                     DAYS60_BUCKET,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) > 30
              AND ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) <= 60
              AND ap_inv.sch_pay_count = 1 THEN Round(
         ap_tb.amount_due * CASE
                              WHEN invoice_amount = 0 THEN 0
                              ELSE invoice_net_amount / invoice_amount
                            END, 2)
         ELSE NULL
       END                                     DAYS60_BUCKET_NET,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) > 30
              AND ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) <= 60
              AND ap_inv.sch_pay_count = 1 THEN Round(
         ap_tb.amount_due * CASE
                              WHEN invoice_amount = 0 THEN 0
                              ELSE total_tax_amount / invoice_amount
                            END, 2)
         ELSE NULL
       END                                     DAYS60_BUCKET_TAX,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) > 60
              AND ap_inv.sch_pay_count = 1 THEN Round (ap_tb.amount_due, 2)
         ELSE NULL
       END                                     DAYS61_PLUS_BUCKET,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) > 60
              AND ap_inv.sch_pay_count = 1 THEN Round(
         ap_tb.amount_due * CASE
                              WHEN invoice_amount = 0 THEN 0
                              ELSE invoice_net_amount / invoice_amount
                            END, 2)
         ELSE NULL
       END                                     DAYS61_PLUS_BUCKET_NET,
       CASE
         WHEN ( Ceil(To_date(as_of_date) - ap_inv.due_date) ) > 60
              AND ap_inv.sch_pay_count = 1 THEN Round(
         ap_tb.amount_due * CASE
                              WHEN invoice_amount = 0 THEN 0
                              ELSE total_tax_amount / invoice_amount
                            END, 2)
         ELSE NULL
       END                                     DAYS61_PLUS_BUCKET_TAX,
       ap_inv.invoice_id
FROM   ap_tb
       join ap_inv
         ON ap_tb.invoice_id = ap_inv.invoice_id
       left outer join year_end_rate
                    ON ap_tb.trx_currency_code = year_end_rate.from_currency
                       AND ap_tb.ledger_curr_code = year_end_rate.to_currency
WHERE  1 = 1
       AND ap_tb.as_of_date = To_date(:as_of_date, 'DD-MM-YYYY')
       AND ap_inv.organisation IN ( :organisation )
       
