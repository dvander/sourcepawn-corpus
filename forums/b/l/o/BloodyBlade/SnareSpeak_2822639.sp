#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

//globals
#define L4D2_MAXWEAPONNAME 50 //probably not true
int snareArray[MAXPLAYERS + 1],  spitArray[MAXPLAYERS + 1];
ConVar hPrintChannel, hAllTalk, hTags, hEndRoundAllTalk, hAllowBoomer, hAllowSpitter, hBoomerTime, hSpitterTime, hTwoWayCommunication;
bool roundAllTalk;
ConVar hStartRoundAllTalk;
//The sdk documentation is outdated, these are the correct defines for ClientListening
#define LISTEN_DEFAULT      0   /**< No overwriting is done */
#define LISTEN_NO           1   /**< Disallows the client to listen to the sender */
#define LISTEN_YES          2   /**< Allows the client to listen to the sender */

#define PLUGIN_VERSION "1.9"

#define ISBOOMER 0
#define ISSPITTER 1

public Plugin myinfo = 
{
	name = "SnareSpeak silpheed mod",
	author = "n0limit",
	description = "Allows a survivor that is snared by an infected to speak over voice to the captor, and vice-versa",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=94977"
}

public void OnPluginStart()
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
    SetConVarFlags(hAllTalk, (GetConVarFlags(hAllTalk) & ~FCVAR_NOTIFY));
    SetConVarFlags(hTags, (GetConVarFlags(hTags) & ~FCVAR_NOTIFY));
    
    CreateConVar("snarespeak_version",PLUGIN_VERSION,"SnareSpeak Version",FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    hPrintChannel = CreateConVar("snarespeak_printchannel","1","Print to player chat when a voice channel is created and destroyed",FCVAR_SPONLY|FCVAR_NOTIFY);
    hEndRoundAllTalk = CreateConVar("snarespeak_endofround_alltalk","1","Turns on all talk when the round ends",FCVAR_SPONLY|FCVAR_NOTIFY);
    hAllowBoomer = CreateConVar("snarespeak_allowboomer","1","Allow the boomer to create an audio channel when it vomits on a survivor.",FCVAR_SPONLY|FCVAR_NOTIFY);
    hAllowSpitter = CreateConVar("snarespeak_allowspitter","1","Allow the spitter to create an audio channel when a survivor wanders into its spit.",FCVAR_SPONLY|FCVAR_NOTIFY);
    hBoomerTime = CreateConVar("snarespeak_boomertime","10","Time in seconds the boomer channel is left open. Set to 0 for expiration when puke wears off.",FCVAR_SPONLY|FCVAR_NOTIFY);
    hSpitterTime = CreateConVar("snarespeak_spittertime","10","Time in seconds the spitter channel is left open. Also retriggers after these many seconds if survivor is still in spit.",FCVAR_SPONLY|FCVAR_NOTIFY);
    hTwoWayCommunication = CreateConVar("snarespeak_twoway","1","Allow two way communication between attacker and infected. If 0, attacker can hear survivor but not vice-versa");
    hStartRoundAllTalk = CreateConVar("snarespeak_startofround_alltalk","1","Turns all talk on for the beginning of the round until the safe room door is opened.",FCVAR_SPONLY|FCVAR_NOTIFY);
    AutoExecConfig(true,"snarespeak");
}

public void OnPluginEnd()
{
	//Reset the alltalk and tags cvar so notify is re-enabled
	SetConVarFlags(hAllTalk, (GetConVarFlags(hAllTalk) & FCVAR_NOTIFY));
	SetConVarFlags(hTags, (GetConVarFlags(hTags) & FCVAR_NOTIFY));
}

void Event_PlayerGrabbed(Event event, const char[] name, bool dontBroadcast)
{
	int attackerClient = GetClientOfUserId(event.GetInt("userid"));
	int victimClient = GetClientOfUserId(event.GetInt("victim"));
	char attackerName[MAX_NAME_LENGTH], victimName[MAX_NAME_LENGTH];

	//Make sure alltalk isn't on
	if(!hAllTalk.BoolValue && !IsFakeClient(victimClient) && !IsFakeClient(attackerClient))
	{
		//Store the victim index in the infected index's position, signaling a channel has been setup
		snareArray[attackerClient] = victimClient;
		//Set up the channel
		if(hTwoWayCommunication.BoolValue) SetListenOverride(victimClient, attackerClient, Listen_Yes);
		SetListenOverride(attackerClient, victimClient, Listen_Yes);

		if(hPrintChannel.BoolValue)
		{
			GetClientName(victimClient, victimName, sizeof(victimName));
			GetClientName(attackerClient, attackerName, sizeof(attackerName));
			if(hTwoWayCommunication.BoolValue) PrintToChat(victimClient,"\x04Voice channel\x03 Enabled\x04 between you and\x03 %s", attackerName);
			PrintToChat(attackerClient,"\x04Voice channel\x03 Enabled\x04 between you and\x03 %s", victimName);
		}
	}
}

