#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define VERSION "1.2.1K"
#define MAX_FILE_LEN 80
#define SOUND_BLIP "buttons/blip1.wav"
#define SOUND_EXPLODE "ambient/explosions/explode_8.wav"
#define SOUND_TIMER "ambient/tones/floor1.wav"

public Plugin:myinfo =
{
	name = "1v1 Knife Fight",
	author = "XARiUS",
	description = "Let the last two players alive choose whether to knife it out.",
	version = "1.2.1",
	url = "http://www.the-otc.com/"
};

new Float:teleloc[3];
new Float:g_winnerspeed;
new String:language[4];
new String:languagecode[4];
new String:ctname[MAX_NAME_LENGTH];
new String:tname[MAX_NAME_LENGTH];
new String:ctitems[8][64];
new String:titems[8][64];
new String:winnername[MAX_NAME_LENGTH];
new String:losername[MAX_NAME_LENGTH];
new String:g_declinesound[MAX_FILE_LEN];
new String:g_fightsongs[64];
new String:fightsong[6][64];
new String:song[64];
new String:itemswon[256];
new bool:g_winnereffects;
new bool:g_losereffects;
new bool:g_forcefight;
new bool:g_enabled;
new bool:g_useteleport;
new bool:g_restorehealth;
new bool:g_locatorbeam;
new bool:g_stopmusic;
new bool:g_intermission;
new bool:isHandling = false;
new bool:isFighting = false;
new bool:bombplanted = false;
new bool:countdown = false;
new ctid, tid, winner, winnerid, loser, alivect, alivet;
new ctagree = -1;
new tagree = -1;
new songsfound = 0;
new timesrepeated;
new g_iMyWeapons, g_iHealth, g_iAccount, g_iSpeed;
new g_beamsprite, g_halosprite, g_lightning, g_locatebeam, g_locatehalo;
new g_countdowntimer, g_winnerhealth, g_winnermoney, g_minplayers;
new g_fighttimer, fighttimer;
new Handle:g_Cvarenabled = INVALID_HANDLE;
new Handle:g_Cvarminplayers = INVALID_HANDLE;
new Handle:g_Cvardeclinesound = INVALID_HANDLE;
new Handle:g_Cvarfightsongs = INVALID_HANDLE;
new Handle:g_Cvaruseteleport = INVALID_HANDLE;
new Handle:g_Cvarrestorehealth = INVALID_HANDLE;
new Handle:g_Cvarwinnerspeed = INVALID_HANDLE;
new Handle:g_Cvarwinnerhealth = INVALID_HANDLE;
new Handle:g_Cvarwinnermoney = INVALID_HANDLE;
new Handle:g_Cvarwinnereffects = INVALID_HANDLE;
new Handle:g_Cvarlosereffects = INVALID_HANDLE;
new Handle:g_Cvarlocatorbeam = INVALID_HANDLE;
new Handle:g_Cvarstopmusic = INVALID_HANDLE;
new Handle:g_Cvarforcefight = INVALID_HANDLE;
new Handle:g_Cvarcountdowntimer = INVALID_HANDLE;
new Handle:g_Cvarfighttimer = INVALID_HANDLE;
new Handle:g_Cvarremoveweapon = INVALID_HANDLE;
new UserMsg:g_VGUIMenu;

