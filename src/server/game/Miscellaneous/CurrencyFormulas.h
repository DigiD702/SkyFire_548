/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#ifndef SKYFIRE_CURRENCY_FORMULAS_H
#define SKYFIRE_CURRENCY_FORMULAS_H

#include "Define.h"

#include <cmath>

namespace Skyfire
{
    namespace Currency
    {
        inline uint32 ConquestRatingCalculator(uint32 rate)
        {
            if (rate <= 1500)
                return 1350; // Default conquest points
            else if (rate > 3000)
                rate = 3000;

            // http://www.arenajunkies.com/topic/179536-conquest-point-cap-vs-personal-rating-chart/page__st__60#entry3085246
            return uint32(1.4326 * ((1511.26 / (1 + 1639.28 / std::exp(0.00412 * rate))) + 850.15));
        }

        inline uint32 BgConquestRatingCalculator(uint32 rate)
        {
            // WowWiki: Battleground ratings receive a bonus of 22.2% to the cap they generate
            return uint32((ConquestRatingCalculator(rate) * 1.222f) + 0.5f);
        }
    } // namespace Skyfire::Currency
} // namespace Skyfire

#endif
