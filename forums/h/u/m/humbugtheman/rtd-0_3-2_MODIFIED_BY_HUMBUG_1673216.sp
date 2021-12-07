/*
* [TF2] Roll The Dice
* 
* Author: linux_lower
* Date: June 6, 2009
* 
*/
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION 			"0.3.8.2"

#define cDefault				0x01
#define cLightGreen 			0x03
#define cGreen					0x04
#define cDarkGreen  			0x05

#define MAX_GOOD_AWARDS			11

#define AWARD_G_GODMODE			0
#define AWARD_G_TOXIC   		1
#define AWARD_G_HEALTH			2
#define AWARD_G_SPEED			3
#define AWARD_G_NOCLIP  		4
#define AWARD_G_GRAVITY 		5
#define AWARD_G_UBER			6
#define AWARD_G_INVIS			7
#define AWARD_G_INSTANTKILL		8
#define AWARD_G_CLOAK			9
#define AWARD_G_CRITS			10

#define MAX_BAD_AWARDS			11

#define AWARD_B_EXPLODE			0
#define AWARD_B_SNAIL			1
#define AWARD_B_FREEZE			2
#define AWARD_B_TIMEBOMB		3
#define AWARD_B_IGNITE			4
#define AWARD_B_HEALTH			5
#define AWARD_B_DRUG			6
#define AWARD_B_BLIND			7
#define AWARD_B_WEAPONS			8
#define AWARD_B_BEACON			9
#define AWARD_B_TAUNT			10

#define PLAYER_STATUS			0
#define PLAYER_TIMESTAMP		1
#define PLAYER_EFFECT			2
#define PLAYER_EXTRA			3
#define PLAYER_FLAG				4

#define RED_TEAM				2
#define BLUE_TEAM				3

#define DIRTY_HACK				100

#define BLACK					{200,200,200,192}
#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

#define MAX_CHAT_TRIGGERS		15
#define MAX_CHAT_TRIGGER_LENGTH 15

new Handle:c_Enabled   		= INVALID_HANDLE;
new Handle:c_Timelimit		= INVALID_HANDLE;
new Handle:c_Mode	   		= INVALID_HANDLE;
new Handle:c_Disabled  		= INVALID_HANDLE;
new Handle:c_Duration  		= INVALID_HANDLE;
new Handle:c_Teamlimit 		= INVALID_HANDLE;
new Handle:c_Chance	   		= INVALID_HANDLE;
new Handle:c_Distance  		= INVALID_HANDLE;
new Handle:c_Health	   		= INVALID_HANDLE;
new Handle:c_Gravity   		= INVALID_HANDLE;
new Handle:c_Snail	   		= INVALID_HANDLE;
new Handle:c_Trigger   		= INVALID_HANDLE;
new Handle:c_Admin	   		= INVALID_HANDLE;
new Handle:c_Donator		= INVALID_HANDLE;
new Handle:c_DonatorChance 	= INVALID_HANDLE;

new TrackPlayers[MAXPLAYERS+1][5];

new Disabled_Good_Commands[MAX_GOOD_AWARDS];
new Disabled_Bad_Commands[MAX_BAD_AWARDS];

new Handle:PlayerTimers[MAXPLAYERS+1][2]; // 0 for end effects timer & 1 for repeating timer

new String:chatTriggers[MAX_CHAT_TRIGGERS][MAX_CHAT_TRIGGER_LENGTH];
new g_iTriggers = 0;

new g_cloakOffset;
new g_wearableOffset;
new g_shieldOffset;

new bool:g_instantRed = false;
new bool:g_instantBlu = false;

public Plugin:myinfo = 
{
	name = "[TF2] Roll The Dice",
	author = "linux_lover",
	description = "Let's users roll for special temporary powers.",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
}