public OnPluginStart()
{
  LoadTranslations("knifefight.phrases");
  CreateConVar("sm_knifefight_version", VERSION, "Knife Fight Version || PLEASE DO NOT CHANGE THIS", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
  g_Cvarenabled = CreateConVar("sm_knifefight_enabled", "1", "Enable this plugin. 0 = Disabled");
  g_Cvarminplayers = CreateConVar("sm_knifefight_minplayers", "4", "Minimum number of players before knife fights will trigger.");
  g_Cvaruseteleport = CreateConVar("sm_knifefight_useteleport", "1", "Use smart teleport system prior to knife fight. 0 = Disabled");
  g_Cvarrestorehealth = CreateConVar("sm_knifefight_restorehealth", "1", "Give players full health before knife fight. 0 = Disabled");
  g_Cvarforcefight = CreateConVar("sm_knifefight_forcefight", "0", "Force knife fight at end of round instead of prompting with menus. 0 = Disabled");
  g_Cvarwinnerhealth = CreateConVar("sm_knifefight_winnerhealth", "0", "Total health to give the winner. 0 = Disabled");
  g_Cvarwinnerspeed = CreateConVar("sm_knifefight_winnerspeed", "0", "Total speed given to the winner. 0 = Disabled (1.0 is normal speed, 2.0 is twice normal)");
  g_Cvarwinnermoney = CreateConVar("sm_knifefight_winnermoney", "0", "Total extra money given to the winner. 0 = Disabled");
  g_Cvarwinnereffects = CreateConVar("sm_knifefight_winnereffects", "1", "Enable special effects on the winner. 0 = Disabled");
  g_Cvarlosereffects = CreateConVar("sm_knifefight_losereffects", "1", "Dissolve loser body using special effects. 0 = Disabled");
  g_Cvarlocatorbeam = CreateConVar("sm_knifefight_locatorbeam", "1", "Use locator beam between players if they are far apart. 0 = Disabled");
  g_Cvarstopmusic = CreateConVar("sm_knifefight_stopmusic", "0", "Stop music when fight is over.  Useful when used with gungame. 0 = Disabled");
  g_Cvardeclinesound = CreateConVar("sm_knifefight_declinesound", "chicken.wav", "The sound to play when player declines to knife.");
  g_Cvarcountdowntimer = CreateConVar("sm_knifefight_countdowntimer", "3", "Number of seconds to count down before a knife fight.");
  g_Cvarfighttimer = CreateConVar("sm_knifefight_fighttimer", "30", "Number of seconds to allow for knifing.  Players get slayed after this time limit expires.");
  g_Cvarfightsongs = CreateConVar("sm_knifefight_fightsongs", "", "Songs to play during the fight, comma delimited. (example: song1.mp3,song2.mp3,song3.mp3) (max: 6)");
  g_Cvarremoveweapon = CreateConVar("sm_knifefight_removeweapon", "1", "Remove dropped weapons before knifefight");

  GetLanguageInfo(GetServerLanguage(), languagecode, sizeof(languagecode), language, sizeof(language));

  HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
  HookEvent("player_death", EventPlayerDeath, EventHookMode_Post);
  HookEvent("item_pickup", EventItemPickup, EventHookMode_Post);
  HookEvent("bomb_planted", EventBombPlanted, EventHookMode_PostNoCopy);
  HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);

  g_VGUIMenu = GetUserMessageId("VGUIMenu");
  if (g_VGUIMenu == INVALID_MESSAGE_ID)
  {
    LogError("FATAL: Cannot find VGUIMenu user message id.");
    SetFailState("VGUIMenu Not Found");
  }
  HookUserMessage(g_VGUIMenu, UserMsg_VGUIMenu);
  
  HookConVarChange(g_Cvarenabled, OnSettingChanged);
  HookConVarChange(g_Cvarminplayers, OnSettingChanged);
  HookConVarChange(g_Cvaruseteleport, OnSettingChanged);
  HookConVarChange(g_Cvarrestorehealth, OnSettingChanged);
  HookConVarChange(g_Cvarwinnerhealth, OnSettingChanged);
  HookConVarChange(g_Cvarwinnerspeed, OnSettingChanged);
  HookConVarChange(g_Cvarwinnermoney, OnSettingChanged);
  HookConVarChange(g_Cvarwinnereffects, OnSettingChanged);
  HookConVarChange(g_Cvarlosereffects, OnSettingChanged);
  HookConVarChange(g_Cvarlocatorbeam, OnSettingChanged);
  HookConVarChange(g_Cvarstopmusic, OnSettingChanged);
  HookConVarChange(g_Cvarforcefight, OnSettingChanged);
  HookConVarChange(g_Cvarcountdowntimer, OnSettingChanged);
  HookConVarChange(g_Cvarfighttimer, OnSettingChanged);

  SetupOffsets();  
  AutoExecConfig(true, "knifefight");
}


