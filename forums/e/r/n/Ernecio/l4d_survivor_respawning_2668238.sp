#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define L4D2 Survivor Respawn
#define PLUGIN_VERSION "1.26"

bool isRespawn = false, isBot = false, isIncapped = false, isHanging = false, isRespected = false, isRescuable[MAXPLAYERS + 1] = false;
static bool g_bL4DVersion, g_bL4D2Version;

static Handle hRoundRespawn = INVALID_HANDLE, hGameConf = INVALID_HANDLE;

Handle cvarEnable, cvarEnableBot, cvarRespawnHanging, cvarRespawnIncapped, cvarRespawnRespect, cvarRespawnLimit, cvarRespawnTimeout, 
		cvarRespawnHP, cvarRespawnBuffHP, RespawnTimer[MAXPLAYERS + 1] = INVALID_HANDLE, cvarIncapDelay, cvarHangingDelay, 
		HangingTimer[MAXPLAYERS + 1] = INVALID_HANDLE, IncapTimer[MAXPLAYERS + 1] = INVALID_HANDLE, PluginStartTimer = INVALID_HANDLE,
		FirstWeapon, SecondWeapon, ThrownWeapon, PrimeHealth, SecondaryHealth;

int RespawnLimit[MAXPLAYERS + 1] = 0;
int BufferHP = -1;

