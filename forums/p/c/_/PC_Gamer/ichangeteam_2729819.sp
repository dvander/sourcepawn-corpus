#include <sdktools>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0" 

#define TEAM_CLASSNAME "tf_team"

Handle g_hSDKTeamAddPlayer;
Handle g_hSDKTeamRemovePlayer;

public Plugin myinfo =  
{ 
	name = "Instantly Change Team", 
	author = "PC Gamer using amazing code from Benoist3012",
	description = "Change Player Team", 
	version = PLUGIN_VERSION, 
	url = "www.sourcemod.com" 
} 

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	Handle hGameData = LoadGameConfigFile("ichangeteam");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeam::AddPlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeamAddPlayer = EndPrepSDKCall();
	if(g_hSDKTeamAddPlayer == INVALID_HANDLE)
	SetFailState("Could not find CTeam::AddPlayer!");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTeam::RemovePlayer");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	g_hSDKTeamRemovePlayer = EndPrepSDKCall();
	if(g_hSDKTeamRemovePlayer == INVALID_HANDLE)
	SetFailState("Could not find CTeam::RemovePlayer!");
	
	delete hGameData;
	
	RegAdminCmd("sm_ctred", Command_changeteamred, ADMFLAG_SLAY, "Change a player to Red team");
	RegAdminCmd("sm_ctblue", Command_changeteamblue, ADMFLAG_SLAY, "Change a player to Blue team"); 
	RegAdminCmd("sm_ctgray", Command_changeteamgray, ADMFLAG_SLAY, "Change a player to Gray team");
	RegAdminCmd("sm_ctgrey", Command_changeteamgray, ADMFLAG_SLAY, "Change a player to Grey team");
	RegAdminCmd("sm_nospec", Command_MoveSpec, ADMFLAG_SLAY, "Move all players from spec to a team"); 
	RegAdminCmd("sm_noafk", Command_MoveSpec, ADMFLAG_SLAY, "Move all players from spec to a team");    	
	RegAdminCmd("sm_ctspec", Command_changeteamspectator, ADMFLAG_SLAY, "Change a player to Spectator team");
	RegAdminCmd("sm_ctspectator", Command_changeteamspectator, ADMFLAG_SLAY, "Change a player to Spectator team");
}

public Action Command_changeteamred(int client, int args) 
{ 
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString( 
					arg1, 
					client, 
					target_list, 
					MAXPLAYERS, 
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), 
					target_name, 
					sizeof(target_name), 
					tn_is_ml)) <= 0) 
	{ 
		ReplyToTargetError(client, target_count); 
		return Plugin_Handled; 
	} 
	for (int t = 0; t < target_count; t++) 
	{ 
		ChangeClientTeamEx(target_list[t], 2);     
		LogAction(client, target_list[t], "\"%L\" made \"%L\" change to the Red team", client, target_list[t]); 
		PrintToChat(target_list[t], "You were changed to Red team");
	} 
	return Plugin_Handled; 
} 

public Action Command_changeteamblue(int client, int args) 
{ 
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString( 
					arg1, 
					client, 
					target_list, 
					MAXPLAYERS, 
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), 
					target_name, 
					sizeof(target_name), 
					tn_is_ml)) <= 0) 
	{ 
		ReplyToTargetError(client, target_count); 
		return Plugin_Handled; 
	} 
	for (int t = 0; t < target_count; t++) 
	{ 
		ChangeClientTeamEx(target_list[t], 3);     
		LogAction(client, target_list[t], "\"%L\" made \"%L\" change to the Blue team", client, target_list[t]); 
		PrintToChat(target_list[t], "You were changed to the Blue team");
	} 
	return Plugin_Handled; 
} 

public Action Command_changeteamspectator(int client, int args) 
{ 
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString( 
					arg1, 
					client, 
					target_list, 
					MAXPLAYERS, 
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), 
					target_name, 
					sizeof(target_name), 
					tn_is_ml)) <= 0) 

	if ((target_count = ProcessTargetString( 
					arg1, 
					client, 
					target_list, 
					MAXPLAYERS, 
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), 
					target_name, 
					sizeof(target_name), 
					tn_is_ml)) <= 0) 
	{ 
		ReplyToTargetError(client, target_count); 
		return Plugin_Handled; 
	} 
	for (int t = 0; t < target_count; t++) 
	{ 
		ForcePlayerSuicide(target_list[t]);
		ChangeClientTeamEx(target_list[t], 1);     
		LogAction(client, target_list[t], "\"%L\" made \"%L\" change to the Spectator team", client, target_list[t]); 
		PrintToChat(target_list[t], "You were changed to the Spectator team");
	} 
	return Plugin_Handled; 
} 

