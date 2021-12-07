#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#define VERSION "1.1.8.b"

static const String:g_sPistolsSon[6][] = {
	"weapon_glock",
	"weapon_usp",
	"weapon_deagle",
	"weapon_fiveseven",
	"weapon_elite",
	"weapon_p228"
};

static const String:g_sGunsSon[17][] = {
	"weapon_m3",
	"weapon_xm1014",
	"weapon_tmp",
	"weapon_mac10",
	"weapon_mp5",
	"weapon_ump45",
	"weapon_p90",
	"weapon_famas",
	"weapon_galil",
	"weapon_m4a1",
	"weapon_ak47",
	"weapon_aug",
	"weapon_sg552",
	"weapon_scout",
	"weapon_awp",
	"weapon_sg550",
	"weapon_g3sg1",
};

public Plugin:myinfo =
{
	name = "Warmup Round MOD",
	author = "XARiUS | [PRince4]",
	description = "Modified version of WarmUp Plugin that gives random weapon on spawn.",
	version = "1.1.8.b",
	url = "http://www.the-otc.com/"
};

new String:language[4];
new String:languagecode[4];
new String:g_preexec[32];
new String:g_postexec[32];
new bool:IsWarmup;
new bool:g_enabled;
new bool:g_respawn;
//new g_respawntime;
new bool:g_friendlyfire;
new g_time;
new timesrepeated;
new g_iWPOff;
new bool:g_bWarming;

new Handle:g_Cvarenabled = INVALID_HANDLE;
new Handle:g_Cvartime = INVALID_HANDLE;
new Handle:g_Cvarrespawn = INVALID_HANDLE;
//new Handle:g_Cvarrespawntime = INVALID_HANDLE;
new Handle:g_Cvarfriendlyfire = INVALID_HANDLE;
new Handle:g_Cvarpreexec = INVALID_HANDLE;
new Handle:g_Cvarpostexec = INVALID_HANDLE;
new Handle:g_Cvaractive = INVALID_HANDLE;
new Handle:g_warmuptimer = INVALID_HANDLE;

new g_iMyWeapons;

public OnPluginStart()
{
  LoadTranslations("warmup.phrases");
  CreateConVar("sm_warmupround_version", VERSION, "Warmup Round Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Cvaractive = CreateConVar("sm_warmupround_active", "0", "DO NOT MODIFY THIS VALUE DIRECTLY - USED FOR STATS TRACKING", FCVAR_DONTRECORD);
  g_Cvarenabled = CreateConVar("sm_warmupround_enabled", "1", "Enable this plugin. 0 = Disabled");
  g_Cvartime = CreateConVar("sm_warmupround_time", "30", "Time in seconds for the warmup to last.  Minimum 15.", _, true, 15.0, true, 120.0);
  g_Cvarrespawn = CreateConVar("sm_warmupround_respawn", "1", "Respawn players during warmup. 0 = Disabled");
//g_Cvarrespawntime = CreateConVar("sm_warmupround_respawn_time", "1.5", "Time to wait in seconds to respawn a player after he/she dies. 1.5 = Default.");
  g_Cvarfriendlyfire = CreateConVar("sm_warmupround_friendlyfire", "0", "Disable friendly fire during warmup. (Use this if you keep friendly fire ON normally) 0 = Disabled");
  g_Cvarpreexec = CreateConVar("sm_warmupround_preexec", "", "Config file to execute prior to warmup round starting.  File goes in /cfg/sourcemod/ directory.  (Example: 'warmup_pre.cfg' | Leave blank for none)");
  g_Cvarpostexec = CreateConVar("sm_warmupround_postexec", "", "Config file to execute after warmup round has ended.  File goes in /cfg/sourcemod/ directory.  (Example: 'warmup_post.cfg' | Leave blank for none)");
  GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));

  HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
  HookEvent("round_start", EventRoundStart, EventHookMode_Post);
  
  HookConVarChange(g_Cvarenabled, OnSettingChanged);
  HookConVarChange(g_Cvartime, OnSettingChanged);
//HookConvarChange(g_Cvarrespawntime, OnSettingChanged);
  HookConVarChange(g_Cvarrespawn, OnSettingChanged);
  HookConVarChange(g_Cvarfriendlyfire, OnSettingChanged);
  HookConVarChange(g_Cvarpreexec, OnSettingChanged);
  HookConVarChange(g_Cvarpostexec, OnSettingChanged);

  g_enabled = GetConVarBool(g_Cvarenabled);
  g_respawn = GetConVarBool(g_Cvarrespawn);
//g_respawntime = GetConVarInt(g_Cvarrespawntime);
  g_friendlyfire = GetConVarBool(g_Cvarfriendlyfire);
  g_time = GetConVarInt(g_Cvartime);
  GetConVarString(g_Cvarpreexec, g_preexec, sizeof(g_preexec));
  GetConVarString(g_Cvarpostexec, g_postexec, sizeof(g_postexec));

  timesrepeated = g_time;
  IsWarmup = false;
  SetupOffsets();
  
  AddCommandListener(CmdJoinClass, "joinclass");
  
  AutoExecConfig(true, "warmup");
}