void Event_PlayerRelease(Event event, const char[] name, bool dontBroadcast)
{
	//player who has died
	int userClient = GetClientOfUserId(event.GetInt("userid"));
	int victimClient = snareArray[userClient];
	char userName[MAX_NAME_LENGTH], victimName[MAX_NAME_LENGTH];

	if(victimClient != 0)
	{
		if(IsClientInGame(victimClient) && IsClientInGame(userClient))
		{
			//Shut down the voice channel link
		    SetListenOverride(victimClient, userClient, Listen_Default);
		    SetListenOverride(userClient, victimClient, Listen_Default);

		    if(hPrintChannel.BoolValue)
			{
				GetClientName(victimClient, victimName, sizeof(victimName));
				GetClientName(userClient, userName, sizeof(userName));
				if(hTwoWayCommunication.BoolValue) PrintToChat(victimClient,"\x04Voice channel\x03 Disabled\x04 between you and\x03 %s", userName);
				PrintToChat(userClient,"\x04Voice channel\x03 Disabled\x04 between you and\x03 %s", victimName);
			}
		}
		snareArray[userClient] = 0;
	}
}

/*void Event_PlayerTeamSwitch(Event event, const char[] name, bool dontBroadcast)
{
	int userClient = GetClientOfUserId(event.GetInt("userid"));
	
	if(userClient && !event.GetBool("disconnect") && !hAllTalk.BoolValue)
	{
		//erase possible channel, if one exists
		snareArray[userClient] = 0;
		spitArray[userClient] = 0;
		//assume (hope) for now that team change severs existing channels
		//Set user to default listening options
		SetClientListeningFlags(userClient, VOICE_NORMAL);
	}
}*/

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if(hEndRoundAllTalk.BoolValue && !hAllTalk.BoolValue)
	{
		PrintToChatAll("\x04End of Round AllTalk \x03Enabled");
		SetConVarBool(hAllTalk,true);
		roundAllTalk = true;
	}
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(hAllTalk.BoolValue && roundAllTalk)
	{
		if(hStartRoundAllTalk.BoolValue) PrintToChatAll("\x04Start of Round AllTalk\x03 Enabled");
		else
		{
			PrintToChatAll("\x04End of Round AllTalk\x03 Disabled");
			SetConVarBool(hAllTalk,false);
			roundAllTalk = false;
		}
	}
	else
	{
		if(hStartRoundAllTalk.BoolValue)
		{
			PrintToChatAll("\x04Start of Round AllTalk\x03 Enabled");
			SetConVarBool(hAllTalk,true);
			roundAllTalk = true;
		}
	}
}

void Event_PlayerBoomed(Event event, const char[] name, bool dontBroadcast)
{
	int victimId = event.GetInt("userid");
	int attackerId = event.GetInt("attacker");

	if(victimId && attackerId) StartBoomerSpitterEffect(ISBOOMER, victimId, attackerId);
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	char weaponName[L4D2_MAXWEAPONNAME];
	event.GetString("weapon", weaponName, sizeof(weaponName));
	//Spitter's spit is named as "insect_swarm". They must be some pretty crazy insects.
	if (!StrEqual(weaponName,"insect_swarm",false)) return;

	int victimId = event.GetInt("userid");
	int attackerId = event.GetInt("attacker");

	//DamageDebug(event, victimId, attackerId)

	if(victimId && attackerId) StartBoomerSpitterEffect(ISSPITTER, victimId, attackerId);
}

/*void DamageDebug(Event event, int victimId, int attackerId, char[] weaponName)
{
	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];

	int attackerEntityId = event.GetInt("attackerentid");
	int health = event.GetInt("health");
	int armor = event.GetInt("armor");
	int damage = event.GetInt("dmg_health");
	int damageArmor = event.GetInt("dmg_armor");
	int hitGroup = event.GetInt("hitGroup");
	int type = event.GetInt("type");

	int victimClient = GetClientOfUserId(victimId);
	int attackerClient = GetClientOfUserId(attackerId);

	if(victimClient && attackerClient)
	{
		GetClientName(victimClient, victimName, sizeof(victimName));
		GetClientName(attackerClient, attackerName, sizeof(attackerName));

		PrintToChatAll("Damage done: %d %s %d %s %d %d %d %s %d %d %d %d",victimId, victimName, attackerId, attackerName, attackerEntityId, health, armor, weaponName, damage, damageArmor, hitGroup, type);
	}
}*/

