/*
	Plugin game: Team Fortress 2
	Plugin require: RCBot! http://rcbot.bots-united.com!
	Plugin author: Tom Hackers
	Plugin category: Server Management
	Plugin version: 1.0.6 (updated 10 august 2009)
	Plugin description:
	bot_count_blue - Keep that count of bots in blue team. Default: 9.
	bot_count_red - Keep that count of bots in red team. Default: 9.
	bot_changeclass2 - Allow bots to change classes after X deathes. Default: 1.
	bot_changeclass_dc - Death amount. Default: 4.
	bot_count_humans - Count humans as bots. So humans replace bots. Default: 1.
	bot_class_limit - Do not allow bots class spam. Automatic. Default: 1.
	bot_class_adv - More advanced class limit. Keeps atleast 1 character for each class. Default: 1.
	bot_fall_speed - Bot's fall speed multiplier. Default: 0.05.
	bot_gravity - Bot's gravity multiplier. Default: 0.7.
	bot_ping - Change bot's ping. Default: 1.
	bot_ping_min - Bot's minimal ping. Default: 15.
	bot_ping_max - Bot's maximum ping. Default: 120.
	bot_respawn_time - Respawn time of bot's in second, keep in mind that this will be +1 second longer due to class changing. Default: 1. Value less then 1 - Disabled.
	bot_respawn_humans - This will respawn humans just like bots. Default: 1. If zero, only bots will be spawned if time >= 1.
	bot_names_file - Bot names file. Default: botnames.txt, warning! File should exist in "sourcemod/configs" directory! -NEW-
	bot_console_cheats - Allow server console to use cheat commands and adding bots without sv_cheats 1. Default: 1. 
	Switch this to 0, if you use admin cheats plugin.

	I will keep this updated... Also you should find "tf2.bots.cfg" in "cfg/sourcemod" folder. Have a nice time.
	Do not forget to create botnames.txt file in "sourcemod/configs" folder, with names of bots.

	Notes: This is sourcemod's plugin, extract sourcemod folder into addons folder, overwrite: yes. Enjoy.  
*/

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define MAX_COMMANDS 512
#define PLUGIN_VERSION "1.0.6"

//Class related
new deathcount[MAXPLAYERS + 1] = {0, ...};
new ClassLimit = 4;
new CurrentCount[TFTeam + TFTeam:1][TFClassType + TFClassType:1];
//Bot control related
new bool:UnderControl[MAXPLAYERS + 1] = {false, ...};
new ControlSkips[MAXPLAYERS + 1] = 0;
//Cvars
new Handle:cvar1;
new Handle:cvar2;
new Handle:cvar3;
new Handle:cvar4;
new Handle:cvar5;
new Handle:cvar6;
new Handle:cvar6b;
new Handle:cvar7;
new Handle:cvar8;
new Handle:cvar9;
new Handle:cvar10;
new Handle:cvar11;
new Handle:cvar12;
new Handle:cvar13;
new Handle:cvarfile;
new Handle:hooknamesfile;
new Handle:botnames;
//Temp, i love temp values/strings :D
new String:temp[64];
new itemp = 0;
//Ping related
new String:playermanager[64] = "tf_player_manager";
new iPlayerManager;
new iPing;
new Handle:Pings[MAXPLAYERS + 1];
//Misc/other
new String:namespath[64];
new bool:dedicated, bool:listen;
new Handle:testsubject;
new Handle:rcbotver;
//Fast resp related
new bool:Playing = true;
//Cheats related
new String:hooked[MAX_COMMANDS][128];
new nextHooked=0;
new Handle:consolecheats;
new Handle:svcheats;

new Classlimits[10];

public Plugin:myinfo = 
{
	name = "TF2 RCbot Manager",
	author = "Tom Hackers",
	description = "Little plugin to provide some rcbot management in tf2.",
	version = PLUGIN_VERSION,
	url = "www.tomhackers.com"
}