public OnPluginStart()
{
	CheckGame();
	CreateConVar("sm_rtd_version", PLUGIN_VERSION, "Current RTD Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Enabled   = CreateConVar("sm_rtd_enable",    	"1",        "<0/1> Enable RTD");
	c_Timelimit = CreateConVar("sm_rtd_timelimit",	"120",      "<0-x> Time in seconds between RTDs");
	c_Mode		= CreateConVar("sm_rtd_mode",      	"1",        "<0/1/2> See plugin's webpage for description");
	c_Disabled  = CreateConVar("sm_rtd_disabled",  	"",         "All the effects you want disabled - Seperated by commas");
	c_Duration  = CreateConVar("sm_rtd_duration",  	"20.0",     "<0.1-x> Time in seconds the RTD effects last.");
	c_Teamlimit = CreateConVar("sm_rtd_teamlimit", 	"1",        "<1-x> Number of players on the same team that can RTD in mode 1");
	c_Chance	= CreateConVar("sm_rtd_chance",    	"0.5",      "<0.1-1.0> Chance of a good award.");
	c_Distance  = CreateConVar("sm_rtd_distance",  	"275.0",    "<any float> Distance for toxic kills");
	c_Health    = CreateConVar("sm_rtd_health",    	"1000",    	"<500/2000/5000/etc> Ammount of health given for health award..");
	c_Gravity   = CreateConVar("sm_rtd_gravity",   	"0.1",      "<0.1-x> Gravity multiplier.");
	c_Snail		= CreateConVar("sm_rtd_snail",     	"50.0",     "<1.0-x> Speed for the snail award.");
	c_Admin		= CreateConVar("sm_rtd_admin",	   	"",			"The access flag if you want to make rtd admin only: 'abcz' (must have all flags)");
	c_Donator 	= CreateConVar("sm_rtd_donator",	"",			"The access flag for donators: 'o' (must have all flags)");
	c_DonatorChance = CreateConVar("sm_rtd_dchance","1.0",		"<0.1-1.0> Chance for a good awards for donators");
	
	c_Trigger   = CreateConVar("sm_rtd_trigger",   "rtd,rollthedice,roll", "All the chat triggers - Seperated by commas.");

	RegConsoleCmd("say", Command_rtd);
	RegConsoleCmd("say_team", Command_rtd);
	RegAdminCmd("sm_forcertd", Command_ForceRTD, ADMFLAG_GENERIC);
	RegAdminCmd("sm_randomrtd", Command_RandomRTD, ADMFLAG_GENERIC);
	
	HookEvent("teamplay_round_active", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	for(new i=0; i<MAXPLAYERS+1; i++)
	{
		PlayerTimers[i][0] = INVALID_HANDLE;
		PlayerTimers[i][1] = INVALID_HANDLE;
	}
	
	ResetStatus();
	
	g_cloakOffset = FindSendPropInfo("CTFPlayer", "m_flCloakMeter");
	g_wearableOffset = FindSendPropInfo("CTFWearableItem", "m_hOwnerEntity");
	g_shieldOffset = FindSendPropInfo("CTFWearableItemDemoShield", "m_hOwnerEntity");
	
	LoadTranslations("rtd.phrases.txt");
	
	/* HUMBUG STUFF */
	RegConsoleCmd("explode", Command_Explode);
	RegConsoleCmd("kill", Command_Kill);
}

public OnConfigsExecuted()
{	
	PrintToServer("[RTD] %T", "Server_Loaded", LANG_SERVER, PLUGIN_VERSION);

	HookConVarChange(c_Disabled, ConVarChange_Disable);
	new String:strDisable[200];
	GetConVarString(c_Disabled, strDisable, sizeof(strDisable));
	Parse_Disabled_Commands(strDisable);
	
	CheckForInstantRespawn();
	
	new Handle:hEnabled = FindConVar("sm_respawn_time_enabled");
	new Handle:hRed = FindConVar("sm_respawn_time_red");
	new Handle:hBlue = FindConVar("sm_respawn_time_blue");
	
	if(hEnabled != INVALID_HANDLE)
		HookConVarChange(FindConVar("sm_respawn_time_enabled"), ConVarChange_RespawnEnabled);
	
	if(hRed != INVALID_HANDLE)
		HookConVarChange(FindConVar("sm_respawn_time_red"), ConVarChange_RespawnRed);
	
	if(hBlue != INVALID_HANDLE)
		HookConVarChange(FindConVar("sm_respawn_time_blue"), ConVarChange_RespawnBlue);
	
	HookConVarChange(c_Trigger, ConVarChange_Trigger);
	new String:strTrig[200];
	GetConVarString(c_Trigger, strTrig, sizeof(strTrig));
	Parse_Chat_Triggers(strTrig);
}

public ConVarChange_Trigger(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Parse_Chat_Triggers(newValue);
	PrintToChatAll("[RTD] Chat triggers reparsed.");
}

public ConVarChange_RespawnEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{			
	if(StringToInt(newValue) == 0)
	{
		g_instantBlu = false;
		g_instantRed = false;
	}
}

public ConVarChange_RespawnRed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToFloat(newValue) == 0.0)
	{
		g_instantRed = true;
	}else{
		g_instantRed = false;
	}
}

public ConVarChange_RespawnBlue(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(StringToFloat(newValue) == 0.0)
	{
		g_instantBlu = true;
	}else{
		g_instantBlu = false;
	}
}

public ConVarChange_Disable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Parse_Disabled_Commands(newValue);
	PrintToChatAll("[SM] RTD Disabled commands reparsed.");
}

public OnMapStart()
{
	ResetStatus();
}

