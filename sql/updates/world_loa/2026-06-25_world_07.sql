-- LOA port: missing gameobject_template rows referenced by world spawns.
-- Maps LOA schema to SkyFire (adds faction, flags, WDBVerified defaults).
-- Requires loa database on same MySQL host. Status: local-only (not pushed upstream)

INSERT INTO `gameobject_template` (
    `entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
    `faction`, `flags`, `size`, `questItem1`, `questItem2`, `questItem3`, `questItem4`, `questItem5`, `questItem6`,
    `data0`, `data1`, `data2`, `data3`, `data4`, `data5`, `data6`, `data7`, `data8`, `data9`,
    `data10`, `data11`, `data12`, `data13`, `data14`, `data15`, `data16`, `data17`, `data18`, `data19`,
    `data20`, `data21`, `data22`, `data23`, `data24`, `data25`, `data26`, `data27`, `data28`, `data29`,
    `data30`, `data31`, `unkInt32`, `AIName`, `ScriptName`, `WDBVerified`
)
SELECT
    l.`entry`, l.`type`, l.`displayId`, l.`name`, l.`IconName`, l.`castBarCaption`, l.`unk1`,
    0, 0, l.`size`, l.`questItem1`, l.`questItem2`, l.`questItem3`, l.`questItem4`, l.`questItem5`, l.`questItem6`,
    l.`data0`, l.`data1`, l.`data2`, l.`data3`, l.`data4`, l.`data5`, l.`data6`, l.`data7`, l.`data8`, l.`data9`,
    l.`data10`, l.`data11`, l.`data12`, l.`data13`, l.`data14`, l.`data15`, l.`data16`, l.`data17`, l.`data18`, l.`data19`,
    l.`data20`, l.`data21`, l.`data22`, l.`data23`, l.`data24`, l.`data25`, l.`data26`, l.`data27`, l.`data28`, l.`data29`,
    l.`data30`, l.`data31`, l.`unkInt32`, l.`AIName`, l.`ScriptName`, 1
FROM `loa`.`gameobject_template` l
LEFT JOIN `gameobject_template` w ON w.`entry` = l.`entry`
WHERE w.`entry` IS NULL
  AND l.`entry` IN (213074, 215413);
