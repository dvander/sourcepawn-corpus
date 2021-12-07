#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION  "0.0.11"

public Plugin:myinfo = 
{
	name = "L4D Info",
	author = "TeddyRuxpin",
	description = "Utilities for L4D Stat Tracking",
	version = PLUGIN_VERSION,
	url = "http://blacktusklabs.com/btlforums"
}

new iKStats[MAXPLAYERS + 1][2];  // Common Zombie Kills Prev Round
new iHStats[MAXPLAYERS + 1][2];  // Head shots against Commons Prev Round

public OnPluginStart()
{
	CreateConVar("sm_l4d_playstats_version", PLUGIN_VERSION, "Get L4D Current Play Stats", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_zinfoteam", cmdGetInfo, "Get your current L4D stats");
	RegConsoleCmd("sm_zinfo", cmdGetInfo1, "Get your current team L4D stats");
	HookEvent("map_transition", evtRoundEnd);
	HookEvent("player_spawn", evtPlayerSpawn);

}
// Pull the information when trigged by map transtion event
public Action:evtRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= GetMaxClients(); i++) 
		if (IsClientInGame(i))	
	{
		new ckills_mission = GetEntProp(i, Prop_Send, "m_checkpointZombieKills");
		new hdShotM_mission = GetEntProp(i, Prop_Send, "m_checkpointHeadshots");
		iKStats[i][0] += ckills_mission;
		iHStats[i][1] += hdShotM_mission;
	}
}

// Tell players on spawn about the stats
public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			PrintToChat(client, "\x04[SM]\x01 L4D Info Enabled Type !zinfo to see your stats");
}

// Display the all of the survivors players stats
public Action:cmdGetInfo(client, args)
{
		decl String:iName[MAX_NAME_LENGTH];
		for (new i=1; i <= MAXPLAYERS; i++)
				if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && IsClientAuthorized(i)) {
				{	 	
				GetClientName(i, iName, sizeof(iName));
				new ckills_check = GetEntProp(i, Prop_Send, "m_checkpointZombieKills");
				new hdShot_check = GetEntProp(i, Prop_Send, "m_checkpointHeadshots");
				new hdShotA_check = RoundFloat((float(hdShot_check) / ckills_check) * 100);
				new hdShotM_check = RoundFloat((float( iHStats[i][1]) / iKStats[i][0]) * 100);

				PrintToChat(i, "\x04[SM]\x01 L4D Current Play Stats: %s ", iName );
				PrintToChat(i, "\x04[\x01 Zombies killed This Stage: %d ", ckills_check);
				PrintToChat(i, "\x04[\x01 Zombies killed This Campaign: %d ", iKStats[i][0]);
				PrintToChat(i, "\x04[\x01 Head Shots This Stage: %d ", hdShot_check);
				PrintToChat(i, "\x04[\x01 Head Shots This Campaign: %d ", iHStats[i][1]);			
				PrintToChat(i, "\x04[\x01 Head Shot Accuracy This Stage: %d %", hdShotA_check);
				PrintToChat(i, "\x04[\x01 Head Shot Accuracy This Campaign: %d %", hdShotM_check);
				}
			}
		return Plugin_Handled;
}

// Display the single players stats
public Action:cmdGetInfo1(client, args)
{
				decl String:iName[MAX_NAME_LENGTH];
				GetClientName(client, iName, sizeof(iName));
				new ckills_check = GetEntProp(client, Prop_Send, "m_checkpointZombieKills");
				new hdShot_check = GetEntProp(client, Prop_Send, "m_checkpointHeadshots");
				new hdShotA_check = !ckills_check ? 0 : RoundFloat((float(hdShot_check) / ckills_check) * 100);
				new hdShotM_check = !(iKStats[client][0]) ? 0 :RoundFloat((float(iHStats[client][1]) / iKStats[client][0]) * 100);
				PrintToChat(client, "\x04[SM]\x01 L4D Current Play Stats: %s ", iName );
				PrintToChat(client, "\x04[\x01 Zombies killed This Stage: %d ", ckills_check);
				PrintToChat(client, "\x04[\x01 Zombies killed This Campaign: %d ", iKStats[client][0]);
				PrintToChat(client, "\x04[\x01 Head Shots This Stage: %d ", hdShot_check);
				PrintToChat(client, "\x04[\x01 Head Shots This Campaign: %d ", iHStats[client][1]);			
				PrintToChat(client, "\x04[\x01 Head Shot Accuracy This Stage: %d %", hdShotA_check);
				PrintToChat(client, "\x04[\x01 Head Shot Accuracy This Campaign: %d %", hdShotM_check);
				return Plugin_Handled;
}

