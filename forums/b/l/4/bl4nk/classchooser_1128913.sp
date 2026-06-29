#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

// Global Definitions
#define PLUGIN_VERSION "2.0.0"

new bool:g_bChangingClass[MAXPLAYERS+1];
new Handle:g_hCvarEnable;
new Handle:g_hCvarClass;

public Plugin:myinfo =
{
	name = "ClassChooser",
	author = "bl4nk",
	description = "Choose a class to spawn everyone as",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_classchooser_version", PLUGIN_VERSION, "ClassChooser Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarEnable = CreateConVar("sm_classchooser_enable", "0", "Enables/Disables the ClassChooser plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCvarClass = CreateConVar("sm_classchooser_class", "random", "Class for people to spawn as", FCVAR_PLUGIN);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnClientPutInserver(iClient)
{
	g_bChangingClass[iClient] = false;
}

public Event_PlayerSpawn(Handle:hEvent, const String:sEventName[], bool:bDontBroadcast)
{
	if (!IsPluginEnabled())
	{
		return;
	}
	
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (g_bChangingClass[iClient])
	{
		g_bChangingClass[iClient] = false;
		return;
	}

	decl String:sClasses[32];
	GetConVarString(g_hCvarClass, sClasses, sizeof(sClasses));

	new TFClassType:iClass = TF2_GetClass(sClasses);
	new TFClassType:iPlayerClass = TF2_GetPlayerClass(iClient);
	
	if (iClass && iClass == iPlayerClass)
	{
		return;
	}
	else if (iClass == TFClass_Unknown)
	{
		if (strcmp(sClasses, "random", false) == 0)
		{
			iClass = TFClassType:GetRandomInt(_:TFClass_Scout, _:TFClass_Engineer);
		}
		else
		{
			return;
		}
	}
	
	g_bChangingClass[iClient] = true;
	
	TF2_SetPlayerClass(iClient, iClass);
	TF2_RespawnPlayer(iClient);
}

bool:IsPluginEnabled()
{
	return GetConVarInt(g_hCvarEnable);
}