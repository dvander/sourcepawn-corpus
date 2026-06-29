 //////////////////////////////////////////////
//
// SourceMod Script
//
// DoD CloseCombat Source
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
//
//
// USAGE:
// ======
//
//
// CVARs:
// ------
//
// dod_closecombat_source <1/2/3/0>			=	set CloseCombat Weapons
//												1 = Melee only (Knife/Spade)
//												2 = Pistols only (Colt/P38)
//												3 = Melee & Pistols
//												0 = disabled
//
// dod_closecombat_sounds <1/0>				=	enable/disable using sounds for headshots,
//												melee kills and announcement
//
// dod_closecombat_announce <1/0>			=	enable/disable displaying a hint message about
//												the CloseCombat setup for spawning players
//
// dod_closecombat_pistolclips <#>			=	set amount of clips to hand out for the pistol
//
// dod_closecombat_meleebonushp <#/0>		=	set amount of health points to add for melee kills
//												0 = disable
//
// dod_closecombat_headshotbonushp <#/0>	=	set amount of health points to add for pistol headshots
//												0 = disable
//
// dod_closecombat_glowplayers <1/0>		=	enable/disable making players glow in their team's color
//
//
// dod_closecombat_fraggrenades <#/0>		=	set number of frag grenades to give to each player
//												0 to disable fraggrenades!
//
// dod_closecombat_smokegrenades <#/0>		=	set number of smoke grenades to give to each player
//												0 to disable smokegrenades!
//
//
//
// CHANGELOG:
// ==========
// 
// - 12 October 2008 - Version 1.0
//   Initial Release
//
// - 16 November 2008 - Version 1.1
//   New Features:
//   * smoke grenades and/or frag grenades can
//     be added to players closecombat equipment
//     as well!
//     (see new cvars "dod_closecombat_fraggrenades"
//      and "dod_closecombat_smokegrenades")
//   * added Multi-Language support!
//   Bugfixes:
//   * fixed players still glowing after disabling
//     the plugin
//   * fixed "Client X is not in game" errors
//
//
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

#define PLUGIN_VERSION "1.2"

#define SPEC 1
#define ALLIES 2
#define AXIS 3

public Plugin myinfo = 
{
	name = "DoD CloseCombat Source", 
	author = "FeuerSturm, update Micmacx", 
	description = "Sidearms and/or Melee Weapons only (+ grenades)!!", 
	version = PLUGIN_VERSION, 
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=micmacx&description=&search=1"
};

char CloseCombatSound[4][] =  { "", "", "player/american/us_dropweapons.wav", "player/german/ger_dropweapons.wav" }
char WpnMelee[4][] =  { "", "", "weapon_amerknife", "weapon_spade" }
char WpnPistol[4][] =  { "", "", "weapon_colt", "weapon_p38" }
char WpnFragGrenade[4][] =  { "", "", "weapon_frag_us", "weapon_frag_ger" }
char WpnSmokeGrenade[4][] =  { "", "", "weapon_smoke_us", "weapon_smoke_ger" }
int PistolOffset[4] =  { 0, 0, 4, 8 }
int PistolAmmo[4] =  { 0, 0, 7, 8 }
int FragGrenadeOffset[4] =  { 0, 0, 52, 56 }
int SmokeGrenadeOffset[4] =  { 0, 0, 68, 72 }
char Headshot[3][] =  { "player/headshot1.wav", "player/headshot2.wav", "player/headshot3.wav" }
char Melee[] =  { "misc/freeze_cam.wav" }
char Status[4][] =  { "DISABLED", "Melee Weapons ONLY!", "Pistols ONLY!", "CloseCombat Weapons ONLY!" }

int g_nomessage[MAXPLAYERS + 1]
bool IsGlowing[MAXPLAYERS + 1]

Handle CCStatus = INVALID_HANDLE
Handle CCSounds = INVALID_HANDLE
Handle CCAnnounce = INVALID_HANDLE
Handle CCFragGrenades = INVALID_HANDLE
Handle CCSmokeGrenades = INVALID_HANDLE
Handle CCPistolClips = INVALID_HANDLE
Handle CCMeleeBonus = INVALID_HANDLE
Handle CCHeadshotBonus = INVALID_HANDLE
Handle CCGlowPlayers = INVALID_HANDLE

