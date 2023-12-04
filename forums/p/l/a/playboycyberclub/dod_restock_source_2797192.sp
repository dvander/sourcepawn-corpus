#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name = "DoD Restock Source",
	author = "FeuerSturm, playboycyberclub",
	description = "Get fresh Ammo for the gun in your hand!",
	version = PLUGIN_VERSION,
	url = "http://www.dodsourceplugins.net"
}

#define MAXWEAPONS 24

new g_iAmmo
new String:RestockDone[] = "object/object_taken.wav"
new String:RestockDenied[] = "common/weapon_denyselect.wav"
new String:NeedAmmo[4][] = { "", "", "player/american/us_needammo2.wav", "player/german/ger_needammo2.wav" }

new String:g_Weapon[MAXWEAPONS][] =
{
	"weapon_amerknife", "weapon_spade", "weapon_colt", "weapon_p38", "weapon_m1carbine", "weapon_c96",
	"weapon_garand", "weapon_k98", "weapon_thompson", "weapon_mp40", "weapon_bar", "weapon_mp44",
	"weapon_spring", "weapon_k98_scoped", "weapon_30cal", "weapon_mg42", "weapon_bazooka", "weapon_pschreck",
	"weapon_riflegren_us", "weapon_riflegren_ger", "weapon_frag_us", "weapon_frag_ger", "weapon_smoke_us", "weapon_smoke_ger"
}
 
new g_AmmoOffs[MAXWEAPONS] =
{
	0, 0, 4, 8, 24, 12, 16, 20, 32, 32, 36, 32, 28, 20, 40, 44, 48, 48, 84, 88, 52, 56, 68, 72
}

new g_AmmoRestock[MAXWEAPONS] =
{
	0, 0, 14, 16, 30, 40, 80, 60, 180, 180,	240, 180, 50, 60, 300, 250, 4, 4, 2, 2, 2, 2, 0, 0
}

new Float:g_LastRestock[MAXPLAYERS+1]
new g_RestockCount[MAXPLAYERS+1]
new bool:g_UsedRestock[MAXPLAYERS+1]
new Handle:RestockEnabled = INVALID_HANDLE
new Handle:RestockCount = INVALID_HANDLE
new Handle:RestockDelay = INVALID_HANDLE
new Handle:RestockAmmoCheck = INVALID_HANDLE
new Handle:RestockAnnounce = INVALID_HANDLE

public OnPluginStart()
{
	CreateConVar("dod_restock_version", PLUGIN_VERSION, "DoD Restock Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_restock_version"),PLUGIN_VERSION)
	PrecacheSound(RestockDone)
	PrecacheSound(RestockDenied)
	PrecacheSound(NeedAmmo[2])
	PrecacheSound(NeedAmmo[3])
	decl String:ConVarName[256]
	decl String:ConVarValue[256]
	decl String:ConVarDescription[256]
	for(new i = 2; i < MAXWEAPONS; i++)
	{
		Format(ConVarName, sizeof(ConVarName), "dod_restock_%s",g_Weapon[i])
		IntToString(g_AmmoRestock[i], ConVarValue, sizeof(ConVarValue))
		Format(ConVarDescription, sizeof(ConVarDescription), "<#> set amount of Ammo to restock for %s", g_Weapon[i])
		CreateConVar(ConVarName, ConVarValue, ConVarDescription)
	}
	RestockEnabled = CreateConVar("dod_restock_source", "1", "<1/0> = enable/disable players being able to restock")
	RestockCount = CreateConVar("dod_restock_maxcountperlife", "3", "<#/0> = number of restocks per life a player can use  -  0=no limit")
	RestockDelay = CreateConVar("dod_restock_delaybetweenuse", "30", "<#/0> = number of seconds after restocking can be used again  -  0=no limit")
	RestockAnnounce = CreateConVar("dod_restock_announce", "1", "<1/2/0> = set announcement  -  1=only on first spawn  -  2=every spawn until it is used  -  0=no announcements")
	RestockAmmoCheck = CreateConVar("dod_restock_ammocheck", "1", "<1/0> = enable/disable disallowing to restock if player has more than half of the set restock ammo")
	RegAdminCmd("sm_restock", cmdRestock, 0)
	HookEventEx("player_death", OnPlayerDeath, EventHookMode_Post)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	AutoExecConfig(true, "dod_restock_source", "dod_restock_source")
	LoadTranslations("dod_restock_source.txt")
}

public OnMapStart()
{
	g_iAmmo = FindSendPropInfo("CDODPlayer", "m_iAmmo")
}

public OnClientPostAdminCheck(client)
{
	g_LastRestock[client] = 0.0
	g_RestockCount[client] = 0
	g_UsedRestock[client] = false
}

