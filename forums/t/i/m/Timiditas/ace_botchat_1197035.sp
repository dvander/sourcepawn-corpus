/*
		Todo:	Add some talkall / teamsay detection
		(if chatting player used teamsay OR talkall is 0, select bot from same team to reply instead any bot)
		(auto detect talkall/sm_deadtalk settings and presence of deadchat plugin and adapt bot responses to match configuration)
*/

/*
	Quote MC HuMs (mchums) on Twitter:
		"Heute können wir alles Griechisch Essen gehen !!! Bezahlt ist ja schon muhahahahhaha oh gott :)"
*/

/*************************************************************************************************************************

 ACE BOTCHAT V1.01.798
 by Ace Rimmer 2006 - 2007
 Thanks to Spikey00 for ideas and encouragement

 Original script written by Phil Pendlebury - aka - Ace Rimmer and is available at: http://www.pendlebury.biz/acerimmer/
 Sourcemod conversion by Timiditas

 Faked Chatmessages code (stock PrintGameChatMessage) taken from
 'DeadChat' ->  http://forums.alliedmods.net/showthread.php?p=651748
 with kind permission from Greyscale

*************************************************************************************************************************/
/*new in v1.2:
extended botchat_say function. if you type !botchat_say or /botchat_say into the chat, omitting all arguments, it will
open a menu listing all bot names. select one (closing menu) THEN then next thing you type into the chat will be said by
the selected bot. this function supports the {talkteam} tag to make the bot use teamchat instead allchat.
you can also type {botchat_cancel} to abort
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.2.1"

#define DEADCHAT_GAME_CSS
#define GAME_GCHAT      "\x01%s1 \x03%s2 \x01:  %s3"
#define TEAM_1_TCHAT    "DeadChat CSS teamsay spectator"
#define TEAM_2_TCHAT    "DeadChat CSS teamsay terrorist"
#define TEAM_3_TCHAT    "DeadChat CSS teamsay counter-terrorist"
#define GAME_TCHAT      "\x01%s1%s2 \x03%s3 \x01:  %s4"
#define GAME_SPECLBL    "DeadChat CSS label spectator"
#define GAME_DEADLBL    "DeadChat CSS label dead"

new Handle:kvFSS;

new Handle:arrNames;
new arrNames_count = 0;
new arrFreeNames_count = 0;		//actually these "counts" are count - 1
new UsedNames[MAXPLAYERS+1];

new Handle:arrFreeNames;
new Handle:Pseudostack;
new Handle:Pseudomirror;
new SpawnBlock[MAXPLAYERS+1];	//prevent item pickup comments at round start/spawn
//using one for each client now to make it compatible to deathmatch. also its blocked on death, round end and spawn
//while the unblocking timer is initialized five secs after spawn. maybe this is needed to be raised again

new chance_of_chat = 10;
new cvar_g_chance_of_chat = -1;

new bot_say_replies = 1;
new rename_bots = 1;

new Handle:cvar_bot_say_replies = INVALID_HANDLE;
new Handle:cvar_chance_of_chat = INVALID_HANDLE;
new Handle:cvar_rename_bots = INVALID_HANDLE;

new Handle:cvar_block_connect = INVALID_HANDLE;
new Handle:cvar_block_name = INVALID_HANDLE;
new Handle:cvar_block_team = INVALID_HANDLE;
new Handle:cvar_block_disconnect = INVALID_HANDLE;
new block_connect = 0;
new block_name = 1;
new block_team = 1;
new block_disconnect = 0;

new Handle:cvar_bot_deadchat = INVALID_HANDLE;
new bot_deadchat = 1;

new Handle:cvar_dmcontrol = INVALID_HANDLE, dmcontrol = 0;

new SpecTeamNum = 1;

new aBotSay[MAXPLAYERS+1];

new BotCount, HumanCount, HumanTeam;
new Handle:cv_bot_quota, bot_quota;
new disc_check = 0;


public Plugin:myinfo = {
	name = "ACE BOTCHAT for Sourcemod",
	author = "Ace Rimmer / Timiditas",
	description = "Force BOTs to speak randomly when certain events happen",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=128452"
};

public OnPluginStart()
{
	LoadTranslations("botchat.phrases");
	CreateConVar("sm_ace_botchat_version", PLUGIN_VERSION, "ace_botchat SM Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_chance_of_chat = CreateConVar("sm_ace_botchat_chance_of_chat", "-1", "Chance of bots commenting events. Set to 1 to make them respond every kill etc. or higher number for less responses. Use default(-1) to have it set to double the bot count automatically");
	cvar_bot_say_replies = CreateConVar("sm_ace_botchat_bot_say_replies", "1", "BOTS WILL ALSO RESPOND TO PLAYER CHAT?");
	cvar_rename_bots = CreateConVar("sm_ace_botchat_rename_bots", "1", "Use name list to rename bots");
	cvar_bot_deadchat = CreateConVar("sm_ace_botchat_bot_deadchat", "1", "Living players see dead bots chat");
	cvar_dmcontrol = CreateConVar("sm_ace_botchat_deathmatch_control", "0", "Manage bot quota in running rounds/neverending rounds");
	
	cvar_block_connect = CreateConVar("sm_ace_botchat_block_connect", "0", "Block bot connected message");
	cvar_block_name = CreateConVar("sm_ace_botchat_block_namechange", "1", "Block bot changed name message");
	cvar_block_team = CreateConVar("sm_ace_botchat_block_team", "1", "Block bot/unconnected changed team message");
	cvar_block_disconnect = CreateConVar("sm_ace_botchat_block_disconnect", "0", "Block bot disconnected message");
	
	cv_bot_quota = FindConVar("bot_quota");
	
	RegStuff();
	AutoExecConfig(true, "sm_ace_botchat");
	LoadTranslations("common.phrases");
	RegAdminCmd("botchat_say", Botsay,ADMFLAG_BAN,"Usage: botchat_say <\"quoted text\"> <botname/id> (if you omit botname/id, a random bot is selected to say your text)");
	RegConsoleCmd("say", player_say);
	RegAdminCmd("botchat_debug", getinfo,ADMFLAG_BAN,"get debug info");
	if(rename_bots == 1)
		ReadNameFiles();
}

public OnMapStart()
{
	SpecTeamNum = FindTeamByName("spect");	//we might not stick with CS:S in the future, do we?
}

public Action:event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (dontBroadcast)
		return Plugin_Continue;
	
	new userid = GetEventInt(event, "userid");
	//player doesn't have a clientID yet
	
	new String:net_id[22];
	GetEventString(event, "networkid", net_id, sizeof(net_id));
	if (strcmp(net_id[0], "BOT", false) == 0)
	{
		new String:username[65], String:location[32];
		GetEventString(event, "name", username, sizeof(username));
		GetEventString(event, "address", location, sizeof(location));
		if(rename_bots == 1)
		{
			if(arrFreeNames_count == 0)
				LogError("No free names on list left to rename bot");
			else if (arrFreeNames_count < 0)
				SetFailState("arrFreeNames_count went below zero! Please contact author.");
			else
			{
				//select random name from free names index list
				new iNewName = GetRandomInt(0,arrFreeNames_count);
				new StringIndex = GetArrayCell(arrFreeNames, iNewName);
				RemoveFromArray(arrFreeNames, iNewName);
				PushArrayCell(Pseudostack, userid);
				PushArrayCell(Pseudomirror, StringIndex);
				arrFreeNames_count -= 1;
				new String:NewName[65];
				GetArrayString(arrNames, StringIndex, NewName, sizeof(NewName));
				strcopy(username, sizeof(username), NewName);
			}
		}
		if(block_connect == 0)
		{
			new Handle:sup = CreateEvent("player_connect", true);
			SetEventString(sup, "name", username);
			SetEventInt(sup, "index", GetEventInt(event, "index"));
			SetEventInt(sup, "userid", userid);
			SetEventString(sup, "networkid", "iBOT");	//prevent stack overflow
			SetEventString(sup, "address", location);
			FireEvent(sup, false);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public OnClientPutInServer(client)
{
	aBotSay[client] = -1;
	new userid = GetClientUserId(client);

	if(IsFakeClient(client))
	{
		SpawnBlock[client] = 1;
		if(cvar_g_chance_of_chat == -1)
			chance_of_chat = GetBotCount() * 2;
		else
			chance_of_chat = cvar_g_chance_of_chat;
		if(rename_bots == 1)
		{
			new Stackpos = FindValueInArray(Pseudostack, userid);
			if (Stackpos != -1)
			{
				UsedNames[client] = GetArrayCell(Pseudomirror, Stackpos);
				RemoveFromArray(Pseudostack, Stackpos);
				RemoveFromArray(Pseudomirror, Stackpos);
				new String:NewName[65];
				GetArrayString(arrNames, UsedNames[client], NewName, sizeof(NewName));
				SetClientInfo(client, "name", NewName);
			}
		}
	}
	
	//Delay join chat to prevent bots using the wrong name
	CreateTimer(0.1, DelayedGreetings, userid);
	DControl(client);
}

public Action:getinfo(client, args)
{
	//botchat_debug
	new String:Reply[2048];
	for(new i=0;i<=MaxClients;i++)
	{
		Format(Reply, sizeof(Reply), "UsedNames[%i] = %i", i, UsedNames[i]);
		ReplyToCommand(client,Reply);
	}
	if(arrNames == INVALID_HANDLE)
		Format(Reply, sizeof(Reply), "arrNames = INVALID_HANDLE");
	else
		Format(Reply, sizeof(Reply), "arrNames = valid handle");
	ReplyToCommand(client,Reply);
	Format(Reply, sizeof(Reply), "arrNames_count = %i", arrNames_count);
	ReplyToCommand(client,Reply);
	
	if(arrFreeNames == INVALID_HANDLE)
		Format(Reply, sizeof(Reply), "arrFreeNames = INVALID_HANDLE");
	else
		Format(Reply, sizeof(Reply), "arrFreeNames = valid handle");
	ReplyToCommand(client,Reply);
	Format(Reply, sizeof(Reply), "arrFreeNames_count = %i", arrFreeNames_count);
	ReplyToCommand(client,Reply);
	Format(Reply, sizeof(Reply), "chance_of_chat = %i", chance_of_chat);
	ReplyToCommand(client,Reply);
}
BotchatMenu(client)
{
	new Handle:menu = CreateMenu(BotchatMenuHandler);
	SetMenuTitle(menu, "Select Bot then type text in chat");
	AddMenuItem(menu, "-1", "-Random Bot-");
	for(new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		if(!IsFakeClient(i))
			continue;
		decl String:Name[65], String:ID[4];
		GetClientName(i, Name, sizeof(Name));
		IntToString(i, ID, sizeof(ID));
		AddMenuItem(menu, ID, Name);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}
public BotchatMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[4];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		if(found)
		{
			new BotClientID = StringToInt(info), client = param1;
			if(BotClientID == -1)
				aBotSay[client] = GetClientUserId(ForceRandomBot(0));
			else
				aBotSay[client] = GetClientUserId(BotClientID);
			PrintToChat(client, "Selected #%i. Now type your text!", aBotSay[client]);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:Botsay(client, args)
{
	if(GetCmdArgs() == 0)
	{
		if(client != 0)
		{
			if(GetBotCount() == 0)
				ReplyToCommand(client, "No bots in server!");
			else
				BotchatMenu(client);
		}
		else
			ReplyToCommand(client, "Usage: botchat_say <\"quoted text\"> <botname/id> (if you omit botname/id, a random bot is selected to say your text)");
		return Plugin_Handled;
	}
	
	new String:he_said[256];
	GetCmdArg(1, he_said, sizeof(he_said));
	new SayBot;
	if(GetCmdArgs() == 2)
	{
		new String:Target[65];
		GetCmdArg(2, Target, sizeof(Target));
		SayBot = FindTarget(client, Target);
		if(SayBot == -1)
		{
			ReplyToCommand(client, "Targeted bot not found. Use status command to get a list of UserIDs.");
			return Plugin_Handled;
		}
		else if (!IsFakeClient(SayBot))
		{
			ReplyToCommand(client, "Targeted player %s is not a bot", Target);
			return Plugin_Handled;
		}
	}
	else
		SayBot = SelectRandomBot(client,true);	//true = ignore chance and FORCE picking of a random bot
	if(SayBot == 0)
	{
		ReplyToCommand(client, "No bots on the server");
		return Plugin_Handled;
	}
	new String:Command[256];
	Format(Command,sizeof(Command), "say %s",he_said);
	FakeClientCommandEx(SayBot, Command);
	return Plugin_Handled;
}

public SettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetSettings();
}

GetBotCount()
{
	new bots = 0;
	for(new i=1;i <= MaxClients;i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i))
			bots++;
	}
	return bots;
}

GetSettings()
{
	cvar_g_chance_of_chat = GetConVarInt(cvar_chance_of_chat);
	
	if(cvar_g_chance_of_chat == -1)
		chance_of_chat = GetBotCount() * 2;
	else
		chance_of_chat = cvar_g_chance_of_chat;
	
	bot_say_replies = GetConVarInt(cvar_bot_say_replies);
	
	bot_deadchat = GetConVarInt(cvar_bot_deadchat);
	
	dmcontrol = GetConVarInt(cvar_dmcontrol);
	
	block_connect = GetConVarInt(cvar_block_connect);
	block_name = GetConVarInt(cvar_block_name);
	block_team = GetConVarInt(cvar_block_team);
	block_disconnect = GetConVarInt(cvar_block_disconnect);

	new tNew = GetConVarInt(cvar_rename_bots);
	if(tNew == rename_bots)
		return;
	rename_bots = tNew;
	if(tNew == 0)
		EraseNames();
	else
		ReadNameFiles();
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=1;i<=MaxClients;i++)
	{ SpawnBlock[i] = 1; }
}

RegStuff()
{
	for(new i=1;i<=MaxClients;i++)
	{
		UsedNames[i] = -1;
	}
	Pseudostack = CreateArray();
	Pseudomirror = CreateArray();
	HookUserMessage(GetUserMessageId("SayText2"), SupressMessage, true);
	//HookEvent("player_changename", event_PlayerChangename, EventHookMode_Pre);
	HookEvent("player_connect", event_PlayerConnect, EventHookMode_Pre);
	HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Pre);
	HookEvent("player_team", event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_team", event_PlayerTeam_Post, EventHookMode_PostNoCopy);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
	HookEvent("item_pickup", EventItemPickup, EventHookMode_Post);
	HookEvent("bomb_pickup", EventBombPickup, EventHookMode_Post);
	HookEvent("bomb_exploded", EventBombExploded, EventHookMode_Post);
	HookEvent("bomb_planted", EventBombPlanted, EventHookMode_Post);
	HookEvent("bomb_defused", EventBombDefused, EventHookMode_Post);
	HookEvent("hostage_follows", EventHostageFollows, EventHookMode_Post);
	HookEvent("hostage_stops_following", EventHostageStopsFollowing, EventHookMode_Post);
	HookEvent("hostage_killed", EventHostageKilled, EventHookMode_Post);
	HookEvent("player_blind", EventPlayerBlind, EventHookMode_Post);
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Post);
	HookConVarChange(cvar_chance_of_chat, SettingChanged);
	HookConVarChange(cvar_bot_say_replies, SettingChanged);
	HookConVarChange(cvar_rename_bots, SettingChanged);
	HookConVarChange(cvar_block_connect, SettingChanged);
	HookConVarChange(cvar_block_name, SettingChanged);
	HookConVarChange(cvar_block_team, SettingChanged);
	HookConVarChange(cvar_block_disconnect, SettingChanged);
	HookConVarChange(cvar_bot_deadchat, SettingChanged);
	HookConVarChange(cvar_dmcontrol, SettingChanged);
	
	new String:fileFSS[PLATFORM_MAX_PATH];
	kvFSS=CreateKeyValues("bot_replies");
	BuildPath(Path_SM, fileFSS, sizeof(fileFSS), "configs/sm_bot_replies_db.txt");
	if(!FileExists(fileFSS))
		SetFailState("File not found: %s", fileFSS);
	if(!FileToKeyValues(kvFSS, fileFSS))
		SetFailState("Error while reading file: %s", fileFSS); 
	GetSettings();
}

EraseNames()
{
	arrNames_count = 0;
	if(arrNames != INVALID_HANDLE)
		CloseHandle(arrNames);
	arrFreeNames_count = 0;
	if(arrFreeNames != INVALID_HANDLE)
		CloseHandle(arrFreeNames);
}

ReadNameFiles()
{
	new Ready = 0;
	new String:fileNames[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, fileNames, sizeof(fileNames), "configs/sm_bot_fakebotnames_db_plain.txt");
	if(FileExists(fileNames))
		Ready = ReadNameFile(fileNames);
	if(Ready == 0)
	{
		BuildPath(Path_SM, fileNames, sizeof(fileNames), "configs/sm_bot_fakebotnames_db.txt");
		if(FileExists(fileNames))
			Ready = ReadNameFileKV(fileNames);
	}
	if(Ready == 0)
	{
		rename_bots = 0;
		LogError("Error reading sm_bot_fakebotnames");
		EraseNames();
	}
	else
	{
		arrFreeNames = CreateArray();
		for(new i=0;i<=arrNames_count;i++)	{	PushArrayCell(arrFreeNames, i); }
		arrFreeNames_count = GetArraySize(arrNames)-1;
	}
}

ReadNameFile(const String:fileNames[])
{
	new Handle:hFiles;
	hFiles = OpenFile(fileNames, "r");
	if (hFiles == INVALID_HANDLE)
		return 0;
	arrNames = CreateArray(ByteCountToCells(65));
	new String:Buffer[65];
	do
	{
		ReadFileLine(hFiles, Buffer, sizeof(Buffer));
		TrimString(Buffer);
		PushArrayString(arrNames, Buffer);
  }
  while (!IsEndOfFile(hFiles));
	CloseHandle(hFiles);
	arrNames_count = GetArraySize(arrNames)-1;
	return 1;
}
ReadNameFileKV(const String:fileNames[])
{
	new Handle:kvNames=CreateKeyValues("ace_fakebots");
	if(!FileToKeyValues(kvNames, fileNames))
	{
		CloseHandle(kvNames);
		return 0;
	}
	KvRewind(kvNames);
	if(!KvJumpToKey(kvNames, "botnames"))
	{
		CloseHandle(kvNames);
		return 0;
	}
	new count = KvGetNum(kvNames, "botcount");
	if(count < 1)
	{
		CloseHandle(kvNames);
		return 0;
	}
	arrNames = CreateArray(ByteCountToCells(65));
	new String:Buffer[65];
	new String:func_reply_number[5];
	for(new i=1;i<=count;i++)
	{
		IntToString(i, func_reply_number, sizeof(func_reply_number));
		KvGetString(kvNames, func_reply_number, Buffer, sizeof(Buffer));
		TrimString(Buffer);
		PushArrayString(arrNames, Buffer);
	}
	CloseHandle(kvNames);
	arrNames_count = GetArraySize(arrNames)-1;
	return 1;
}

public Action:player_say(client, args)
{
	if(client == 0)
		return Plugin_Continue;
	if(aBotSay[client] != -1)
	{
		new String:bot_said[256];
		GetCmdArg(1, bot_said, sizeof(bot_said));
		if (strcmp(bot_said[0], "{botchat_cancel}", false) != 0)
		{
			new botCID = GetClientOfUserId(aBotSay[client]);
			if(botCID == 0)
				PrintToChat(client, "Selected bot left the server before you finished typing, sorry.");
			else
			{
				new bool:TeamOnly = false;
				if(ReplaceString(bot_said, sizeof(bot_said), "{talkteam}", "") > 0)
					TeamOnly = true;
				FakeSay(botCID, bot_said, TeamOnly);
			}
		}
		aBotSay[client] = -1;
		return Plugin_Handled;
	}
	
	if(bot_say_replies != 1)
		return Plugin_Continue;
	
	new SayBot = SelectRandomBot(client);	//push origin clientID so a bot won't comment its own action
	if(SayBot == 0)
		return Plugin_Continue;
	
	new String:he_said[128];
	GetCmdArg(1, he_said, sizeof(he_said));
	new String:Name[65];
	GetClientName(client, Name, sizeof(Name));
	
	new BotID = GetClientUserId(SayBot);
	new String:ReplyName[65];
	GetClientName(SayBot, ReplyName, sizeof(ReplyName));
	new RandomTypeDelay = GetRandomInt(1, 3);
	NewFunc(BotID, he_said,RandomTypeDelay,ReplyName,Name);	//"victim" and "attacker" are swapped here to retain ES logic in say event
	
	return Plugin_Continue;
}

public Action:DelayedGreetings(Handle:timer, any:data)
{
	new userid = data;
	new client = GetClientOfUserId(userid);
	if (client == 0)
		return;
	new String:Name[65];
	GetClientName(client, Name, sizeof(Name));
	
	if(IsFakeClient(client))
	{
		new chat_chance = GetRandomInt(1, chance_of_chat);
		if (chat_chance == 1)
		{
			new RandomTypeDelay = GetRandomInt(20, 40);
			NewFunc(userid, "greetings",RandomTypeDelay,Name,"");
		}
	}
	//event origin has spoken. now lets see if a random bot will comment the event
	new SayBot = SelectRandomBot(client);	//push origin clientID so a bot won't comment its own action (again)
	if(SayBot == 0)
		return;
	new BotID = GetClientUserId(SayBot);
	new RandomTypeDelay = GetRandomInt(8, 20);
	new String:ATTName[65];
	GetClientName(SayBot, ATTName, sizeof(ATTName));
	NewFunc(BotID, "playerconnect",RandomTypeDelay,ATTName,Name);	
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim_userID = GetEventInt(event, "userid");
	new attacker_userID = GetEventInt(event, "attacker");
	new victim_clientID = GetClientOfUserId(victim_userID);
	new attacker_clientID = GetClientOfUserId(attacker_userID);
	if(IsFakeClient(victim_clientID))
		SpawnBlock[victim_clientID] = 1;
	
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new String:Cause[24];
	
	strcopy(Cause, sizeof(Cause), "normal");
	
	if(GetEventBool(event, "headshot"))
		strcopy(Cause, sizeof(Cause), "headshot");
	if(strcmp(weapon[0], "knife", false) == 0)
		strcopy(Cause, sizeof(Cause), "knife");
	if(strcmp(weapon[0], "hegrenade", false) == 0)
		strcopy(Cause, sizeof(Cause), "nade");
	//if(strcmp(weapon[0], "world", false) == 0)
	if((attacker_clientID == 0) || (attacker_clientID == victim_clientID))
		strcopy(Cause, sizeof(Cause), "suicide");
	else
	{
		if(GetClientTeam(victim_clientID)==GetClientTeam(attacker_clientID))
			strcopy(Cause, sizeof(Cause), "tk");
	}
	new String:AttackerName[64];
	if(attacker_clientID != 0)
		GetClientName(attacker_clientID, AttackerName, sizeof(AttackerName));
	
	new String:VictimName[64];
	GetClientName(victim_clientID, VictimName, sizeof(VictimName));
	
	if(IsFakeClient(victim_clientID))
	{
		new String:kvKey[24];
		Format(kvKey, sizeof(kvKey), "%sdeath", Cause);
		new death_chance = GetRandomInt(1, chance_of_chat);
		if (death_chance == 1)
		{
			new RandomTypeDelay = GetRandomInt(2, 4);
			NewFunc(victim_userID, kvKey,RandomTypeDelay,AttackerName,VictimName);
		}
	}
	if(attacker_clientID != 0)
	{
		if(IsFakeClient(attacker_clientID) && attacker_clientID != victim_clientID)
		{
			new String:kvKey[24];
			Format(kvKey, sizeof(kvKey), "%skill", Cause);
			new death_chance = GetRandomInt(1, chance_of_chat);
			if (death_chance == 1)
			{
				new RandomTypeDelay = GetRandomInt(2, 4);
				NewFunc(attacker_userID, kvKey,RandomTypeDelay,AttackerName,VictimName);
			}
		}
	}
}

public Action:RSTimer(Handle:timer, any:data)
{
	SpawnBlock[data] = 0;
}

public EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	//prevent item pickup comments at round start/spawning
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client))
	{
		SpawnBlock[client] = 1;
		CreateTimer(5.0, RSTimer, client);
	}
}

public EventItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	//still babbling sometimes after spawning but works better now
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(IsFakeClient(client) && SpawnBlock[client] == 0)
	{
		new chat_chance = GetRandomInt(1, chance_of_chat);
		if (chat_chance == 1)
			NewFunc(userid, "itempickup",2);
	}
}

public EventBombPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(!IsFakeClient(client))
		return;
	new chat_chance = GetRandomInt(1, chance_of_chat);
	if (chat_chance != 1)
		return;
	NewFunc(userid, "bombpickup",2);
}

public EventBombExploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(client == 0)
		return;		//<--- warning! *********** if there will be an 'bombexplodedother' in the future, CHANGE THIS
	if(!IsFakeClient(client))
		return;
	new chat_chance = GetRandomInt(1, chance_of_chat);
	if (chat_chance != 1)
		return;
	NewFunc(userid, "bombexploded",3);
}

public EventBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(!IsFakeClient(client))
		return;
	new chat_chance = GetRandomInt(1, chance_of_chat);
	if (chat_chance != 1)
		return;
	NewFunc(userid, "bombplanted",2);
}

public EventBombDefused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(!IsFakeClient(client))
		return;
	new chat_chance = GetRandomInt(1, chance_of_chat);
	if (chat_chance != 1)
		return;
	NewFunc(userid, "bombdefused",2);
}

public EventHostageFollows(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(!IsFakeClient(client))
		return;
	new chat_chance = GetRandomInt(1, chance_of_chat);
	if (chat_chance != 1)
		return;
	NewFunc(userid, "hostagefollows",1);
}

public EventHostageStopsFollowing(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(client == 0)
		return;	//player left
	if(!IsFakeClient(client))
		return;
	new chat_chance = GetRandomInt(1, chance_of_chat);
	if (chat_chance != 1)
		return;
	NewFunc(userid, "hostagestops",1);
}

public EventHostageKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(client == 0)
		return;	//player left server with a primed grenade near a hostage
	new String:Name[65];
	GetClientName(client, Name, sizeof(Name));
	
	if(IsFakeClient(client))
	{
		new chat_chance = GetRandomInt(1, chance_of_chat);
		if (chat_chance == 1)
			NewFunc(userid, "hostagekilled",1,Name,"");
	}
	
	//event origin has spoken. now lets see if a random bot will comment the event
	
	new SayBot = SelectRandomBot(client);	//push origin clientID so the bot won't comment its own action (again)
	if(SayBot == 0)
		return;
	new String:SayBotName[65];
	GetClientName(SayBot, SayBotName, sizeof(SayBotName));
	new BotID = GetClientUserId(SayBot);
	NewFunc(BotID, "hostagekilledother",4,Name,SayBotName);
}

public EventPlayerBlind(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if(!IsFakeClient(client))
		return;
	new chat_chance = GetRandomInt(1, chance_of_chat);
	if (chat_chance != 1)
		return;
	//new String:Name[65];
	//GetClientName(client, Name, sizeof(Name));
	NewFunc(userid, "blinded",2);
}

ForceRandomBot(event_origin)
{
	new Bots[MAXPLAYERS+1];
	new Botcount, selected;
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		if(!IsFakeClient(i))
			continue;
		if(i==event_origin)
			continue;
		if(GetClientTeam(i) == SpecTeamNum) //DO NOT SELECT SOURCETV FAKECLIENT
			continue;
		Botcount += 1;
		Bots[Botcount] = i;
	}
	if(Botcount == 0)
		selected = 0;
	else
		selected = Bots[GetRandomInt(1, Botcount)];
	return selected;
}

SelectRandomBot(event_origin, bool:IgnoreChance = false)
{
	new selected = 0;
	if(chance_of_chat == 1 || IgnoreChance)			//when chance_of_chat is 1, it would always be the same bot talking, so select random one
		selected = ForceRandomBot(event_origin);
	else
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(!IsClientInGame(i))
				continue;
			if(!IsFakeClient(i))
				continue;
			if(i==event_origin)
				continue;
			if(GetClientTeam(i) == SpecTeamNum) //DO NOT SELECT SOURCETV FAKECLIENT
				continue;
			new say_chance;
			say_chance = GetRandomInt(1, chance_of_chat);
			if(say_chance != 1)
				continue;
			selected = i;
			break;
		}
	}
	//if(selected != 0)
	//	selected = GetClientUserId(selected);
	return selected;
}
NewFunc(TalkingBotUserID,const String:kvKey[],delay,const String:AttackerName[] = "", const String:VictimName[] = "")
{
	KvRewind(kvFSS);
	if(!KvJumpToKey(kvFSS, kvKey))
		return;
	new TeamOnly = KvGetNum(kvFSS, "teamonly");	//ignore this setting in linked section if there is a link
	new String:LinkSec[255];
	KvGetString(kvFSS, "link", LinkSec, sizeof(LinkSec));
	//if kvKey contains a link, jump to linked section
	if(strlen(LinkSec) > 0)
	{
		KvRewind(kvFSS);
		if(!KvJumpToKey(kvFSS, LinkSec))
		{
			//linked section not found. jump back to kvKey
			KvRewind(kvFSS);
			KvJumpToKey(kvFSS, kvKey);
		}
		else
		{
			new func_reply_count = KvGetNum(kvFSS, "count");
			if(func_reply_count < 1)
			{
				//linked section empty! jump back to kvKey
				KvRewind(kvFSS);
				KvJumpToKey(kvFSS, kvKey);
			}
		}
	}
	new func_reply_count = KvGetNum(kvFSS, "count");
	if(func_reply_count < 1)
		return;
	new String:func_reply_number[5], String:func_reply_string[255];
	IntToString(GetRandomInt(1, func_reply_count), func_reply_number, sizeof(func_reply_number));
	KvGetString(kvFSS, func_reply_number, func_reply_string, sizeof(func_reply_string));
	ReplaceString(func_reply_string, sizeof(func_reply_string), "{section}", kvKey);
	ReplaceString(func_reply_string, sizeof(func_reply_string), "{attacker}", AttackerName);
	ReplaceString(func_reply_string, sizeof(func_reply_string), "{victim}", VictimName);
	if(StrContains(func_reply_string, "{mapname}", false) != -1)
	{
		//strip map type tokens like de, cs, gg, aim etc (anything smaller than four chars will be discarded)
		new String:MapName[255], String:MapOut[255], subnum, String:SubStr[6][255];
		GetCurrentMap(MapName, sizeof(MapName));
		subnum = ExplodeString(MapName, "_", SubStr, 6, 255);
		if(subnum < 2)
			strcopy(MapOut, sizeof(MapOut), MapName);
		else
		{
			for(new i=0;i<subnum;i++)
			{
				if(strlen(SubStr[i]) > 3)
				{
					StrCat(MapOut, sizeof(MapOut), SubStr[i]);
					StrCat(MapOut, sizeof(MapOut), "_");
				}
			}
			strcopy(MapName, sizeof(MapName), MapOut);
			new TheLen = strlen(MapName);
			strcopy(MapOut, TheLen, MapName);
		}
		ReplaceString(func_reply_string, sizeof(func_reply_string), "{mapname}", MapOut);
	}
	if(StrContains(func_reply_string, "{mapminutesleft}", false) != -1)
	{
		new TimeSecs, String:Minutes[10];
		GetMapTimeLeft(TimeSecs);
		TimeSecs /= 60;
		IntToString(TimeSecs, Minutes, sizeof(Minutes));
		ReplaceString(func_reply_string, sizeof(func_reply_string), "{mapminutesleft}", Minutes);
	}
	
	new Position;
	do
	{
		Position = StrContains(func_reply_string, "{servertime", false);
		if(Position != -1)
		{
			//parse reply string to extract exact tag!
			new String:TheTag[255], String:Buffer[255], EndPos, String:TimeString[255];
			strcopy(Buffer, sizeof(Buffer), func_reply_string[Position]);
			EndPos = FindCharInString(Buffer, 125);	//asc(125) = "}"
			if(EndPos != -1)
			{
				strcopy(TheTag, (EndPos+2), Buffer);
				//extract time format string if present in tag
				new StartPos = FindCharInString(TheTag, 58);	//asc(58) = ":"
				EndPos = FindCharInString(TheTag, 125)-1;
				new TheLen = EndPos-StartPos;
				if(StartPos != -1 && TheLen > 1)
				{
					strcopy(Buffer, TheLen+1, TheTag[StartPos+1]);
				}
				else
					strcopy(Buffer, sizeof(Buffer), "%H:%M");
				FormatTime(TimeString, sizeof(TimeString), Buffer);	//if fourth argument (stamp) is omitted, it copies the actual servertime
				ReplaceString(func_reply_string, sizeof(func_reply_string), TheTag, TimeString);
			}
		}
	}
	while (Position != -1);
	
	if(ReplaceString(func_reply_string, sizeof(func_reply_string), "{talkall}", "") > 0)
		TeamOnly = 0;
	if(ReplaceString(func_reply_string, sizeof(func_reply_string), "{talkteam}", "") > 0)
		TeamOnly = 1;
	new Handle:dataPackHandle;
	CreateDataTimer(float(delay), DataTimer, dataPackHandle);
	WritePackCell(dataPackHandle, TalkingBotUserID);
	WritePackCell(dataPackHandle, TeamOnly);
	WritePackString(dataPackHandle, func_reply_string);
}
public Action:DataTimer(Handle:timer, Handle:pack)
{
	decl String:str[255];//, String:scomm[255];
	new clientID;
	ResetPack(pack);
	clientID = GetClientOfUserId(ReadPackCell(pack));
	if (clientID == 0)
		return;
	//isclientingame should be unnecessary, since getclientofuserid will return 0 anyway
	new bool:TeamOnly = (ReadPackCell(pack)==1);
	ReadPackString(pack, str, sizeof(str));
	/*
	if(TeamOnly == 0)
		Format(scomm, sizeof(scomm), "say %s", str);
	else
		Format(scomm, sizeof(scomm), "say_team %s", str);
	FakeClientCommandEx(clientID, scomm);	<-- conflicts with popular rcon_lock.smx which blocks fakeclients from using say&say_team
	*/
	FakeSay(clientID, str, TeamOnly);
}

