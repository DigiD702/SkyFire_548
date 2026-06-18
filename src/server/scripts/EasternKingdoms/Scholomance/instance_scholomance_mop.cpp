/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "ScriptMgr.h"
#include "InstanceScript.h"
#include "scholomance.h"

class instance_scholomance_mop : public InstanceMapScript
{
    public:
        instance_scholomance_mop() : InstanceMapScript(ScholomanceMopScriptName, 1007) { }

        struct instance_scholomance_mop_InstanceMapScript : public InstanceScript
        {
            instance_scholomance_mop_InstanceMapScript(InstanceMap* map) : InstanceScript(map)
            {
                SetBossNumber(EncounterCount);
                ChillheartGUID = 0;
                JandiceGUID = 0;
                LilianGUID = 0;
                GandlingGUID = 0;
            }

            void OnCreatureCreate(Creature* creature) OVERRIDE
            {
                switch (creature->GetEntry())
                {
                    case BOSS_INSTRUCTOR_CHILLHEART:
                        ChillheartGUID = creature->GetGUID();
                        break;
                    case BOSS_JANDICE_BAROV:
                        JandiceGUID = creature->GetGUID();
                        break;
                    case BOSS_LILIAN_VOSS:
                        LilianGUID = creature->GetGUID();
                        break;
                    case BOSS_DARKMASTER_GANDLING:
                        GandlingGUID = creature->GetGUID();
                        break;
                    default:
                        break;
                }
            }

            uint64 GetData64(uint32 type) const OVERRIDE
            {
                switch (type)
                {
                    case DATA_INSTRUCTOR_CHILLHEART:
                        return ChillheartGUID;
                    case DATA_JANDICE_BAROV:
                        return JandiceGUID;
                    case DATA_LILIAN_VOSS:
                        return LilianGUID;
                    case DATA_DARKMASTER_GANDLING:
                        return GandlingGUID;
                    default:
                        break;
                }
                return 0;
            }

        private:
            uint64 ChillheartGUID;
            uint64 JandiceGUID;
            uint64 LilianGUID;
            uint64 GandlingGUID;
        };

        InstanceScript* GetInstanceScript(InstanceMap* map) const OVERRIDE
        {
            return new instance_scholomance_mop_InstanceMapScript(map);
        }
};

void AddSC_instance_scholomance_mop()
{
    new instance_scholomance_mop();
}
