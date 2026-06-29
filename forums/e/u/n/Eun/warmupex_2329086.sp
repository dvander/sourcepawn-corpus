#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "WarmupEX",
	author = "Eun",
	description = "Extended Warmup Settings for CS:GO",
	version = "1.0.0"
}

#define RESTRICTMSG_DELAY 1.0
new Handle:PluginEnabled = INVALID_HANDLE;
new Handle:GiveCT = INVALID_HANDLE;
new Handle:GiveT = INVALID_HANDLE;
new Handle:InfiniteHE = INVALID_HANDLE;
new Handle:InfiniteFlash = INVALID_HANDLE;
new Handle:InfiniteSmoke = INVALID_HANDLE;
new Handle:InfiniteDecoy = INVALID_HANDLE;
new Handle:InfiniteMolotov = INVALID_HANDLE;
new Handle:InfiniteIncendiary = INVALID_HANDLE;
new Handle:InfiniteTaser = INVALID_HANDLE;

new Handle:RestrictSound = INVALID_HANDLE;

bool g_bRestrictSound = false;
new String:g_sCachedSound[PLATFORM_MAX_PATH];
new bool:g_bSpamProtectPrint[MAXPLAYERS+1];
new String:g_GiveCT[8][32];
new String:g_GiveT[8][32];
new g_GiveCTNum = 0;
new g_GiveTNum = 0;

new iAmmoOffset;
new iClip1Offset;


public OnPluginStart()
{
	PluginEnabled = CreateConVar("sm_warmupex", "1", "Enable or disable plugin");
	GiveCT = CreateConVar("sm_warmupex_givect", "weapon_knife,item_kevlar", "Comma seperated list of items to give the Counter-Terrorists");
	GiveT = CreateConVar("sm_warmupex_givet", "weapon_knife,item_kevlar", "Comma seperated list of items to give the Terrorists");
	InfiniteHE = CreateConVar("sm_warmupex_infinite_he", "1", "Infinite high explosive grenades (0 = disabled, 1 = unlimited, 2 = unlimited and switch to nade)");
	InfiniteFlash = CreateConVar("sm_warmupex_infinite_flash", "1", "Infinite flashbangs (0 = disabled, 1 = unlimited, 2 = unlimited and switch to nade)");
	InfiniteSmoke = CreateConVar("sm_warmupex_infinite_smoke", "1", "Infinite smoke grenades (0 = disabled, 1 = unlimited, 2 = unlimited and switch to nade)");
	InfiniteDecoy = CreateConVar("sm_warmupex_infinite_decoy", "1", "Infinite decoy grenades (0 = disabled, 1 = unlimited, 2 = unlimited and switch to nade)");
	InfiniteMolotov = CreateConVar("sm_warmupex_infinite_molotov", "1", "Infinite molotov cocktails (0 = disabled, 1 = unlimited, 2 = unlimited and switch to nade)");
	InfiniteIncendiary = CreateConVar("sm_warmupex_infinite_incendiary", "1", "Infinite incendiary grenades (0 = disabled, 1 = unlimited, 2 = unlimited and switch to nade)");
	InfiniteTaser = CreateConVar("sm_warmupex_infinite_taser", "1", "Infinite Tasers (0 = disabled, 1 = unlimited, 2 = unlimited and switch to taser, 3 = unlimited insta mode)");
	RestrictSound = CreateConVar("sm_restricted_sound", "sound/buttons/weapon_cant_buy.wav", "Sound to play when a weapon is restricted (leave blank to disable)");
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("hegrenade_detonate", OnHegrenadeDetonate, EventHookMode_Post);
	HookEvent("flashbang_detonate", OnFlashbangDetonate, EventHookMode_Post);
	HookEvent("smokegrenade_detonate", OnSmokegrenadeDetonate, EventHookMode_Post);
	HookEvent("molotov_detonate", OnMolotovDetonate, EventHookMode_Post);
	HookEvent("inferno_startburn", OnInfernoStartburn, EventHookMode_Post);
	HookEvent("decoy_started", OnDecoyStarted, EventHookMode_Post);
	HookEvent("weapon_fire", OnWeaponFire, EventHookMode_Post);

	iAmmoOffset = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	iClip1Offset = FindSendPropInfo("CWeaponTaser", "m_iClip1");
}