FakeSay(client, const String:SayText[], bool:TeamOnly)
{
	new SayClientTeam = GetClientTeam(client);
	new bool:SayClientAlive = IsPlayerAlive(client);
	
	for(new i = 1;i <= MaxClients;i++)
	{
		if (!IsClientInGame(i))
			continue;
		if (IsFakeClient(i))
			continue;
		new OtherClientTeam = GetClientTeam(i);
		new bool:OtherClientAlive = IsPlayerAlive(i);
		
		if(OtherClientTeam == SpecTeamNum)	//always print to spectators - can't use IsPlayerObserver because dead players are observers too
		{
			PrintGameChatMessage(client, i, SayText, TeamOnly);
			continue;
		}
		if(bot_deadchat == 1 || SayClientAlive == OtherClientAlive)
		{
			if (!TeamOnly)
				PrintGameChatMessage(client, i, SayText, TeamOnly);
			else
			{
				if (SayClientTeam == OtherClientTeam)
					PrintGameChatMessage(client, i, SayText, TeamOnly);
			}
		}
	}
}

stock PrintGameChatMessage(sender, receiver, const String:text[], bool:teamonly)
{
    decl String:sendername[64];
    GetClientName(sender, sendername, sizeof(sendername));
    
    new Handle:hSayText2 = StartMessageOne("SayText2", receiver);
        
    BfWriteByte(hSayText2, sender);
    BfWriteByte(hSayText2, true);
    
    new String:label[16];   // Use |new| to initialize the string.
    
    if (teamonly)
    {
        // Write the team chat format string to the usermessage.
        BfWriteString(hSayText2, GAME_TCHAT);
        
        // Format the client's team name on in the message.
        decl String:team[32];
        new clientteam = GetClientTeam(sender);
        if (clientteam <= 1)
        {
            strcopy(label, sizeof(label), "");
            Format(team, sizeof(team), "%T", TEAM_1_TCHAT, receiver);
            clientteam = 1; // Just in case the client isn't on a team.  Using 0 in the TEAM_X_TCHAT macro would cause errors
        }
        else
        {
            if (!IsPlayerAlive(sender))
                Format(label, sizeof(label), "%T", GAME_DEADLBL, receiver);
            
            if (clientteam  == 2)
                Format(team, sizeof(team), "%T", TEAM_2_TCHAT, receiver);
            else if (clientteam  == 3)
                Format(team, sizeof(team), "%T", TEAM_3_TCHAT, receiver);
        }
        
        // Write the label of the string.
        BfWriteString(hSayText2, label);
        
        // Write the team of the client whose sending the message.
        BfWriteString(hSayText2, team);
    }
    else
    {
        // Write the global chat format string to the usermessage.
        BfWriteString(hSayText2, GAME_GCHAT);
        
        if (GetClientTeam(sender) > 1)
        {
            // Format the *DEAD* label if the sender isn't alive.
            if (!IsPlayerAlive(sender))
                Format(label, sizeof(label), "%T", GAME_DEADLBL, receiver);
        }
        else
            Format(label, sizeof(label), "%T", GAME_SPECLBL, receiver);
        
        BfWriteString(hSayText2, label);
    }
    
    BfWriteString(hSayText2, sendername);
    BfWriteString(hSayText2, text);
    
    EndMessage();
}

