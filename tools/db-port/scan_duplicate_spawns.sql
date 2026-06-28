-- Same-name creature pairs within ~2yd on the same map.
-- Params: set @map filter in the outer WHERE (0 = all maps).

SET @dist_xy := 2.0;
SET @dist_z  := 3.0;

SELECT
    c1.map,
    ct.name,
    ct.subname,
    c1.guid   AS guid_a,
    c1.id     AS id_a,
    c2.guid   AS guid_b,
    c2.id     AS id_b,
    ROUND(c1.position_x, 2) AS x,
    ROUND(c1.position_y, 2) AS y,
    ROUND(c1.position_z, 2) AS z,
    ROUND(SQRT(POW(c1.position_x - c2.position_x, 2) + POW(c1.position_y - c2.position_y, 2)), 3) AS dist_xy,
    (ct.npcflag & 128) > 0 AS is_vendor_flag,
    COALESCE(v1.cnt, 0) AS vendor_items_a,
    COALESCE(v2.cnt, 0) AS vendor_items_b
FROM creature c1
INNER JOIN creature c2
    ON  c2.map = c1.map
    AND c2.guid > c1.guid
    AND ABS(c1.position_x - c2.position_x) < @dist_xy
    AND ABS(c1.position_y - c2.position_y) < @dist_xy
    AND ABS(c1.position_z - c2.position_z) < @dist_z
INNER JOIN creature_template ct ON ct.entry = c1.id
INNER JOIN creature_template ct2 ON ct2.entry = c2.id AND ct2.name = ct.name
LEFT JOIN (
    SELECT entry, COUNT(*) AS cnt FROM npc_vendor GROUP BY entry
) v1 ON v1.entry = c1.id
LEFT JOIN (
    SELECT entry, COUNT(*) AS cnt FROM npc_vendor GROUP BY entry
) v2 ON v2.entry = c2.id
WHERE c1.map IN (870, 860, 859, 861, 1064, 1050, 1098, 1135, 1004)
ORDER BY c1.map, ct.name, dist_xy;
