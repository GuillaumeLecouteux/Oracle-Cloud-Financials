select xep.name as legal_entity_name
, xep.legal_entity_id as legal_entity_id
, hou.name  as business_unit_name
, hou.organization_id as org_id
, geo.country_code as country_code
, geo.geography_id as geography_id
from fusion.xle_entity_profiles xep
join fusion.hr_operating_units hou
  on hou.default_legal_context_id = xep.legal_entity_id
join fusion.hz_geographies geo
  on geo.geography_id = xep.geography_id
order by geo.country_code, xep.name
