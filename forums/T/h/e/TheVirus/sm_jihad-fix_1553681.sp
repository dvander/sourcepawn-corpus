#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define PLUGIN_NAME		"Jihad Mod"
#define PLUGIN_VERSION	"0.88"
#define STR_MAX_LEN		128
#define CC_OLIVE			"\x05"	// Chat Colors
#define CC_GREEN			"\x04"	
#define CC_LGREEN			"\x03"
#define CC_WHITE			"\x01"	// default
#define MAX_FILE_LEN 180

enum Team		// easier to remember
{
	None = 0,
	Spectator = 1,
	Terrorist = 2,
	CounterTerrorist = 3
};

enum BombType
{
	None = -1,
	Upgrade = 0,
	Base = 1,
	Max = 4294967296 // 2^32
};

enum ClientData
{
	UserId,
	BombType:Bomb,
	BuyCount,
	bool:IsBombArmed,
	Handle:timerData
};

new g_Clients[MAXPLAYERS + 1][ClientData];
new g_stat_BombCount[Team];	
new g_iAccount = -1;
new Float:g_fBuyTimeEnd;
new String:g_pluginPrefix[STR_MAX_LEN];
new Handle:g_cvar_BombLevels =		 	INVALID_HANDLE;	// int
new Handle:g_cvar_BombLimitCT = 		INVALID_HANDLE;	// int
new Handle:g_cvar_BombLimitRound =		INVALID_HANDLE;	// (per player) int
new Handle:g_cvar_BombLimitT =			INVALID_HANDLE;	// int
new Handle:g_cvar_ColorOnArmed = 		INVALID_HANDLE; // bool
new Handle:g_cvar_PostDelay =			INVALID_HANDLE;	// float (seconds) // "sound" length
new Handle:g_cvar_PostSoundPath =		INVALID_HANDLE;	// string
new Handle:g_cvar_PreDelay =			INVALID_HANDLE;	// float (seconds) // arming time
new Handle:g_cvar_ExplosionDamage =		INVALID_HANDLE;	// int
new Handle:g_cvar_FailRate = 			INVALID_HANDLE;	// float (%)
new Handle:g_cvar_PluginEnabled =		INVALID_HANDLE;	// bool
//new Handle:g_cvar_PluginVersion =		INVALID_HANDLE;	// string
new Handle:g_cvar_PriceBase = 			INVALID_HANDLE; // int ($)
new Handle:g_cvar_PriceUpgrade= 		INVALID_HANDLE;	// int ($)
new Handle:g_cvar_SizeMultiplier =		INVALID_HANDLE;	// int

new Handle:g_cvar_BombBuyTime =			INVALID_HANDLE;
new Handle:g_cvar_RandomExplosion = 	INVALID_HANDLE;
new g_RandExplosion =			0;
new MoneyOffset;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Momemtum Mori modified by TheVirus",
	description = "SM remake of es_bombermod",
	version = PLUGIN_VERSION,
	url = "http://www.steamgamers.com/"
};


