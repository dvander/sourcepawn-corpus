#include <sourcemod>
#include <tf2_stocks>

new Handle:g_hRegenerationTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
new Handle:g_Cvar_PluginEnable = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Unlimited Mod",
	author = "John B.",
	description = "This plugin creates a regeneration (ammo, metal, cloak) timer for joined players",
	version = "1.0.0",
	url = "www.sourcemod.net",
}

public OnPluginStart()
{
	g_Cvar_PluginEnable = CreateConVar("sm_unlimitedmod_enable", "1", "0 disable / 1 enable", _, true, 0.0, true, 1.0);
	AutoExecConfig(true, "plugin.unlimitedmod");

	if(GetConVarInt(g_Cvar_PluginEnable) == 1)
	{
		HookEvent("player_changeclass", Event_PlayerChangeClass);
	}
	else
	{
		//Do Nothing
	}
}

public OnClientDisconnect(client)
{
	if(g_hRegenerationTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(g_hRegenerationTimer[client]);
		g_hRegenerationTimer[client] = INVALID_HANDLE;
	}
}

public Action:Event_PlayerChangeClass(Handle:event, const String:name[], bool:dontBrodcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	PrintToChat(client, "\x04[Unlimited Mod]: \x03Unlimited mode enabled.");
	
	if(g_hRegenerationTimer[client] == INVALID_HANDLE)
	{
		g_hRegenerationTimer[client] = CreateTimer(1.0, Regenerate, client, TIMER_REPEAT);
	}	
	else
	{
		//Do Nothing
	}	
	
	return Plugin_Continue;
}

public Action:Regenerate(Handle:timer, any:client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);

	switch(class)
	{
		case TFClass_Scout:
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 32);
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 36);
		}
		case TFClass_Soldier:
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 16);
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 32);
		}
		case TFClass_Pyro:
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 200);
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 32);
		}
		case TFClass_DemoMan:
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 16);
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 24);
		}
		case TFClass_Heavy:
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 200);
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 32);
		}
		case TFClass_Engineer:
		{
			SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 200, 4, true);
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 200);
		}
		case TFClass_Medic:
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 150);
		}
		case TFClass_Sniper:
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 4, 25);
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 75);
		}
		case TFClass_Spy:
		{
			SetEntData(client, FindSendPropInfo("CTFPlayer", "m_iAmmo") + 8, 24);
			SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 150.0);
		}
	}
	return Plugin_Continue;
}