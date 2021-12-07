#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <regex>
#include <tf2>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <adminmenu>


#define PLUGIN_VERSION "1.2"
#define RED_TEAM				2
#define BLUE_TEAM				3
#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

new Handle:g_Cvar_Bots, Handle:g_Cvar_ReserveSlots, Handle:g_Cvar_SupressEvents, Handle:g_Cvar_Damage_Received, Handle:g_Cvar_Damage_Delt, Handle:g_Cvar_Damage_Received_inc, Handle:g_Cvar_Damage_Delt_inc, Handle:g_Cvar_Enabled, Handle:g_Cvar_bVh_Enabled, Handle:g_Cvar_bVh_Difference, Handle:g_Cvar_RTB_Limit, Handle:g_Cvar_RTB_Delay, Handle:g_Cvar_Cmd_Bot_Kick;
new Handle:hTopMenu, Handle:g_Cookie_AddRem_Msg, Handle:g_Cookie_All_Msg;
new Float:damage_received, Float:damage_delt, Float:damage_received_inc, Float:damage_delt_inc, Float:rtb_limit;
new botman_enabled = 1;
new cvarBots=2;
new botAutoCount, botCmdCount, botsVsHumans, botsVsHumansSwitch, botCount, playerCount, clientCount, spectatorCount, bVh_difference, inRTB, rtb_available, rtb_delay, rtb_Votes, rtb_VotesNeeded, cmd_bot_kick = 0;
new botTeam = RED_TEAM;
new humanTeam = BLUE_TEAM;
new bool:rtb_Voted[MAXPLAYERS+1] = {false, ...};
new bm_options[MAXPLAYERS+1][3];
new String:message[200];
public Plugin:myinfo = {
	name = "[TF2] Bot Manager",
	author = "Matheus28 && Kilandor &&& Fox",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}
/* Modified by Kilandor
   http://www.kilandor.com/

   pfft...don't forget Fox
   http://www.rtdgaming.com/
*/

