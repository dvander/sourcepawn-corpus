#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"
#define DEVELOPER_INFO false

new Handle:Is_Plugin_Enabled;
new Handle:Normalize_Health;
new Handle:Medkit_Full_Health;
new Handle:Precache_Guns;
new Handle:Precache_Characters;
new Handle:IsMapFinished;
new Handle:z_max_player_zombies;

public Plugin:myinfo = 
{
	name = "[L4D2] Assistant Director",
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("l4d2_ad_version", PLUGIN_VERSION, "Assistant Director Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Is_Plugin_Enabled = CreateConVar("l4d2_ad", "1", "Enable L4D Assistant Director plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Normalize_Health = CreateConVar("l4d2_ad_normalize_health", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Medkit_Full_Health = CreateConVar("l4d2_ad_fullhealth", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Precache_Guns = CreateConVar("l4d2_ad_precache_guns", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	Precache_Characters = CreateConVar("l4d2_ad_precache_chr", "1", "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	IsMapFinished = CreateConVar("l4d2_mapfinished", "0", "", FCVAR_PLUGIN);
	
	HookConVarChange(IsMapFinished, IsMapFinishedChanged);
	
	z_max_player_zombies = FindConVar("z_max_player_zombies");
	SetConVarBounds(z_max_player_zombies, ConVarBound_Upper, true, 5.0);
	
	HookEvent("heal_success", Event_MedkitUsed);
//	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_start_pre_entity", Event_RoundStartPreEntity);
	HookEvent("round_start_post_nav", Event_RoundStartPostNav);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("map_transition", Event_MapTransition);
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("finale_escape_start", Event_FinaleEscapeStart);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("player_entered_checkpoint", Event_CheckPoint);
	HookEvent("create_panic_event", Event_Panic);
	HookEvent("finale_radio_start", Event_C3M4_Radio2);
	RegAdminCmd("sm_hp", Command_HP, ADMFLAG_RCON, "");
	RegAdminCmd("sm_give", CMD_Give, ADMFLAG_CHEATS, "");
	RegAdminCmd("sm_spawn", CMD_Spawn, ADMFLAG_CHEATS, "");
	RegAdminCmd("sm_use", CMD_Use, ADMFLAG_CHEATS, "");
	RegAdminCmd("sm_team", Command_Team, ADMFLAG_RCON, "");

//	RegConsoleCmd("sm_join", Command_Join);
//	RegConsoleCmd("sm_ts", CMD_TS);	
	CreateTimer(5.0, ExecServerConfig);
}

public PrecacheSurvModels()
{
	if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))
		PrecacheModel("models/survivors/survivor_teenangst.mdl");
	if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))
		PrecacheModel("models/survivors/survivor_biker.mdl");
	if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))
		PrecacheModel("models/survivors/survivor_manager.mdl");
	if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))
		PrecacheModel("models/survivors/survivor_namvet.mdl");
	if (!IsModelPrecached("models/infected/witch.mdl"))
		PrecacheModel("models/infected/witch.mdl");
}

public OnMapStart()
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return;
	}
	if (GetConVarInt(Precache_Characters) < 1)
	{
		return;
	}
	PrecacheSurvModels();  // from http://forums.alliedmods.net/showpost.php?p=1158878&postcount=530
}

public IsMapFinishedChanged(Handle:hVariable, const String:strOldValue[], const String:strNewValue[])
{
	new Handle:l4d2_loot_g_chance_nodrop = FindConVar("l4d2_loot_g_chance_nodrop");
	new Handle:monsterbots_interval = FindConVar("monsterbots_interval");
	if (GetConVarInt(IsMapFinished) > 0) 
	{
		SetConVarInt(l4d2_loot_g_chance_nodrop, 77, false, false);
		SetConVarInt(monsterbots_interval, 5, false, false);
	}
	else
	{
		SetConVarInt(l4d2_loot_g_chance_nodrop, 15, false, false);
		SetConVarInt(monsterbots_interval, 11, false, false);
	}
}

public CheckPointReached(any:client)
{
	SetConVarInt(IsMapFinished, 1, false, false);
}

public Action:Event_C3M4_Radio2(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "userid");
	{
		if (client < 1)
		{
			return;
		}
		if (client > 32)
		{
			return;
		}
	}
	PrintToChatAll("\x04%N has caused a boat", client);
}

public Action:Event_Panic(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "userid");
	{
		if (client < 1)
		{
			return;
		}
		if (client > 32)
		{
			return;
		}
	}
	PrintToChatAll("\x04%N started panic event", client);
}

