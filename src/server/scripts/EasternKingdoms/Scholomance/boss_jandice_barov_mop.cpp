/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "scholomance.h"

enum JandiceSpells
{
    SPELL_GRAVITY_FLUX   = 114062,
    SPELL_WONDROUS_RAPID = 114476
};

enum JandiceEvents
{
    EVENT_GRAVITY_FLUX   = 1,
    EVENT_WONDROUS_RAPID = 2
};

class boss_jandice_barov_mop : public CreatureScript
{
    public:
        boss_jandice_barov_mop() : CreatureScript("boss_jandice_barov_mop") { }

        struct boss_jandice_barov_mopAI : public BossAI
        {
            boss_jandice_barov_mopAI(Creature* creature) : BossAI(creature, DATA_JANDICE_BAROV) { }

            void Reset() OVERRIDE
            {
                _Reset();
            }

            void EnterCombat(Unit* /*who*/) OVERRIDE
            {
                _EnterCombat();
                if (instance)
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, me);

                events.ScheduleEvent(EVENT_GRAVITY_FLUX, 10 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_WONDROUS_RAPID, 20 * IN_MILLISECONDS);
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
                        case EVENT_GRAVITY_FLUX:
                            DoCastAOE(SPELL_GRAVITY_FLUX);
                            events.ScheduleEvent(EVENT_GRAVITY_FLUX, 25 * IN_MILLISECONDS);
                            break;
                        case EVENT_WONDROUS_RAPID:
                            DoCastVictim(SPELL_WONDROUS_RAPID);
                            events.ScheduleEvent(EVENT_WONDROUS_RAPID, 15 * IN_MILLISECONDS);
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
            return GetScholomanceMopAI<boss_jandice_barov_mopAI>(creature);
        }
};

void AddSC_boss_jandice_barov_mop()
{
    new boss_jandice_barov_mop();
}