public OnPluginStart()
{
	//Commands
	RegAdminCmd("sm_botadd", Command_BotAdd, ADMFLAG_GENERIC, "[num] [blue/red] [class] - Spawns an Intelligent bot");
	RegAdminCmd("sm_botkick", Command_BotKick, ADMFLAG_GENERIC, "[num/blue/red/name/all] - Kicks bot(s) from the server");
	RegAdminCmd("sm_botsvshumans", Command_BotsVsHumans, ADMFLAG_GENERIC, "[1/0] Enable/Disable Bots Vs Humans");
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	CreateConVar("sm_bm_version",PLUGIN_VERSION,"[TF2] Bot Manager version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_SupressEvents = CreateConVar("sm_bm_supressevents", "1", "[0/1] Supresss Bot Connect/Disconnect Messages, and Team Change in BotVsHuman", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_Bots = CreateConVar("sm_bm_slotsfree","1","How many slots the bots should not use (Doesn't count reserved slots)", FCVAR_PLUGIN, true, 1.0, true, float(MAXPLAYERS));
	g_Cvar_Enabled = CreateConVar("sm_bm_enabled","1","[1/0] Enable/Disable Bot Manager", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_Damage_Received = CreateConVar("sm_bm_damage_received","0.80","Amount to reduce damage recived(from humans) by(0.80 = -20%) on bots(-1 to disable)", FCVAR_PLUGIN, true, -1.0, true, 10.0);
	g_Cvar_Damage_Delt = CreateConVar("sm_bm_damage_delt","-1.0","Amount to increase damage delt(to humans) by(1.2 = +20%) from bots(-1 to disable)", FCVAR_PLUGIN, true, -1.0, true, 10.0);
	g_Cvar_Damage_Received_inc = CreateConVar("sm_bm_damage_received_inc","0.05","Damage Received Unbalance Increment(adjust damage)", FCVAR_PLUGIN, true, 0.1, true, 10.0);
	g_Cvar_Damage_Delt_inc = CreateConVar("sm_bm_damage_delt_inc","0.0","Damage Delt Unbalance Increment(adjust damage)", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	g_Cvar_bVh_Enabled = CreateConVar("sm_bm_bvh_enabled","0","[1/0] Enable/Disable Bots Vs Humans by default for a round", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_Cvar_bVh_Difference = CreateConVar("sm_bm_bvh_difference","2","Number of Bots to put in over Humans", FCVAR_PLUGIN, true, 0.0, true, 32.0);
	g_Cvar_RTB_Limit = CreateConVar("sm_bm_rtb_limit", "0.60", "% required for sucessful RTB vote", 0, true, 0.05, true, 1.0);
	g_Cvar_RTB_Delay = CreateConVar("sm_bm_rtb_delay", "180", "Number of seconds delay between votes", 0, true, 0.0, false, 0.0);
	g_Cvar_Cmd_Bot_Kick = CreateConVar("sm_bm_cmd_bot_kick", "1", "[1/0] Enable/Disable Kicking Manualy added bots to keep 1 slot free", 0, true, 0.0, true, 1.0);

	HookConVarChange(g_Cvar_Bots, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_SupressEvents, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_Damage_Received, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_Damage_Delt, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_Damage_Received_inc, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_Damage_Delt_inc, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_Enabled, ConVarChange_BotMan);
	//HookConVarChange(g_Cvar_bVh_Enabled, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_bVh_Difference, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_RTB_Limit, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_RTB_Delay, ConVarChange_BotMan);
	HookConVarChange(g_Cvar_Cmd_Bot_Kick, ConVarChange_BotMan);

	damage_received = GetConVarFloat(g_Cvar_Damage_Received);
	damage_delt = GetConVarFloat(g_Cvar_Damage_Delt);
	damage_received_inc = GetConVarFloat(g_Cvar_Damage_Received_inc);
	damage_delt_inc = GetConVarFloat(g_Cvar_Damage_Delt_inc);
	botman_enabled = GetConVarInt(g_Cvar_Enabled);
	bVh_difference = GetConVarInt(g_Cvar_bVh_Difference);
	rtb_limit = GetConVarFloat(g_Cvar_RTB_Limit);
	rtb_delay = GetConVarInt(g_Cvar_RTB_Delay);
	cmd_bot_kick = GetConVarInt(g_Cvar_Cmd_Bot_Kick);

	g_Cvar_ReserveSlots = FindConVar("sm_reserved_slots");
	if(g_Cvar_ReserveSlots != INVALID_HANDLE)
	{
		HookConVarChange(g_Cvar_ReserveSlots, ConVarChange_BotMan);
	}

	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_round_win", Event_RoundWin);
	HookEvent("teamplay_round_start", Event_RoundStart);

	//Create ClientPrefs Cookies to use
	g_Cookie_AddRem_Msg = RegClientCookie("bm_addrem_msg", "Disable BotMan Add/Remove bots messages", CookieAccess_Protected);
	g_Cookie_All_Msg = RegClientCookie("bm_all_msg", "Disable BotMan All messages", CookieAccess_Protected);

	ProcessBotsVars();
}

public OnMapStart()
{
	botAutoCount=0;
	botCmdCount=0;
	botsVsHumans=0;
	botsVsHumansSwitch=0;
	rtb_Votes = 0;
	rtb_VotesNeeded = 0;
	rtb_available = GetTime()+rtb_delay;

	CreateTimer(5.0,Timer_CheckBots,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(300.0,Timer_RTB,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	decl flags
	flags=GetCommandFlags("nav_generate")
	if(flags&FCVAR_CHEAT){
		SetCommandFlags("nav_generate",flags^FCVAR_CHEAT);
	}
	flags=GetCommandFlags("tf_bot_add")
	if(flags&FCVAR_CHEAT){
		SetCommandFlags("tf_bot_add",flags^FCVAR_CHEAT);
	}

	if(GetConVarInt(g_Cvar_bVh_Enabled))
	{
		Change_BotsVsHumans(1);
	}

	//Take into account existing bots on load
	//this way it doesn't create too many bots
	new maxAutoBots = MaxClients-cvarBots;
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientConnected(i) && IsFakeClient(i) && botAutoCount < maxAutoBots)
			botAutoCount++;
		else if(IsClientConnected(i) && IsFakeClient(i) && botAutoCount >= maxAutoBots)
			botCmdCount++;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client,SDKHook_OnTakeDamage, TakeDamageHook);
}

public Action:Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_Cvar_SupressEvents))
	{
		if(!dontBroadcast)
		{
			decl String:strName[50];
			GetEventString(event, "name", strName, sizeof(strName));
			new iIndex = GetEventInt(event, "index");
			new iUserId = GetEventInt(event, "userid");
			decl String:strNetworkId[50];
			GetEventString(event, "networkid", strNetworkId, sizeof(strNetworkId));
			decl String:strAddress[50];
			GetEventString(event, "address", strAddress, sizeof(strAddress));
			if(!StrEqual(strNetworkId,"BOT",false))
			{
				return Plugin_Continue;
			}
			new Handle:hEvent = CreateEvent("player_connect");
			SetEventString(hEvent, "name", strName);
			SetEventInt(hEvent, "index", iIndex);
			SetEventInt(hEvent, "userid", iUserId);
			SetEventString(hEvent, "networkid", strNetworkId);
			SetEventString(hEvent, "address", strAddress);

			FireEvent(hEvent, true);

			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(iUserId);
	if(rtb_Voted[client])
		rtb_Votes--;
	rtb_Voted[client] = false;

	decl String:strNetworkId[50];
	GetEventString(event, "networkid", strNetworkId, sizeof(strNetworkId));
	if(!StrEqual(strNetworkId,"BOT",false))
	{
		return Plugin_Continue;
	}
	decl String:strReason[50];
	GetEventString(event, "reason", strReason, sizeof(strReason));
	if(GetConVarInt(g_Cvar_SupressEvents))
	{
		if(!dontBroadcast)
		{
			if(SimpleRegexMatch(strReason, "(AutoKick)", PCRE_CASELESS))
			{
				UpdateBotCounts(2);
			}
			else if(SimpleRegexMatch(strReason, "(bVhKick)", PCRE_CASELESS))
				UpdateBotCounts(3);
			else
				UpdateBotCounts();
			decl String:strName[50];
			GetEventString(event, "name", strName, sizeof(strName));
			new Handle:hEvent = CreateEvent("player_disconnect");
			SetEventInt(hEvent, "userid", iUserId);
			SetEventString(hEvent, "reason", strReason);
			SetEventString(hEvent, "name", strName);
			SetEventString(hEvent, "networkid", strNetworkId);

			FireEvent(hEvent, true);

			return Plugin_Handled;
		}
	}
	else
	{
		if(SimpleRegexMatch(strReason, "(AutoKick)", PCRE_CASELESS))
		{
			UpdateBotCounts(2);
		}
		else if(SimpleRegexMatch(strReason, "(bVhKick)", PCRE_CASELESS))
			UpdateBotCounts(3);
		else
			UpdateBotCounts();
	}
	return Plugin_Continue;
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(client < 1)
		return Plugin_Continue;
	if(GetConVarInt(g_Cvar_SupressEvents) && botsVsHumans || IsFakeClient(client))
	{
		if(!dontBroadcast && !GetEventBool(event, "silent"))
		{
			new iUserId = GetEventInt(event, "userid");
			new iTeam = GetEventInt(event, "team");
			new iOldTeam = GetEventInt(event, "oldteam");
			new bool:bDisconnect = GetEventBool(event, "disconnect");
			new bool:bAutoteam = GetEventBool(event, "autoteam");
			decl String:strName[50];

			GetEventString(event, "name", strName, sizeof(strName));

			new Handle:hEvent = CreateEvent("player_team");
			SetEventInt(hEvent, "userid", iUserId);
			SetEventInt(hEvent, "team", iTeam);
			SetEventInt(hEvent, "oldteam", iOldTeam);
			SetEventBool(hEvent, "disconnect", bDisconnect);
			SetEventBool(hEvent, "autoteam", bAutoteam);
			SetEventBool(hEvent, "silent", true);
			SetEventString(hEvent, "name", strName);

			FireEvent(hEvent, true);

			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new full_round = GetEventInt(event, "full_round");
	if(full_round)
	{
		botsVsHumansSwitch = 1;
		if(botTeam == RED_TEAM)
		{
			botTeam = BLUE_TEAM;
			humanTeam = RED_TEAM;
		}
		else
		{
			botTeam = RED_TEAM;
			humanTeam = BLUE_TEAM;
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	botsVsHumansSwitch = 0;
	if(botsVsHumans)
	{
		PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 bVh is enabled. Type \x04rtb\x01 to Rock the Bot.\nType \x04bmoptions\x01 to Change your BotMan message options.");
	}
	else
	{
		PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 bVh is disabled Type \x04rtb\x01 to Rock the Bot.\nType \x04bmoptions\x01 to Change your BotMan message options.");
	}
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!botman_enabled)
		return Plugin_Continue;

	if(botsVsHumans)
	{
		new client = GetClientOfUserId(GetEventInt(event,"userid"));

		new iTeam = GetEventInt(event, "team");
		if(IsClientConnected(client) && IsFakeClient(client) && botTeam != iTeam)
		{
			CreateTimer(0.1, Timer_switchBot, client, TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Handled;
		}
		else if(IsClientConnected(client) && iTeam != 1 && !IsFakeClient(client) && humanTeam != iTeam)
		{
			if(!botsVsHumansSwitch)
			{
				PrintToChat(client, "\x04[\x03BotMan\x04][\x03bVh\x04]\x01 Unable to switch teams during bVh.");
			}

			ChangeClientTeam(client, humanTeam);
			TF2_RespawnPlayer(client);

			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

// Note that damage is BEFORE modifiers are applied by the game for
// things like crits, hitboxes, etc.  The damage shown here will NOT
// match the damage shown in player_hurt (which is after crits, hitboxes,
// etc. are applied).
public Action:TakeDamageHook(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!botman_enabled)
		return Plugin_Continue;

	new BotAttacker, BotClient, Float:damage_received_tmp, Float:damage_delt_tmp, clientDifference;

	//Client and Attacker must both be players
	if(client <= (MaxClients + 1) && client > 0 && attacker <= (MaxClients + 1) && attacker > 0)
	{
		//the attacker and the clients must both be in game
		if(!IsClientConnected(attacker) || !IsClientConnected(client))
			return Plugin_Continue;

		if(IsFakeClient(attacker))
			BotAttacker = true;
		else
			BotAttacker = false;

		if(IsFakeClient(client))
			BotClient = true;
		else
			BotClient = false;

		if(botsVsHumans)
		{
			if(playerCount > botCount)
			{
				//When there are more players
				//Bots will receive less damage & do more damage

				clientDifference = playerCount - botCount;

				damage_received_tmp = damage_received - (damage_received_inc * clientDifference);
				damage_delt_tmp = damage_delt + (damage_delt_inc * clientDifference);
			}
			else
			{
				//When there are more players
				//Bots will receive more damage & do less damage

				clientDifference = botCount - playerCount;

				damage_received_tmp = damage_received + (damage_received_inc * clientDifference);
				damage_delt_tmp = damage_delt - (damage_delt_inc * clientDifference);
			}
		}
		else
		{
			damage_received_tmp = damage_received;
			damage_delt_tmp = damage_delt;
		}

		if(damage_received_tmp <= 0.0)
			damage_received_tmp = 0.1;

		if(damage_delt_tmp <= 0.0)
			damage_delt_tmp = 0.1;

		if(!BotAttacker && BotClient && damage_received != -1)
		{
			//Reduce Damage on Bots
			damage *= damage_received_tmp;

			//Compensates for damage values so 1 damage is always delt
			if(damage < 1.0)
				damage = 1.0;
		}
		else if(BotAttacker && !BotClient && damage_delt != -1)
		{
			//Increase Damage from Bots
			damage *= damage_delt_tmp;

			//Compensates for damage values so 1 damage is always delt
			if(damage < 1.0)
				damage = 1.0;
		}
	}
	return Plugin_Changed;
}

public Action:Timer_switchBot(Handle:timer,any: client)
{
	if(IsClientInGame(client))
	{
		ChangeClientTeam(client, botTeam);
		TF2_RespawnPlayer(client);
	}

	return Plugin_Stop;
}

public Action:Timer_RTB(Handle:timer,any: client)
{
	if(botsVsHumans)
	{
		PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 bVh is enabled. Type \x04rtb\x01 to Rock the Bot.\nType \x04bmoptions\x01 to Change your BotMan message options.");
	}
	else
	{
		PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 bVh is disabled Type \x04rtb\x01 to Rock the Bot.\nType \x04bmoptions\x01 to Change your BotMan message options.");
	}
	return Plugin_Continue;
}

public Action:Timer_CheckBots(Handle:timer)
{
	if(!botman_enabled)
		return Plugin_Continue;

	if(MaxClients==0)
		return Plugin_Continue;

	if(botAutoCount < 0)
		botAutoCount = 0;

	if(botAutoCount > MaxClients)
		botAutoCount = MaxClients;

	if(botCmdCount < 0)
		botCmdCount = 0;

	if(botCmdCount > MaxClients)
		botCmdCount = MaxClients;

	botCount = 0;
	playerCount = 0;
	clientCount = 0;
	spectatorCount = 0;
	for(new i=1;i<=MaxClients;i++)
	{
		new clientConnected = IsClientConnected(i);
		new clientInGame = IsClientInGame(i);
		if(clientConnected && !IsFakeClient(i) && clientInGame && GetClientTeam(i) > 1)
			playerCount++;

		if(clientConnected && !IsFakeClient(i) && clientInGame && GetClientTeam(i) == 1)
			spectatorCount++;

		if(clientConnected)
			clientCount++;

		if(clientConnected && IsFakeClient(i))
			botCount++;
	}

	rtb_VotesNeeded = RoundToFloor(float(playerCount) * rtb_limit);

	if(cmd_bot_kick)
	{
		if((botCount+playerCount+spectatorCount) >= MaxClients && botCmdCount)
		{
			PrintToChatSome("\x04[\x03BotMan\x04]\x01 Removing a Manual Bot.", 2);
			botCount--;
			KickBots(2);
		}
	}
	if(botsVsHumans)
	{
		new halfMaxClients = MaxClients / 2;
		new maxbVhBots;

		if(playerCount >= halfMaxClients)
		{
			maxbVhBots = MaxClients-playerCount-1;
		}
		else
		{
			maxbVhBots = playerCount+bVh_difference;
		}
		if((botCount+playerCount+spectatorCount+1) >= MaxClients && ((botCount-botCmdCount) == maxbVhBots || maxbVhBots >= MaxClients))
		{
			maxbVhBots = (botCount-botCmdCount);
		}
		if(maxbVhBots < 0)
			maxbVhBots = 0;
		if((botCount-botCmdCount) < maxbVhBots)
		{
			ServerCommand("tf_bot_add");
			PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 Adding a Bot.", 2);
		}
		else if((botCount-botCmdCount) > maxbVhBots)
		{
			KickBots(2,_,3);
			PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 Removing a Bot.", 2);
		}
	}
	else
	{
		new maxAutoBots = MaxClients-cvarBots-playerCount;
		if(maxAutoBots < 0)
			maxAutoBots = 0;
		if(botCount != (botAutoCount+botCmdCount))
		{
			if(botCount <= maxAutoBots)
			{
				botAutoCount = maxAutoBots;
				botCmdCount = 0;
			}
			else
			{
				botAutoCount = maxAutoBots;
				botCmdCount = botCount-botAutoCount;
			}
		}
		if((botAutoCount+playerCount+spectatorCount+1) >= MaxClients && maxAutoBots == botAutoCount)
		{
			maxAutoBots = botAutoCount;
		}

		if(botAutoCount < maxAutoBots)
		{
			ServerCommand("tf_bot_add");
			botAutoCount++;
			PrintToChatSome("\x04[\x03BotMan\x04]\x01 Not Enough Players Adding a Bot.", 2);
		}
		else if(botAutoCount > maxAutoBots)
		{
			if(botAutoCount<=0)
			{
				return Plugin_Continue;
			}
			KickBots(2,_,2);
			PrintToChatSome("\x04[\x03BotMan\x04]\x01 Enough Players Removing a Bot.", 2);
		}
	}
	return Plugin_Continue
}

public Action:Command_BotAdd(client, args)
{
	//Usage: sm_botadd [num] [blue/red] [class]
	new String:botadd_args[64];
	GetCmdArgString(botadd_args, sizeof(botadd_args));
	new String:botadd_num[64];
	GetCmdArg(1, botadd_num, sizeof(botadd_num));
	new botadd_num2 = StringToInt(botadd_num);

	BotAdd(client, botadd_num2, botadd_args);

	return Plugin_Handled;
}

public Action:BotAdd(client, amountToAdd, String:botadd_args[64])
{
	new botadd_max  = 0;

	if(amountToAdd + clientCount > MaxClients)
	{
		PrintToChat(client, "\x04[\x03BotMan\x04]\x01 Unable to add the number of requested bots(not enough slots)");
		return Plugin_Handled;
	}

	botadd_max = MaxClients - clientCount;

	if(amountToAdd <= botadd_max)
		botadd_max = amountToAdd;

	//amountToAdd:2 |botadd_args:2 | botadd_max:0

	if(botadd_max <= 1)
	{
		botCmdCount++;
		ServerCommand("tf_bot_add");
		PrintToChatSome("\x04[\x03BotMan\x04]\x01 Adding a Bot.");
	}
	else
	{
		if(StrEqual(botadd_args, ""))
			ServerCommand("tf_bot_add %i", botadd_max);
		else
			ServerCommand("tf_bot_add %s", botadd_args);

		botCmdCount += botadd_max;
		Format(message, sizeof(message), "\x04[\x03BotMan\x04]\x01 Adding %d Bots.", botadd_max);
		PrintToChatSome(message);
	}

	return Plugin_Continue;
}

public Action:Command_BotKick(client, args)
{
	new String:botkick_arg[128];
	GetCmdArg(1, botkick_arg, sizeof(botkick_arg));

	if(strcmp(botkick_arg, "all", false) == 0)
	{
		botAutoCount = 0;
		botCmdCount = 0;
		KickBots(4);
		PrintToChatSome("\x04[\x03BotMan\x04]\x01 Kicking all Bots.");
	}
	else if(SimpleRegexMatch(botkick_arg, "([1-9]+)"))
	{
		new botkick_num = StringToInt(botkick_arg);
		KickBots(2, botkick_arg);
		Format(message, sizeof(message), "\x04[\x03BotMan\x04]\x01 Kicking %d Bots.", botkick_num);
		PrintToChatSome(message);
	}
	else if(SimpleRegexMatch(botkick_arg, "(red|blue)", PCRE_CASELESS))
	{
		KickBots(3, botkick_arg);
		Format(message, sizeof(message), "\x04[\x03BotMan\x04]\x01 Kicking %s Bots.", botkick_arg);
		PrintToChatSome(message);
	}
	else if(StrEqual(botkick_arg, ""))
	{
		KickBots(2);
		PrintToChatSome("\x04[\x03BotMan\x04]\x01 Kicking a Bot.");
	}
	else
	{
		KickBots(1, botkick_arg);
	}

	return Plugin_Handled;
}

public Action:Command_BotsVsHumans(client, args)
{
	new String:tmpsetting[64];
	GetCmdArg(1, tmpsetting, sizeof(tmpsetting));
	new setting = StringToInt(tmpsetting);

	Change_BotsVsHumans(setting);

	return Plugin_Handled;
}

public Action:Change_BotsVsHumans(enabled)
{
	if(!botman_enabled)
		return Plugin_Continue;

	if(enabled)
	{
		botsVsHumans = 1;
		PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 Bots Vs Humans Enabled.");
		ServerCommand("mp_autoteambalance 0");
		PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 Enforcing Team Restrictions.");
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientConnected(i) && IsFakeClient(i))
			{
				ChangeClientTeam(i, RED_TEAM);
				TF2_RespawnPlayer(i);
			}
			else if(IsClientConnected(i) && !IsFakeClient(i) && IsClientInGame(i) && GetClientTeam(i) != 1)
			{
				ChangeClientTeam(i, BLUE_TEAM);
				TF2_RespawnPlayer(i);
			}
		}
	}
	else
	{
		botAutoCount=0;
		botCmdCount=0;
		KickBots(4);
		botsVsHumans = 0;
		PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 Bots Vs Humans Disabled.");
		ServerCommand("mp_autoteambalance 1");
		PrintToChatSome("\x04[\x03BotMan\x04][\x03bVh\x04]\x01 Scrambling Teams.");
		new red,blue=0;
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) != 1)
			{
				if(red == blue)
				{
					ChangeClientTeam(i, GetRandomInt(2,3));
				}
				else if(red > blue)
				{
					ChangeClientTeam(i, BLUE_TEAM);
				}
				else if(red < blue)
				{
					ChangeClientTeam(i, RED_TEAM);
				}
				TF2_RespawnPlayer(i);
				if(GetClientTeam(i) == RED_TEAM)
				{
					red++;
				}
				else
				{
					blue++;
				}
			}
		}
	}
	for(new i=1;i<=MaxClients;i++)
	{
		rtb_Voted[i] = false;
	}
	rtb_Votes = 0;
	inRTB = 0;

	return Plugin_Continue;
}

public ConVarChange_BotMan(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_Cvar_Bots || convar == g_Cvar_ReserveSlots)
	{
		ProcessBotsVars();
	}
	else if(convar == g_Cvar_Damage_Received)
	{
		damage_received = GetConVarFloat(g_Cvar_Damage_Received);
	}
	else if(convar == g_Cvar_Damage_Delt)
	{
		damage_delt = GetConVarFloat(g_Cvar_Damage_Delt);
	}
	else if(convar == g_Cvar_Damage_Received_inc)
	{
		damage_received_inc = GetConVarFloat(g_Cvar_Damage_Received_inc);
	}
	else if(convar == g_Cvar_Damage_Delt_inc)
	{
		damage_delt_inc = GetConVarFloat(g_Cvar_Damage_Delt_inc);
	}
	else if(convar == g_Cvar_Enabled)
	{
		botman_enabled = GetConVarInt(g_Cvar_Enabled);
	}
	else if(convar == g_Cvar_bVh_Difference)
	{
		bVh_difference = GetConVarInt(g_Cvar_bVh_Difference);
	}
	else if(convar == g_Cvar_RTB_Limit)
	{
		rtb_limit = GetConVarFloat(g_Cvar_RTB_Limit);
	}
	else if(convar == g_Cvar_RTB_Delay)
	{
		rtb_delay = GetConVarInt(g_Cvar_RTB_Delay);
	}
	else if(convar == g_Cvar_Cmd_Bot_Kick)
	{
		cmd_bot_kick = GetConVarInt(g_Cvar_Cmd_Bot_Kick);
	}
}

public ProcessBotsVars()
{
	new iReservedSlots;
	if(g_Cvar_ReserveSlots != INVALID_HANDLE)
	{
		iReservedSlots = GetConVarInt(g_Cvar_ReserveSlots);
	}
	cvarBots=GetConVarInt(g_Cvar_Bots)+iReservedSlots
}

/*
  Type
  1 = name
  2 = random
  3 = team
  4 = all
  Method
  1 = Command
  2 = Auto
*/
KickBots(any:type, const String:args[128]="", method=1)
{
	new String:bot_name[128];
	new bot_num = StringToInt(args);
	new String:reason[64];
	switch(method)
	{
		case 2:
			reason = "AutoKick";
		case 3:
			reason = "bVhKick";
		default:
			reason = "CommandKick";
	}
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && type == 1)
		{
			GetClientName(i, bot_name, sizeof(bot_name));
			if(StrEqual(bot_name, args, false))
			{
				Format(message, sizeof(message), "\x04[\x03BotMan\x04]\x01 Kicking Bot %s.", bot_name);
				PrintToChatSome(message);
				ServerCommand("kickid %d %s", GetClientUserId(i), reason);
				return;
			}
		}
		if(IsClientInGame(i) && IsFakeClient(i) && type == 2)
		{
			ServerCommand("kickid %d %s", GetClientUserId(i), reason);
			bot_num--;
			if(bot_num <= 0)
			{
				return;
			}
		}
		if(IsClientInGame(i) && IsFakeClient(i) && type == 3)
		{
			if(GetClientTeam(i) == 2 && StrEqual(args, "red", false))
			{
				ServerCommand("kickid %d %s", GetClientUserId(i), reason);
			}
			else if(GetClientTeam(i) == 3 && StrEqual(args, "blue", false))
			{
				ServerCommand("kickid %d %s", GetClientUserId(i), reason);
			}
		}
		if(IsClientInGame(i) && IsFakeClient(i) && type == 4)
		{
			ServerCommand("kickid %d %s", GetClientUserId(i), reason);
		}
	}

}
//This function is used on disconnect to be sure bot counts are correct
UpdateBotCounts(method=1)
{
	if(method == 2)
	{
		botAutoCount--;
	}
	else if(method == 3)
	{
		//bVh Kick should not ever update counts
	}
	else
	{
		if(botCmdCount >= 1)
		{
			botCmdCount--;
		}
		else if(botAutoCount >= 1)
		{
			botAutoCount--;
		}
	}
}

/*
Admin menu integration
*/
public OnAdminMenuReady(Handle:topmenu)
{
	/* Block us from being called twice */
	if (topmenu == hTopMenu)
		return;

	/* Save the Handle */
	hTopMenu = topmenu;

	/* Find the "Server Commands" category */
	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
	AddToTopMenu(hTopMenu, "addmenu_BotManager", 		TopMenuObject_Item, AdminMenu_BotManager,	server_commands,"sm_kick",	ADMFLAG_BAN);
}

public AdminMenu_BotManager(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%s", "Bot Manager");
	else if (action == TopMenuAction_SelectOption)
		DisplayAdminBotManagerMenu(param);
}


/*
Admin Bot Manager menu
*/
DisplayAdminBotManagerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AdminBotManager);

	SetMenuTitle(menu, "Admin Bot Manager Menu");
	SetMenuExitBackButton(menu, true);

	new String:menuDescription[128];
	new String:menuDescription2[128];
	if(botsVsHumans)
		menuDescription = "Bots VS Humans (enabled)";
	else
		menuDescription = "Bots VS Humans (disabled)";

	if(botman_enabled)
		menuDescription2 = "DISABLE Bot Manager";
	else
		menuDescription2 = "ENABLE Bot Manager";

	AddMenuItem(menu,"Option 1",	menuDescription2);
	AddMenuItem(menu,"Option 2",	"Add Bot");
	AddMenuItem(menu,"Option 3",	"Kick Bot");
	AddMenuItem(menu,"Option 4",	menuDescription);

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminBotManager(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		switch (action)
		{
			case MenuAction_Select:
			{
				switch (param2)
				{
					case 0:
					{
						if(botman_enabled)
							ServerCommand("sm_bm_enabled 0");
						else
							ServerCommand("sm_bm_enabled 1");
					}

					case 1:
					{
						DisplayAdminAddBotMenu(param1);
					}

					case 2:
					{
						DisplayAdminKickBotMenu(param1);
					}

					case 3:
					{
						if(botsVsHumans)
							botsVsHumans = 0;
						else
							botsVsHumans = 1;
						Change_BotsVsHumans(botsVsHumans);
					}
				}
			}
		}
	}
	else
		CloseHandle(menu);
}

DisplayAdminAddBotMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AdminAddBot);

	SetMenuTitle(menu, "Admin Bot Manager Menu");
	SetMenuExitBackButton(menu, true);

	new String:optionNum[128];
	new String:itemDescription[128];

	new botadd_max = MaxClients - clientCount;

	for (new i = 1; i <= botadd_max; i++)
	{
		Format(optionNum, sizeof(optionNum), "Option %i", i);
		Format(itemDescription, sizeof(itemDescription), "Add %i Bots", i);

		AddMenuItem(menu,optionNum, itemDescription);
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminAddBot(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
		BotAdd(param1, param2+1, "");
	else
		CloseHandle(menu);
}

DisplayAdminKickBotMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_AdminKickBot);

	SetMenuTitle(menu, "Admin Bot Manager Menu");
	SetMenuExitBackButton(menu, true);

	new String:optionNum[32];
	new String:botname[32];
	new botsFound = 1;

	for (new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i))
			continue;

		if(!IsFakeClient(i))
			continue;

		Format(optionNum, sizeof(optionNum), "%i", i);

		GetClientName(i, botname, sizeof(botname));
		Format(botname, sizeof(botname), "%s (%i)", botname, GetClientUserId(i));

		AddMenuItem(menu,optionNum, botname);

		botsFound ++;
	}

	//Format(optionNum, sizeof(optionNum), "Option %i", botsFound);
	AddMenuItem(menu,"Kick All Bots", "Kick All Bots");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_AdminKickBot(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[128];
		new String:clientname[128];

		GetMenuItem(menu, param2, info, sizeof(info));

		new target = StringToInt(info);
		if(target > 0)
		{
			//target = GetClientUserId(wantedClient);
			GetClientName(target,clientname,sizeof(clientname));
		}

		if ((target == 0 || !IsClientInGame(target)) && !StrEqual(info, "Kick All Bots"))
		{
			PrintToChat(param1, "\x04[\x03BotMan\x04]\x01 Could Not Find %s.", info);
		}
		else
		{
			if(!StrEqual(info, "Kick All Bots"))
				ServerCommand("sm_botkick %s",clientname);
			else
				ServerCommand("sm_botkick all");
		}
	}
	else
		CloseHandle(menu);
}