public OnConfigsExecuted()
{
  decl String:buffer[MAX_FILE_LEN];
  g_beamsprite = PrecacheModel("materials/sprites/laser.vmt");
  g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
  g_lightning = PrecacheModel("materials/sprites/tp_beam001.vmt");
  g_locatebeam = PrecacheModel("materials/sprites/physbeam.vmt");
  g_locatehalo = PrecacheModel("materials/sprites/plasmahalo.vmt");
  PrecacheSound(SOUND_BLIP, true);
  PrecacheSound(SOUND_EXPLODE,true);
  PrecacheSound(SOUND_TIMER,true);
  GetConVarString(g_Cvardeclinesound, g_declinesound, sizeof(g_declinesound));
  Format(buffer, MAX_FILE_LEN, "knifefight/%s", g_declinesound);
  if (!PrecacheSound(buffer, true))
  {
    SetFailState("1v1 Knife Fight: Could not pre-cache sound: %s", buffer);
  }
  else
  {
    Format(buffer, MAX_FILE_LEN, "sound/knifefight/%s", g_declinesound);
    AddFileToDownloadsTable(buffer);
  }
  GetConVarString(g_Cvarfightsongs, g_fightsongs, sizeof(g_fightsongs));
  if (!StrEqual(g_fightsongs, "", false))
  {
    songsfound = ExplodeString(g_fightsongs, ",", fightsong, 6, 64);
    for (new i = 0; i <= songsfound -1; i++)
    {
      Format(buffer, MAX_FILE_LEN, "knifefight/%s", fightsong[i]);
      if (!PrecacheSound(buffer, true))
      {
        SetFailState("1v1 Knife Fight: Could not pre-cache sound: %s", buffer);
      }
      else
      {
        Format(buffer, MAX_FILE_LEN, "sound/knifefight/%s", fightsong[i]);
        AddFileToDownloadsTable(buffer);
      }
    }
  }
  g_enabled = GetConVarBool(g_Cvarenabled);
  g_minplayers = GetConVarInt(g_Cvarminplayers);
  g_useteleport = GetConVarBool(g_Cvaruseteleport);
  g_restorehealth = GetConVarBool(g_Cvarrestorehealth);
  g_winnerhealth = GetConVarInt(g_Cvarwinnerhealth);
  g_winnerspeed = GetConVarFloat(g_Cvarwinnerspeed);
  g_winnereffects = GetConVarBool(g_Cvarwinnereffects);
  g_losereffects = GetConVarBool(g_Cvarlosereffects);
  g_locatorbeam = GetConVarBool(g_Cvarlocatorbeam);
  g_stopmusic = GetConVarBool(g_Cvarstopmusic);
  g_forcefight = GetConVarBool(g_Cvarforcefight);
  g_countdowntimer = GetConVarInt(g_Cvarcountdowntimer);
  g_fighttimer = GetConVarInt(g_Cvarfighttimer);
}

SetupOffsets()
{
  g_iMyWeapons = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
  if (g_iMyWeapons == -1)
  {
    SetFailState("[1v1 Knife Fight] Error - Unable to get offset for CBaseCombatCharacter::m_hMyWeapons");
  }

  g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
  if (g_iHealth == -1)
  {
    SetFailState("[1v1 Knife Fight] Error - Unable to get offset for CSSPlayer::m_iHealth");
  }

  g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
  if (g_iAccount == -1)
  {
    SetFailState("[1v1 Knife Fight] Error - Unable to get offset for CSSPlayer::m_iAccount");
  }

  g_iSpeed = FindSendPropOffs("CCSPlayer", "m_flLaggedMovementValue");
  if (g_iSpeed == -1)
  {
    SetFailState("[1v1 Knife Fight] Error - Unable to get offset for CSSPlayer::m_flLaggedMovementValue");
  }
}

public OnAutoConfigsBuffered()
{
  g_intermission = false;
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
  if (convar == g_Cvaruseteleport)
  {
    if (newValue[0] == '1')
    {
      g_useteleport = true;
    }
    else
    {
      g_useteleport = false;
    }
  }
  if (convar == g_Cvarrestorehealth)
  {
    if (newValue[0] == '1')
    {
      g_restorehealth = true;
    }
    else
    {
      g_restorehealth = false;
    }
  }
  if (convar == g_Cvarwinnereffects)
  {
    if (newValue[0] == '1')
    {
      g_winnereffects = true;
    }
    else
    {
      g_winnereffects = false;
    }
  }
  if (convar == g_Cvarlosereffects)
  {
    if (newValue[0] == '1')
    {
      g_losereffects = true;
    }
    else
    {
      g_losereffects = false;
    }
  }
  if (convar == g_Cvarlocatorbeam)
  {
    if (newValue[0] == '1')
    {
      g_locatorbeam = true;
    }
    else
    {
      g_locatorbeam = false;
    }
  }
  if (convar == g_Cvarstopmusic)
  {
    if (newValue[0] == '1')
    {
      g_stopmusic = true;
    }
    else
    {
      g_stopmusic = false;
    }
  }
  if (convar == g_Cvarforcefight)
  {
    if (newValue[0] == '1')
    {
      g_forcefight = true;
    }
    else
    {
      g_forcefight = false;
    }
  }
  if (convar == g_Cvarwinnerhealth)
  {
    g_winnerhealth = StringToInt(newValue);
  }
  if (convar == g_Cvarwinnerspeed)
  {
    g_winnerspeed = StringToFloat(newValue);
  }
  if (convar == g_Cvarwinnermoney)
  {
    g_winnermoney = StringToInt(newValue);
  }
  if (convar == g_Cvarcountdowntimer)
  {
    g_countdowntimer = StringToInt(newValue);
  }
  if (convar == g_Cvarfighttimer)
  {
    g_fighttimer = StringToInt(newValue);
  }
  if (convar == g_Cvarminplayers)
  {
    g_minplayers = StringToInt(newValue);
  }
}

