#include <tf2>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Call for Medic",
	author = "PC Gamer",
	description = "Add condition when medic is called",
	version = "1.0",
	url = "www.sourcemod.com"	
}

bool g_wait[MAXPLAYERS + 1] = {false, ...}; 

public void OnPluginStart()
{
	AddCommandListener(Command_Listening, "voicemenu");
}

public Action Command_Listening(int client, char[] command, int args)
{
	char arguments[4];
	GetCmdArgString(arguments, sizeof(arguments));
	if (StrEqual(arguments, "0 0") && g_wait[client] == false)
	{
		//PrintToChatAll("Player %N called for a Medic", client);
		TF2_AddCondition(client, TFCond_RadiusHealOnDamage, 0.1);
		g_wait[client] = true;
		CreateTimer(10.0, Waiting, client); //How long you have to wait to use it again	
	}
	
	return Plugin_Continue;
}

public Action Waiting(Handle timer, any client) 
{
	g_wait[client] = false;
	
	return Plugin_Handled; 	
}