public OnPluginStart()
{
	Format(g_pluginPrefix, sizeof(g_pluginPrefix), "%s[Jihad] %s", CC_OLIVE, CC_GREEN);
	
	// Commands
	// 	Not admin cmds for more customization posibilities
	RegConsoleCmd("sm_jihad_detonate", 	Command_Detonate, 	"Detonate your bomb, if any.");
	RegConsoleCmd("sm_jihad_buybomb", 	Command_BuyBomb, 	"Buy a bomb or upgrade an existing one.");

	// ConVars
	g_cvar_BombLevels = 		CreateConVar("sm_jihad_bomblevels",		"1",	"Sets how many bomb types exists.");
	g_cvar_BombLimitCT = 		CreateConVar("sm_jihad_bomblimitct",		"0",	"Sets how many CTs may carry a bomb at once.");
	g_cvar_BombLimitRound = 	CreateConVar("sm_jihad_bomblimitround",	"1",	"Sets how many time a player may buy a bomb per round.");
	g_cvar_BombLimitT = 		CreateConVar("sm_jihad_bomblimitt",		"1",	"Sets how many Ts may carry a bomb at once.");
	g_cvar_ColorOnArmed = 		CreateConVar("sm_jihad_coloronarmed",	"0",	"Sets whether the wearer of an armed bomb changes color.");
	g_cvar_PostDelay = 			CreateConVar("sm_jihad_postdelay",		"1.0",	"Sets the delay (in seconds) before detonating the bomb.");
	g_cvar_PostSoundPath =	CreateConVar("sm_jihad_postsoundpath",	"jihad/jihad.wav",	"Sets the path of the sound to play after detonating the bomb. (Relative to the sound folder)");
	g_cvar_PreDelay = 			CreateConVar("sm_jihad_predelay",		"15.0",	"Sets the delay (in seconds) before arming the bomb.");
	g_cvar_ExplosionDamage = 	CreateConVar("sm_jihad_explosiondamage",	"400",	"Sets the damage of the explosions.");
	g_cvar_FailRate = 			CreateConVar("sm_jihad_failrate",		"0.25",	"Sets the chance (in percent) that the bomb will fail to detonate.");
	g_cvar_PluginEnabled = 	CreateConVar("sm_jihad_enable", 			"1", 	"Sets whether the plugin is enabled or not.");
	//g_cvar_PluginVersion = 	CreateConVar("sm_jihad_version",			PLUGIN_VERSION, 		"Version of the plugin.", FCVAR_NOTIFY);
	g_cvar_PriceBase =			CreateConVar("sm_jihad_pricebase", 		"5000",	"Sets the base price to buy a bomb.");
	g_cvar_PriceUpgrade = 		CreateConVar("sm_jihad_priceupgrade", 	"2500",	"Sets the price to upgrade a bomb.");
	g_cvar_SizeMultiplier = 	CreateConVar("sm_jihad_sizemultiplier",	"300",	"Sets the radius of the explosions.");
	
	g_cvar_BombBuyTime =		CreateConVar("sm_jihad_bombbuytime", "10", "Number of seconds after round starts that a bomb can be purchased.");
	g_cvar_RandomExplosion = 	CreateConVar("sm_jihad_randomexplosion", "10", "Percentage increase the bomb will randomly blow when not used.");
	
	MoneyOffset=FindSendPropOffs("CCSPlayer","m_iAccount");
	if(MoneyOffset==-1)
		SetFailState("Failed to find CCSPlayer::m_iAccount offset");
		
	// Events
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("player_disconnect", Event_PlayerDisconnect);	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	
	// Variables
	g_stat_BombCount[Terrorist] = 0;
	g_stat_BombCount[CounterTerrorist] = 0;
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	//Custom sound	
	new String:soundPath[STR_MAX_LEN];
	GetConVarString(g_cvar_PostSoundPath, soundPath, STR_MAX_LEN);
	AddFileToDownloadsTable(soundPath);
	/*
	if (strlen(soundPath) != 0)
	{
		new String:buffer[MAX_FILE_LEN];
		Format(buffer, sizeof(buffer), "sound/%s", soundPath);
		AddFileToDownloadsTable(buffer);
		PrecacheSound(buffer, true);
	}
	*/
	
	// Misc
	PrecacheSound("jihad/jihad.wav", true);
	PrecacheSound("ambient/explosions/explode_1.wav", true);
	PrecacheSound("buttons/blip2.wav", true);
	PrecacheSound("buttons/button11.wav", true);
	
	AutoExecConfig(true, "sm_jihadmod");
	
	// Load the clients in g_Clients.
	for (new i = 0; i < MaxClients; ++i)
	{
		new userid = GetClientUserId(i);
		NewClient(userid, i);
	}
	
	g_RandExplosion = 0;
	
	PrintToChatAll("%sLoaded (Version %s)", g_pluginPrefix, PLUGIN_VERSION);
}


