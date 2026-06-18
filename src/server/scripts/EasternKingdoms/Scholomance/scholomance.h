/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef DEF_SCHOLOMANCE_MOP_H_
#define DEF_SCHOLOMANCE_MOP_H_

#include "Map.h"
#include "Creature.h"
#include "ObjectMgr.h"

#define ScholomanceMopScriptName "instance_scholomance_mop"

uint32 const EncounterCount = 4;

enum ScholomanceDataTypes
{
    DATA_INSTRUCTOR_CHILLHEART  = 0,
    DATA_JANDICE_BAROV          = 1,
    DATA_LILIAN_VOSS            = 2,
    DATA_DARKMASTER_GANDLING    = 3
};

enum ScholomanceCreatureIds
{
    BOSS_INSTRUCTOR_CHILLHEART  = 58633,
    BOSS_JANDICE_BAROV          = 59184,
    BOSS_LILIAN_VOSS            = 59200,
    BOSS_DARKMASTER_GANDLING    = 59080
};

template<class AI>
CreatureAI* GetScholomanceMopAI(Creature* creature)
{
    if (InstanceMap* instance = creature->GetMap()->ToInstanceMap())
        if (instance->GetInstanceScript())
            if (instance->GetScriptId() == sObjectMgr->GetScriptId(ScholomanceMopScriptName))
                return new AI(creature);
    return NULL;
}

#endif
