#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

#define SOUND_KILL		 "weapons/knife/knife_hitwall1.wav"
#define SOUND_HEARTBEAT	 "player/heartbeatloop.wav"

#define INCAP			 1
#define INCAP_GRAB		 2
#define INCAP_POUNCE	 4
#define INCAP_EDGEGRAB	 8

#define TEAM_SURVIVOR	2
#define TEAM_INFECTED	3

#define GAMEMODE_COOP		1
#define GAMEMODE_VERSUS		2
#define GAMEMODE_SURVIVAL	3

#define FLAGS_SURVIVOR	1
#define FLAGS_INFECTED	2
#define FLAGS_ALIVE		4
#define FLAGS_DEAD		8

#define	LIFE_ALIVE		0

char LOSTCALLDIR[5][64] = 
{
	"sound/player/survivor/voice/namvet", 
	"sound/player/survivor/voice/teengirl",
	"sound/player/survivor/voice/biker",
	"sound/player/survivor/voice/manager",
	""
};

char LOSTCALLSOUNDS[5][64] = 
{
	"player/survivor/voice/namvet", 
	"player/survivor/voice/teengirl",
	"player/survivor/voice/biker",
	"player/survivor/voice/manager",
	""
};

int empty[MAXPLAYERS+1]; // empty var for cleaning purposes.

//bool	g_bFirstHumanCheck = false;
bool	g_bMissionStarted = false;
int 	g_Attacker[MAXPLAYERS+1];
int 	g_IncapType[MAXPLAYERS+1];
int 	g_NeedMedkits[MAXPLAYERS+1];
int 	g_iGameMode;
int		g_Inmunity[MAXPLAYERS+1];
int		g_default_DirectorNoDeathCheck;
int		g_default_DirectorNoSurvivorBots;
float	g_fClosest_teammate[MAXPLAYERS+1];
Handle	g_hTimers[MAXPLAYERS+1];

Handle 	l4d1_lastman_enabled;
Handle 	l4d1_lastman_smoker_revive;
Handle 	l4d1_lastman_hunter_revive;
Handle 	l4d1_lastman_no_starting_bots;
Handle 	l4d1_lastman_force_kick_bots;
Handle  l4d1_lastman_kill_attacker;
Handle 	l4d1_lastman_inmunity = INVALID_HANDLE;
Handle 	l4d1_lastman_revive_health = INVALID_HANDLE;
Handle 	l4d1_lastman_no_pipe_bombs = INVALID_HANDLE;
Handle 	l4d1_lastman_vocalize = INVALID_HANDLE;
Handle 	g_hNoDeathCheck = INVALID_HANDLE;

char	g_strLostcall[5][16][256];
int		g_intLostcall[5];

public Plugin myinfo =
{
	name = "The Last Man On Earth",
	author = "Axel Juan Nieves",
	description = "Simulates L4D2's mutation called The Last Man On Earth",
	version = PLUGIN_VERSION,
}

public void OnConfigsExecuted()
{
	//store default values. This is needed if the admin want to remove/disable this plugin and doesnt want to loose his default values...
	g_default_DirectorNoDeathCheck = GetConVarInt(FindConVar("director_no_death_check"));
	g_default_DirectorNoSurvivorBots = GetConVarInt(FindConVar("director_no_survivor_bots"));
}

public void OnPluginEnd()
{
	SetConVarInt(FindConVar("director_no_death_check"), g_default_DirectorNoDeathCheck);
	SetConVarInt(FindConVar("director_no_survivor_bots"), g_default_DirectorNoSurvivorBots);
}

