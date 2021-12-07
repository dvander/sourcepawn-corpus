#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#define SDKHOOKS false
#if SDKHOOKS
#include <sdkhooks>
#endif
#define PLUGIN_VERSION "1.0 alpha"
#define DEVELOPER_INFO false

int timercount = -3;

ConVar Is_Plugin_Enabled;
ConVar Normalize_Health;
ConVar Medkit_Full_Health;
ConVar Remove_Spawns;
ConVar Colored_Tanks;
#if SDKHOOKS
ConVar HuntingRifleMod;
#endif

public Plugin myinfo = 
{
	name = "[L4D] Assistant Director",
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	CreateConVar("l4d_ad_ver", PLUGIN_VERSION, "Assistant Director Version", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD);
	Is_Plugin_Enabled = CreateConVar("l4d_ad", "1", "Enable L4D Assistant Director plugin", FCVAR_NOTIFY|FCVAR_SPONLY);
	Normalize_Health = CreateConVar("l4d_ad_normalize_health", "1", "", FCVAR_NOTIFY|FCVAR_SPONLY);
	Medkit_Full_Health = CreateConVar("l4d_ad_fullhealth", "1", "", FCVAR_NOTIFY|FCVAR_SPONLY);
	Remove_Spawns = CreateConVar("l4d_ad_removespawns", "1", "", FCVAR_NOTIFY|FCVAR_SPONLY);
	Colored_Tanks = CreateConVar("l4d_ad_coloredtanks", "1", "", FCVAR_NOTIFY|FCVAR_SPONLY);
#if SDKHOOKS	
	HuntingRifleMod = CreateConVar("l4d_ad_huntingrifle_mod", "0", "", FCVAR_NOTIFY|FCVAR_SPONLY);
#endif	

	HookEvent("heal_success", Event_MedkitUsed);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_start_post_nav", Event_RoundStartPostNav);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("map_transition", Event_MapTransition);
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("finale_escape_start", Event_FinaleEscapeStart);
	HookEvent("witch_harasser_set", Event_WitchHarasserSet);
//	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("tank_spawn", Event_TankSpawn);
//	HookEvent("player_hurt", Event_PlayerHurt);
//	HookEvent("player_incapacitated", Event_PlayerIncapacitated);	
	RegAdminCmd("sm_starttimer", Command_StartTimer, ADMFLAG_RCON, "");
	RegAdminCmd("sm_stoptimer", Command_StopTimer, ADMFLAG_RCON, "");
	RegAdminCmd("sm_hp", Command_HP, ADMFLAG_RCON, "");
}

public void OnMapStart()
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return;
	}
	if (GetConVarInt(Remove_Spawns) < 1)
	{
		return;
	}	
	RemoveAllEntityes();
	return;
}

#if SDKHOOKS
public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return Plugin_Continue;
	}
	if (GetConVarInt(HuntingRifleMod) < 1)
	{
		return Plugin_Continue;
	}

	char sWeapon[32];
	GetEdictClassname(inflictor, sWeapon, sizeof(sWeapon));
	
	PrintToChatAll("\x05Event: OnTakeDamage (Start)");    
	PrintToChatAll("\x05Event: OnTakeDamage (%s :: %f)", sWeapon, damage);
	
	if(StrEqual(sWeapon, "rifle_ak47"))
    {
        damage = 300.0;
        return Plugin_Changed;
    }
    
	PrintToChatAll("\x05Event: OnTakeDamage (End)");
	return Plugin_Continue;
}
#endif

stock int AlivePlayers()
{
#if DEVELOPER_INFO		
	PrintToChatAll("\x04[DEVINFO]: \x03Function ( \x01AlivePlayers()\x03 )");
#endif	
	int alive_players = 0;
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				alive_players++;
			}
		}
	}
	return alive_players;
}