public Action:UserMsg_VGUIMenu(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
  if (g_intermission)
  {
    return Plugin_Handled;
  }
  
  decl String:type[15];

  if (BfReadString(bf, type, sizeof(type)) < 0)
  {
    return Plugin_Handled;
  }
 
  if (BfReadByte(bf) == 1 && BfReadByte(bf) == 0 && (strcmp(type, "scores", false) == 0))
  {
    g_intermission = true;
  }
  return Plugin_Handled;
}

WeaponHandler(client, teamid)
{
  if (isFighting && !isHandling && client != 0)
  {
    isHandling = true;
    static count = 0;
    for (new i = 0; i <= 128; i += 4)
    {
      new weaponentity = -1;
      new String:weaponname[32];
      weaponentity = GetEntDataEnt2(client, (g_iMyWeapons + i));
      if (IsValidEdict(weaponentity))
      {
        GetEdictClassname(weaponentity, weaponname, sizeof(weaponname));
        if (weaponentity != -1 && !StrEqual(weaponname, "worldspawn", false))
        {
          if (teamid == 0 && !StrEqual(weaponname, "weapon_knife", false))
          {
            RemovePlayerItem(client, weaponentity);
            RemoveEdict(weaponentity);
            if (!countdown)
            {
              EquipKnife(client);
            }
          }
          else if (teamid == 3 || teamid == 2)
          {
            RemovePlayerItem(client, weaponentity);
            RemoveEdict(weaponentity);
            if (teamid == 3)
            {
              ctitems[count] = weaponname;
              count++;
            }

            if (teamid == 2)
            {
              titems[count] = weaponname;
              count++;
            }
          }
        }
      }
    }
    count = 0;
    isHandling = false;
  }
  else
  {
    for (new i = 0; i <= 7 ; i++)
    {
      if (IsClientInGame(client))
      {    
        if (teamid == 3)
        {
          if (!StrEqual(ctitems[i], "", false))
          {
            GivePlayerItem(client, ctitems[i]);
          }
        }
        else if (teamid == 2)
        {
          if (!StrEqual(titems[i], "", false))
          {
            GivePlayerItem(client, titems[i]);
          }
        }
      }
    }
  }
}

public EquipKnife(client)
{
  if (client != 0)
  {
    GivePlayerItem(client, "weapon_knife");
    for (new i = 1; i <=5; ++i)
    {
      new weaponentity = -1;
      weaponentity = GetPlayerWeaponSlot(client, i);
      if (weaponentity != -1)
      {
        EquipPlayerWeapon(client, weaponentity);
      }
    }
  }
}

public Action:WinnerEffects()
{
  CreateTimer(0.1, LightningTimer, _, TIMER_REPEAT);
  CreateTimer(0.6, ExplosionTimer, _, TIMER_REPEAT);
}

public Action:DelayWeapon(Handle:timer, any:clientid) // Prevent crashes with gungame and turbo.
{
  WeaponHandler(clientid, 0);
}

public Action:LightningTimer(Handle:timer)
{
  if (winner != 0)
  {
    static TimesRepeated = 0;
    if (TimesRepeated++ <= 30)
    {
      Lightning();
      return Plugin_Continue;
    }
    else
    {
      TimesRepeated = 0;
      return Plugin_Stop;
    }
  }
  return Plugin_Stop;
}