public void OnPluginStart()
{
	//Require Left 4 Dead 1:
	char GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if ( !StrEqual(GameName, "left4dead", false) )
		SetFailState("Plugin supports Left 4 Dead 1 only. L4D2 has already these features.");
	GameCheck();
	
	//create convars:
	CreateConVar("l4d1_lastman_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	l4d1_lastman_enabled = CreateConVar("l4d1_lastman_enabled", "1", "Enable/Disable this plugin. 0:disable, 1:enable", 0);
	l4d1_lastman_smoker_revive = CreateConVar("l4d1_lastman_smoker_revive", "1", "Get a second chance against Smoker incap. 0:disable, 1:enable", 0);
	l4d1_lastman_hunter_revive = CreateConVar("l4d1_lastman_hunter_revive", "1", "Get a second chance against Hunter incap. 0:disable, 1:enable", 0);
	l4d1_lastman_no_starting_bots = CreateConVar("l4d1_lastman_no_starting_bots", "1", "Remove bots on map starting. 0:disable, 1:enable", 0);
	l4d1_lastman_force_kick_bots = CreateConVar("l4d1_lastman_force_kick_bots", "0", "Automatically kick any bot trying to join at any moment. 0: disable, 1:enable", 0);
	l4d1_lastman_kill_attacker = CreateConVar("l4d1_lastman_kill_attacker", "0", "Kill the attacker when reviving. 0:disable, 1:enable", 0);
	l4d1_lastman_inmunity = CreateConVar("l4d1_lastman_inmunity", "4", "Inmunity (in seconds) to special attacks after getting free from a boss.", 0, true, 0.0, true, 15.0);
	l4d1_lastman_revive_health = CreateConVar("l4d1_lastman_revive_health", "40", "Temporal health after reviving.", 0, true, 1.0, true, 300.0);
	l4d1_lastman_no_pipe_bombs = CreateConVar("l4d1_lastman_no_pipe_bombs", "1", "Converts all pipe-bombs to medkits or molotovs.", 0);
	l4d1_lastman_vocalize = CreateConVar("l4d1_lastman_vocalize", "30.0", "Lets player vocalize L4D2's lostcall when alone or too far from other players.", 0);
	g_hNoDeathCheck = FindConVar("director_no_death_check");
	
	AutoExecConfig(true, "l4d1_lastmanonearth");
	
	//set survivor bots:
	if ( GetConVarInt(l4d1_lastman_no_starting_bots) )
		SetConVarInt(FindConVar("director_no_survivor_bots"), 1);
	
	//disable no-death check:
	SetConVarInt(g_hNoDeathCheck, 0);
	
	HookEvent("player_incapacitated", event_player_incapacitated, EventHookMode_Pre);
	HookEvent("lunge_pounce", event_lunge_pounce);
	HookEvent("pounce_stopped", event_pounce_stopped);
	HookEvent("tongue_grab", event_tongue_grab);
	HookEvent("tongue_release", event_tongue_release);
	HookEvent("player_death", event_player_death, EventHookMode_Post);
	HookEvent("player_hurt",  event_player_hurt);
	HookEvent("heal_success", event_heal_success);
	//HookEvent("round_start", event_round_start, EventHookMode_PostNoCopy);
	HookEvent("round_end", event_round_end, EventHookMode_PostNoCopy);
	HookEvent("finale_start", event_finale_start, EventHookMode_Pre);
	HookEvent("player_bot_replace", event_player_bot_replace, EventHookMode_Post);
	HookEvent("player_spawn", event_player_spawn, EventHookMode_Post);
	
	HookConVarChange(g_hNoDeathCheck, noDeathCheck);
	HookConVarChange(l4d1_lastman_vocalize, ConVarVocalizeLostCall);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if	( !IsValidEdict(entity) ) return;
	char modelname[255];
	GetEdictClassname(entity, modelname, 64);
	if  ( StrEqual(classname, "infected") )
	{
		SDKHook(entity, SDKHook_SpawnPost, remove_infected);
		//PrintToServer( "removing: %s", classname );
	}
	//else
	//PrintToChatAll( "nothing found: %s", classname );
	return;
}

public Action remove_infected(int entity, int classname)
{
	if (!IsValidEntity(entity))
	{
		//PrintToServer("Error during entity deleting. Invalid entity: %i", entity);
		return Plugin_Continue;
	}
	AcceptEntityInput(entity, "Kill"); //remove common infecteds.
	
	//char test[128]; //debug
	//GetEntPropString(entity, Prop_Data, "m_ModelName", test, sizeof(test)); //debug
	//PrintToChatAll("Removing: %s", test); //debug
	return  Plugin_Changed;
}

public Action timed_MoreMedkits(Handle timer, int client)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return Plugin_Continue;
	if ( !IsClientInGame(client) ) return Plugin_Continue;
	if ( !IsPlayerAlive(client) ) return Plugin_Continue;
	if ( GetClientTeam(client)!=TEAM_SURVIVOR ) return Plugin_Continue;
	
	if ( g_NeedMedkits[client]==0 ) return Plugin_Stop;
	if ( GetPlayerWeaponSlot(client, 3)!=-1 && GetClientHealth(client)>50)
	{
		g_NeedMedkits[client] = 0;
		return Plugin_Stop;
	}
	
	MoreMedkits(client);
	return Plugin_Continue;
}