public Action:Command_Say(client, args)
{
	decl String:text[192];
	if (!GetCmdArgString(text, sizeof(text)) || inRTB || !client || !botman_enabled || GetClientTeam(client) == 1)
	{
		return Plugin_Continue;
	}

	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(text[startidx], "rtb", false) == 0 || strcmp(text[startidx], "rockthebot", false) == 0)
	{
		if(rtb_available > GetTime())
		{
			new rtb_remaining = rtb_available-GetTime();
			PrintToChat(client, "\x04[\x03BotMan\x04]\x01 Rock the Bot is Unavailable for the next %d seconds.",  rtb_remaining);
			return Plugin_Continue
		}
		if (rtb_Voted[client])
		{
			PrintToChat(client, "\x04[\x03BotMan\x04]\x01 You have already voted to Rock the Bot. (%d votes, %d required)",  rtb_Votes, rtb_VotesNeeded);
			return Plugin_Continue;
		}

		new String:name[64];
		GetClientName(client, name, sizeof(name));

		rtb_Votes++;
		rtb_Voted[client] = true;

		PrintToChatAll("\x04[\x03BotMan\x04]\x01 %s wants to Rock the Bot. (%d votes, %d required)", name, rtb_Votes, rtb_VotesNeeded);
		if (rtb_Votes >= rtb_VotesNeeded)
		{
			PrintToChatAll("\x04[\x03BotMan\x04]\x01 The bots have been Rocked!", name, rtb_Votes, rtb_VotesNeeded);
			inRTB = 1;
			rtb_available = GetTime()+rtb_delay;
			if(botsVsHumans)
				Change_BotsVsHumans(0);
			else
				Change_BotsVsHumans(1);
		}
	}
	else if (strcmp(text[startidx], "bmoptions", false) == 0)
	{
		ShowBMOptions(client);
	}

	return Plugin_Continue;
}

