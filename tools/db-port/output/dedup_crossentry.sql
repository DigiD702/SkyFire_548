SELECT c1.guid
FROM creature c1
INNER JOIN creature c2
    ON  c2.map = c1.map
    AND c2.id <> c1.id
    AND c2.phaseId = c1.phaseId
    AND c2.phaseGroup = c1.phaseGroup
    AND c2.guid > c1.guid
    AND ABS(c1.position_x - c2.position_x) < 1.25
    AND ABS(c1.position_y - c2.position_y) < 1.25
    AND ABS(c1.position_z - c2.position_z) < 2
INNER JOIN creature_template ct1 ON ct1.entry = c1.id
INNER JOIN creature_template ct2 ON ct2.entry = c2.id AND ct2.name = ct1.name
LEFT JOIN (SELECT entry, COUNT(*) AS cnt FROM npc_vendor GROUP BY entry) v1 ON v1.entry = c1.id
LEFT JOIN (SELECT entry, COUNT(*) AS cnt FROM npc_vendor GROUP BY entry) v2 ON v2.entry = c2.id
WHERE c1.map IN (870,860,859,861,1064,1050,1098,1135,1004)
  AND c1.guid < 8000000
  AND (
      (COALESCE(v1.cnt, 0) = 0 AND COALESCE(v2.cnt, 0) > 0)
      OR ((ct1.npcflag & 2) = 0 AND (ct2.npcflag & 2) <> 0
          AND EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = c2.id))
      OR ((ct1.npcflag & 4096) = 0 AND (ct2.npcflag & 4096) <> 0)
  );