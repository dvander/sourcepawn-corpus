#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2>
#define REQUIRE_EXTENSIONS

#define PLUGIN_VERSION "1.4"

new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_Message = INVALID_HANDLE;
new Handle:gH_Time = INVALID_HANDLE;
new bool:gB_Enabled;
new bool:gB_Message;
new Float:gF_Time;
new String:mod[16];

public Plugin:myinfo = 
{
	name = "[CSS/CSP/CSGO/TF2] Autorespawn",
	author = "shavit",
	description = "Autorespawn for CSS, CS:GO, TF2, CSPROMOD",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("sm_autorespawn_version", PLUGIN_VERSION, "Autorespawn's version", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	gH_Enabled = CreateConVar("sm_autorespawn_enabled", "1", "Autorespawn enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Message = CreateConVar("sm_autorespawn_message", "1", "Message the player that he will respawn?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Time = CreateConVar("sm_autorespawn_time", "0.0", "Time to wait before autorespawn. [Float] [0.0 - Instant]", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	
	gB_Enabled = GetConVarBool(gH_Enabled);
	gB_Message = GetConVarBool(gH_Message);
	gF_Time = GetConVarFloat(gH_Time);
	
	new Handle:Tags = FindConVar("sv_tags");
	SetConVarString(Tags, "respawntimes,instant_respawn,autorespawn");
	
	HookConVarChange(gH_Enabled, ConVarChanged);
	HookConVarChange(gH_Time, ConVarChanged);
	
	HookEvent("player_death", Hook);
	
	GetGameFolderName(mod, 16);
	
	if(StrEqual(mod, "tf"))
	{
		HookEvent("player_class", Hook);
	}
	
	AutoExecConfig(true, "autorespawn");
}

public Action:Hook(Handle:event, const String:name[], bool:dontBroadcast)
{
	new i = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(gB_Enabled)
	{
		if(gF_Time == 0.0)
		{
			CreateTimer(0.1, Respawn, i);
		}
		
		else
		{
			if(gB_Message)
			{
				PrintHintText(i, "You'll respawn in %f seconds.", gF_Time);
			}
			
			CreateTimer(gF_Time, Respawn, i);
		}
	}
}

public Action:Respawn(Handle:Timer, any:i)
{
	if(!IsValidClient(i) || GetClientTeam(i) < 2)
	{
		return Plugin_Stop;
	}
	
	if(StrEqual(mod, "tf"))
	{
		TF2_RespawnPlayer(i);
	}
	
	else if(StrContains(mod, "cs") != -1)
	{
		CS_RespawnPlayer(i);
	}
	
	PrintHintText(i, "Successfully respawned!");
	
	return Plugin_Stop;
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = StringToInt(newVal)? true:false;
		if(gB_Enabled)
		{
			for(new i; i <= MaxClients; i++)
			{
				if(StrEqual(mod, "tf"))
				{
					TF2_RespawnPlayer(i);
				}
				
				else if(StrContains(mod, "cs") != -1)
				{
					CS_RespawnPlayer(i);
				}
			}
		}
	}
	
	else if(cvar == gH_Time)
	{
		gF_Time = StringToFloat(newVal);
	}
	
	else if(cvar == gH_Message)
	{
		gB_Message = StringToInt(newVal)? true:false;
	}
}

stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)));
}
