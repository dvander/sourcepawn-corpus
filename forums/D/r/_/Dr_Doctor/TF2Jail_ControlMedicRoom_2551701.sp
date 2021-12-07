#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Battlefield Duck"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <tf2jail>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2] Jailbreak - Control Medic Room",
	author = PLUGIN_AUTHOR,
	description = "Let Warden to Enable or Disable medic room",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/battlefieldduck/"
};

Handle hEnabled;
bool bEnableMR; //bool Enable Medic Room
bool bLocked;
public void OnPluginStart()
{
	LoadTranslations("TF2Jail.phrases");
	HookEvent("teamplay_round_start", OnRoundStart);
	
	CreateConVar("sm_tf2jail_cmr_version", PLUGIN_VERSION, "Version of [TF2] Jailbreak - Control Medic Room", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	hEnabled = CreateConVar("sm_tf2jail_cmr_enable", "1", "Enable [TF2] Jailbreak - Control Medic Room", _, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_cmr", ControlMR, "Enable or Disable Medic room");
	RegAdminCmd("sm_lockmedicroom", Command_LockMedicRoom, ADMFLAG_GENERIC, "Lock the medic room");
	RegAdminCmd("sm_lmr", Command_LockMedicRoom, ADMFLAG_GENERIC, "Lock the medic room");
}

public Action Command_LockMedicRoom(int client, int args)
{
	if(IsValidClient(client))
	{
		if(bLocked)
		{
			bLocked = false;
			CPrintToChatAll("%t {darkkhaki} Admin {green}%N {darkkhaki}has {green}UNLOCK {darkkhaki}the Medic Room Warden access!", "plugin tag", client);
		}
		else
		{
			bLocked = true;
			CPrintToChatAll("%t {darkkhaki} Admin {green}%N {darkkhaki}has {red}LOCK {darkkhaki}the Medic Room Warden access!", "plugin tag", client);
		}
	}
}
public Action ControlMR(int client, int args)
{
	if(!GetConVarBool(hEnabled) || !IsValidClient(client))
		return Plugin_Continue;
		
	if(!TF2Jail_IsWarden(client) && !IsPlayerGenericAdmin(client))
	{
		CPrintToChat(client, "%t %t", "plugin tag", "not warden");
		return Plugin_Continue;
	}
	
	if(bLocked && !IsPlayerGenericAdmin(client))
	{
		CPrintToChat(client, "%t {darkkhaki}The Medic Room is currently locked", "plugin tag");
		return Plugin_Continue;
	}
	
	if(bEnableMR)
	{
		bEnableMR = false;
		if(IsPlayerGenericAdmin(client) && !TF2Jail_IsWarden(client))
			CPrintToChatAll("%t {darkkhaki} Admin {green}%N {darkkhaki}has {red}disabled {darkkhaki}the Medic Room!", "plugin tag", client);
		else
			CPrintToChatAll("%t {darkkhaki} Warden {green}%N {darkkhaki}has {red}disabled {darkkhaki}the Medic Room!", "plugin tag", client);
	}
	else
	{
		bEnableMR = true;
		if(IsPlayerGenericAdmin(client) && !TF2Jail_IsWarden(client))
			CPrintToChatAll("%t {darkkhaki} Admin {green}%N {darkkhaki}has {green}enabled {darkkhaki}the Medic Room!", "plugin tag", client);
		else
			CPrintToChatAll("%t {darkkhaki} Warden {green}%N {darkkhaki}has {green}enabled {darkkhaki}the Medic Room!", "plugin tag", client);
	}	
	
		
	int i = -1;
	while((i = FindEntityByClassname(i, "trigger_hurt")) != -1)
	{
		if(GetEntPropFloat(i, Prop_Data, "m_flDamage") < 0)  //thanks for XaH JoB bug report <3
		{
			if(bEnableMR)
			{
				AcceptEntityInput(i, "Enable");
			}
			else
			{
				AcceptEntityInput(i, "Disable");
			}
      	}
	}
	return Plugin_Continue;
}

//------------------[ Enable Medic Room On round start]----------------------
public Action OnRoundStart(Handle event, char[] name, bool dontBroadcast)
{
	if(!GetConVarBool(hEnabled))
		return;
		
	bEnableMR = true;
	bLocked = false;
}

stock bool IsValidClient(int client)
{ 
    if(client <= 0 ) return false; 
    if(client > MaxClients) return false; 
    if(!IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
}

stock bool IsPlayerGenericAdmin(int client) 
{ 
    if (CheckCommandAccess(client, "generic_admin", ADMFLAG_GENERIC, false)) 
        return true; 
        
    return false; 
}  