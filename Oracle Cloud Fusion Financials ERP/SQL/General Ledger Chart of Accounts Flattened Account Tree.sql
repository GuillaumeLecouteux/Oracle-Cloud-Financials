select ftn.tree_code
, ftn.pk1_start_value as account_code
, ftn.parent_pk1_value as parent_account_code
, ffv.description as account_description
, substr(replace(ffv.compiled_value_attributes,CHR(10),''),1,1) as attribute_summary
, substr(replace(ffv.compiled_value_attributes,CHR(10),''),2,1) as attribute_allow_posting
, substr(replace(ffv.compiled_value_attributes,CHR(10),''),3,1) as attribute_allow_bugetting
, substr(replace(ffv.compiled_value_attributes,CHR(10),''),4,1) as attribute_account_type
, substr(replace(ffv.compiled_value_attributes,CHR(10),''),5,1) as attribute_3rd_party_control
, substr(replace(ffv.compiled_value_attributes,CHR(10),''),6,1) as attribute_reconcile
, ftn.depth
, ftn.child_count
from FND_TREE ft /*This table holds Trees details for managing trees.*/
join FND_TREE_VERSION ftv /*This table holds Tree Versions.*/
  on ftv.tree_structure_code = ft.tree_structure_code
  and ftv.tree_code = ft.tree_code
  and ftv.enterprise_id = ft.enterprise_id
join  FND_ID_FLEX_SEGMENTS fifs
  on fifs.id_flex_code = 'GL#'
  and fifs.application_id = 101 /*GL*/
  and fifs.segment_name = ft.tree_code
join FND_TREE_NODE ftn /*This table holds the nodes of trees.*/
  on ftn.tree_structure_code = ft.tree_structure_code
  and ftn.tree_code = ft.tree_code
  and ftn.enterprise_id = ft.enterprise_id
  and ftn.tree_version_id = ftv.  tree_version_id
join FND_FLEX_VALUES_VL ffv
  on ffv.flex_value_set_id = fifs.flex_value_set_id
  and ffv.flex_value = ftn.pk1_start_value
where ft.tree_structure_code = 'GL_ACCT_FLEX' /* General Ledger Chart of Accounts Structure */
and ft.tree_code = :P_TREE_CODE /*Tree code identifying the chart of account segment */
and ft.enterprise_id = 1
and ftv.status = 'ACTIVE'
order by ftn.depth, ftn.pk1_start_value