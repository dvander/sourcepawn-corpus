#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.7"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Less Than 4 Dead",
	author = "chinagreenelvis",
	description = "Dynamically change the number of survivors",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1330706"
}

new bool:Enabled = false;
new survivorlimit = 0;

new NewClient[MAXPLAYERS+1];

new Handle:lt4d_survivors = INVALID_HANDLE;
new Handle:lt4d_survivorsmin = INVALID_HANDLE;
new Handle:lt4d_survivorsmax = INVALID_HANDLE;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

public OnPluginStart() 
{
	lt4d_survivors = CreateConVar("lt4d_survivors", "1", "Allow dyanamic survivor numbers? 1: Yes, 0: No", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_survivorsmin = CreateConVar("lt4d_survivorsmin", "1", "Minimum number of survivors to allow (additional slots are filled by bots)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lt4d_survivorsmax = CreateConVar("lt4d_survivorsmax", "4", "Maximum number of survivors to allow", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	AutoExecConfig(true, "l4d_2_lessthan4dead");
	
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
	if (GetConVarInt(lt4d_survivors) == 1)
	{
		new flags = GetConVarFlags(FindConVar("survivor_limit")); 
		if (flags & FCVAR_NOTIFY)
		{ 
			SetConVarFlags(FindConVar("survivor_limit"), flags ^ FCVAR_NOTIFY); 
		}
		new max = GetConVarInt(lt4d_survivorsmax);
		if (GetConVarInt(lt4d_survivorsmax) < GetConVarInt(lt4d_survivorsmin))
		{
			max = GetConVarInt(lt4d_survivorsmin);
		}
		SetConVarInt(FindConVar("survivor_limit"), max);
		SetConVarInt(FindConVar("sv_visiblemaxplayers"), max);
		SetConVarInt(FindConVar("director_no_survivor_bots"), 1);
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
	if (GetConVarInt(lt4d_survivors) == 1 && !IsFakeClient(client))
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
		if (GetConVarInt(lt4d_survivors) == 1 && Enabled == false)
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
		if (GetConVarInt(lt4d_survivors) == 1 && Enabled == false)
		{
			Enabled = true;
			PlayerCheck();
		}
	}
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (NewClient[client] == 1 && GetEventInt(event, "team") == 2)
	{
		CreateTimer(1.0, Timer_Respawn, client);
	}
	if (NewClient[client] == 1 && GetEventInt(event, "team") == 3)
	{
		NewClient[client] = 0;
	}
}

public Event_SurvivorRescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (GetConVarInt(lt4d_survivors) == 1 && NewClient[victim] == 1)
	{
		GiveRandomWeapon(victim);
	}
}

PlayerCheck()
{
	if (Enabled == true)
	{
		CreateTimer(2.0, Timer_PlayerCheck);
	}
}

public Action:Timer_PlayerCheck(Handle:timer)
{
	//PrintToChatAll("Performing PlayerCheck");
	new minsurvivors = GetConVarInt(lt4d_survivorsmin);
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
		SetConVarInt(FindConVar("survivor_limit"), survivorlimit, true, false);
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
				CreateTimer(2.0, Timer_KickBot);
			}
		}
	}
}

public Action:Timer_KickFakeClient(Handle:timer, any:client)
{
	KickClient(client);
	CreateTimer(0.1, Timer_DirectorSurvivorBots);
}

public Action:Timer_DirectorSurvivorBots(Handle:timer)
{
	SetConVarInt(FindConVar("director_no_survivor_bots"), 1);
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
	CreateTimer(0.1, Timer_NewClient, client);
}

public Action:Timer_NewClient(Handle:timer, any:client)
{
	if (client)
	{
		NewClient[client] = 0;
	}
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