void MoreMedkits(int client)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return;
	if ( !IsClientInGame(client) ) return;
	if ( !IsPlayerAlive(client) ) return;
	if ( GetClientTeam(client)!=TEAM_SURVIVOR ) return;
	
	int NearestItem = -1;
	float ClientLocation[3];
	float ItemLocation[3];
	float NearestItemLocation[3];
	float ItemAngle[3];
	int EntityCount = GetEntityCount();
	char EdictClassName[128];
	
	//this will get every weapon/item on the map, but we need only the nearest one...
	for (int item = -1; item <= EntityCount; item++)
	{
		if (!IsValidEntity(item)) continue;
		
		GetEdictClassname(item, EdictClassName, sizeof(EdictClassName));
		
		//convert only pistols, pills, molotovs and pipe bombs (if present) to medkits...
		if (StrContains(EdictClassName, "weapon_pain_pills", false)==0) {}
		else if (StrContains(EdictClassName, "weapon_pipe_bomb", false)==0) {}
		else if (StrContains(EdictClassName, "weapon_molotov", false)==0) {}
		else if (StrContains(EdictClassName, "weapon_pistol", false)==0) {}
		else if (StrContains(EdictClassName, "weapon_first_aid_kit", false)==0) {} //this is needed  to prevent creating more medkits if you are closer to one.
		else 
		{
			continue;
		}
		
		//get item position...
		GetEntPropVector(item, Prop_Send, "m_vecOrigin", ItemLocation);
		
		//get client position...
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientLocation);
		
		//don't convert far away items...
		if (GetVectorDistance(ClientLocation, ItemLocation, false) > 600)
			continue;
		
		if (NearestItemLocation[0]+NearestItemLocation[1]+NearestItemLocation[2] == 0)
		{
			NearestItemLocation = ItemLocation;
		}
		
		//if current item is not closest that previous one, dont convert to medkit...
		if ( GetVectorDistance(ClientLocation, ItemLocation, false) > GetVectorDistance(ClientLocation, NearestItemLocation, false) )
			continue;
		
		//if you are closer to a medkit, stop creating more medkits...
		if (StrContains(EdictClassName, "weapon_first_aid_kit", false)==0) return; 
		
		NearestItem = item;
		NearestItemLocation = ItemLocation;
	}
	
	if (NearestItem != -1)
	{
		int Medkit = CreateEntityByName("weapon_first_aid_kit_spawn");
		if (Medkit==-1) return;
		GetEntPropVector(NearestItem, Prop_Send, "m_angRotation", ItemAngle);
		GetEdictClassname(NearestItem, EdictClassName, sizeof(EdictClassName));
		TeleportEntity(Medkit, NearestItemLocation, ItemAngle, NULL_VECTOR);
		AcceptEntityInput(NearestItem, "Kill"); //remove found item.
		DispatchSpawn(Medkit); //spawn a medkit.
	}
}

void NoPipeBombs()
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return;
	
	float ItemLocation[3];
	float ItemAngle[3];
	int EntityCount = GetEntityCount();
	char EdictClassName[128];
	int replacementItem = -1;
	
	//scan for pipe bombs at starting...
	for (int pipe_bomb = -1; pipe_bomb <= EntityCount; pipe_bomb++)
	{
		if (!IsValidEntity(pipe_bomb)) continue;
		
		GetEdictClassname(pipe_bomb, EdictClassName, sizeof(EdictClassName));
		
		if (StrContains(EdictClassName, "weapon_pipe_bomb", false)!=0)
			continue;
		
		//get pipe_bomb position...
		GetEntPropVector(pipe_bomb, Prop_Send, "m_vecOrigin", ItemLocation);
		if ( GetRandomInt(0,2) ) // there are 2/3 probabilities to find medkit instead pipe pipe_bomb.
			replacementItem = CreateEntityByName("weapon_first_aid_kit_spawn");
		else //there are 1/3 probabilities to find molotov instead pipe pipe_bomb.
			replacementItem = CreateEntityByName("weapon_molotov");
		if ( replacementItem==-1 ) //if something weird happens, stop at this point.
			continue;
		TeleportEntity(replacementItem, ItemLocation, ItemAngle, NULL_VECTOR);
		AcceptEntityInput(pipe_bomb, "Kill"); //remove pipe pipe_bomb.
		DispatchSpawn(replacementItem); //spawn a replacement.
	}
}