void StartBoomerSpitterEffect(int type, int victimInt, int attackerInt)
{
	int attackerClient = GetClientOfUserId(attackerInt);
	int victimClient = GetClientOfUserId(victimInt);

	if(hAllTalk.BoolValue || IsFakeClient(victimClient) || IsFakeClient(attackerClient))
		return;

	char attackerName[MAX_NAME_LENGTH], victimName[MAX_NAME_LENGTH];
	float duration;
	
	if (type == ISBOOMER)
	{
		if (!hAllowBoomer.BoolValue) return;
		else
		{
			duration = hBoomerTime.FloatValue;
			//NOTE: This uses the storage array in reverse order of the hunter and smoker. 
			//This is because the boomer and spitter can affect multiple survivors.
			//The victim's index is surely unused (since they're a survivor)
			snareArray[victimClient] = attackerClient;
		}
	}
	if (type == ISSPITTER)
	{
		if (!hAllowSpitter.BoolValue) return;
		else
		{
			duration = hSpitterTime.FloatValue;
			//Don't trigger if already active.
			if (spitArray[victimClient] != 0) return;
			//Can't use the same trick as above here as the Boomer already uses the snareArray.
			spitArray[victimClient] = attackerClient;
		}
	}
	
	if(!hAllTalk.BoolValue && !IsFakeClient(victimClient) && !IsFakeClient(attackerClient))
	{
		if ((duration > 0) && (type == ISBOOMER)) CreateTimer(duration, BoomerTimer, victimClient);
		if ((duration > 0) && (type == ISSPITTER)) CreateTimer(duration, SpitterTimer, victimClient);

		if(hTwoWayCommunication.BoolValue) SetListenOverride(victimClient, attackerClient, Listen_Yes);
		SetListenOverride(attackerClient, victimClient, Listen_Yes);

		if(hPrintChannel.BoolValue)
		{
			GetClientName(victimClient, victimName, sizeof(victimName));
			GetClientName(attackerClient, attackerName, sizeof(attackerName));
			if(hTwoWayCommunication.BoolValue) PrintToChat(victimClient,"\x04Voice channel\x03 Enabled\x04 between you and\x03 %s", attackerName);
			PrintToChat(attackerClient,"\x04Voice channel\x03 Enabled\x04 between you and\x03 %s", victimName);
		}
	}
}

//No longer under the boomer bile's effect.
void Event_PlayerClean(Event event, const char[] name, bool dontBroadcast)
{
	int victimClient = GetClientOfUserId(event.GetInt("userid"));

	if(hAllowBoomer.BoolValue && hBoomerTime.IntValue == 0 && victimClient)
		EndBoomerSpitterEffect(ISBOOMER, victimClient);
}

//Timer that raises when the boomer channel should close, and passes the victimClient slot to remove from the infected array.
Action BoomerTimer(Handle timer, any victimClient)
{
	if(hAllowBoomer.BoolValue)
		EndBoomerSpitterEffect(ISBOOMER, victimClient);
	return Plugin_Stop;
}

//Timer that raises when the spitter channel should close, and passes the victimClient slot to remove from the spitter array.
Action SpitterTimer(Handle timer, any victimClient)
{
	if(hAllowSpitter.BoolValue)
		EndBoomerSpitterEffect(ISSPITTER, victimClient);
	return Plugin_Stop;
}

void EndBoomerSpitterEffect(int type, int victimClient)
{
	int attackerClient;
	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];

	//Could have already triggered via timer
	if (type == ISBOOMER)
	{
		if (snareArray[victimClient] == 0) return;
		else attackerClient = snareArray[victimClient];
	}
	if (type == ISSPITTER)
	{
		if (spitArray[victimClient] == 0) return;
		else attackerClient = spitArray[victimClient];
	}

	if((victimClient != 0) && (attackerClient != 0) && IsClientInGame(attackerClient) && IsClientInGame(victimClient))
	{
		//Shut down the voice channel link
		SetListenOverride(victimClient, attackerClient, Listen_Default);
		SetListenOverride(attackerClient, victimClient, Listen_Default);
		if (type == ISBOOMER) snareArray[victimClient] = 0;
		if (type == ISSPITTER) spitArray[victimClient] = 0;
		if(hPrintChannel.BoolValue)
		{
			GetClientName(victimClient, victimName, sizeof(victimName));
			GetClientName(attackerClient, attackerName, sizeof(attackerName));
			if(hTwoWayCommunication.BoolValue) PrintToChat(victimClient,"\x04Voice channel\x03 Disbled\x04 between you and\x03 %s", attackerName);
			PrintToChat(attackerClient,"\x04Voice channel\x03 Disabled\x04 between you and\x03 %s", victimName);
		}
	}
}

void Event_PlayerLeftStartArea(Event event, const char[] name, bool dontBroadcast)
{
	if(hAllTalk.BoolValue && roundAllTalk)
	{
		PrintToChatAll("\x04Start of Round AllTalk\x03 Disabled");
		SetConVarBool(hAllTalk,false);
		roundAllTalk = false;
	}
}
