#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.8.0"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Less Than 4 Dead",
	author = "chinagreenelvis",
	description = "Dynamically changes the number of survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1330706"
}

new Handle:lessthan4dead = INVALID_HANDLE;
new Handle:lessthan4dead_survivors = INVALID_HANDLE;
new Handle:lessthan4dead_maxplayers = INVALID_HANDLE;

new Handle:survivor_limit = INVALID_HANDLE;
new Handle:sv_visiblemaxplayers = INVALID_HANDLE;
new Handle:director_no_survivor_bots = INVALID_HANDLE;

new survivor_limit_cvar = 0;
new sv_visiblemaxplayers_cvar = 0;
new director_no_survivor_bots_cvar = 0;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

new NewClient[MAXPLAYERS+1];
new survivorlimit = 0;

new bool:Enabled = false;

public OnPluginStart() 
{
	lessthan4dead = CreateConVar("lessthan4dead", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lessthan4dead_maxplayers = CreateConVar("lessthan4dead_maxplayers", "4", "Maximum number of players to allow on the server. This should always be higher than lessthan4dead_survivors. Additional plugins are required to enable more than four players.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lessthan4dead_survivors = CreateConVar("lessthan4dead_survivors", "1", "This is the number of survivors the game will start with.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	survivor_limit =(FindConVar("survivor_limit"));
	sv_visiblemaxplayers =(FindConVar("sv_visiblemaxplayers"));
	director_no_survivor_bots =(FindConVar("director_no_survivor_bots"));
	
	AutoExecConfig(true, "cge_l4d2_lessthan4dead");
	
	HookConVarChange(lessthan4dead, ConVarChange_lessthan4dead);
	HookConVarChange(lessthan4dead_survivors, ConVarChange_other);
	HookConVarChange(lessthan4dead_maxplayers, ConVarChange_other);
	
	LoadTranslations("common.phrases");
	hGameConf = LoadGameConfigFile("l4drespawn");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
	
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("survivor_rescued", Event_SurvivorRescued);
	
	Enabled = false;
}

public OnConfigsExecuted()
{
	new flags = GetConVarFlags(FindConVar("survivor_limit")); 
	if (flags & FCVAR_NOTIFY)
	{ 
		SetConVarFlags(FindConVar("survivor_limit"), flags ^ FCVAR_NOTIFY); 
	}
	
	survivor_limit_cvar = GetConVarInt(survivor_limit);
	sv_visiblemaxplayers_cvar = GetConVarInt(sv_visiblemaxplayers);
	director_no_survivor_bots_cvar = GetConVarInt(director_no_survivor_bots);
	
	if (GetConVarInt(lessthan4dead) == 1)
	{
		SetCvars();
	}
}

SetCvars()
{
	new max = GetConVarInt(lessthan4dead_maxplayers);
	if (GetConVarInt(lessthan4dead_maxplayers) < GetConVarInt(lessthan4dead_survivors))
	{
		max = GetConVarInt(lessthan4dead_survivors);
	}
	SetConVarInt(survivor_limit, max);
	SetConVarInt(sv_visiblemaxplayers, max);
	SetConVarInt(director_no_survivor_bots, 1);
}

public ConVarChange_lessthan4dead(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
	{
		if (StringToInt(newValue) == 1)
		{
			SetCvars();
			PlayerCheck();
		}
		else
		{
			SetConVarInt(survivor_limit, survivor_limit_cvar);
			SetConVarInt(sv_visiblemaxplayers, sv_visiblemaxplayers_cvar);
			SetConVarInt(director_no_survivor_bots, director_no_survivor_bots_cvar);
			PlayerCheck();
		}
	}
}

public ConVarChange_other(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0 && GetConVarInt(lessthan4dead) == 1)
	{
		SetCvars();
		PlayerCheck();
	}
}

public OnMapEnd()
{
	if (Enabled == true)
	{
		Enabled = false;
	}
}

public OnClientConnected(client)
{
	if (GetConVarInt(lessthan4dead) == 1 && !IsFakeClient(client))
	{
		NewClient[client] = 1;
	}
	PlayerCheck();
}


public OnClientDisconnect(client)
{
	PlayerCheck();
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(lessthan4dead) == 1 && Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(lessthan4dead) == 1 && Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
		}
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetConVarInt(lessthan4dead) == 1)
	{
		if (NewClient[client] == 1)
		{
			if (GetEventInt(event, "team") == 2)
			{
				CreateTimer(1.0, Timer_Respawn, client);
			}
			if (GetEventInt(event, "team") == 3)
			{
				NewClient[client] = 0;
			}
		}
	}
	else
	{
		if (GetEventInt(event, "team") == 2 || GetEventInt(event, "team") == 3)
		{
			NewClient[client] = 0;
		}
	}
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (GetConVarInt(lessthan4dead) == 1 && NewClient[victim] == 1)
	{
		GiveRandomWeapon(victim);
	}
	NewClient[victim] = 0;
}

PlayerCheck()
{
	if (Enabled == true)
	{
		CreateTimer(0.5, Timer_PlayerCheck);
	}
}

