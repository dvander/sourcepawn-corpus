#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#define VERSION "1.1.8"

public Plugin:myinfo =
{
	name = "Warmup Round",
	author = "XARiUS",
	description = "Simple warmup round plugin.",
	version = "1.1.8",
	url = "http://www.the-otc.com/"
};

new String:language[4];
new String:languagecode[4];
new String:g_weapon[32];
new String:g_preexec[32];
new String:g_postexec[32];
new bool:IsWarmup;
new bool:g_enabled;
new bool:g_respawn;
new bool:g_friendlyfire;
new g_time;
new timesrepeated;

new Handle:g_Cvarenabled = INVALID_HANDLE;
new Handle:g_Cvartime = INVALID_HANDLE;
new Handle:g_Cvarweapon = INVALID_HANDLE;
new Handle:g_Cvarrespawn = INVALID_HANDLE;
new Handle:g_Cvarfriendlyfire = INVALID_HANDLE;
new Handle:g_Cvarpreexec = INVALID_HANDLE;
new Handle:g_Cvarpostexec = INVALID_HANDLE;
new Handle:g_Cvaractive = INVALID_HANDLE;
new Handle:g_warmuptimer = INVALID_HANDLE;

new g_iMyWeapons;

public OnPluginStart()
{
  LoadTranslations("warmup.phrases");
  CreateConVar("sm_warmupround_version", VERSION, "Warmup Round Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Cvaractive = CreateConVar("sm_warmupround_active", "0", "DO NOT MODIFY THIS VALUE DIRECTLY - USED FOR STATS TRACKING", FCVAR_DONTRECORD);
  g_Cvarenabled = CreateConVar("sm_warmupround_enabled", "1", "Enable this plugin. 0 = Disabled");
  g_Cvartime = CreateConVar("sm_warmupround_time", "30", "Time in seconds for the warmup to last.  Minimum 15.", _, true, 15.0, true, 120.0);
  g_Cvarweapon = CreateConVar("sm_warmupround_weapon", "hegrenade", "Weapon to give players during warmup.  HEGrenades are unlimted.  Examples: knife,deagle,fiveseven,elite,p228..");
  g_Cvarrespawn = CreateConVar("sm_warmupround_respawn", "1", "Respawn players during warmup. 0 = Disabled");
  g_Cvarfriendlyfire = CreateConVar("sm_warmupround_friendlyfire", "0", "Disable friendly fire during warmup. (Use this if you keep friendly fire ON normally) 0 = Disabled");
  g_Cvarpreexec = CreateConVar("sm_warmupround_preexec", "", "Config file to execute prior to warmup round starting.  File goes in /cfg/ directory.  (Example: 'prewarmup.cfg' | Leave blank for none)");
  g_Cvarpostexec = CreateConVar("sm_warmupround_postexec", "", "Config file to execute after warmup round has ended.  File goes in /cfg/ directory.  (Example: 'postwarmup.cfg' | Leave blank for none)");
  GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));

  HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
  HookEvent("item_pickup", EventItemPickup, EventHookMode_Post);
  HookEvent("weapon_fire", EventWeaponFire, EventHookMode_Post);
  
  HookConVarChange(g_Cvarenabled, OnSettingChanged);
  HookConVarChange(g_Cvartime, OnSettingChanged);
  HookConVarChange(g_Cvarweapon, OnSettingChanged);
  HookConVarChange(g_Cvarrespawn, OnSettingChanged);
  HookConVarChange(g_Cvarfriendlyfire, OnSettingChanged);
  HookConVarChange(g_Cvarpreexec, OnSettingChanged);
  HookConVarChange(g_Cvarpostexec, OnSettingChanged);

  g_enabled = GetConVarBool(g_Cvarenabled);
  g_respawn = GetConVarBool(g_Cvarrespawn);
  g_friendlyfire = GetConVarBool(g_Cvarfriendlyfire);
  g_time = GetConVarInt(g_Cvartime);
  GetConVarString(g_Cvarpreexec, g_preexec, sizeof(g_preexec));
  GetConVarString(g_Cvarpostexec, g_postexec, sizeof(g_postexec));
  GetConVarString(g_Cvarweapon, g_weapon, sizeof(g_weapon));
  timesrepeated = g_time;
  IsWarmup = false;
  SetupOffsets();
  
  AutoExecConfig(true, "warmup");
}