public OnPluginStart()
{
	cvar1 = CreateConVar("bot_count_blue", "9");
	cvar2 = CreateConVar("bot_count_red", "9");
	cvar3 = CreateConVar("bot_changeclass2", "1");
	cvar4 = CreateConVar("bot_changeclass_dc", "4");
	cvar5 = CreateConVar("bot_count_humans", "1");
	cvar6 = CreateConVar("bot_class_limit", "1");
	cvar6b = CreateConVar("bot_class_adv", "1");
	cvar7 = CreateConVar("bot_fall_speed", "0.05");
	cvar8 = CreateConVar("bot_gravity", "0.7");
	cvar9 = CreateConVar("bot_ping", "1");
	cvar10 = CreateConVar("bot_ping_min", "15");
	cvar11 = CreateConVar("bot_ping_max", "120");
	cvar12 = CreateConVar("bot_respawn_time", "1");
	cvar13 = CreateConVar("bot_respawn_humans", "1");
	
	RegAdminCmd("sm_botclasslimit", setbotclasslimit, Admin_Root, "Sets the limit for a particular class");
	
	cvarfile = CreateConVar("bot_names_file", "botnames.txt");
	consolecheats = CreateConVar("bot_console_cheats", "1");
	svcheats = FindConVar("sv_cheats");
	iPing = FindSendPropOffs("CPlayerResource", "m_iPing");
	AutoExecConfig(true, "tf2.bots");
	CreateConVar("bot_manager_version", PLUGIN_VERSION, "TF2 RCbot Manager version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	GetConVarString(cvarfile, temp, sizeof(temp));
	Format(temp, sizeof(temp), "configs/%s", temp);
	BuildPath(Path_SM, namespath, sizeof(namespath), temp);
	rcbotver = FindConVar("rcbot_ver");
	if (!FileExists(namespath))
	{
		GetConVarString(cvarfile, temp, sizeof(temp));
		LogMessage("I couldn't find %s! Error!", temp);
	}
	else if (rcbotver == INVALID_HANDLE)
	{
		LogMessage("RCBot is not loaded! ABORT!");
		LogMessage("Lol man, are you running rcbot?");
	}
	else
	{
		HookEvent("player_death", PlayerDeath);
		HookEvent("player_spawn", PlayerSpawn);
		//Disabling fast resp for bots on round end...
		HookEvent("teamplay_round_win", RoundEnded);
		HookEvent("arena_win_panel", RoundEnded);
		//Enabling fast resp for bots on round start...
		HookEvent("teamplay_restart_round", RoundStarted);
		HookEvent("teamplay_round_start", RoundStarted);
		HookEvent("arena_round_start", RoundStarted);
		//I was creating fast resp totally on my own, so sorry if it bugs a bit, you are able to not use it.
		
		botnames = CreateArray(256);
		ParseNames();
		
		LogMessage("Oh hi there! If you see this message,");
		LogMessage("that mean that i finished reading,");
		LogMessage("your botnames.txt! Enjoy! :D");
		LogMessage(" ");
		LogMessage("RCBot by Cheeseh.")
		GetConVarString(rcbotver, temp, sizeof(temp));
		LogMessage("RCBot version: %s", temp);
		LogMessage("Plugin created by Tom Hackers.")
		LogMessage("Plugin version: %s", PLUGIN_VERSION);
		
		hooknamesfile = FindConVar("bot_names_file");
		if (hooknamesfile != INVALID_HANDLE)
			HookConVarChange(hooknamesfile, OnNamesFileChange);
		
		//[1.0.6] This is my way to detect is this server Listen or Dedicated...
		LogMessage("Server detection started!");
		testsubject = FindConVar("deathmatch"); //I know that changing a cvar for a sec looks lame, but it works perfect.
		CreateTimer(2.0, TestingWhoIsServer);
		
		//This code below doesnt belong to me, thanks devicenull!
		new String:cmdname[128];
		new bool:iscmd, cmdflags;
		new Handle:cmds = FindFirstConCommand(cmdname,128,iscmd,cmdflags);
		do
		{
			if (cmdflags&FCVAR_CHEAT && iscmd && nextHooked < MAX_COMMANDS)
			{
				RegConsoleCmd(cmdname,cheatcommand);
				SetCommandFlags(cmdname,GetCommandFlags(cmdname)^FCVAR_CHEAT);
				strcopy(hooked[nextHooked++],128,cmdname);
			}
		} while (FindNextConCommand(cmds,cmdname,1024,iscmd,cmdflags));
	}
}

public Action:setbotclasslimit(client, args)
{
	new String:class[8];
	new String:a2[2];
	GetCmdArg(1,class,8);
	GetCmdArg(2,a2,8);
	new Limit = StringToInt(a2);
	new TFClassType:Classnum = StringToInt(class);
	if (Limit <= 0)
		if (StrEqual(class,"scout",false))
			Classnum = 1;
			//TFClass=TFClass_Scout;
		else if (StrEqual(class,"soldier",false) || StrEqual(class,"solider",false))
			Classnum = 2;
			//TFClass=TFClass_Soldier;
		else if (StrEqual(class,"pyro",false))
			Classnum = 3;
			//TFClass=TFClass_Pyro;
		else if (StrEqual(class,"demo",false) || StrEqual(class,"demoman",false))
			Classnum = 4;
			//TFClass=TFClass_DemoMan;
		else if (StrEqual(class,"heavy",false))
			Classnum = 5;
			//TFClass=TFClass_Heavy;
		else if (StrEqual(class,"engi",false) || StrEqual(class,"engineer",false))
			Classnum = 6;
			//TFClass=TFClass_Engineer;
		else if (StrEqual(class,"medic",false))
			Classnum = 7;
			//TFClass=TFClass_Medic;
		else if (StrEqual(class,"sniper",false))
			Classnum = 8;
			//TFClass=TFClass_Sniper;
		else if (StrEqual(class,"spy",false))
			Classnum = 9;
			//TFClass=TFClass_Spy;
		else
		{
			PrintToChat(client,"Invalid Class!");
			return Plugin_Handled;
		}	
	
	Classlimits[Classnum] = Limit;
	return Plugin_Handled;
}

public OnPluginEnd()
{
	for (new i=0;i<nextHooked;i++)
	{
		SetCommandFlags(hooked[i],GetCommandFlags(hooked[i])|FCVAR_CHEAT);
	}
	//End of code :D
}

public OnMapStart()
{
	iPlayerManager	= FindEntityByClassname(GetMaxClients() + 1, playermanager);
}

public OnMapEnd()
{
	for (new i = 1; i <= GetMaxClients(); i++) 
	{
		UnderControl[i] = false;
		ControlSkips[i] = 0;
	}
}

public OnClientPutInServer(client) 
{
	if (IsFakeClient(client))
	{		
		new Handle:hTVName = FindConVar("tv_name"), String:sName[MAX_NAME_LENGTH], String:sTVName[MAX_NAME_LENGTH];
		GetClientName(client, sName, sizeof(sName));
		
		if (hTVName != INVALID_HANDLE) 
		{
			GetConVarString(hTVName, sTVName, sizeof(sTVName));
		}
		
		if (StrEqual(sName, sTVName)) 
		{
			UnderControl[client] = true;
			ControlSkips[client] = 0;
		}
		else
		{
			UnderControl[client] = false;
			ControlSkips[client] = 0;
		}
	}
}

public Action:TakeControlOfBots(Handle:timer)
{
	new iMaxClients = GetMaxClients(), Team;
	for (new i = 1; i <= iMaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i))
		{
			Team = GetClientTeam(i);
			if (Team > 1)
			{
				if (!UnderControl[i] && ControlSkips[i] > 4)  
				{
					GetClientName(i, temp, sizeof(temp));
					if (dedicated)
						ServerCommand("rcbotd control \"%s\"", temp);
					if (listen)
						ServerCommand("rcbot control \"%s\"", temp);
					UnderControl[i] = true;
				}
				else if (ControlSkips[i] <= 4)
				{
					//I know that SourceTV has team by number 1, but i decided to leave old (1.0.5) part of code alone.
					new Handle:hTVName = FindConVar("tv_name"), String:sName[MAX_NAME_LENGTH], String:sTVName[MAX_NAME_LENGTH];
					GetClientName(i, sName, sizeof(sName));
					if (hTVName != INVALID_HANDLE) 
					{
						GetConVarString(hTVName, sTVName, sizeof(sTVName));
					}
					if (StrEqual(sName, sTVName)) 
					{
						UnderControl[i] = true;
						ControlSkips[i] = 0;
					}
					else
					{
						ControlSkips[i]++;
					}
				} 
			}
		}
	}
}

