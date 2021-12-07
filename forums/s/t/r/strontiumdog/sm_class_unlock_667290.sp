//
// SourceMod Script
//
// Developed by <eVa>Dog
// August 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// Allows certain classes to be unlocked as server numbers grow

//
// Do not edit code without permission.
// If you do change the code, you do so at your own risk.
//


#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.103"

new Handle:g_Cvar_Class[10] ;
new Handle:g_Cvar_AdminImmunity = INVALID_HANDLE ;
new Handle:g_Cvar_Enable = INVALID_HANDLE ;

new g_AvailableClass;

new g_PreviousClass[MAXPLAYERS+1];

new String:ClassName[10][16];

public Plugin:myinfo = 
{
	name = "TF2 Class Unlock",
	author = "<eVa>Dog",
	description = "Unlock classes as players join the server",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
};

public OnPluginStart()
{
	CreateConVar("sm_class_unlock_version", PLUGIN_VERSION, "Version of TF2 Class Unlock", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_Cvar_Class[1]  = CreateConVar("sm_class_unlock_scout", "0", "- number of players on server needed to unlock Scout");
	g_Cvar_Class[2]  = CreateConVar("sm_class_unlock_sniper", "0", "- number of players on server needed to unlock Sniper");
	g_Cvar_Class[3]  = CreateConVar("sm_class_unlock_soldier", "0", "- number of players on server needed to unlock Soldier");
	g_Cvar_Class[4]  = CreateConVar("sm_class_unlock_demo", "0", "- number of players on server needed to unlock Demo");
	g_Cvar_Class[5]  = CreateConVar("sm_class_unlock_medic", "0", "- number of players on server needed to unlock Medic");
	g_Cvar_Class[6]  = CreateConVar("sm_class_unlock_heavy", "0", "- number of players on server needed to unlock Heavy");
	g_Cvar_Class[7]  = CreateConVar("sm_class_unlock_pyro", "0", "- number of players on server needed to unlock Pyro");
	g_Cvar_Class[8]  = CreateConVar("sm_class_unlock_spy", "0", "- number of players on server needed to unlock Spy");
	g_Cvar_Class[9]  = CreateConVar("sm_class_unlock_engineer", "0", "- number of players on server needed to unlock Engineer");
	
	g_Cvar_AdminImmunity = CreateConVar("sm_class_unlock_immunity", "0", "- when enabled, admins can access locked classes");
	g_Cvar_Enable        = CreateConVar("sm_class_unlock", "1", "- Enables/Disables the plugin");

	HookEvent("player_changeclass", ChangeClassEvent, EventHookMode_Pre);
}

public OnEventShutdown()
{
	UnhookEvent("player_changeclass", ChangeClassEvent);
}

public OnMapStart()
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		ClassName[1] = "Scout";
		ClassName[2] = "Sniper";
		ClassName[3] = "Soldier";
		ClassName[4] = "Demo";
		ClassName[5] = "Medic";
		ClassName[6] = "Heavy";
		ClassName[7] = "Pyro";
		ClassName[8] = "Spy";
		ClassName[9] = "Engineer";

		CheckClassAvailability();
	}
}

public Action:ChangeClassEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_Cvar_Enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		if ((GetUserFlagBits(client) & ADMFLAG_GENERIC) && (GetConVarInt(g_Cvar_AdminImmunity) == 1))
		{
			return Plugin_Continue;
		}
		else if((GetUserFlagBits(client) & ADMFLAG_ROOT) && (GetConVarInt(g_Cvar_AdminImmunity) == 1))
		{
			return Plugin_Continue;
		}
		else
		{
			new class  = GetEventInt(event, "class");
			
			new CurrentPlayers = GetClientCount();
			CheckClassAvailability();
			
			if ((class > 0) && (g_AvailableClass > 0))
			{
				new ClassLimit = GetConVarInt(g_Cvar_Class[class]);
				
				if (CurrentPlayers <= ClassLimit)
				{
					PrintCenterText(client, "%s Class LOCKED: Requires %i players on server", ClassName[class], ClassLimit);
					TF2_SetPlayerClass(client, TFClassType:g_PreviousClass[client]);
					new team   = GetClientTeam(client);
					ShowVGUIPanel(client, team == 3 ? "class_blue" : "class_red");
				}
				else
				{
					g_PreviousClass[client] = class;
				}
			}
			
			if (g_PreviousClass[client] == 0)
			{
				g_PreviousClass[client] = g_AvailableClass;
			}
		}
	}
	return Plugin_Continue;
}

CheckClassAvailability()
{
	g_AvailableClass = 0;
	for (new i = 1; i <= 9; i++)
	{
		if (GetConVarInt(g_Cvar_Class[i]) == 0)
		{
			g_AvailableClass = i;
			break;
		}
	}
	
	if (g_AvailableClass == 0)
	{
		PrintToServer("[SM] ClassUnlock Error! You must set at least one class to zero");
		LogError("[SM] ClassUnlock Error! You must set at least one class to zero");
	}
}
