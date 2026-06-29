#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

ConVar tf_powerup_mode;

public Plugin myinfo = 
{
	name = "[TF2] Force Change Team",
	author = "Peanut",
	description = "This plugin allows players to change teams in case they weren't supposed",
	version = PLUGIN_VERSION,
	url = "https://discord.gg/7sRn8Bt"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
	{
		SetFailState("=======Next time try TF2!=======");
	}
	return APLRes_Success;
} 

public void OnPluginStart()
{
	RegConsoleCmd("sm_setteamdeprecated", PootPlayerTeamOBSOLETE, "This command is OBSOLETE, i can use me if you want to, but you should use my newer cousin instead");
	RegConsoleCmd("sm_setmyteam", PootPlayerTeam, "Sets the player's team using the command (only works if tf_powerup_mode is set to 1)");
	tf_powerup_mode  = FindConVar("tf_powerup_mode");
	CreateConVar("sm_teamchanger_version", PLUGIN_VERSION, "i hate editing this!", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddCommandListener(PutPlayerTeam, "jointeam");
}

public Action PootPlayerTeamOBSOLETE(int client, int args)
{
    if(!tf_powerup_mode.BoolValue)
    {
    	ReplyToCommand(client, "[SM] Mannpower mode is not enabled");
    	return Plugin_Handled;
    }
    if(args != 1) 
    {
        ReplyToCommand(client, "[SM] Usage: !setmyteam <red/blu>");
        return Plugin_Handled;
    }
	
    char teamArg[16];
    GetCmdArg(1, teamArg, sizeof(teamArg));

    TFTeam team;
    if(StrEqual(teamArg, "red"))
    {
        team = TFTeam_Red;
    } 
    else if(StrEqual(teamArg, "blu")) 
    {
        team = TFTeam_Blue;
    } 
    else 
    {
        ReplyToCommand(client, "[SM] That's not a valid team");
        return Plugin_Handled;
    }
    TF2_ChangeClientTeam(client, team);
    return Plugin_Handled;
}

public Action PootPlayerTeam(int client, int args)
{
    if(!tf_powerup_mode.BoolValue)
    {
    	ReplyToCommand(client, "[SM] Mannpower mode is not enabled");
    	return Plugin_Handled;
    }
	
    ShowVGUIPanel(client, "team");
    return Plugin_Handled;
}

public Action PutPlayerTeam(int client, const char[] command, int args)
{
	if(tf_powerup_mode.BoolValue)
	{
		TFTeam SetTeam;
		
		char GetTeam[2];
		GetCmdArgString(GetTeam, sizeof(GetTeam));
		
		switch (GetTeam[0])
		{
			case 's': SetTeam = TFTeam_Spectator;
			case 'r': SetTeam = TFTeam_Red;
			case 'b': SetTeam = TFTeam_Blue;
			default:return Plugin_Handled;
		}
		TF2_ChangeClientTeam(client, SetTeam);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}