public void OnPluginStart()
{
	CreateConVar("dod_closecombat_version", PLUGIN_VERSION, "DoD CloseCombat Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY)
	CCStatus = CreateConVar("dod_closecombat_source", "0", "<1/2/3/0> = set CloseCombat Weapons  -  1=Melee only  -  2=Pistols only  -  3=Melee & Pistols  -  0=disabled!")
	CCSounds = CreateConVar("dod_closecombat_sounds", "1", "<1/0> = enable/disable using sounds for headshots, melee kills and announcement")
	CCAnnounce = CreateConVar("dod_closecombat_announce", "1", "<1/0> = enable/disable displaying a hint message about the CloseCombat setup for spawning players")
	CCPistolClips = CreateConVar("dod_closecombat_pistolclips", "50", "<#> = set amount of clips to hand out for the pistol")
	CCMeleeBonus = CreateConVar("dod_closecombat_meleebonushp", "25", "<#/0> = set amount of health points to add for melee kills  -  0=disable")
	CCHeadshotBonus = CreateConVar("dod_closecombat_headshotbonushp", "10", "<#/0> = set amount of health points to add for pistol headshots  -  0=disable")
	CCGlowPlayers = CreateConVar("dod_closecombat_glowplayers", "1", "<1/0> = enable/disable making players glow in their team's color")
	CCFragGrenades = CreateConVar("dod_closecombat_fraggrenades", "3", "<0/#> = set number of frag grenades to give to each player  -  0 to disable fraggrenades!")
	CCSmokeGrenades = CreateConVar("dod_closecombat_smokegrenades", "2", "<0/#> = set number of smoke grenades to give to each player  -  0 to disable smokegrenades!")
	HookEvent("player_team", Surpress_TeamMSG, EventHookMode_Pre)
	HookEvent("dod_stats_weapon_attack", EventWeaponAttack, EventHookMode_Pre)
	HookEventEx("dod_stats_player_damage", EventPlayerDamage, EventHookMode_Post)
	HookEventEx("player_spawn", EventPlayerSpawn, EventHookMode_Post)
	PrecacheSound(Headshot[0])
	PrecacheSound(Headshot[1])
	PrecacheSound(Headshot[2])
	PrecacheSound(Melee)
	HookConVarChange(CCStatus, CCStatusChange)
	AutoExecConfig(true, "dod_closecombat_source", "dod_closecombat_source")
	LoadTranslations("dod_closecombat_source.txt")
}

public void OnClientPostAdminCheck(int client)
{
	g_nomessage[client] = 0
	IsGlowing[client] = false
}

public void OnClientDisconnect(int client)
{
	g_nomessage[client] = 0
	IsGlowing[client] = false
}

public Action Surpress_TeamMSG(Handle event, const char []name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (g_nomessage[client] == 1)
	{
		g_nomessage[client] = 0
		return Plugin_Handled
	}
	return Plugin_Continue
}

public void CCStatusChange(Handle convar, const char []oldValue, const char []newValue)
{
	int oldvalue = StringToInt(oldValue)
	int newvalue = StringToInt(newValue)
	if (oldvalue != newvalue)
	{
		for (int client = 1; client < MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client))
			{
				int  team = GetClientTeam(client)
				g_nomessage[client] = 1
				ChangeClientTeam(client, SPEC)
				SecretTeamSwitch(client, team)
			}
		}
		PrintToChatAll("\x04[DoD CloseCombat] \x01%T", "StatusChange", LANG_SERVER, Status[newvalue])
	}
}

stock void SecretTeamSwitch(int client, int team)
{
	g_nomessage[client] = 1
	ChangeClientTeam(client, team)
	ShowVGUIPanel(client, team == AXIS ? "class_ger" : "class_us", INVALID_HANDLE, false)
}

