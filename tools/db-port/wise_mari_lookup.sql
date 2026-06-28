SELECT spell1,spell2,spell3,spell4,spell5,spell6,spell7,spell8 FROM loa.creature_template WHERE entry=56448;
SELECT entryorguid,id,event_type,action_type,action_param1,comment FROM loa.smart_scripts WHERE entryorguid=56448 LIMIT 20;
SELECT ScriptName, AIName FROM loa.creature_template WHERE entry=56448;
SELECT ScriptName, AIName FROM world.creature_template WHERE entry=56448;
