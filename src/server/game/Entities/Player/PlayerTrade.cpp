/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "Player.h"
#include "Item.h"
#include "WorldSession.h"

void Player::TradeCancel(bool sendback, TradeStatus status /*= TRADE_STATUS_CANCELLED*/)
{
    if (m_trade)
    {
        Player* trader = m_trade->GetTrader();

        // send yellow "Trade canceled" message to both traders
        if (sendback)
            GetSession()->SendCancelTrade(status);

        trader->GetSession()->SendCancelTrade(status);

        // cleanup
        delete m_trade;
        m_trade = NULL;
        delete trader->m_trade;
        trader->m_trade = NULL;
    }
}

void Player::UpdateSoulboundTradeItems()
{
    if (m_itemSoulboundTradeable.empty())
        return;

    // also checks for garbage data
    for (ItemDurationList::iterator itr = m_itemSoulboundTradeable.begin(); itr != m_itemSoulboundTradeable.end();)
    {
        ASSERT(*itr);
        if ((*itr)->GetOwnerGUID() != GetGUID())
        {
            m_itemSoulboundTradeable.erase(itr++);
            continue;
        }
        if ((*itr)->CheckSoulboundTradeExpire())
        {
            m_itemSoulboundTradeable.erase(itr++);
            continue;
        }
        ++itr;
    }
}

void Player::AddTradeableItem(Item* item)
{
    m_itemSoulboundTradeable.push_back(item);
}

/// @todo should never allow an item to be added to m_itemSoulboundTradeable twice
void Player::RemoveTradeableItem(Item* item)
{
    m_itemSoulboundTradeable.remove(item);
}
