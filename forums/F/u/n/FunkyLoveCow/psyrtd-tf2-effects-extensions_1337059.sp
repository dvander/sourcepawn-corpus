#include <sourcemod>
#include <psyrtd>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_NAME "Extended TF2 RTD Effects"
#define PLUGIN_VERSION "0.0.1"
#define PLUGIN_DESC "Adds several more RTD effects for TF2"

public Plugin:myinfo = 
{
	name = "psyRTD TF2 Effects; Strip to Melee and Infinate Cloak",
	author = "FunkyLoveCow; Inspiration from pheadxdll's RTD plugin",
	description = "TF2 effects module for psyRTD",
	version = "0.0.1",
	url = "http://www.sourcemod.net"
}

new bool:g_bPsyRTDLoaded;
new Handle:g_EffectTimers[MAXPLAYERS+1] = INVALID_HANDLE;

// Cloak
new Handle:g_cvCloakEnable;
new Handle:g_cvCloakDuration;
new g_eidCloak = -1;
new g_cloakOffset;

// Melee
new Handle:g_cvStripToMeleeEnable;

public OnPluginStart()
{
	g_cvCloakEnable = CreateConVar("psyrtd_cloak_enable", "1", "Enable rolling Infinate Cloak", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_cvCloakDuration = CreateConVar("psyrtd_cloak_duration", "20", "Duration of Infinate Cloak", FCVAR_PLUGIN, true, 1.0);
	
	g_cvStripToMeleeEnable = CreateConVar("psyrtd_melee_enable", "1", "Enable rolling melee only", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "psyrtd_tf2");
}

public OnAllPluginsLoaded()
{
	if (!LibraryExists("psyrtd"))
	{
		SetFailState("psyRTD Not Found!");
	}
	
		// OnLibraryAdded sneaking in before this might be possible(?)
	if (!g_bPsyRTDLoaded)
	{
		g_bPsyRTDLoaded = true;
		InitEffects();
		
		g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
	}
}

InitEffects()
{
	if (psyRTD_GetGame() != psyRTDGame_TF)
	{
		SetFailState("This module only supports TF2");
	}
	
	g_eidCloak = psyRTD_RegisterTimedEffect(psyRTDEffectType_Good, "Infinate Cloak", GetConVarFloat(g_cvCloakDuration), DoInfinateCloak, EndInfinateCloak);
	psyRTD_RegisterEffect(psyRTDEffectType_Bad, "Strip to Melee", DoMeleeStrip);
	
}

public psyRTDAction:DoInfinateCloak(client)
{
	if (psyRTD_GetGame() == psyRTDGame_FOF)
	{
		// No one plays this game so I didn't test it.
		// Let the core re-roll and choose another effect.
		return psyRTD_Reroll;
	}
	
	if (!GetConVarBool(g_cvCloakEnable))		
	{
		return psyRTD_Reroll;
	}
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(class != TFClass_Spy)		// If not a spy, reroll
	{
		return psyRTD_Reroll;
	}
	
	new userid = GetClientUserId(client);
	
	Timer_Cloak(INVALID_HANDLE, userid);
	g_EffectTimers[client] = CreateTimer(1.0, Timer_Cloak, userid, TIMER_REPEAT);
	
	return psyRTD_Continue;
}

public EndInfinateCloak(client, psyRTDEffectEndReason:reason)
{
	if (g_EffectTimers[client] != INVALID_HANDLE)
	{
		CloseHandle(g_EffectTimers[client]);
	}
	g_EffectTimers[client] = INVALID_HANDLE;
}

public psyRTDAction:DoMeleeStrip(client)
{
	if (psyRTD_GetGame() == psyRTDGame_FOF)
	{
		// No one plays this game so I didn't test it.
		// Let the core re-roll and choose another effect.
		return psyRTD_Reroll;
	}
	
	if (!GetConVarBool(g_cvStripToMeleeEnable))		
	{
		return psyRTD_Reroll;
	}
	
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	for (new i = 0; i <= 5; i++)
	{
		if (i != 2)
		{
			if (class != TFClass_Spy)
			{
				TF2_RemoveWeaponSlot(client, i);
			}
			else
			{
				if (i != 4)
				{
					TF2_RemoveWeaponSlot(client, i);
				}
			}
		}
	}
	
	new weapon = GetPlayerWeaponSlot(client, 2);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	
	return psyRTD_Continue;
}

// *********************** Timers Below Here *********************** //
public Action:Timer_Cloak(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client == 0 || !IsClientInGame(client))
	{
		g_EffectTimers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	SetEntDataFloat(client, g_cloakOffset, 100.0);
	
	return Plugin_Continue;
}