public Action:ShowBMOptions(client)
{
	new Handle:hMenu = CreateMenuEx(GetMenuStyleHandle(MenuStyle_Radio), MenuHandler_Options);

	SetMenuTitle(hMenu,"BotManger Options");

	if(bm_options[client][0] == 0)
		AddMenuItem(hMenu,"Option 0","Disable Auto Add/Remove Messages");
	else
		AddMenuItem(hMenu,"Option 0","Enable Auto Add/Remove Messages");

	if(bm_options[client][1] == 0)
		AddMenuItem(hMenu,"Option 1","Disable All Messages");
	else
		AddMenuItem(hMenu,"Option 1","Enable All Messages");

	DisplayMenu(hMenu,client,MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public MenuHandler_Options(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					if(bm_options[param1][0] == 0)
					{
						bm_options[param1][0] = 1;
						SetClientCookie(param1, g_Cookie_AddRem_Msg, "1");
					}
					else
					{
						bm_options[param1][0] = 0;
						SetClientCookie(param1, g_Cookie_AddRem_Msg, "0");
					}
				}

				case 1:
				{
					if(bm_options[param1][1] == 0)
					{
						bm_options[param1][1] = 1;
						SetClientCookie(param1, g_Cookie_All_Msg, "1");
					}
					else
					{
						bm_options[param1][1] = 0;
						SetClientCookie(param1, g_Cookie_All_Msg, "0");
					}
				}
			}
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public OnClientCookiesCached(client)
{
	new String:value[100];
	GetClientCookie(client, g_Cookie_AddRem_Msg, value, sizeof(value));
	bm_options[client][0] = StringToInt(value);

	GetClientCookie(client, g_Cookie_All_Msg, value, sizeof(value));
	bm_options[client][1] = StringToInt(value);
}

/*
  Type
  1 - Normal
  2 - AutoBot
*/
PrintToChatSome(const String:msg[], type=1 )
{

	for(new i=1; i <= MaxClients; i++)
	{
		//Checks if All Messages are Disabled
		if(IsClientInGame(i) && bm_options[i][1])
			continue;
		//Checks if Autobot Messages are Disabled
		if(IsClientInGame(i) && bm_options[i][0]  && type == 2)
			continue;
		if(IsClientInGame(i))
			PrintToChat(i,msg);
	}
}