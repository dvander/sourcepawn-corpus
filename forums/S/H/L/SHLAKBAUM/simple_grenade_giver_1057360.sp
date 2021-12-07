/*
* 
*	Description:
*	Plugin gives a grenades for Sniper and Machine Gunner, and allows the admin give a grenade any player.
* 
*	Commands:
*	sm_give_grenade <playername> - Give a grenade player
* 
*	Changelog:
*	v0.2
* 	- First Release
*	v0.2.1
*	- Fixed command name (thanks a.aqua)
* 	
*/

#include <sourcemod>
#include <sdktools>

#define VERSION "0.2.1"

new g_iTeam

public Plugin:myinfo = 
{
	name = "Simple Grenade Giver",
	author = "SHLAKBAUM",
	description = "Plugin gives a grenades for Sniper and Machine Gunner, and allows the admin give a grenade any player.",
	version = VERSION,
	url = "http://www.allcsmods.ru"
}

public OnPluginStart()
{
	CreateConVar("sgg_version", VERSION, "Simple Grenade Giver", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegAdminCmd ("sm_give_grenade", GiveClientGrenadeCmd, ADMFLAG_KICK)
	
	HookEvent("player_spawn", PlayerSpawnEvent)
}


public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	CreateTimer(0.1, GiveClientGreade, client)
}

public Action:GiveClientGreade(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		g_iTeam = GetClientTeam(client)
		
		new iClass = GetEntProp(client, Prop_Send, "m_iPlayerClass")
		
		if ((iClass == 3) || (iClass == 4))
		{
			if (g_iTeam == 2) 
			{
				GivePlayerItem(client, "weapon_frag_us")
			}
			
			if (g_iTeam == 3) 
			{
				GivePlayerItem(client, "weapon_frag_ger")
			}
		}
	}
	return Plugin_Handled
}

public Action:GiveClientGrenadeCmd(client, args)
{
	new String:szArg[ 32 ]
	GetCmdArg(1, szArg, sizeof szArg)
	
	new eTarget = FindTarget(client, szArg)
	
	if(eTarget == -1)
	{
		return Plugin_Handled
	}
	if(!IsPlayerAlive(eTarget))
	{
		return Plugin_Handled
	}
	
	new String:szPlayerName[ 32 ], String:szAdminName[ 32 ]
	
	GetClientName(client, szAdminName, 31)
	GetClientName(eTarget, szPlayerName, 31)
	
	g_iTeam = GetClientTeam(client)
	
	if(g_iTeam == 2) 
	{
		GivePlayerItem(eTarget, "weapon_frag_us")
	}

	if(g_iTeam == 3) 
	{
		GivePlayerItem(eTarget, "weapon_frag_ger")
	}
	
	PrintToChatAll("Admin %s gave a grenade player %s", szAdminName, szPlayerName)
	
	return Plugin_Handled
}