/*
* This file is part of Project SkyFire https://www.projectskyfire.org. 
* See LICENSE.md file for Copyright information
*/

#include "ScriptMgr.h"
#include "ScriptedCreature.h"
#include "ScriptedGossip.h"
#include "Player.h"
#include "CreatureTextMgr.h"
#include "GameObject.h"
#include "InstanceScript.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "SpellScript.h"
#include "zulaman.h"

enum VoljinSays
{
    SAY_INTRO_1 = 0,
    SAY_INTRO_2 = 1,
    SAY_INTRO_3 = 2,
    SAY_INTRO_4 = 3,
};

enum HexLordSays
{
    SAY_HEXLORD_INTRO = 0,
};

enum VoljinSpells
{
    SPELL_BANGING_THE_GONG = 45225,
};

enum VoljinEvents
{
    EVENT_INTRO_MOVEPOINT_1 = 1,
    EVENT_INTRO_MOVEPOINT_2 = 2,
    EVENT_INTRO_MOVEPOINT_3 = 3,
    EVENT_BANGING_THE_GONG = 4,
    EVENT_START_DOOR_OPENING_1 = 5,
    EVENT_START_DOOR_OPENING_2 = 6,
    EVENT_START_DOOR_OPENING_3 = 7,
    EVENT_START_DOOR_OPENING_4 = 8,
    EVENT_START_DOOR_OPENING_5 = 9,
    EVENT_START_DOOR_OPENING_6 = 10,
    EVENT_START_DOOR_OPENING_7 = 11,
};

enum VoljinPoints
{
    POINT_INTRO = 1,
    POINT_STRANGE_GONG = 2,
    POINT_START_DOOR_OPENING_1 = 3,
    POINT_START_DOOR_OPENING_2 = 4,
};

enum VoljinMisc
{
    ITEM_VIRTUAL_ITEM = 5301,
};

Position const VoljinIntroWaypoint[4] =
{
    { 117.7349f, 1662.77f, 42.02156f, 0.0f },
    { 132.14f, 1645.143f, 42.02158f, 0.0f },
    { 121.8901f, 1639.118f, 42.23253f, 0.0f },
    { 122.618f, 1639.546f, 42.11659f, 0.0f },
};

class npc_voljin_zulaman : public CreatureScript
{
public:
    npc_voljin_zulaman() : CreatureScript("npc_voljin_zulaman") { }

    struct npc_voljin_zulamanAI : public ScriptedAI
    {
        npc_voljin_zulamanAI(Creature* creature) : ScriptedAI(creature), _instance(creature->GetInstanceScript()), _gongCount(0)
        {
            if (_instance && _instance->GetData(DATA_ZULAMAN_STATE) == NOT_STARTED)
                me->SetFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_GOSSIP);
        }

        void sGossipSelect(Player* player, uint32 menuId, uint32 gossipListId) OVERRIDE
        {
            if (!_instance || _instance->GetData(DATA_ZULAMAN_STATE) != NOT_STARTED)
                return;

            if (me->GetCreatureTemplate()->GossipMenuId != menuId || gossipListId != 0)
                return;

            player->PlayerTalkClass->ClearMenus();
            player->CLOSE_GOSSIP_MENU();
            StartIntro(player);
        }

        void Reset() OVERRIDE
        {
            _gongCount = 0;
        }

        void StartIntro(Player* player)
        {
            if (!_instance || _instance->GetData(DATA_ZULAMAN_STATE) != NOT_STARTED)
                return;

            _events.Reset();
            me->SetUInt32Value(UNIT_FIELD_MOUNT_DISPLAY_ID, 0);
            me->RemoveFlag(UNIT_FIELD_NPC_FLAGS, UNIT_NPC_FLAG_GOSSIP);
            me->SetUInt32Value(OBJECT_FIELD_DYNAMIC_FLAGS, 0);
            _events.ScheduleEvent(EVENT_INTRO_MOVEPOINT_1, 1000);
            Talk(SAY_INTRO_1, player);
            me->SetWalk(true);
        }

        void DoAction(int32 action) OVERRIDE
        {
            if (action == ACTION_START_ZULAMAN)
            {
                if (++_gongCount == 10)
                    _events.ScheduleEvent(EVENT_START_DOOR_OPENING_1, 500);
            }
        }

