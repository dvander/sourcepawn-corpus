#include <sourcemod>
#include <sdktools>

//globals
new infectedPosition[32]; //32 clients
new Handle:hPrintChannel;
new Handle:hAllTalk;

//The sdk documentation is outdated, these are the correct defines for SetClientListening
#define LISTEN_DEFAULT      0   /**< No overwriting is done */
#define LISTEN_NO           1   /**< Disallows the client to listen to the sender */
#define LISTEN_YES          2   /**< Allows the client to listen to the sender */

#define PLUGIN_VERSION "1.2"
public Plugin:myinfo = 
{
	name = "SnareSpeak",
	author = "n0limit",
	description = "Allows a survivor that is snared by an infected to speak over voice to the captor, and vice-versa",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=94977"
}

public OnPluginStart()
{
	HookEvent("lunge_pounce",Event_PlayerGrabbed);
	HookEvent("tongue_grab",Event_PlayerGrabbed);
	HookEvent("pounce_end",Event_PlayerRelease);
	HookEvent("tongue_release",Event_PlayerRelease);
	HookEvent("player_team",Event_PlayerTeamSwitch);
	//To shut down the channel when a player becomes tank
	HookEvent("tank_spawn",Event_PlayerRelease);
	
	CreateConVar("snarespeak_version",PLUGIN_VERSION,"SnareSpeak Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hAllTalk = FindConVar("sv_alltalk");
	hPrintChannel = CreateConVar("snarespeak_printchannel","0","Print to player chat when a voice channel is created and destroyed",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Event_PlayerGrabbed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "userid");
	new victimId = GetEventInt(event, "victim");
	new attackerClient = GetClientOfUserId(attackerId);
	new victimClient = GetClientOfUserId(victimId);
	new String:attackerName[MAX_NAME_LENGTH];
	new String:victimName[MAX_NAME_LENGTH];
	
	//Make sure alltalk isn't on
	if(!GetConVarBool(hAllTalk))
	{
		//Store the victim index in the infected index's position, signaling a channel has been setup
		infectedPosition[attackerClient] = victimClient;
		//Set up the channel
		SetClientListening(victimClient,attackerClient,LISTEN_YES);
		SetClientListening(attackerClient,victimClient,LISTEN_YES);
		
		if(GetConVarBool(hPrintChannel))
		{
			GetClientName(victimClient,victimName,sizeof(victimName));
			GetClientName(attackerClient,attackerName,sizeof(attackerName));
			PrintToChat(victimClient,"Voice channel created between you and %s", attackerName);
			PrintToChat(attackerClient,"Voice channel created between you and %s", victimName);
		}
	}
}

public Event_PlayerRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	//player who has died
	new userId = GetEventInt(event, "userid");
	new userClient = GetClientOfUserId(userId);
	new victimClient = infectedPosition[userClient];
	new String:userName[MAX_NAME_LENGTH];
	new String:victimName[MAX_NAME_LENGTH];

	if(victimClient != 0)
	{
		//Shut down the voice channel link
		SetClientListening(victimClient,userClient,LISTEN_NO);
		SetClientListening(userClient,victimClient,LISTEN_NO);
		
		if(GetConVarBool(hPrintChannel))
		{
			GetClientName(victimClient,victimName,sizeof(victimName));
			GetClientName(userClient,userName,sizeof(userName));
			PrintToChat(victimClient,"Voice channel destroyed between you and %s", userName);
			PrintToChat(userClient,"Voice channel destroyed between you and %s", victimName);
		}

		infectedPosition[userClient] = 0;
	}
}

public Event_PlayerTeamSwitch(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:disconnected = GetEventBool(event,"disconnect");
	new userid = GetEventInt(event,"userid");
	new userClient = GetClientOfUserId(userid);
	
	if(!disconnected && !GetConVarBool(hAllTalk))
	{
		//erase possible channel, if one exists
		infectedPosition[userClient] = 0;
		//assume (hope) for now that team change severs existing channels
		//Set user to default listening options
		SetClientListeningFlags(userClient,VOICE_NORMAL);
	}
}