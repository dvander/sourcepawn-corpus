/*
    Copyright by Mortiegama.
    Copyright by Fabian "Graveeater" Kürten <graveeater@sitl.de>.

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation version 3 of the License.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    There are modifications by Fabian "Graveeater" Kürten <graveeater@sitl.de>
    which can be additionally used under any later version of the License.
 */

#include <sourcemod>
#pragma semicolon 1

#define L4D2 HP Regen
#define PLUGIN_VERSION "1.3"

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6
#define ZOMBIECLASS_TANK 8

new bool:isHooked = false;
new bool:isDelayed = false;
new bool:clientRegen[MAXPLAYERS + 1] = false;

new Handle:cvarEnable;
new Handle:cvarDelayEnable;
new Handle:clientTimer[MAXPLAYERS + 1];
new Handle:clientHurt[MAXPLAYERS + 1];
new Handle:cvarDamageStop;

new Handle:cvarTeam1;
new Handle:cvarTickRate1;
new Handle:cvarSurvivorHP;
new Handle:cvarAmount1;

new Handle:cvarTeam2;
new Handle:cvarTickRate2;
new Handle:cvarBoomerHealth;
new Handle:cvarChargerHealth;
new Handle:cvarJockeyHealth;
new Handle:cvarHunterHealth;
new Handle:cvarSmokerHealth;
new Handle:cvarSpitterHealth;
new Handle:cvarTankHealth;
new Handle:cvarAmountBoomer;
new Handle:cvarAmountCharger;
new Handle:cvarAmountJockey;
new Handle:cvarAmountHunter;
new Handle:cvarAmountSmoker;
new Handle:cvarAmountSpitter;
new Handle:cvarAmountTank;

new String:modName[32];

public Plugin:myinfo =
{
    name = "[L4D2] HP Regeneration",
    author = "Mortiegama",
    description = "Allows you to set custom HP regeneration levels for infected and survivors.",
    version = PLUGIN_VERSION,
    url = ""
    // Thanks to:
    // MaTTe (mateo10) for making the original "HP Regeneration" plugin
    // Bl4nk for updating the plugin
}

