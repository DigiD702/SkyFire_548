/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "scholomance.h"

enum GandlingSpells
{
    SPELL_INCINERATE = 113918,
    SPELL_RISE       = 113824
};

enum GandlingEvents
{
    EVENT_INCINERATE = 1,
    EVENT_RISE       = 2
};

class boss_darkmaster_gandling_mop : public CreatureScript
{
    public:
        boss_darkmaster_gandling_mop() : CreatureScript("boss_darkmaster_gandling_mop") { }

        struct boss_darkmaster_gandling_mopAI : public BossAI
        {
            boss_darkmaster_gandling_mopAI(Creature* creature) : BossAI(creature, DATA_DARKMASTER_GANDLING) { }

            void Reset() OVERRIDE
            {
                _Reset();
            }

            void EnterCombat(Unit* /*who*/) OVERRIDE
            {
                _EnterCombat();
                if (instance)
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, me);

                events.ScheduleEvent(EVENT_INCINERATE, 6 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_RISE, 20 * IN_MILLISECONDS);
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
                        case EVENT_INCINERATE:
                            if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0, 40.0f, true))
                                DoCast(target, SPELL_INCINERATE);
                            events.ScheduleEvent(EVENT_INCINERATE, 10 * IN_MILLISECONDS);
                            break;
                        case EVENT_RISE:
                            DoCast(me, SPELL_RISE);
                            events.ScheduleEvent(EVENT_RISE, 30 * IN_MILLISECONDS);
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
            return GetScholomanceMopAI<boss_darkmaster_gandling_mopAI>(creature);
        }
};

void AddSC_boss_darkmaster_gandling_mop()
{
    new boss_darkmaster_gandling_mop();
}
