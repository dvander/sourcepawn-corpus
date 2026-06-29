#include <sourcemod>
#include <sdktools>
#include <soundlib>
#include <clientprefs>

#define PLUGIN_VERSION "0.4.1"

public Plugin:dispenser_music =
{
  name = "Dispenser Music",
  author = "Jeremy Rodi",
  description = "Adds music to dispensers.",
  version = PLUGIN_VERSION,
  url = ""
}

new Handle:soundArray;
new Handle:soundLengthArray;
new Handle:entTrie;
new Handle:dispenserCookie;
new soundNumber;

public OnPluginStart()
{

  CreateConVar("sm_dispenser_music_version", PLUGIN_VERSION,
    "The version of the Dispenser Music plugin.", FCVAR_SPONLY | FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED);

  RegAdminCmd("sm_dispenser_music_reload", Command_ReloadDispenserMusic, ADMFLAG_ROOT);
  RegConsoleCmd("sm_dispenser", Command_ToggleDispenser, "Toggles your dispensers playing music.");

  HookEvent("player_builtobject", Event_player_builtobject);
  HookEvent("object_destroyed", Event_object_destroyed, EventHookMode_Pre);
  HookEvent("object_removed", Event_object_destroyed, EventHookMode_Pre);
  HookEvent("player_carryobject", Event_object_destroyed, EventHookMode_Pre);
  soundArray = CreateArray(PLATFORM_MAX_PATH);
  soundLengthArray = CreateArray();
  entTrie = CreateTrie();
  dispenserCookie = RegClientCookie("dispenser music", "Whether or not the dispensers play music.", CookieAccess_Public);
  soundNumber = 0;
}

public OnPluginEnd()
{
  CloseHandle(soundArray);
  CloseHandle(soundLengthArray);
  CloseHandle(entTrie);
  CloseHandle(dispenserCookie);
}

public OnConfigsExecuted()
{
  SetupSounds();
  ClearTrie(entTrie);
}

public Action:Command_ReloadDispenserMusic(client, args)
{
  SetupSounds();

  return Plugin_Handled;
}

public Action:Command_ToggleDispenser(client, args)
{
  decl String:buffer[7];
  GetClientCookie(client, dispenserCookie, buffer, 7);

  if(buffer[0] == '0')
  {
    SetClientCookie(client, dispenserCookie, "1");
    PrintToChat(client, "\x04[\x03dispenser\x04]\x01 Your dispensers will now play music.");
  }
  else
  {
    SetClientCookie(client, dispenserCookie, "0");
    PrintToChat(client, "\x04[\x03dispenser\x04]\x01 Your dispensers will not play music.");
  }

  return Plugin_Handled;
}

SetupSounds()
{
  new Handle:soundKeyValue = CreateKeyValues("dismusic");
  new Handle:soundFile;
  new Float:soundLength;
  decl String:filePath[PLATFORM_MAX_PATH];
  decl String:value[PLATFORM_MAX_PATH];
  decl String:musicDir[PLATFORM_MAX_PATH];
  ClearArray(soundArray);
  ClearArray(soundLengthArray);

  soundNumber = 0;
  BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, "configs/dispenser_music.cfg");

  if(!FileToKeyValues(soundKeyValue, filePath)) {
    SetFailState("Could not load file %s.", filePath);
    return;
  }

  KvJumpToKey(soundKeyValue, "Music");

  if(!KvGotoFirstSubKey(soundKeyValue, false)) {
    SetFailState("No sounds in file %s!", filePath);
    return;
  }

  do {
    KvGetString(soundKeyValue, NULL_STRING, value, PLATFORM_MAX_PATH);
    PushArrayString(soundArray, value);
    musicDir = "sound/";
    StrCat(musicDir, PLATFORM_MAX_PATH, value);


    AddFileToDownloadsTable(musicDir);
    PrecacheSound(value);

    if((soundFile = OpenSoundFile(value)) != INVALID_HANDLE) {
      soundLength = GetSoundLengthFloat(soundFile);
      CloseHandle(soundFile);
    } else {
      soundLength = -1.0;
    }

    PrintToServer("Adding sound %s (length: %f)", value, soundLength);
    PushArrayCell(soundLengthArray, soundLength);

    soundNumber++;
  } while(KvGotoNextKey(soundKeyValue, false))

  CloseHandle(soundKeyValue);

}