stock int GetSpecials(const char[] SpecialInfected)
{
	int j = 0;
	char ClientName[20];
	if (StrEqual(SpecialInfected, "Hunter", false))
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				if (GetClientTeam(i) == 3 && GetClientHealth(i) > 1)
				{
					GetClientName(i, ClientName, sizeof(ClientName));
					{
						if (StrEqual(ClientName, "Hunter", false) || StrEqual(ClientName, "(1)Hunter", false) || StrEqual(ClientName, "(2)Hunter", false) || StrEqual(ClientName, "(3)Hunter", false) || StrEqual(ClientName, "(4)Hunter", false) || StrEqual(ClientName, "(5)Hunter", false))
						{
							j++;
						}
					}
				}
			}
		}
		return j;
	}
	if (StrEqual(SpecialInfected, "Boomer", false))
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				if (GetClientTeam(i) == 3 && GetClientHealth(i) > 1)
				{
					GetClientName(i, ClientName, sizeof(ClientName));
					{
						if (StrEqual(ClientName, "Boomer", false) || StrEqual(ClientName, "(1)Boomer", false) || StrEqual(ClientName, "(2)Boomer", false) || StrEqual(ClientName, "(3)Boomer", false) || StrEqual(ClientName, "(4)Boomer", false) || StrEqual(ClientName, "(5)Boomer", false))
						{
							j++;
						}
					}
				}
			}
		}
		return j;
	}	
	if (StrEqual(SpecialInfected, "Smoker", false))
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				if (GetClientTeam(i) == 3 && GetClientHealth(i) > 1)
				{
					GetClientName(i, ClientName, sizeof(ClientName));
					{
						if (StrEqual(ClientName, "Smoker", false) || StrEqual(ClientName, "(1)Smoker", false) || StrEqual(ClientName, "(2)Smoker", false) || StrEqual(ClientName, "(3)Smoker", false) || StrEqual(ClientName, "(4)Smoker", false) || StrEqual(ClientName, "(5)Smoker", false))
						{
							j++;
						}
					}
				}
			}
		}
		return j;
	}
	if (StrEqual(SpecialInfected, "Tank", false))
	{
		for (int i = 1; i < MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				if (GetClientTeam(i) == 3 && GetClientHealth(i) > 1)
				{
					GetClientName(i, ClientName, sizeof(ClientName));
					{
						if (StrEqual(ClientName, "Tank", false) || StrEqual(ClientName, "(1)Tank", false) || StrEqual(ClientName, "(2)Tank", false) || StrEqual(ClientName, "(3)Tank", false) || StrEqual(ClientName, "(4)Tank", false) || StrEqual(ClientName, "(5)Tank", false))
						{
							j++;
						}
					}
				}
			}
		}
		return j;
	}
	return -1;
}

/*
public Action CheckTanks(Handle timer, any client)
{
	if (GetSpecials("Tank") > 1)
	{
		char ClientSteamID[12];
		char ClientName[20];
		int i;
		for (i = 1; i < MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				if (GetClientTeam(i) == 3 && GetClientHealth(i) > 1)
				{
					GetClientName(i, ClientName, sizeof(ClientName));
					{
						if (StrEqual(ClientName, "Tank(1)", false) || StrEqual(ClientName, "Tank(2)", false) || StrEqual(ClientName, "Tank(3)", false) || StrEqual(ClientName, "Tank(4)", false) || StrEqual(ClientName, "Tank(5)", false))
						{
							KickClient(i,  "fn_checktanks");
							CreateTimer(1.0, CheckTanks);
							return;
						}
					}
				}
			}
		}
	}
}
*/

/*
public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"));
	int target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return Plugin_Continue;

	if (client == target)
		return Plugin_Continue;
		
	if (GetEventInt(event, "dmg_health") < 1)
		return Plugin_Continue;

	char ClientSteamID[32];
	char TargetSteamID[32];

	GetClientAuthId(client, AuthId_Steam2, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthId(target, AuthId_Steam2, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	float X;

	X = (1 + (Multiplier[client] / 10));

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");

	PrintToChat(client, "\x01%N attacked %N", client, target);
	PrintToChat(client, "\x03%d (%d - voteban; 2750 - permanent) TK points!", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + 600);
	PrintToChat(target, "\x01%N attacked %N", client, target);
	PrintToChat(target, "\x03%d (%d - voteban; 2750 - permanent) TK points!", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + 600);
	CheckPunishmentPoints(client);

	return Plugin_Continue;
}
*/

public void SpawnSpecial(const char[] SpecialInfected)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				int flags = GetCommandFlags("z_spawn");
				SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
				FakeClientCommand(i, "z_spawn %s auto", SpecialInfected);
				SetCommandFlags("z_spawn", flags);
#if DEVELOPER_INFO				
				PrintToChatAll("\x04[DEVINFO]: \x03SpawnSpecial ( \x01%s spawned?\x03 )", SpecialInfected);
#endif
				return;
			}
		}
	}
}

public void SpawnRandomSpecial(const int SpawnCount)
{
	if (SpawnCount < 1)
	{
		return;
	}
	
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				int flags = GetCommandFlags("z_spawn");
				SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
				for (int j = 1; j < MaxClients; j++)
				{
					CreateTimer(GetRandomFloat(1.0, 3.0), SpawnTimer, GetRandomInt(1, 3));
				}
				SetCommandFlags("z_spawn", flags);
				return;
			}
		}
	}
}

