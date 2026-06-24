/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef ELUNA_COMPATIBILITY_H
#define ELUNA_COMPATIBILITY_H

#include <optional>

template<typename T>
using Optional = std::optional<T>;

using Difficulty = DifficultyID;

static constexpr TypeID TYPEID_OBJECT = TypeID::TYPEID_OBJECT;
static constexpr TypeID TYPEID_ITEM = TypeID::TYPEID_ITEM;
static constexpr TypeID TYPEID_CONTAINER = TypeID::TYPEID_CONTAINER;
static constexpr TypeID TYPEID_UNIT = TypeID::TYPEID_UNIT;
static constexpr TypeID TYPEID_PLAYER = TypeID::TYPEID_PLAYER;
static constexpr TypeID TYPEID_GAMEOBJECT = TypeID::TYPEID_GAMEOBJECT;
static constexpr TypeID TYPEID_DYNAMICOBJECT = TypeID::TYPEID_DYNAMICOBJECT;
static constexpr TypeID TYPEID_CORPSE = TypeID::TYPEID_CORPSE;

static constexpr TempSummonType TEMPSUMMON_TIMED_OR_DEAD_DESPAWN = TempSummonType::TEMPSUMMON_TIMED_OR_DEAD_DESPAWN;
static constexpr TempSummonType TEMPSUMMON_TIMED_OR_CORPSE_DESPAWN = TempSummonType::TEMPSUMMON_TIMED_OR_CORPSE_DESPAWN;
static constexpr TempSummonType TEMPSUMMON_TIMED_DESPAWN = TempSummonType::TEMPSUMMON_TIMED_DESPAWN;
static constexpr TempSummonType TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT = TempSummonType::TEMPSUMMON_TIMED_DESPAWN_OUT_OF_COMBAT;
static constexpr TempSummonType TEMPSUMMON_CORPSE_DESPAWN = TempSummonType::TEMPSUMMON_CORPSE_DESPAWN;
static constexpr TempSummonType TEMPSUMMON_CORPSE_TIMED_DESPAWN = TempSummonType::TEMPSUMMON_CORPSE_TIMED_DESPAWN;
static constexpr TempSummonType TEMPSUMMON_DEAD_DESPAWN = TempSummonType::TEMPSUMMON_DEAD_DESPAWN;
static constexpr TempSummonType TEMPSUMMON_MANUAL_DESPAWN = TempSummonType::TEMPSUMMON_MANUAL_DESPAWN;

static constexpr GOState GO_STATE_ACTIVE = GOState::GO_STATE_ACTIVE;
static constexpr GOState GO_STATE_READY = GOState::GO_STATE_READY;
static constexpr GOState GO_STATE_ACTIVE_ALTERNATIVE = GOState::GO_STATE_ACTIVE_ALTERNATIVE;

static constexpr LootState GO_NOT_READY = LootState::GO_NOT_READY;
static constexpr LootState GO_READY = LootState::GO_READY;
static constexpr LootState GO_ACTIVATED = LootState::GO_ACTIVATED;
static constexpr LootState GO_JUST_DEACTIVATED = LootState::GO_JUST_DEACTIVATED;

inline WorldObject* ElunaGetWorldObject(WorldObject const& context, uint64 guid)
{
    return ObjectAccessor::GetWorldObject(context, guid);
}

#endif