public Action:Event_player_builtobject(Handle:event, const String:name[], bool:dontBroadcast)
{

  if(GetEventInt(event, "object") != 0)
    return Plugin_Continue;

  new user   = GetEventInt(event, "userid");
  new client = GetClientOfUserId(user);
  new index  = GetEventInt(event, "index");
  decl String:buffer[7];
  GetClientCookie(client, dispenserCookie, buffer, 7);

  if(buffer[0] == '0')
  {
    return Plugin_Continue;
  }

  decl String:strIndex[7];
  IntToString(index, strIndex, 7);
  SetTrieValue(entTrie, strIndex, false);
  PrintToServer("detected dispenser built.");

  CreateTimer(0.01, Timer_dispenser, index, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
  return Plugin_Continue;
}

public Action:Timer_dispenser(Handle:this, any:ent)
{
  decl String:strIndex[7];
  new v;
  new Handle:timer;
  IntToString(ent, strIndex, 7);

  if(!IsValidEdictType(ent, "obj_dispenser") || GetEntProp(ent, Prop_Send, "m_bPlacing"))
  {
    PrintToServer("Removing sounds for dispenser.");
    RemoveSound(ent);
    RemoveFromTrie(entTrie, strIndex);
    return Plugin_Stop;
  }

  if(GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") == 1.00 &&
     GetTrieValue(entTrie, strIndex, v) && !v)
  {
    /*new Float:position[3];
    new sound = GetRandomInt(0, soundNumber - 1);
    decl String:buf[PLATFORM_MAX_PATH];
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position);
    GetArrayString(soundArray, sound, buf, PLATFORM_MAX_PATH);
    SetTrieValue(entTrie, strIndex, true);
    EmitSoundToAll(buf, ent, SNDCHAN_USER_BASE + 14, SNDLEVEL_NORMAL, SND_NOFLAGS,
      SNDVOL_NORMAL, SNDPITCH_NORMAL, ent, position);*/
    timer = CreateTimer(0.0, Timer_nextSound, ent, TIMER_FLAG_NO_MAPCHANGE);
    SetTrieValue(entTrie, strIndex, timer);

    return Plugin_Stop;
  }

  return Plugin_Continue;
}

public Action:Timer_nextSound(Handle:this, any:index)
{
  new v;
  new sound;
  new Float:soundLength = 0.0;
  new Float:position[3];
  new Handle:timer;
  decl String:strIndex[7];
  decl String:buf[PLATFORM_MAX_PATH];
  IntToString(index, strIndex, 7);

  if(GetTrieValue(entTrie, strIndex, v) && v)
  {
    sound = GetRandomInt(0, soundNumber - 1);
    GetArrayString(soundArray, sound, buf, PLATFORM_MAX_PATH);
    soundLength = Float:GetArrayCell(soundLengthArray, sound);
    PrintToServer("Playing to server %s (length: %f)", buf, soundLength);
    GetEntPropVector(index, Prop_Send, "m_vecOrigin", position);
    EmitSoundToAll(buf, index, SNDCHAN_USER_BASE + 14, SNDLEVEL_NORMAL, SND_NOFLAGS,
      SNDVOL_NORMAL, SNDPITCH_NORMAL, index, position);
    if(soundLength > -1.0)
    { // if we know the kength of the sound

      timer = CreateTimer(soundLength, Timer_nextSound, index, TIMER_FLAG_NO_MAPCHANGE);
      SetTrieValue(entTrie, strIndex, timer);
    } // we can't specify a timer if we don't know the length of the song!

  }

  return Plugin_Stop;
}

RemoveSound(index)
{
  new i = 0;
  new Handle:v;
  decl String:strIndex[7];
  IntToString(index, strIndex, 7);
  if(GetTrieValue(entTrie, strIndex, v) && v)
  {
    KillTimer(v);
  }
  RemoveFromTrie(entTrie, strIndex);

  decl String:buf[PLATFORM_MAX_PATH];

  for(i = 0; i < soundNumber; i++)
  {
    GetArrayString(soundArray, i, buf, PLATFORM_MAX_PATH);
    StopSound(index, SNDCHAN_USER_BASE + 14, buf);
  }
}

IsValidEdictType(edict, String:class[])
{
  if (edict && IsValidEdict(edict))
  {
    decl String:s[64];
    GetEdictClassname(edict, s, 64);
    if (StrEqual(class,s))
      return true;
  }
  return false;
}

public Action:Event_object_destroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
  RemoveSound(GetEventInt(event, "index"));
  return Plugin_Continue;
}