public void noDeathCheck(Handle convar, const char[] oldValue, const char[] newValue)
{
	if ( g_bMissionStarted==true)
		SetConVarInt(g_hNoDeathCheck, 1);
	
	else
		SetConVarInt(g_hNoDeathCheck, 0);
}

public void ConVarVocalizeLostCall(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return;
	
	for (int client=1; client<=MaxClients; client++)
	{
		if (!IsValidClientInGame(client)) continue;
		if (GetClientTeam(client)!=TEAM_SURVIVOR) continue;
		if (!IsPlayerAlive(client)) continue;
		
		//new vocalize's timer:
		if (g_hTimers[client])
		{
			KillTimer(g_hTimers[client], true);
			g_hTimers[client] = CreateTimer(GetConVarFloat(l4d1_lastman_vocalize), VocalizeLostCall, client, TIMER_REPEAT);
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return;
	
	//allow clients to mid-game join...
	if ( !IsFakeClient(client) )
	{
		DispatchSpawn(client);
	}
}

public void OnClientDisconnect_Post(int client)
{
	if (!IsValidClientInGame(client)) return;
	
	//stop vocalize's timer:
	if (g_hTimers[client])
	{
		KillTimer(g_hTimers[client], true);
		g_hTimers[client] = INVALID_HANDLE;
	}
}

/*public void OnClientPutInServer(int client)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return;
	
	//we need the first human player joins the server...
	if ( !IsFakeClient(client) )
	{
		//delay starting bots kicking...
		if ( GetConVarInt(l4d1_lastman_no_starting_bots) && !g_bFirstHumanCheck )
		{
			g_bFirstHumanCheck = true;
			//Kick any third-party bot...
			CreateTimer(0.1, KickStartingBots, _, TIMER_REPEAT);
		}
	}
	else if ( GetConVarInt(l4d1_lastman_force_kick_bots) && GetClientTeam(client)==TEAM_SURVIVOR )
	{
		KickClientEx(client); //kick any bot trying to join anytime.
	}
}*/

public void OnMapStart()
{
	PrecacheSound(SOUND_KILL, true);
	PrecacheSound(SOUND_HEARTBEAT, true);
	
	//prevent all-dead bug by setting director_no_death_check to 1 before round starting...
	SetConVarInt(g_hNoDeathCheck, 0);
	PrecacheLostCallSounds();
}

//this is needed for playing THE SACRIFICE alone...
public Action event_finale_start(Handle event, const char[] name, bool dontBroadcast)
{
	char map[32];
	GetCurrentMap(map, sizeof(map));
	if ( StrEqual(map, "l4d_river03_port", false) )
	{
		SetConVarInt(g_hNoDeathCheck, 1);
	}
}

void PrecacheLostCallSounds()
{
	int count;
	Handle dir;
	char filename[64];
	char fullpath[256];
	for (int survivor=0; survivor<=3; survivor++)
	{
		dir = OpenDirectory(LOSTCALLDIR[survivor]);
		count = 0;
		
		if (!dir)
		{
			PrintToServer("[L4D1 LAST MAN ON EARTH] Error: Failed OpenDir LOSTCALLDIR[survivor=%i]=%s", survivor, LOSTCALLDIR[survivor]);
			continue;
		}
		while (ReadDirEntry(dir, filename, sizeof(filename))!=false)
		{
			if ( StrContains(filename, "lostcall", false)==-1 ) continue;
			
			if (count >= 16) break; //we have a limit of 15 files maximum per survivor.
			
			g_intLostcall[survivor] = count; //here we will store how many result were found for future randomize.
			FormatEx(fullpath, sizeof(fullpath), "%s/%s", LOSTCALLSOUNDS[survivor], filename);
			FormatEx(g_strLostcall[survivor][count], 255, fullpath);
			//g_strLostcall[survivor][count] = fullpath;
			PrintToServer("[L4D1 LAST MAN ON EARTH] Info: PRECACHING: %s)", fullpath);
			PrecacheSound(fullpath);
			count++;
		}
	}
}

public Action VocalizeLostCall(Handle timer, int client)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return Plugin_Stop;
	if ( !IsValidClientInGame(client) ) return Plugin_Stop;
	if (GetConVarFloat(l4d1_lastman_vocalize)==0.0) 
	{
		//stop vocalize's timer:
		if (g_hTimers[client])
		{
			KillTimer(g_hTimers[client], true);
			g_hTimers[client] = INVALID_HANDLE;
		}
		return Plugin_Stop;
	}
	
	if ( !IsPlayerAlive(client) ) 
	{
		//stop vocalize's timer:
		if (g_hTimers[client])
		{
			KillTimer(g_hTimers[client], true);
			g_hTimers[client] = INVALID_HANDLE;
		}
		return Plugin_Continue;
	}
	
	int survivor = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	int random_int;
	
	//if client is alone or the last standing man, vocalize LostCall:
	if ( GetHumanPlayersCount(FLAGS_SURVIVOR|FLAGS_ALIVE)==1 )
	{
		random_int = GetRandomInt(0, g_intLostcall[survivor]-1 );
		//PrintToChatAll("Max Files found for current survivor: %i", g_intLostcall[survivor]); //debug
		//PrintToChatAll("Emittin sound (alone): %s RANDOMINT(%i)", g_strLostcall[survivor][random_int], random_int); //debug
		EmitSoundToClient( client, g_strLostcall[survivor][random_int] );
		return Plugin_Continue;
	}
	
	float client_pos[3], i_pos[3], distance;
	GetClientAbsOrigin(client, client_pos);
	
	//we need to get the closest alive teammate. If he is too far, vocalize LostCall:
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsValidClientInGame(i)) continue;
		if ( GetClientTeam(i)!=TEAM_SURVIVOR ) continue;
			
		GetClientAbsOrigin(i, i_pos);
		distance = GetVectorDistance(client_pos, i_pos);
		if (g_fClosest_teammate[client]==0.0)
			g_fClosest_teammate[client] = distance;
		
		if ( distance < g_fClosest_teammate[client] )
			g_fClosest_teammate[client] = distance;
	}
	
	if (g_fClosest_teammate[client] >= 3000.0)
	{
		random_int = GetRandomInt(0, g_intLostcall[ GetEntProp(client, Prop_Send, "m_survivorCharacter") ] - 1 );
		//PrintToChatAll("Emittin sound (not alone): %s", g_strLostcall[survivor][random_int]); //debug
		EmitSoundToClient( client, g_strLostcall[survivor][random_int] );
	}
	return Plugin_Continue;
}