public Action:SupressMessage(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new client = BfReadByte(bf);
	if(block_name == 1 && client > 0)
	{
		//this obviously only works on CS:S
		//supress name change message of bots
		if(!IsFakeClient(client))
			return Plugin_Continue;
		BfReadByte(bf);	//skip second byte
		new String:MessageType[255];
		new MTypeLen = BfReadString(bf, MessageType, sizeof(MessageType));
		if (MTypeLen != 20)
			return Plugin_Continue;
		if (strcmp(MessageType[0], "#Cstrike_Name_Change", false) == 0)
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	//supress bots teamchange messages, especially the nasty "unconnected changed team" messages

	if (dontBroadcast || block_team == 0)
		return Plugin_Continue;
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new bool:iFake = true;
	if(client != 0)		//<-- I don't know why it happens, but it happens. maybe it was that unconnected bot team change
		iFake = IsFakeClient(client);
	
	if(iFake)
	{
		/*new team = GetEventInt(event, "team");
		new oldteam = GetEventInt(event, "oldteam");
		new bool:disconnect = GetEventBool(event, "disconnect");
		//this might break when css is moved to orange box
		new Handle:sup = CreateEvent("player_team", true);
		SetEventInt(sup, "userid", userid);
		SetEventInt(sup, "team", team);
		SetEventInt(sup, "oldteam", oldteam);
		SetEventBool(sup, "disconnect", disconnect);
		FireEvent(sup, true);*/
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
}

public Action:event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (dontBroadcast)
		return Plugin_Continue;
	
	new userid = GetEventInt(event, "userid");
	new String:net_id[22];
	GetEventString(event, "networkid", net_id, sizeof(net_id));
	if (strcmp(net_id[0], "BOT", false) == 0)
	{
		new String:uname[65], String:reason[255];
		GetEventString(event, "name", uname, sizeof(uname));
		GetEventString(event, "reason", reason, sizeof(reason));
		
		new Handle:sup = CreateEvent("player_disconnect", true);
		SetEventInt(sup, "userid", userid);
		//SetEventString(sup, "reason", reason);	//Do not include string 'kicked by console'
		SetEventString(sup, "name", uname);
		SetEventString(sup, "networkid", "iBOT");	//prevent stack overflow
		FireEvent(sup, (block_disconnect == 1));
		return Plugin_Handled;
	}
	else
		return Plugin_Continue;
	//This seems to be fired rarely when bots leave...
}
public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
	{
		if(cvar_g_chance_of_chat == -1)
			chance_of_chat = (GetBotCount() -1)* 2;
		else
			chance_of_chat = cvar_g_chance_of_chat;
	}
	else
		return;
	
	if(rename_bots == 1 && UsedNames[client] != -1)
	{
		PushArrayCell(arrFreeNames, UsedNames[client]);
		arrFreeNames_count += 1;
		UsedNames[client] = -1;
		if (arrFreeNames_count > arrNames_count)
			SetFailState("arrFreeNames_count went above arrNames_count! Please contact author.");
	}
}
Update()
{
	BotCount = 0;
	HumanCount = 0;
	HumanTeam = 0;

	for(new i=1;i <= MaxClients;i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i))
			BotCount++;
		else if(IsClientConnected(i))
		{
			HumanCount++;
			if(IsClientInGame(i))
			{
				new cTeam = GetClientTeam(i);
				if(cTeam != 0 && cTeam != SpecTeamNum)
					HumanTeam++;
			}
		}
	}
}
public OnConfigsExecuted()
{
	bot_quota = GetConVarInt(cv_bot_quota);
}
AddBots(count)
{
	for(new i=1;i<=count;i++)
	{
		ServerCommand("bot_add");
	}
}