SetupOffsets()
{
  g_iMyWeapons = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
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
  if (convar == g_Cvarweapon)
  {
    CheckWeaponString(newValue);
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
    new String:buffer[32] = "cfg/";
    StrCat(buffer, sizeof(buffer), g_preexec);
    if (FileExists(buffer))
    {
      ServerCommand("exec %s", g_preexec);
    }
    if (g_friendlyfire)
    {
      ServerCommand("mp_friendlyfire 0");
    }
    g_warmuptimer = CreateTimer(1.0, Countdown, _, TIMER_REPEAT);
	}
}

public CheckWeaponString(const String:weapon[])
{
  new String:weapons[26][32];
  new bool:valid = false;
  
  weapons[0] = "glock";
  weapons[1] = "usp";
  weapons[2] = "p228";
  weapons[3] = "deagle";
  weapons[4] = "elite";
  weapons[5] = "fiveseven";
  weapons[6] = "m3";
  weapons[7] = "xm1014";
  weapons[8] = "mac10";
  weapons[9] = "tmp";
  weapons[10] = "mp5navy";
  weapons[11] = "ump45";
  weapons[12] = "p90";
  weapons[13] = "galil";
  weapons[14] = "famas";
  weapons[15] = "ak47";
  weapons[16] = "m4a1";
  weapons[17] = "sg552";
  weapons[18] = "aug";
  weapons[19] = "m249";
  weapons[20] = "scout";
  weapons[21] = "awp";
  weapons[22] = "g3sg1";
  weapons[23] = "sg550";
  weapons[24] = "hegrenade";
  weapons[25] = "knife";
  
  for (new i = 0; i <= 25; i++)
  {
    if (StrEqual(weapon, weapons[i], false))
    {
      valid = true;
    }
  }
  if (!valid)
  {
    PrintToServer("[Warmup Round] Weapon selection: %s, is not valid.  Please try setting sm_warmupround_weapon again.", weapon);
    g_weapon = "hegrenade";
  }
  else
  {
    PrintToServer("[Warmup Round] Weapon selection changed to: %s", weapon);
    strcopy(g_weapon, sizeof(g_weapon), weapon);
  }
}

public Action:CancelWarmup()
{
  SetConVarBool(g_Cvaractive, false, false, false);
  g_warmuptimer = INVALID_HANDLE;
  IsWarmup = false;
  ServerCommand("mp_restartgame 1");
  new String:buffer[32] = "cfg/";
  StrCat(buffer, sizeof(buffer), g_postexec);
  if (FileExists(buffer))
  {
    ServerCommand("exec %s", g_postexec);
  }
  if (g_friendlyfire)
  {
    ServerCommand("mp_friendlyfire 1");
  }
}  

WeaponHandler(client)
{
  if (IsWarmup && client != 0)
  {
    new String:buffer[32];
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
    if (strlen(g_weapon) > 2)
    {
      Format(buffer, sizeof(buffer), "weapon_%s", g_weapon);
      GivePlayerItem(client, buffer);
    }
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

public Action:SpawnPlayer(Handle:timer, any:client)
{
  if (IsClientInGame(client))
  {
    CS_RespawnPlayer(client);
  }
}

public EventItemPickup(Handle:event, const String:name[],bool:dontBroadcast)
{
	if (g_enabled && IsWarmup)
  {
    new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
    new String:item[32];
    GetEventString(event, "item", item, sizeof(item));
    if (!StrEqual(item, g_weapon, false))
    {
      CreateTimer(0.1, DelayWeapon, clientid);
    }
  }
}

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast)
{
  if (g_enabled && IsWarmup)
  {
    if (StrEqual(g_weapon, "hegrenade", false))
    {
      new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
      new String:weapon[32];
      GetEventString(event, "weapon", weapon, sizeof(weapon));
      if (StrEqual(weapon, "hegrenade", false))
      {
        CreateTimer(1.1, DelayWeapon, clientid);
      }
    }
  }
}
public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
  if (g_enabled && IsWarmup && g_respawn)
  {
    new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.5, SpawnPlayer, clientid);
  }
}  
