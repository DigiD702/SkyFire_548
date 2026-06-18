/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_SPELL_EFFECT_METADATA_H
#define SF_SPELL_EFFECT_METADATA_H

#include "Define.h"

namespace Skyfire
{
namespace Spells
{
    enum TriggerSpellRuleKind
    {
        TRIGGER_SPELL_RULE_NONE,
        TRIGGER_SPELL_RULE_VANISH,
        TRIGGER_SPELL_RULE_DEMONIC_EMPOWERMENT_SUCCUBUS,
        TRIGGER_SPELL_RULE_STACK_TRIGGER,
        TRIGGER_SPELL_RULE_CLOAK_OF_SHADOWS
    };

    struct TriggerSpellRule
    {
        uint32 TriggerSpellId;
        TriggerSpellRuleKind Kind;
        uint32 CastSpellId;
        uint32 StackSpellId;
    };

    enum ForceCastDamageRuleKind
    {
        FORCE_CAST_DAMAGE_RULE_NONE,
        FORCE_CAST_DAMAGE_RULE_REMOVE_AURA,
        FORCE_CAST_DAMAGE_RULE_CUSTOM_BASEPOINTS,
        FORCE_CAST_DAMAGE_RULE_TRIGGERED_ORIGINAL_CASTER
    };

    struct ForceCastDamageRule
    {
        uint32 SpellId;
        ForceCastDamageRuleKind Kind;
    };

    struct ShadowFlameScriptRule
    {
        uint32 ProtectionAuraSpellId;
        uint32 TriggerSpellId;
    };

    struct ProtoTypicalShorteningBlasterSpells
    {
        uint32 CasterSpellId;
        uint32 TargetSpellId;
    };

    TriggerSpellRule const* GetTriggerSpellRule(uint32 triggerSpellId);
    ForceCastDamageRule const* GetForceCastDamageRule(uint32 spellId);
    bool ShouldSendNoFlyZoneNotification(uint32 spellId);
    uint32 GetKillCreditFallbackCreatureEntry(uint32 spellId);
    bool ShouldLearnSpellFromEffectDamage(uint32 spellId);
    uint32 GetBendingShinboneTriggerSpellId(bool strongHit);
    uint32 GetScriptEffectStackRemovalAuraSpellId(uint32 scriptSpellId);
    ShadowFlameScriptRule const* GetShadowFlameScriptRule(uint32 scriptSpellId);
    uint32 GetDecimateScriptTriggerSpellId(uint32 scriptSpellId);
    uint32 GetMirrensDrinkingHatItemId(uint32 roll);
    uint32 GetPlantWarmaulOgreBannerEventId();
    uint32 GetMugTransformationItemId();
    uint32 GetBrewfestSampleSpellId();
    uint32 GetBrutallusBurnRangeAuraSpellId();
    uint32 GetGoblinWeatherMachineSpellId(uint32 roll);
    uint32 GetGoldScriptAmount();
    uint32 GetEmblazonRunebladeTriggerSpellId();
    uint32 GetDeathKnightInitiateVisualSpellId(uint32 displayId);
    uint32 GetDeathboltWardAuraSpellId();
    uint32 GetDeathboltReflectedSpellId();
    uint32 GetDeathboltDirectSpellId();
    uint32 GetSummonGhoulsOnScarletCrusadeSpellId();
    bool IsScriptDespawnSpell(uint32 scriptSpellId);
    uint32 GetGiftOfTheHarvesterFallbackSpellId();
    uint32 GetWintergraspRpggDropItemCount();
    uint32 GetBigBlizzardBearMountSpellId(uint16 ridingSkill);
    uint32 GetTeleportingScriptSpellId(uint32 areaId);
    uint32 GetGrabCrateParentSpellId();
    uint32 GetLightwellHealSpellId(uint32 creatureEntry);
    uint32 GetLightwellChargesAuraSpellId();
    ProtoTypicalShorteningBlasterSpells const* GetProtoTypicalShorteningBlasterSpells(uint32 roll);
    uint32 GetJudgementSealTriggerSpellId(uint32 judgementSpellId);
    uint32 GetJudgementFallbackSealTriggerSpellId(uint32 sealSpellId);
    uint32 GetPestilenceBloodPlagueSpellId();
    uint32 GetPestilenceFrostFeverSpellId();
    uint32 GetCreateHealthstoneTriggeredSpellId(uint32 createHealthstoneSpellId);
}
}

#endif
