SELECT papf.full_name "Employee Name" , 
  papf.employee_number "Employee Number" , 
  papf.start_date "Employee Start Date" , 
  pps.actual_termination_date "Actual Termination Date" , 
  ppt.user_person_type "Employee Type" , 
  papf1.full_name "Supervisor Name" , 
  ( per_accrual_calc_functions.get_other_net_contribution( p_assignment_id =>paaf.assignment_id ,p_plan_id => 62 ,p_calculation_date => sysdate ,p_start_date => '01-JUL-2014' ,p_input_value_id => NULL) + ((per_utility_functions.get_Net_Accrual (P_Assignment_ID => paaf.assignment_id ,P_Payroll_ID => 61 ,P_Business_Group_ID => 81 ,P_Assignment_Action_ID => NULL ,P_Calculation_Date => sysdate ,P_Plan_ID => 62 ,P_Accrual_Start_Date => NULL ,P_Accrual_Latest_Balance => NULL)) - ( per_accrual_calc_functions.get_other_net_contribution( p_assignment_id =>paaf.assignment_id ,p_plan_id => 62 ,p_calculation_date => sysdate ,p_start_date => '01-JUL-2014' ,p_input_value_id => NULL) )) + 
  (SELECT NVL(SUM(peevf.screen_entry_value),0) 
  FROM PAY_INPUT_VALUES_F pivf , 
    PAY_ELEMENT_TYPES_F petf , 
    PAY_ELEMENT_ENTRIES_F peef , 
    PAY_ELEMENT_ENTRY_VALUES_F peevf 
  WHERE pivf.element_type_id = petf.element_type_id 
  AND petf.element_name     IN ( 'Annual Leave Adjustment') 
  AND pivf.NAME             IN ('Annual Leave Adjustment') 
  AND pivf.element_type_id   = peef.element_type_id 
  AND peef.element_entry_id  = peevf.element_entry_id 
  AND pivf.input_value_id    = peevf.input_value_id 
  AND peef.assignment_id     = paaf.assignment_id 
  AND peef.CREATION_DATE     > '30-JUN-2014' 
  ))-(per_utility_functions.get_Net_Accrual ( P_Assignment_ID => paaf.assignment_id ,P_Payroll_ID => 61 ,P_Business_Group_ID => 81 ,P_Assignment_Action_ID => NULL ,P_Calculation_Date => sysdate ,P_Plan_ID => 61 ,P_Accrual_Start_Date => NULL ,P_Accrual_Latest_Balance => NULL )) "Holiday Used" , 
  per_utility_functions.get_Net_Accrual ( P_Assignment_ID => paaf.assignment_id ,P_Payroll_ID => 61 ,P_Business_Group_ID => 81 ,P_Assignment_Action_ID => NULL ,P_Calculation_Date => sysdate ,P_Plan_ID => 61 ,P_Accrual_Start_Date => NULL ,P_Accrual_Latest_Balance => NULL ) "Holiday Balance Left" , 
  (per_utility_functions.get_Net_Accrual (P_Assignment_ID => paaf.assignment_id ,P_Payroll_ID => 61 ,P_Business_Group_ID => 81 ,P_Assignment_Action_ID => NULL ,P_Calculation_Date => sysdate ,P_Plan_ID => 62 ,P_Accrual_Start_Date => NULL ,P_Accrual_Latest_Balance => NULL)) - ( per_accrual_calc_functions.get_other_net_contribution( p_assignment_id =>paaf.assignment_id ,p_plan_id => 62 ,p_calculation_date => sysdate ,p_start_date => '01-JUL-2014' ,p_input_value_id => NULL) ) "Holiday Entitlement" , 
  (SELECT SUM(peevf.screen_entry_value) 
  FROM PAY_INPUT_VALUES_F pivf , 
    PAY_ELEMENT_TYPES_F petf , 
    PAY_ELEMENT_ENTRIES_F peef , 
    PAY_ELEMENT_ENTRY_VALUES_F peevf 
  WHERE pivf.element_type_id = petf.element_type_id 
  AND petf.element_name     IN ( 'Annual Leave Adjustment') 
  AND pivf.NAME             IN ('Annual Leave Adjustment') 
  AND pivf.element_type_id   = peef.element_type_id 
  AND peef.element_entry_id  = peevf.element_entry_id 
  AND pivf.input_value_id    = peevf.input_value_id 
  AND peef.assignment_id     = paaf.assignment_id 
  AND peef.CREATION_DATE     > '30-JUN-2014' 
  ) "Annual Leave Adjustment" , 
  per_utility_functions.get_Net_Accrual ( P_Assignment_ID => paaf.assignment_id ,P_Payroll_ID => 61 ,P_Business_Group_ID => 81 ,P_Assignment_Action_ID => NULL ,P_Calculation_Date => sysdate ,P_Plan_ID => 62 ,P_Accrual_Start_Date => NULL ,P_Accrual_Latest_Balance => NULL ) + 
  (SELECT SUM(peevf.screen_entry_value) 
  FROM PAY_INPUT_VALUES_F pivf , 
    PAY_ELEMENT_TYPES_F petf , 
    PAY_ELEMENT_ENTRIES_F peef , 
    PAY_ELEMENT_ENTRY_VALUES_F peevf 
  WHERE pivf.element_type_id = petf.element_type_id 
  AND petf.element_name     IN ( 'Annual Leave Adjustment') 
  AND pivf.NAME             IN ('Annual Leave Adjustment') 
  AND pivf.element_type_id   = peef.element_type_id 
  AND peef.element_entry_id  = peevf.element_entry_id 
  AND pivf.input_value_id    = peevf.input_value_id 
  AND peef.assignment_id     = paaf.assignment_id 
  AND peef.CREATION_DATE     > '30-JUN-2014' 
  ) "Total Holiday Entitlement" 
FROM per_all_people_f papf , 
  per_all_assignments_f paaf , 
  per_all_people_f papf1 , 
  per_periods_of_service pps , 
  per_person_types ppt 
WHERE papf.person_id = paaf.person_id(+) 
AND TRUNC(sysdate) BETWEEN papf.effective_start_date AND papf.effective_end_date 
AND TRUNC(sysdate) BETWEEN paaf.effective_start_date(+) AND paaf.effective_end_date(+) 
AND TRUNC(sysdate) BETWEEN papf1.effective_start_date(+) AND papf1.effective_end_date(+) 
AND paaf.period_of_service_id  = PPS.period_of_service_id(+) 
AND papf.current_employee_flag = 'Y' 
AND paaf.primary_flag(+)       = 'Y' 
AND paaf.assignment_type(+)    = 'E' 
AND papf.business_group_id     = 81 
AND papf.person_type_id        = ppt.person_type_id 
AND paaf.supervisor_id         = papf1.person_id(+) 
;
