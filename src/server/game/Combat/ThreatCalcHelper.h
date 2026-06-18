/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SF_THREATCALCHELPER
#define SF_THREATCALCHELPER

#include "Define.h"

class Unit;
class SpellInfo;

struct ThreatCalcHelper
{
    static uint32 const NormalSchoolMask = 1;

    struct SpellThreatCalculation
    {
        float threat;
        bool ignoresUnitModifiers;
    };

    static SpellThreatCalculation ApplySpellThreatModifiers(float threat, float pctMod, bool hasEnergizeEffect)
    {
        if (pctMod != 1.0f)
            threat *= pctMod;

        SpellThreatCalculation result = { threat, hasEnergizeEffect };
        return result;
    }

    static float calcThreat(Unit* hatedUnit, Unit* hatingUnit, float threat, uint32 schoolMask = NormalSchoolMask, SpellInfo const* threatSpell = NULL);
    static bool isValidProcess(Unit* hatedUnit, Unit* hatingUnit, SpellInfo const* threatSpell = NULL);
};

#endif
