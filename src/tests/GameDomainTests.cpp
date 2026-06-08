/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "Cell.h"
#include "CurrencyFormulas.h"
#include "GridDefines.h"
#include "SpellTargeting.h"
#include "SpellValidation.h"
#include "ThreatCalcHelper.h"
#include "WorldPacket.h"

#include <cmath>
#include <iostream>
#include <limits>
#include <string>

namespace
{
    bool Expect(bool condition, char const* message)
    {
        if (!condition)
            std::cerr << message << '\n';

        return condition;
    }

    bool ExpectNear(float actual, float expected, float epsilon, char const* message)
    {
        return Expect(std::fabs(actual - expected) <= epsilon, message);
    }

    bool TestCurrencyFormulaBoundaries()
    {
        bool passed = true;

        passed &= Expect(Skyfire::Currency::ConquestRatingCalculator(0) == 1350,
            "Conquest cap below rated threshold should use the base cap");
        passed &= Expect(Skyfire::Currency::ConquestRatingCalculator(1500) == 1350,
            "Conquest cap at rated threshold should use the base cap");
        passed &= Expect(Skyfire::Currency::ConquestRatingCalculator(2000) > 1350,
            "Conquest cap above rated threshold should increase");
        passed &= Expect(Skyfire::Currency::ConquestRatingCalculator(3100) == Skyfire::Currency::ConquestRatingCalculator(3000),
            "Conquest cap should clamp ratings above 3000");
        passed &= Expect(Skyfire::Currency::BgConquestRatingCalculator(1500) == 1650,
            "Battleground conquest cap should apply the 22.2 percent bonus");

        return passed;
    }

    bool TestWorldPacketContainerBehavior()
    {
        bool passed = true;

        WorldPacket packet(SMSG_PONG, 4);
        packet << uint32(0x11223344);

        passed &= Expect(packet.GetOpcode() == SMSG_PONG, "WorldPacket should preserve its opcode");
        passed &= Expect(packet.size() == sizeof(uint32), "WorldPacket should store appended payload bytes");

        packet.rpos(0);
        uint32 value = 0;
        packet >> value;
        passed &= Expect(value == 0x11223344, "WorldPacket should round-trip uint32 payloads");

        packet.SetReceivedOpcode(0x1234);
        WorldPacket copy(packet);
        passed &= Expect(copy.GetOpcode() == SMSG_PONG, "WorldPacket copy should preserve opcode");
        passed &= Expect(copy.GetReceivedOpcode() == 0, "WorldPacket copy should reset received opcode tracking");

        packet.Initialize(CMSG_PING, 1);
        passed &= Expect(packet.GetOpcode() == CMSG_PING, "WorldPacket Initialize should replace opcode");
        passed &= Expect(packet.size() == 0 && packet.rpos() == 0 && packet.wpos() == 0,
            "WorldPacket Initialize should clear payload and positions");

        WorldPacket bitPacket(SMSG_PONG, 1);
        bitPacket.WriteBit(1);
        bitPacket.WriteBit(0);
        bitPacket.WriteBit(1);
        bitPacket.FlushBits();

        passed &= Expect(bitPacket.size() == 1, "WorldPacket bit writes should flush into one byte");
        passed &= Expect(bitPacket.contents()[0] == 0xA0, "WorldPacket bit writes should use high-bit-first packing");

        bitPacket.rpos(0);
        passed &= Expect(bitPacket.ReadBit() == true, "WorldPacket should read first written bit");
        passed &= Expect(bitPacket.ReadBit() == false, "WorldPacket should read second written bit");
        passed &= Expect(bitPacket.ReadBit() == true, "WorldPacket should read third written bit");

        return passed;
    }

