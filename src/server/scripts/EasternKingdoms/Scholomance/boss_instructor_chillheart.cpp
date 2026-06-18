/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*
* MoP Scholomance - Instructor Chillheart
* Wrack Soul jump handled by spell_gen_chillheart_wrack_soul (#704)
*/

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "Map.h"
#include "MapReference.h"
#include "Player.h"
#include "scholomance.h"

enum ChillheartSpells
{
    SPELL_WRACK_SOUL            = 111631,
    SPELL_FRIGID_GRASP          = 111254,
    SPELL_ICE_WALL              = 111209,
    SPELL_CIRCLE_OF_DESTRUCTION = 111854
};

enum ChillheartNPCs
{
    NPC_PHYLACTERY_VEHICLE       = 58662
};

enum ChillheartEvents
{
    EVENT_WRACK_SOUL            = 1,
    EVENT_FRIGID_GRASP          = 2,
    EVENT_ICE_WALL              = 3,
    EVENT_CIRCLE_OF_DESTRUCTION = 4
};

class boss_instructor_chillheart : public CreatureScript
{
    public:
        boss_instructor_chillheart() : CreatureScript("boss_instructor_chillheart") { }

        struct boss_instructor_chillheartAI : public BossAI
        {
            boss_instructor_chillheartAI(Creature* creature) : BossAI(creature, DATA_INSTRUCTOR_CHILLHEART) { }

            void Reset() OVERRIDE
            {
                _Reset();
            }

            void EnterCombat(Unit* /*who*/) OVERRIDE
            {
                _EnterCombat();
                if (instance)
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_ENGAGE, me);

                events.ScheduleEvent(EVENT_WRACK_SOUL, 8 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_FRIGID_GRASP, 15 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_ICE_WALL, 25 * IN_MILLISECONDS);
                events.ScheduleEvent(EVENT_CIRCLE_OF_DESTRUCTION, 35 * IN_MILLISECONDS);
            }

            void EnterEvadeMode() OVERRIDE
            {
                if (instance)
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
                CleanupChillheartEncounter();
                _EnterEvadeMode();
                _DespawnAtEvade();
            }

            void JustDied(Unit* /*killer*/) OVERRIDE
            {
                CleanupChillheartEncounter();
                _JustDied();
                if (instance)
                    instance->SendEncounterUnit(ENCOUNTER_FRAME_DISENGAGE, me);
            }

            void CleanupChillheartEncounter()
            {
                std::list<Creature*> phylacteries;
                GetCreatureListWithEntryInGrid(phylacteries, me, NPC_PHYLACTERY_VEHICLE, 200.0f);
                for (Creature* phylactery : phylacteries)
                    phylactery->DespawnOrUnsummon();

                Map::PlayerList const& players = me->GetMap()->GetPlayers();
                for (Map::PlayerList::const_iterator itr = players.begin(); itr != players.end(); ++itr)
                    if (Player* player = itr->GetSource())
                        player->RemoveAurasDueToSpell(SPELL_WRACK_SOUL);
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
                        case EVENT_WRACK_SOUL:
                            if (Unit* target = SelectTarget(SELECT_TARGET_RANDOM, 0, 40.0f, true))
                                DoCast(target, SPELL_WRACK_SOUL);
                            events.ScheduleEvent(EVENT_WRACK_SOUL, 12 * IN_MILLISECONDS);
                            break;
                        case EVENT_FRIGID_GRASP:
                            DoCastVictim(SPELL_FRIGID_GRASP);
                            events.ScheduleEvent(EVENT_FRIGID_GRASP, 18 * IN_MILLISECONDS);
                            break;
                        case EVENT_ICE_WALL:
                            DoCast(me, SPELL_ICE_WALL);
                            events.ScheduleEvent(EVENT_ICE_WALL, 30 * IN_MILLISECONDS);
                            break;
                        case EVENT_CIRCLE_OF_DESTRUCTION:
                            DoCastAOE(SPELL_CIRCLE_OF_DESTRUCTION);
                            events.ScheduleEvent(EVENT_CIRCLE_OF_DESTRUCTION, 40 * IN_MILLISECONDS);
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
            return GetScholomanceMopAI<boss_instructor_chillheartAI>(creature);
        }
};

void AddSC_boss_instructor_chillheart()
{
    new boss_instructor_chillheart();
}
