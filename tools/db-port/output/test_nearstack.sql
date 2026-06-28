SELECT DISTINCT lo.guid
FROM creature lo
INNER JOIN creature sf
    ON  sf.map = lo.map
    AND sf.id = lo.id
    AND sf.phaseId = lo.phaseId
    AND sf.phaseGroup = lo.phaseGroup
    AND sf.guid >= 8000000
    AND lo.guid < 8000000
    AND SQRT(POW(lo.position_x - sf.position_x, 2) + POW(lo.position_y - sf.position_y, 2)) < 1.25
    AND ABS(lo.position_z - sf.position_z) < 2.0
INNER JOIN creature_template ct ON ct.entry = lo.id
WHERE lo.map = 870
  AND lo.id = 57324;
