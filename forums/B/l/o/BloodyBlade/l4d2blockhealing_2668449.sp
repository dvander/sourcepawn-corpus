/**
 * =============================================================================
 * L4D2 Block Healing (C)2012 Buster "Mr. Zero" Nielsen
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License, version 3.0, as 
 * published by the Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
 * FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along 
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2,"
 * the "Source Engine," the "SourcePawn JIT," and any Game MODs that run on 
 * software by the Valve Corporation.  You must obey the GNU General Public
 * License in all respects for all other code used.  Additionally, 
 * AlliedModders LLC grants this exception to all derivative works.  
 * AlliedModders LLC defines further exceptions, found in LICENSE.txt 
 * (as of this writing, version JULY-31-2007), or 
 * <http://www.sourcemod.net/license.php>.
 */

/*
 * ==================================================
 *                    Preprocessor
 * ==================================================
 */

/* Parser settings */
#pragma semicolon 1

/* Plugin information */
#define PLUGIN_FULLNAME                 "L4D2 Block Healing"                // Used when printing the plugin name anywhere
#define PLUGIN_AUTHOR                   "Buster \"Mr. Zero\" Nielsen"       // Author of the plugin
#define PLUGIN_DESCRIPTION              "Blocks Survivors from freezing other Survivors in place with their medkit" // Description of the plugin
#define PLUGIN_VERSION                  "1.1.3"                             // Version of the plugin
#define PLUGIN_URL                      "mrzerodk@gmail.com"                // URL associated with the project
#define PLUGIN_CVAR_PREFIX              "l4d2_blockhealing"                 // Prefix for plugin cvars

#define BLOCK_ATTACK_TIME 5.0 // How long attack1 is blocked after swapping away from a medkit
#define TIME_BEFORE_CAN_BREAK_HEAL 1.5 // How long healing action must last before the subject can break the heal

/*
 * ==================================================
 *                     Includes
 * ==================================================
 */

/*
 * --------------------
 *       Globals
 * --------------------
 */
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <l4d_stocks>
#tryinclude <vocalizetools>

/*
 * ==================================================
 *                     Variables
 * ==================================================
 */

/*
 * --------------------
 *       Private
 * --------------------
 */

static          bool   g_bIsBlockingMedkit[MAXPLAYERS + 1];
static          bool   g_bIsBlockingFire[MAXPLAYERS + 1];
static          bool   g_bIsBlockingUse[MAXPLAYERS + 1];
static          bool   g_bWasRecentlyOnLadder[MAXPLAYERS + 1];
static          bool   g_bHasOverrideAccess[MAXPLAYERS + 1];
static          bool   g_bIsBot[MAXPLAYERS + 1];
static          bool   g_bIsInGame[MAXPLAYERS + 1];

static          float  g_fStartHealingTime[MAXPLAYERS + 1];

#if defined _vocalizetools_included
static          bool   g_bWantsToBreakHeal[MAXPLAYERS + 1];
#endif

static          ConVar g_hBlockMedkitTime_Cvar;
static          ConVar g_hBlockMedkitTime_Ladder_Cvar;
static          ConVar g_hBlockUseTime_Cvar;

/*
 * ==================================================
 *                     Forwards
 * ==================================================
 */

public Plugin myinfo = 
{
    name           = PLUGIN_FULLNAME,
    author         = PLUGIN_AUTHOR,
    description    = PLUGIN_DESCRIPTION,
    version        = PLUGIN_VERSION,
    url            = PLUGIN_URL
}

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if (!IsDedicatedServer())
    {
        strcopy(error, err_max, "Plugin only support dedicated servers");
        return APLRes_Failure; // Plugin does not support client listen servers, return
    }

    char buffer[128];
    GetGameFolderName(buffer, 128);
    if (!StrEqual(buffer, "left4dead2", false))
    {
        strcopy(error, err_max, "Plugin only support Left 4 Dead 2");
        return APLRes_Failure; // Plugin does not support this game, return
    }

    return APLRes_Success;
}

/**
 * Called on plugin start.
 *
 * @noreturn
 */
