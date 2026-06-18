/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "sfmt.h"

#include <cmath>
#include <cstdint>
#include <iostream>

namespace
{
    bool Expect(bool condition, char const* message)
    {
        if (!condition)
            std::cerr << message << '\n';

        return condition;
    }

    bool TestSeededSfmtProducesUsableValues()
    {
        bool passed = true;

        CRandomSFMT rng(12345);

        double firstNormal = rng.Random();
        passed &= Expect(std::isfinite(firstNormal), "Seeded SFMT normal roll should be finite");
        passed &= Expect(firstNormal >= 0.0 && firstNormal < 1.0, "Seeded SFMT normal roll should be in [0, 1)");

        std::uint32_t firstBits = rng.BRandom();
        std::uint32_t secondBits = rng.BRandom();
        passed &= Expect(firstBits != secondBits, "Seeded SFMT bit rolls should advance the sequence");

        int exactRoll = rng.IRandomX(10, 20);
        passed &= Expect(exactRoll >= 10 && exactRoll <= 20, "Seeded SFMT exact integer roll should stay inside the requested range");

        return passed;
    }
}

int main()
{
    bool passed = true;

    passed &= TestSeededSfmtProducesUsableValues();

    return passed ? 0 : 1;
}