public Action:Command_ForceRTD(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] sm_forcertd <target>");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		ForceRTD(target_list[i]);
	}
	
	return Plugin_Handled;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetConVarInt(c_Enabled))
		PrintToChatAll("%c[RTD]%c %T", cGreen, cDefault, "Announcement_Message", LANG_SERVER, cGreen, cDefault);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(c_Enabled))
	{	
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if(TrackPlayers[client][PLAYER_FLAG])
		{
			new userid = GetEventInt(event, "userid");
			
			switch(TrackPlayers[client][PLAYER_FLAG])
			{
				case AWARD_B_BEACON:
				{
					ServerCommand("sm_beacon #%d", userid);
				}
				case AWARD_B_DRUG:
				{
					ServerCommand("sm_drug #%d", userid);
				}
				case AWARD_B_FREEZE:
				{
					ServerCommand("sm_freeze #%d", userid);
				}
				case AWARD_B_TIMEBOMB:
				{
					ServerCommand("sm_timebomb #%d", userid);
				}
			}
			
			TrackPlayers[client][PLAYER_FLAG] = 0;
		}
		
		/*
		// Fail-safe I guess, can't see this happening
		if(TrackPlayers[client][PLAYER_STATUS])
		{
			CleanPlayer(client);
			TrackPlayers[client][PLAYER_TIMESTAMP] = GetTime();
			
			decl String:message[200];
			Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Effect_Off", LANG_SERVER, cLightGreen, client, cDefault);

			SayText2(client, message);
			TrackPlayers[client][PLAYER_EXTRA] = 0;
		}
		*/
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!TrackPlayers[attackerId][PLAYER_STATUS]) return Plugin_Continue;
	
	// If player has instant kills
	if(TrackPlayers[attackerId][PLAYER_EFFECT] == AWARD_G_INSTANTKILL + DIRTY_HACK)
	{
		new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
		if(attackerId == victimId) return Plugin_Continue;
		
		// Uber exception
		if(victimId <= 0 || victimId > MaxClients || GetEntProp(victimId, Prop_Send, "m_nPlayerCond") & 32) return Plugin_Continue;
		
		new iHealth = GetEventInt(event, "health");
		
		// Make sure we don't kill them twice
		if(iHealth > 0)
		{			
			SetEntProp(victimId, Prop_Data, "m_iHealth", 0);
		}
		
		PrintToChat(victimId, "%c[RTD]%c %T", cGreen, cDefault, "Instantkill_Notify", LANG_SERVER, cGreen, attackerId, cDefault);
	}
	
	return Plugin_Continue;
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
		if(!TrackPlayers[client][PLAYER_STATUS]) return Plugin_Continue;
		
		if(TrackPlayers[client][PLAYER_EFFECT] == (AWARD_G_CRITS + DIRTY_HACK))
		{
			result = true;
			return Plugin_Handled;
		}

		return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new death_ringer = GetEventInt(event, "death_flags");
	if(death_ringer & 32) return Plugin_Continue;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!TrackPlayers[client][PLAYER_STATUS]) return Plugin_Continue;
	
	// Code that is needed to reverse RTD effects on DEATH
	if(TrackPlayers[client][PLAYER_EFFECT] >= DIRTY_HACK)
	{
		TrackPlayers[client][PLAYER_EFFECT] -= DIRTY_HACK;
		
		switch(TrackPlayers[client][PLAYER_EFFECT])
		{
			case AWARD_G_GRAVITY:
			{
				SetEntityGravity(client, 1.0);
			}
			case AWARD_G_INVIS:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_TOXIC:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_GODMODE:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_INSTANTKILL:
			{
				Colorize(client, NORMAL);
			}
		}
	}else{
		/* Not needed yet
		switch(TrackPlayers[client][PLAYER_EFFECT])
		{
		}
		*/
		
		// Special respawn case for servers running instant respawn @ 0.0
		// By this time, the players are already dead, so we need to toggle
		// the effects when they spawn again. Set a flag here.
		if((g_instantBlu && (GetClientTeam(client) == BLUE_TEAM)) || (g_instantRed && (GetClientTeam(client) == RED_TEAM)))
		{
			switch(TrackPlayers[client][PLAYER_EFFECT])
			{
				case AWARD_B_BEACON:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_BEACON;
				}
				case AWARD_B_DRUG:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_DRUG;
				}
				case AWARD_B_FREEZE:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_FREEZE;
				}
				case AWARD_B_TIMEBOMB:
				{
					TrackPlayers[client][PLAYER_FLAG] = AWARD_B_TIMEBOMB;
				}
			}
		}
	}	
	
	CleanPlayer(client);
	TrackPlayers[client][PLAYER_TIMESTAMP] = GetTime();
	
	decl String:message[200];
	Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Player_Died", LANG_SERVER, cLightGreen, client, cDefault);

	SayText2(client, message);
	
	return Plugin_Continue;
}

public Parse_Chat_Triggers(const String:strTriggers[])
{
	g_iTriggers = ExplodeString(strTriggers, ",", chatTriggers, MAX_CHAT_TRIGGERS, MAX_CHAT_TRIGGER_LENGTH);
}

public Parse_Disabled_Commands(const String:strDisabled[])
{
	for(new i=0; i<MAX_BAD_AWARDS; i++)
		Disabled_Bad_Commands[i] = 0;
	
	for(new i=0; i<MAX_GOOD_AWARDS; i++)
		Disabled_Good_Commands[i] = 0;
	
	if(StrContains(strDisabled, "godmode") >= 0) 		Disabled_Good_Commands[AWARD_G_GODMODE] = 1;
	if(StrContains(strDisabled, "toxic") >= 0) 			Disabled_Good_Commands[AWARD_G_TOXIC] = 1;
	if(StrContains(strDisabled, "goodhealth") >= 0) 	Disabled_Good_Commands[AWARD_G_HEALTH] = 1;
	if(StrContains(strDisabled, "speed") >= 0) 			Disabled_Good_Commands[AWARD_G_SPEED] = 1;
	if(StrContains(strDisabled, "noclip") >= 0) 		Disabled_Good_Commands[AWARD_G_NOCLIP] = 1;
	if(StrContains(strDisabled, "gravity") >= 0) 		Disabled_Good_Commands[AWARD_G_GRAVITY] = 1;
	if(StrContains(strDisabled, "uber") >= 0) 			Disabled_Good_Commands[AWARD_G_UBER] = 1;
	if(StrContains(strDisabled, "invis") >= 0) 			Disabled_Good_Commands[AWARD_G_INVIS] = 1;
	if(StrContains(strDisabled, "instantkill") >= 0)	Disabled_Good_Commands[AWARD_G_INSTANTKILL] = 1;
	if(StrContains(strDisabled, "cloak") >= 0) 			Disabled_Good_Commands[AWARD_G_CLOAK] = 1;
	if(StrContains(strDisabled, "crits") >= 0) 			Disabled_Good_Commands[AWARD_G_CRITS] = 1;
	
	if(StrContains(strDisabled, "explode") >= 0) 		Disabled_Bad_Commands[AWARD_B_EXPLODE] = 1;
	if(StrContains(strDisabled, "snail") >= 0) 			Disabled_Bad_Commands[AWARD_B_SNAIL] = 1;
	if(StrContains(strDisabled, "freeze") >= 0) 		Disabled_Bad_Commands[AWARD_B_FREEZE] = 1;
	if(StrContains(strDisabled, "timebomb") >= 0)		Disabled_Bad_Commands[AWARD_B_TIMEBOMB] = 1;
	if(StrContains(strDisabled, "ignite") >= 0) 		Disabled_Bad_Commands[AWARD_B_IGNITE] = 1;
	if(StrContains(strDisabled, "badhealth") >= 0) 		Disabled_Bad_Commands[AWARD_B_HEALTH] = 1;
	if(StrContains(strDisabled, "drug") >= 0) 			Disabled_Bad_Commands[AWARD_B_DRUG] = 1;
	if(StrContains(strDisabled, "blind") >= 0) 			Disabled_Bad_Commands[AWARD_B_BLIND] = 1;
	if(StrContains(strDisabled, "weapons") >= 0) 		Disabled_Bad_Commands[AWARD_B_WEAPONS] = 1;
	if(StrContains(strDisabled, "beacon") >= 0) 		Disabled_Bad_Commands[AWARD_B_BEACON] = 1;
	if(StrContains(strDisabled, "taunt") >= 0) 			Disabled_Bad_Commands[AWARD_B_TAUNT] = 1;
	
	new goodCounter, badCounter;
	
	for(new i=0; i<MAX_GOOD_AWARDS; i++)
		if(Disabled_Good_Commands[i]) goodCounter++;
	
	for(new i=0; i<MAX_BAD_AWARDS; i++)
		if(Disabled_Bad_Commands[i]) badCounter++;
		
	if(goodCounter >= MAX_GOOD_AWARDS || badCounter >= MAX_BAD_AWARDS)
	{
		PrintToServer("[RTD] %T", "Server_Disable_Message", LANG_SERVER);
		PrintToChatAll("[RTD] %T", "Server_Disable_Message", LANG_SERVER);
	}
}

