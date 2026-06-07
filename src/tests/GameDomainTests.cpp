/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "Cell.h"
#include "CurrencyFormulas.h"
#include "GridDefines.h"
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
    passed &= TestGridAndCellPrimitives();

    return passed ? 0 : 1;
}