public Action:Event_CheckPoint(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(IsMapFinished) > 0)
	{
		return Plugin_Continue;
	}
	
	new Target = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:strBuffer[128];
	GetEventString(event, "doorname", strBuffer, sizeof(strBuffer));
	
	if (Target && (GetClientTeam(Target)) == 2)
	{
		if (StrEqual(strBuffer, "checkpoint_entrance", false))
		{
			CheckPointReached(Target);
		}
		else
		{
			new String:current_map[64];
			GetCurrentMap(current_map, 63);
			if (StrEqual(current_map, "c2m1_highway", false))
			{
				if (GetEventInt(event, "area") == 89583)
					CheckPointReached(Target);
			}
			else if (StrEqual(current_map, "c4m4_milltown_b", false))
			{
				if (GetEventInt(event, "area") == 502575)
					CheckPointReached(Target);
			}
			else if (StrEqual(current_map, "c5m1_waterfront", false))
			{
				if (GetEventInt(event, "area") == 54867)
					CheckPointReached(Target);
			}
			else if (StrEqual(current_map, "c5m2_park", false))
			{
				if (GetEventInt(event, "area") == 196623)
					CheckPointReached(Target);
			}
		}
	}
	return Plugin_Continue;
}

SetPlayerArmor(entity, amount, bool:maxArmor=false, bool:ResetMax=false)
{
	if (maxArmor)
	{
		if (ResetMax)
		{
			SetEntData(entity, 4228, 250, 4, true);
		}
		else
		{
			SetEntData(entity, 4228, amount, 4, true);
		}
	}
}

stock GetGameMode()
{
	new String:GameMode[13];
	new Handle:gamecvar_mp_gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamecvar_mp_gamemode, GameMode, sizeof(GameMode));
	if (StrEqual(GameMode, "coop", false) == true)
	{
		return 1;
	}
	else if (StrEqual(GameMode, "realism", false) == true)
	{
		return 2;
	}
	else if (StrEqual(GameMode, "survival", false) == true)
	{
		return 3;
	}
	else if (StrEqual(GameMode, "versus", false) == true)
	{
		return 4;
	}
	else if (StrEqual(GameMode, "teamversus", false) == true)
	{
		return 5;
	}
	else if (StrEqual(GameMode, "scavenge", false) == true)
	{
		return 6;
	}
	else if (StrEqual(GameMode, "teamscavenge", false) == true)
	{
		return 7;
	}
	else if (StrEqual(GameMode, "mutation3", false) == true)
	{
		return 8;
	}
	else if (StrEqual(GameMode, "mutation12", false) == true)
	{
		return 9;
	}
	else if (StrEqual(GameMode, "mutation9", false) == true)
	{
		return 10;
	}
	return 0;
}

stock AlivePlayers()
{
#if DEVELOPER_INFO		
	PrintToChatAll("\x04[DEVINFO]: \x03Function ( \x01NormalizeHealth\x03 )");
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

public Action:CMD_Give(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_give <args>");
		return Plugin_Handled;
	}

	decl String:argstring[255];
	new flags = GetCommandFlags("give");

	GetCmdArgString(argstring, sizeof(argstring));
	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", argstring);
	SetCommandFlags("give", flags);
		
	return Plugin_Handled;
}

public Action:CMD_Spawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spawn <args>");
		return Plugin_Handled;
	}

	decl String:argstring[255];
	new flags = GetCommandFlags("z_spawn");

	GetCmdArgString(argstring, sizeof(argstring));
	
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	if (GetClientTeam(client) == 3)
	{
		FakeClientCommand(client, "z_spawn %s", argstring);
	}
	else
	{
		FakeClientCommand(client, "z_spawn %s auto", argstring);
	}
	SetCommandFlags("z_spawn", flags);
		
	return Plugin_Handled;
}

public Action:Command_Join(client, args)
{
	if (client)
	{
		ChangeClientTeam(client, 2);
	}
}

public Action:Command_Team(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_team <args>");
		return Plugin_Handled;
	}

	decl String:argstring[255];
	GetCmdArgString(argstring, sizeof(argstring));
	
	ChangeClientTeam(client, StringToInt(argstring));
	return Plugin_Handled;
}

public Action:CMD_TS(client, args)
{
	decl String:MOTD[192];
	MOTD = "ts3server://217.76.183.79:9987";
	ShowMOTDPanel(client, "Team Speak 3", MOTD, MOTDPANEL_TYPE_URL);
}

public Action:CMD_Use(client, args)
{
	decl entity;
	entity = GetClientAimTarget(client, false);
	if (entity < 0)
	{
		return;
	}
	ActivateEntity(entity);
}

//Used to set temp health, written by TheDanner.
SetTempHealth(client, hp)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime())
	new Float:newOverheal = hp * 1.0; // prevent tag mismatch
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal)
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
	PrintToChatAll("\x04[DEVINFO]: \x03Function ( \x01NormalizeHealth\x03 )");
