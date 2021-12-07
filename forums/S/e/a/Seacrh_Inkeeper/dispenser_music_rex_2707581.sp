#include <sourcemod>
#include <sdktools>
#include <soundlib>
#include <clientprefs>

#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

#define PLUGIN_VERSION "1.1.2"

public Plugin:dispenser_music =
{
  name = "Dispenser Music",
  author = "Ordinary Made by Jeremy Rodi, Powered By Увеселитель",
  description = "Adds music to dispensers.",
  version = PLUGIN_VERSION,
  url = "https://forums.alliedmods.net/showthread.php?p=2707581"
}
ConVar sm_dmusic_delay;

Handle soundArray;
Handle soundLengthArray;
Handle entTrie;
Handle dispenserCookie;
int soundNumber;

int abscount;
int clientsMass[128];
int eventsMass[128];
int globallogic;
bool checkmusic;

float DMusicDelay;

public OnPluginStart()
{

	CreateConVar("sm_dispenser_music_rex_version", PLUGIN_VERSION,
	"The version of the Dispenser Music Choice plugin.", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED);

	sm_dmusic_delay = CreateConVar("sm_dmusic_delay", "30.0", "Delay after !dmall in seconds");
	DMusicDelay = 30.0;

	RegAdminCmd("sm_dispenser_music_reload", Command_ReloadDispenserMusic, ADMFLAG_ROOT);
	RegConsoleCmd("sm_dispenser", Command_ToggleDispenser, "Toggles your dispensers playing music.");
	RegAdminCmd("sm_dispmusic", Command_Dispencer, ADMFLAG_RESERVATION, "sm_dispmusic <number>");
	RegAdminCmd("sm_dm", Command_Dispencer, ADMFLAG_RESERVATION, "sm_dm <number>");
	RegAdminCmd("sm_dmtarget", Command_DispencerTarget, ADMFLAG_CHEATS, "sm_dm <client> <number>");
	RegAdminCmd("sm_dmall", Command_DispencerAll, ADMFLAG_CHEATS, "sm_dmall <number>");

	HookEvent("player_builtobject", Event_player_builtobject);
	HookEvent("object_destroyed", Event_object_destroyed, EventHookMode_Pre);
	HookEvent("object_removed", Event_object_destroyed, EventHookMode_Pre);
	HookEvent("player_carryobject", Event_object_destroyed, EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnRoundEnd);
	soundArray = CreateArray(PLATFORM_MAX_PATH);
	soundLengthArray = CreateArray();
	entTrie = CreateTrie();
	dispenserCookie = RegClientCookie("dispenser music", "Whether or not the dispensers play music.", CookieAccess_Public);
	soundNumber = 0;
	abscount = 0;
	for (int i = 0; i < 128; i++)
	{
		eventsMass[i] = -1;
		clientsMass[i] = -1;
	}
	globallogic = 0;
	checkmusic = true;
}

public OnPluginEnd()
{

}

public void OnMapStart()
{
	HookEvent("player_death",				Event_PlayerDeath);
	//CreateTimer(30.0, Timer_LoadCfg, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{

}

public Action Timer_LoadCfg(Handle hTimer)
{
	ServerCommand("exec server.cfg"); //Some plugins (not this one) can't correctly change their CVARs between the maps. This little command fixes it.
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < 128; i++)
	{
		if (eventsMass[i] != -1)
		{
			RemoveSound(eventsMass[i]);
		}
		eventsMass[i] = -1;
		clientsMass[i] = -1;
		//loopMass[i] = false;
	}
	abscount = 0;
	globallogic = 0;
	checkmusic = true;
	DMusicDelay = GetConVarFloat(sm_dmusic_delay);
}

public OnConfigsExecuted()
{
	SetupSounds();
	ClearTrie(entTrie);
}

public Action Command_ReloadDispenserMusic(int client,int args)
{
  SetupSounds();

  return Plugin_Handled;
}

public Action Event_PlayerDeath(Handle hEvent, const char[] sEventName, bool dontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0)	return Plugin_Continue;
	
	int objEvent = -1;
	for (int i = 0; i < 128; i++)
	{
		if (clientsMass[i] == client)
		{
			objEvent = eventsMass[i];
			if (objEvent != -1)
			{
				RemoveSound(eventsMass[i]);				
			}	
		}
	}
	return Plugin_Continue;
}

