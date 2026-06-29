#define SDKHOOKS false
#include <sourcemod>
#include <sdktools>
#if SDKHOOKS
#include <sdkhooks>
#endif
#define PLUGIN_VERSION "1.0 alpha"
#define DEVELOPER_INFO false


new timercount = -3;

new Handle:Is_Plugin_Enabled;
new Handle:Normalize_Health;
new Handle:Medkit_Full_Health;
new Handle:Remove_Spawns;
new Handle:Colored_Tanks;
#if SDKHOOKS
new Handle:HuntingRifleMod;
#endif

public Plugin:myinfo = 
{
	name = "[L4D] Assistant Director",
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("l4d_ad_ver", PLUGIN_VERSION, "Assistant Director Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Is_Plugin_Enabled = CreateConVar("l4d_ad", "1", "Enable L4D Assistant Director plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Normalize_Health = CreateConVar("l4d_ad_normalize_health", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Medkit_Full_Health = CreateConVar("l4d_ad_fullhealth", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Remove_Spawns = CreateConVar("l4d_ad_removespawns", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Colored_Tanks = CreateConVar("l4d_ad_coloredtanks", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
#if SDKHOOKS	
	HuntingRifleMod = CreateConVar("l4d_ad_huntingrifle_mod", "0", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
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

public OnMapStart()
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
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return Plugin_Continue;
	}
	if (GetConVarInt(HuntingRifleMod) < 1)
	{
		return Plugin_Continue;
	}

	decl String:sWeapon[32];
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

stock AlivePlayers()
{
#if DEVELOPER_INFO		
	PrintToChatAll("\x04[DEVINFO]: \x03Function ( \x01AlivePlayers()\x03 )");
#endif	
	new alive_players = 0;
	for (new i = 1; i < MaxClients; i++)
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
stock GetSpecials(const String:SpecialInfected[])
{
	new j = 0;
	decl String:ClientName[20];
	if (StrEqual(SpecialInfected, "Hunter", false))
	{
		for (new i = 1; i < MaxClients; i++)
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
		for (new i = 1; i < MaxClients; i++)
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
		for (new i = 1; i < MaxClients; i++)
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
		for (new i = 1; i < MaxClients; i++)
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

/* public Action:CheckTanks(Handle:timer, any:client)
{
	if (GetSpecials("Tank") > 1)
	{
		decl String:ClientSteamID[12];
		decl String:ClientName[20];
		new i;
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
} */

/* public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new target = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!client)
		return Plugin_Continue;

	if (client == target)
		return Plugin_Continue;
		
	if (GetEventInt(event, "dmg_health") < 1)
		return Plugin_Continue;

	decl String:ClientSteamID[32];
	decl String:TargetSteamID[32];

	GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
	GetClientAuthString(target, TargetSteamID, sizeof(TargetSteamID));

	if (StrEqual(ClientSteamID, "BOT", false) || StrEqual(TargetSteamID, "BOT", false))
		return Plugin_Continue;

	new Float:X;

	X = (1 + (Multiplier[client] / 10));

	Damage[client] = Damage[client] + GetEventInt(event, "dmg_health");

	PrintToChat(client, "\x01%N attacked %N", client, target);
	PrintToChat(client, "\x03%d (%d - voteban; 2750 - permanent) TK points!", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + 600);
	PrintToChat(target, "\x01%N attacked %N", client, target);
	PrintToChat(target, "\x03%d (%d - voteban; 2750 - permanent) TK points!", RoundToZero(X * Damage[client]), RoundToZero(Punishment[client]) + 600);
	CheckPunishmentPoints(client);

	return Plugin_Continue;
} */

public SpawnSpecial(const String:SpecialInfected[])
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				new flags = GetCommandFlags("z_spawn");
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

public SpawnRandomSpecial(const SpawnCount)
{
	if (SpawnCount < 1)
	{
		return;
	}
	
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				new flags = GetCommandFlags("z_spawn");
				SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
				
				for (new j = 1; j < MaxClients; j++)
				{
					CreateTimer(GetRandomFloat(1.0, 3.0), SpawnTimer, GetRandomInt(1, 3));
				}
				
				SetCommandFlags("z_spawn", flags);
	
				return;
			}
		}
	}
}

public Action:SpawnTimer(Handle:timer, const any:client)
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
SetTempHealth(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime())
	new Float:newOverheal = hp * 1.0; // prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal)
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}

public RemoveAllEntityByName(const String:EntityName[64])
{
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, EntityName)) != -1)
	{
		RemoveEdict(entity);
	}
}

public Action:TimedRemoveAllEntityes(Handle:timer, any:client)
{
	RemoveAllEntityes();
}

public RemoveAllEntityes()
{
	new entity = -1;

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
//	while ((entity = FindEntityByClassname2(entity, "weapon_ammo_spawn")) != -1)
//	{
//		if (IsValidEdict(entity))
//			RemoveEdict(entity);	
//	}
}

public NormalizeHealth()
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
	new map_full_health = 0;
	new String:current_map[36];
	GetCurrentMap(current_map, 35);
	
	if (StrEqual(current_map, "l4d_garage01_alleys", false))
	{
		map_full_health = 1;
	}
	
	new HP;
	for (new i = 1; i < MaxClients; i++)
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

public Action:DirectorTimer(Handle:timer, any:client)
{
	return;
	new PlayersA = AlivePlayers();
	new PlayersB = PlayersA - 10;
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

public Action:Command_StartTimer(client, args)
{
	timercount = 0;
	CreateTimer(1.0, DirectorTimer);
}

public Action:Command_StopTimer(client, args)
{
	timercount = -2;
}

public Action:Command_HP(client, args)
{
	NormalizeHealth();
}

public Action:Event_MedkitUsed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return Plugin_Continue;
	}
	if (GetConVarInt(Medkit_Full_Health) < 1)
	{
		return Plugin_Continue;
	}
//	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new target = GetClientOfUserId(GetEventInt(event, "subject"));

	SetEntityHealth(target, 100);
	SetEntProp(target, Prop_Send, "m_isGoingToDie", 0);
	SetEntProp(target, Prop_Send, "m_currentReviveCount", 0);
	SetEntPropFloat(target, Prop_Send, "m_healthBuffer", 0.0); 
	SetEntPropFloat(target, Prop_Send, "m_healthBufferTime", 0.0);
	SetTempHealth(target, 0);
	
	return Plugin_Continue;
}

public Action:Event_WitchSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Witch = GetEventInt(event, "witchid");
	new WitchHP = GetConVarInt(FindConVar("z_witch_health"));
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

public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return;
	}
	if (GetConVarInt(Colored_Tanks) < 1)
	{
		return;
	}
	new Tank = GetEventInt(event, "tankid");
	new TankHP = GetClientHealth(GetClientOfUserId(GetEventInt(event, "userid")))
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

public Action:Event_WitchHarasserSet(Handle:event, const String:name[], bool:dontBroadcast)
{
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	if (target)
		PrintToChat(target, "\x05Witch hates you!");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
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

public Action:Event_RoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast)
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

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01round_end\x03 )");
#endif
	timercount = -1;
	//NormalizeHealth();
}

public Action:Event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01map_transition\x03 )");
#endif
	timercount = -1;
	NormalizeHealth();
}

public Action:Event_FinaleEscapeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01finale_escape_start\x03 )");
#endif
	timercount = -1;
}

public Action:Event_FinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
#if DEVELOPER_INFO	
	PrintToChatAll("\x04[DEVINFO]: \x03Event ( \x01finale_start\x03 )");
#endif
	timercount = -1;
}

stock GetPlayersFromTeam(const Team)
{
	new players_count = 0;
	for (new i = 1; i < MaxClients; i++)
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