#endif	
	new map_full_health = 0;
	new String:current_map[36];
	GetCurrentMap(current_map, 35);
	
	if (StrEqual(current_map, "c1m3_mall", false) || StrEqual(current_map, "c4m2_sugarmill_a", false))
	{
		map_full_health = 1;
	}
	
	new HP;
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
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
				
				if (GetGameMode() != 8)
					{
					if (map_full_health > 0)
					{
						SetEntityHealth(i, 100);
					}
					else
					{
						if (HP < 51)
						{
							FakeClientCommand(i, "give health");
							SetEntityHealth(i, HP + 50);
						}
						else if (HP > 100)
						{
							FakeClientCommand(i, "give health");
							SetEntityHealth(i, 50);
						}
						else
						{
							FakeClientCommand(i, "give health");
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
	SetCommandFlags("give", flags);
}

public Action:ExecServerConfig(Handle:timer, any:client)
{
	ServerCommand("exec server_postload.cfg");
}

public Action:Command_HP(client, args)
{
	NormalizeHealth();
}

public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return;
	}
	new client = GetEventInt(event, "userid");
	{
		if (client > 32)
		{
			return;
		}
	}
	if (!IsClientConnected(client))
	{
		return;
	}
	if (!IsClientInGame(client))
	{
		return;
	}
	if (GetClientTeam(client) == 3)
	{
		SetPlayerArmor(client, 100, true, true);
	}
}

public Action:Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Tank = GetEventInt(event, "tankid");
	new TankHP = GetClientHealth(GetClientOfUserId(GetEventInt(event, "userid")))
	if (TankHP < 10000)
	{
		SetEntityRenderColor(Tank, 0, 0, 0, 255);
	}
	else if (TankHP < 20000)
	{
		SetEntityRenderColor(Tank, 0, 0, 127, 255);
	}
	else if (TankHP < 30000)
	{
		SetEntityRenderColor(Tank, 0, 0, 255, 255);
	}
	else if (TankHP < 40000)
	{
		SetEntityRenderColor(Tank, 0, 127, 255, 255);
	}
	else if (TankHP < 45000)
	{
		SetEntityRenderColor(Tank, 0, 255, 255, 255);
	}
	else if (TankHP < 50000)
	{
		SetEntityRenderColor(Tank, 0, 255, 127, 255);
	}
	else if (TankHP < 55000)
	{
		SetEntityRenderColor(Tank, 0, 255, 0, 255);
	}
	else if (TankHP < 60000)
	{
		SetEntityRenderColor(Tank, 127, 255, 0, 255);
	}
	else if (TankHP < 62000)
	{
		SetEntityRenderColor(Tank, 255, 255, 0, 255);
	}
	else if (TankHP < 64000)
	{
		SetEntityRenderColor(Tank, 255, 127, 0, 255);
	}
	else if (TankHP < 66000)
	{
		SetEntityRenderColor(Tank, 255, 0, 0, 255);
	}
	else if (TankHP < 70000)
	{
		SetEntityRenderColor(Tank, 30, 30, 30, 255);
	}
	else
	{
		SetEntityRenderColor(Tank, 0, 0, 0, 255);
	}
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

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	NormalizeHealth();
	SetConVarInt(IsMapFinished, 0, false, false);
}

public Action:Event_RoundStartPreEntity(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Is_Plugin_Enabled) < 1)
	{
		return;
	}
	if (GetConVarInt(Precache_Guns) < 1)
	{
		return;
	}
	if (!IsModelPrecached("models/w_models/weapons/w_smg_mp5.mdl")) 
		PrecacheModel("models/w_models/weapons/w_smg_mp5.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_rifle_sg552.mdl")) 
		PrecacheModel("models/w_models/weapons/w_rifle_sg552.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_scout.mdl"))
		PrecacheModel("models/w_models/weapons/w_sniper_scout.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl"))
		PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl");
	if (!IsModelPrecached("models/v_models/v_smg_mp5.mdl"))
		PrecacheModel("models/v_models/v_smg_mp5.mdl");
	if (!IsModelPrecached("models/v_models/v_rif_sg552.mdl"))
		PrecacheModel("models/v_models/v_rif_sg552.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_scout.mdl"))
		PrecacheModel("models/v_models/v_snip_scout.mdl");
	if (!IsModelPrecached("models/v_models/v_snip_awp.mdl"))
		PrecacheModel("models/v_models/v_snip_awp.mdl");
	if (!IsModelPrecached("models/w_models/weapons/w_m60.mdl"))
		PrecacheModel("models/w_models/weapons/w_m60.mdl");
	if (!IsModelPrecached("models/weapons/melee/w_golfclub.mdl"))
		PrecacheModel("models/weapons/melee/w_golfclub.mdl");
}

public Action:Event_RoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetConVarInt(IsMapFinished, 0, false, false);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	NormalizeHealth();
}

public Action:Event_MapTransition(Handle:event, const String:name[], bool:dontBroadcast)
{
	NormalizeHealth();
}

public Action:Event_FinaleEscapeStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "userid");
	{
		if (client < 1)
		{
			return;
		}
		if (client > 32)
		{
			return;
		}
	}
	PrintToChatAll("\x04%N started finale escape event", client);
}

public Action:Event_FinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
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