    bool TestThreatSpellModifierRules()
    {
        bool passed = true;

        ThreatCalcHelper::SpellThreatCalculation defaultCalculation =
            ThreatCalcHelper::ApplySpellThreatModifiers(100.0f, 1.0f, false);
        passed &= Expect(defaultCalculation.threat == 100.0f,
            "Threat spell modifier default multiplier should leave threat unchanged");
        passed &= Expect(!defaultCalculation.ignoresUnitModifiers,
            "Non-energize threat should still allow unit threat modifiers");

        ThreatCalcHelper::SpellThreatCalculation percentCalculation =
            ThreatCalcHelper::ApplySpellThreatModifiers(100.0f, 1.25f, false);
        passed &= Expect(percentCalculation.threat == 125.0f,
            "Threat spell modifier percent should scale threat");
        passed &= Expect(!percentCalculation.ignoresUnitModifiers,
            "Percent-only threat should still allow unit threat modifiers");

        ThreatCalcHelper::SpellThreatCalculation energizeCalculation =
            ThreatCalcHelper::ApplySpellThreatModifiers(100.0f, 0.5f, true);
        passed &= Expect(energizeCalculation.threat == 50.0f,
            "Energize threat should still apply spell threat percent modifiers");
        passed &= Expect(energizeCalculation.ignoresUnitModifiers,
            "Energize threat should bypass later unit threat modifiers");

        return passed;
    }

    bool TestSpellValidationMasks()
    {
        bool passed = true;

        passed &= Expect(Skyfire::Spells::IsMechanicRepresentable(MECHANIC_STUN),
            "Stun should be representable in a 32-bit spell mechanic mask");
        passed &= Expect(!Skyfire::Spells::IsMechanicRepresentable(MECHANIC_NONE),
            "Mechanic none should not set a mechanic mask bit");
        passed &= Expect(!Skyfire::Spells::IsMechanicRepresentable(MECHANIC_WOUNDED),
            "Mechanics outside the 32-bit mask should be rejected");

        uint32 stunMask = Skyfire::Spells::GetMechanicMask(MECHANIC_STUN);
        passed &= Expect(stunMask == (1u << MECHANIC_STUN),
            "Mechanic mask should set the mechanic bit");
        passed &= Expect(Skyfire::Spells::GetMechanicMask(MECHANIC_NONE) == 0,
            "Mechanic none should build an empty mask");
        passed &= Expect(Skyfire::Spells::GetMechanicMask(MECHANIC_WOUNDED) == 0,
            "Out-of-range mechanics should build an empty mask");
        passed &= Expect(Skyfire::Spells::HasMechanic(stunMask, MECHANIC_STUN),
            "Mechanic mask lookup should find an active mechanic");
        passed &= Expect(!Skyfire::Spells::HasMechanic(stunMask, MECHANIC_FEAR),
            "Mechanic mask lookup should reject inactive mechanics");
        passed &= Expect(Skyfire::Spells::BuildMechanicMask({ MECHANIC_SNARE, MECHANIC_ROOT, MECHANIC_WOUNDED }) ==
            ((1u << MECHANIC_SNARE) | (1u << MECHANIC_ROOT)),
            "Mechanic mask builder should combine representable mechanics only");
        passed &= Expect(Skyfire::Spells::HasAnyMechanic(stunMask, { MECHANIC_FEAR, MECHANIC_STUN }),
            "Mechanic mask lookup should find any requested active mechanic");

        passed &= Expect(Skyfire::Spells::GetEffectIndexMask(0) == 1u,
            "Effect index zero should map to the lowest mask bit");
        passed &= Expect(Skyfire::Spells::GetEffectIndexMask(31) == 0x80000000u,
            "Effect index thirty-one should map to the highest mask bit");
        passed &= Expect(Skyfire::Spells::GetEffectIndexMask(32) == 0,
            "Effect indexes outside the 32-bit mask should be rejected");

        passed &= Expect(Skyfire::Spells::GetDispelMask(DISPEL_MAGIC) == (1u << DISPEL_MAGIC),
            "Specific dispel types should map to their dispel bit");
        passed &= Expect(Skyfire::Spells::GetDispelMask(DISPEL_ALL) == DISPEL_ALL_MASK,
            "Dispel all should expand to all removable dispel types");
        passed &= Expect(Skyfire::Spells::GetDispelMask(DispelType(32)) == 0,
            "Out-of-range dispel types should build an empty mask");

        return passed;
    }

