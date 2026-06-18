/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "AccountMgr.h"
#include "AreaTrigger.h"
#include "Battleground.h"
#include "BattlegroundMgr.h"
#include "BattlePetMgr.h"
#include "CellImpl.h"
#include "Common.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "DatabaseEnv.h"
#include "DynamicObject.h"
#include "Formulas.h"
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GossipDef.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "Guild.h"
#include "GuildMgr.h"
#include "InstanceScript.h"
#include "Language.h"
#include "Log.h"
#include "MapManager.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Opcodes.h"
#include "OutdoorPvPMgr.h"
#include "PathGenerator.h"
#include "Pet.h"
#include "Player.h"
#include "ReputationMgr.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "SkillDiscovery.h"
#include "SkillExtraItems.h"
#include "SocialMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellValidation.h"
#include "TemporarySummon.h"
#include "Totem.h"
#include "Unit.h"
#include "UpdateData.h"
#include "UpdateMask.h"
#include "Util.h"
#include "Vehicle.h"
#include "VMapFactory.h"
#include "World.h"
#include "WorldPacket.h"

void Spell::EffectDuel(SpellEffIndex effIndex)
{
    if (effectHandleMode != SPELL_EFFECT_HANDLE_HIT_TARGET)
        return;

    if (!unitTarget || m_caster->GetTypeId() != TypeID::TYPEID_PLAYER || unitTarget->GetTypeId() != TypeID::TYPEID_PLAYER)
        return;

    Player* caster = m_caster->ToPlayer();
    Player* target = unitTarget->ToPlayer();

    // caster or target already have requested duel
    if (caster->duel || target->duel || !target->GetSocial() || target->GetSocial()->HasIgnore(caster->GetGUIDLow()))
        return;

    // Players can only fight a duel in zones with this flag
    AreaTableEntry const* casterAreaEntry = GetAreaEntryByAreaID(caster->GetAreaId());
    if (casterAreaEntry && !(casterAreaEntry->m_flags & AREA_FLAG_ALLOW_DUELS))
    {
        SendCastResult(SpellCastResult::SPELL_FAILED_NO_DUELING);            // Dueling isn't allowed here
        return;
    }

    AreaTableEntry const* targetAreaEntry = GetAreaEntryByAreaID(target->GetAreaId());
    if (targetAreaEntry && !(targetAreaEntry->m_flags & AREA_FLAG_ALLOW_DUELS))
    {
        SendCastResult(SpellCastResult::SPELL_FAILED_NO_DUELING);            // Dueling isn't allowed here
        return;
    }

    //CREATE DUEL FLAG OBJECT
    GameObject* pGameObj = new GameObject;

    uint32 gameobject_id = m_spellInfo->Effects[effIndex].MiscValue;

    Map* map = m_caster->GetMap();
    if (!pGameObj->Create(sObjectMgr->GenerateLowGuid(HIGHGUID_GAMEOBJECT), gameobject_id,
        map,
        m_caster->GetPositionX() + (unitTarget->GetPositionX() - m_caster->GetPositionX()) / 2,
        m_caster->GetPositionY() + (unitTarget->GetPositionY() - m_caster->GetPositionY()) / 2,
        m_caster->GetPositionZ(),
        m_caster->GetOrientation(), 0.0f, 0.0f, 0.0f, 0.0f, 0, GOState::GO_STATE_READY))
    {
        delete pGameObj;
        return;
    }

    for (auto phase : m_caster->GetPhases())
        pGameObj->SetPhased(phase, false, true);

    pGameObj->SetUInt32Value(GAMEOBJECT_FIELD_FACTION_TEMPLATE, m_caster->getFaction());
    pGameObj->SetUInt32Value(GAMEOBJECT_FIELD_LEVEL, m_caster->getLevel() + 1);
    int32 duration = m_spellInfo->GetDuration();
    pGameObj->SetRespawnTime(duration > 0 ? duration / IN_MILLISECONDS : 0);
    pGameObj->SetSpellId(m_spellInfo->Id);

    ExecuteLogEffectSummonObject(effIndex, pGameObj);

    m_caster->AddGameObject(pGameObj);
    map->AddToMap(pGameObj);
    //END

    // Send request
    ObjectGuid arbiterGuid = pGameObj->GetGUID();
    ObjectGuid casterGuid = caster->GetGUID();

    WorldPacket data(SMSG_DUEL_REQUESTED, 8 + 8);
    data.WriteGuidMask(arbiterGuid, 5);
    data.WriteGuidMask(casterGuid, 4, 2, 7);
    data.WriteGuidMask(arbiterGuid, 0);
    data.WriteGuidMask(casterGuid, 5);
    data.WriteGuidMask(arbiterGuid, 4, 6);
    data.WriteGuidMask(casterGuid, 1, 3, 6);
    data.WriteGuidMask(arbiterGuid, 7, 3, 2, 1);
    data.WriteGuidMask(casterGuid, 0);

    data.WriteGuidBytes(arbiterGuid, 5, 3);
    data.WriteGuidBytes(casterGuid, 7, 4);
    data.WriteGuidBytes(arbiterGuid, 7);
    data.WriteGuidBytes(casterGuid, 3, 6, 0);
    data.WriteGuidBytes(arbiterGuid, 4);
    data.WriteGuidBytes(casterGuid, 2, 1);
    data.WriteGuidBytes(arbiterGuid, 0, 2, 6, 1);
    data.WriteGuidBytes(casterGuid, 5);

    caster->GetSession()->SendPacket(&data);
    target->GetSession()->SendPacket(&data);

    // create duel-info
    DuelInfo* duel = new DuelInfo;
    duel->initiator = caster;
    duel->opponent = target;
    duel->startTime = 0;
    duel->startTimer = 0;
    duel->isMounted = (GetSpellInfo()->Id == 62875); // Mounted Duel
    caster->duel = duel;

    DuelInfo* duel2 = new DuelInfo;
    duel2->initiator = caster;
    duel2->opponent = caster;
    duel2->startTime = 0;
    duel2->startTimer = 0;
    duel2->isMounted = (GetSpellInfo()->Id == 62875); // Mounted Duel
    target->duel = duel2;

    caster->SetUInt64Value(PLAYER_FIELD_DUEL_ARBITER, pGameObj->GetGUID());
    target->SetUInt64Value(PLAYER_FIELD_DUEL_ARBITER, pGameObj->GetGUID());

    sScriptMgr->OnPlayerDuelRequest(target, caster);
}

