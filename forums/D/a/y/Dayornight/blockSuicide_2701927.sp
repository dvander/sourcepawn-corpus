#pragma semicolon 1 

#include <sourcemod> 
#include <morecolors>

#define PL_VERSION "1.0" 

new const TEAM_RED = 2;
new const TEAM_BLUE = 3;


// CVAR Handles
new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarKill = INVALID_HANDLE;
new Handle:cvarExplode = INVALID_HANDLE;
new Handle:cvarSwitch = INVALID_HANDLE;
new Handle:cvarAllowSpectate = INVALID_HANDLE;
new Handle:cvarAllowOverride = INVALID_HANDLE;
new Handle:cvarAllowSpectateTeam = INVALID_HANDLE;

public Plugin:myinfo = { 
    name        = "Block Suicide", 
    author      = "Dayornight", 
    description = "Disable the Kill and explode command for TF2. Also disables team switching.", 
    version     = PL_VERSION, 
    url         = "" 
}; 

public OnPluginStart() 
{ 
	// Add CVARS
	cvarEnabled = CreateConVar("sm_blockSuicide_enabled", "1", "Enable this plugin?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0);
	cvarKill = CreateConVar("sm_blockKillTeam", "0", "Disable kill for which team?\n0 = No team\n1 = Red team\n2 = Blue team\n3 = Both teams", _, true, 0.0, true, 3.0);
	cvarExplode = CreateConVar("sm_blockExplodeTeam", "0", "Disable explode for which team?\n0 = No team\n1 = Red team\n2 = Blue team\n3 = Both teams", _, true, 0.0, true, 3.0);
	cvarSwitch = CreateConVar("sm_blockSwitchTeam", "0", "Disable switching teams for which team?\n0 = No team\n1 = Red team\n2 = Blue team\n3 = Both teams", _, true, 0.0, true, 3.0);
	cvarAllowSpectate = CreateConVar("sm_allowSpectate", "1", "Allow spectate?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0);
	cvarAllowSpectateTeam = CreateConVar("sm_allowSpectateTeam", "0", "Allow spectate for which team?\n0 = Both teams\n1 = Red Team\n2 = Blue Team", _, true, 0.0, true, 2.0);
	cvarAllowOverride = CreateConVar("sm_allowOverride", "1", "Allow overrides for suicides and team switches?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0);
	
	// Add listen commands
	AddCommandListener(Kill, "kill");
	AddCommandListener(Explode, "explode");
	AddCommandListener(Switch, "jointeam");
	
	
	// Load translations file
	LoadTranslations("blockSuicide.phrases");
	
	// Execute the config file
	AutoExecConfig(true, "plugin.blocksuicide");
} 

public Action:Kill(client, const String:command[], args)
{ 
	if(GetConVarBool(cvarEnabled) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1) 
	{
		if(GetConVarBool(cvarAllowOverride) && CheckCommandAccess(client, "suicideandteamswitch_override", ADMFLAG_GENERIC, true)) 
		{
			return Plugin_Continue;
		}
		else
		{
			switch(GetConVarInt(cvarKill)) 
			{
				case 0: 
				{
					return Plugin_Continue;
				}
				case 1:
				{
					if(GetClientTeam(client) == TEAM_RED) 
					{
						CPrintToChat(client, "%t", "noKill");
						return Plugin_Handled;
					}
				}
				case 2:
				{
					if(GetClientTeam(client) == TEAM_BLUE) 
					{
						CPrintToChat(client, "%t", "noKill");
						return Plugin_Handled;
					}				
				}
				case 3:
				{
					CPrintToChat(client, "%t", "noKill");
					return Plugin_Handled;				
				}
			}
		}
	}
	return Plugin_Continue;
} 

public Action:Explode(client, const String:command[], args)
{ 
	if(GetConVarBool(cvarEnabled) && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1) 
	{
		if(GetConVarBool(cvarAllowOverride) && CheckCommandAccess(client, "suicideandteamswitch_override", ADMFLAG_GENERIC, true)) 
		{
			return Plugin_Continue;
		}
		else
		{
			switch(GetConVarInt(cvarExplode)) 
			{
				case 0: 
				{
					return Plugin_Continue;
				}
				case 1:
				{
					if(GetClientTeam(client) == TEAM_RED) 
					{
						CPrintToChat(client, "%t", "noExplode");
						return Plugin_Handled;
					}
				}
				case 2:
				{
					if(GetClientTeam(client) == TEAM_BLUE) 
					{
						CPrintToChat(client, "%t", "noExplode");
						return Plugin_Handled;
					}				
				}
				case 3:
				{
					CPrintToChat(client, "%t", "noExplode");
					return Plugin_Handled;
				}
			}
		}	
	}
	return Plugin_Continue;
} 

public Action:Switch(client, const String:command[], args)
{
	if(GetConVarBool(cvarEnabled) && IsClientInGame(client)) 
	{
		if(GetConVarBool(cvarAllowOverride) && CheckCommandAccess(client, "suicideandteamswitch_override", ADMFLAG_GENERIC, true)) 
		{
			return Plugin_Continue;
		}
		else
		{
			new currentTeam = GetClientTeam(client);
			
			if(GetConVarBool(cvarAllowSpectate)) 
			{
				new String:team[10];
				GetCmdArgString(team, sizeof(team));
				strcopy(team, sizeof(team), team);
		
				new spectateTeam = GetConVarInt(cvarAllowSpectateTeam);
				
				switch(GetConVarInt(cvarSwitch))
				{
					case 0:
					{
						return Plugin_Continue;
					}
					case 1:
					{
						if(currentTeam == TEAM_RED) 
						{
							if(spectateTeam == 2) {
								CPrintToChat(client, "%t", "noSwitchNoSpectate");
								return Plugin_Handled;
							} else {
								if(!StrEqual(team, "spectate"))
								{
									CPrintToChat(client, "%t", "noSwitchAllowSpectate");
									return Plugin_Handled;	
								} else {
									return Plugin_Continue;
								}
							}
						}				
					}
					case 2:
					{
						if(currentTeam == TEAM_BLUE) 
						{
							if(spectateTeam == 1) {
								CPrintToChat(client, "%t", "noSwitchNoSpectate");
								return Plugin_Handled;
							} else {
								if(!StrEqual(team, "spectate"))
								{
									CPrintToChat(client, "%t", "noSwitchAllowSpectate");
									return Plugin_Handled;	
								} else {
									return Plugin_Continue;
								}
							}
						}				
					}
					case 3:
					{	
						if(currentTeam > 1)
						{
							if( (((currentTeam == TEAM_RED) || (currentTeam == TEAM_BLUE)) && (spectateTeam == 0)) || ((currentTeam == TEAM_RED) && spectateTeam == 1) || ((currentTeam == TEAM_BLUE) && spectateTeam == 2) )
							{
								if(!StrEqual(team, "spectate"))
								{	
									CPrintToChat(client, "%t", "noSwitchAllowSpectate");
									return Plugin_Handled;	
								} else {
									return Plugin_Continue;
								}
							}
							else 
							{
								CPrintToChat(client, "%t", "noSwitchNoSpectate");
								return Plugin_Handled;
							}	
						}
					}
				}
			} 
			else 
			{
				switch(GetConVarInt(cvarSwitch))
				{
					case 0:
					{
						return Plugin_Continue;
					}
					case 1:
					{
						if(currentTeam == TEAM_RED) 
						{
							CPrintToChat(client, "%t", "noSwitchNoSpectate");
							return Plugin_Handled;
						}				
					}
					case 2:
					{
						if(currentTeam == TEAM_BLUE) 
						{
							CPrintToChat(client, "%t", "noSwitchNoSpectate");
							return Plugin_Handled;
						}				
					}
					case 3:
					{	
						if((currentTeam == TEAM_RED) || (currentTeam == TEAM_BLUE)) {
							CPrintToChat(client, "%t", "noSwitchNoSpectate");
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
} 
