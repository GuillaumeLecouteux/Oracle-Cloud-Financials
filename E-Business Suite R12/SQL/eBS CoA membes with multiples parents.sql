SELECT hier_name,
  hier20_code AS base_member_code,
  hier20_name AS base_member_name,
  COUNT(1)    AS nb_parents,
  listagg(hier1_code,', ') within GROUP (
ORDER BY hier1_code) AS hier1_code_list
FROM w_hierarchy_d
WHERE hier_name LIKE 'XXAQV_GL_COA%'
GROUP BY hier_name,
  --  hier1_code,
  --  hier1_name,
  hier20_code,
  hier20_name
HAVING COUNT(1) > 1
ORDER BY 1,2