public Action:ExplosionTimer(Handle:timer)
{
  if (winner != 0)
  {
    static TimesRepeated = 0;
    new Float:playerpos[3];
    if (TimesRepeated++ <= 3 && IsClientInGame(winner))
    {
      GetClientAbsOrigin(winner,playerpos);
      EmitAmbientSound("ambient/explosions/explode_8.wav", playerpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
      return Plugin_Continue;
    }
    else
    {
      TimesRepeated = 0;
      return Plugin_Stop;
    }
  }
  return Plugin_Stop;
}

public Action:KillPlayer(Handle:timer, any:clientid)
{
	ForcePlayerSuicide(clientid);
}

public Action:SlapTimer(Handle:timer)
{
  static TimesRepeated = 0;
  if (TimesRepeated <= 1)
  {
    SlapPlayer(ctid, 0, false);
    TimesRepeated++;
    return Plugin_Continue;
  }
  else
  {
    TimesRepeated = 0;
    return Plugin_Stop;
  }
}

public Action:TeleportTimer(Handle:timer)
{
  TeleportEntity(tid, teleloc, NULL_VECTOR, NULL_VECTOR);
  return;
}

public Action:ItemsWon(Handle:timer)
{
  static TimesRepeated = 0;
  if (IsClientInGame(winner))
  {
    if (TimesRepeated <=2)
    {
      PrintHintText(winner, itemswon);
      TimesRepeated++;
      return Plugin_Continue;
    }
    else
    {
      TimesRepeated = 0;
      itemswon = "";
      return Plugin_Stop;
    }
  }
  return Plugin_Stop;
}

public Action:StartFight()
{
  if (ctid == 0 || tid == 0)
  {
    return;
  }
  isFighting = true;
  if (IsPlayerAlive(ctid) && IsPlayerAlive(tid))
  {
    new randomsong = 0;
    song = "knifefight/";
    if (songsfound > 0)
    {
      if (songsfound < 2)
      {
        StrCat(song, sizeof(song), fightsong[randomsong]);
      }
      else
      {
        randomsong = GetRandomInt(0,songsfound - 1);
        StrCat(song, sizeof(song), fightsong[randomsong]);
      }
      EmitSoundToAll(song, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
    }
    PrintHintTextToAll("%t", "Removing weapons");
    if(GetConVarInt(g_Cvarremoveweapon)) RemoveDroppedWeapons();
    CreateTimer(2.0, StartBeacon, ctid, TIMER_REPEAT);
    CreateTimer(2.0, StartBeacon, tid, TIMER_REPEAT);
    WeaponHandler(ctid, 3);
    WeaponHandler(tid, 2);
    if (g_useteleport)
    {
      SetEntData(ctid, g_iHealth, 400);
      SetEntData(tid, g_iHealth, 400);
      new Float:ctvec[3];
      new Float:tvec[3];
      new Float:distance[1];
      GetClientAbsOrigin(ctid,Float:ctvec);
      GetClientAbsOrigin(tid,Float:tvec);
      distance[0] = GetVectorDistance(ctvec, tvec, true);
      if (distance[0] >= 600000.0)
      {
        teleloc = ctvec;
        CreateTimer(0.1, SlapTimer, _, TIMER_REPEAT);
        CreateTimer(0.5, TeleportTimer);
      }
      else if (g_locatorbeam)
      {
        CreateTimer(0.1, DrawBeamsTimer, _, TIMER_REPEAT);
      }
    }
    else if (g_locatorbeam)
    {
      CreateTimer(0.1, DrawBeamsTimer, _, TIMER_REPEAT);
    }
    countdown = true;
    CreateTimer(1.0, Countdown, _, TIMER_REPEAT);
  }
	else
	{
		CancelFight();
	}
}

public Action:CancelFight()
{
  isFighting = false;
  if (g_stopmusic && songsfound > 0)
  {
    EmitSoundToAll(song, _, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_STOPLOOPING, SNDVOL_NORMAL, SNDPITCH_NORMAL);
  }
  if (winner != 0)
  {
    if (IsPlayerAlive(winner))
    {
      WeaponHandler(winner, GetClientTeam(winner));
      for (new i = 0; i <= 7; i++)
      {
        ctitems[i] = "";
        titems[i] = "";
      }
    }
  }
}  

public Action:FightTimer(Handle:timer)
{
  if (!isFighting)
  {
    return Plugin_Stop;
  }
  if (fighttimer >= 6)
  {
    PrintHintTextToAll("%t: %i", "Time remaining", fighttimer);
    fighttimer--;
    return Plugin_Continue;
  }
  else if (fighttimer >= 0)
  {
    PrintHintTextToAll("%t: %i", "Time remaining", fighttimer);
    EmitSoundToAll(SOUND_TIMER);
    fighttimer--;
    return Plugin_Continue;
  }
  else if (fighttimer == -1)
  {
    CreateTimer(0.1, KillPlayer, ctid);
    CreateTimer(0.1, KillPlayer, tid);
    PrintHintTextToAll("%t", "Fight draw");
    return Plugin_Stop;
  }
  return Plugin_Continue;
}

public Action:Countdown(Handle:timer)
{
  if (isFighting)
  {
    SetEntData(ctid, g_iSpeed, 1.0);
    SetEntData(tid, g_iSpeed, 1.0);
    
    if (timesrepeated >= 1)
    {
      PrintHintTextToAll("%t: %i", "Prepare fight", timesrepeated);
      timesrepeated--;
    }
    else if (timesrepeated == 0)
    {
      if (g_restorehealth)
      {
        SetEntData(ctid, g_iHealth, 100);
        SetEntData(tid, g_iHealth, 100);
      }
      countdown = false;
      PrintHintTextToAll("%t", "Fight");
      EquipKnife(ctid);
      EquipKnife(tid);
      timesrepeated = g_countdowntimer;
      CreateTimer(1.0, FightTimer, _, TIMER_REPEAT);
      return Plugin_Stop;
    }
  }
  else
  {
    timesrepeated = g_countdowntimer;
    return Plugin_Stop;
  }
  return Plugin_Continue;
}

public Action:DrawBeamsTimer(Handle:timer)
{
  if (isFighting && IsPlayerAlive(ctid) && IsPlayerAlive(tid))
  {
    new Float:ctvec[3];
    new Float:tvec[3];
    new Float:distance[1];
    new color[4] = {255, 75, 75, 255};
    GetClientEyePosition(ctid,Float:ctvec);
    GetClientEyePosition(tid,Float:tvec);
    distance[0] = GetVectorDistance(ctvec, tvec, true);
    if (distance[0] >= 200000.0)
    {
      TE_SetupBeamPoints(ctvec, tvec, g_locatebeam, g_locatehalo, 1, 1, 0.1, 5.0, 5.0, 0, 10.0, color, 255);
      TE_SendToClient(tid);
      TE_SetupBeamPoints(tvec, ctvec, g_locatebeam, g_locatehalo, 1, 1, 0.1, 5.0, 5.0, 0, 10.0, color, 255);
      TE_SendToClient(ctid);
    }
    else
    {
      return Plugin_Stop;
    }
  }
  else
  {
    return Plugin_Stop;
  }
  return Plugin_Continue;
}

public Action:StartBeacon(Handle:timer, any:client)
{
  if (isFighting && IsClientInGame(ctid) && IsClientInGame(tid))
  {
    new redColor[4] = {255, 75, 75, 255};
    new blueColor[4] = {75, 75, 255, 255};
    new greyColor[4] = {128, 128, 128, 255};
    new team = GetClientTeam(client);
    new Float:vec[3];
    GetClientAbsOrigin(client, vec);
    vec[2] += 10;

    TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_beamsprite, g_halosprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
    TE_SendToAll();
    
    if (team == 2)
    {
      TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_beamsprite, g_halosprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
    }
    else if (team == 3)
    {
      TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_beamsprite, g_halosprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
    }
    TE_SendToAll();
      
    GetClientEyePosition(client, vec);
    EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
    return Plugin_Continue;
  }
  return Plugin_Stop;
}

public Action:VerifyConditions(Handle:timer)
{
  new Handle:warmup = INVALID_HANDLE;
  warmup = FindConVar("sm_warmupround_active");
  if (warmup != INVALID_HANDLE)
  {
    if (GetConVarBool(warmup))
    {
      return;
    }
  }
  if (g_intermission)
  {
    return;
  }
  if (ctid == 0 || tid == 0)
  {
    return;
  }
  if (GetClientCount() < g_minplayers)
  {
    return;
  }
  if (IsPlayerAlive(ctid) &&  IsPlayerAlive(tid))
  {
    if (!IsFakeClient(ctid) || !IsFakeClient(tid))
    {
      winner = 0;
      GetClientName(ctid, ctname, sizeof(ctname));
      GetClientName(tid, tname, sizeof(tname));
      PrintHintTextToAll("%t", "1v1 situation");
      if (g_forcefight)
      {
        CreateTimer(0.5, DelayFight);
      }
      else
      {
        SendKnifeMenus(ctid,tid);
      }
    }
  }
}

public Action:DelayFight(Handle:timer)
{
  StartFight();
}

public OnClientDisconnect(client)
{
	if (isFighting)
	{
		if (client == ctid)
		{
			winner = tid;
			loser = tid;
			CancelFight();
		}
		else if (client == tid)
		{
			winner = ctid;
			loser = ctid;
			CancelFight();
		}
	}
}

public EventRoundStart(Handle:event, const String:name[],bool:dontBroadcast)
{
	if (g_enabled)
	{
    if (isFighting)
		{
			CancelFight();
		}
    ctname = "";
    tname = "";
    winnername = "";
    losername = "";
    alivect = 0;
    alivet = 0;
    ctid = 0;
    tid = 0;
    loser = 0;
    countdown = false;
    bombplanted = false;
    timesrepeated = g_countdowntimer;
    fighttimer = g_fighttimer;
	}
}

public EventBombPlanted(Handle:event, const String:name[],bool:dontBroadcast)
{
  if (g_enabled)
  {
    bombplanted = true;
  }
}

public Action:EventItemPickup(Handle:event, const String:name[],bool:dontBroadcast)
{
	if (g_enabled && isFighting)
  {
    new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
    if (clientid == ctid || clientid == tid)
		{
			new String:item[64];
			GetEventString(event, "item", item, sizeof(item));
			if (!StrEqual(item, "knife", false))
			{
        CreateTimer(0.1, DelayWeapon, clientid); // Prevent crashes with Gungame4 Turbo
			}
		}
  }
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast)
{
  alivect = 0, alivet = 0;
  if (g_enabled && isFighting)
	{
		loser = GetClientOfUserId(GetEventInt(event, "userid"));
		if (loser == ctid || loser == tid)
		{
			winner = GetClientOfUserId(GetEventInt(event, "attacker"));
			if (winner != loser)
			{
        if (g_losereffects)
        {
          CreateTimer(0.4, DissolveRagdoll, loser);
        }
        winnerid = winner;
        GetClientName(winner, winnername, sizeof(winnername));
        GetClientName(loser, losername, sizeof(losername));
        PrintHintTextToAll("%s %t %s %t", winnername, "beat", losername, "win battle");
        if (g_winnereffects)
        {
          WinnerEffects();
				}
        CancelFight();
			}
			else if (winner == loser)
			{
				if (ctid == loser)
				{
					winner = tid;
					CancelFight();
				}
				else if (tid == loser)
				{
					winner = ctid;
					CancelFight();
				}
			}
		}
	}  
	else if (g_enabled && !isFighting)
	{
    for (new i = 1; i <= GetMaxClients(); i++)
    {
      new team;
      if (IsClientInGame(i) && IsPlayerAlive(i))
      {
        team = GetClientTeam(i);
        if (team == 3) { ctid = i; alivect++; }
        else if (team == 2) { tid = i; alivet++; }
      }
    }
    if (alivect == 1 && alivet == 1 && !bombplanted)
    {
      CreateTimer(0.5, VerifyConditions);
    }
  }
}

public EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast)
{
  if (g_enabled && isFighting)
  {
		new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
		if (IsClientInGame(clientid) && IsPlayerAlive(clientid))
		{
			CreateTimer(0.1, KillPlayer, clientid);
		}
	}
	else if (g_enabled && !isFighting && GetClientOfUserId(GetEventInt(event, "userid")) == winnerid)
	{
		if (g_winnerhealth > 0)
		{
			SetEntData(winnerid, g_iHealth, g_winnerhealth);
		}
		if (g_winnermoney > 0)
		{ 
			new totalmoney = GetEntData(winnerid, g_iAccount) + g_winnermoney;
			SetEntData(winnerid, g_iAccount, totalmoney);
		}
		if (g_winnerspeed > 0)
		{
			SetEntData(winnerid, g_iSpeed, g_winnerspeed);
		}
		if (g_winnerhealth > 0 || g_winnermoney > 0 || g_winnerspeed > 0.0 )
		{
      new String:buffer[256];
      Format(buffer, sizeof(buffer), "%t:\n\n", "Items won");
      StrCat(itemswon, sizeof(itemswon), buffer);
      if (g_winnerhealth > 0)
      {
        Format(buffer, sizeof(buffer), "%t: %i\n", "Health", g_winnerhealth);
        StrCat(itemswon, sizeof(itemswon), buffer);
      }
      if (g_winnermoney > 0)
      {
        Format(buffer, sizeof(buffer), " %t: $%i\n", "Money", g_winnermoney);
        StrCat(itemswon, sizeof(itemswon), buffer);
      }
      if (g_winnerspeed > 0)
      {
        Format(buffer, sizeof(buffer), "%t: %.2fx", "Speed", g_winnerspeed);
        StrCat(itemswon, sizeof(itemswon), buffer);
      }
      CreateTimer(1.0, ItemsWon, _, TIMER_REPEAT);
      winnerid = 0;
    }
  }
}

// Thanks to LDuke for the dissolve effects.

public Action:DissolveRagdoll(Handle:timer, any:client)
{
  if (!IsValidEntity(client) || IsPlayerAlive(client))
  {
    return;
  }
    
  new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

  if (ragdoll < 0)
  {
    return;
  }
    
  new String:dname[32];
  Format(dname, sizeof(dname), "dis_%d", client);
  
  new entid = CreateEntityByName("env_entity_dissolver");

  if (entid > 0)
  {
    DispatchKeyValue(ragdoll, "targetname", dname);
    DispatchKeyValue(entid, "dissolvetype", "0");
    DispatchKeyValue(entid, "target", dname);
    AcceptEntityInput(entid, "Dissolve");
    AcceptEntityInput(entid, "kill");
  }
}

public Action:SendKnifeMenus(ct,t)
{
  ctagree = -1;
  tagree = -1;
  new String:title[128];
  new String:question[128];
  new String:yes[128];
  new String:no[128];
  Format(title,127, "%t", "Knife menu title");
  Format(question,127, "%t", "Knife question");
  Format(yes,127, "%t", "Yes option");
  Format(no,127, "%t", "No option");
  
  new Handle:panel = CreatePanel();
  
  SetPanelTitle(panel,title);
  DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
  DrawPanelText(panel,question);
  DrawPanelItem(panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
  DrawPanelItem(panel,yes);
  DrawPanelItem(panel,no);
  if (IsFakeClient(ct))
  {
    PrintToChatAll("[SM] [CT] %s %t", ctname, "Player agrees");
    ctagree = 1;
  }
  else
  {
    SendPanelToClient(panel, ct, PanelHandler, 30);
  }
  if (IsFakeClient(t))
  {
    PrintToChatAll("[SM] [T] %s %t", tname, "Player agrees");
    tagree = 1;
  }
  else
  {
    SendPanelToClient(panel, t, PanelHandler, 30);
  }

  CloseHandle(panel);
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
  if (action == MenuAction_Select)
	{
    if (param2 == 1 && param1 != 0)
    {
      if (GetClientTeam(param1) == 3 && param1 == ctid && tagree != 0 && IsPlayerAlive(tid))
      {
        PrintToChatAll("[SM] [CT] %s %t", ctname, "Player agrees");
        ctagree = 1;
      } 
      else if (GetClientTeam(param1) == 2 && param1 == tid && ctagree != 0 && IsPlayerAlive(ctid))
      {
        PrintToChatAll("[SM] [T] %s %t", tname, "Player agrees");
        tagree = 1;
      }
    }
    else if (param2 == 2 && param1 != 0)
    {
      if (GetClientTeam(param1) == 3 && param1 == ctid && tagree != 0 && IsPlayerAlive(tid))
      {
        PrintToChatAll("[SM] [CT] %s %t", ctname, "Player disagrees");
        ctagree = 0;
        new String:decline[64] = "knifefight/";
        StrCat(decline, sizeof(decline), g_declinesound);
        EmitSoundToAll(decline);
      } 
      else if (GetClientTeam(param1) == 2 && param1 == tid && ctagree != 0 && IsPlayerAlive(tid))
      {
        PrintToChatAll("[SM] [T] %s %t", tname, "Player disagrees");
        tagree = 0;
        new String:decline[64] = "knifefight/";
        StrCat(decline, sizeof(decline), g_declinesound);
        EmitSoundToAll(decline);
      }
    }
	}
	else if (action == MenuAction_Cancel)
	{
    ctagree = -1;
    tagree = -1;
  }
  if (ctagree == 1 && tagree == 1)
  {
    PrintToChatAll("[SM] %t", "Both agree");
    StartFight();
  }
}

// Thanks to FlyingMongoose for the lightning effects.

Lightning()
{
	if (IsClientInGame(winner) && IsPlayerAlive(winner))
	{
		new Float:playerpos[3];
		GetClientAbsOrigin(winner,playerpos);
		new Float:toppos[3];
		toppos[0] = playerpos[0];
		toppos[1] = playerpos[1];
		toppos[2] = playerpos[2]+1000;
		new lightningcolor[4];
		lightningcolor[0] = 255;
		lightningcolor[1] = 255;
		lightningcolor[2] = 255;
		lightningcolor[3] = 255;
		new Float:lightninglife = 0.1;
		new Float:lightningwidth = 40.0;
		new Float:lightningendwidth = 10.0;
		new lightningstartframe = 0;
		new lightningframerate = 20;
		new lightningfadelength = 1;
		new Float:lightningamplitude = 20.0;
		new lightningspeed = 250;
		TE_SetupBeamPoints(toppos, playerpos, g_lightning, g_lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
		TE_SendToAll(0.0);
	}
}

RemoveDroppedWeapons()
{
    new f_Max = GetMaxEntities( );
    decl String:f_EntName[MAX_NAME_LENGTH];

    for(new i = 1; i <= f_Max; i++)
    {
        if(!IsValidEntity(i)
            || !IsValidEdict(i))
            continue;

        f_EntName[0] = '\0';
        
        if(!GetEdictClassname(i, f_EntName, sizeof(f_EntName)))
            continue;

        if(StrContains(f_EntName, "weapon_", false) == -1)
            continue;
        
        if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") == -1)
        {
            RemoveEdict(i);
        }
    }
}