    bool TestSpellTargetingRules()
    {
        bool passed = true;

        passed &= Expect(GetTargetFlagMask(TARGET_OBJECT_TYPE_NONE) == TARGET_FLAG_NONE,
            "Empty target object type should not require an explicit target flag");
        passed &= Expect(GetTargetFlagMask(TARGET_OBJECT_TYPE_UNIT_AND_DEST) ==
            (TARGET_FLAG_DEST_LOCATION | TARGET_FLAG_UNIT),
            "Unit-and-destination object type should require both unit and destination flags");
        passed &= Expect(GetTargetFlagMask(TARGET_OBJECT_TYPE_CORPSE) ==
            (TARGET_FLAG_CORPSE_ALLY | TARGET_FLAG_CORPSE_ENEMY),
            "Generic corpse object type should allow both corpse target flags");
        passed &= Expect(GetTargetFlagMask(TARGET_OBJECT_TYPE_GOBJ_ITEM) == TARGET_FLAG_GAMEOBJECT_ITEM,
            "Gameobject item object type should map to the gameobject item flag");

        SpellImplicitTargetInfo enemyTarget(TARGET_UNIT_TARGET_ENEMY);
        passed &= Expect(!enemyTarget.IsArea(), "Single enemy unit target should not be area-targeted");
        passed &= Expect(enemyTarget.GetSelectionCategory() == TARGET_SELECT_CATEGORY_DEFAULT,
            "Single enemy unit target should use default target selection");
        passed &= Expect(enemyTarget.GetReferenceType() == TARGET_REFERENCE_TYPE_TARGET,
            "Single enemy unit target should reference the selected target");
        passed &= Expect(enemyTarget.GetObjectType() == TARGET_OBJECT_TYPE_UNIT,
            "Single enemy unit target should use unit object type");
        passed &= Expect(enemyTarget.GetCheckType() == TARGET_CHECK_ENEMY,
            "Single enemy unit target should require enemy target checks");

        bool srcSet = false;
        bool dstSet = false;
        passed &= Expect(enemyTarget.GetExplicitTargetMask(srcSet, dstSet) == TARGET_FLAG_UNIT_ENEMY,
            "Single enemy unit target should request the enemy-unit explicit target flag");
        passed &= Expect(!srcSet && !dstSet,
            "Single enemy unit target should not mark source or destination locations as consumed");

        SpellImplicitTargetInfo coneTarget(TARGET_UNIT_CONE_ENEMY_54);
        passed &= Expect(coneTarget.IsArea(), "Cone enemy target should be area-targeted");
        passed &= Expect(coneTarget.GetDirectionType() == TARGET_DIR_FRONT,
            "Cone enemy target should face forward");
        passed &= ExpectNear(coneTarget.CalcDirectionAngle(), 0.0f, 0.001f,
            "Forward direction target should have zero angle");

        SpellImplicitTargetInfo rightDest(TARGET_DEST_CASTER_RIGHT);
        passed &= ExpectNear(rightDest.CalcDirectionAngle(), static_cast<float>(-M_PI / 2), 0.001f,
            "Right caster destination should resolve to negative half-pi");

        SpellImplicitTargetInfo frontLeftDest(TARGET_DEST_CASTER_FRONT_LEFT);
        passed &= ExpectNear(frontLeftDest.CalcDirectionAngle(), static_cast<float>(M_PI / 4), 0.001f,
            "Front-left caster destination should resolve to quarter-pi");

        SpellImplicitTargetInfo randomDest(TARGET_DEST_CASTER_RANDOM);
        passed &= ExpectNear(randomDest.CalcDirectionAngle(), static_cast<float>(M_PI / 2), 0.001f,
            "Random caster destination should scale the normalized random value across a full circle");

        SpellImplicitTargetInfo sourceMarker(TARGET_SRC_CASTER);
        srcSet = false;
        dstSet = false;
        passed &= Expect(sourceMarker.GetExplicitTargetMask(srcSet, dstSet) == TARGET_FLAG_NONE,
            "Caster source marker should not request an explicit target flag");
        passed &= Expect(srcSet && !dstSet,
            "Caster source marker should mark the source location as consumed");

        SpellImplicitTargetInfo trajectoryTarget(TARGET_DEST_TRAJ);
        srcSet = false;
        dstSet = false;
        passed &= Expect(trajectoryTarget.GetExplicitTargetMask(srcSet, dstSet) ==
            (TARGET_FLAG_SOURCE_LOCATION | TARGET_FLAG_DEST_LOCATION),
            "Trajectory target should request both source and destination when neither is present");
        passed &= Expect(!srcSet && dstSet,
            "Trajectory target should mark destination consumption through its object type");

        srcSet = true;
        dstSet = false;
        passed &= Expect(trajectoryTarget.GetExplicitTargetMask(srcSet, dstSet) == TARGET_FLAG_DEST_LOCATION,
            "Trajectory target should only request destination when source is already present");

        return passed;
    }