        void UpdateAI(uint32 diff) OVERRIDE
        {
            _events.Update(diff);

            while (uint32 eventId = _events.ExecuteEvent())
            {
                switch (eventId)
                {
                    case EVENT_INTRO_MOVEPOINT_1:
                        me->GetMotionMaster()->MovePoint(POINT_INTRO, VoljinIntroWaypoint[0]);
                        _events.ScheduleEvent(EVENT_INTRO_MOVEPOINT_2, 1000);
                        break;
                    case EVENT_INTRO_MOVEPOINT_2:
                        me->GetMotionMaster()->MovePoint(POINT_STRANGE_GONG, VoljinIntroWaypoint[1]);
                        _events.ScheduleEvent(EVENT_INTRO_MOVEPOINT_3, 4000);
                        break;
                    case EVENT_INTRO_MOVEPOINT_3:
                        Talk(SAY_INTRO_2);
                        _events.ScheduleEvent(EVENT_BANGING_THE_GONG, 3000);
                        break;
                    case EVENT_BANGING_THE_GONG:
                        DoCast(me, SPELL_BANGING_THE_GONG);
                        if (GameObject* strangeGong = ObjectAccessor::GetGameObject(*me, _instance->GetData64(DATA_STRANGE_GONG)))
                            strangeGong->RemoveFlag(GAMEOBJECT_FIELD_FLAGS, GO_FLAG_NOT_SELECTABLE);
                        me->SetUInt32Value(UNIT_FIELD_VIRTUAL_ITEM_ID, ITEM_VIRTUAL_ITEM);
                        break;
                    case EVENT_START_DOOR_OPENING_1:
                        me->RemoveAura(SPELL_BANGING_THE_GONG);
                        _events.ScheduleEvent(EVENT_START_DOOR_OPENING_2, 500);
                        break;
                    case EVENT_START_DOOR_OPENING_2:
                        me->SetUInt32Value(UNIT_FIELD_VIRTUAL_ITEM_ID, 0);
                        if (GameObject* strangeGong = ObjectAccessor::GetGameObject(*me, _instance->GetData64(DATA_STRANGE_GONG)))
                            strangeGong->SetFlag(GAMEOBJECT_FIELD_FLAGS, GO_FLAG_NOT_SELECTABLE);
                        _events.ScheduleEvent(EVENT_START_DOOR_OPENING_3, 500);
                        break;
                    case EVENT_START_DOOR_OPENING_3:
                        me->GetMotionMaster()->MovePoint(POINT_START_DOOR_OPENING_1, VoljinIntroWaypoint[2]);
                        break;
                    case EVENT_START_DOOR_OPENING_4:
                        _instance->SetData(DATA_ZULAMAN_STATE, IN_PROGRESS);
                        if (GameObject* masiveGate = ObjectAccessor::GetGameObject(*me, _instance->GetData64(DATA_MASSIVE_GATE)))
                            masiveGate->SetGoState(GOState::GO_STATE_ACTIVE);
                        _events.ScheduleEvent(EVENT_START_DOOR_OPENING_5, 3000);
                        break;
                    case EVENT_START_DOOR_OPENING_5:
                        Talk(SAY_INTRO_4);
                        _events.ScheduleEvent(EVENT_START_DOOR_OPENING_6, 6000);
                        break;
                    case EVENT_START_DOOR_OPENING_6:
                        _events.ScheduleEvent(EVENT_START_DOOR_OPENING_7, 6000);
                        break;
                    case EVENT_START_DOOR_OPENING_7:
                        if (Creature* hexLordTrigger = ObjectAccessor::GetCreature(*me, _instance->GetData64(DATA_HEXLORD_TRIGGER)))
                            sCreatureTextMgr->SendChat(hexLordTrigger, SAY_HEXLORD_INTRO, NULL, ChatMsg::CHAT_MSG_ADDON, Language::LANG_ADDON, TEXT_RANGE_MAP);
                        break;
                    default:
                        break;
                }
            }
        }

        void MovementInform(uint32 movementType, uint32 pointId) OVERRIDE
        {
            if (movementType != POINT_MOTION_TYPE)
                return;

            switch (pointId)
            {
                case POINT_STRANGE_GONG:
                    if (GameObject* strangeGong = ObjectAccessor::GetGameObject(*me, _instance->GetData64(DATA_STRANGE_GONG)))
                        me->SetFacingToObject(strangeGong);
                    break;
                case POINT_START_DOOR_OPENING_1:
                    me->SetFacingTo(4.747295f);
                    me->GetMotionMaster()->MovePoint(POINT_START_DOOR_OPENING_2, VoljinIntroWaypoint[3]);
                    Talk(SAY_INTRO_3);
                    _events.ScheduleEvent(EVENT_START_DOOR_OPENING_4, 4500);
                    break;
                default:
                    break;
            }
        }

    private:
        InstanceScript* _instance;
        EventMap _events;
        uint8 _gongCount;
    };

    CreatureAI* GetAI(Creature* creature) const OVERRIDE
    {
        return GetZulAmanAI<npc_voljin_zulamanAI>(creature);
    }
};

// 45226 - Banging the Gong
class spell_banging_the_gong : public SpellScriptLoader
{
public:
    spell_banging_the_gong() : SpellScriptLoader("spell_banging_the_gong") { }

    class spell_banging_the_gong_SpellScript : public SpellScript
    {
        PrepareSpellScript(spell_banging_the_gong_SpellScript);

        void Activate(SpellEffIndex index)
        {
            PreventHitDefaultEffect(index);
            if (GameObject* go = GetHitGObj())
                go->SendCustomAnim(0);
        }

        void Register() OVERRIDE
        {
            OnEffectHitTarget += SpellEffectFn(spell_banging_the_gong_SpellScript::Activate, EFFECT_1, SPELL_EFFECT_ACTIVATE_OBJECT);
        }
    };

    SpellScript* GetSpellScript() const OVERRIDE
    {
        return new spell_banging_the_gong_SpellScript();
    }
};

void AddSC_zulaman()
{
    new npc_voljin_zulaman();
    new spell_banging_the_gong();
}
