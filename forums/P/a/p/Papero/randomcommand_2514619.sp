#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <colors>
#include <autoexecconfig>


#pragma newdecls required
#pragma semicolon 1


#define PLUGIN_AUTHOR "Hexah"
#define PLUGIN_VERSION "1.00"

ConVar Commands;





public Plugin myinfo = 
{
	name = "Random Command", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	
	AutoExecConfig_SetFile("RandomComm");
	AutoExecConfig_SetCreateFile(true);
	Commands = AutoExecConfig_CreateConVar("sm_randomcommands", "sm_giveweapon client 1", "List of random commands separanted by a comma (,) put 'client' to select him");
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	RegConsoleCmd("sm_random", Command_Random);
}

public Action Command_Random(int client, int args)
{
	if (IsValidClient(client, false, false))
	{
		int iCount = 0;
		char sCommands[128], sCommandsL[12][32], sCommand[32];
		Commands.GetString(sCommands, sizeof(sCommands));
		iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
		
		Format(sCommand, sizeof(sCommand), "%s", sCommandsL[GetRandomInt(0, iCount)]);
		
		char sClientName[32];
		GetClientName(client, "sClientName", sizeof(sClientName));
		
		if (StrContains(sCommand, "client", false) != -1)
			ReplaceString(sCommand, sizeof(sCommand), "client", sClientName, false);
		
		ServerCommand(sCommand);
	}
}


stock bool IsValidClient(int client, bool AllowBots = false, bool AllowDead = false)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !AllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!AllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
} 