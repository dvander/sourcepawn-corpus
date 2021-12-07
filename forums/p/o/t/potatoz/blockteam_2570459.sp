#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define VERSION "1.0"

bool IsMapConfigured;
int team_blocked = -1;
Handle blockedteam;

KeyValues kv;

public Plugin:myinfo =
{
    name = "blockteam",
    author = "Potatoz",
    description = "",
    version = VERSION,
    url = ""
};


public OnPluginStart()
{
	RegAdminCmd("sm_blockteam", Command_BlockTeam, ADMFLAG_ROOT);
	
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/blockteam_config.cfg");
	
	kv = new KeyValues("blockteam_config");
	kv.ImportFromFile(buffer);
}

public OnConfigsExecuted()
{	
	blockedteam = FindConVar("mp_humanteam");
	SetConVarString(blockedteam, "any", true, false);
	SetCvar("sm_teamchange_unlimited_restrict_t", "0");
	SetCvar("sm_teamchange_unlimited_restrict_ct", "0");
	IsMapConfigured = false;
	Parse_MapConfig();
}

public Action Command_BlockTeam(client, args)
{		
	if(args != 1)
	{
		if(IsMapConfigured)
		{
			Parse_MapConfig();
			
			if(team_blocked == 0)
				PrintToChat(client, " \x07* This map has already been configured to allow all teams");
			else if(team_blocked == 2)
				PrintToChat(client, " \x07* This map has already been configured to block T");
			else if(team_blocked == 3)
				PrintToChat(client, " \x07* This map has already been configured to block CT");
				
			PrintToChat(client, " \x06* \x01Overwrite team-block with: \x06sm_blockteam <CT/T/NONE>");
		} else PrintToChat(client, " \x06* \x01Usage: \x06sm_blockteam <CT/T/NONE>");
		
		return Plugin_Handled;
	}
	
	if(IsFakeClient(client)) return Plugin_Handled;

	char buffer[PLATFORM_MAX_PATH];
	
	char sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));

	kv.JumpToKey(sMapName, true);

	GetCmdArgString(buffer, sizeof(buffer));

	if(StrEqual(buffer, "CT", false))
	{
		team_blocked = 3;
		SetConVarString(blockedteam, "t", true, false);
		SetCvar("sm_teamchange_unlimited_restrict_t", "0");
		SetCvar("sm_teamchange_unlimited_restrict_ct", "1");
		Format(buffer, sizeof(buffer), "CT");
	}
	else if(StrEqual(buffer, "T", false))
	{
		team_blocked = 2;
		SetConVarString(blockedteam, "ct", true, false);
		SetCvar("sm_teamchange_unlimited_restrict_t", "1");
		SetCvar("sm_teamchange_unlimited_restrict_ct", "0");
		Format(buffer, sizeof(buffer), "T");
	}
	else if(StrEqual(buffer, "NONE", false))
	{
		team_blocked = 0;
		SetConVarString(blockedteam, "any", true, false);
		SetCvar("sm_teamchange_unlimited_restrict_t", "0");
		SetCvar("sm_teamchange_unlimited_restrict_ct", "0");
		Format(buffer, sizeof(buffer), "NONE");
	}
	else 
	{
		PrintToChat(client, " \x06* \x01Usage: \x06sm_blockteam <CT/T/NONE>");
		return Plugin_Handled;
	}
	
	if(StrEqual(buffer, "NONE", false))
		PrintToChat(client, " \x06* \x01No longer blocking entry to any specific team on \x06%s", sMapName);
	else
		PrintToChat(client, " \x06* \x01Now blocking entry to \x06%s \x01on \x06%s", buffer, sMapName);

	kv.SetString("team_blocked", buffer);
	kv.Rewind();

	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/blockteam_config.cfg");
	kv.ExportToFile(buffer);
	
	
	Parse_MapConfig();
	
	return Plugin_Handled;
}

Parse_MapConfig()
{
	char sConfig[PLATFORM_MAX_PATH], sMapName[128];
	GetCurrentMap(sMapName, sizeof(sMapName));
	BuildPath(Path_SM, sConfig, sizeof(sConfig), "configs/blockteam_config.cfg");

	KeyValues hConfig = new KeyValues("blockteam_config");
	
	if (FileToKeyValues(hConfig, sConfig))
	{
		if (KvJumpToKey(hConfig, sMapName))
		{
			new String:sTeamBlocked[6];
			KvGetString(hConfig, "team_blocked", sTeamBlocked, sizeof(sTeamBlocked));
			if(StrEqual(sTeamBlocked, "T", false)) 
			{
				SetConVarString(blockedteam, "ct", true, false);
				SetCvar("sm_teamchange_unlimited_restrict_t", "1");
				SetCvar("sm_teamchange_unlimited_restrict_ct", "0");
				team_blocked=2;
			}
			else if(StrEqual(sTeamBlocked, "CT", false)) 
			{
				SetConVarString(blockedteam, "t", true, false);
				SetCvar("sm_teamchange_unlimited_restrict_t", "0");
				SetCvar("sm_teamchange_unlimited_restrict_ct", "1");
				team_blocked=3;
			}
			else if(StrEqual(sTeamBlocked, "NONE", false)) 
			{
				SetConVarString(blockedteam, "any", true, false);
				SetCvar("sm_teamchange_unlimited_restrict_t", "0");
				SetCvar("sm_teamchange_unlimited_restrict_ct", "0");
				team_blocked=0;
			}
			
			IsMapConfigured = true;
		}
		else
		{
			SetConVarString(blockedteam, "any", true, false);
			SetCvar("sm_teamchange_unlimited_restrict_t", "0");
			SetCvar("sm_teamchange_unlimited_restrict_ct", "0");
			IsMapConfigured = false;
			team_blocked = -1;
		}
	}
	
	CloseHandle(hConfig);
}

stock SetCvar(String:scvar[], String:svalue[])
{
    new Handle:cvar = FindConVar(scvar);
    SetConVarString(cvar, svalue, true);
}