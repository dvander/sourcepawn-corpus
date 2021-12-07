#include <sourcemod>
#include <basecomm>
#include <cstrike>

new bool:block_guns
new bool:block_teams

public Plugin:myinfo = 
{
	name = "Jailbreak [1]",
	author = "Vaggelis",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegServerCmd("jb_allowguns", CmdAllowGuns)
	RegServerCmd("jb_blockguns", CmdBlockGuns)
	RegServerCmd("jb_allowteams", CmdAllowTeams)
	RegServerCmd("jb_blockteams", CmdBlockTeams)
	RegServerCmd("jb_removeguns", CmdRemoveGuns)
	
	HookEvent("round_start", Event_RoundStart)
	HookEvent("player_spawn", Event_PlayerSpawn)
	HookEvent("player_death", Event_PlayerDeath)
	
	AddCommandListener(ChangeTeam, "jointeam")
	
	HookUserMessage(GetUserMessageId("VGUIMenu"), TeamMenuHook, true)
}

public Action:CS_OnCSWeaponDrop(client, weaponIndex)
{
	if(block_guns)
	{
		return Plugin_Stop
	}
	
	return Plugin_Continue
}

public OnClientPostAdminCheck(client)
{
	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
		BaseComm_SetClientMute(client, true)
	}
	else
	{
		BaseComm_SetClientMute(client, false)
	}
}

public Action:CmdAllowGuns(args)
{
	block_guns = false
	
	SetConVarInt(FindConVar("mp_death_drop_grenade"), 1)
	SetConVarInt(FindConVar("mp_death_drop_gun"), 1)
}

public Action:CmdBlockGuns(args)
{
	block_guns = true
	
	SetConVarInt(FindConVar("mp_death_drop_grenade"), 0)
	SetConVarInt(FindConVar("mp_death_drop_gun"), 0)
}

public Action:CmdAllowTeams(args)
{
	block_teams = false
}

public Action:CmdBlockTeams(args)
{
	block_teams = true
}

public Action:CmdRemoveGuns(args)
{
	new max_ent = GetMaxEntities()
	new String:weapon[64]
	
	for(new i = GetMaxClients(); i < max_ent; i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, weapon, sizeof(weapon))
			
			if((StrContains(weapon, "weapon_") != -1) && GetEntProp(i, Prop_Send, "m_iState") == 0)
			{
				RemoveEdict(i)
			}
		}
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ServerCommand("jb_allowguns")
	ServerCommand("jb_allowteams")
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if(GetClientTeam(client) == 3)
	{
		BaseComm_SetClientMute(client, false)
	}
	
	else if(GetClientTeam(client) == 2)
	{
		if(GetUserAdmin(client) == INVALID_ADMIN_ID)
		{
			BaseComm_SetClientMute(client, true)
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if(GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
		BaseComm_SetClientMute(client, true)
	}
}

public Action:ChangeTeam(client, const String:command[], args)
{
	if(block_teams)
	{
		return Plugin_Stop
	}
	
	new guards
	new prisoners
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == 3)
			{
				guards++
			}
			else if(GetClientTeam(i) == 2)
			{
				prisoners++
			}
		}
	}
	
	if(guards == 0)
	{
		return Plugin_Continue
	}
	else if((prisoners - 3) / guards  > 3)
	{
		return Plugin_Continue
	}
	else
	{
		if(GetClientTeam(client) == 3)
		{
			return Plugin_Continue
		}
		
		return Plugin_Stop
	}
}

public Action:TeamMenuHook(UserMsg:msg_id, Handle:msg, const players[], playersNum, bool:reliable, bool:init)
{
	new String:buffermsg[64]
	PbReadString(msg, "name", buffermsg, sizeof(buffermsg))
	
	if(StrEqual(buffermsg, "team", true))
	{
		new client = players[0]
		
		CreateTimer(0.1, AutoJoinT, client)
	}
	
	return Plugin_Continue
}

public Action:AutoJoinT(Handle:timer, any:client)
{
	ChangeClientTeam(client, 2)
}