// Initialize the client in g_Clients if it is a new one.
NewClient(userid, client = -1)
{
	if (client == -1)
		client = GetClientOfUserId(userid);
	
	if (g_Clients[client][(ClientData:UserId)] != userid)
	{
		g_Clients[client][(ClientData:UserId)] = userid;
		g_Clients[client][(ClientData:Bomb)] = (BombType:None);
		g_Clients[client][(ClientData:BuyCount)] = 0;
		g_Clients[client][(ClientData:IsBombArmed)] = false;
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	NewClient(userid);
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	g_Clients[client][(ClientData:UserId)] = -1;
	
	if (g_Clients[client][(ClientData:Bomb)] > (BombType:Upgrade))
	{
		new Team:team = Team:GetClientTeam(client);
		--g_stat_BombCount[team];
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (g_Clients[client][(ClientData:Bomb)] > (BombType:Upgrade))
	{
		new Team:team = Team:GetClientTeam(client);
		--g_stat_BombCount[team];
		PrintToChat(client, "%sYou died. Removing bomb. (Level:%d)", g_pluginPrefix, g_Clients[client][(ClientData:Bomb)]);
		KillTimer(g_Clients[client][timerData]);
		g_Clients[client][timerData] = INVALID_HANDLE;
	}
	
	g_Clients[client][(ClientData:Bomb)] = (BombType:None);
	g_Clients[client][(ClientData:IsBombArmed)] = false;
	
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 0; i < MaxClients; ++i)
	{
		//Kill the timer from the round, so they don't explode at the start of the next one.
		if (g_Clients[i][timerData] != INVALID_HANDLE) {
			KillTimer(g_Clients[i][timerData]);
			g_Clients[i][timerData] = INVALID_HANDLE;
		}
	}
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Reset buy timer.
	g_fBuyTimeEnd = GetEngineTime() + GetConVarFloat(g_cvar_BombBuyTime);
	g_RandExplosion += GetConVarInt(g_cvar_RandomExplosion);
	//Reset the bomb-count to 0 at start of each round
	g_stat_BombCount[Team:Terrorist] = 0;
	g_stat_BombCount[Team:CounterTerrorist] = 0;
	
	for (new i = 0; i < MaxClients; ++i)
	{
		g_Clients[i][(ClientData:BuyCount)] = 0;
		if (g_Clients[i][(ClientData:Bomb)] > (BombType:Upgrade) && IsPlayerAlive(i))
		{
			//Only care about T's and CT's
			new Team:team = Team:GetClientTeam(i);
			if (team == Team:Terrorist || team == Team:CounterTerrorist)
			{
				//Player is living and still has bomb
				PrintToChat(i, "%sYou are wearing a bomb. (Level:%d)", g_pluginPrefix, g_Clients[i][(ClientData:Bomb)]);
				g_stat_BombCount[team]++;
				
				//Start a timer for the bomb to randomly explode.
				//Explode sometime between 30 seconds and 2 minutes after round starts.
				new Float:time = GetRandomFloat(30.0, 120.0);
				g_Clients[i][timerData] = CreateTimer(time, TimerCallback_RandomExplosion, i);
			}
		}
	}
	
	//Get the number of bombs per team and check them against the limit.
	new bombLimitT, bombLimitCT, canBuyBombT=1, canBuyBombCT=1;
	bombLimitT = GetConVarInt(g_cvar_BombLimitT);
	bombLimitCT = GetConVarInt(g_cvar_BombLimitCT);
	
	if (g_stat_BombCount[2] >= bombLimitT)
		canBuyBombT = 0;
	if (g_stat_BombCount[3] >= bombLimitCT)
		canBuyBombCT = 0;
	
	//Show the menu to buy the bomb if the limit is not reached.
	new maxclients = GetMaxClients();
	for(new i=1;i<=maxclients;i++)
	{
		//Make sure the player is alive and playing and not AFK/Spectating.
		if(IsPlayerAlive(i))
		{
			//Only care about T's and CT's
			new Team:team = Team:GetClientTeam(i);
			switch (team)
			{
				case 3: //CT
				{
					if (canBuyBombCT == 1)
					{
						ShowBuyMenu(i);
					}
				}
				case 2: //T
				{
					if (canBuyBombT == 1)
					{
						ShowBuyMenu(i);
					}
				}
			}
		}
	}
}

public Action:TimerCallback_Detonate(Handle:Timer, any:client)
{
	Detonate(client);
}

Detonate(client)
{
	// Explosion!
	new ExplosionIndex = CreateEntityByName("env_explosion");
	if (ExplosionIndex != -1)
	{
		new radius = GetConVarInt(g_cvar_SizeMultiplier) * _:g_Clients[client][(ClientData:Bomb)];
		SetEntProp(ExplosionIndex, Prop_Data, "m_spawnflags", 16384);
		SetEntProp(ExplosionIndex, Prop_Data, "m_iMagnitude", GetConVarInt(g_cvar_ExplosionDamage));
		SetEntProp(ExplosionIndex, Prop_Data, "m_iRadiusOverride", radius);

		DispatchSpawn(ExplosionIndex);
		ActivateEntity(ExplosionIndex);
		
		new Float:playerEyes[3];
		GetClientEyePosition(client, playerEyes);
		new clientTeam = GetEntProp(client, Prop_Send, "m_iTeamNum");

		TeleportEntity(ExplosionIndex, playerEyes, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(ExplosionIndex, Prop_Send, "m_hOwnerEntity", client);
		SetEntProp(ExplosionIndex, Prop_Send, "m_iTeamNum", clientTeam);

		EmitAmbientSound("ambient/explosions/explode_1.wav", NULL_VECTOR, client);
		
		AcceptEntityInput(ExplosionIndex, "Explode");
		AcceptEntityInput(ExplosionIndex, "Kill");
	}
}

public Action:Command_Detonate(client, args)
{
	if (!(client && IsClientInGame(client)) || !GetConVarBool(g_cvar_PluginEnabled) || !IsPlayerAlive(client))
		return Plugin_Handled;
		
	if (args != 0)
	{
		ReplyToCommand(client, "%sUsage : sm_jihad_detonate", g_pluginPrefix);
		return Plugin_Handled;
	}
	
	if (g_Clients[client][(ClientData:Bomb)] <= (BombType:Upgrade))
	{
		ReplyToCommand(client, "%sYou do not wear a bomb.", g_pluginPrefix);
		return Plugin_Handled;
	}
	
	if (g_Clients[client][(ClientData:IsBombArmed)] == false)
	{
		ReplyToCommand(client, "%sYour bomb is not armed.", g_pluginPrefix);
		return Plugin_Handled;
	}
	
	// Random fail
	new randomInt = GetRandomInt(1, 100);
	new Float:failRate = GetConVarFloat(g_cvar_FailRate);
	if (randomInt <= failRate * 100)
	{
		g_Clients[client][(ClientData:IsBombArmed)] = false;

		new Float:time = GetConVarFloat(g_cvar_PreDelay);
		CreateTimer(time, TimerCallback_ArmBomb, client);
		
		EmitAmbientSound("buttons/button11.wav", NULL_VECTOR, client);
		ReplyToCommand(client, "%sWooops! Better luck next time.", g_pluginPrefix);
		return Plugin_Handled;
	}
	
	// Remove the bomb
	if (g_Clients[client][(ClientData:Bomb)] > (BombType:Upgrade))
	{
		new Team:team = Team:GetClientTeam(client);
		--g_stat_BombCount[team];
	}

	g_Clients[client][(ClientData:Bomb)] = (BombType:None);
	g_Clients[client][(ClientData:IsBombArmed)] = false;
	
	// Play the sound
	new String:soundPath[STR_MAX_LEN];
	//new String:clientName[STR_MAX_LEN];
	//GetClientName(client, clientName, STR_MAX_LEN);
	GetConVarString(g_cvar_PostSoundPath, soundPath, STR_MAX_LEN);
	if (strlen(soundPath) != 0)
	{
		//LogMessage("Playing jihad sound. %s emiting from %s", soundPath, clientName);
		EmitAmbientSound(soundPath, NULL_VECTOR, client);
	}	
	// Detonate the bomb
	new Float:time = GetConVarFloat(g_cvar_PostDelay);
	if (time <= 0.0)
		Detonate(client);
		
	else
		CreateTimer(time, TimerCallback_Detonate, client);
	
	return Plugin_Handled;
}

public Action:TimerCallback_ArmBomb(Handle:Timer, any:client)
{
	g_Clients[client][(ClientData:IsBombArmed)] = true;
	PrintToChat(client, "%sYour bomb is now armed.", g_pluginPrefix);
	
	new colorEnabled = GetConVarBool(g_cvar_ColorOnArmed);
	if (colorEnabled)
		SetEntityRenderColor(client, 255, 0, 0, 255); // rgba
	
	EmitAmbientSound("buttons/blip2.wav", NULL_VECTOR, client);
}

// Gives a bomb to {client} if he has enough money({price}) and substract {price} from his money.
BuyBomb(client, BombType:type, price)
{
	new Team:team = Team:GetClientTeam(client);
	if (team != (Team:Terrorist) && team != (Team:CounterTerrorist))
	{
		ReplyToCommand(client, "%sYou must be playing to buy a bomb.", g_pluginPrefix);
		return;
	}

	
	if (type > (BombType:Upgrade))
	{
		new bombLimit;
		if (team == (Team:Terrorist))
			bombLimit = GetConVarInt(g_cvar_BombLimitT);
		else if (team == (Team:CounterTerrorist))
			bombLimit = GetConVarInt(g_cvar_BombLimitCT);
			
		if (g_stat_BombCount[team] >= bombLimit)
		{
			ReplyToCommand(
				client, 
				"%sThere are too many players wearing bombs on your team. (Current:%d, Max:%d)", 
				g_pluginPrefix, g_stat_BombCount[team], bombLimit);
			return;
		}
		
		new bombLimitRound = GetConVarInt(g_cvar_BombLimitRound);
		if (g_Clients[client][(ClientData:BuyCount)] >= bombLimitRound)
		{
			ReplyToCommand(client, "%sYou can not buy a bomb again this round. (Max:%d)", g_pluginPrefix, bombLimitRound);
			return;
		}

	}

	new cashCurrent = GetEntData(client, g_iAccount);
	if (cashCurrent >= price)
	{
		SetEntData(client, g_iAccount, cashCurrent - price, 4, true);
		if (type > (BombType:Upgrade))
		{
			g_Clients[client][(ClientData:Bomb)] = type;
			++g_stat_BombCount[team];
			++g_Clients[client][(ClientData:BuyCount)];
		}
		
		else
			++g_Clients[client][(ClientData:Bomb)];
		
		ReplyToCommand(client, "%sYou now wear a bomb. (Level:%d)", g_pluginPrefix, g_Clients[client][(ClientData:Bomb)]);
		
		// create the timer that will arm the bomb.
		new Float:time = GetConVarFloat(g_cvar_PreDelay);
		CreateTimer(time, TimerCallback_ArmBomb, client);
		return;
	}
	
	else
	{
		ReplyToCommand(client, "%sYou do not have sufficient money to perform an upgrade. (Cash:%d, Price:%d)", g_pluginPrefix, cashCurrent, price);
		return;
	}
}

public Action:Command_BuyBomb(client, args)
{
	if (!(client && IsClientInGame(client)) || !GetConVarBool(g_cvar_PluginEnabled) || !IsPlayerAlive(client))
		return Plugin_Handled;
		
	//Prevent purchasing the bomb after X seconds (default is 10)
	if (!BuyAllowed())
	{
		ReplyToCommand(client, "%sBuy time has exceeded.", g_pluginPrefix);
		return Plugin_Handled;
	}
		
	new BombType:maxLevels = BombType:GetConVarInt(g_cvar_BombLevels);
	if (args != 1)
	{
		ReplyToCommand(client, "%sUsage : sm_jihad_buybomb <[0-%d]>", g_pluginPrefix, maxLevels);
		return Plugin_Handled;
	}
	
	new String:arg1[STR_MAX_LEN];
	GetCmdArg(1, arg1, STR_MAX_LEN);
	new BombType:buyType = BombType:StringToInt(arg1);

	if ((BombType:Upgrade) > buyType || buyType > maxLevels)	
	{
		ReplyToCommand(client, "%sInvalid bomb level. (Max:%d)", g_pluginPrefix, maxLevels);
		return Plugin_Handled;
	}
	
	else if ((BombType:Upgrade) == buyType)
	{
		if (g_Clients[client][(ClientData:Bomb)] <= (BombType:Upgrade)
			|| g_Clients[client][(ClientData:Bomb)] >= maxLevels)
		{
			ReplyToCommand(client, "%sYou do not have a bomb to upgrade.", g_pluginPrefix);
			return Plugin_Handled;
		}
		
		BuyBomb(client, (BombType:Upgrade), GetConVarInt(g_cvar_PriceUpgrade));
	}
	
	else
	{
		if (g_Clients[client][(ClientData:Bomb)] != (BombType:None))
		{
			ReplyToCommand(client, "%sYou already wear a bomb.", g_pluginPrefix);
			return Plugin_Handled;
		}
		
		new price = GetConVarInt(g_cvar_PriceBase) + (GetConVarInt(g_cvar_PriceUpgrade) * (_:buyType - 1));
		BuyBomb(client, buyType, price);
	}
	
	return Plugin_Handled;
}

public bool:BuyAllowed()
{
	return (GetEngineTime() < g_fBuyTimeEnd ? true : false);
}

//Setup the Buy Bomb Menu.
public ShowBuyMenu(client)
{
	new Handle:menu=CreateMenu(BombMenuHandler);
	SetMenuTitle(menu, "Purchase a bomb:\n ");
	
	//Make sure the player can purchase a bomb.
	new playerCash=GetEntData(client,MoneyOffset,4);
	if (playerCash >= GetConVarInt(g_cvar_PriceBase))
		AddMenuItem(menu, "buybomb", "Buy Bomb");
		
	if (GetConVarInt(g_cvar_BombLevels) > 1 && playerCash >= GetConVarInt(g_cvar_PriceUpgrade)) //If there is only 1 bomb level, don't bother showing 'Upgrade'.
		AddMenuItem(menu, "upgrade", "Upgrade Bomb");
		
	DisplayMenu(menu,client,20);
}

public BombMenuHandler(Handle:menu,MenuAction:action,client,slot)
{
	if(action==MenuAction_Select)
	{
		new String:info[32];
		new bool:found = GetMenuItem(menu,slot,info,31);
		
		//Buy bomb
		if (StrEqual(info, "buybomb")  && found)
		{
			if (!(client && IsClientInGame(client)) || !GetConVarBool(g_cvar_PluginEnabled) || !IsPlayerAlive(client))
				return;
				
			//Prevent purchasing the bomb after X seconds (default is 10)
			if (!BuyAllowed())
			{
				ReplyToCommand(client, "%sBuy time has exceeded.", g_pluginPrefix);
				return;
			}
		
			if (g_Clients[client][(ClientData:Bomb)] != (BombType:None))
			{
				ReplyToCommand(client, "%sYou already wear a bomb.", g_pluginPrefix);
				return;
			}
			
			new price = GetConVarInt(g_cvar_PriceBase);
			BuyBomb(client, BombType:Base, price);
		}
		
		//Upgrade Bomb.
		if (StrEqual(info, "upgrade") && found)
		{
			if (!(client && IsClientInGame(client)) || !GetConVarBool(g_cvar_PluginEnabled) || !IsPlayerAlive(client))
				return;
				
			//Prevent purchasing the bomb after X seconds (default is 10)
			if (!BuyAllowed())
			{
				ReplyToCommand(client, "%sBuy time has exceeded.", g_pluginPrefix);
				return;
			}
				
			new BombType:maxLevels = BombType:GetConVarInt(g_cvar_BombLevels);
			new BombType:buyType = (BombType:Upgrade);
			if ((BombType:Upgrade) > buyType || buyType > maxLevels)	
			{
				ReplyToCommand(client, "%sCannot upgrade further. (Max:%d)", g_pluginPrefix, maxLevels);
				return;
			}
			
			else if ((BombType:Upgrade) == buyType)
			{
				if (g_Clients[client][(ClientData:Bomb)] <= (BombType:Upgrade)
					|| g_Clients[client][(ClientData:Bomb)] >= maxLevels)
				{
					ReplyToCommand(client, "%sYou do not have a bomb to upgrade.", g_pluginPrefix);
					return;
				}
				
				BuyBomb(client, (BombType:Upgrade), GetConVarInt(g_cvar_PriceUpgrade));
			}
		}
	}
	if(action==MenuAction_End)
		CloseHandle(menu);
}

public Action:TimerCallback_RandomExplosion(Handle:Timer, any:client)
{
	new randPercent = GetRandomInt(1, 100);
	if (randPercent <= g_RandExplosion && IsPlayerAlive(client)) {
		PrintToChat(client, "%sOh, shit. You waited too long and the bomb malfunctioned!", g_pluginPrefix);
		Detonate(client);
	}
}