public ResetStatus()
{
	for(new i=0; i<MAXPLAYERS+1; i++)
	{
		CleanPlayer(i);
		TrackPlayers[i][PLAYER_FLAG] = 0;
	}
}

public OnClientDisconnect(client)
{	
	if(TrackPlayers[client][PLAYER_STATUS])
		PrintToChatAll("%c[RTD]%c %T", cGreen, cDefault, "Player_Disconnect", LANG_SERVER);
	
	CleanPlayer(client);
	TrackPlayers[client][PLAYER_FLAG] = 0;
}

public Action:Command_RandomRTD(client, args)
{
	new arrayPlayers[MaxClients];
	new index = 0;
	
	for(new i=1; i<MaxClients; i++)
	{
		if(IsClientConnected(i) && IsPlayerAlive(i) && !IsFakeClient(i) && !TrackPlayers[i][PLAYER_STATUS])
		{
			arrayPlayers[index] = i;
			index++;
		}
	}
	
	if(index > 0)
	{
		new victim = arrayPlayers[GetRandomInt(0, index-1)];
		
		if(ForceRTD(victim))
		{
			ReplyToCommand(client, "%c[SM]%c %N was forced to roll", cGreen, cDefault, victim);
		}else{
			ReplyToCommand(client, "%c[SM]%c Error occured.", cGreen, cDefault);
		}
	}else{
		ReplyToCommand(client, "%c[SM]%c No one to target.", cGreen, cDefault);
	}
	
	return Plugin_Handled;
}

stock bool:ForceRTD(client)
{
	// Check to see if client is valid
	if(client <= 0 || !IsClientConnected(client)) return false;	
	
	// Check to see if the person is already rtd'ing
	if(TrackPlayers[client][PLAYER_STATUS])	return false;
	
	if(!IsPlayerAlive(client)) return false;
	
	new bool:success = RollTheDice(client);
	
	if(!success)
		return false;
	
	return true;
}

