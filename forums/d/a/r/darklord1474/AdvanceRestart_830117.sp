/* 
* 	Advance Restart
* 	By Darklord1474
* 
*	This is my first plugin I've release (be gentle :]) 
* 
* 	Allows an admin to restart a server and warning the 
* 	users that the server is about to be restarted.
* 
* 
*   To Do.
* 	
* 	* Reason for restart
* 	* Admin Logging
* 	* Stop restart command
* 	* Timed Restarts with reasons stored in SQL
* 	* Admin Menu with restart reasons.
* 	* Options for diffrent typed of Messaging (say,csay etc) - done
* 	* Translations?
* 	* choice to use diffrent sound files
* 
* 
*   Commands
* 	sm_restart 
*	Usage: sm_restart <seconds Between 0 and 120>"
*/

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2"

new Handle:g_hEnabledChat;
new Handle:g_hEnabledHint;
new Handle:g_hEnabledCenter;
new String:filelocation[255];
new currenttime = 0;
new targettime= 10;
new STOP;
public Plugin:myinfo = 
{
	name = "Advance Restart",
	author = "Darklord1474",
	description = "Advance Restart",
	version = "1.0",
	url = "Http://www.programmingmuffins.co.uk"
}

public OnPluginStart()
{
	currenttime=0;
	targettime=10;
	filelocation = "buttons/bell1.wav";
	if(FileExists(filelocation)){
		PrecacheSound(filelocation, true);
	}
	CreateConVar("sm_AdvanceRestart_version", PLUGIN_VERSION, "Advance Restart version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_restart", Command_Restart,ADMFLAG_RCON, "Restarts the Server.");
	RegAdminCmd("sm_stoprestart", Command_stopRestart,ADMFLAG_RCON, "Stops the restart");
	g_hEnabledHint= CreateConVar("sm_ar_hintsay", "1", "Sets whether messages are sent to hintsay");
	g_hEnabledChat= CreateConVar("sm_ar_chatsay", "1", "Sets whether messages are sent to chatsay");
	g_hEnabledCenter = CreateConVar("sm_ar_centersay", "1", "Sets whether messages are sent to centersay");

}

 
public Action:PrintMsg(Handle:timer)
{
	if(STOP==1){
		KillTimer(Handle:timer);
		return Plugin_Handled;
	}
	new maxplayers = GetMaxClients();
	EmitSoundToAll(filelocation);
	if(currenttime == targettime){
		if (GetConVarInt(g_hEnabledHint) >= 1){PrintHintTextToAll("Have A Nice Day :]");}
		if (GetConVarInt(g_hEnabledChat) >= 1){PrintToChatAll("Have A Nice Day :]");}
		if (GetConVarInt(g_hEnabledCenter) >= 1){PrintCenterTextAll("Have A Nice Day :]");}

		// force client to retry from superadmin by pRED*
		for(new i = 1; i <= maxplayers; i++)
		{
		if (IsClientInGame(i))
			{
				ClientCommand(i, "retry")
			}
		}
		KillTimer(Handle:timer);
		ServerCommand("_restart");
		return Plugin_Handled;
	}else{
		
		if (GetConVarInt(g_hEnabledHint) >= 1){PrintHintTextToAll("Server Restart: %d",(targettime-currenttime));}
		if (GetConVarInt(g_hEnabledChat) >= 1){PrintToChatAll("Server Restart: %d",(targettime-currenttime));}
		if (GetConVarInt(g_hEnabledCenter) >= 1){PrintCenterTextAll("%d",(targettime-currenttime));}
	}
	currenttime++;
	return Plugin_Continue;

}
	
	
public Action:Command_stopRestart(client, args) {
	
	STOP =1;
	return Plugin_Handled;
}
public Action:Command_Restart(client, args) {
	decl String:sec[32];

	new secs;
	STOP=0;

	GetCmdArg(1, sec, sizeof(sec));
	secs = StringToInt(sec); 

	
	if (secs < 0 || secs > 120)
	{
		ReplyToCommand(client, "[SM] Usage: sm_restart <seconds Between 0 and 120> [reason]");
		return Plugin_Handled;
	}else{
		if (GetConVarInt(g_hEnabledHint) >= 1){PrintHintTextToAll("Server Restart!");}
		if (GetConVarInt(g_hEnabledChat) >= 1){PrintToChatAll("Server Restart!");}
		if (GetConVarInt(g_hEnabledCenter) >= 1){PrintCenterTextAll("Server Restart!");}

		targettime = secs;
		currenttime = 0;
		CreateTimer(1.0, PrintMsg, _, TIMER_REPEAT);
	
	}
	
	
	return Plugin_Handled;
}