public OnConfigsExecuted()
{
	CreateTimer(0.1, LoadRestrictSound);

	#define BUFFERLEN 1024
	new String:buffer[BUFFERLEN];
	GetConVarString(GiveCT, buffer, BUFFERLEN);
	g_GiveCTNum = ExplodeString(buffer, ",", g_GiveCT, sizeof(g_GiveCT), sizeof(g_GiveCT[]));
	GetConVarString(GiveT, buffer, BUFFERLEN);
	g_GiveTNum = ExplodeString(buffer, ",", g_GiveT, sizeof(g_GiveT), sizeof(g_GiveT[]));
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_WeaponEquip, EventItemPickup2);
}


public Action:EventItemPickup2(client, weapon)
{
	if (!isWarmup())
	{
		return Plugin_Continue;
	}
	new String:weapon_name[32];
	GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
	new team = GetClientTeam(client);
	if (team == CS_TEAM_T)
	{
		for (int i = 0; i < g_GiveTNum; ++i)
		{
			if (StrEqual(weapon_name, g_GiveT[i], false))
			{
				return Plugin_Continue;
			}
		}
	}
	else if (team == CS_TEAM_CT)
	{
		for (int i = 0; i < g_GiveCTNum; ++i)
		{
			if (StrEqual(weapon_name, g_GiveCT[i], false))
			{
				return Plugin_Continue;
			}
		}
	}
	AcceptEntityInput(weapon, "Kill");
	return Plugin_Handled;
}


public Action:LoadRestrictSound(Handle:timer)
{
	g_bRestrictSound = false;
	new String:file[PLATFORM_MAX_PATH];
	GetConVarString(RestrictSound, file, sizeof(file));
	if(strlen(file) > 0 && FileExists(file, true))
	{
		AddFileToDownloadsTable(file);
		if(StrContains(file, "sound/", false) == 0)
		{
			ReplaceStringEx(file, sizeof(file), "sound/", "", -1, -1, false);
			strcopy(g_sCachedSound, sizeof(g_sCachedSound), file);
		}
		if(PrecacheSound(g_sCachedSound, true))
		{
			g_bRestrictSound = true;
		}
		else
		{
			LogError("Failed to precache restrict sound please make sure path is correct in %s and sound is in the sounds folder", file);
		}
	}
	else if(strlen(file) > 0)
	{
		LogError("Sound %s dosnt exist", file);
	}
}

bool isWarmup()
{
	if (GetConVarBool(PluginEnabled) == true && GameRules_GetProp("m_bWarmupPeriod") == 1)
		return true;
	return false;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!isWarmup())
	{
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new team = GetClientTeam(client);
		if (team > CS_TEAM_SPECTATOR)
		{
			if ((team == CS_TEAM_T && g_GiveTNum > 0) || (team == CS_TEAM_CT && g_GiveCTNum > 0))
			{
				//Armor and kit Reset
				SetEntProp(client, Prop_Send, "m_ArmorValue", 0, 1);
				SetEntProp(client, Prop_Send, "m_bHasHelmet", 0, 1);
				SetEntProp(client, Prop_Send, "m_bHasDefuser",0, 1);
			
				
				if (team == CS_TEAM_T)
				{
					for (int i = 0; i < g_GiveTNum; ++i)
					{
						GivePlayerItem(client, g_GiveT[i]);
					}
				}
				else if (team == CS_TEAM_CT)
				{
					for (int i = 0; i < g_GiveCTNum; ++i)
					{
						GivePlayerItem(client, g_GiveCT[i]);
					}
				}
				
			}
		}
	}
	return Plugin_Continue;
}