public OnPluginStart()
{
    CreateConVar("sm_hpregeneration_version", PLUGIN_VERSION, "HpRegeneration Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    cvarEnable = CreateConVar("sm_hpregeneration_enable", "1", "Enables the HpRegeneration plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvarDelayEnable = CreateConVar("sm_hpregeneration_delayenable", "0", "Enables a delay in regeneration due to damage.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvarDamageStop = CreateConVar("sm_hpregeneration_damagedelay", "2", "How long after damage stops that regeneration begins (Def 2)", FCVAR_PLUGIN, true, 1.0, false, _);

    cvarTeam1 = CreateConVar("sm_hpregeneration_team1", "2", "Sets the team to affect by teamindex value (Def 2)", FCVAR_PLUGIN, true, 0.0);
    cvarTickRate1 = CreateConVar("sm_hpregeneration_tickrate1", "3", "Time, in seconds, between each regeneration tick (Def 3)", FCVAR_PLUGIN, true, 1.0, false, _);
    cvarSurvivorHP = CreateConVar("sm_hpregeneration_survivorhealth", "100", "Health to regenerate to, based on the control mode (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarAmount1 = CreateConVar("sm_hpregeneration_amountsurvivor", "1", "Amount of life to heal per regeneration tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);

    cvarTeam2 = CreateConVar("sm_hpregeneration_team2", "3", "Sets the team to affect by teamindex value (Def 3)", FCVAR_PLUGIN, true, 0.0);
    cvarTickRate2 = CreateConVar("sm_hpregeneration_tickrate2", "1", "Time, in seconds, between each regeneration tick (Def 1)", FCVAR_PLUGIN, true, 1.0, false, _);
    cvarBoomerHealth = CreateConVar("sm_hpregeneration_boomerhealth", "50", "Health to regenerate to, based on the control mode (Def 50)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarChargerHealth = CreateConVar("sm_hpregeneration_chargerhealth", "600", "Health to regenerate to, based on the control mode (Def 600)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarJockeyHealth = CreateConVar("sm_hpregeneration_jockeyhealth", "325", "Health to regenerate to, based on the control mode (Def 325)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarHunterHealth = CreateConVar("sm_hpregeneration_hunterhealth", "250", "Health to regenerate to, based on the control mode (Def 250)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarSmokerHealth = CreateConVar("sm_hpregeneration_smokerhealth", "250", "Health to regenerate to, based on the control mode (Def 250)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarSpitterHealth = CreateConVar("sm_hpregeneration_spitterhealth", "100", "Health to regenerate to, based on the control mode (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarTankHealth = CreateConVar("sm_hpregeneration_tankhealth", "6000", "Health to regenerate to, based on the control mode (Def 6000)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarAmountBoomer = CreateConVar("sm_hpregeneration_amountboomer", "5", "Amount of life to heal per regeneration tick (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarAmountCharger = CreateConVar("sm_hpregeneration_amountcharger", "5", "Amount of life to heal per regeneration tick (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarAmountJockey = CreateConVar("sm_hpregeneration_amountjockey", "5", "Amount of life to heal per regeneration tick (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarAmountHunter = CreateConVar("sm_hpregeneration_amounthunter", "5", "Amount of life to heal per regeneration tick (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarAmountSmoker = CreateConVar("sm_hpregeneration_amountsmoker", "5", "Amount of life to heal per regeneration tick (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarAmountSpitter = CreateConVar("sm_hpregeneration_amountspitter", "5", "Amount of life to heal per regeneration tick (Def 5)", FCVAR_PLUGIN, true, 0.0, false, _);
    cvarAmountTank = CreateConVar("sm_hpregeneration_amounttank", "0", "Amount of life to heal per regeneration tick (Def 0)", FCVAR_PLUGIN, true, 0.0, false, _);

    AutoExecConfig(true, "plugin.L4D2.HPRegen");
    CreateTimer(3.0, OnPluginStart_Delayed);
    GetGameFolderName(modName, sizeof(modName));
}

public Action:OnPluginStart_Delayed(Handle:timer)
{
    if (GetConVarInt(cvarEnable))
    {
        isHooked = true;
        LogMessage("[HpRegeneration] - Loaded");
    }

    if (GetConVarInt(cvarDelayEnable))
    {
        isDelayed = true;
    }

    HookEvent("player_hurt", event_PlayerHurt);
    HookEvent("player_death", event_PlayerDeath);
    HookEvent("player_team", event_PlayerTeam);
}


public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (isHooked)
    {
        if (clientTimer[client] == INVALID_HANDLE && IsClientInGame(client) == true && GetClientTeam(client) == GetConVarInt(cvarTeam1)) {
            clientTimer[client] = CreateTimer(GetConVarFloat(cvarTickRate1), RegenTick, client, TIMER_REPEAT);
      }

        if (clientTimer[client] == INVALID_HANDLE && IsClientInGame(client) == true && GetClientTeam(client) == GetConVarInt(cvarTeam2)) {
            clientTimer[client] = CreateTimer(GetConVarFloat(cvarTickRate2), RegenTick, client, TIMER_REPEAT);
      }

    }
    if (isDelayed)
    {
        clientHurt[client] = CreateTimer(GetConVarFloat(cvarDamageStop), DamageStop, client);
        clientRegen[client] = true;
    }
}

public Action:RegenTick(Handle:timer, any:client)
{
    if (IsClientInGame(client) == true && !clientRegen[client])
    {

        if (GetClientTeam(client) == GetConVarInt(cvarTeam1))
        {
            new sHP = GetClientHealth(client);
            new Float:sBuffHP = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
            new sHPRegen = GetConVarInt(cvarAmount1);
            new sMaxHP = GetConVarInt(cvarSurvivorHP);

            if (sHP + sBuffHP < sMaxHP)
            {
                SetEntProp(client, Prop_Send, "m_iHealth", sHP + sHPRegen, 1);
            }
        }

        new class = GetEntProp(client, Prop_Send, "m_zombieClass");

        if (GetClientTeam(client) == GetConVarInt(cvarTeam2))
        {
            new iHP = 0;
            new iHPRegen = 0;
            new iMaxHP = 0;

            switch (class)
            {
                case ZOMBIECLASS_BOOMER:
                {
                    iHP = GetClientHealth(client);
                    iHPRegen = GetConVarInt(cvarAmountBoomer);
                    iMaxHP = GetConVarInt(cvarBoomerHealth);
                }

                case ZOMBIECLASS_CHARGER:
                {
                    iHP = GetClientHealth(client);
                    iHPRegen = GetConVarInt(cvarAmountCharger);
                    iMaxHP = GetConVarInt(cvarChargerHealth);
                }

                case ZOMBIECLASS_JOCKEY:
                {
                    iHP = GetClientHealth(client);
                    iHPRegen = GetConVarInt(cvarAmountJockey);
                    iMaxHP = GetConVarInt(cvarJockeyHealth);
                }

                case ZOMBIECLASS_HUNTER:
                {
                    iHP = GetClientHealth(client);
                    iHPRegen = GetConVarInt(cvarAmountHunter);
                    iMaxHP = GetConVarInt(cvarHunterHealth);
                }

                case ZOMBIECLASS_SMOKER:
                {
                    iHP = GetClientHealth(client);
                    iHPRegen = GetConVarInt(cvarAmountSmoker);
                    iMaxHP = GetConVarInt(cvarSmokerHealth);
                }

                case ZOMBIECLASS_SPITTER:
                {
                    iHP = GetClientHealth(client);
                    iHPRegen = GetConVarInt(cvarAmountSpitter);
                    iMaxHP = GetConVarInt(cvarSpitterHealth);
                }

                default:
                {
                    // Please have a look at this. This should not happen.
                    // Or maybe tank here?
                    // For now, in this case all thre variables will be 0
                    // which will result the following if...if else... to pass.
                }

            } // end of switch

            if (iMaxHP > (iHPRegen + iHP))
            {
                SetEntProp(client, Prop_Send, "m_iHealth", iHPRegen + iHP, 1);
            }
            else if (iMaxHP < (iHPRegen + iHP))
            {
                SetEntProp(client, Prop_Send, "m_iHealth", iMaxHP, 1);
            }
        }

        if (class == ZOMBIECLASS_TANK)
        {
            new iHP = GetClientHealth(client);
            new iHPRegen = GetConVarInt(cvarAmountTank);
            new iMaxHP = GetConVarInt(cvarTankHealth);

            if (iMaxHP > (iHPRegen + iHP))
            {
                SetEntProp(client, Prop_Send, "m_iHealth", iHPRegen + iHP, 1);
            }
            else if (iMaxHP < (iHPRegen + iHP))
            {
                SetEntProp(client, Prop_Send, "m_iHealth", iMaxHP, 1);
            }
        }
    }
}

public Action:DamageStop(Handle:timer, any:client)
{
    clientRegen[client] = false;
}

public event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (clientTimer[client] != INVALID_HANDLE)
    {
        CloseHandle(clientTimer[client]);
        clientTimer[client] = INVALID_HANDLE;
    }
}

public event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (clientTimer[client] != INVALID_HANDLE)
    {
        CloseHandle(clientTimer[client]);
        clientTimer[client] = INVALID_HANDLE;
    }
}