public Action Command_ToggleDispenser(int client,int args)
{
  char buffer[7];
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
  Handle soundKeyValue = CreateKeyValues("dismusic");
  Handle soundFile;
  float soundLength;
  char filePath[PLATFORM_MAX_PATH];
  char value[PLATFORM_MAX_PATH];
  char musicDir[PLATFORM_MAX_PATH];
  ClearArray(soundArray);
  ClearArray(soundLengthArray);

  soundNumber = 0;
  BuildPath(Path_SM, filePath, PLATFORM_MAX_PATH, "configs/dispenser_music_rex.cfg");

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

	//SetFailState("Error detected in config %s, check empty fields!", filePath);
	
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

public Action Event_player_builtobject(Handle event, const char[] name, bool dontBroadcast)
{

  if(GetEventInt(event, "object") != 0)
    return Plugin_Continue;

  int user   = GetEventInt(event, "userid");
  int client = GetClientOfUserId(user);
  if (!CheckCommandAccess(client, "sm_dmusic_override", 0))
  {
	 PrintToChat(client, "[REX] Get VIP to play music for dispenser!");
	 return Plugin_Handled;
  }
  int index  = GetEventInt(event, "index");
  char buffer[7];
  GetClientCookie(client, dispenserCookie, buffer, 7);

  if(buffer[0] == '0')
  {
    return Plugin_Continue;
  }

  char strIndex[7];
  
  clientsMass[abscount] = client;
  eventsMass[abscount] = index;
  abscount++;
  if (abscount > 127) abscount = 0;
  
  //playingEvent = index;
  //absClient = client;
  IntToString(index, strIndex, 7);
  SetTrieValue(entTrie, strIndex, false);
  PrintToServer("detected dispenser built.");

  CreateTimer(0.01, Timer_dispenser, index, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
  return Plugin_Continue;
}

public Action Timer_dispenser(Handle timer2, any ent)
{
  char strIndex[7];
  int v;
  Handle timer;
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
    char buf[PLATFORM_MAX_PATH];
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

public Action Timer_nextSound(Handle timer2, any index)
{
  int v;
  int sound;
  float soundLength = 0.0;
  float position[3];
  Handle timer;
  char strIndex[7];
  char buf[PLATFORM_MAX_PATH];
  IntToString(index, strIndex, 7);

  if(GetTrieValue(entTrie, strIndex, v) && v)
  {
    sound = GetRandomInt(0, soundNumber - 1);
    GetArrayString(soundArray, sound, buf, PLATFORM_MAX_PATH);
    soundLength = Float:GetArrayCell(soundLengthArray, sound);
    
	if(!IsValidEdictType(index, "obj_dispenser") || GetEntProp(index, Prop_Send, "m_bPlacing"))
	{
		PrintToServer("Failed to play next sound %s (length: %f)", buf, soundLength);
	}
	else
	{
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
  }

  return Plugin_Stop;
}

public Action Command_Dispencer(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[REX] Cant give music to console!");
		return Plugin_Handled;
	}
	if (!(IsPlayerAlive(client)))
	{
		ReplyToCommand(client, "[REX] You must be alive!");
		return Plugin_Handled;
	}
	if (!(TF2_GetPlayerClass(client) == TFClass_Engineer))
	{
		ReplyToCommand(client, "[REX] You must be Engineer!");
		return Plugin_Handled;
	}
	if (args != 1)
	{
		ReplyToCommand(client, "[REX] Usage: sm_dm <number>");
		return Plugin_Handled;
	}
	if (!checkmusic)
	{
		ReplyToCommand(client, "[REX] Someoned used !dmall recently. Just wait some seconds");
		return Plugin_Handled;
	}
	
	char number[50];
	/* Get the arguments */
	GetCmdArg(1, number, sizeof(number));	

	int numbers = StringToInt(number);
	
	if ((numbers > (soundNumber-1)) || (numbers < 0))
	{
		ReplyToCommand(client, "[REX] Invalid number! Playing the last one...");
		numbers = soundNumber-1;
	}
	int objEvent = -1;
	for (int i = 0; i < 128; i++)
	{
		if (clientsMass[i] == client)
		{
			objEvent = eventsMass[i];
			
			if (objEvent > 0)
			{
				RemoveSound(objEvent);
				
				char strIndex[7];
				IntToString(objEvent, strIndex, 7);
				int sound = numbers;

				float soundLength = 0.0;
				float position[3];
				Handle timer;
				char buf[PLATFORM_MAX_PATH];					
				
				GetArrayString(soundArray, sound, buf, PLATFORM_MAX_PATH);
				soundLength = Float:GetArrayCell(soundLengthArray, sound);
				PrintToServer("[REX] Player selected to server %s (length: %f)", buf, soundLength);
				ReplyToCommand(client, "[REX] Turn on...");
				GetEntPropVector(objEvent, Prop_Send, "m_vecOrigin", position);
				EmitSoundToAll(buf, objEvent, SNDCHAN_USER_BASE + 14, SNDLEVEL_NORMAL, SND_NOFLAGS,
				SNDVOL_NORMAL, SNDPITCH_NORMAL, objEvent, position);
				if(soundLength > -1.0)
				{ // if we know the kength of the sound
					timer = CreateTimer(soundLength, Timer_nextSound, objEvent, TIMER_FLAG_NO_MAPCHANGE);
					SetTrieValue(entTrie, strIndex, timer);
				} // we can't specify a timer if we don't know the length of the song!
			}
			
		}
	}
	if(!IsValidEdictType(objEvent, "obj_dispenser") || GetEntProp(objEvent, Prop_Send, "m_bPlacing"))
	{
		ReplyToCommand(client, "[REX] You must build a dispenser!");
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_DispencerTarget(int client, int args)
{

	if (args != 2)
	{
		ReplyToCommand(client, "[REX] Usage: sm_dmtarget #client <number>");
		return Plugin_Handled;
	}
	
	char number[50];
	/* Get the arguments */	

	char sTrgName[MAX_TARGET_LENGTH], sTrg[32];
	int	 aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;
	GetCmdArg(1, sTrg, sizeof(sTrg));

	if((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, COMMAND_FILTER_CONNECTED, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0)
	{	
		ReplyToCommand(client, "[REX] Target doesn't exist!");
		return Plugin_Handled;
	}	
	int targets = aTrgList[0];	
	
	GetCmdArg(2, number, sizeof(number));	

	int numbers = StringToInt(number);
	
	if ((numbers > (soundNumber-1)) || (numbers < 0))
	{
		ReplyToCommand(client, "[REX] Invalid number! Playing the last one...");
		numbers = soundNumber-1;
	}
	
	int objEvent = -1;
	for (int i = 0; i < 128; i++)
	{
		if (clientsMass[i] == targets)
		{
			objEvent = eventsMass[i];
			if (objEvent > 0)
			{
				RemoveSound(objEvent);	
	
				char strIndex[7];
				IntToString(objEvent, strIndex, 7);
				int sound = numbers;

				float soundLength = 0.0;
				float position[3];
				Handle timer;
				char buf[PLATFORM_MAX_PATH];					
				
				GetArrayString(soundArray, sound, buf, PLATFORM_MAX_PATH);
				soundLength = Float:GetArrayCell(soundLengthArray, sound);
				PrintToServer("Admin %L selected for player %L sound %s (length: %f)", client, targets, buf, soundLength);
				ReplyToCommand(client, "[REX] Turn on...");
				GetEntPropVector(objEvent, Prop_Send, "m_vecOrigin", position);
				EmitSoundToAll(buf, objEvent, SNDCHAN_USER_BASE + 14, SNDLEVEL_NORMAL, SND_NOFLAGS,
				SNDVOL_NORMAL, SNDPITCH_NORMAL, objEvent, position);
				if(soundLength > -1.0)
				{ // if we know the kength of the sound
					timer = CreateTimer(soundLength, Timer_nextSound, objEvent, TIMER_FLAG_NO_MAPCHANGE);
					SetTrieValue(entTrie, strIndex, timer);
				} // we can't specify a timer if we don't know the length of the song!
			}
		}
	}	
	
	if(!IsValidEdictType(objEvent, "obj_dispenser") || GetEntProp(objEvent, Prop_Send, "m_bPlacing"))
	{
		ReplyToCommand(client, "[REX] Target has no dispenser!");
		return Plugin_Handled;
	}	
	
	return Plugin_Handled;
}

public Action Command_DispencerAll(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[REX] Usage: sm_dmall <number>");
		return Plugin_Handled;
	}
	
	char number[50];
	/* Get the arguments */
	GetCmdArg(1, number, sizeof(number));	

	int numbers = StringToInt(number);	
	
	if ((numbers > (soundNumber-1)) || (numbers < 0))
	{
		ReplyToCommand(client, "[REX] Invalid number! Playing the last one...");
		numbers = soundNumber-1;
	}	
		
	int objEvent = -1;
	char strIndex[7];
	int sound = numbers;	
	
	float soundLength = 0.0;
	float position[3];
	Handle timer;
	char buf[PLATFORM_MAX_PATH];				
	GetArrayString(soundArray, sound, buf, PLATFORM_MAX_PATH);
	soundLength = Float:GetArrayCell(soundLengthArray, sound);
	for (int i = 0; i < 128; i++)
	{
		if (eventsMass[i] != -1)
		{
			objEvent = eventsMass[i];
			if(!IsValidEdictType(objEvent, "obj_dispenser") || GetEntProp(objEvent, Prop_Send, "m_bPlacing"))
			{
				PrintToServer("[REX] Can't remove sound %s (object: %i)", buf, i);
			}
			else
			{
				RemoveSound(objEvent);
			}
		}
	}
	for (int i = 0; i < 128; i++)
	{
		if (eventsMass[i] != -1)
		{
			objEvent = eventsMass[i];
			IntToString(objEvent, strIndex, 7);	
			
			if(!IsValidEdictType(objEvent, "obj_dispenser") || GetEntProp(objEvent, Prop_Send, "m_bPlacing"))
			{
				PrintToServer("[REX] Cant play sound %s (object: %i)", buf, i);
			}
			else
			{
				PrintToServer("[REX] Admin %L plays sound %s (object: %i)", client, buf, i);			
				GetEntPropVector(objEvent, Prop_Send, "m_vecOrigin", position);
				EmitSoundToAll(buf, objEvent, SNDCHAN_USER_BASE + 14, SNDLEVEL_NORMAL, SND_NOFLAGS,
				SNDVOL_NORMAL, SNDPITCH_NORMAL, objEvent, position);
				if(soundLength > -1.0)
				{ // if we know the kength of the sound
					timer = CreateTimer(soundLength, Timer_nextSound, objEvent, TIMER_FLAG_NO_MAPCHANGE);
					SetTrieValue(entTrie, strIndex, timer);
				} // we can't specify a timer if we don't know the length of the song!
			}
			
		}
	}			
	ReplyToCommand(client, "[REX] Turn on...");
	globallogic++;
	checkmusic = false;
	CreateTimer(DMusicDelay, Timer_GlobalDelay, globallogic, TIMER_FLAG_NO_MAPCHANGE);		
	return Plugin_Handled;
}

public Action Timer_GlobalDelay(Handle hTimer, any checkint)
{
	if (checkint == globallogic) checkmusic = true;
}

RemoveSound(index)
{
  int i = 0;
  Handle v;
  char strIndex[7];
  IntToString(index, strIndex, 7);
  if(GetTrieValue(entTrie, strIndex, v) && v)
  {
    KillTimer(v);
  }
  RemoveFromTrie(entTrie, strIndex);

  char buf[PLATFORM_MAX_PATH];

  for(i = 0; i < soundNumber; i++)
  {
    GetArrayString(soundArray, i, buf, PLATFORM_MAX_PATH);
    StopSound(index, SNDCHAN_USER_BASE + 14, buf);
  }
}

IsValidEdictType(edict, char[] class)
{
  if (edict && IsValidEdict(edict))
  {
    char s[64];
    GetEdictClassname(edict, s, 64);
    if (StrEqual(class,s))
      return true;
  }
  return false;
}

public Action Event_object_destroyed(Handle event, const char[] name, bool dontBroadcast)
{
  int destroyedEvent = GetEventInt(event, "index");
  RemoveSound(destroyedEvent);
  
  for (int i = 0; i < 128; i++)
	{
		if (eventsMass[i] == destroyedEvent)
		{
			eventsMass[i] = -1;
			clientsMass[i] = -1;
			break;
		}
	}
	
  return Plugin_Continue;
}

