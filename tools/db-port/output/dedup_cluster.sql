SELECT c.guid
FROM creature c
INNER JOIN creature_template ct ON ct.entry = c.id
INNER JOIN (
    SELECT
        c2.map,
        c2.id,
        c2.phaseId,
        c2.phaseGroup,
        ROUND(c2.position_x, 1) AS bx,
        ROUND(c2.position_y, 1) AS pos_y,
        ROUND(c2.position_z, 1) AS bz,
        COALESCE(
            MIN(CASE WHEN c2.guid >= 8000000 THEN c2.guid END),
            MIN(CASE WHEN bs.guid IS NOT NULL THEN c2.guid END),
            MIN(c2.guid)
        ) AS keep_guid
    FROM creature c2
    INNER JOIN creature_template ct2 ON ct2.entry = c2.id
    LEFT JOIN `world_sfdb`.creature bs ON bs.guid = c2.guid
    WHERE c2.map IN (870,860,859,861,1064,1050,1098,1135,1004)
      AND (
    (ct2.npcflag & 0x03FFFFFE) <> 0
    OR EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct2.entry)
    OR EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct2.entry)
    OR EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct2.entry)
    OR EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct2.entry)
    OR (
        ct2.type IN (7, 8)
        AND ct2.`rank` = 0
        AND NOT EXISTS (
            SELECT 1 FROM creature_loot_template clt WHERE clt.entry = ct2.entry
        )
    )
)
AND NOT (
    ct2.type IN (1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13)
    AND (ct2.npcflag & 0x03FFFFFE) = 0
    AND NOT EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct2.entry)
    AND NOT EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct2.entry)
    AND NOT EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct2.entry)
    AND NOT EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct2.entry)
)
    GROUP BY c2.map, c2.id, c2.phaseId, c2.phaseGroup, bx, pos_y, bz
    HAVING COUNT(*) > 1
) k ON  k.map = c.map
   AND k.id = c.id
   AND c.phaseId = k.phaseId
   AND c.phaseGroup = k.phaseGroup
   AND ROUND(c.position_x, 1) = k.bx
   AND ROUND(c.position_y, 1) = k.pos_y
   AND ROUND(c.position_z, 1) = k.bz
   AND c.guid <> k.keep_guid
WHERE c.map IN (870,860,859,861,1064,1050,1098,1135,1004)
  AND (
    (ct.npcflag & 0x03FFFFFE) <> 0
    OR EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct.entry)
    OR EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct.entry)
    OR EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct.entry)
    OR EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct.entry)
    OR (
        ct.type IN (7, 8)
        AND ct.`rank` = 0
        AND NOT EXISTS (
            SELECT 1 FROM creature_loot_template clt WHERE clt.entry = ct.entry
        )
    )
)
AND NOT (
    ct.type IN (1, 2, 3, 4, 5, 6, 9, 10, 11, 12, 13)
    AND (ct.npcflag & 0x03FFFFFE) = 0
    AND NOT EXISTS (SELECT 1 FROM npc_vendor nv WHERE nv.entry = ct.entry)
    AND NOT EXISTS (SELECT 1 FROM npc_trainer nt WHERE nt.entry = ct.entry)
    AND NOT EXISTS (SELECT 1 FROM creature_queststarter cqs WHERE cqs.id = ct.entry)
    AND NOT EXISTS (SELECT 1 FROM creature_questender cqe WHERE cqe.id = ct.entry)
);