/**
 * vim: set ts=4 :
 * =============================================================================
 * AFK Manager
 * Handles AFK Players
 *
 * SourceMod (C)2004-2007 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION "2.1"

// global variables
new Float:g_Position[MAXPLAYERS+1][3];
new g_TimeAFK[MAXPLAYERS+1];

// cvars
new Handle:g_Cvar_Enabled = INVALID_HANDLE;
new Handle:g_Cvar_MinPlayersMove = INVALID_HANDLE;
new Handle:g_Cvar_MinPlayersKick = INVALID_HANDLE;
new Handle:g_Cvar_AdminsImmune = INVALID_HANDLE;
new Handle:g_Cvar_MoveSpec = INVALID_HANDLE;
new Handle:g_Cvar_TimeToMove = INVALID_HANDLE;
new Handle:g_Cvar_TimeToKick = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "AFK Manager",
    author = "Liam",
    description = "Handles AFK Players",
    version = VERSION,
    url = "http://www.wcugaming.org"
};

public OnPluginStart( )
{
    LoadTranslations("common.phrases");
    RegisterHooks( );
    RegisterCvars( );
    AutoExecConfig(true, "afk_manager");
    
}

public OnMapStart( )
{
    new f_MaxPlayers = GetMaxClients( );

    for(new i = 1; i <= f_MaxPlayers; i++)
        g_TimeAFK[i] = 0;

    CreateTimer(7.0, Timer_UpdateView, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(10.0, Timer_CheckPlayers, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

RegisterHooks( )
{
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_TimeAFK[client] = 0;
}

RegisterCvars( )
{
    CreateConVar("sm_afk_version", VERSION, 
        "Current version of the AFK Manager", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_Cvar_Enabled = CreateConVar("sm_afkenable", "1", "Is the AFK manager enabled or disabled? [0 = FALSE, 1 = TRUE]");
    g_Cvar_MinPlayersMove = CreateConVar("sm_minplayersmove", "4", "Minimum amount of connected clients needed to move AFK clients to spec.");
    g_Cvar_MinPlayersKick = CreateConVar("sm_minplayerskick", "6", "Minimum amount of connected clients needed to kick AFK clients.");
    g_Cvar_AdminsImmune = CreateConVar("sm_adminsimmune", "1", "Admins immune to being kicked? [0 = FALSE, 1 = TRUE]");
    g_Cvar_MoveSpec = CreateConVar("sm_movespec", "1", "Move AFK clients to spec before kicking them? [0 = FALSE, 1 = TRUE]");
    g_Cvar_TimeToMove = CreateConVar("sm_timetomove", "60.0", "Time in seconds before moving an AFK player.");
    g_Cvar_TimeToKick = CreateConVar("sm_timetokick", "120.0", "Time in seconds before kicking an AFK player.");
}

public Action:Timer_UpdateView(Handle:Timer)
{
    new f_MaxClients = GetMaxClients( );

    for(new i = 1; i <= f_MaxClients; i++)
    {
        if(!IsClientConnected(i) || !IsClientInGame(i)
            || IsFakeClient(i))
            continue;

        GetPlayerEye(i, g_Position[i]);
    }
}

public Action:Timer_CheckPlayers(Handle:Timer)
{
    if(GetConVarInt(g_Cvar_Enabled) == 0)
        return Plugin_Stop;

    if(GetConVarInt(g_Cvar_MinPlayersMove) >= GetClientCount( ))
        return Plugin_Continue;

    new f_MaxPlayers = GetMaxClients( );

    for(new i = 1; i < f_MaxPlayers; i++)
    {
        if(!IsClientConnected(i) || !IsClientInGame(i)
            || IsFakeClient(i))
            continue;

        CheckForAFK(i);
        HandleAFKClient(i);
    }
    return Plugin_Continue;
}

CheckForAFK(client)
{
    new Float:f_Loc[3], bool:f_SamePlace;
    new f_Team = GetClientTeam(client);

    if(f_Team > 1)
    {
        GetPlayerEye(client, f_Loc);

        for(new i = 0; i < 3; i++)
        {
            if(g_Position[client][i] == f_Loc[i])
                f_SamePlace = true;
            else
                f_SamePlace = false;
        }
    }

    if(f_SamePlace || f_Team < 2) // 1 == spec on TF2 and CSS, 0 == unchosen class for TF2
    {
        g_TimeAFK[client]++;
    }
    else
    {
        g_TimeAFK[client] = 0;
    }
}

HandleAFKClient(client)
{
    new f_SpecTime = RoundToZero(GetConVarFloat(g_Cvar_TimeToMove)) / 10;
    new f_KickTime = RoundToZero(GetConVarFloat(g_Cvar_TimeToKick)) / 10;
    new f_MoveSpec = GetConVarInt(g_Cvar_MoveSpec);
    new f_MinKick = GetConVarInt(g_Cvar_MinPlayersKick);
    new f_ClientCount = GetClientCount(false);
    decl String:f_Name[MAX_NAME_LENGTH];

    GetClientName(client, f_Name, sizeof(f_Name));

    if(f_MoveSpec == 1 && g_TimeAFK[client] < f_KickTime 
        && g_TimeAFK[client] >= f_SpecTime)
    {
        new f_Team = GetClientTeam(client);

        switch(f_Team)
        {
            case 2, 3:
            {
                PrintToChatAll("%s was moved to spectate for being AFK.", f_Name);
                LogAction(0, -1, "\"%L\" was moved to spectate for being AFK too long.", client);
                ChangeClientTeam(client, 1);                
            }

            case 0:
            {
                PrintToChatAll("%s was kicked for being AFK.", f_Name);
                LogAction(0, -1, "\"%L\" was kicked for being AFK too long.", client);
                KickClient(client, "You were AFK for too long.");                
            }
        }
        return;
    }

    LogAction(0, -1, "CVar_MinKick: %d - ClientCount: %d", f_MinKick, f_ClientCount);

    if(g_TimeAFK[client] >= f_KickTime 
        && f_MinKick <= f_ClientCount 
        && !IsAdmin(client))
    {
        PrintToChatAll("%s was kicked for being AFK.", f_Name);
        LogAction(0, -1, "\"%L\" was kicked for being AFK too long.", client);
        KickClient(client, "You were AFK for too long.");        
    }
}

// This code was borrowed from Nican's spraytracer
bool:GetPlayerEye(client, Float:pos[3])
{
	new Float:vAngles[3], Float:vOrigin[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	
	if(TR_DidHit(trace))
	{
	 	//This is the first function i ever saw that anything comes before the handle
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
    return entity > GetMaxClients( );
}

bool:IsAdmin(client)
{
    LogAction(0, -1, "Checking for admins.");
    if(GetConVarInt(g_Cvar_AdminsImmune) == 0)
    {
        LogAction(0, -1, "Admins are not immune to being kicked.");
        return false;
    }

    new AdminId:admin = GetUserAdmin(client);
    decl String:name[MAX_NAME_LENGTH];

    GetClientName(client, name, sizeof(name));
    LogAction(0, -1, "Checking for valid AdminID: Found: %d for client %s", _:admin, name);

    if(admin == INVALID_ADMIN_ID)
    {
        LogAction(0, -1, "Client %s has an invalid Admin ID.", name);
        return false;
    }
    LogAction(0, -1, "Client %s has a valid Admin ID and is immune.", name);
    return true;
}