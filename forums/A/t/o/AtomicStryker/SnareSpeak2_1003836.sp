#include <sourcemod>
#include <sdktools>

//globals
#define L4D_MAXCLIENTS 19
new snareArray[L4D_MAXCLIENTS];
new Handle:hPrintChannel;
new Handle:hAllTalk;
new Handle:hTags;
new Handle:hEndRoundAllTalk;
new Handle:hAllowBoomer;
new Handle:hBoomerTime;
new Handle:hTwoWayCommunication;
new bool:roundAllTalk;
new Handle:hStartRoundAllTalk;
//The sdk documentation is outdated, these are the correct defines for ClientListening
#define LISTEN_DEFAULT      0   /**< No overwriting is done */
#define LISTEN_NO           1   /**< Disallows the client to listen to the sender */
#define LISTEN_YES          2   /**< Allows the client to listen to the sender */

#define PLUGIN_VERSION "1.9"

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
	HookEvent("jockey_ride", Event_PlayerGrabbed);
	HookEvent("charger_carry_start", Event_PlayerGrabbed);
	HookEvent("charger_pummel_start", Event_PlayerGrabbed);
	
	HookEvent("pounce_end",Event_PlayerRelease);
	HookEvent("tongue_release",Event_PlayerRelease);
	HookEvent("jockey_ride_end", Event_PlayerRelease);
	HookEvent("charger_carry_end", Event_PlayerRelease);
	HookEvent("charger_pummel_end", Event_PlayerRelease);
	
	//To reset listening channels when switching a team
	//HookEvent("player_team",Event_PlayerTeamSwitch);
	//To shut down the channel when a player becomes tank
	HookEvent("tank_spawn",Event_PlayerRelease);
	//To enable all_talk for end of round
	HookEvent("round_end",Event_RoundEnd);
	HookEvent("round_start",Event_RoundStart);
	HookEvent("player_left_start_area",Event_PlayerLeftStartArea);
	roundAllTalk = false;
	//Boomer addon
	HookEvent("player_now_it",Event_PlayerBoomed);
	HookEvent("player_no_longer_it",Event_PlayerClean);
	
	//Remove notify flag from alltalk/tags to avoid end of round spamming
	hAllTalk = FindConVar("sv_alltalk");
	hTags = FindConVar("sv_tags");
	SetConVarFlags(hAllTalk,(GetConVarFlags(hAllTalk) & ~FCVAR_NOTIFY));
	SetConVarFlags(hTags,(GetConVarFlags(hTags) & ~FCVAR_NOTIFY));
	
	CreateConVar("snarespeak_version",PLUGIN_VERSION,"SnareSpeak Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hPrintChannel = CreateConVar("snarespeak_printchannel","1","Print to player chat when a voice channel is created and destroyed",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hEndRoundAllTalk = CreateConVar("snarespeak_endofround_alltalk","0","Turns on all talk when the round ends",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hAllowBoomer = CreateConVar("snarespeak_allow_boomer","1","Allow the boomer to create an audio channel when it vomits on a survivor.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hBoomerTime = CreateConVar("snarespeak_boomertime","10","Time in seconds the boomer channel is left open. Set to 0 for expiration when puke wears off.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hTwoWayCommunication = CreateConVar("snarespeak_twoway","1","Allow two way communication between attacker and infected. If 0, attacker can hear survivor but not vice-versa");
	hStartRoundAllTalk = CreateConVar("snarespeak_startofround_alltalk","0","Turns all talk on for the beginning of the round until the safe room door is opened.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig(true,"snarespeak");
}
public OnPluginEnd()
{
	//Reset the alltalk and tags cvar so notify is re-enabled
	SetConVarFlags(hAllTalk,(GetConVarFlags(hAllTalk) & FCVAR_NOTIFY));
	SetConVarFlags(hTags,(GetConVarFlags(hTags) & FCVAR_NOTIFY));
}

public Event_PlayerGrabbed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "userid");
	new victimId = GetEventInt(event, "victim");
	new attackerClient = GetClientOfUserId(attackerId);
	new victimClient = GetClientOfUserId(victimId);
	
	//Make sure alltalk isn't on
	if(!GetConVarBool(hAllTalk) && !IsFakeClient(victimClient) && !IsFakeClient(attackerClient))
	{
		//Store the victim index in the infected index's position, signaling a channel has been setup
		snareArray[attackerClient] = victimClient;
		//Set up the channel
		if(GetConVarBool(hTwoWayCommunication))
			SetListenOverride(victimClient,attackerClient,Listen_Yes);
		SetListenOverride(attackerClient,victimClient,Listen_Yes);
		
		if(GetConVarBool(hPrintChannel))
		{
			if(GetConVarBool(hTwoWayCommunication))
				PrintToChat(victimClient,"Voice channel created between you and %N", attackerClient);
			PrintToChat(attackerClient,"Voice channel created between you and %N", victimClient);
		}
	}
}

