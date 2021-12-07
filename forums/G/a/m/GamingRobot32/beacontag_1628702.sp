#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define cDefault				0x01
#define cLightGreen 			0x03
#define cGreen					0x04
#define cDarkGreen  			0x05
#define CHAT_TAG "\x04[BT]\x01"
#define TF_DEATHFLAG_DEADRINGER         (1 << 5)

new current = -1;
new bool:beacon_spawn = false;
new bool:isTF2 = false;
new Handle:c_Enabled   		= INVALID_HANDLE;


new g_BeaconSerial[MAXPLAYERS+1] = { 0, ... };
new Handle:g_Cvar_BeaconRadius = INVALID_HANDLE;
new g_Serial_Gen = 0;
#define SOUND_BLIP		"buttons/blip1.wav"
new g_BeamSprite        = -1;
new g_HaloSprite        = -1;
// Basic color arrays for temp entities
//new redColor[4]		= {255, 75, 75, 255};
new greenColor[4]	= {75, 255, 75, 255};
//new blueColor[4]	= {75, 75, 255, 255};
//new greyColor[4]	= {128, 128, 128, 255};
#define DEFAULT_TIMER_FLAGS TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE
 
public Plugin:myinfo =
{
	name = "Beacon Tag",
	author = "GamingRobot32",
	description = "Play tag with guns",
	version = "1.1.0.0",
	url = "http://www.gamingrobot.net/"
};
 
public OnPluginStart()
{
  LoadTranslations("common.phrases");
  
  decl String:GameType[50];
  GetGameFolderName(GameType, sizeof(GameType));
  
  //PrintToServer("%s IS THE GAMETYPE", GameType);
  
  if (StrEqual(GameType, "tf"))
    isTF2 = true;


  c_Enabled = CreateConVar("sm_beacontag",  "0", "<0/1> Enable Beacon Tag");
  HookConVarChange(c_Enabled, ConVarChange_BTEnabled);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
  HookEvent("player_changeclass", Event_ChangeClass);
  
  if(isTF2)
  {
    HookEvent("teamplay_round_start", Event_RoundStart);
  }
  else
  {
    HookEvent("round_start", Event_RoundStart);
  }
  
  
  RegAdminCmd("sm_btshuffle", Command_BTShuffle, ADMFLAG_SLAY, "sm_btshuffle, pick a random player to be it");
  RegAdminCmd("sm_btpick", Command_BTPick, ADMFLAG_SLAY, "sm_beacon <#userid|name>, pick a player to be it");
  
  g_Cvar_BeaconRadius = CreateConVar("sm_bt_radius", "375", "Sets the radius for beacon tag's light rings.", 0, true, 50.0, true, 1500.0);
}

public ConVarChange_BTEnabled(Handle:convar, const String:oldValue[], const String:newValue[])
{			
	if(StringToInt(newValue) == 1)
	{
		PrintToChatAll("%s Beacon Tag Enabled", CHAT_TAG);
		//Pick random player
    BeaconRandomPlayer(-1);
	}
	else if(StringToInt(newValue) == 0)
	{
		PrintToChatAll("%s Beacon Tag Disabled", CHAT_TAG);
    current = -1;
    beacon_spawn = false;
		//kill all beacons
    KillAllBeacons();
	}
}

public Action:Command_BTShuffle(client, args)
{	
	if (!GetConVarBool(c_Enabled))
	{
		return Plugin_Continue;
	}
  KillBeacon(current);
  ShowActivity2(client, CHAT_TAG, "Shuffling who is it");
  //PrintToChatAll("%c[BT] %cAdmin shuffling who is it!", cGreen, cDefault);
  //BeaconRandomPlayer(-1); 
  CreateTimer(1.0, DelayBeaconRandom);
	return Plugin_Handled;
}

public Action:Command_BTPick(client, args)
{
  if (!GetConVarBool(c_Enabled))
	{
		return Plugin_Continue;
	}
       
	if (args < 1)
	{
		ReplyToCommand(client, "%s Usage: sm_btpick <#userid|name>", CHAT_TAG);
		return Plugin_Handled;
	}
  
	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	if(current != target_list[0])
  {
    KillBeacon(current);
    ShowActivity2(client, CHAT_TAG, "%N Was selected to be it", target_list[0]);
    //PrintToChatAll("[BT] %N Was picked by admin!", target_list[0]);
    PrintToChatAll("%s %N Is it!", CHAT_TAG, target_list[0]);
    Beacon(target_list[0]);
    current = target_list[0];
  }
  else
  {
    ShowActivity2(client, CHAT_TAG, " %N Is already it", target_list[0]);
  }
  
	return Plugin_Handled;
}

public OnMapStart()
{
  g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
  PrecacheSound(SOUND_BLIP, true);
}

public OnMapEnd()
{
  SetConVarInt(FindConVar("sm_beacontag"), 0);
}