public Action:Command_rtd(client, args)
{
	// Check to see if client is valid
	if(client <= 0 || !IsClientInGame(client) || !GetConVarInt(c_Enabled)) return Plugin_Continue;
	
	// Check the admin flag cvar
	decl String:strFlags[20];
	GetConVarString(c_Admin, strFlags, sizeof(strFlags));
	if(strlen(strFlags) > 0)
	{
		if(!CheckAdminFlagsByString(client, strFlags))
			return Plugin_Continue;
	}
	
	decl String:strMessage[128];
	GetCmdArgString(strMessage, sizeof(strMessage));
	
	// Check for chat triggers
	new startidx = 0;
	if(strMessage[0] == '"')
	{
		startidx = 1;
		new len = strlen(strMessage);
		
		if(strMessage[len-1] == '"') strMessage[len-1] = '\0';
	}
	
	new bool:cond = false;
	for(new i=0; i<g_iTriggers; i++)
	{
		if(StrEqual(chatTriggers[i], strMessage[startidx], false))
		{
			cond = true;
			continue;
		}
	}
	
	if(StrEqual("!rtd", strMessage[startidx], false)) cond = true;
	
	if(!cond) return Plugin_Continue;
	
	// Check to see if the person is already rtd'ing
	if(TrackPlayers[client][PLAYER_STATUS])
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Already", LANG_SERVER);
		return Plugin_Handled;
	}
	
	// Check to see if the person has waited long enough
	new timeleft = GetTime() - TrackPlayers[client][PLAYER_TIMESTAMP];
	if(TrackPlayers[client][PLAYER_TIMESTAMP] > 0 && timeleft < GetConVarInt(c_Timelimit))
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Wait", LANG_SERVER, cGreen, (GetConVarInt(c_Timelimit)-timeleft), cDefault);
		return Plugin_Handled;
	}
	
	// Check to see if the player is still alive
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Alive", LANG_SERVER);
		return Plugin_Handled;
	}
	
	switch(GetConVarInt(c_Mode))
	{
		// Only one player can rtd at a time
		case 1:
			for(new i=1; i<MAXPLAYERS+1; i++)
			{
				if(TrackPlayers[i][PLAYER_STATUS])
				{
					decl String:message[200];
					Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Player_Occupied_Mode1", LANG_SERVER, cLightGreen, i, cDefault);
					
					// Another player is rtd'ing
					SayText2One(client, i, message);
					return Plugin_Handled;
				}
			}
		
		// Verify that only X ammount of players on a team can rtd
		case 2:
		{
			new counter;
			for(new i=1; i<MAXPLAYERS+1; i++)
			{
				if(TrackPlayers[i][PLAYER_STATUS])
				{
					if(GetClientTeam(i)==GetClientTeam(client))
						counter++;
				}
			}
			
			if(counter >= GetConVarInt(c_Teamlimit))
			{
				PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Player_Occupied_Mode2", LANG_SERVER);
				return Plugin_Handled;
			}
		}
	}
	
	// Player has passed all the checks
	new bool:success = RollTheDice(client);
	
	if(!success)
	{
		PrintToChat(client, "%c[RTD]%c %T", cGreen, cDefault, "Disable_Overload", LANG_SERVER);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

bool:RollTheDice(client)
{
	new bool:goodCommand = false;
	
	new Float:fChance = GetConVarFloat(c_Chance);
	// Check the admin flag cvar
	decl String:strFlags[20];
	GetConVarString(c_Donator, strFlags, sizeof(strFlags));
	if(strlen(strFlags) > 0)
	{
		if(CheckAdminFlagsByString(client, strFlags))
			fChance = GetConVarFloat(c_DonatorChance);
	}
	if(fChance > GetRandomFloat(0.0, 1.0)) goodCommand = true;
	
	new bound;
	if(goodCommand) bound = MAX_GOOD_AWARDS; else bound = MAX_BAD_AWARDS;
	
	new bool:foundAward = false;
	/* Method of selection:
	* 1. Pick a random number
	* 2. If it is not suitable, increment from that position until we find one that is.
	*/
	new award = GetRandomInt(0, bound-1);
	
	if(UnAcceptable(client, goodCommand, award))
	{
		for(new i=award+1; i<bound; i++)
		{
			// Double negative, lol
			if(!UnAcceptable(client, goodCommand, i))
			{
				foundAward = true;
				award = i;
				break;
			}				
		}
		
		// If we still haven't found it, let's start from the begining again
		if(!foundAward)
		{
			for(new i=0; i<award; i++)
			{
				if(!UnAcceptable(client, goodCommand, i))
				{
					foundAward = true;
					award = i;
					break;
				}
			}
		}
	}else{
		foundAward = true;
	}
	
	// Give up
	if(!foundAward)
	{
		return false;
	}
	
	GivePlayerEffect(client, goodCommand, award);
	return true;
}

public bool:UnAcceptable(client, bool:goodCommand, award)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	if(goodCommand)
	{
		if(Disabled_Good_Commands[award]) return true;		
		
		if(award == AWARD_G_UBER && class != TFClass_Medic) return true;
		if(award == AWARD_G_CLOAK && class != TFClass_Spy) return true;	
		if(award == AWARD_G_SPEED && (class == TFClass_Heavy || class == TFClass_Sniper)) return true;
	}else{ // Bad Command
		if(Disabled_Bad_Commands[award]) return true;
		
		if(award == AWARD_B_SNAIL && (class == TFClass_Heavy || class == TFClass_Sniper)) return true;
	}
	
	return false;
}