public Action EventPlayerDamage(Handle event, const char []name, bool dontBroadcast)
{
	int  victim = GetClientOfUserId(GetEventInt(event, "victim"))
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	int weapon = GetEventInt(event, "weapon")
	int Hitgroup = GetEventInt(event, "hitgroup")
	int attackerteam = GetClientTeam(attacker)
	int victimteam = GetClientTeam(victim)
	int status = GetConVarInt(CCStatus)
	if (status == 0 || GetClientHealth(victim) > 0 || attacker == victim || attackerteam == victimteam || attacker == 0 || victim == 0)
	{
		return Plugin_Continue
	}
	int sounds = GetConVarInt(CCSounds)
	if ((weapon == 1 || weapon == 2) && (status == 1 || status == 3))
	{
		int meleebonus = GetConVarInt(CCMeleeBonus)
		if (meleebonus > 0)
		{
			SetEntityHealth(attacker, GetClientHealth(attacker) + meleebonus)
			PrintToChat(attacker, "\x04[DoD CloseCombat] \x01%T", "MeleeKillBonus", attacker, meleebonus)
		}
		if (sounds == 1)
		{
			EmitSoundToClient(attacker, Melee, SOUND_FROM_PLAYER, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
		}
		return Plugin_Continue
	}
	if (Hitgroup == 1 && (weapon == 3 || weapon == 4) && (status == 2 || status == 3))
	{
		int headshotbonus = GetConVarInt(CCHeadshotBonus)
		if (headshotbonus > 0)
		{
			SetEntityHealth(attacker, GetClientHealth(attacker) + headshotbonus)
			PrintToChat(attacker, "\x04[DoD CloseCombat] \x01%T", "HeadshotBonus", attacker, headshotbonus)
		}
		if (sounds == 1)
		{
			EmitSoundToClient(attacker, Headshot[GetRandomInt(0, 2)], SOUND_FROM_PLAYER, SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
		}
		return Plugin_Continue
	}
	return Plugin_Continue
}

public Action EventWeaponAttack(Handle event, const char []name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "attacker"))
	int weapon = GetEventInt(event, "weapon")
	int status = GetConVarInt(CCStatus)
	int fraggrenades = GetConVarInt(CCFragGrenades)
	int smokegrenades = GetConVarInt(CCSmokeGrenades)
	if (status == 0 || weapon < 5 || (fraggrenades != 0 && (weapon >= 19 && weapon <= 22)) || (smokegrenades != 0 && (weapon == 23 || weapon == 24)))
	{
		return Plugin_Continue
	}
	CloseCombatPlayer(client)
	if (GetConVarInt(CCAnnounce) == 1)
	{
		CreateTimer(0.1, ShowMsg, client, TIMER_FLAG_NO_MAPCHANGE)
	}
	return Plugin_Continue
}

public Action EventPlayerSpawn(Handle event, const char []name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"))
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		if (IsGlowing[client])
		{
			SetEntityRenderColor(client)
			IsGlowing[client] = false
		}
		if (GetConVarInt(CCStatus) != 0)
		{
			CloseCombatPlayer(client)
			if (GetConVarInt(CCAnnounce) == 1)
			{
				CreateTimer(0.1, ShowMsg, client, TIMER_FLAG_NO_MAPCHANGE)
			}
			return Plugin_Continue
		}
	}
	return Plugin_Continue
}

public Action ShowMsg(Handle timer, any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		PrintHintText(client, "%s", Status[GetConVarInt(CCStatus)])
	}
	return Plugin_Handled
}

public Action CloseCombatPlayer(int client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		int team = GetClientTeam(client)
		if (GetConVarInt(CCGlowPlayers) == 1)
		{
			if (team == ALLIES)
			{
				SetEntityRenderColor(client, 0, 255, 0, 255)
			}
			else
			{
				SetEntityRenderColor(client, 255, 0, 0, 255)
			}
			IsGlowing[client] = true
		}
		if (GetConVarInt(CCAnnounce) == 1 && GetConVarInt(CCSounds) == 1)
		{
			EmitSoundToClient(client, CloseCombatSound[team], SOUND_FROM_PLAYER, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL)
		}
		StripWeapons(client)
		CreateTimer(0.1, GiveCloseCombat, client, TIMER_FLAG_NO_MAPCHANGE)
	}
	return Plugin_Handled
}

public Action GiveCloseCombat(Handle timer, any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1)
	{
		int ammo_offset = FindSendPropInfo("CDODPlayer", "m_iAmmo")
		int status = GetConVarInt(CCStatus)
		int fraggrenades = GetConVarInt(CCFragGrenades)
		int smokegrenades = GetConVarInt(CCSmokeGrenades)
		int team = GetClientTeam(client)
		if (fraggrenades > 0)
		{
			GivePlayerItem(client, WpnFragGrenade[team])
			SetEntData(client, ammo_offset + FragGrenadeOffset[team], fraggrenades, 4, true)
		}
		if (smokegrenades > 0)
		{
			GivePlayerItem(client, WpnSmokeGrenade[team])
			SetEntData(client, ammo_offset + SmokeGrenadeOffset[team], smokegrenades, 4, true)
		}
		if (status == 1 || status == 3)
		{
			GivePlayerItem(client, WpnMelee[team])
		}
		if (status == 2 || status == 3)
		{
			int clips = GetConVarInt(CCPistolClips) * PistolAmmo[team]
			GivePlayerItem(client, WpnPistol[team])
			SetEntData(client, ammo_offset + PistolOffset[team], clips, 4, true)
		}
	}
	return Plugin_Handled
}

public Action StripWeapons(int client)
{
	for (int i = 0; i < 4; i++)
	{
		int weapon = GetPlayerWeaponSlot(client, i)
		if (weapon != -1)
		{
			RemovePlayerItem(client, weapon)
			RemoveEdict(weapon)
		}
	}
	return Plugin_Handled
} 