#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

#define PLUGIN_VERSION "1.3"

#define MAXENTITIES 2048

public Plugin myinfo = 
{
	name = "DoD DropTNT Source", 
	author = "BenSib, Micmacx", 
	description = "Players drop tnt on death / by command!", 
	version = PLUGIN_VERSION, 
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=micmacx&description=&search=1"
}

Handle TnTDropTimer[MAXENTITIES + 1];

char g_TnT_Model[PLATFORM_MAX_PATH];
char g_TnT_Sound[PLATFORM_MAX_PATH];

Handle tntdeaddrop = INVALID_HANDLE;
Handle tntdropcmd = INVALID_HANDLE;
Handle tntliefetime = INVALID_HANDLE;
Handle tntcooldown = INVALID_HANDLE;
Handle tntnotify = INVALID_HANDLE;
bool tnt_candrop[MAXPLAYERS];

public void OnPluginStart()
{
	CreateConVar("dod_droptnt_version", PLUGIN_VERSION, "DoD DropTnT Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	SetConVarString(FindConVar("dod_droptnt_version"), PLUGIN_VERSION);
	
	tntdeaddrop = CreateConVar("dod_droptnt_deaddrop", "1", "<1/0> = enable/disable dropping a tnt on players' death (default: 1)", _, true, 0.0, true, 1.0);
	tntdropcmd = CreateConVar("dod_droptnt_alivedrop", "1", "<1/0> = enable/disable allowing alive players to drop their tnt (default: 1)", _, true, 0.0, true, 1.0);
	tntnotify = CreateConVar("dod_droptnt_notify", "1", "<1/0> = enable/disable drop/pickup message to player (default: 1)", _, true, 0.0, true, 1.0);
	tntliefetime = CreateConVar("dod_droptnt_lifetime", "60", "<#> = number of seconds a dropped tnt stays on the map (default: 60)", _, true, 5.0, true, 60.0);
	tntcooldown = CreateConVar("dod_droptnt_cooldown", "10", "<#> = number of seconds between two dropcommands (default: 10)", _, true, 5.0, true, 60.0);
	
	RegConsoleCmd("dropammo", cmdDropTnT);
	HookEvent("player_hurt", OnPlayerDeath, EventHookMode_Pre);
	AutoExecConfig(true, "dod_droptnt_source", "dod_droptnt_source");
}

public void OnMapStart()
{
	Format(g_TnT_Sound, sizeof(g_TnT_Sound), "weapons/c4_pickup.wav");
	Format(g_TnT_Model, sizeof(g_TnT_Model), "models/weapons/w_tnt.mdl");
}

public void OnClientPutInServer(int client)
{
	tnt_candrop[client] = true;
}

public Action cmdDropTnT(int client, int args)
{
	if (!IsPlayerAlive(client) || !IsClientInGame(client) || GetConVarInt(tntdropcmd) == 0 || !tnt_candrop[client])
	{
		return Plugin_Continue;
	}
	
	int wpn = GetPlayerWeaponSlot(client, 4);
	if (wpn != -1)
	{
		float origin[3];
		GetClientAbsOrigin(client, origin);
		origin[2] += 55.0;
		float angles[3];
		GetClientEyeAngles(client, angles);
		float velocity[3];
		GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 350.0);
		int tnt = CreateEntityByName("prop_physics_override");
		SetEntityModel(tnt, g_TnT_Model);
		DispatchSpawn(tnt);
		TeleportEntity(tnt, origin, angles, velocity);
		SDKHook(tnt, SDKHook_Touch, OnTnTTouched);
		tnt_candrop[client] = false;
		CreateTimer(GetConVarFloat(tntcooldown), EnableDrop, client, TIMER_FLAG_NO_MAPCHANGE);
		TnTDropTimer[tnt] = CreateTimer(GetConVarFloat(tntliefetime), RemoveDroppedTnT, tnt, TIMER_FLAG_NO_MAPCHANGE);
		RemoveWeapon(client, wpn);
		if (GetConVarInt(tntnotify) == 1)
		{
			PrintHintText(client, "You dropped TNT");
		}
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

void RemoveWeapon(int client, int wpn) {
	RemovePlayerItem(client, wpn);
	AcceptEntityInput(wpn, "Kill");
	//RemoveEdict(wpn);
}

public Action RemoveDroppedTnT(Handle timer, int tnt)
{
	TnTDropTimer[tnt] = INVALID_HANDLE;
	SDKUnhook(tnt, SDKHook_Touch, OnTnTTouched);
	if (IsValidEdict(tnt))
	{
		char iModel[PLATFORM_MAX_PATH];
		Format(iModel, PLATFORM_MAX_PATH, "");
		GetEntPropString(tnt, Prop_Data, "m_ModelName", iModel, PLATFORM_MAX_PATH);
		if (StrEqual(iModel, g_TnT_Model))
		{
			AcceptEntityInput(tnt, "Kill");
		}
	}
	return Plugin_Handled;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientHealth(client) > 0 || !IsClientInGame(client) || GetConVarInt(tntdeaddrop) == 0)
	{
		return Plugin_Continue;
	}
	int wpn = GetPlayerWeaponSlot(client, 4);
	if (wpn != -1)
	{
		float deathorigin[3];
		GetClientAbsOrigin(client, deathorigin);
		deathorigin[2] += 5.0;
		int tnt = CreateEntityByName("prop_physics_override");
		SetEntityModel(tnt, g_TnT_Model);
		DispatchSpawn(tnt);
		TeleportEntity(tnt, deathorigin, NULL_VECTOR, NULL_VECTOR);
		SDKHook(tnt, SDKHook_Touch, OnTnTTouched);
		TnTDropTimer[tnt] = CreateTimer(GetConVarFloat(tntliefetime), RemoveDroppedTnT, tnt, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action OnTnTTouched(int tnt, int client)
{
	if (client > 0 && client <= MaxClients && tnt > 0 && IsValidEntity(client) && IsClientInGame(client) && IsPlayerAlive(client) && IsValidEdict(tnt))
	{
		int wpn = GetPlayerWeaponSlot(client, 4);
		if (wpn == -1)
		{
			if (GetConVarInt(tntnotify) == 1)
			{
				PrintHintText(client, "You picked up TNT");
			}
			GivePlayerItem(client, "weapon_basebomb");
			KillTnTTimer(tnt);
			PlayPickUpSound(client);
			SDKUnhook(tnt, SDKHook_Touch, OnTnTTouched);
			char iModel[PLATFORM_MAX_PATH];
			Format(iModel, PLATFORM_MAX_PATH, "");
			GetEntPropString(tnt, Prop_Data, "m_ModelName", iModel, PLATFORM_MAX_PATH);
			if (StrEqual(iModel, g_TnT_Model))
			{
				//RemoveEdict(tnt);
				AcceptEntityInput(tnt, "Kill");
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action EnableDrop(Handle timer, int client)
{
	tnt_candrop[client] = true;
}

void KillTnTTimer(int tnt)
{
	if (TnTDropTimer[tnt] != INVALID_HANDLE)
	{
		CloseHandle(TnTDropTimer[tnt]);
	}
	TnTDropTimer[tnt] = INVALID_HANDLE;
}

void PlayPickUpSound(int client)
{
	EmitSoundToClient(client, g_TnT_Sound, SOUND_FROM_PLAYER, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
}