public Action:EachSecond(Handle:timer)
{
	new iBots = 0, iClients = GetClientCount(), iMaxClients = GetMaxClients(), Team, target, iBlue, iRed, bool:bBlue = false, bool:bRed = false, sloop = 0;
	//[1.0.6] Decided to rebuild this part of code...
	for (new i = 1; i <= iMaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			Team = GetClientTeam(i);
			if (GetConVarBool(cvar5) || IsFakeClient(i))
			{ 
				if (Team == 3)
				{
					iBlue++;
				}
				else if (Team == 2)
				{
					iRed++;
				}
			}
			if (IsFakeClient(i) && Team > 1)
			{
				iBots++;
				if (!bBlue && Team == 3)
				{
					bBlue = true;
				}
				else if (!bRed && Team == 2)
				{
					bRed = true;
				}
			}
		}
	}
	decl iTargets[MAXPLAYERS], bool:tn_is_ml, String:sName[MAX_NAME_LENGTH], String:sTarget[MAX_TARGET_LENGTH];
	GetArrayString(botnames,   GetRandomInt(0, GetArraySize(botnames) - 1), sName, sizeof(sName));
	while (ProcessTargetString(sName,
	0,
	iTargets,
	MAXPLAYERS,
	COMMAND_FILTER_NO_MULTI,
	sTarget,
	MAX_TARGET_LENGTH,
	tn_is_ml) == 1 && IsFakeClient(iTargets[0])) 
	{
		GetArrayString(botnames, GetRandomInt(0, GetArraySize(botnames) - 1), sName, sizeof(sName));
	}
	if (iBlue < GetConVarInt(cvar1) && bRed && iRed > GetConVarInt(cvar2))
	{
		do
		{
			sloop++;
			target = GetRandomInt(1, GetMaxClients());
			if (IsClientInGame(target) && IsFakeClient(target) && GetClientTeam(target) == 2)
			{
				ChangeClientTeam(target, 3);
				sloop = 100;
			}
		} while (sloop<100);				
	}
	else if (iRed < GetConVarInt(cvar2) && bBlue && iBlue > GetConVarInt(cvar1))
	{
		do
		{
			sloop++;
			target = GetRandomInt(1, GetMaxClients());
			if (IsClientInGame(target) && IsFakeClient(target) && GetClientTeam(target) == 3)
			{
				ChangeClientTeam(target, 2);
				sloop = 100;
			}
		} while (sloop<100);				
	}
	else if (iBlue > GetConVarInt(cvar1) && bBlue)
	{
		do
		{
			sloop++;
			target = GetRandomInt(1, GetMaxClients());
			if (IsClientInGame(target) && IsFakeClient(target) && GetClientTeam(target) == 3)
			{
				UnderControl[target] = false;
				ControlSkips[target] = 0;
				KickClient(target, "Slot reserved");
				sloop = 100;
			}
		} while (sloop<100);				
	}
	else if (iRed > GetConVarInt(cvar2) && bRed)
	{
		do
		{
			sloop++;
			target = GetRandomInt(1, GetMaxClients());
			if (IsClientInGame(target) && IsFakeClient(target) && GetClientTeam(target) == 2)
			{
				UnderControl[target] = false;
				ControlSkips[target] = 0;
				KickClient(target, "Slot reserved");
				sloop = 100;
			}
		} while (sloop<100);				
	}	
	//[1.0.6] Just there, making sure that it's possible to add new bot into game. :D
	else if (iClients < iMaxClients && iBlue < GetConVarInt(cvar1) && iRed >= iBlue)
	{
		ServerCommand("bot -team blue -name \"%s\"", sName);
	}
	else if (iClients < iMaxClients && iRed < GetConVarInt(cvar2) && iRed <= iBlue)
	{
		ServerCommand("bot -team red -name \"%s\"", sName);
	}
	if (iBots <= 6)
	{
		ClassLimit = 1;
	}
	else if (iBots <= 12 && iBots > 6)
	{
		ClassLimit = 2;
	}
	else if (iBots <= 18 && iBots > 12)
	{
		ClassLimit = 3;
	}
	else if (iBots > 18)
	{
		ClassLimit = 4;
	}
}