public GivePlayerSupply(client, const String:grenade[], mode)
{
	if(client != 0 && IsClientInGame(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR && IsPlayerAlive(client))
	{
		new weapon = GivePlayerItem(client, grenade);
		if (mode == 2)
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
	}
}

public Action:GiveTaser(Handle:timer, any:client)
{
	GivePlayerSupply(client, "weapon_taser", GetConVarInt(InfiniteTaser));
}


public Action:OnHegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isWarmup())
	{
		new mode = GetConVarInt(InfiniteHE);
		if (mode > 0) {
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			{
				return Plugin_Continue;
			}
			GivePlayerSupply(client, "weapon_hegrenade", mode);
		}
	}
	return Plugin_Continue;
}


public Action:OnFlashbangDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isWarmup())
	{
		new mode = GetConVarInt(InfiniteFlash);
		if (mode > 0) {
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			{
				return Plugin_Continue;
			}
			GivePlayerSupply(client, "weapon_flashbang", mode);
		}
	}
	return Plugin_Continue;
}

public Action:OnSmokegrenadeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isWarmup())
	{
		new mode = GetConVarInt(InfiniteSmoke);
		if (mode > 0) {
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			{
				return Plugin_Continue;
			}
			GivePlayerSupply(client, "weapon_smokegrenade", mode);
		}
	}
	return Plugin_Continue;
}

public Action:OnMolotovDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isWarmup())
	{
		new mode = GetConVarInt(InfiniteMolotov);
		if (mode > 0) {
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			{
				return Plugin_Continue;
			}
			GivePlayerSupply(client, "weapon_molotov", mode);
		}
	}
	return Plugin_Continue;
}

public Action:OnInfernoStartburn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isWarmup())
	{
		new mode = GetConVarInt(InfiniteIncendiary);
		if (mode > 0) {
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			{
				return Plugin_Continue;
			}
			GivePlayerSupply(client, "weapon_incgrenade", mode);
		}
	}
	return Plugin_Continue;
}

public Action:OnDecoyStarted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (isWarmup())
	{
		new mode = GetConVarInt(InfiniteDecoy);
		if (mode > 0) {
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			{
				return Plugin_Continue;
			}
			GivePlayerSupply(client, "weapon_decoy", mode);
		}
	}
	return Plugin_Continue;
}

public Action:OnWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (isWarmup())
	{
		new mode = GetConVarInt(InfiniteTaser);
		if (mode > 0)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));

			if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= CS_TEAM_SPECTATOR)
			{
				return Plugin_Continue;
			}

			new String: weapon[64];
			GetEventString(event, "weapon", weapon, sizeof(weapon));
			if(StrEqual("taser", weapon))
			{
				if (mode == 3)
				{
					new iWeapon;
					iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
					if (IsValidEdict(iWeapon))
					{
						if (iAmmoOffset)
							SetEntData(iWeapon, iClip1Offset, 2, _, true);
					}
				}
				else
				{
					CreateTimer(1.0, GiveTaser, client);
				}
			}
		}
	}
	return Plugin_Continue;
}



public Action:CS_OnBuyCommand(client, const String:weapon[])
{
	if (isWarmup())
	{
		if (g_bSpamProtectPrint[client] == false)
		{
			g_bSpamProtectPrint[client] = true;
			PrintToChat(client, "\x0FYou are not allowed to buy during warmup!");
			if (g_bRestrictSound)
			{
				EmitSoundToClient(client, g_sCachedSound);
			}
			CreateTimer(RESTRICTMSG_DELAY, ResetPrintDelay, client);
		}		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}




public Action:ResetPrintDelay(Handle:timer, any:client)
{
	g_bSpamProtectPrint[client] = false;
}

public Action:CS_OnCSWeaponDrop(client, weapon)
{
	if (isWarmup())
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}