public Action event_round_end(Handle event, const char[] name, bool dontBroadcast)
{
	//we have to wait at least 7 seconds before setting no_death_check to 1.
	CreateTimer(7.0, timed_reset);
	
	//we need to clean this var as soon as possible...
	g_NeedMedkits = empty;
	
	//prevent all-dead bug...
	SetConVarInt(g_hNoDeathCheck, 0);
	
	return Plugin_Continue;
}

public Action event_player_bot_replace(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarInt(l4d1_lastman_enabled) ) return Plugin_Continue;
	if ( GetConVarInt(l4d1_lastman_no_starting_bots) || GetConVarInt(l4d1_lastman_force_kick_bots) )
	{
		int bot = GetClientOfUserId(GetEventInt(event, "bot"));
		if (IsValidClientInGame(bot))
		{
			//stop vocalize's timer (if any)...
			if ( g_hTimers[bot] )
			{
				KillTimer(g_hTimers[bot], true);
				g_hTimers[bot] = INVALID_HANDLE;
			}
			KickClientEx(bot); //kick bot when a player leaves server
		}
	}
	return Plugin_Continue;
}

public Action event_player_spawn(Handle event, const char[] name, bool dontBroadcast)
{
	if ( !GetConVarInt(l4d1_lastman_enabled) ) return Plugin_Continue;
	if ( GetConVarFloat(l4d1_lastman_vocalize)==0.0 ) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if ( GetClientTeam(client)!=TEAM_SURVIVOR ) return Plugin_Continue;
	
	if ( GetConVarInt(l4d1_lastman_force_kick_bots) && IsFakeClient(client) )
	{
		//stop vocalize's timer (if any)...
		if ( g_hTimers[client] )
		{
			KillTimer(g_hTimers[client], true);
			g_hTimers[client] = INVALID_HANDLE;
		}
		KickClientEx(client);
	}
	
	if (!g_hTimers[client])
		g_hTimers[client] = CreateTimer(GetConVarFloat(l4d1_lastman_vocalize), VocalizeLostCall, client, TIMER_REPEAT);
	return Plugin_Continue;
}