public Event_PlayerRelease(Handle:event, const String:name[], bool:dontBroadcast)
{
	//player who has died
	new userClient = GetClientOfUserId(GetEventInt(event, "userid"));
	new victimClient = snareArray[userClient];
	
	if(victimClient != 0)
	{
		if(IsClientInGame(victimClient) && IsClientInGame(userClient))
		{
			//Shut down the voice channel link
			SetListenOverride(victimClient,userClient,Listen_Default);
			SetListenOverride(userClient,victimClient,Listen_Default);
			
			if(GetConVarBool(hPrintChannel))
			{
				if(GetConVarBool(hTwoWayCommunication))
					PrintToChat(victimClient,"Voice channel destroyed between you and %N", userClient);
				PrintToChat(userClient,"Voice channel destroyed between you and %N", victimClient);
			}
		}
		snareArray[userClient] = 0;
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
		snareArray[userClient] = 0;
		//assume (hope) for now that team change severs existing channels
		//Set user to default listening options
		SetClientListeningFlags(userClient,VOICE_NORMAL);
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(hEndRoundAllTalk) && !GetConVarBool(hAllTalk))
	{
		PrintToChatAll("\x04End of Round \x03All Talk Enabled");
		SetConVarBool(hAllTalk,true);
		roundAllTalk = true;
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(hAllTalk) && roundAllTalk)
	{
		if(GetConVarBool(hStartRoundAllTalk))
			PrintToChatAll("\x04Start of Round \x03All Talk Enabled");
		else
		{
			PrintToChatAll("\x04End of Round \x03All Talk Disabled");
			SetConVarBool(hAllTalk,false);
			roundAllTalk = false;
		}
	}
	else
	{
		if(GetConVarBool(hStartRoundAllTalk))
		{
			PrintToChatAll("\x04Start of Round \x03All Talk Enabled");
			SetConVarBool(hAllTalk,true);
			roundAllTalk = true;
		}
	}
}

public Event_PlayerBoomed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerClient = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victimClient = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(GetConVarBool(hAllowBoomer) && !GetConVarBool(hAllTalk) && !IsFakeClient(victimClient) && !IsFakeClient(attackerClient) && GetClientTeam(attackerClient) == 3)
	{
		//NOTE: This uses the storage array in reverse order of the hunter and smoker. 
		//This is because the boomer can affect multiple survivors.
		//The victim's index is surely unused (since they're a survivor)
		snareArray[victimClient] = attackerClient;
		
		new Float:boomerTime = GetConVarFloat(hBoomerTime);
		if(boomerTime > 0)
			CreateTimer(boomerTime,BoomerTimer,victimClient);
		
		if(GetConVarBool(hTwoWayCommunication))
			SetListenOverride(victimClient,attackerClient,Listen_Yes);
		SetListenOverride(attackerClient,victimClient,Listen_Yes);
		
		if(GetConVarBool(hPrintChannel))
		{
			if(GetConVarBool(hTwoWayCommunication))
				PrintToChat(victimClient,"Voice channel created between you and %s", attackerClient);
			PrintToChat(attackerClient,"Voice channel created between you and %s", victimClient);
		}
	}
}
//no longer under the boomer bile's effect
public Event_PlayerClean(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimClient = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if(GetConVarBool(hAllowBoomer) && GetConVarInt(hBoomerTime) == 0)
		CloseBoomerChannel(victimClient);
}
//Timer that raises when the boomer channel should close, and passes the victimClient slot to remove from the infected array
public Action:BoomerTimer(Handle:timer, any:victimClient)
{
	if(GetConVarBool(hAllowBoomer))
		CloseBoomerChannel(victimClient);
}

public CloseBoomerChannel(victimClient)
{
	//Could have already triggered via timer
	if(snareArray[victimClient])
	{
		new attackerClient = snareArray[victimClient];
		if(IsClientInGame(attackerClient) && IsClientInGame(victimClient))
		{
			//Shut down the voice channel link
			SetListenOverride(victimClient,attackerClient,Listen_Default);
			SetListenOverride(attackerClient,victimClient,Listen_Default);
			snareArray[victimClient] = 0;
			
			if(GetConVarBool(hPrintChannel))
			{
				if(GetConVarBool(hTwoWayCommunication))
					PrintToChat(victimClient,"Voice channel destroyed between you and %s", attackerClient);
				PrintToChat(attackerClient,"Voice channel destroyed between you and %s", victimClient);
			}
		}
	}
}

public Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(hAllTalk) && roundAllTalk)
	{
		PrintToChatAll("\x04Start of Round \x03All Talk Disabled");
		SetConVarBool(hAllTalk,false);
		roundAllTalk = false;
	}
}