public Plugin myinfo = 
{
	name 		= "[L4D1 AND L4D2] Survivor Respawning",
	author 		= "Mortiegama, Edited by Ernecio",
	description = "When a Survivor dies, is hanging. or is incapped, will respawn after a period of time.",
	version 	= PLUGIN_VERSION,
	url 		= "<URL>"

	//Special Thanks:
	//AtomicStryker - SM_Respawn & Infected Ghost Everywhere
	//This plugin contains scripts from SM Respawn and uses the gamedata file
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in the \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
		return APLRes_SilentFailure;
	}
	
	g_bL4D2Version = (engine == Engine_Left4Dead2);
	g_bL4DVersion = (engine == Engine_Left4Dead);
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_survivorrespawn_version", PLUGIN_VERSION, "Survivor Respawning Version", FCVAR_NOTIFY|FCVAR_REPLICATED);

	cvarEnable 				= CreateConVar("l4d_survivorrespawn_enable", 			"1", 		"Enables Survivors to respawn automatically when incapped and/or killed (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarEnableBot 			= CreateConVar("l4d_survivorrespawn_enablebot", 		"1",		"Allows Bots to respawn automatically when incapped and/or killed (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRespawnHanging 		= CreateConVar("l4d_survivorrespawn_hanging", 			"0", 		"Survivors will be killed when hanging and respawn afterwards (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRespawnIncapped 	= CreateConVar("l4d_survivorrespawn_incapped", 			"1", 		"Survivors will be killed when incapped and respawn afterwards (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRespawnRespect 		= CreateConVar("l4d_survivorrespawn_limitenable", 		"1", 		"Enables the respawn limit for Survivors (Def 1)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvarRespawnLimit 		= CreateConVar("l4d_survivorrespawn_deathlimit", 		"2", 		"Amount of times a Survivor can respawn before permanently dying (Def 2)", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarRespawnTimeout 		= CreateConVar("l4d_survivorrespawn_respawntimeout", 	"10", 		"How many seconds till the Survivor respawns (Def 10)", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarIncapDelay 			= CreateConVar("l4d_survivorrespawn_incapdelay", 		"25", 		"How many seconds till the Survivor is killed after being incapacitated (Def 25)", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarHangingDelay 		= CreateConVar("l4d_survivorrespawn_hangingdelay", 		"25",		"How many seconds till the Survivor is killed while hanging (Def 25)", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarRespawnHP 			= CreateConVar("sm_survivorrespawn_respawnhp", 			"70",		"Amount of HP a Survivor will respawn with (Def 70)", FCVAR_NOTIFY, true, 0.0, false, _);
	cvarRespawnBuffHP 		= CreateConVar("sm_survivorrespawn_respawnbuffhp", 		"30", 		"Amount of buffer HP a Survivor will respawn with (Def 30)", FCVAR_NOTIFY, true, 0.0, false, _);	
	
	if (g_bL4DVersion)
	{
		FirstWeapon 			= CreateConVar("l4d_survivorrespawn_firstweapon", 		"1", 		"Which primary weapon will be given to the Survivor (1 - Autoshotgun, 2 - M16, 3 - Hunting Rifle, 4 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
		SecondWeapon 			= CreateConVar("l4d_survivorrespawn_secondweapon", 		"1", 		"Which second slot weapon will be given to the Survivor (1 - Dual Pistol, 2 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
		ThrownWeapon 			= CreateConVar("l4d_survivorrespawn_thrownweapon", 		"3", 		"Which throwable will be given to the Survivor (1 - Molotov, 2 - Pipe Bomb, 3 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
		PrimeHealth 			= CreateConVar("l4d_survivorrespawn_primehealth", 		"1",	 	"Which carriable health unit will be given to the Survivor (1 - Medkit, 2 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
		SecondaryHealth 		= CreateConVar("l4d_survivorrespawn_secondaryhealth", 	"1", 		"Which medical supply will be given to the Survivor (1 - Pills, 2 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
	}
	
	if (g_bL4D2Version)
    {
		FirstWeapon 			= CreateConVar("l4d_survivorrespawn_firstweapon", 		"1", 		"Which first slot weapon will be given to the Survivor (1 - Autoshotgun, 2 - M16, 3 - Hunting Rifle, 4 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
		SecondWeapon 			= CreateConVar("l4d_survivorrespawn_secondweapon", 		"1", 		"Which second slot weapon will be given to the Survivor (1 - Bat, 2 - Dual Pistol, 3 - Magnum)", FCVAR_NOTIFY, true, 0.0, false, _);
		ThrownWeapon 			= CreateConVar("l4d_survivorrespawn_thrownweapon", 		"4", 		"Which thrown weapon will be given to the Survivor (1 - Moltov, 2 - Bile Jar, 3 - Pipe Bomb, 4 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
		PrimeHealth 			= CreateConVar("l4d_survivorrespawn_primehealth", 		"3", 		"Which prime health unit will be given to the Survivor (1 - Medkit, 2 - Defib, 3 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
		SecondaryHealth 		= CreateConVar("l4d_survivorrespawn_secondaryhealth", 	"1", 		"Which secondary health unit will be given to the Survivor (1 - Pills, 2 - Adrenaline, 3 - None)", FCVAR_NOTIFY, true, 0.0, false, _);
	}

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("player_incapacitated", Event_PlayerIncapped);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	LoadTranslations("common.phrases");
	
	hGameConf = LoadGameConfigFile("l4d_survivor_respawning");
	
	AutoExecConfig(true, "l4d_survivor_respawn");
	
	BufferHP = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
	PluginStartTimer = CreateTimer(3.0, OnPluginStart_Delayed);

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	if (hRoundRespawn == INVALID_HANDLE) SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
}

public Action OnPluginStart_Delayed(Handle timer)
{
	if (GetConVarInt(cvarEnable))
	{
		isRespawn = true;
	}

	if (GetConVarInt(cvarEnableBot))
	{
		isBot = true;
	}

	if (GetConVarInt(cvarRespawnHanging))
	{
		isHanging = true;
	}

	if (GetConVarInt(cvarRespawnIncapped))
	{
		isIncapped = true;
	}

	if (GetConVarInt(cvarRespawnRespect))
	{
		isRespected = true;
	}
	
	if(PluginStartTimer != INVALID_HANDLE)
	{
 		KillTimer(PluginStartTimer);
		PluginStartTimer = INVALID_HANDLE;
	}	
	
	return Plugin_Stop;
}

public void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    for (int client=1; client<=MaxClients; client++)
	{
		RespawnLimit[client] = 0;
		
		if (RespawnTimer[client] != INVALID_HANDLE)
		{
			KillTimer(RespawnTimer[client]);
			RespawnTimer[client] = INVALID_HANDLE;
		}
	}
}

public void Event_PlayerLedgeGrab(Handle event, const char[] ame, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (isRespawn && isHanging && IsValidClient(client))
	{
		HangingTimer[client] = CreateTimer(GetConVarFloat(cvarHangingDelay), Timer_HangingRespawn, client); 
		isRescuable[client] = true;
	}
}

public Action Timer_HangingRespawn(Handle timer, any client)
{
	int limit = GetConVarInt(cvarRespawnLimit);

	if (IsValidClient(client) && isRescuable[client] && IsPlayerHanging(client))
	{
		if (RespawnLimit[client] < limit)
		{
			ForcePlayerSuicide(client);
			isRescuable[client] = false;
		}
		else if (RespawnLimit[client] >= limit)
		{
			PrintHintText(client, "You have reached your respawn limit and will be unable to revive on your own.");
			isRescuable[client] = false;
		}
	}
	
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		isRescuable[client] = false;
	}
	
	if (HangingTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HangingTimer[client]);
		HangingTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public void Event_PlayerIncapped(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (isRespawn && isIncapped && IsValidClient(client))
	{
		IncapTimer[client] = CreateTimer(GetConVarFloat(cvarIncapDelay), Timer_IncapRespawn, client); 
		isRescuable[client] = true;
	}
}
		
public Action Timer_IncapRespawn(Handle timer, any client)
{
	int limit = GetConVarInt(cvarRespawnLimit);
	
	if (IsValidClient(client) && isRescuable[client] && IsPlayerIncapped(client))
	{
		if (RespawnLimit[client] < limit)
		{
			ForcePlayerSuicide(client);
		}
		else if (RespawnLimit[client] >= limit)
		{
			PrintHintText(client, "You have reached your respawn limit and will be unable to revive on your own.");
		}
	}

	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		isRescuable[client] = false;
	}
	
	if (IncapTimer[client] != INVALID_HANDLE)
	{
		KillTimer(IncapTimer[client]);
		IncapTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

public void Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	int limit = GetConVarInt(cvarRespawnLimit);
	int time = GetConVarInt(cvarRespawnTimeout);

	if (isRespawn && !isRespected && IsValidClient(client))
	{
		RespawnTimer[client] = CreateTimer(GetConVarFloat(cvarRespawnTimeout), Timer_Respawn, client); 
		PrintHintText(client, "You will automatically respawn in %i seconds.", time);
		isRescuable[client] = false;
	}

	if (isRespawn && isRespected && IsValidClient(client))
	{
		if (RespawnLimit[client] < limit)
		{
			RespawnLimit[client] += 1;
			RespawnTimer[client] = CreateTimer(GetConVarFloat(cvarRespawnTimeout), Timer_Respawn, client); 
			PrintHintText(client, "You will automatically respawn in %i seconds.", time);
			isRescuable[client] = false;
		}
		else if (RespawnLimit[client] >= limit)
		{
			PrintHintText(client, "You have reached your respawn limit and will be unable to revive.");
			isRescuable[client] = false;
		}
	}
}

public void Event_ReviveSuccess(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"victim"));

	isRescuable[client] = false;
}

public Action Timer_Respawn(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		SDKCall(hRoundRespawn, client);
		
		SetHealth(client);
		GiveItems(client);
		Teleport(client);

		char playername[64];
		GetClientName(client, playername, sizeof(playername));
		PrintToChatAll("Player \x05%s \x01has been respawned.", playername);
	}
	
	if (RespawnTimer[client] != INVALID_HANDLE)
	{
		KillTimer(RespawnTimer[client]);
		RespawnTimer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Stop;
}

void SetHealth(int client)
{
	float sBuff = GetEntDataFloat(client, BufferHP);
	int sBonusHP = GetConVarInt(cvarRespawnHP);
	int sBuffHP = GetConVarInt(cvarRespawnBuffHP);

	SetEntProp(client, Prop_Send, "m_iHealth", sBonusHP, 1);
	SetEntDataFloat(client, BufferHP, sBuff + sBuffHP, true);
}

void GiveItems(int client)
{
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);

	if (g_bL4DVersion)
	{
		switch (GetConVarInt(FirstWeapon))
		{
			case 1: { FakeClientCommand(client, "give autoshotgun"); }
			case 2: { FakeClientCommand(client, "give rifle"); }
			case 3: { FakeClientCommand(client, "give hunting_rifle"); }
		}
		switch (GetConVarInt(SecondWeapon))
		{
			case 1: { FakeClientCommand(client, "give pistol"); FakeClientCommand(client, "give pistol"); }
		}
		switch (GetConVarInt(ThrownWeapon))
		{
			case 1: { FakeClientCommand(client, "give molotov"); }
			case 2: { FakeClientCommand(client, "give pipe_bomb"); }
		}
		switch (GetConVarInt(PrimeHealth))
		{
			case 1: { FakeClientCommand(client, "give first_aid_kit"); }
		}
		switch (GetConVarInt(SecondaryHealth))
		{
			case 1: { FakeClientCommand(client, "give pain_pills"); }
		}
		SetCommandFlags("give", flags|FCVAR_CHEAT);
	}
		
	if (g_bL4D2Version)
    {
		switch (GetConVarInt(FirstWeapon))
		{
			case 1: { FakeClientCommand(client, "give autoshotgun"); }
			case 2: { FakeClientCommand(client, "give rifle"); }
			case 3: { FakeClientCommand(client, "give hunting_rifle"); }
		}
		switch (GetConVarInt(SecondWeapon))
		{
			case 1: { FakeClientCommand(client, "give baseball_bat"); }
			case 2: { FakeClientCommand(client, "give pistol"); FakeClientCommand(client, "give pistol"); }
			case 3: { FakeClientCommand(client, "give pistol_magnum"); }
		}
		switch (GetConVarInt(ThrownWeapon))
		{
			case 1: { FakeClientCommand(client, "give molotov"); }
			case 2: { FakeClientCommand(client, "give vomitjar"); }
			case 3: { FakeClientCommand(client, "give pipe_bomb"); }
		}
		switch (GetConVarInt(PrimeHealth))
		{
			case 1: { FakeClientCommand(client, "give first_aid_kit"); }
			case 2: { FakeClientCommand(client, "give defibrillator"); }
		}
		switch (GetConVarInt(SecondaryHealth))
		{
			case 1: { FakeClientCommand(client, "give pain_pills"); }
			case 2: { FakeClientCommand(client, "give adrenaline"); }
		}
		SetCommandFlags("give", flags|FCVAR_CHEAT);
	}
}

void Teleport(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && i != client)
		{
			// get the position coordinates of any active living player
			float coordinates[3];
			GetClientAbsOrigin(i, coordinates);
			TeleportEntity(client, coordinates, NULL_VECTOR, NULL_VECTOR);
			break;
		}
	}
}

public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    for (int client=1; client<=MaxClients; client++)
	{
		RespawnLimit[client] = 0;
		isRescuable[client] = false;
	}
}

public int IsValidClient(int client)
{
	if (client == 0)
		return false;

	if (!IsClientInGame(client))
		return false;
		
	if (GetClientTeam(client) != 2)
		return false;

	if (IsFakeClient(client) && !isBot)
		return false;
	
	return true;
}

public int IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) 
		return true;
		
	return false;
}

public int IsPlayerHanging(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1)) 
		return true;
		
	return false;
}