public GivePlayerEffect(client, bool:goodCommand, award)
{
	decl String:message[200];
	
	ResetTimers(client);
	
	// MASSIVE SWITCH STATEMENT
	if(goodCommand)
	{
		switch(award)
		{
			case AWARD_G_GODMODE:
			{
				// Setup the proper translation message				
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Godmode_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				// Enable Godmode
				SetGodmode(client, true);
				Colorize(client, BLACK);
				
				// Mark that the player is rtd'ing
				TrackPlayers[client][PLAYER_STATUS] = 1;
				TrackPlayers[client][PLAYER_EXTRA] = GetConVarInt(c_Duration);
				
				// Setup the timer
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);	
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_TOXIC:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Toxic_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);

				// Make the toxic player black
				Colorize(client, BLACK);

				TrackPlayers[client][PLAYER_STATUS] = 1;

				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);	
				PlayerTimers[client][1] = CreateTimer(0.5, Timer_Toxic, client, TIMER_REPEAT);
			}
			case AWARD_G_HEALTH:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Good_Health_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				SetEntProp(client, Prop_Data, "m_iHealth", GetConVarInt(c_Health));

				CreateParticle("healhuff_red", 5.0, client);
				CreateParticle("healhuff_blu", 5.0, client);
			}
			case AWARD_G_SPEED:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Speed_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = RoundToFloor(GetEntPropFloat(client, Prop_Send, "m_flMaxspeed"));
				SetEntDataFloat(client, FindSendPropInfo("CTFPlayer", "m_flMaxspeed"), 400.0);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_G_NOCLIP:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Noclip_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				SetEntityMoveType(client, MOVETYPE_NOCLIP);
				
				TrackPlayers[client][PLAYER_EXTRA] = GetConVarInt(c_Duration);
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_GRAVITY:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Gravity_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				SetEntityGravity(client, GetConVarFloat(c_Gravity));
				
				TrackPlayers[client][PLAYER_EXTRA] = GetConVarInt(c_Duration);
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);				
			}
			case AWARD_G_UBER:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Uber_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				TF_SetUberLevel(client, 100);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Uber, client, TIMER_REPEAT);
			}
			case AWARD_G_INVIS:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Invis_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				Colorize(client, INVIS);
				
				TrackPlayers[client][PLAYER_EXTRA] = GetConVarInt(c_Duration);
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_INSTANTKILL:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Instantkill_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				Colorize(client, BLACK);
				
				TrackPlayers[client][PLAYER_EXTRA] = GetConVarInt(c_Duration);
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
			case AWARD_G_CLOAK:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Cloak_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				TF_SetCloak(client, 100.0);
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Cloak, client, TIMER_REPEAT);
			}
			case AWARD_G_CRITS:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Crits_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = GetConVarInt(c_Duration);
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(1.0, Timer_Countdown, client, TIMER_REPEAT);
			}
		}
		award += DIRTY_HACK; // dirty workaround - oh well
	}else{ // Bad Command
		switch(award)
		{
			case AWARD_B_EXPLODE:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Explode_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				FakeClientCommand(client, "explode");
			}
			case AWARD_B_SNAIL:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Snail_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				TrackPlayers[client][PLAYER_EXTRA] = RoundToFloor(GetEntPropFloat(client, Prop_Send, "m_flMaxspeed"));
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetConVarFloat(c_Snail));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_FREEZE:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Freeze_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				ServerCommand("sm_freeze #%d %d", GetClientUserId(client), GetConVarInt(c_Duration));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_TIMEBOMB:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Timebomb_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				ServerCommand("sm_timebomb #%d", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][1] = CreateTimer(GetConVarFloat(c_Duration)-0.5, Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_IGNITE:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Ignite_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				TF2_IgnitePlayer(client, client);
			}
			case AWARD_B_HEALTH:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Bad_Health_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				SetEntProp(client, Prop_Data, "m_iHealth", 1);
			}
			case AWARD_B_DRUG:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Drug_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);

				ServerCommand("sm_drug #%d 1", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_BLIND:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Blind_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				ServerCommand("sm_blind #%d 255", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_WEAPONS:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Weapons_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault);
				
				StripToMelee(client);
			}
			case AWARD_B_BEACON:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Beacon_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				ServerCommand("sm_beacon #%d", GetClientUserId(client));
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
			}
			case AWARD_B_TAUNT:
			{
				Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Taunt_Start", LANG_SERVER, cLightGreen, client, cDefault, cGreen, cDefault, cGreen, GetConVarInt(c_Duration), cDefault);
				
				ClientCommand(client, "taunt");
				
				TrackPlayers[client][PLAYER_STATUS] = 1;
				
				PlayerTimers[client][0] = CreateTimer(GetConVarFloat(c_Duration), Timer_RemovePlayerEffect, client, TIMER_REPEAT);
				PlayerTimers[client][1] = CreateTimer(0.5, Timer_Taunt, client, TIMER_REPEAT);
			}
		}
	}

	// Mark the effect that the player is using. Timer_RemovePlayerEffect will read this later
	TrackPlayers[client][PLAYER_EFFECT] = award;
	TrackPlayers[client][PLAYER_TIMESTAMP] = GetTime();
	
	SayText2(client, message);
	
	return;
}

public Action:Timer_RemovePlayerEffect(Handle:Timer, any:client)
{
	if(!IsClientInGame(client)) { PlayerTimers[client][0] = INVALID_HANDLE; return Plugin_Handled; }
	
	if(TrackPlayers[client][PLAYER_EFFECT] >= DIRTY_HACK) // Good command
	{
		TrackPlayers[client][PLAYER_EFFECT] -= DIRTY_HACK;

		switch(TrackPlayers[client][PLAYER_EFFECT])
		{
			case AWARD_G_GODMODE:
			{				
				// Disable Godmode
				SetGodmode(client, false);
				Colorize(client, NORMAL);
			}
			case AWARD_G_TOXIC:
			{
				// Return the player's color
				Colorize(client, NORMAL);
				// Toxic timer should be terminated below
			}
			case AWARD_G_NOCLIP:
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
			case AWARD_G_GRAVITY:
			{
				SetEntityGravity(client, 1.0);
			}
			case AWARD_G_INVIS:
			{
				Colorize(client, NORMAL);
			}
			case AWARD_G_SPEED:
			{				
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", float(TrackPlayers[client][PLAYER_EXTRA]));
			}
			case AWARD_G_INSTANTKILL:
			{
				Colorize(client, NORMAL);
			}
		}
	}else{ // Bad Command
		switch(TrackPlayers[client][PLAYER_EFFECT])
		{
			case AWARD_B_SNAIL:
			{
				SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", float(TrackPlayers[client][PLAYER_EXTRA]));
			}
			case AWARD_B_BLIND:
			{
				ServerCommand("sm_blind #%d 0", GetClientUserId(client));
			}
			case AWARD_B_DRUG:
			{
				ServerCommand("sm_drug #%d", GetClientUserId(client));
			}
			case AWARD_B_BEACON:
			{
				ServerCommand("sm_beacon #%d", GetClientUserId(client));
			}
		}
	}

	// Mark that the player is no longer rtd'ing
	TrackPlayers[client][PLAYER_STATUS] = 0;
	TrackPlayers[client][PLAYER_EFFECT] = 0;
	
	// Set a new timestamp
	TrackPlayers[client][PLAYER_TIMESTAMP] = GetTime();

	CheckSecondTimer(client);

	decl String:message[200];
	Format(message, sizeof(message), "%c[RTD]%c %T", cGreen, cDefault, "Effect_Off", LANG_SERVER, cLightGreen, client, cDefault);

	SayText2(client, message);
	
	PlayerTimers[client][0] = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:Timer_Uber(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_G_UBER + DIRTY_HACK) return Plugin_Stop;
	
	TF_SetUberLevel(client, 100);
	
	return Plugin_Continue;
}