public Action:Timer_PlayerCheck(Handle:timer)
{
	//PrintToChatAll("Performing PlayerCheck");
	new minsurvivors = 0;
	if (GetConVarInt(lessthan4dead) == 1)
	{
		minsurvivors = GetConVarInt(lessthan4dead_survivors);
	}
	else
	{
		minsurvivors = survivor_limit_cvar;
	}
	new players = 0;
	new bots = 0;
	new survivorplayers = 0;
	new idlesurvivors = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			players++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
		{
			bots++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i))
		{
			survivorplayers++;
		}
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2 && IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") > 0)
		{
			idlesurvivors++;
		}
	}
	new actualsurvivorplayers = survivorplayers + idlesurvivors;
	new waitingplayers = players - actualsurvivorplayers;
	new shouldbots = minsurvivors - actualsurvivorplayers;
	//PrintToChatAll("Actual players %i", players);
	//PrintToChatAll("Actual survivor players %i", actualsurvivorplayers);
	//PrintToChatAll("Survivor bots %i", bots);
	//PrintToChatAll("Idle survivors %i", idlesurvivors);
	if (shouldbots <= 0)
	{
		shouldbots = waitingplayers;
	}
	survivorlimit = actualsurvivorplayers + shouldbots;
	//PrintToChatAll("Survivor limit %i", survivorlimit);
	if (survivorlimit > 0)
	{
		SetConVarInt(survivor_limit, survivorlimit, true, false);
		if (shouldbots > bots)
		{
			new addbots = shouldbots - bots;
			for (new i = 1; i <= addbots; i++)
			{
				ServerCommand("sb_add");
				CreateTimer(0.1, Timer_DirectorSurvivorBots);
				
				//SetConVarInt(FindConVar("director_no_survivor_bots"), 0);
				//new bot = CreateFakeClient("SurvivorBot");
				//ChangeClientTeam(bot, 2);
				//DispatchKeyValue(bot, "classname", "SurvivorBot");
				//DispatchSpawn(bot);
				//CreateTimer(0.1, Timer_KickFakeClient, bot);
			}
		}
		if (shouldbots < bots)
		{
			new subtractbots = bots - shouldbots;
			for (new i = 1; i <= subtractbots; i++)
			{
				CreateTimer(0.1, Timer_KickBot);
			}
		}
	}
}

//	public Action:Timer_KickFakeClient(Handle:timer, any:client)
//	{
//		KickClient(client);
//		CreateTimer(0.1, Timer_DirectorSurvivorBots);
//	}

public Action:Timer_DirectorSurvivorBots(Handle:timer)
{
	if (GetConVarInt(lessthan4dead) == 1)
	{
		SetConVarInt(director_no_survivor_bots, 1);
	}
	else
	{
		SetConVarInt(director_no_survivor_bots, director_no_survivor_bots_cvar);
	}
}

public Action:Timer_KickBot(Handle:timer)
{	
	//PrintToChatAll("A bot should be about to be kicked.")
	new bool:ABotHasBeenKicked = false;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (ABotHasBeenKicked == false)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) 
			{ 
				//PrintToChatAll("A bot is very likely about to be kicked.")
				if (IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
				{
					//PrintToChatAll("A bot is definitely about to be kicked.")
					if (IsPlayerAlive(i))
					{
						ForcePlayerSuicide(i);
					}
					KickClient(i);
					ABotHasBeenKicked = true;
				}
			}
		}
	}
}

public Action:Timer_Respawn(Handle:timer, any:client)
{
	if (!IsPlayerAlive(client))
	{
		RespawnPlayer(client);
	}
	else
	{
		NewClient[client] = 0;
	}
}

static RespawnPlayer(client)
{
	SDKCall(hRoundRespawn, client);
	GiveRandomWeapon(client);
	TeleportPlayer(client);
}

static GiveRandomWeapon(client)
{
	new RandomWeapon = GetRandomInt(1, 9);
	if (RandomWeapon == 1)
	{
		CheatCommand(client, "give", "autoshotgun");
	}
	if (RandomWeapon == 1)
	{
		CheatCommand(client, "give", "pistol_magnum");
	}
	if (RandomWeapon == 2)
	{
		CheatCommand(client, "give", "pumpshotgun");
	}
	if (RandomWeapon == 3)
	{
		CheatCommand(client, "give", "rifle");
	}
	if (RandomWeapon == 4)
	{
		CheatCommand(client, "give", "rifle_ak47");
	}
	if (RandomWeapon == 5)
	{
		CheatCommand(client, "give", "rifle_desert");
	}
	if (RandomWeapon == 6)
	{
		CheatCommand(client, "give", "shotgun_chrome");
	}
	if (RandomWeapon == 7)
	{
		CheatCommand(client, "give", "shotgun_spas");
	}
	if (RandomWeapon == 8)
	{
		CheatCommand(client, "give", "smg");
	}
	if (RandomWeapon == 9)
	{
		CheatCommand(client, "give", "smg_silenced");
	}
}

static TeleportPlayer(client)
{
	new iClients[MAXPLAYERS+1];
	new iNumClients = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && !IsFakeClient(i) && IsPlayerAlive(i) && NewClient[i] == 0)
		{
			iClients[iNumClients++] = i;
			decl String:clientname[64];
			GetClientName(i, clientname, 64);
			//PrintToServer("%s is a valid player to teleport to.", clientname);
		}
	}
	new iRandomClient = iClients[GetRandomInt(0, iNumClients-1)];
	decl String:nameofclient[64];
	GetClientName(iRandomClient, nameofclient, 64);
	//PrintToServer("Teleporting new player to %s", nameofclient);
	new Float:coordinates[3];
	GetClientAbsOrigin(iRandomClient, coordinates);
	TeleportEntity(client, coordinates, NULL_VECTOR, NULL_VECTOR);
	NewClient[client] = 0;
}

stock CheatCommand(client, String:command[], String:arguments[]="")
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