public Action:RoundStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
	Playing = true;
}

public Action:RoundEnded(Handle:event, const String:name[], bool:dontBroadcast)
{
	Playing = false;
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvar3) && GetConVarInt(cvar12) < 1)
		return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarInt(cvar12) >= 1 && GetConVarBool(cvar13) && !IsFakeClient(client))
	{
		CreateTimer(GetConVarFloat(cvar12), RespawnPlayer, client);
	}
	if (GetConVarBool(cvar3) && IsFakeClient(client))
	{
		CreateTimer(0.5, ChangeClass, client);
	}
	//If class stuff is disabled, we can respawn them, otherwise do class related stuff and then respawn.
	else if (GetConVarInt(cvar12) >= 1 && IsFakeClient(client))
	{
		CreateTimer(GetConVarFloat(cvar12), RespawnPlayer, client);			
	}
}

public Action:ChangeClass(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (deathcount[client] >= GetConVarInt(cvar4))
		{
			new TFTeam:team = TFTeam:GetClientTeam(client);
			new TFClassType:oldclass;
			oldclass == TF2_GetPlayerClass(client)
			new newclass, iBots = 0, iMaxClients = GetMaxClients(), Team, Teamc, sloop = 0;
			Teamc = GetClientTeam(client)
			new bool:searchforfreeclass;
			for (new i = 1; i <= iMaxClients; i++)
			{
				if (IsClientInGame(i))
				{
					Team = GetClientTeam(i);
					if (Team == Teamc)
					{
						iBots++;
					}
				}
			}
			if (GetConVarBool(cvar6))
			{
				RecountClasses();
				if (GetConVarBool(cvar6b))
				{
					for (new TFClassType:c=TFClass_Scout; c<=TFClass_Engineer; c++)
					{
						if (CurrentCount[Teamc][c] == 0)
							searchforfreeclass = true;
					}
				}
			}
			new bool:pass = true;
			do
			{
				sloop++;
				newclass = GetRandomInt(1, 9);
				if (GetConVarBool(cvar6))
				{
					if (searchforfreeclass)
					{
						if (CurrentCount[team][TFClassType:newclass] == 0)
						{
							pass = true;
						}
						else if (CurrentCount[team][oldclass] <= 1)
						{
							deathcount[client]--;
							newclass = _:oldclass;
							pass = true;
						}
						else
						{
							pass = false;
						}
					}
					else
					{
						if (oldclass == TFClassType:newclass || CurrentCount[team][TFClassType:newclass] >= ClassLimit)
						{
							pass = false;
						}
						else
						{
							pass = true;
						}
					}
				}
				if (sloop >= 100)
				{
					pass = true;
				}
			} while(!pass)				
			TF2_SetPlayerClass(client, TFClassType:newclass);
		}
		else
		{
			deathcount[client]++;
		}
		if (GetConVarInt(cvar12) >= 1)
		{
			new Float:time = GetConVarFloat(cvar12) + 1.0;
			CreateTimer(time, RespawnPlayer, client);
		}
	}
}

