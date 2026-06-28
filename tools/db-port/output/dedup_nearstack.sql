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
    AND ABS(lo.position_z - sf.position_z) < 2
INNER JOIN creature_template ct ON ct.entry = lo.id
WHERE lo.map IN (870,860,859,861,1064,1050,1098,1135,1004)
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