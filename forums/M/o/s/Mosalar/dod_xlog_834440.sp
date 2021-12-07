/*
* DoD XtraLog
* 
* Adds messaging and log events for alt weapon position kills so 
* stats packages can track and award them. Both psychostats and HLStatsXCE
* can track these events and use for awards/bonuses.
* 
* IE:
* Single shot on the support class..
* IronSight for the rifles.
* "Rambo" for the mg class.
* NoScope and Noscope headshots
* 
* Kudos:
* Tsunami for the pm secks. <3
* psychonic for being hooker #1 <3
* 
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.5"

new Handle:g_Cvar_XlogNS
new Handle:g_Cvar_XlogHS
new Handle:g_Cvar_XlogMG
new Handle:g_Cvar_XlogSupport
new Handle:g_Cvar_XlogRifle

public Plugin:myinfo = 
{
	name = "DoD Xtralog",
	author = "Mosalar",
	description = "Extra weapon logging info",
	version = PLUGIN_VERSION,
	url = "http://www.budznetwork.com"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_xlog_version", PLUGIN_VERSION, "Extra weapon logging info version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_XlogNS = CreateConVar("sm_dod_xlog_ns", "1", "NoSocpe messages", FCVAR_PLUGIN)
	g_Cvar_XlogHS = CreateConVar("sm_dod_xlog_hs", "1", "NoSocpe HeadShot messages", FCVAR_PLUGIN)
	g_Cvar_XlogMG = CreateConVar("sm_dod_xlog_mg", "1", "MG Messages", FCVAR_PLUGIN)
	g_Cvar_XlogSupport = CreateConVar("sm_dod_xlog_support", "1", "Support Messages", FCVAR_PLUGIN)
	g_Cvar_XlogRifle = CreateConVar("sm_dod_xlog_rifle", "1", "Ironsight Messages", FCVAR_PLUGIN)

	
	HookEvent("dod_stats_player_damage", PlayerDamageEvent)
	
	AutoExecConfig()
}

public PlayerDamageEvent(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	new client = GetClientOfUserId(GetEventInt(event, "victim"))
	if (attacker == 0 || !IsClientInGame(attacker) || !IsPlayerAlive(attacker)) {
		return
	}
	new String:auth[33]
	new String:attacker_name[65]
	new String:tname[33]
	new String:wname[65]
	new weapon_pos = GetEventInt(event, "weapon")
	new hitgroup = GetEventInt(event, "hitgroup")
	new userid = GetClientUserId(attacker)
	GetClientName(attacker, attacker_name, sizeof(attacker_name))
	GetClientAuthString(attacker, auth, sizeof(auth))
	GetTeamName(GetClientTeam(attacker), tname, sizeof(tname))
	GetClientWeapon(attacker, wname, sizeof(wname))
	
	if (client != 0) {
		
		switch (weapon_pos) {
			
			case 9,10: {
				if (GetClientHealth(client) < 1) {
					
					if (hitgroup == 1) {
						if (attacker == 0 || !IsPlayerAlive(attacker)) {
							return
						}
						if (GetConVarInt(g_Cvar_XlogHS) == 1) {
							PrintToChatAll("\x01[Xlog] \x04%s made a noscope headshot", attacker_name)
						}
					}
					else {
						if (attacker == 0 || !IsPlayerAlive(attacker)) {
							return
						}
						if (GetConVarInt(g_Cvar_XlogNS) == 1) {
							PrintToChatAll("\x01[Xlog] \x04%s got a noscope kill", attacker_name)
						}
					} 
					LogToGame("\"%s<%d><%s><%s>\" triggered \"noscope\" with \"%s\"", attacker_name, userid, auth, tname, wname);
				}
			}	
			case 35,36: {
				if (GetClientHealth(client) < 1) {
					
					if (attacker == 0 || !IsPlayerAlive(attacker)) {
						return
					}
					if (GetConVarInt(g_Cvar_XlogMG) == 1) {
						PrintToChatAll("\x01[Xlog] \x04%s is RAMBO!", attacker_name)
					}
					LogToGame("\"%s<%d><%s><%s>\" triggered \"rambo\" with \"%s\"", attacker_name, userid, auth, tname, wname);
				}
			}
			case 31,32: {
				if (GetClientHealth(client) < 1) {
					
					if (attacker == 0 || !IsPlayerAlive(attacker)) {
						return
					}
					if (GetConVarInt(g_Cvar_XlogRifle) == 1) {
						PrintToChatAll("\x01[Xlog] \x04%s has the Ironsight", attacker_name)
					}
					LogToGame("\"%s<%d><%s><%s>\" triggered \"ironsight\" with \"%s\"", attacker_name, userid, auth, tname, wname);
				}
			}
			case 37,38: {
				if (GetClientHealth(client) < 1) {
					
					if (attacker == 0 || !IsPlayerAlive(attacker)) {
						return
					}
					if (GetConVarInt(g_Cvar_XlogSupport) == 1) {
						PrintToChatAll("\x01[Xlog] \x04%s is Support sniping", attacker_name)
					}
					LogToGame("\"%s<%d><%s><%s>\" triggered \"singleshot\" with \"%s\"", attacker_name, userid, auth, tname, wname);
				}
			}
		}
	}
}
