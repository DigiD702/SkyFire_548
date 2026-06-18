/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_SPELLVALIDATION_H
#define SF_SPELLVALIDATION_H

#include "SharedDefines.h"

#include <initializer_list>

namespace Skyfire
{
namespace Spells
{
    uint32 const SpellMaskBitCount = 32;

    enum SpellDispatchHandlerKind
    {
        SPELL_DISPATCH_HANDLER_REAL,
        SPELL_DISPATCH_HANDLER_NULL,
        SPELL_DISPATCH_HANDLER_UNUSED,
        SPELL_DISPATCH_HANDLER_NO_IMMEDIATE_EFFECT
    };

    enum SpellDispatchValidationStatus
    {
        SPELL_DISPATCH_SUPPORTED,
        SPELL_DISPATCH_INTENTIONALLY_UNUSED,
        SPELL_DISPATCH_NO_IMMEDIATE_EFFECT,
        SPELL_DISPATCH_MISSING_OR_UNSUPPORTED
    };

    inline bool IsMaskBitRepresentable(uint32 bitIndex)
    {
        return bitIndex < SpellMaskBitCount;
    }

    inline uint32 GetMaskBit(uint32 bitIndex)
    {
        return IsMaskBitRepresentable(bitIndex) ? (1u << bitIndex) : 0;
    }

    inline bool IsMechanicRepresentable(uint32 mechanic)
    {
        return mechanic != MECHANIC_NONE && IsMaskBitRepresentable(mechanic);
    }

    inline uint32 GetMechanicMask(uint32 mechanic)
    {
        return IsMechanicRepresentable(mechanic) ? GetMaskBit(mechanic) : 0;
    }

    inline uint32 BuildMechanicMask(std::initializer_list<uint32> mechanics)
    {
        uint32 mask = 0;
        for (uint32 mechanic : mechanics)
            mask |= GetMechanicMask(mechanic);

        return mask;
    }

    inline bool HasMechanic(uint32 mask, uint32 mechanic)
    {
        uint32 mechanicMask = GetMechanicMask(mechanic);
        return mechanicMask != 0 && (mask & mechanicMask) != 0;
    }

    inline bool HasAnyMechanic(uint32 mask, std::initializer_list<uint32> mechanics)
    {
        return (mask & BuildMechanicMask(mechanics)) != 0;
    }

    inline uint32 GetEffectIndexMask(uint32 effIndex)
    {
        return GetMaskBit(effIndex);
    }

    inline uint32 GetDispelMask(DispelType type)
    {
        if (type == DISPEL_ALL)
            return DISPEL_ALL_MASK;

        return GetMaskBit(uint32(type));
    }

    inline SpellDispatchValidationStatus ClassifySpellDispatchHandler(SpellDispatchHandlerKind kind)
    {
        switch (kind)
        {
            case SPELL_DISPATCH_HANDLER_REAL:
                return SPELL_DISPATCH_SUPPORTED;
            case SPELL_DISPATCH_HANDLER_UNUSED:
                return SPELL_DISPATCH_INTENTIONALLY_UNUSED;
            case SPELL_DISPATCH_HANDLER_NO_IMMEDIATE_EFFECT:
                return SPELL_DISPATCH_NO_IMMEDIATE_EFFECT;
            case SPELL_DISPATCH_HANDLER_NULL:
            default:
                return SPELL_DISPATCH_MISSING_OR_UNSUPPORTED;
        }
    }

    inline char const* GetSpellDispatchValidationStatusName(SpellDispatchValidationStatus status)
    {
        switch (status)
        {
            case SPELL_DISPATCH_SUPPORTED:
                return "supported";
            case SPELL_DISPATCH_INTENTIONALLY_UNUSED:
                return "intentionally unused";
            case SPELL_DISPATCH_NO_IMMEDIATE_EFFECT:
                return "no immediate effect";
            case SPELL_DISPATCH_MISSING_OR_UNSUPPORTED:
            default:
                return "missing or unsupported";
        }
    }
}
}

#endif
