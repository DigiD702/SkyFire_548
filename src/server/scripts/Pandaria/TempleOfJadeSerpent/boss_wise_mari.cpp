/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "temple_of_jade_serpent.h"

enum WiseMariSpells
{
    SPELL_WATER_BUBBLE    = 106062,
    SPELL_HYDROLANCE      = 106105,
    SPELL_WASH_AWAY       = 106653,
};

enum WiseMariEvents
{
    EVENT_WATER_BUBBLE = 1,
    EVENT_HYDROLANCE,
    EVENT_WASH_AWAY,
};

// LOA uses the historical typo "boss_wase_mari" in creature_template.ScriptName.
class boss_wase_mari : public CreatureScript
{
public:
    boss_wase_mari() : CreatureScript("boss_wase_mari") { }

    struct boss_wase_mariAI : public BossAI
    {
        boss_wase_mariAI(Creature* creature) : BossAI(creature, DATA_WISE_MARI) { }

        void Reset() OVERRIDE
        {
            BossAI::Reset();
            events.ScheduleEvent(EVENT_WATER_BUBBLE, 10000);
            events.ScheduleEvent(EVENT_HYDROLANCE, 5000);
            events.ScheduleEvent(EVENT_WASH_AWAY, 15000);
        }

        void JustDied(Unit* /*killer*/) OVERRIDE
        {
            _JustDied();
            instance->SetBossState(DATA_WISE_MARI, DONE);
        }

        void JustReachedHome() OVERRIDE
        {
            BossAI::JustReachedHome();
            instance->SetBossState(DATA_WISE_MARI, FAIL);
        }

        void EnterCombat(Unit* victim) OVERRIDE
        {
            BossAI::EnterCombat(victim);
            instance->SetBossState(DATA_WISE_MARI, IN_PROGRESS);
        }

        void UpdateAI(uint32 diff) OVERRIDE
        {
            if (!UpdateVictim() || !CheckInRoom())
                return;

            events.Update(diff);

            if (me->HasUnitState(UNIT_STATE_CASTING))
                return;

            while (uint32 eventId = events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_WATER_BUBBLE:
                        DoCast(me, SPELL_WATER_BUBBLE);
                        events.ScheduleEvent(EVENT_WATER_BUBBLE, 25000);
                        break;
                    case EVENT_HYDROLANCE:
                        if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0, 50.0f, true))
                            DoCast(target, SPELL_HYDROLANCE);
                        events.ScheduleEvent(EVENT_HYDROLANCE, 12000);
                        break;
                    case EVENT_WASH_AWAY:
                        DoCastAOE(SPELL_WASH_AWAY);
                        events.ScheduleEvent(EVENT_WASH_AWAY, 20000);
                        break;
                    default:
                        break;
                }
            }

            DoMeleeAttackIfReady();
        }
    };

    CreatureAI* GetAI(Creature* creature) const OVERRIDE
    {
        return GetJadeSerpentAI<boss_wase_mariAI>(creature);
    }
};

void AddSC_boss_wase_mari()
{
    new boss_wase_mari();
}