/*public Action KickStartingBots(Handle timer)
{
	if ( !GetConVarInt(l4d1_lastman_enabled) ) return Plugin_Stop;
	if ( !GetConVarInt(l4d1_lastman_no_starting_bots) ) return Plugin_Stop;
	static float secondsPassed = 0.0;
	static float lastKicked = 0.0;
	static char buffer[8];
	
	//we will keep trying to kick starting bots for 10 seconds...
	if (secondsPassed >= 10.0) 
	{
		secondsPassed = 0.0;
		return Plugin_Stop;
	}
	
	//but if 3 seconds passed since last bot was kicked, we will stop.
	if ( (secondsPassed-lastKicked) >= 3.0 )
	{
		secondsPassed = 0.0;
		lastKicked = 0.0;
		FloatToString((secondsPassed-lastKicked), buffer, 7);
		return Plugin_Stop;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client)) continue;
		if (!IsFakeClient(client)) 
		{
			continue;
		}
		if ( GetClientTeam(client)==TEAM_INFECTED ) continue; //dont kick infected bots!
		
		lastKicked = secondsPassed;
		KickClientEx(client);
	}
	secondsPassed+=0.1;
	return Plugin_Continue;
}*/

//hunter's incap start...
public Action event_lunge_pounce(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return Plugin_Continue;
	if (!GetConVarInt(l4d1_lastman_hunter_revive)) return Plugin_Continue;
	if (g_iGameMode==GAMEMODE_VERSUS) return Plugin_Continue;
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return Plugin_Continue;
	if (!attacker) return Plugin_Continue;
	
	g_Attacker[victim] = attacker;
	g_IncapType[victim] = INCAP_POUNCE;
	
	check_inmunity(victim);
	return Plugin_Continue;
}

//hunter stopped pounce...
public Action event_pounce_stopped(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return Plugin_Continue;
	if (g_iGameMode==GAMEMODE_VERSUS) return Plugin_Continue;
	int victim = GetClientOfUserId(GetEventInt(event, "victim")); //survivor player
	if (!victim) return Plugin_Continue;
	g_Attacker[victim] = 0;
	g_IncapType[victim] = 0;
	return Plugin_Continue;
}

//smoker grabbed someone...
public Action event_tongue_grab(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return Plugin_Continue;
	if (!GetConVarInt(l4d1_lastman_smoker_revive)) return Plugin_Continue;
	if (g_iGameMode==GAMEMODE_VERSUS) return Plugin_Continue;
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return Plugin_Continue;
	if (!attacker) return Plugin_Continue;
	
	g_Attacker[victim] = attacker;
	g_IncapType[victim]=INCAP_GRAB;
	
	//temporal inmunity from smokers if we just revived (alternative notarget)...
	check_inmunity(victim);
	return Plugin_Continue;
}

//smoker released someone...
public Action event_tongue_release(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return Plugin_Continue;
	if (g_iGameMode==GAMEMODE_VERSUS) return Plugin_Continue;
	int victim = GetClientOfUserId(GetEventInt(event, "victim"));
	int smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return Plugin_Continue;
	if (!smoker) return Plugin_Continue;
	
	//we need to check this because hunters can steal victims to smokers...
	if(g_Attacker[victim] == smoker)
	{
			g_Attacker[victim] = 0;
			g_IncapType[victim] = 0;
	}
	return Plugin_Continue;
}

