#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <smlib>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

new WarmUpWeapon;

new Handle:gGH_Restart = INVALID_HANDLE,
	Handle:gGH_AllTalk = INVALID_HANDLE,
	Handle:gGH_FreezeTime = INVALID_HANDLE;

new bool:gB_Restart,
	bool:gB_WarmUp,
	bool:gB_AllTalk,
	bool:gB_StartMoney,
	bool:gB_FreezeTime,
	bool:gB_WarmUpActive = false;

new Handle:gH_Restart = INVALID_HANDLE,
	Handle:gH_AllTalk = INVALID_HANDLE,
	Handle:gH_WarmUp = INVALID_HANDLE,
	Handle:gH_StartMoney = INVALID_HANDLE,
	Handle:gH_FreezeTime = INVALID_HANDLE;

new MoneyOffset = -1,
	Ammo = -1;

public Plugin:myinfo = 
{
	name = "Aim_Texture Maps Plugin",
	author = "TimeBomb",
	description = "An useful plugin for aim_texture maps!",
	version = PLUGIN_VERSION
}

public OnMapStart()
{
	Texture();
	
	gB_WarmUpActive = false;
	
	if(gB_WarmUp)
	{
		CreateTimer(1.0, Warmup);
		CreateTimer(30.0, Warmup_Disable);
		
		WarmUpWeapon = Math_GetRandomInt(1, 5);
	}
	
	if(gB_Restart)
	{
		SetConVarInt(gGH_Restart, 60);
		CreateTimer(60.0, Restart);
	}
}

public Action:Restart(Handle:Timer)
{
	PrintHintTextToAll("Game has been restarted!");
}

public Action:Warmup_Disable(Handle:Timer)
{
	SetConVarInt(gGH_Restart, 1);
	gB_WarmUpActive = false;
	PrintHintTextToAll("Game has been restarted!");
}

public Action:Warmup(Handle:Timer)
{
	gB_WarmUpActive = true;
}