public OnClientDisconnect(client)
{
	if(GetConVarBool(c_Enabled))
	{
    if(current == client)
    {
      PrintToChatAll("%s %N Disconnected, Picking new player", CHAT_TAG, client);
      //pick new player
      BeaconRandomPlayer(client);
    }
  }
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(c_Enabled))
	{
		return;
	}
                
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new deathflags = GetEventInt(event, "death_flags");
  
  //PrintToChatAll("[BT] %N Killed %N",attacker, victim);
  //PrintToChatAll("[BT] %d Killed %d",attacker, victim);
  if(isTF2)
    // We dislike spies and invalid client
    if ((deathflags & TF_DEATHFLAG_DEADRINGER) || victim < 1)
    {
      return;
    }
  else
  {
    if (victim < 1)
    {
      return;
    } 
  }
 
  if (current == victim)
  {
    KillBeacon(victim);

    if (attacker != victim && attacker > 0)
    {
      if (IsPlayerAlive(attacker))
      {
        PrintToChatAll("%s %N Is now it!", CHAT_TAG, attacker);

        current = attacker;
        Beacon(current);    
      }
      else
      {
        current = attacker;
        beacon_spawn = true;
      }
    }
    else
    {
      // Player suicided or something - beacon a new player!
      BeaconRandomPlayer(current);
    }
  }
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(GetConVarBool(c_Enabled))
	{
    new spawn = GetClientOfUserId(GetEventInt(event, "userid"));
    if(beacon_spawn && current == spawn)
    {
      //PrintToChatAll("[BT] %N Spawned!", spawn);
      PrintToChatAll("%s %N Is it!", CHAT_TAG, spawn);

      beacon_spawn = false;
      //beacon player
      //Beacon(spawn);	
      CreateTimer(1.0, DelayBeacon, spawn);
    }
    else if(current == -1)
    {
     BeaconRandomPlayer(-1);
    
    }
  }
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(GetConVarBool(c_Enabled))
	{
    KillAllBeacons();
    //PrintToChatAll("[BT] New Round, Picking new player");
    CreateTimer(1.0, DelayBeaconRandom);
    //BeaconRandomPlayer(-1);
  }
}

public Event_ChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
  if(GetConVarBool(c_Enabled))
	{
    new player = GetClientOfUserId(GetEventInt(event, "userid"));
    KillBeacon(player);
    if(current == player)
    {
      //PrintToChatAll("[BT] %N Changed Class", player);
      //change_class = true;
      CreateTimer(1.0, DelayBeacon, player);
      //beacon player
      //Beacon(player);	
    }
  }
}


public Action:DelayBeacon(Handle:timer, any:client)
{
  Beacon(client);
}

public Action:DelayBeaconRandom(Handle:timer)
{
  BeaconRandomPlayer(-1);
}

BeaconRandomPlayer(oldplayer)
{
	new arrayPlayers[MaxClients];
	new index = 0;
	
	for(new i=1; i<MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
    {
      if(IsPlayerAlive(i) && oldplayer != i)
      {
        arrayPlayers[index] = i;
        index++;
      }
    }
	}
    
	//PrintToChatAll("[KT] RandomPlayer Index is %d", index);
	if(index > 0)
	{
		new victim = arrayPlayers[GetRandomInt(0, index-1)];
    //PrintToChatAll("[BT] %N Randomly Picked", victim);
    PrintToChatAll("%s %N Is now it!", CHAT_TAG, victim);

    current = victim;
		Beacon(victim);	
	}
  else
  {	
    PrintToChatAll("%s Everyone is dead, Waiting for someone to spawn", CHAT_TAG);   
    current = -1;
	}
}


Beacon(client)
{
	g_BeaconSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_Beacon, client | (g_Serial_Gen << 7), DEFAULT_TIMER_FLAGS);	
}

KillBeacon(client)
{
	g_BeaconSerial[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

KillAllBeacons()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		KillBeacon(i);
	}
}

public Action:Timer_Beacon(Handle:timer, any:value)
{
	new client = value & 0x7f;
	new serial = value >> 7;

	if (!IsClientInGame(client)
		|| !IsPlayerAlive(client)
		|| g_BeaconSerial[client] != serial)
	{
		KillBeacon(client);
		return Plugin_Stop;
	}
	
	//new team = GetClientTeam(client);

	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greenColor, 10, 0);
	TE_SendToAll();
	
	/*if (team == 2)
	{
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
	}
	else if (team == 3)
	{
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, blueColor, 10, 0);
	}
	else
	{
		TE_SetupBeamRingPoint(vec, 10.0, GetConVarFloat(g_Cvar_BeaconRadius), g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, greenColor, 10, 0);
	}*/
	
	//TE_SendToAll();
		
	GetClientEyePosition(client, vec);
	EmitAmbientSound(SOUND_BLIP, vec, client, SNDLEVEL_RAIDSIREN);	
		
	return Plugin_Continue;
}