public Action event_player_incapacitated(Handle event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return Plugin_Continue;
	if (g_iGameMode==GAMEMODE_VERSUS) return Plugin_Continue;
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( GetClientTeam(victim)!=TEAM_SURVIVOR ) return Plugin_Continue;
	int MaxIncaps = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	//g_IncapType[victim]=INCAP;
	
	//if victim is b&w and then is incaped, allow die.
	if ( GetEntProp(victim, Prop_Send, "m_isGoingToDie") )
	{
		SetConVarInt(g_hNoDeathCheck, 0);
		return Plugin_Continue;
	}
	
	//check if incapped by hunter or smoker...
	if ( (INCAP_GRAB|INCAP_POUNCE)&g_IncapType[victim] )
	{
		//check if already black and white. If so, dont get free:
		if ( GetEntProp(victim, Prop_Send, "m_currentReviveCount") == MaxIncaps )
		{
			SetConVarInt(g_hNoDeathCheck, 0);
			return Plugin_Continue;
		}
		
		//get free from attacker...
		if (GetConVarInt(l4d1_lastman_kill_attacker)) KillAttacker(victim);
		else ShoveAttacker(victim);
		
		//remove attacker references...
		g_Attacker[victim] = 0;
		g_IncapType[victim] = 0;
		
		//revive victim black and white...
		ReviveClient(victim);
		
		//set temporal inmunity:
		float  fInmunity = GetConVarFloat(l4d1_lastman_inmunity);
		if (fInmunity > 0.0)
		{
			CreateTimer(fInmunity, removeInmunity, victim);
			g_Inmunity[victim] = 1;
		}
	}
	//incaped by other reasons...
	else 
	{
		//revive victim black and white...
		ReviveClient(victim);
	}
	return  Plugin_Continue;
}

public Action event_heal_success(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_iGameMode==GAMEMODE_VERSUS) return Plugin_Continue;
	int client = GetClientOfUserId(GetEventInt(event,"subject"));
	//int healer = GetClientOfUserId(GetEventInt(event,"userid"));
	if (client <= 0 || client > MaxClients) return Plugin_Continue;
	
	//disable black and white:
	SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
	
	//stop heartbeat:
	StopSound(client, SNDCHAN_AUTO, SOUND_HEARTBEAT);
	return Plugin_Continue;
}

public Action event_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsValidClientInGame(client) ) return Plugin_Continue;
	if ( (GetClientTeam(client)!=TEAM_SURVIVOR) ) return Plugin_Continue;
	
	//stop heartbeat:
	StopSound(client, SNDCHAN_AUTO, SOUND_HEARTBEAT);
	
	//stop vocalize's timer:
	if (g_hTimers[client])
	{
		KillTimer(g_hTimers[client], true);
		g_hTimers[client] = INVALID_HANDLE;
	}
	
	//custom death check, which allow to play alone at The Sacrifice finale:
	//extra: it allows you to use self-help script when you get incapped and you are the last standing man, and you have pills.
	int players = 0;
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (GetClientTeam(i)!=TEAM_SURVIVOR) continue;
		if (!IsPlayerAlive(i)) continue;
		players++;
	}
	if ( players>=1 )
		return Plugin_Continue;
	
	//PrintToChatAll("All players dead.");
	g_bMissionStarted = false;
	
	//force round_end...
	int round_end = CreateEntityByName("game_end");
	
	if ( round_end!=-1 )
		DispatchSpawn(round_end);
	//ServerExecuteCmd("endround");
	SetConVarInt(g_hNoDeathCheck, 0);
	
	return Plugin_Continue;
}

public Action event_player_hurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsClientInGame(client) ) return Plugin_Continue;
	if ( !IsPlayerAlive(client) ) return Plugin_Continue;
	if ( GetClientTeam(client)!=TEAM_SURVIVOR ) return Plugin_Continue;
	if ( g_NeedMedkits[client]==1 ) return Plugin_Continue;
	
	//start spawning medkits nearby...
	if ( GetClientHealth(client)<=50 || GetPlayerWeaponSlot(client, 3)<1 )
	{
		g_NeedMedkits[client] = 1;
		CreateTimer(1.0, timed_MoreMedkits, client, TIMER_REPEAT);
	}
	return Plugin_Continue;
}

void ReviveClient(int client)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return;
	
	//Method 1:
	int flagsgive = GetCommandFlags("give");
	SetCommandFlags("give", flagsgive & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", "health");
	SetCommandFlags("give", flagsgive|FCVAR_CHEAT);
	
	/*//remove incapacitation:
	SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
	ClientCommand(client, "music_dynamic_stop_playing %s", "Event.Down"); //stop incap music1
	ClientCommand(client, "music_dynamic_stop_playing %s", "Event.DownHit"); //stop incap music2*/
	
	//set temporal health:
	int tempHpOffset = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
	float tempHealth = GetConVarFloat(l4d1_lastman_revive_health);
	SetEntDataFloat(client, tempHpOffset, tempHealth, true); //make sure it's greater or equal than 1
	
	//set permanent health to 1:
	SetEntProp(client, Prop_Send, "m_iHealth", 1);
	
	//set the players' incap count:
	int MaxIncaps = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	SetEntProp(client, Prop_Send, "m_currentReviveCount", MaxIncaps);
	
	//set black and white:
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
	
	//heartbeat sound:
	EmitSoundToClient(client, "player/heartbeatloop.wav");
	
	//stop incapacitation's musics...
	ClientCommand(client, "music_dynamic_stop_playing %s", "Event.HunterHit");
	ClientCommand(client, "music_dynamic_stop_playing %s", "Event.HunterPounce");
	ClientCommand(client, "music_dynamic_stop_playing %s", "Event.SmokerDrag");
	ClientCommand(client, "music_dynamic_stop_playing %s", "Event.SmokerChoke");
	ClientCommand(client, "music_dynamic_stop_playing %s", "Event.DownHit");
}

