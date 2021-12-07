#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#define VERSION "2.2.0"

public Plugin:myinfo =
{
	name = "Warmup Round",
	author = "XARiUS, Avo, Gdk",
	description = "Simple warmup round plugin.",
	version = VERSION,
	url = ""
};

new String:language[4];
new String:languagecode[4];
new String:g_weapon[32];
new String:g_weapon2[32];
new String:g_preexec[32];
new String:g_postexec[32];
new bool:IsWarmup;
new bool:g_enabled;
new bool:g_respawn;
new bool:g_friendlyfire;
new g_time;
new g_paused;
new timesrepeated;

new Handle:g_Cvarenabled = INVALID_HANDLE;
new Handle:g_Cvartime = INVALID_HANDLE;
new Handle:g_CvarPaused = INVALID_HANDLE;
new Handle:g_Cvarweapon = INVALID_HANDLE;
new Handle:g_Cvarweapon2 = INVALID_HANDLE;
new Handle:g_Cvarrespawn = INVALID_HANDLE;
new Handle:g_Cvarfriendlyfire = INVALID_HANDLE;
new Handle:g_Cvarpreexec = INVALID_HANDLE;
new Handle:g_Cvarpostexec = INVALID_HANDLE;
new Handle:g_Cvaractive = INVALID_HANDLE;
new Handle:g_warmuptimer = INVALID_HANDLE;

new g_iMyWeapons;

#define WEAPON_NB 32
new String:g_sWeaponsNamesGame[WEAPON_NB][] = {"knife","glock","hkp2000","p250","deagle","elite","fiveseven","tec9","nova","xm1014","mag7","bizon","sawedoff","mac10","mp9","mp7","ump45","p90","galilar","ak47","scar20","famas","m4a1","aug","ssg08","sg556","awp","g3sg1","m249","negev","hegrenade","taser"};

public OnPluginStart()
{
  LoadTranslations("warmup.phrases");
  CreateConVar("sm_warmupround_version", VERSION, "Warmup Round Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Cvaractive = CreateConVar("sm_warmupround_active", "0", "DO NOT MODIFY THIS VALUE DIRECTLY - USED FOR STATS TRACKING", FCVAR_DONTRECORD);
  g_Cvarenabled = CreateConVar("sm_warmupround_enabled", "1", "Enable this plugin. 0 = Disabled");
  // g_Cvartime = CreateConVar("sm_warmupround_time", "30", "Time in seconds for the warmup to last.  Minimum 15.", _, true, 15.0, true, 120.0);
  g_Cvartime = FindConVar("mp_warmuptime");
  g_CvarPaused = FindConVar("mp_warmup_pausetimer");
  g_Cvarweapon = CreateConVar("sm_warmupround_weapon", "hegrenade", "Weapon to give players during warmup.  HEGrenades are unlimted.  Examples: knife,deagle,fiveseven,elite,hkp2000,random..");
  g_Cvarweapon2 = CreateConVar("sm_warmupround_weapon2", "nova", "Weapon to give players during warmup.  HEGrenades are unlimted.  Examples: knife,deagle,fiveseven,elite,hkp2000,random..");
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
  HookConVarChange(g_CvarPaused, OnSettingChanged);
  HookConVarChange(g_Cvarweapon, OnSettingChanged);
  HookConVarChange(g_Cvarrespawn, OnSettingChanged);
  HookConVarChange(g_Cvarfriendlyfire, OnSettingChanged);
  HookConVarChange(g_Cvarpreexec, OnSettingChanged);
  HookConVarChange(g_Cvarpostexec, OnSettingChanged);
  
  g_enabled = GetConVarBool(g_Cvarenabled);
  g_respawn = GetConVarBool(g_Cvarrespawn);
  g_friendlyfire = GetConVarBool(g_Cvarfriendlyfire);
  g_time = GetConVarInt(g_Cvartime);
  g_paused = GetConVarInt(g_CvarPaused);
  GetConVarString(g_Cvarpreexec, g_preexec, sizeof(g_preexec));
  GetConVarString(g_Cvarpostexec, g_postexec, sizeof(g_postexec));
  timesrepeated = g_time;
  IsWarmup = false;
  SetupOffsets();
  
  AutoExecConfig(true, "warmup");
}

public OnMapStart()
{
	GetConVarString(g_Cvarweapon, g_weapon, sizeof(g_weapon));
  	CheckWeaponString(g_weapon);
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
  if (convar == g_CvarPaused)
  {
    g_paused = StringToInt(newValue);
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
  if (g_warmuptimer != INVALID_HANDLE && g_paused == 0)
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
  new bool:valid = false;
  
  if(StrEqual(weapon, "random", false))
  {
    strcopy(g_weapon, sizeof(g_weapon), g_sWeaponsNamesGame[GetURandomInt() % WEAPON_NB]);
    PrintToServer("[Warmup Round] Weapon selection random: %s", weapon);
  }
  else
  {
    for (new i = 0; i < WEAPON_NB; i++)
    {
      if (StrEqual(weapon, g_sWeaponsNamesGame[i], false))
      {
        valid = true;
        break;
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
    for (Slot = 0; Slot <= (11); Slot += 1)
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
	if (IsWarmup && g_paused == 1)
  	{
    		PrintHintTextToAll("%t", "warmup pause");
		return Plugin_Continue;
  	}
  	if (IsWarmup && g_paused == 0)
  	{
    		if (timesrepeated >= 1)
    		{
      			PrintHintTextToAll("%t", "warmup time");
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
    if (StrEqual(g_weapon, "hegrenade", false) || StrEqual(g_weapon, "taser", false) || StrEqual(g_weapon, "random", false))
    {
      new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
      new String:weapon[32];
      GetEventString(event, "weapon", weapon, sizeof(weapon));
      if (StrEqual(weapon, "hegrenade", false) || StrEqual(weapon, "taser", false))
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