public Action SpawnTimer(Handle timer, const any client)
{
	if (GetPlayersFromTeam(3) > 3)
		return;

	switch(client)
	{
		case 1: SpawnSpecial("hunter");
		case 2: SpawnSpecial("smoker");
		case 3: SpawnSpecial("boomer");
	}
	return;
}

//Used to set temp health, written by TheDanner.
void SetTempHealth(int client, int hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	float newOverheal = hp * 1.0; // prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

stock int FindEntityByClassname2(int startEnt, const char[] classname)
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

public void RemoveAllEntityByName(const char EntityName[64])
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, EntityName)) != -1)
	{
		RemoveEdict(entity);
	}
}

public Action TimedRemoveAllEntityes(Handle timer, any client)
{
	RemoveAllEntityes();
}

public void RemoveAllEntityes()
{
	int entity = -1;
	while ((entity = FindEntityByClassname2(entity, "weapon_autoshotgun_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);		
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_rifle_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_hunting_rifle_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_pumpshotgun_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_smg_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_pain_pills_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_first_aid_kit_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_pipe_bomb_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}
	while ((entity = FindEntityByClassname2(entity, "weapon_molotov_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}
/*	while ((entity = FindEntityByClassname2(entity, "weapon_ammo_spawn")) != -1)
	{
		if (IsValidEdict(entity))
			RemoveEdict(entity);	
	}*/
}

public void NormalizeHealth()
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return;
	}
	if (GetConVarInt(Normalize_Health) < 1)
	{
		return;
	}
#if DEVELOPER_INFO		
	PrintToChatAll("\x04[DEVINFO]: \x03Function ( \x01NormalizeHealth()\x03 )");
#endif	
	int map_full_health = 0;
	char current_map[36];
	GetCurrentMap(current_map, 35);
	if (StrEqual(current_map, "l4d_garage01_alleys", false))
	{
		map_full_health = 1;
	}
	
	int HP;
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
#if DEVELOPER_INFO		
	PrintToChatAll("\x04[DEVINFO]: \x03Health ( \x01%N - %d\x03 )", i, GetClientHealth(i));
#endif
				HP = GetEntProp(i, Prop_Send, "m_iHealth");
				if (map_full_health > 0)
				{
					SetEntityHealth(i, 100);
				}
				else
				{
					if (HP < 51)
					{
						SetEntityHealth(i, HP + 50);
					}
					else
					{
						SetEntityHealth(i, 100);
					}
				}
				SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
				SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
				SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0); 
				SetEntPropFloat(i, Prop_Send, "m_healthBufferTime", 0.0);
				SetTempHealth(i, 0);
			}
		}
	}
}

public Action DirectorTimer(Handle timer, any client)
{
	int PlayersA = AlivePlayers();
	int PlayersB = PlayersA - 10;
	if (PlayersB < 1)
	{
		PlayersB = 1;
	}
	if (timercount < 0)
	{
		return;
	}
	if (AlivePlayers() < 9)
	{
		timercount = 10;
		CreateTimer(1.0, DirectorTimer);
		return;
	}
	if (timercount == 0)
	{
		if (GetConVarInt(Is_Plugin_Enabled) == 0)
		{
			timercount = 0;
			CreateTimer(1.0, DirectorTimer);
			return;
		}
		if (GetSpecials("Tank") > 0)
		{
			if (GetPlayersFromTeam(3) < 3)
			{
				SpawnRandomSpecial(GetRandomInt(1, 3 - GetPlayersFromTeam(3)));
				timercount = RoundToZero(GetRandomFloat(36.0, 46.0) / SquareRoot(PlayersB * 1.0));
			}
		}
		else
		{
			if (GetPlayersFromTeam(3) < 3)
			{
				SpawnRandomSpecial(GetRandomInt(1, 3 - GetPlayersFromTeam(3)));
				timercount = RoundToZero(GetRandomFloat(16.0, 26.0) / SquareRoot(PlayersB * 1.0));
			}
		}
	}
	else
	{
		timercount--;
	}

#if DEVELOPER_INFO		
	PrintToChatAll("\x04[DEVINFO]: \x03Director Timer ( \x01%i\x03 )", timercount);
#endif	

	CreateTimer(1.0, DirectorTimer);
}

public Action Command_StartTimer(int client, int args)
{
	timercount = 0;
	CreateTimer(1.0, DirectorTimer);
}