public Action:RespawnPlayer(Handle:timer, any:client)
{
	if (Playing && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		TF2_RespawnPlayer(client);
	}
}

RecountClasses()
{
	for (new TFClassType:c=TFClass_Unknown; c<=TFClass_Engineer; c++)
	{
		CurrentCount[TFTeam_Red][c] = 0;
		CurrentCount[TFTeam_Blue][c] = 0;
	}
	
	for (new i=1; i<=GetMaxClients(); i++)
	{
		if (IsClientInGame(i))
		{
			CurrentCount[TFTeam:GetClientTeam(i)][TF2_GetPlayerClass(i)]++;
		}
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && IsFakeClient(client) && GetClientTeam(client) > 1)
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(cvar7))
		SetEntityGravity(client, GetConVarFloat(cvar8));
		if (GetConVarBool(cvar9)) 
		{
			if (Pings[client] == INVALID_HANDLE)
			{
				Pings[client] = CreateTimer(GetRandomFloat(1.0, 3.0), ChangePing, client, TIMER_REPEAT);
			}
			else
			{
				KillTimer(Pings[client]); Pings[client] = INVALID_HANDLE;
				CreateTimer(GetRandomFloat(1.0, 3.0), ChangePing, client, TIMER_REPEAT);
			}
		}
		new PlayerClasses[MAXPLAYERS+1];
		new ClassesPlayer[10];
		for (new i = 1;i<=MAXPLAYERS;i++)
			if (IsClientInGame(i) && IsFakeClient(i))
			{
				PlayerClasses[i] = TF2_GetPlayerClass(i);
				ClassesPlayer[PlayerClasses[i]]++;
			}
		new Botclass = PlayerClasses[client];
		while (ClassesPlayer[PlayerClasses[client]] > Classlimits[PlayerClasses[client]])
		{
			ClassesPlayer[PlayerClasses[client]]--;
			PlayerClasses[client]++
			if (PlayerClasses[client] == 10)
				PlayerClasses[client]=1;
			if (PlayerClasses[client] == Botclass)
				break;
		}
		if (ClassesPlayer[PlayerClasses[client]] > Classlimits[PlayerClasses[client]])
			if (PlayerClasses[client] == Botclass)
			{
				KickClient(client,"Unable to find a class");
				PrintToChatAll("Removed bot (Classes Full)");
			}
			else
			{
				TF2_SetPlayerClass(client,PlayerClasses[client]);
				TF2_RespawnPlayer(client);
			}
	}
}

