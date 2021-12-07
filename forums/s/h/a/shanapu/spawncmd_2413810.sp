//includes
#include <sourcemod>


//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//ConVars
ConVar gc_bPlugin;
ConVar gc_sCMD;

//Strings
char g_sCMD[64];

public Plugin myinfo = {
	name = "Spawn command",
	author = "shanapu",
	description = "execute a player command on spawn",
	version = "0.2",
	url = "shanapu.de"
};

public void OnPluginStart()
{
	
	CreateConVar("sm_spawncmd_version", "0.2", "The version of the SourceMod plugin", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gc_bPlugin = CreateConVar("sm_spawncmd_enable", "1", "0 - disabled, 1 - enable Plugin");
	gc_sCMD = CreateConVar("sm_spawncmd", "say Hello World", "the command to execute");
	
	//Hooks
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookConVarChange(gc_sCMD, OnSettingChanged);
	
	gc_sCMD.GetString(g_sCMD , sizeof(g_sCMD));
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sCMD)
	{
		strcopy(g_sCMD, sizeof(g_sCMD), newValue);
	}
}

public Action Event_PlayerSpawn(Handle event, char[] name, bool dontBroadcast)
{
	if(gc_bPlugin.BoolValue)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer( 1.0, ExecCommand, client);
	}
}

public Action ExecCommand(Handle timer, any client)	
{
	if (IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		FakeClientCommand(client,"%s", g_sCMD);
	}
}