public OnClientDisconnect(client)
{
	g_LastRestock[client] = 0.0
	g_RestockCount[client] = 0
	g_UsedRestock[client] = false
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	g_LastRestock[client] = 0.0
	g_RestockCount[client] = 0
	return Plugin_Continue
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new announce = GetConVarInt(RestockAnnounce)
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1 && !g_UsedRestock[client] && GetConVarInt(RestockEnabled) == 1 && announce != 0)
	{
		if(announce == 1)
		{
			g_UsedRestock[client] = true
		}
		decl String:restock[32]
		Format(restock, sizeof(restock), "\x04!restock\x01")
		PrintToChat(client, "\x04[Restock] \x01%T", "AnnounceRestock", client, restock)
	}
	return Plugin_Continue
}

public Action:cmdRestock(client, args)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(GetConVarInt(RestockEnabled) == 0)
		{
			PrintToChat(client, "\x04[Restock] \x01%T", "PluginDisabled", client)
			return Plugin_Handled
		}
		else
		{
			if(!g_UsedRestock[client])
			{
				g_UsedRestock[client] = true
			}
			decl String:Weapon[32]
			GetClientWeapon(client, Weapon, sizeof(Weapon))
			new WeaponID = -1
			for(new i = 0; i < MAXWEAPONS; i++)
			{
				if(strcmp(Weapon,g_Weapon[i]) == 0)
				{
					WeaponID = i
				}
			}
			if(WeaponID != -1)
			{
				ReplaceString(Weapon, sizeof(Weapon), "weapon_", "")
				if(WeaponID == 0 || WeaponID == 1)
				{
					PrintToChat(client, "\x04[Restock] \x01%T", "NoMeleeRestock", client, Weapon)
					RestockSound(client, RestockDenied)
					return Plugin_Handled
				}
				else
				{
					decl String:RestockConVar[256]
					Format(RestockConVar, sizeof(RestockConVar), "dod_restock_weapon_%s", Weapon) 
					new AmmoRestock = GetConVarInt(FindConVar(RestockConVar))
					if(AmmoRestock == 0)
					{
						PrintToChat(client, "\x04[Restock] \x01%T", "WeaponDisabled", client, Weapon)
						RestockSound(client, RestockDenied)
						return Plugin_Handled
					}				
					new delay = GetConVarInt(RestockDelay)
					new maxrestocks = GetConVarInt(RestockCount)
					if((GetGameTime() < g_LastRestock[client] + delay) && g_RestockCount[client] != 0 && g_RestockCount[client] < maxrestocks && delay != 0)
					{
						RestockSound(client, RestockDenied)
						PrintToChat(client, "\x04[Restock] \x01%T", "RecentlyRestocked", client, RoundToCeil(g_LastRestock[client] + delay - GetGameTime()))
						return Plugin_Handled
					}
					if(g_RestockCount[client] >= maxrestocks && maxrestocks != 0)
					{
						RestockSound(client, RestockDenied)
						PrintToChat(client, "\x04[Restock] \x01%T", "RestockLimit", client,  g_RestockCount[client])
						return Plugin_Handled
					}
					new WeaponAmmo = g_iAmmo + g_AmmoOffs[WeaponID]
					if(GetConVarInt(RestockAmmoCheck) == 1)
					{
						new currammo = GetEntData(client, WeaponAmmo)
						if((StrContains(Weapon, "riflegren") != -1 && currammo > RoundToCeil(float(AmmoRestock) / 2.0)-1) || (StrContains(Weapon, "riflegren") == -1 && currammo > RoundToCeil(float(AmmoRestock) / 2.0)))
						{
							RestockSound(client, RestockDenied)
							PrintToChat(client, "\x04[Restock] \x01%T", "RestockEnoughAmmo", client, Weapon)
							return Plugin_Handled
						}
					}
					new team = GetClientTeam(client)
					EmitSoundToClient(client, NeedAmmo[team], SOUND_FROM_PLAYER,SNDCHAN_VOICE,SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
					if(StrContains(Weapon, "riflegren") != -1)
					{
						AmmoRestock--
					}
					SetEntData(client, WeaponAmmo, AmmoRestock, 4, true)
					RestockSound(client, RestockDone)
					PrintToChat(client, "\x04[Restock] \x01%T", "RestockSuccess", client, Weapon)
					g_LastRestock[client] = GetGameTime()
					g_RestockCount[client]++
					return Plugin_Handled
				}
			}
		}
	}
	else
	{
		PrintToChat(client, "\x04[Restock] \x01%T", "DeadRestock", client)
		return Plugin_Handled
	}
	return Plugin_Handled
}

stock RestockSound(client, String:sound[])
{
	EmitSoundToClient(client, sound, SOUND_FROM_PLAYER,SNDCHAN_WEAPON,SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
}