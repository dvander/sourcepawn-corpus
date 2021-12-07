#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <clients>
#include <sdktools_functions>

#define AFA_VERSION "1.5.8"

new bool:temp_disabled = false 
new Handle:h_enabled, Handle:h_time, Handle:h_admins_only;
new Float:client_orgin[MAXPLAYERS][3];
new Float:client_angels[MAXPLAYERS][3];
new Handle:h_sudden_death, Handle:h_re, Handle:h_teleport_enabled,
	Handle:h_flag, Handle:h_tags;
new AdminFlag:cflag;

public Plugin:myinfo = 
{
	name = "Autorespawn for Admins",
	author = "Chefe",
	description = "Respawn(&Teleport) Admins/Players in a varaible amount of time.",
	version = AFA_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=110918"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath)
	HookEvent("teamplay_round_win", Event_TeamplayRoundWin)
	HookEvent("teamplay_round_start", Event_TeamplayRoundStart)
	HookEvent("teamplay_suddendeath_begin", Event_SuddendeathBegin)
	h_enabled = CreateConVar("sm_instant_enabled", "1", "Enable or Disable Instant Respawn for Admins.");
	h_time = CreateConVar("sm_instant_time", "0.1", "Set the Instant Respawn Time for Admins.", _, true, 0.1);
	h_admins_only = CreateConVar("sm_instant_admins_only", "1", "Set is instant respawn only enabled for admins or for all.");
	h_sudden_death = CreateConVar("sm_instant_sudeath", "1", "Enable or Disable the Respawn in Sudden Death.");
	h_re = CreateConVar("sm_instant_re", "1", "Enable or Disable the Respawn on Roundend");
	h_teleport_enabled = CreateConVar("sm_instant_teleport", "0", "Enable or Disable teleport Player to ther old Position");
	h_flag = CreateConVar("sm_instant_flag", "t", "Set the flag witch admins must have to use instant respawn.");
	CreateConVar("sm_instant_version", AFA_VERSION, "Autorespawn Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true);
	
	new String:flagcvar[1];
	GetConVarString(h_flag, flagcvar, sizeof(flagcvar));
	FindFlagByChar(flagcvar[0], cflag);
	
	h_tags = FindConVar("sv_tags");
	HookConVarChange(h_tags, OnTagsChange);
	CheckForPluginTag(h_tags, "respawntimes");
}

CheckForPluginTag(Handle:convar, String:tag[])
{
	new String:oldtags[256];
	GetConVarString(convar, oldtags, sizeof(oldtags));
	
	if (StrContains(oldtags, tag, false) == -1)
	{
		new String:newtags[256];
		Format(newtags, sizeof(newtags), "%s,%s", oldtags, tag);
		
		SetConVarString(convar, newtags, _, true);
	}
}

RemovePluginTag(Handle:convar, String:tag[])
{
	new String:oldtags[256];
	GetConVarString(convar, oldtags, sizeof(oldtags));
	
	if (StrContains(oldtags, tag, false) != -1)
	{
		ReplaceString(oldtags, sizeof(oldtags), tag, "", false);
		
		SetConVarString(convar, oldtags, _, true);
	}
}

public OnPluginEnd()
{
	RemovePluginTag(h_tags, "respawntimes");
}

public OnTagsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CheckForPluginTag(h_tags, "respawntimes");
}

public Event_SuddendeathBegin(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (!GetConVarBool(h_sudden_death))
	{
		temp_disabled = true;
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_userid);
	
	new AdminId:admin_id = GetUserAdmin(client);
	
	if (GetConVarBool(h_teleport_enabled))
	{
		GetClientAbsOrigin(client, client_orgin[client]);
		GetClientAbsAngles(client, client_angels[client]);
	}
	
	new Float:time = GetConVarFloat(h_time);
	new death_flags = GetEventInt(event, "death_flags");
	
	if (GetConVarBool(h_admins_only))
	{
		if (admin_id != INVALID_ADMIN_ID && IsClientInGame(client) && GetConVarBool(h_enabled) && !temp_disabled && !(death_flags & 32) && GetAdminFlag(admin_id, cflag, AdmAccessMode:Access_Effective))
		{
			CreateTimer(time, RespawnClient, client)
		}
	}
	else
	{
		if (IsClientInGame(client) && GetConVarBool(h_enabled) && !temp_disabled && !(death_flags & 32))
		{
			CreateTimer(time, RespawnClient, client)
		}
	}
}

public Event_TeamplayRoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(h_re))
	{
		temp_disabled = true;
	}
}

public Event_TeamplayRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	temp_disabled = false;
}

public Action:RespawnClient(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		TF2_RespawnPlayer(client);
		if (GetConVarBool(h_teleport_enabled))
		{
			TeleportEntity(client, client_orgin[client], client_angels[client], NULL_VECTOR);
		}
	}
}