public Action Command_changeteamgray(int client, int args) 
{ 
	char arg1[32];
	if (args < 1)
	{
		arg1 = "@me";
	}
	else GetCmdArg(1, arg1, sizeof(arg1));
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString( 
					arg1, 
					client, 
					target_list, 
					MAXPLAYERS, 
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), 
					target_name, 
					sizeof(target_name), 
					tn_is_ml)) <= 0) 

	if ((target_count = ProcessTargetString( 
					arg1, 
					client, 
					target_list, 
					MAXPLAYERS, 
					COMMAND_FILTER_ALIVE|(args < 1 ? COMMAND_FILTER_NO_IMMUNITY : 0), 
					target_name, 
					sizeof(target_name), 
					tn_is_ml)) <= 0) 
	{ 
		ReplyToTargetError(client, target_count); 
		return Plugin_Handled; 
	} 
	for (int t = 0; t < target_count; t++) 
	{ 
		ChangeClientTeamEx(target_list[t], 0);     
		LogAction(client, target_list[t], "\"%L\" made \"%L\" change to the Gray team", client, target_list[t]); 
		PrintToChat(target_list[t], "You were changed to the Gray team");
	} 
	return Plugin_Handled; 
} 


void ChangeClientTeamEx(int client, int iNewTeamNum)
{
	int iTeamNum = GetEntProp(client, Prop_Send, "m_iTeamNum");
	
	// Safely swap team
	int iTeam = MaxClients+1;
	while ((iTeam = FindEntityByClassname(iTeam, TEAM_CLASSNAME)) != -1)
	{
		int iAssociatedTeam = GetEntProp(iTeam, Prop_Send, "m_iTeamNum");
		if (iAssociatedTeam == iTeamNum)
		SDK_Team_RemovePlayer(iTeam, client);
		else if (iAssociatedTeam == iNewTeamNum)
		SDK_Team_AddPlayer(iTeam, client);
	}
	
	SetEntProp(client, Prop_Send, "m_iTeamNum", iNewTeamNum);
}

void SDK_Team_AddPlayer(int iTeam, int client)
{
	if (g_hSDKTeamAddPlayer != INVALID_HANDLE)
	{
		SDKCall(g_hSDKTeamAddPlayer, iTeam, client);
	}
}

void SDK_Team_RemovePlayer(int iTeam, int client)
{
	if (g_hSDKTeamRemovePlayer != INVALID_HANDLE)
	{
		SDKCall(g_hSDKTeamRemovePlayer, iTeam, client);
	}
}

//This part adds in AFKtoTeam
public Action Command_MoveSpec(int client, int args) {
	int ClientTeam;
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i)) {
			ClientTeam = GetClientTeam(i);
			if (ClientTeam == view_as<int>(TFTeam_Unassigned) || ClientTeam == view_as<int>(TFTeam_Spectator)) {
				int RedCount = GetTeamClientCount(view_as<int>(TFTeam_Red));
				int BlueCount = GetTeamClientCount(view_as<int>(TFTeam_Blue));
				
				if(BlueCount < RedCount) {
					JoinTeam(i, TFTeam_Blue);
				} else {
					JoinTeam(i, TFTeam_Red);
				}
			}
		}
	}
}

/* Returns false if client couldn't join any team. true otherwise */
bool JoinTeam(int client, TFTeam team) {
	int ClientTeam;
	
	ChangeClientTeam(client, view_as<int>(team));
	ClientTeam = GetClientTeam(client);
	
	if (ClientTeam == view_as<int>(TFTeam_Unassigned) || ClientTeam == view_as<int>(TFTeam_Spectator)) {
		//If Client was unable to join team try the other team.
		if(team == TFTeam_Red) {
			ChangeClientTeam(client, view_as<int>(TFTeam_Blue));
		} else {
			ChangeClientTeam(client, view_as<int>(TFTeam_Red));
		}
		ClientTeam = GetClientTeam(client);
		if (ClientTeam == view_as<int>(TFTeam_Unassigned) || ClientTeam == view_as<int>(TFTeam_Spectator)) {
			
			return false;
		}
	}
	SetClass(client);
	
	return true;
}

Action SetClass(int client) {
	TF2_SetPlayerClass(client, view_as<TFClassType>(GetRandomInt(1, 9)), false);
}