SetupOffsets()
{
  g_iMyWeapons = FindSendPropInfo("CBaseCombatCharacter", "m_hMyWeapons");
  if (g_iMyWeapons == -1)
  {
    SetFailState("[Warmup] Error - Unable to get offset for CBaseCombatCharacter::m_hMyWeapons");
  }
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
  if (convar == g_Cvarenabled)
  {
    if (newValue[0] == '1')
    {
			g_enabled = true;
    }
    else
    {
      g_enabled = false;
    }
  }
  if (convar == g_Cvarrespawn)
  {
    if (newValue[0] == '1')
    {
			g_respawn = true;
    }
    else
    {
      g_respawn = false;
    }
  }
  if (convar == g_Cvarfriendlyfire)
  {
    if (newValue[0] == '1')
    {
			g_friendlyfire = true;
    }
    else
    {
      g_friendlyfire = false;
    }
  }

  if (convar == g_Cvartime)
  {
    g_time = StringToInt(newValue);
  }
  if (convar == g_Cvarpreexec)
  {
    strcopy(g_preexec, sizeof(g_preexec), newValue);
  }
  if (convar == g_Cvarpostexec)
  {
    strcopy(g_postexec, sizeof(g_postexec), newValue);
  }

}

public OnAutoConfigsBuffered()
{
  if (g_warmuptimer != INVALID_HANDLE)
  {
    KillTimer(g_warmuptimer);
  }
  if (g_enabled)
	{
    SetConVarBool(g_Cvaractive, true, false, false);
    timesrepeated = g_time;
    IsWarmup = true;
    ServerCommand("exec %s", g_preexec);
    if (g_friendlyfire)
    {
      ServerCommand("mp_friendlyfire 0");
    }
    g_warmuptimer = CreateTimer(1.0, Countdown, _, TIMER_REPEAT);
	}
	new maxent = GetMaxEntities(), String:ent[64];
	for (new i = MaxClients; i < maxent; i++) 
	{
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, ent, sizeof(ent))) 
		{
			if (StrContains(ent, "func_bomb_target") != -1 ||
			StrContains(ent, "func_hostage_rescue") != -1 ||
			StrContains(ent, "func_buyzone") != -1)
			AcceptEntityInput(i,"Disable");
		}
	}
}

public Action:CancelWarmup()
{
  SetConVarBool(g_Cvaractive, false, false, false);
  g_warmuptimer = INVALID_HANDLE;
  IsWarmup = false;
  new maxent = GetMaxEntities(), String:ent[64];
  for (new i = MaxClients; i < maxent; i++)
		if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, ent, sizeof(ent)) && ((StrContains(ent, "func_bomb_target") != -1 ||
		StrContains(ent, "func_hostage_rescue") != -1 ||
		StrContains(ent, "func_buyzone") != -1)))
		AcceptEntityInput(i, "Enable");
    ServerCommand("exec %s", g_postexec);
  if (g_friendlyfire)
  {
    ServerCommand("mp_friendlyfire 1");
  }
    ServerCommand("mp_restartgame 1");
}  

WeaponHandler(client)
{
  if (IsWarmup && client != 0)
  {
    static Slot = 0, EntityIndex = 0;
    decl String:WeaponClass[64] = "";
    for (Slot = 0; Slot <= (32 * 4); Slot += 4)
    {
      EntityIndex = GetEntDataEnt2(client, (g_iMyWeapons + Slot));
      if (EntityIndex != 0 && IsValidEdict(EntityIndex))
      {
        GetEdictClassname(EntityIndex, WeaponClass, sizeof(WeaponClass));
        if (StrEqual(WeaponClass, "worldspawn", false))
        {
          return;
        }
        RemovePlayerItem(client, EntityIndex);
        RemoveEdict(EntityIndex);
      }
    }
	GivePlayerItem(client, g_sGunsSon[GetURandomIntRange(0, sizeof(g_sGunsSon) - 1)]);
	GivePlayerItem(client, g_sPistolsSon[GetURandomIntRange(0, sizeof(g_sPistolsSon) - 1)]);
	GivePlayerItem(client, "item_assaultsuit");
	GivePlayerItem(client, "weapon_hegrenade");
	GivePlayerItem(client, "weapon_smokegrenade");
	GivePlayerItem(client, "weapon_knife");
    Slot = 0;
    EntityIndex = 0;
  }
}

public Action:Countdown(Handle:timer)
{
  if (IsWarmup)
  {
    if (timesrepeated >= 1)
    {
      PrintHintTextToAll("%t: %i", "warmup time", timesrepeated);
      timesrepeated--;
    }
    else if (timesrepeated == 0)
    {
      timesrepeated = g_time;
      CancelWarmup();
      return Plugin_Stop;
    }
  }
  else
  {
    timesrepeated = g_time;
    return Plugin_Stop;
  }
  return Plugin_Continue;
}

public Action:DelayWeapon(Handle:timer, any:client)
{
  WeaponHandler(client);
}

public EventRoundStart(Handle:event,const String:name[],bool:dontBroadcast) {

	if (g_bWarming) {
		new maxent = GetMaxEntities(), String:ent[64];
		for (new i = MaxClients; i < maxent; i++)
			if (IsValidEdict(i) && IsValidEntity(i) && GetEdictClassname(i, ent, sizeof(ent)))
				if (StrContains(ent, "weapon_") != -1 && GetEntDataEnt2(i, g_iWPOff) == -1)
					RemoveEdict(i);
	}
}

public Action:SpawnPlayer(Handle:timer, any:client)
{
  if (IsClientInGame(client))
  {
    CS_RespawnPlayer(client);
	WeaponHandler(client);
  }
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
  if (g_enabled && IsWarmup && g_respawn)
  {
    new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(1.5, SpawnPlayer, clientid);
  }
}  

stock GetURandomIntRange(min, max) {

	return (GetURandomInt() % (max-min+1)) + min;
}

public Action:SpawnLateJoiningPlayer(Handle:timer, any:client) {

	if (IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1)
		CS_RespawnPlayer(client);
}

public Action:CmdJoinClass(client, const String:command[], argc) {

	if (g_bWarming)
		CreateTimer(2.0, SpawnLateJoiningPlayer, client);
}