public Action:Timer_Cloak(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_G_CLOAK + DIRTY_HACK) return Plugin_Stop;
	
	TF_SetCloak(client, 100.0);
	
	return Plugin_Continue;
}

public Action:Timer_Countdown(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS]) return Plugin_Stop;
	
	TrackPlayers[client][PLAYER_EXTRA]--;
	
	PrintCenterText(client, "%i", TrackPlayers[client][PLAYER_EXTRA]);
	
	return Plugin_Continue;
}

public Action:Timer_Taunt(Handle:timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_B_TAUNT) return Plugin_Stop;
	
	ClientCommand(client, "taunt");
	
	return Plugin_Continue;
}

public Action:Timer_Toxic(Handle:Timer, any:client)
{
	if(!TrackPlayers[client][PLAYER_STATUS] || TrackPlayers[client][PLAYER_EFFECT] != AWARD_G_TOXIC + DIRTY_HACK) return Plugin_Stop;
	
	new Float:vec[3];
	GetClientEyePosition(client, vec);
	
	new team = GetClientTeam(client);
	
	for(new i=1; i<=MaxClients; i++)
	{
		// Check for a valid client
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		
		// Check to make sure the player is on the other team
		if(GetClientTeam(i) == team) continue;
		
		// Godmode/uber exception
		if(GetEntProp(i, Prop_Data, "m_takedamage", 1) == 0 || GetEntProp(i, Prop_Send, "m_nPlayerCond") & 32) continue;
		
		if(TrackPlayers[i][PLAYER_STATUS] && TrackPlayers[i][PLAYER_EFFECT] == AWARD_G_GODMODE + DIRTY_HACK) continue;
		
		new Float:pos[3];
		GetClientEyePosition(i, pos);
		
		new Float:distance = GetVectorDistance(vec, pos);
		
		if(distance < GetConVarFloat(c_Distance))
		{
			KillPlayer(i, client);
			PrintToChat(i, "%c[RTD]%c %T", cGreen, cDefault, "Toxic_Notify", LANG_SERVER, client);
		}
	}
	
	return Plugin_Continue;
}

public CheckSecondTimer(client)
{
	// Check to see if the secondary timer is running
	if(PlayerTimers[client][1] != INVALID_HANDLE)
	{
		KillTimer(PlayerTimers[client][1]);
		PlayerTimers[client][1] = INVALID_HANDLE;
	}
	
	return;
}

public Colorize(client, color[4])
{
	new maxents = GetMaxEntities();
	// Colorize player and weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	

	for(new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
	
		if(weapon > -1 )
		{
			decl String:strClassname[250];
			GetEdictClassname(weapon, strClassname, sizeof(strClassname));
			if(StrContains(strClassname, "tf_weapon") == -1) continue;
			
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1],color[2], color[3]);
		}
	}
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	// Colorize any wearable items
	for(new i=MaxClients+1; i <= maxents; i++)
	{
		if(!IsValidEntity(i)) continue;
		
		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		
		if(strcmp(netclass, "CTFWearableItem") == 0)
		{
			if(GetEntDataEnt2(i, g_wearableOffset) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}else if(strcmp(netclass, "CTFWearableItemDemoShield") == 0)
		{
			if(GetEntDataEnt2(i, g_shieldOffset) == client)
			{
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if(iWeapon && IsValidEntity(iWeapon))
		{
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iWeapon, color[0], color[1], color[2], color[3]);
		}
	}
	
	return;
}

public SetGodmode(client, bool:playerState)
{
	if(playerState)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}else{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
	}
	
	return;
}

public ResetTimers(client)
{
	if(PlayerTimers[client][0] != INVALID_HANDLE)
	{
		KillTimer(PlayerTimers[client][0]);
		PlayerTimers[client][0] = INVALID_HANDLE;
	}
	
	if(PlayerTimers[client][1] != INVALID_HANDLE)
	{
		KillTimer(PlayerTimers[client][1]);
		PlayerTimers[client][1] = INVALID_HANDLE;
	}
	
	return;
}

public CleanPlayer(client)
{
	TrackPlayers[client][PLAYER_STATUS] = 0;
	TrackPlayers[client][PLAYER_EXTRA] = 0;
	TrackPlayers[client][PLAYER_EFFECT] = 0;	
	
	ResetTimers(client);
	
	return;
}

stock SayText2(author_index , const String:message[] ) 
{
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) 
	{
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}

