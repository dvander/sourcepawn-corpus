/**
 * vim: set ts=4 :
 * =============================================================================
 * Admin Spec ESP
 * Allows admin spectate enhancements
 * Code by Liam 7.17.2008
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

/* Credits
 *
 * The idea for this came from KoST's CS Admin Spectator Plugin,
 * and Knagg0's CSS Meta-Mod Spectator Plugin
 * Observer ideas / framework came from Whitewolf's Observe Plugin
 * Laser entity framework came from Bonaparte's CS:S Laser Tag plugin.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"

new bool:g_SpectateEnable[MAXPLAYERS + 1];
new g_SpectateTarget[MAXPLAYERS + 1];
new g_ObserverTargetOffset = -1;
new g_Sprite;
new g_glow;
new g_glow2;

// colors - borrowed from funcommands.sp
new blueColor[4] =  { 0, 0, 255, 255 };
new redColor[4] =  { 255, 0, 0, 255 };

new Float:g_Life = 0.1;
new Float:g_Width = 100.0;

public Plugin:myinfo = 
{
	name = "Admin Spectate ESP", 
	author = "Liam", 
	description = "Admin spectate information.", 
	version = VERSION, 
	url = "http://www.wcugaming.org"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("spec_version", VERSION, "Current version of Admin Spectate ESP Plugin", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	RegisterOffsets();
	RegisterCommands();
	RegisterHooks();
	g_glow = PrecacheModel("sprites/redglow1.vmt");
}
public OnMapStart()
{
	g_glow = PrecacheModel("sprites/redglow1.vmt");
	g_glow2 = PrecacheModel("sprites/blueglow1.vmt");
}

RegisterOffsets()
{
	g_ObserverTargetOffset = FindSendPropInfo("CBasePlayer", "m_hObserverTarget");
	g_Sprite = PrecacheModel("materials/sprites/laser.vmt");
	
	if (g_ObserverTargetOffset == -1)
	{
		SetFailState("Unable to find m_hObserverTarget offset. Contact the author.");
	}
}

RegisterCommands()
{
	RegAdminCmd("sm_esp", Command_Spectate, ADMFLAG_GENERIC, "Enables or disables the spectate option.");
}

RegisterHooks()
{
	HookEvent("round_end", Event_RoundEnd);
}

public Action:Command_Spectate(client, args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	new team_client = GetClientTeam(client);
	if (team_client != 0 && team_client != 1)
		return Plugin_Handled;
	
	decl String:f_TargetName[MAX_NAME_LENGTH];
	new f_Target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	
	//    GetCmdArg(1, f_TargetName, sizeof(f_TargetName));
	//    f_Target = FindTarget(client, f_TargetName);//, true, true);
	//    PrintToChat(client, "Cible : %s.", f_TargetName);
	//    PrintToChat(client, "Cible num client : %i.", f_Target);
	
	if (f_Target == -1)
		return Plugin_Handled;
	
	if (!IsPlayerAlive(f_Target))
	{
		PrintToChat(client, "You cannot spectate someone who is dead.");
		return Plugin_Handled;
	}
	
	if (g_SpectateEnable[client] && f_Target == g_SpectateTarget[client])
	{
		StopSpectating(client);
		PrintToChat(client, "You stop spectating %s.", f_TargetName);
		return Plugin_Handled;
	}
	
	if (IsPlayerAlive(client))
		ClientCommand(client, "kill");
	
	StartSpectating(client, f_Target);
	return Plugin_Handled;
}

StartSpectating(client, target)
{
	SetClientObserve(client, target);
	g_SpectateEnable[client] = true;
	g_SpectateTarget[client] = target;
	CreateTimer(0.1, Timer_RefreshView, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

StopSpectating(client)
{
	g_SpectateEnable[client] = false;
	g_SpectateTarget[client] = 0;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new f_MaxClients = MaxClients;
	
	for (new i = 1; i < f_MaxClients; i++)
	{
		StopSpectating(i);
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	StopSpectating(client);
	return true;
}

public OnClientDisconnect(client)
{
	StopSpectating(client);
}

public Action:Timer_RefreshView(Handle:timer, any:client)
{
	if (!IsClientConnected(client) || !IsClientInGame(client))
	{
		StopSpectating(client);
		return Plugin_Handled;
	}
	
	new target = GetClientObserve(client);
	
	if (target == -1 || target == 0 || !IsClientConnected(target)
		 || !IsClientInGame(target) || !IsPlayerAlive(target)
		 || target != g_SpectateTarget[client])
	{
		StopSpectating(client);
		return Plugin_Handled;
	}
	else
	{
		new Float:f_TargetOrigin[3], Float:f_OthersOrigin[3];
		new f_Team, Float:f_Width = g_Width;
		new f_MaxClients = MaxClients;
		decl String:f_Name[MAX_NAME_LENGTH], String:f_SteamID[32];
		
		GetClientName(target, f_Name, sizeof(f_Name));
		GetClientAuthId(target, AuthId_Engine, f_SteamID, sizeof(f_SteamID));
		GetClientAbsOrigin(target, f_TargetOrigin);
		if (GetClientButtons(client) & IN_DUCK)
			f_TargetOrigin[2] += 20;
		else
			f_TargetOrigin[2] += 40;
		
		for (new i = 1; i < f_MaxClients; i++)
		{
			if (!IsClientConnected(i) || !IsClientInGame(i) || !IsPlayerAlive(i) || target == i)
				continue;
			
			GetClientAbsOrigin(i, f_OthersOrigin);
			f_OthersOrigin[2] += 50;
			f_Team = GetClientTeam(i);
			f_Width = ((g_Width / GetVectorDistance(f_TargetOrigin, f_OthersOrigin)) * 900.0);

			
			switch (f_Team)
			{
				case 3:
				TE_SetupBeamPoints(f_TargetOrigin, f_OthersOrigin, g_Sprite, 0, 0, 0, g_Life, 0.1, 0.0, 1, 0.0, blueColor, 0);
				//				TE_SetupBeamPoints(f_TargetOrigin, f_OthersOrigin, g_Sprite, 0, 0, 0, g_Life, f_Width, 0.0, 1, 0.0, blueColor, 0);
				
				case 2:
				TE_SetupBeamPoints(f_TargetOrigin, f_OthersOrigin, g_Sprite, 0, 0, 0, g_Life, 0.1, 0.0, 1, 0.0, redColor, 0);
				//				TE_SetupBeamPoints(f_TargetOrigin, f_OthersOrigin, g_Sprite, 0, 0, 0, g_Life, f_Width, 0.0, 1, 0.0, redColor, 0);
			}
			TE_SendToClient(client);
			
			//			GetPlayerEye(target, f_OthersOrigin);
			//			TE_SetupBeamPoints(f_TargetOrigin, f_OthersOrigin, g_Sprite, 0, 0, 0, g_Life, 1.0, 1.0, 1, 0.0, whiteColor, 0);
			//			TE_SendToClient(client);
			
			PrintHintText(client, "%s\n\r%s", f_Name, f_SteamID);
		}
		return Plugin_Continue;
	}
}

// This code was borrowed from WhiteWolf's Observe plugin
SetClientObserve(client, target)
{
	decl String:name[MAX_NAME_LENGTH];
	
	GetClientName(target, name, sizeof(name));
	SetEntDataEnt2(client, g_ObserverTargetOffset, target, true);
	PrintToChat(client, "You are now observing %s.", name);
}

GetClientObserve(client)
{
	return GetEntDataEnt2(client, g_ObserverTargetOffset);
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients;
}
bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	else
	{
		return false;
	}
} 