public void OnPluginStart()
{
    char cvarName[128];
    Format(cvarName, sizeof(cvarName), "%s_%s", PLUGIN_CVAR_PREFIX, "version");

    char desc[128];
    Format(desc, sizeof(desc), "%s SourceMod Plugin Version", PLUGIN_FULLNAME);

    Handle cvar = CreateConVar(cvarName, PLUGIN_VERSION, desc, FCVAR_NOTIFY | FCVAR_DONTRECORD);
    SetConVarString(cvar, PLUGIN_VERSION);

    Format(cvarName, sizeof(cvarName), "%s_time", PLUGIN_CVAR_PREFIX);
    g_hBlockMedkitTime_Cvar = CreateConVar(cvarName, "5.0", "How long the healing Survivor is prohibit from taking out their medkit after the receiving Survivor breaks free of the heal. 0 to disable prohibition");

    Format(cvarName, sizeof(cvarName), "%s_time_ladder", PLUGIN_CVAR_PREFIX);
    g_hBlockMedkitTime_Ladder_Cvar = CreateConVar(cvarName, "10.0", "How long the healing Survivor is prohibit from taking out their medkit after trying to heal a fellow Survivor on a ladder. 0 to disable prohibition");

    Format(cvarName, sizeof(cvarName), "%s_time_use", PLUGIN_CVAR_PREFIX);
    g_hBlockUseTime_Cvar = CreateConVar(cvarName, "5.0", "How long the reviving Survivor is prohibit from using their use button after the incapacitated Survivor breaks free of the reviving. 0 to disable Survivors being able to break free of a revive");

    HookEvent("heal_end", OnHealEnd_Event);

    AutoExecConfig();
}

public void OnAllPluginsLoaded()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client)) continue;

        g_bIsBlockingMedkit[client] = false;
        g_bIsBlockingFire[client] = false;
        g_bIsBlockingUse[client] = false;
        g_bWasRecentlyOnLadder[client] = false;
        g_bHasOverrideAccess[client] = false;
        g_fStartHealingTime[client] = 0.0;
        g_bIsBot[client] = IsFakeClient(client);
        g_bIsInGame[client] = true;
#if defined _vocalizetools_included
        g_bWantsToBreakHeal[client] = false;
#endif
        if (IsClientAuthorized(client))
        {
        	g_bHasOverrideAccess[client] = CheckCommandAccess(client, "healoverride_access", ADMFLAG_ROOT, true);
        }
	}
}

public void OnClientPutInServer(int client)
{
    g_bIsBlockingMedkit[client] = false;
    g_bIsBlockingFire[client] = false;
    g_bIsBlockingUse[client] = false;
    g_bWasRecentlyOnLadder[client] = false;
    g_bHasOverrideAccess[client] = false;
    g_fStartHealingTime[client] = 0.0;
    g_bIsBot[client] = IsFakeClient(client);
    g_bIsInGame[client] = true;

#if defined _vocalizetools_included
    g_bWantsToBreakHeal[client] = false;
#endif
}

public void OnClientDisconnect(int client)
{
    g_bIsInGame[client] = false;
}

/**
 * Called once a client is authorized and fully in-game, and after all 
 * post-connection authorizations have been performed.
 *
 * @param client        Client index.
 * @noreturn
 */
public void OnClientPostAdminCheck(int client)
{
    g_bHasOverrideAccess[client] = CheckCommandAccess(client, "healoverride_access", ADMFLAG_ROOT, true);
}

public void OnHealEnd_Event(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client <= 0 || client > MaxClients) return;

    g_fStartHealingTime[client] = 0.0;
}