void Spell::EffectInebriate(SpellEffIndex /*effIndex*/)
{
    if (effectHandleMode != SPELL_EFFECT_HANDLE_HIT_TARGET)
        return;

    if (!unitTarget || unitTarget->GetTypeId() != TypeID::TYPEID_PLAYER)
        return;

    Player* player = unitTarget->ToPlayer();
    uint8 currentDrunk = player->GetDrunkValue();
    uint8 drunkMod = damage;
    if (currentDrunk + drunkMod > 100)
    {
        currentDrunk = 100;
        if (rand_chance() < 25.0f)
            player->CastSpell(player, 67468, false);    // Drunken Vomit
    }
    else
        currentDrunk += drunkMod;

    player->SetDrunkValue(currentDrunk, m_CastItem ? m_CastItem->GetEntry() : 0);
}

void Spell::EffectForceDeselect(SpellEffIndex /*effIndex*/)
{
    if (effectHandleMode != SPELL_EFFECT_HANDLE_HIT)
        return;

    WorldPacket data(SMSG_CLEAR_TARGET, 8);
    ObjectGuid CasterGUID = m_caster->GetGUID();
    data.WriteGuidMask(CasterGUID, 6, 2, 0, 4, 7, 1, 3, 5);
    data.WriteGuidBytes(CasterGUID, 4, 0, 3, 5, 2, 7, 6, 1);
    m_caster->SendMessageToSet(&data, true);
}

void Spell::EffectSkinPlayerCorpse(SpellEffIndex /*effIndex*/)
{
    if (effectHandleMode != SPELL_EFFECT_HANDLE_HIT_TARGET)
        return;

    SF_LOG_DEBUG("spells", "Effect: SkinPlayerCorpse");

    Player* player = m_caster->ToPlayer();
    Player* target = unitTarget->ToPlayer();
    if (!player || !target || target->IsAlive())
        return;

    target->RemovedInsignia(player);
}

void Spell::EffectCastButtons(SpellEffIndex effIndex)
{
    if (effectHandleMode != SPELL_EFFECT_HANDLE_HIT)
        return;

    if (m_caster->GetTypeId() != TypeID::TYPEID_PLAYER)
        return;

    Player* p_caster = m_caster->ToPlayer();
    uint32 button_id = m_spellInfo->Effects[effIndex].MiscValue + 132;
    uint32 n_buttons = m_spellInfo->Effects[effIndex].MiscValueB;

    for (; n_buttons; --n_buttons, ++button_id)
    {
        ActionButton const* ab = p_caster->GetActionButton(button_id);
        if (!ab || ab->GetType() != ActionButtonType::ACTION_BUTTON_SPELL)
            continue;

        //! Action button data is unverified when it's set so it can be "hacked"
        //! to contain invalid spells, so filter here.
        uint32 spell_id = ab->GetAction();
        if (!spell_id)
            continue;

        SpellInfo const* spellInfo = sSpellMgr->GetSpellInfo(spell_id);
        if (!spellInfo)
            continue;

        if (!p_caster->HasSpell(spell_id) || p_caster->HasSpellCooldown(spell_id))
            continue;

        if (!(spellInfo->AttributesEx9 & SPELL_ATTR9_SUMMON_PLAYER_TOTEM))
            continue;

        int32 cost = m_powerCost;
        if (m_caster->GetPower(POWER_MANA) < cost)
            continue;

        TriggerCastFlags triggerFlags = TriggerCastFlags(TRIGGERED_IGNORE_GCD | TRIGGERED_IGNORE_CAST_IN_PROGRESS | TRIGGERED_CAST_DIRECTLY);
        m_caster->CastSpell(m_caster, spell_id, triggerFlags);
    }
}