KickBots(count)
{
	for(new i=1;i<=count;i++)
	{
		KickBot();
	}
}

KickBot(client = 0)
{
	new bot = client;
	if (bot == 0)
		bot = ForceRandomBot(0);
	if (bot != 0)
		KickClientEx(bot);
}
public event_PlayerTeam_Post(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(dmcontrol == 0)
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client != 0)
	{
		if(!IsFakeClient(client))
			ManageQuota();
	}
	else
	{
		if(disc_check == 0)
		{
			disc_check = 1;
			CreateTimer(1.0, CheckQuota);
		}
	}
}
public Action:CheckQuota(Handle:timer, any:data)
{
	disc_check = 0;
	ManageQuota();
}

/*
//I don't think we need this
public event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	Update();
	if(BotCount + HumanCount == MaxClients && bot_auto_vacate == 1)
		KickBot();
	
}
*/
public Action:Checkalive(Handle:timer, any:data)
{
	new client = GetClientOfUserId(data);
	if(client != 0)
	{
		if(!IsPlayerAlive(client))
			CS_RespawnPlayer(client);
	}
}
/*
public OnClientDisconnect_Post(client)
{
	//a bot might have been kicked by auto vacate function and the client might not have fully connected before leaving again
	Update();
	if(HumanCount == 0 && bot_join_after_player == 1)
		ServerCommand("bot_kick");
	new NeededBots = HumanCount - BotCount;
	
}
*/
DControl(client)
{
	if(dmcontrol == 0)
		return;
	//Update();
	if(IsFakeClient(client))
		CreateTimer(1.0, Checkalive, GetClientUserId(client));
}
ManageQuota()
{
	Update();
	new Neededbots = (BotCount+HumanTeam)-bot_quota;
	if(Neededbots > 0)
		AddBots(Neededbots);
	else if(Neededbots < 0)
		KickBots(Neededbots);
}
