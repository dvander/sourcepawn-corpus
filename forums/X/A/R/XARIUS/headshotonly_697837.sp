#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "Headshot Only",
	author = "XARiUS",
	description = "Plugin which prevents all damage but headshots.",
	version = "1.0.1",
	url = "http://www.the-otc.com/"
};

new String:language[4];
new String:languagecode[4];
new String:g_headsounds[256];
new String:headsounds[5][256];
new bool:g_enabled;
new bool:g_useambient;
new soundsfound;
new Handle:g_Cvarenabled = INVALID_HANDLE;
new Handle:g_Cvarheadsounds = INVALID_HANDLE;
new Handle:g_Cvaruseambient = INVALID_HANDLE;
new g_iHealth, g_Armor;

public OnPluginStart()
{
  LoadTranslations("headshotonly.phrases");
  GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));
  CreateConVar("sm_headshotonly_version", VERSION, "Headshot Only", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Cvarenabled = CreateConVar("sm_headshotonly_enabled", "1", "Enable this plugin. 0 = Disabled");
  g_Cvarheadsounds = CreateConVar("sm_headshotonly_sounds", "", "Sound files to indicate headshots. (Max: 5)  Leave blank for default sounds.");
  g_Cvaruseambient = CreateConVar("sm_headshotonly_useambient", "1", "Emit sounds from victim to all players.  0 = Emit sound from victim only to attacker.");

  HookEvent("player_hurt", EventPlayerHurt, EventHookMode_Pre);

  HookConVarChange(g_Cvarenabled, OnSettingChanged);
  HookConVarChange(g_Cvaruseambient, OnSettingChanged);
  AutoExecConfig(true, "headshotonly");

  g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
  if (g_iHealth == -1)
  {
    SetFailState("[Headshot Only] Error - Unable to get offset for CSSPlayer::m_iHealth");
  }

  g_Armor = FindSendPropOffs("CCSPlayer", "m_ArmorValue");
  if (g_Armor == -1)
  {
    SetFailState("[Headshot Only] Error - Unable to get offset for CSSPlayer::m_ArmorValue");
  }
}

public OnConfigsExecuted()
{
  g_enabled = GetConVarBool(g_Cvarenabled);
  g_useambient = GetConVarBool(g_Cvaruseambient);

  GetConVarString(g_Cvarheadsounds, g_headsounds, sizeof(g_headsounds));
  if (!StrEqual(g_headsounds, "", false))
  {
    new String: buffer[256];
    soundsfound = ExplodeString(g_headsounds, ",", headsounds, 5, 64);
    if (soundsfound > 0)
    {
      for (new i = 0; i <= soundsfound -1; i++)
      {
        Format(buffer, PLATFORM_MAX_PATH, "headshotonly/%s", headsounds[i]);
        if (!PrecacheSound(buffer, true))
        {
          SetFailState("HeadShot Only: Could not pre-cache sound: %s", buffer);
        }
        else
        {
          Format(buffer, PLATFORM_MAX_PATH, "sound/headshotonly/%s", headsounds[i]);
          AddFileToDownloadsTable(buffer);
          buffer = "headshotonly/";
          StrCat(buffer, sizeof(buffer), headsounds[i]);
          headsounds[i] = buffer;
        }
      }
    }
    return;
  }
  soundsfound = 5;
  headsounds[0] = "physics/flesh/flesh_squishy_impact_hard1.wav";
  headsounds[1] = "physics/flesh/flesh_squishy_impact_hard2.wav";
  headsounds[2] = "physics/flesh/flesh_squishy_impact_hard3.wav";
  headsounds[3] = "physics/flesh/flesh_squishy_impact_hard4.wav";
  headsounds[4] = "physics/flesh/flesh_bloody_break.wav";
  PrecacheSound(headsounds[0], true);
  PrecacheSound(headsounds[1], true);
  PrecacheSound(headsounds[2], true);
  PrecacheSound(headsounds[3], true);
  PrecacheSound(headsounds[4], true);
}

public OnSettingChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
  if (convar == g_Cvarenabled)
  {
    if (newValue[0] == '1')
    {
			g_enabled = true;
			PrintHintTextToAll("%t", "Headshot enabled");
			EmitSoundToAll("player/bhit_helmet-1.wav");
    }
    else
    {
      g_enabled = false;
      PrintHintTextToAll("%t", "Headshot disabled");
      EmitSoundToAll("player/bhit_helmet-1.wav");
    }
  }
  if (convar == g_Cvaruseambient)
  {
    if (newValue[0] == '1')
    {
			g_useambient = true;
    }
    else
    {
      g_useambient = false;
    }
  }
}

public Action:EventPlayerHurt(Handle:event, const String:name[],bool:dontBroadcast)
{
  if (g_enabled)
  {
    new hitgroup = GetEventInt(event, "hitgroup");
    new victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new dhealth = GetEventInt(event, "dmg_health");
    new darmor = GetEventInt(event, "dmg_armor");
    new health = GetEventInt(event, "health");
    new armor = GetEventInt(event, "armor");

    if (hitgroup == 1)
    {
      if (g_useambient)
      {
        new Float:vicpos[3];
        GetClientEyePosition(victim, vicpos);
        EmitAmbientSound(headsounds[GetRandomInt(0, soundsfound -1)], vicpos, victim, SNDLEVEL_GUNFIRE);
      }
      else
      {
        EmitSoundToClient(attacker, headsounds[GetRandomInt(0, soundsfound -1)], SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
      }
      return Plugin_Continue;
    }
    else if (attacker != victim && victim != 0 && attacker != 0)
    {
      if (dhealth > 0)
      {
        SetEntData(victim, g_iHealth, (health + dhealth), 4, true);
      }
      if (darmor > 0)
      {
        SetEntData(victim, g_Armor, (armor + darmor), 4, true);
      }
    }
  }
  return Plugin_Continue;
}