public OnPluginStart()
{
	new Handle:Version = CreateConVar("sm_texture_version", PLUGIN_VERSION, "Plugin's version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(Version, PLUGIN_VERSION, _, true);
	
	gGH_Restart = FindConVar("mp_restartgame");
	gGH_AllTalk = FindConVar("sv_alltalk");
	gGH_FreezeTime = FindConVar("mp_freezetime");
	
	gH_Restart = CreateConVar("sm_texture_restart", "1", "After a map change, restart the game after 1 minute?", FCVAR_PLUGIN, true, _, true, 1.0);
	gB_Restart = true;
	HookConVarChange(gH_Restart, OnConVarChanged);
	
	gH_AllTalk = CreateConVar("sm_texture_alltalk", "1", "AllTalk is enabled?", FCVAR_PLUGIN, true, _, true, 1.0);
	gB_AllTalk = true;
	HookConVarChange(gH_AllTalk, OnConVarChanged);
	
	gH_StartMoney = CreateConVar("sm_texture_startmoney", "1", "Set players cash to 16000 in any new round?", FCVAR_PLUGIN, true, _, true, 1.0);
	gB_StartMoney = true;
	HookConVarChange(gH_StartMoney, OnConVarChanged);
	
	gH_WarmUp = CreateConVar("sm_texture_warmup", "1", "Make a warmup round with a random weapon every new map? (30 seconds warmup)", FCVAR_PLUGIN, true, _, true, 1.0);
	gB_WarmUp = true;
	HookConVarChange(gH_WarmUp, OnConVarChanged);
	
	gH_FreezeTime = CreateConVar("sm_texture_freezetime", "1", "Set the freezetime to 5?", FCVAR_PLUGIN, true, _, true, 1.0);
	gB_FreezeTime = true;
	HookConVarChange(gH_FreezeTime, OnConVarChanged);
	
	HookEvent("round_start", Round_Start);
	HookEvent("player_spawn", Player_Spawn);
	HookEvent("player_death", Player_Death);
	
	MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");  
	Ammo = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	
	if(MoneyOffset == -1)
	{
		SetConVarInt(gH_StartMoney, 0);
		gB_StartMoney = false;
		
		LogError("Cash offset didn't found! Startmoney disabled.");
	}
	
	if(Ammo == -1)
	{
		LogError("Ammo offset didn't found! Hegrenades in warmup should bug.");
	}
	
	AutoExecConfig();
}

public OnConVarChanged(Handle:cvar, String:oldVal[], String:newVal[])
{
	if(cvar == gH_Restart)
	{
		gB_Restart = StringToInt(newVal)? true:false;
	}
	
	else if(cvar == gH_AllTalk)
	{
		gB_AllTalk = StringToInt(newVal)? true:false;
		
		SetConVarInt(gGH_AllTalk, gB_AllTalk? 1:0);
	}
	
	else if(cvar == gH_StartMoney)
	{
		gB_StartMoney = StringToInt(newVal)? true:false;
	}
	
	else if(cvar == gH_WarmUp)
	{
		gB_WarmUp = StringToInt(newVal)? true:false;
	}
	
	else if(cvar == gH_FreezeTime)
	{
		gB_FreezeTime = StringToInt(newVal)? true:false;
		
		SetConVarInt(gGH_FreezeTime, gB_FreezeTime? 5:0);
	}
}

public Action:Player_Death(Handle:event, String:name[], bool:dB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	if(gB_WarmUp && gB_WarmUpActive)
	{
		CreateTimer(3.0, Respawn, client);
		PrintHintText(client, "Respawn in 3 seconds");
	}
	
	return Plugin_Continue;
}

public Action:Respawn(Handle:Timer, any:client)
{
	CS_RespawnPlayer(client);
}

public Action:Player_Spawn(Handle:event, String:name[], bool:dB)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	if(gB_StartMoney)
	{
		SetEntData(client, MoneyOffset, 16000, 4, true);
	}
	
	if(gB_WarmUp && gB_WarmUpActive)
	{
		GiveWarmUpWeapon(client);
	}
	
	Client_SetArmor(client, 250);
	SetEntityHealth(client, 250);
	
	return Plugin_Continue;
}

public Action:Round_Start(Handle:event, String:name[], bool:dB)
{
	SetConVarInt(gGH_AllTalk, gB_AllTalk? 1:0);
	SetConVarInt(gGH_FreezeTime, gB_FreezeTime? 5:0);
	
	PrintToChatAll("\x04[SM_AIM_TEXUTRE]\x01 New round has been started!");
	
	return Plugin_Continue;
}

stock Texture()
{
	decl String:map[32];
	GetCurrentMap(map, 32);
	
	if(StrContains(map, "aim_ag_texture", false) == -1)
	{
		SetFailState("Map isn't a \"Aim_Texture\" map, plugin's shutting down.");
	}
}

stock GiveWarmUpWeapon(client)
{
	new weapon;
	
	switch(WarmUpWeapon)
	{
		case 1: weapon = GivePlayerItem(client, "weapon_m4a1");
		case 2: weapon = GivePlayerItem(client, "weapon_deagle");
		case 3: weapon = GivePlayerItem(client, "weapon_awp");
		case 4: weapon = GivePlayerItem(client, "weapon_knife");
		case 5:
		{
			weapon = GivePlayerItem(client, "weapon_hegrenade");
			SetEntData(client, Ammo + (_:12 * 4), 0, 4, true);
		}
	}
	
	if(weapon != 5 && Ammo != -1)
	{
		Weapon_SetPrimaryClip(weapon, 30);
		Weapon_SetSecondaryClip(weapon, 99999);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(gB_WarmUpActive && WarmUpWeapon == 5 && StrEqual(classname, "hegrenade_projectile"))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
	}
}

public OnEntitySpawned(entity)
{
	CreateTimer(0.8, SpawnNew, entity);
}

public Action:SpawnNew(Handle:Timer, any:entity)
{
	new client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	GivePlayerItem(client, "weapon_hegrenade");
}

stock bool:IsValidClient(client)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	
	return false;
}