    bool TestGridAndCellPrimitives()
    {
        bool passed = true;

        GridCoord grid = Skyfire::ComputeGridCoord(0.0f, 0.0f);
        passed &= Expect(grid.x_coord == CENTER_GRID_ID && grid.y_coord == CENTER_GRID_ID,
            "World origin should map to the center grid");

        CellCoord cell = Skyfire::ComputeCellCoord(0.0f, 0.0f);
        passed &= Expect(cell.x_coord == CENTER_GRID_CELL_ID && cell.y_coord == CENTER_GRID_CELL_ID,
            "World origin should map to the center cell");

        CellCoord low(10, 11);
        CellCoord high(12, 13);
        CellArea area(low, high);
        CellCoord begin;
        CellCoord end;
        area.ResizeBorders(begin, end);
        passed &= Expect(begin == low && end == high, "CellArea should return configured borders");
        passed &= Expect(!CellArea(low, low), "CellArea should be empty when low and high bounds match");
        passed &= Expect(!!area, "CellArea should be non-empty when bounds differ");

        CellCoord invalid(TOTAL_NUMBER_OF_CELLS_PER_MAP + 5, TOTAL_NUMBER_OF_CELLS_PER_MAP + 7);
        invalid.normalize();
        passed &= Expect(invalid.x_coord == TOTAL_NUMBER_OF_CELLS_PER_MAP - 1 &&
            invalid.y_coord == TOTAL_NUMBER_OF_CELLS_PER_MAP - 1,
            "CellCoord normalize should clamp to the valid maximum");

        float highCoord = MAP_HALFSIZE + 100.0f;
        Skyfire::NormalizeMapCoord(highCoord);
        passed &= Expect(std::fabs(highCoord - (MAP_HALFSIZE - 0.5f)) < 0.001f,
            "NormalizeMapCoord should clamp high map coordinates");

        float lowCoord = -MAP_HALFSIZE - 100.0f;
        Skyfire::NormalizeMapCoord(lowCoord);
        passed &= Expect(std::fabs(lowCoord + (MAP_HALFSIZE - 0.5f)) < 0.001f,
            "NormalizeMapCoord should clamp low map coordinates");

        passed &= Expect(Skyfire::IsValidMapCoord(MAP_HALFSIZE - 1.0f),
            "Coordinate inside map bounds should be valid");
        passed &= Expect(!Skyfire::IsValidMapCoord(std::numeric_limits<float>::infinity()),
            "Infinite coordinate should be invalid");

        return passed;
    }
}

int main()
{
    bool passed = true;

    passed &= TestCurrencyFormulaBoundaries();
    passed &= TestWorldPacketContainerBehavior();
    passed &= TestThreatSpellModifierRules();
    passed &= TestSpellValidationMasks();
    passed &= TestSpellTargetingRules();
    passed &= TestGridAndCellPrimitives();

    return passed ? 0 : 1;
}
