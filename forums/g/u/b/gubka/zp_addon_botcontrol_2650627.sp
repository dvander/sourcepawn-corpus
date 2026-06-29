/**
 * ============================================================================
 *
 *  Zombie Plague
 *
 *
 *  Copyright (C) 2015-2019 Nikita Ushakov (Ireland, Dublin)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * ============================================================================
 **/

#include <sourcemod>
#include <sdktools>
#include <zombieplague>
#include <botattackcontrol>

#pragma newdecls required

/**
 * @brief Record plugin info.
 **/
public Plugin myinfo =
{
    name            = "[ZP] Addon: BotControl",
    author          = "qubka (Nikita Ushakov)",     
    description     = "Addon of extra items",
    version         = "1.0",
    url             = "https://forums.alliedmods.net/showthread.php?t=290657"
}

/**
 * @brief Called when bots determine if a player is an enemy.
 *
 * @param botIndex          The client index of the bot.
 * @param clientIndex       The client index of the player.
 * @param bResult           Contains the original result. Can be changed.
 * @return                  Plugin_Changed to use the result param, Plugin_Continue otherwise.
 *
 * @note                    Called several times per tick with bots in the server.
 */
public Action OnShouldBotAttackPlayer(int botIndex, int clientIndex, bool &bResult)
{
    // Block it
    bResult = (ZP_IsPlayerHuman(clientIndex) && ZP_IsPlayerHuman(botIndex) ||
               ZP_IsPlayerZombie(clientIndex) && ZP_IsPlayerZombie(botIndex)) ? false : true;
    
    // Return on the success
    return Plugin_Changed;
}