void KillAttacker(int victim)
{
	if (!GetConVarInt(l4d1_lastman_enabled)) return;
	int attacker=g_Attacker[victim];
	if (!attacker) return;
	if (IsClientInGame(attacker) && GetClientTeam(attacker)==TEAM_INFECTED && IsPlayerAlive(attacker))
	{
		ForcePlayerSuicide(attacker);
		EmitSoundToAll(SOUND_KILL, victim);
	}
}

//get free from special infecteds...
void ShoveAttacker(int victim)
{
	int attacker = g_Attacker[victim];
	
	if ( g_IncapType[victim]==INCAP_POUNCE )
	{
		SetEntProp(victim, Prop_Send, "m_pounceAttacker", 0);
		SetEntProp(attacker, Prop_Send, "m_pounceVictim", 0);
	}
	else  if ( g_IncapType[victim]==INCAP_GRAB )
	{
		SetEntProp(attacker, Prop_Send, "m_tongueVictim", 0);
		SetEntProp(victim, Prop_Send, "m_tongueOwner", 0);
		SetEntProp(victim, Prop_Send, "m_isHangingFromTongue", 0);
	}
}

void check_inmunity(int client)
{
	//we won't kill attackers during inmunity. It should be seem to "notarget"...
	if ( g_Inmunity[client] )
		ShoveAttacker(client);
}

public Action removeInmunity(Handle timer, int client)
{
	g_Inmunity[client] = 0;
}

public Action timed_reset(Handle timer)
{
	reset();
}

void reset()
{
	g_Attacker = empty;
	g_IncapType = empty;
	g_Inmunity = empty;
	//g_bFirstHumanCheck = false;
	g_bMissionStarted = true;
	//SetConVarInt(g_hNoDeathCheck, 1);
	
	//replace all pipe bombs...
	if ( GetConVarInt(l4d1_lastman_no_pipe_bombs) )
		NoPipeBombs();
}

void GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));

	if (StrEqual(GameName, "survival", false))
		g_iGameMode = GAMEMODE_SURVIVAL;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		g_iGameMode = GAMEMODE_VERSUS;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		g_iGameMode = GAMEMODE_COOP;
	else
		g_iGameMode = 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int GetHumanPlayersCount(int flags=0)
{
	int is_alive, count, player_team, pre_count;
	//if both FLAGS_INFECTED and FLAGS_SURVIVOR are omited, both will be enabled.
	if (flags & FLAGS_INFECTED & FLAGS_SURVIVOR == 0)
		flags |= (FLAGS_INFECTED | FLAGS_SURVIVOR);
	
	//if both FLAGS_ALIVE and FLAGS_DEAD are omited, both will be enabled.
	if (flags & FLAGS_ALIVE & FLAGS_DEAD == 0)
		flags |= (FLAGS_ALIVE | FLAGS_DEAD);
	
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsValidClientInGame(i))
			continue;
		if (IsPlayerAlive(i)) is_alive = 1;
		player_team = GetClientTeam(i);
		pre_count = 0;
		
		if ( flags & FLAGS_INFECTED && player_team==TEAM_INFECTED ) pre_count+=1;
		if ( flags & FLAGS_SURVIVOR && player_team==TEAM_SURVIVOR ) pre_count+=2;
		if ( flags & FLAGS_ALIVE && is_alive==1 ) pre_count+=4;
		if ( flags & FLAGS_DEAD && is_alive==0 ) pre_count+=8;
		if (pre_count&(1|2) && pre_count&(4|8)) count++;
	}
	return count;
}