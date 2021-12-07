#include <sourcemod>
#include <sdktools>

//globals
#define L4D_MAXCLIENTS 19
#define L4D2_MAXWEAPONNAME 50 //probably not true
new snareArray[L4D_MAXCLIENTS];
new spitArray[L4D_MAXCLIENTS];
new Handle:hPrintChannel;
new Handle:hAllTalk;
new Handle:hTags;
new Handle:hEndRoundAllTalk;
new Handle:hAllowBoomer;
new Handle:hAllowSpitter;
new Handle:hBoomerTime;
new Handle:hSpitterTime;
new Handle:hTwoWayCommunication;
new bool:roundAllTalk;
new Handle:hStartRoundAllTalk;
//The sdk documentation is outdated, these are the correct defines for ClientListening
#define LISTEN_DEFAULT      0   /**< No overwriting is done */
#define LISTEN_NO           1   /**< Disallows the client to listen to the sender */
#define LISTEN_YES          2   /**< Allows the client to listen to the sender */

#define PLUGIN_VERSION "1.9"

#define ISBOOMER 0
#define ISSPITTER 1

public Plugin:myinfo = 
{
	name = "SnareSpeak silpheed mod",
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
	//Spitter addon
	HookEvent("player_hurt",Event_PlayerHurt);

	//Remove notify flag from alltalk/tags to avoid end of round spamming
	hAllTalk = FindConVar("sv_alltalk");
	hTags = FindConVar("sv_tags");
	SetConVarFlags(hAllTalk,(GetConVarFlags(hAllTalk) & ~FCVAR_NOTIFY));
	SetConVarFlags(hTags,(GetConVarFlags(hTags) & ~FCVAR_NOTIFY));
	
	CreateConVar("snarespeak_version",PLUGIN_VERSION,"SnareSpeak Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hPrintChannel = CreateConVar("snarespeak_printchannel","1","Print to player chat when a voice channel is created and destroyed",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hEndRoundAllTalk = CreateConVar("snarespeak_endofround_alltalk","0","Turns on all talk when the round ends",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	hAllowBoomer = CreateConVar("snarespeak_allowboomer","1","Allow the boomer to create an audio channel when it vomits on a survivor.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hAllowSpitter = CreateConVar("snarespeak_allowspitter","1","Allow the spitter to create an audio channel when a survivor wanders into its spit.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hBoomerTime = CreateConVar("snarespeak_boomertime","10","Time in seconds the boomer channel is left open. Set to 0 for expiration when puke wears off.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hSpitterTime = CreateConVar("snarespeak_spittertime","8","Time in seconds the spitter channel is left open. Also retriggers after these many seconds if survivor is still in spit.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
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
	new String:attackerName[MAX_NAME_LENGTH];
	new String:victimName[MAX_NAME_LENGTH];
	
	//Make sure alltalk isn't on
	if(!GetConVarBool(hAllTalk) && !IsFakeClient(victimClient) && !IsFakeClient(attackerClient))
	{
		//Store the victim index in the infected index's position, signaling a channel has been setup
		snareArray[attackerClient] = victimClient;
		//Set up the channel
		if(GetConVarBool(hTwoWayCommunication))
			SetClientListening(victimClient,attackerClient,LISTEN_YES);
		SetClientListening(attackerClient,victimClient,LISTEN_YES);
		
		if(GetConVarBool(hPrintChannel))
		{
			GetClientName(victimClient,victimName,sizeof(victimName));
			GetClientName(attackerClient,attackerName,sizeof(attackerName));
			if(GetConVarBool(hTwoWayCommunication))
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
	new victimClient = snareArray[userClient];
	new String:userName[MAX_NAME_LENGTH];
	new String:victimName[MAX_NAME_LENGTH];

	if(victimClient != 0)
	{
		if(IsClientInGame(victimClient) && IsClientInGame(userClient))
		{
			//Shut down the voice channel link
			SetClientListening(victimClient,userClient,LISTEN_DEFAULT);
			SetClientListening(userClient,victimClient,LISTEN_DEFAULT);
			
			if(GetConVarBool(hPrintChannel))
			{
				GetClientName(victimClient,victimName,sizeof(victimName));
				GetClientName(userClient,userName,sizeof(userName));
				if(GetConVarBool(hTwoWayCommunication))
					PrintToChat(victimClient,"Voice channel destroyed between you and %s", userName);
				PrintToChat(userClient,"Voice channel destroyed between you and %s", victimName);
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
		spitArray[userClient] = 0;
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
	new victimId = GetEventInt(event,"userid");
	new attackerId = GetEventInt(event, "attacker");

	StartBoomerSpitterEffect(ISBOOMER, victimId, attackerId);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:weaponName[L4D2_MAXWEAPONNAME];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	//Spitter's spit is named as "insect_swarm". They must be some pretty crazy insects.
	if (!StrEqual(weaponName,"insect_swarm",false))
		return;
	
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	
	//DamageDebug(event, victimId, attackerId)
	
	StartBoomerSpitterEffect(ISSPITTER, victimId, attackerId);
}

DamageDebug(Handle:event, int:victimId, int:attackerId, string:weaponName)
{
	new String:victimName[MAX_NAME_LENGTH];
	new String:attackerName[MAX_NAME_LENGTH];

	new attackerEntityId = GetEventInt(event, "attackerentid");
	new health = GetEventInt(event, "health");
	new armor = GetEventInt(event, "armor");
	new damage = GetEventInt(event, "dmg_health");
	new damageArmor = GetEventInt(event, "dmg_armor");
	new hitGroup = GetEventInt(event, "hitGroup");
	new type = GetEventInt(event, "type");
	
	new victimClient = GetClientOfUserId(victimId);
	new attackerClient = GetClientOfUserId(attackerId);
	
	
	GetClientName(victimClient,victimName,sizeof(victimName));
	GetClientName(attackerClient,attackerName,sizeof(attackerName));
		
	PrintToChatAll("Damage done: %d %s %d %s %d %d %d %s %d %d %d %d",victimId, victimName, attackerId, attackerName, attackerEntityId, health, armor, weaponName, damage, damageArmor, hitGroup, type);
}

StartBoomerSpitterEffect(int:type, int:victimInt, int:attackerInt)
{
	new attackerClient = GetClientOfUserId(attackerInt);
	new victimClient = GetClientOfUserId(victimInt);
	
	if(GetConVarBool(hAllTalk) || IsFakeClient(victimClient) || IsFakeClient(attackerClient))
		return;
		
	new String:attackerName[MAX_NAME_LENGTH];
	new String:victimName[MAX_NAME_LENGTH];
	new Float:duration;
	
	if (type == ISBOOMER) {
		if (!GetConVarBool(hAllowBoomer))
			return;
		else {
			duration = GetConVarFloat(hBoomerTime);
			//NOTE: This uses the storage array in reverse order of the hunter and smoker. 
			//This is because the boomer and spitter can affect multiple survivors.
			//The victim's index is surely unused (since they're a survivor)
			snareArray[victimClient] = attackerClient;
		}
	}
	if (type == ISSPITTER) {
		if (!GetConVarBool(hAllowSpitter))
			return;
		else {
			duration = GetConVarFloat(hSpitterTime);
			//Don't trigger if already active.
			if (spitArray[victimClient] != 0)
				return;
			//Can't use the same trick as above here as the Boomer already uses the snareArray.
			spitArray[victimClient] = attackerClient;
		}
	}
	
	if(!GetConVarBool(hAllTalk) && !IsFakeClient(victimClient) && !IsFakeClient(attackerClient))
	{
		if ((duration > 0) && (type == ISBOOMER))
			CreateTimer(duration,BoomerTimer,victimClient);
		if ((duration > 0) && (type == ISSPITTER))
			CreateTimer(duration,SpitterTimer,victimClient);
		
		if(GetConVarBool(hTwoWayCommunication))
			SetClientListening(victimClient,attackerClient,LISTEN_YES);
		SetClientListening(attackerClient,victimClient,LISTEN_YES);
		
		if(GetConVarBool(hPrintChannel))
		{
			GetClientName(victimClient,victimName,sizeof(victimName));
			GetClientName(attackerClient,attackerName,sizeof(attackerName));
			if(GetConVarBool(hTwoWayCommunication))
				PrintToChat(victimClient,"Voice channel created between you and %s", attackerName);
			PrintToChat(attackerClient,"Voice channel created between you and %s", victimName);
		}
	}
}

//No longer under the boomer bile's effect.
public Event_PlayerClean(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event,"userid");
	new victimClient = GetClientOfUserId(victimId);
	
	if(GetConVarBool(hAllowBoomer) && GetConVarInt(hBoomerTime) == 0)
		EndBoomerSpitterEffect(ISBOOMER, victimClient);
}

//Timer that raises when the boomer channel should close, and passes the victimClient slot to remove from the infected array.
public Action:BoomerTimer(Handle:timer, any:victimClient)
{
	if(GetConVarBool(hAllowBoomer))
		EndBoomerSpitterEffect(ISBOOMER, victimClient);
}

//Timer that raises when the spitter channel should close, and passes the victimClient slot to remove from the spitter array.
public Action:SpitterTimer(Handle:timer, any:victimClient)
{
	if(GetConVarBool(hAllowSpitter))
		EndBoomerSpitterEffect(ISSPITTER, victimClient);
}

public EndBoomerSpitterEffect(int:type, victimClient)
{
	new attackerClient;
	new String:victimName[MAX_NAME_LENGTH];
	new String:attackerName[MAX_NAME_LENGTH];
	
	//Could have already triggered via timer
	if (type == ISBOOMER) {
		if (snareArray[victimClient] == 0)
			return;
		else
			attackerClient = snareArray[victimClient];
	}
	if (type == ISSPITTER) {
		if (spitArray[victimClient] == 0)
			return;
		else
			attackerClient = spitArray[victimClient];
	}
		
	if((victimClient != 0) && (attackerClient != 0) && IsClientInGame(attackerClient) && IsClientInGame(victimClient))
	{
		//Shut down the voice channel link
		SetClientListening(victimClient,attackerClient,LISTEN_DEFAULT);
		SetClientListening(attackerClient,victimClient,LISTEN_DEFAULT);
		if (type == ISBOOMER)
			snareArray[victimClient] = 0;
		if (type == ISSPITTER)	
			spitArray[victimClient] = 0;
		if(GetConVarBool(hPrintChannel))
		{
			GetClientName(victimClient,victimName,sizeof(victimName));
			GetClientName(attackerClient,attackerName,sizeof(attackerName));
			if(GetConVarBool(hTwoWayCommunication))
				PrintToChat(victimClient,"Voice channel destroyed between you and %s", attackerName);
			PrintToChat(attackerClient,"Voice channel destroyed between you and %s", victimName);
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
