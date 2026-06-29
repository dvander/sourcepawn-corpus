#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "3.1.0"

public Plugin:myinfo = 
{
	name = "[L4D, L4D2] Less Than 4 Dead",
	author = "chinagreenelvis",
	description = "Dynamically changes the number of survivors.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1330706"
}

new Handle:lessthan4dead = INVALID_HANDLE;
new Handle:lessthan4dead_survivors = INVALID_HANDLE;

new Handle:survivor_limit = INVALID_HANDLE;

new botstokick = 0;

static Handle:hRoundRespawn = INVALID_HANDLE;
static Handle:hGameConf = INVALID_HANDLE;

new NewClient[MAXPLAYERS+1];

new bool:Enabled = false;
new bool:Newmap = true;

public OnPluginStart() 
{
	lessthan4dead = CreateConVar("lessthan4dead", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	lessthan4dead_survivors = CreateConVar("lessthan4dead_survivors", "1", "This is the minimum number of possible survivors.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	survivor_limit = (FindConVar("survivor_limit"));
	
	AutoExecConfig(true, "cge_l4d2_lessthan4dead");
	
	HookConVarChange(lessthan4dead, ConVarChange_lessthan4dead);
	HookConVarChange(lessthan4dead_survivors, ConVarChange_lessthan4dead_survivors);
	
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
	Newmap = true;
}

public ConVarChange_lessthan4dead(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0)
	{
		PlayerCheck();
	}
}

public ConVarChange_lessthan4dead_survivors(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (strcmp(oldValue, newValue) != 0 && GetConVarInt(lessthan4dead) == 1)
	{
		PlayerCheck();
	}
}

public OnMapStart()
{
	if (GetConVarInt(lessthan4dead) == 1)
	{
		PrecacheModel("models/survivors/survivor_biker.mdl");
		PrecacheModel("models/survivors/survivor_coach.mdl");
		PrecacheModel("models/survivors/survivor_gambler.mdl");
		PrecacheModel("models/survivors/survivor_manager.mdl");
		PrecacheModel("models/survivors/survivor_mechanic.mdl");
		PrecacheModel("models/survivors/survivor_namvet.mdl");
		PrecacheModel("models/survivors/survivor_producer.mdl");
		PrecacheModel("models/survivors/survivor_teenangst.mdl");
	}
}

public OnMapEnd()
{
	Enabled = false;
}

public OnClientPutInServer(client)
{
	if (GetConVarInt(lessthan4dead) == 1 && !IsFakeClient(client))
	{
		NewClient[client] = 1;
		if (Enabled == true)
		{
			PlayerCheck();
		}
	}
}

public OnClientDisconnect(client)
{
	if (GetConVarInt(lessthan4dead) == 1 && !IsFakeClient(client))
	{
		if (Enabled == true)
		{
			PlayerCheck();
		}
	}
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(lessthan4dead) == 1)
		{
			if (Newmap == true)
			{
				PlayerCheck();
				Newmap = false;
			}
			Enabled = true;
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
	{
		if (GetConVarInt(lessthan4dead) == 1)
		{
			if (Newmap == true)
			{
				PlayerCheck();
				Newmap = false;
			}
			Enabled = true;
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
				NewClient[client] = 1;
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
	CreateTimer(0.5, Timer_PlayerCheck);
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
		minsurvivors = GetConVarInt(survivor_limit);
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
	new shouldbots = minsurvivors - actualsurvivorplayers;
	//PrintToChatAll("Actual players %i", players);
	//PrintToChatAll("Actual survivor players %i", actualsurvivorplayers);
	//PrintToChatAll("Survivor bots %i", bots);
	//PrintToChatAll("Idle survivors %i", idlesurvivors);
	//PrintToChatAll("Supposed bots %i", shouldbots);
	if (shouldbots > bots)
	{
		new addbots = shouldbots - bots;
		for (new i = 1; i <= addbots; i++)
		{
			ServerCommand("sb_add");
		}
	}
	if (shouldbots < bots)
	{
		new subtractbots = bots - shouldbots;
		botstokick = subtractbots;
		//PrintToChatAll("Bots to kick %i", botstokick);
		CreateTimer(0.1, Timer_KickBot);
	}
	if (players == 0)
	{
		PrintToServer("Resetting Bools");
		Newmap = true;
		Enabled = false;
	}
}

public Action:Timer_KickBot(Handle:timer)
{	
	//PrintToChatAll("A bot should be about to be kicked.")
	for (new i = 1; i <= MaxClients; i++)
	{
		if (botstokick >= 1)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == 2) 
			{ 
				//PrintToChatAll("A bot is very likely about to be kicked.")
				if (IsFakeClient(i) && GetEntProp(i, Prop_Send, "m_humanSpectatorUserID") == 0) 
				{
					//PrintToChatAll("A bot is definitely about to be kicked.")
					if (IsPlayerAlive(i))
					{
						//ForcePlayerSuicide(i);
					}
					KickClient(i);
					botstokick--;
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
	PlayerCheck();
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