public Action:ChangePing(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsValidEdict(i) && IsClientInGame(i) && IsFakeClient(i))
			{
				itemp = GetEntData(iPlayerManager, iPing + (i * 4), 4);
				new randommin = itemp-10;
				new randommax = itemp+10;
				if (randommin < GetConVarInt(cvar10))
					randommin = GetConVarInt(cvar10);
				if (randommax > GetConVarInt(cvar11))
					randommax = GetConVarInt(cvar11);
				SetEntData(iPlayerManager, iPing + (i * 4), GetRandomInt(randommin, randommax));
			}
		}
	}
}

ParseNames() 
{
	decl String:buffer[32];
	new Handle:config = OpenFile(namespath, "r");
	if (config != INVALID_HANDLE) 
	{
		ClearArray(botnames);
		while (ReadFileLine(config, buffer, sizeof(buffer))) 
		{
			TrimString(buffer);
			if (strlen(buffer) > 0) 
			{
				PushArrayString(botnames, buffer);
			}
		}
		CloseHandle(config);
	}
}

public OnNamesFileChange(Handle:cvar, const String:old[], const String:current[])
{
	Format(temp, sizeof(temp), "configs/%s", current);
	BuildPath(Path_SM, namespath, sizeof(namespath), temp);
	if (!FileExists(namespath))
	{
		LogMessage("I couldn't find %s! Error!", current);
		LogMessage("Putting old cvar back!");
		SetConVarString(cvarfile, old);
	}
	else
	{
		botnames = CreateArray(256);
		ParseNames();
	}
}

//[1.0.6] And this is code of Listen/Dedicated server detection...
public Action:TestingWhoIsServer(Handle:timer)
{
	new value = GetConVarInt(testsubject);
	for (new i = 1; i<=GetMaxClients(); i++)
	{
		if (IsValidEdict(i) && !IsFakeClient(i))
		{
			if (GetConVarBool(testsubject))
				ClientCommand(i, "deathmatch 0")
			else
				ClientCommand(i, "deathmatch 1")	
		}
	}
	CreateTimer(2.0, Wait, value);
}

public Action:Wait(Handle:timer, any:value)
{
	if (value == GetConVarInt(testsubject))
	{
		LogMessage("This server is dedicated! OK!");
		dedicated = true;		
	}
	else
	{
		LogMessage("This server is listen! OK!");
		ServerCommand("deathmatch %i", value);
		//[1.0.6] Uncomment next line, if you want... Doesn't matter much.
		//ServerCommand("mp_autoteambalance 0; mp_teams_unbalance_limit 0");
		listen = true;
	}
	CreateTimer(1.0, EachSecond, _, TIMER_REPEAT);
	CreateTimer(1.0, TakeControlOfBots, _, TIMER_REPEAT);
}

//Here is bit modified code of admin cheats plugin...
public Action:cheatcommand(client, args)
{	
	if (GetConVarBool(svcheats))
	{
		return Plugin_Continue;
	}
	else
	{
		new String:argstring[256];
		GetCmdArg(0,argstring,256);
		if (client == 0 && GetConVarBool(consolecheats))
		{
			//Command by console, pass!
			return Plugin_Continue;
		}
		//The end! :D
		return Plugin_Handled;
	}
}