/**
 * Called when a clients movement buttons are being processed.
 *
 * @param client        Client index.
 * @param buttons       Copyback buffer containing the current commands.
 * @param impulse       Copyback buffer containing the current impulse command.
 * @param vel           Players desired velocity.
 * @param angles        Players desired view angles.
 * @param weapon        Entity index of the new weapon if player switches 
 *                      weapon, 0 otherwise.
 * @return              Plugin_Handled to block the commands from being 
 *                      processed, Plugin_Continue otherwise.
 */
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if (g_bIsBlockingFire[client] && buttons & IN_ATTACK)
    {
        buttons ^= IN_ATTACK;
        return Plugin_Continue;
    }

    if (g_bIsBlockingUse[client] && buttons & IN_USE)
    {
        buttons ^= IN_USE;
        return Plugin_Continue;
    }

    if (g_bIsBlockingMedkit[client] && weapon > 0 && IsValidEdict(weapon))
    {
        char classname[64];
        GetEdictClassname(weapon, classname, 64);
        if (StrEqual(classname, "weapon_first_aid_kit")) weapon = GetPlayerMainWeapon(client);
        return Plugin_Continue;
    }

    if (GetEntityMoveType(client) == MOVETYPE_LADDER && !g_bWasRecentlyOnLadder[client])
    {
        g_bWasRecentlyOnLadder[client] = true;
        CreateTimer(5.0, ResetRecentlyOnLadder_Timer, client);
    }

    if (L4D2_GetPlayerUseAction(client) == L4D2UseAction_Healing)
    {
        int subject = L4D2_GetPlayerUseActionTarget(client);
        if (subject <= 0 || subject > MaxClients || subject == client || !g_bIsInGame[subject] || g_bIsBot[subject])
        {
        	return Plugin_Continue;
        }

        if (g_fStartHealingTime[client] == 0.0) g_fStartHealingTime[client] = GetEngineTime();
        if (g_bHasOverrideAccess[client]) return Plugin_Continue;

#if defined _vocalizetools_included
        if (GetClientButtons(subject) & IN_JUMP || g_bWantsToBreakHeal[subject])
#else
        if (GetClientButtons(subject) & IN_JUMP)
#endif
        {
            if (GetEngineTime() - g_fStartHealingTime[client] < TIME_BEFORE_CAN_BREAK_HEAL)
            {
                return Plugin_Continue;
            }

            float blockTime = GetConVarFloat(g_hBlockMedkitTime_Cvar);
            if (blockTime > 0.0)
            {
#if defined _vocalizetools_included
                VocTools_MakePlayerVocalize(subject, "PlayerNo");
#endif
                g_bIsBlockingMedkit[client] = true;
                CreateTimer(blockTime, BlockMedkit_Timer, client, TIMER_FLAG_NO_MAPCHANGE);

                g_bIsBlockingFire[client] = true;
                CreateTimer(BLOCK_ATTACK_TIME, BlockFire_Timer, client);
                weapon = GetPlayerMainWeapon(client);
                return Plugin_Continue;
            }
        }
        else if (g_bWasRecentlyOnLadder[subject])
        {
            float blockTime = GetConVarFloat(g_hBlockMedkitTime_Ladder_Cvar);
            if (blockTime > 0.0)
            {
#if defined _vocalizetools_included
                VocTools_MakePlayerVocalize(subject, "PlayerNo");
#endif
                g_bIsBlockingMedkit[client] = true;
                CreateTimer(blockTime, BlockMedkit_Timer, client, TIMER_FLAG_NO_MAPCHANGE);

                g_bIsBlockingFire[client] = true;
                CreateTimer(BLOCK_ATTACK_TIME, BlockFire_Timer, client);
                weapon = GetPlayerMainWeapon(client);
                return Plugin_Continue;
            }
        }
    }

    if (buttons & IN_JUMP && !g_bIsBot[client] && L4D_IsPlayerIncapacitated(client))
    {
        int owner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner");
        if (owner <= 0 || owner > MaxClients || owner == client || !g_bIsInGame[owner]) return Plugin_Continue;

        if (g_bHasOverrideAccess[owner]) return Plugin_Continue;

        float blockTime = GetConVarFloat(g_hBlockUseTime_Cvar);
        if (blockTime > 0.0)
        {
            g_bIsBlockingUse[owner] = true;
            CreateTimer(blockTime, BlockUse_Timer, owner, TIMER_FLAG_NO_MAPCHANGE);
        }
        return Plugin_Continue;
    }

    return Plugin_Continue;
}

#if defined _vocalizetools_included
public VocTools_OnPlayerVocalize_Post(int client, const char[] vocalize, const char[] rawVocalize, bool isSmartlook)
{
    if (StrEqual(vocalize, "playerno"))
    {
        g_bWantsToBreakHeal[client] = true;
        CreateTimer(1.0, WantToBreakHeal_Timer, client, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action WantToBreakHeal_Timer(Handle timer, any client)
{
    g_bWantsToBreakHeal[client] = false;
    return Plugin_Stop;
}
#endif

public Action BlockUse_Timer(Handle timer, any client)
{
    g_bIsBlockingUse[client] = false;
    return Plugin_Stop;
}

public Action BlockFire_Timer(Handle timer, any client)
{
    g_bIsBlockingFire[client] = false;
    return Plugin_Stop;
}

public Action BlockMedkit_Timer(Handle timer, any client)
{
    g_bIsBlockingMedkit[client] = false;
    return Plugin_Stop;
}

public Action ResetRecentlyOnLadder_Timer(Handle timer, any client)
{
    g_bWasRecentlyOnLadder[client] = false;
    return Plugin_Stop;
}

/*
 * ==================================================
 *                    Private API
 * ==================================================
 */
static int GetPlayerMainWeapon(int client)
{
    int weapon = GetPlayerWeaponSlot(client, view_as<int>(L4DWeaponSlot_Primary));
    if (weapon <= 0 || !IsValidEdict(weapon))
    {
        weapon = GetPlayerWeaponSlot(client, view_as<int>(L4DWeaponSlot_Secondary));
        if (weapon <= 0 || !IsValidEdict(weapon))
        {
            weapon = 0;
        }
    }
    return weapon;
}