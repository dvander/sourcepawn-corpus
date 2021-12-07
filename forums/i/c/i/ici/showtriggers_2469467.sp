#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

// Notify me if I miss a semicolon
#pragma semicolon 1 

// Entity is completely ignored by the client. 
// Can cause prediction errors if a player proceeds to collide with it on the server.
// https://developer.valvesoftware.com/wiki/Effects_enum
#define EF_NODRAW 32

int g_Offset_m_fEffects = -1;
bool g_bShowTriggers[MAXPLAYERS+1];

// Used to determine whether to avoid unnecessary SetTransmit hooks
int g_iTransmitCount;

public Plugin myinfo =
{
	name = "Show Triggers",
	author = "ici",
	description = "Make trigger brushes visible.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/1ci"
};

public void OnPluginStart()
{
	g_Offset_m_fEffects = FindSendPropInfo("CBaseEntity", "m_fEffects");
	
	if (g_Offset_m_fEffects == -1)
		SetFailState("[Show Triggers] Could not find CBaseEntity:m_fEffects");
	
	CreateConVar("showtriggers_version", PLUGIN_VERSION, "Showtriggers version", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	RegConsoleCmd("sm_showtriggers", SM_ShowTriggers, "Command to dynamically toggle trigger visibility");
}

public Action SM_ShowTriggers(int client, int args)
{
	// Can't use this cmd from within the server console
	if (!client)
		return Plugin_Handled;
	
	g_bShowTriggers[client] = !g_bShowTriggers[client];
	
	if (g_bShowTriggers[client]) {
		++g_iTransmitCount;
		PrintToChat(client, "Showing trigger brushes.");
	} else {
		--g_iTransmitCount;
		PrintToChat(client, "Stopped showing trigger brushes.");
	}
	
	transmitTriggers( g_iTransmitCount > 0 );
	return Plugin_Handled;
}

public void OnClientDisconnect_Post(int client)
{
	// Has this player been still using the feature before he left?
	if (g_bShowTriggers[client])
	{
		g_bShowTriggers[client] = false;
		--g_iTransmitCount;
		transmitTriggers( g_iTransmitCount > 0 );
	}
}

// https://forums.alliedmods.net/showthread.php?p=2423363
// https://sm.alliedmods.net/api/index.php?fastload=file&id=4&
// https://developer.valvesoftware.com/wiki/Networking_Entities
// https://github.com/ValveSoftware/source-sdk-2013/blob/master/sp/src/game/server/triggers.cpp#L58
void transmitTriggers(bool transmit)
{
	// Hook only once
	static bool s_bHooked = false;
	
	// Have we done this before?
	if (s_bHooked == transmit)
		return;
	
	// Loop through entities
	char sBuffer[8];
	int lastEdictInUse = GetEntityCount();
	for (int entity = MaxClients+1; entity <= lastEdictInUse; ++entity)
	{
		if ( !IsValidEdict(entity) )
			continue;
		
		// Is this entity a trigger?
		GetEdictClassname(entity, sBuffer, sizeof(sBuffer));
		if (strcmp(sBuffer, "trigger") != 0)
			continue;
		
		// Is this entity's model a VBSP model?
		GetEntPropString(entity, Prop_Data, "m_ModelName", sBuffer, 2);
		if (sBuffer[0] != '*') {
			// The entity must have been created by a plugin and assigned some random model.
			// Skipping in order to avoid console spam.
			continue;
		}
		
		// Get flags
		int effectFlags = GetEntData(entity, g_Offset_m_fEffects);
		int edictFlags = GetEdictFlags(entity);
		
		// Determine whether to transmit or not
		if (transmit) {
			effectFlags &= ~EF_NODRAW;
			edictFlags &= ~FL_EDICT_DONTSEND;
		} else {
			effectFlags |= EF_NODRAW;
			edictFlags |= FL_EDICT_DONTSEND;
		}
		
		// Apply state changes
		SetEntData(entity, g_Offset_m_fEffects, effectFlags);
		ChangeEdictState(entity, g_Offset_m_fEffects);
		SetEdictFlags(entity, edictFlags);
		
		// Should we hook?
		if (transmit)
			SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
		else
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit);
	}
	s_bHooked = transmit;
}

public Action Hook_SetTransmit(int entity, int client)
{
	if (!g_bShowTriggers[client])
	{
		// I will not display myself to this client :(
		return Plugin_Handled;
	}
	return Plugin_Continue;
}