stock SayText2One( client_index , author_index , const String:message[] ) 
{
    new Handle:buffer = StartMessageOne("SayText2", client_index);
    if (buffer != INVALID_HANDLE) 
	{
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}  

StripToMelee(client) 
{
	if(IsClientInGame(client) && IsPlayerAlive(client)) 
	{
		for(new i = 0; i <= 5; i++)
		{
			if(i != 2)
			{
				if(TF2_GetPlayerClass(client) != TFClass_Spy)
				{
					TF2_RemoveWeaponSlot(client, i);
				}else{
					if(i != 4)
						TF2_RemoveWeaponSlot(client, i);
				}
			}
		}
			
		new weapon = GetPlayerWeaponSlot(client, 2);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

CheckGame()
{
	new String:strGame[10];
	GetGameFolderName(strGame, sizeof(strGame));
	
	if(!StrEqual(strGame, "tf"))
	{
		SetFailState("[RTD] Detected game other than TF2. This plugin is only supported for TF2.");
	}
}

CheckForInstantRespawn()
{
	new Handle:enabled = FindConVar("sm_respawn_time_enabled");
	if(enabled == INVALID_HANDLE || GetConVarInt(enabled) <= 0) return;	
	
	new Handle:red = FindConVar("sm_respawn_time_red");
	new Handle:blu = FindConVar("sm_respawn_time_blue");
	
	if(red != INVALID_HANDLE)	
		if(GetConVarFloat(red) == 0.0)
			g_instantRed = true;
	
	if(blu != INVALID_HANDLE)
		if(GetConVarFloat(blu) == 0.0)
			g_instantBlu = true;
}

public Action:Timer_DeleteParticle(Handle:timer, any:iParticle)
{
	if(IsValidEdict(iParticle))
	{
		decl String:strClassname[50];
		GetEdictClassname(iParticle, strClassname, sizeof(strClassname));
		
		if(StrEqual(strClassname, "info_particle_system", false))
			RemoveEdict(iParticle);
	}
}

stock TF_SetUberLevel(client, uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}

stock TF_SetCloak(client, Float:cloaklevel)
{
	SetEntDataFloat(client, g_cloakOffset, cloaklevel);
}

stock CreateParticle(const String:strType[], Float:flTime, iEntity)
{
	new iParticle = CreateEntityByName("info_particle_system");
	
	if(!IsValidEdict(iParticle)) return;
	
	new Float:flPos[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
	TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(iParticle, "effect_name", strType);
	
	SetVariantString("!activator");
	AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);
	
	SetVariantString("head");
	AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);
	
	DispatchKeyValue(iParticle, "targetname", "particle");
	
	DispatchSpawn(iParticle);
	ActivateEntity(iParticle);
	AcceptEntityInput(iParticle, "Start");
	
	CreateTimer(flTime, Timer_DeleteParticle, iParticle);
}

KillPlayer(client, attacker)
{
	new ent = CreateEntityByName("env_explosion");
	
	if (IsValidEntity(ent))
	{
		DispatchKeyValue(ent, "iMagnitude", "1000");
		DispatchKeyValue(ent, "iRadiusOverride", "2");
		SetEntPropEnt(ent, Prop_Data, "m_hInflictor", attacker);
		SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", attacker);
		DispatchKeyValue(ent, "spawnflags", "3964");
		DispatchSpawn(ent);
		
		new Float:pos[3];
		GetClientAbsOrigin(client, pos);
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(ent, "explode", client, client);
		CreateTimer(0.2, RemoveExplosion, ent);
	}
}

public Action:RemoveExplosion(Handle:timer, any:ent)
{
	if (IsValidEntity(ent))
	{
		new String:edictname[128];
		GetEdictClassname(ent, edictname, 128);
		if(StrEqual(edictname, "env_explosion"))
		{
			RemoveEdict(ent);
		}
	}
}

public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i)) continue;
		
		if(TrackPlayers[i][PLAYER_STATUS])
		{
			if(TrackPlayers[i][PLAYER_EFFECT] == (AWARD_G_SPEED+DIRTY_HACK))
			{
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 400.0);
			}else if(TrackPlayers[i][PLAYER_EFFECT] == AWARD_B_SNAIL)
			{
				SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", GetConVarFloat(c_Snail));
			}
		}			
	}
}

/** - Credits to bl4nk -
 * Checks to see if a client has all of the specified admin flags
 *
 * @param client        Player's index.
 * @param flagString    String of flags to check for.
 * @return                True on admin having all flags, false otherwise.
 */
stock bool:CheckAdminFlagsByString(client, const String:flagString[])
{
    new AdminId:admin = GetUserAdmin(client);
    if (admin != INVALID_ADMIN_ID)
    {
        new count, found, flags = ReadFlagString(flagString);
        for(new i = 0; i <= 20; i++)
        {
            if(flags & (1<<i))
            {
                count++;

                if(GetAdminFlag(admin, AdminFlag:i))
                {
                    found++;
                }
            }
        }

        if(count == found)
        {
            return true;
        }
    }

    return false;
}

/* HUMBUG STUFF */
/* WHEN A PLAYER TRIES TO EXPLODE */
public Action:Command_Explode(client, args) 
{
	if (TrackPlayers[client][PLAYER_STATUS])
	{
		/* TELL THEM THEY CAN'T SUICIDE */
		PrintToChat(client, "%c[RTD]%c You aren't allowed to kill yourself when you are rolling.", cGreen, cDefault);
		
		/* STOP THEM IN THEIR TRACKS */
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/* WHEN A PLAYER TRIES TO KILL THEMSELVES */
public Action:Command_Kill(client, args) 
{
	if (TrackPlayers[client][PLAYER_STATUS])
	{
		/* TELL THEM THEY CAN'T SUICIDE */
		PrintToChat(client, "%c[RTD]%c You aren't allowed to kill yourself when you are rolling.", cGreen, cDefault);
		
		/* STOP THEM IN THEIR TRACKS */
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}