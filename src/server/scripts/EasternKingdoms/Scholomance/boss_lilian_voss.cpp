/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "scholomance.h"

enum LilianSpells
{
    SPELL_SHADOW_SHIV      = 111775,
    SPELL_DARK_BLAZE       = 111585
};

enum LilianEvents
{
    EVENT_SHADOW_SHIV      = 1,
    EVENT_DARK_BLAZE       = 2
};

class boss_lilian_voss : public CreatureScript
{
    public:
        boss_lilian_voss() : CreatureScript("boss_lilian_voss") { }

        struct boss_lilian_vossAI : public BossAI
        {
            boss_lilian_vossAI(Creature* creature) : BossAI(creature, DATA_LILIAN_VOSS) { }

            void Reset() OVERRIDE
            {
                _Reset();
            }

            void EnterCombat(Unit* /*who*/) OVERRIDE
            {
                _EnterCombat();
                if (instance)
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, me);

                events.ScheduleEvent(EVENT_SHADOW_SHIV, 8 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_DARK_BLAZE, 18 * IN_MILLISECONDS);
            }

            void EnterEvadeMode() OVERRIDE
            {
                if (instance)
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
                _EnterEvadeMode();
                _DespawnAtEvade();
            }

            void JustDied(Unit* /*killer*/) OVERRIDE
            {
                _JustDied();
                if (instance)
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
            }

            void UpdateAI(uint32 diff) OVERRIDE
            {
                if (!UpdateVictim())
                    return;

                events.Update(diff);

                if (me->HasUnitState(UNIT_STATE_CASTING))
                    return;

                while (uint32 eventId = events.ExecuteEvent())
                {
                    switch (eventId)
                    {
                        case EVENT_SHADOW_SHIV:
                            DoCastVictim(SPELL_SHADOW_SHIV);
                            events.ScheduleEvent(EVENT_SHADOW_SHIV, 12 * IN_MILLISECONDS);
                            break;
                        case EVENT_DARK_BLAZE:
                            DoCastAOE(SPELL_DARK_BLAZE);
                            events.ScheduleEvent(EVENT_DARK_BLAZE, 22 * IN_MILLISECONDS);
                            break;
                        default:
                            break;
                    }

                    if (me->HasUnitState(UNIT_STATE_CASTING))
                        return;
                }

                DoMeleeAttackIfReady();
            }
        };

        CreatureAI* GetAI(Creature* creature) const OVERRIDE
        {
            return GetScholomanceMopAI<boss_lilian_vossAI>(creature);
        }
};

void AddSC_boss_lilian_voss()
{
    new boss_lilian_voss();
}