public Action Command_StopTimer(int client, int args)
{
	timercount = -2;
}

public Action Command_HP(int client, int args)
{
	NormalizeHealth();
}

public Action Event_MedkitUsed(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return Plugin_Continue;
	}
	if (GetConVarInt(Medkit_Full_Health) < 1)
	{
		return Plugin_Continue;
	}
//	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "subject"));

	SetEntityHealth(target, 100);
	SetEntProp(target, Prop_Send, "m_isGoingToDie", 0);
	SetEntProp(target, Prop_Send, "m_currentReviveCount", 0);
	SetEntPropFloat(target, Prop_Send, "m_healthBuffer", 0.0); 
	SetEntPropFloat(target, Prop_Send, "m_healthBufferTime", 0.0);
	SetTempHealth(target, 0);

	return Plugin_Continue;
}

public Action Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int Witch = GetEventInt(event, "witchid");
	int WitchHP = GetConVarInt(FindConVar("z_witch_health"));
	if (WitchHP < 1001)
	{
		SetEntityRenderColor(Witch, 0, 0, 0, 255);
	}
	else if (WitchHP < 2001)
	{
		SetEntityRenderColor(Witch, 128, 128, 0, 255);
	}
	else if (WitchHP < 3001)
	{
		SetEntityRenderColor(Witch, 255, 255, 0, 255);
	}
	else
	{
		SetEntityRenderColor(Witch, 255, 0, 0, 255);
	}
}

public Action Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return;
	}
	if (GetConVarInt(Colored_Tanks) < 1)
	{
		return;
	}
	int Tank = GetEventInt(event, "tankid");
	int TankHP = GetClientHealth(GetClientOfUserId(GetEventInt(event, "userid")));
	if (TankHP < 8001)
	{
		SetEntityRenderColor(Tank, 0, 0, 0, 255);
	}
	else if (TankHP < 12001)
	{
		SetEntityRenderColor(Tank, 0, 0, 255, 255);
	}
	else if (TankHP < 14001)
	{
		SetEntityRenderColor(Tank, 0, 128, 255, 255);
	}
	else if (TankHP < 16001)
	{
		SetEntityRenderColor(Tank, 0, 255, 255, 255);
	}
	else if (TankHP < 18001)
	{
		SetEntityRenderColor(Tank, 0, 255, 128, 255);
	}
	else if (TankHP < 20001)
	{
		SetEntityRenderColor(Tank, 0, 255, 0, 255);
	}
	else if (TankHP < 24001)
	{
		SetEntityRenderColor(Tank, 255, 0, 255, 255);
	}
	else if (TankHP < 30001)
	{
		SetEntityRenderColor(Tank, 128, 128, 255, 255);
	}
	else if (TankHP < 40001)
	{
		SetEntityRenderColor(Tank, 255, 128, 0, 255);
	}
	else if (TankHP < 50001)
	{
		SetEntityRenderColor(Tank, 255, 0, 0, 255);
	}
	else
	{
		SetEntityRenderColor(Tank, 0, 0, 0, 255);
	}
}

public Action Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast)
{
	int target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (target)
		PrintToChat(target, "\x05Witch hates you!");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
//	NormalizeHealth();
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01round_start\x03 )");
#endif
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
		return Plugin_Continue;
	if (GetConVarInt(Remove_Spawns) < 1)
		return Plugin_Continue;
		
	RemoveAllEntityes();
	CreateTimer(1.0, TimedRemoveAllEntityes);
	CreateTimer(5.0, TimedRemoveAllEntityes);
	CreateTimer(15.0, TimedRemoveAllEntityes);
	
	return Plugin_Continue;
}

public Action Event_RoundStartPostNav(Event event, const char[] name, bool dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01round_start_post_nav\x03 )");
#endif
//	NormalizeHealth();

	if (timercount < 0)
	{
		timercount = 60;
		CreateTimer(1.0, DirectorTimer);
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01round_end\x03 )");
#endif
	timercount = -1;
	//NormalizeHealth();
}

public Action Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01map_transition\x03 )");
#endif
	timercount = -1;
	NormalizeHealth();
}

public Action Event_FinaleEscapeStart(Event event, const char[] name, bool dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01finale_escape_start\x03 )");
#endif
	timercount = -1;
}

public Action Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01finale_start\x03 )");
#endif
	timercount = -1;
}

stock int GetPlayersFromTeam(const int Team)
{
	int players_count = 0;
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == Team)
			{
				players_count++;
			}
		}
	}
	return players_count;
}