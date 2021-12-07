/********************************************************************************************
* Plugin	: l4d_witches
* Version	: 1.6
* Game	    : Left4Dead & Left4Dead 2
* Author	: Sheleu
* Testers	: Myself and Aquarius (Ja-Forces)

* Version 1.0 (05.09.10)
* 		-  Initial release
* Version 1.1 (08.09.10)
* 		-  Fixed encountered error 23: Native detected error
* 		-  Fixed bug with counting alive witches
* 		-  Added removal of the witch when she far away from the survivors
* Version 1.2 (09.09.10)
* 		-  Added precache for witch (L4D2)
* Version 1.3 (16.09.10)
* 		-  Added removal director's witch
* 		-  Stopped spawn witches after finale start
* Version 1.4 (24.09.10)
* 		-  Code optimization
* Version 1.5 (17.05.11)
* 		-  Fixed error "Entity is not valid" (sapphire989's message)
* Version 1.6 (04.08.13)
*		- changed z_spawn to z_spawn_old, to stop witches spawning on players and instead adhere to the  *		   cfg rules based on distance and or time. (fixed by irogue)
*********************************************************************************************/ 

#include <sourcemod>
#include <sdktools>

#define PLUGIN_TAG	   "[l4d_witches]"
#define PLUGIN_VERSION "1.6"
// Enable debug messages?
#define DEBUG 1
#define DEBUGFUll 0

static bool: L4DVersion; // Version 1.2

new countWitch;
new maxCountWitchInRound;
new maxCountWitchAlive;
new Float: WitchTimeMin;
new Float: WitchTimeMax;
new Float: WitchDistance; // version 1.1
new bool: NotRemoveDirectorWitch; // version 1.3
new bool: SpawnAfterFinaleStart; // version 1.3
new Handle: Witches_SpawnTimer;
new Handle: g_hCvarCountWitchInRound;
new Handle: g_hCvarCountAliveWitch;
new Handle: g_hCvarWitchTimeMin;
new Handle: g_hCvarWitchTimeMax;
new Handle: g_hCvarWitchDistance; // version 1.1
new Handle: g_hCvarDirectorWitch; // version 1.3
new Handle: g_hCvarSpawnAfterFinaleStart; // version 1.3
new bool: runTimer = false;
new bool: roundStart = false;
new bool: PluginWitch = false;

public Plugin: myinfo = 
{
	name = "l4d_witches",
	author = "Sheleu",  
	description = "Many witches on map",
	version = PLUGIN_VERSION	
};

public OnPluginStart()
{	
	#if DEBUGFUll	
	LogMessage("%s #DEBUG: Plugin start", PLUGIN_TAG);	
	#endif
	End_Timer(false);
	// Console variables
	g_hCvarCountWitchInRound = CreateConVar("l4d_witches_limit", "4", "Sets the limit for witches spawned. If 0, the plugin will not check count witches", FCVAR_NONE);
	g_hCvarCountAliveWitch = CreateConVar("l4d_witches_limit_alive", "2", "Sets the limit alive witches. If 0, the plugin will not check count alive witches", FCVAR_NONE);
	g_hCvarWitchTimeMin = CreateConVar("l4d_witches_spawn_time_min", "100.0", "Sets the min spawn time for witches spawned by the plugin in seconds", FCVAR_NONE);
	g_hCvarWitchTimeMax = CreateConVar("l4d_witches_spawn_time_max", "120.0", "Sets the max spawn time for witches spawned by the plugin in seconds", FCVAR_NONE);
	g_hCvarWitchDistance = CreateConVar("l4d_witches_distance", "1500.0", "The range from survivors that witch should be removed. If 0, the plugin will not remove witches", FCVAR_NONE); // version 1.1
	g_hCvarDirectorWitch = CreateConVar("l4d_witches_director_witch", "1", "If 1, enable director's witch. If 0, disable director's witch", FCVAR_NONE, true, 0.0, true, 1.0); // version 1.3
	g_hCvarSpawnAfterFinaleStart = CreateConVar("l4d_witches_spawn_after_finale_start", "1", "If 1, enable spawn witches after finale start. If 0, disable spawn witches after finale start", FCVAR_NONE, true, 0.0, true, 1.0); // version 1.3
	HookConVarChange(g_hCvarCountWitchInRound, ConVarWitchLimit);
	maxCountWitchInRound = GetConVarInt(g_hCvarCountWitchInRound);
	HookConVarChange(g_hCvarCountAliveWitch, ConVarAliveWitchLimit);
	maxCountWitchAlive = GetConVarInt(g_hCvarCountAliveWitch);
	HookConVarChange(g_hCvarWitchTimeMin, ConVarWitchTimeMin);
	WitchTimeMin = GetConVarFloat(g_hCvarWitchTimeMin);
	HookConVarChange(g_hCvarWitchTimeMax, ConVarWitchTimeMax);
	WitchTimeMax = GetConVarFloat(g_hCvarWitchTimeMax);
	HookConVarChange(g_hCvarWitchDistance, ConVarWitchDistance); // version 1.1
	WitchDistance = GetConVarFloat(g_hCvarWitchDistance); // version 1.1
	HookConVarChange(g_hCvarDirectorWitch, ConVarDirectorWitch); // version 1.3
	NotRemoveDirectorWitch = GetConVarBool(g_hCvarDirectorWitch); // version 1.3
	HookConVarChange(g_hCvarSpawnAfterFinaleStart, ConVarSpawnAfterFinaleStart); // version 1.3
	SpawnAfterFinaleStart = GetConVarBool(g_hCvarSpawnAfterFinaleStart); // version 1.3
	// We hook some events
	HookEvent("witch_spawn", Event_WitchSpawned, EventHookMode_PostNoCopy);	
	HookEvent("player_left_start_area", Event_PlayerLeftStartArea);
	HookEvent("door_open", Event_DoorOpen);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("finale_start", Event_FinaleStart); // version 1.3
	// Autoconfig for plugin
	AutoExecConfig(true, "l4d_witches");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) // Version 1.2
{	
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
		L4DVersion = true;
	else L4DVersion = false;
	return APLRes_Success; 
}

public ConVarWitchLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	maxCountWitchInRound = GetConVarInt(g_hCvarCountWitchInRound);	
	SetConVarInt(FindConVar("l4d_witches_limit"), maxCountWitchInRound);
}

public ConVarAliveWitchLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	maxCountWitchAlive = GetConVarInt(g_hCvarCountAliveWitch);	
	SetConVarInt(FindConVar("l4d_witches_limit_alive"), maxCountWitchAlive);
}

public ConVarWitchTimeMin(Handle:convar, const String:oldValue[], const String:newValue[])
{
	WitchTimeMin = GetConVarFloat(g_hCvarWitchTimeMin);	
	SetConVarFloat(FindConVar("l4d_witches_spawn_time_min"), WitchTimeMin);	
}

public ConVarWitchTimeMax(Handle:convar, const String:oldValue[], const String:newValue[])
{
	WitchTimeMax = GetConVarFloat(g_hCvarWitchTimeMax);	
	SetConVarFloat(FindConVar("l4d_witches_spawn_time_max"), WitchTimeMax);
}

public ConVarWitchDistance(Handle:convar, const String:oldValue[], const String:newValue[]) // version 1.1
{
	WitchDistance = GetConVarFloat(g_hCvarWitchDistance);	
	SetConVarFloat(FindConVar("l4d_witches_distance"), WitchDistance);
}

public ConVarDirectorWitch(Handle:convar, const String:oldValue[], const String:newValue[]) // version 1.3
{
	NotRemoveDirectorWitch = GetConVarBool(g_hCvarDirectorWitch);	
	SetConVarBool(FindConVar("l4d_witches_director_witch"), NotRemoveDirectorWitch);
}

public ConVarSpawnAfterFinaleStart(Handle:convar, const String:oldValue[], const String:newValue[]) // version 1.3
{
	SpawnAfterFinaleStart = GetConVarBool(g_hCvarSpawnAfterFinaleStart);	
	SetConVarBool(FindConVar("l4d_witches_spawn_after_finale_start"), SpawnAfterFinaleStart);
}

public OnPluginEnd()
{
	#if DEBUGFUll
	LogMessage("%s #DEBUG: Plugin end", PLUGIN_TAG);	
	#endif	
	End_Timer(false);
}

public OnConfigsExecuted()
{	
	#if DEBUGFUll	
	LogMessage("%s #DEBUG: On configs executed", PLUGIN_TAG);	
	#endif
	End_Timer(false);
}

public Action: Event_WitchSpawned(Handle:event, const String:name[], bool:dontBroadcast) // version 1.3
{
	if (!PluginWitch && !NotRemoveDirectorWitch)
	{
		new WitchID = GetEventInt(event, "witchid");
		if (IsValidEdict(WitchID)) 
		{
			AcceptEntityInput(WitchID, "Kill"); //RemoveEdict(WitchID); //Version 1.5
			#if DEBUGFUll
			LogMessage("%s #DEBUG: Remove director's witch ID = %i; witch = %d, max count witch = %d", PLUGIN_TAG, WitchID, countWitch, maxCountWitchInRound);	
			#endif
		}
		else
		{			
			#if DEBUGFUll
			LogMessage("%s #DEBUG: Don't remove director's witch ID = %i because not an edict index (witch ID) is valid", PLUGIN_TAG, WitchID);	
			#endif
		}
	}
	else
	{
		countWitch++; 	
		#if DEBUG
		LogMessage("%s #DEBUG: Witch spawned; witch = %d, max count witch = %d", PLUGIN_TAG, countWitch, maxCountWitchInRound);	
		#endif
	}
}

public Action: Event_PlayerLeftStartArea(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!runTimer)
	{
		#if DEBUGFUll	
		LogMessage("%s #DEBUG: Player left start area", PLUGIN_TAG);	
		#endif
		First_Start_Timer();
	}
}

public Action: Event_DoorOpen(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!runTimer)
	{
		if (GetEventBool(event, "checkpoint") && roundStart)
		{
			#if DEBUGFUll	
			LogMessage("%s #DEBUG: Door open", PLUGIN_TAG);	
			#endif
			First_Start_Timer();
		}
	}
}

public Action: Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) // Version 1.2
{
	if (L4DVersion)
	{
		if (!IsModelPrecached("models/infected/witch.mdl")) PrecacheModel("models/infected/witch.mdl");
		if (!IsModelPrecached("models/infected/witch_bride.mdl")) PrecacheModel("models/infected/witch_bride.mdl");
	}
	#if DEBUGFUll	
	LogMessage("%s #DEBUG: End timer", PLUGIN_TAG);	
	#endif
	End_Timer(false);
	roundStart = true;
}

public Action: Event_FinaleStart(Handle:event, const String:name[], bool:dontBroadcast) // Version 1.3
{
	if (!SpawnAfterFinaleStart)
	{
		#if DEBUGFUll	
		LogMessage("%s #DEBUG: End timer (finale start)", PLUGIN_TAG);	
		#endif
		End_Timer(false);
	}
}

public First_Start_Timer()
{		
	runTimer = true;
	roundStart = false;
	countWitch = 0;
	#if DEBUGFUll
	LogMessage("%s #DEBUG: First_Start_Timer; leaved safe room; runTimer = %d", PLUGIN_TAG, runTimer);	
	#endif
	Start_Timer();
}

public Start_Timer()
{	
	new Float: WitchSpawnTime = GetRandomFloat(WitchTimeMin, WitchTimeMax);
	#if DEBUG
	LogMessage("%s #DEBUG: Start_Timer; witch spawn time = %f", PLUGIN_TAG, WitchSpawnTime);			
	#endif
	Witches_SpawnTimer = CreateTimer(WitchSpawnTime, SpawnAWitch, _);
}

public End_Timer(const bool: isClosedHandle) // version 1.1
{
	if (runTimer)
	{
		if (!isClosedHandle) CloseHandle(Witches_SpawnTimer);				
		countWitch = 0;		
		runTimer = false;
		PluginWitch = false; // version 1.3
		#if DEBUGFUll		
		LogMessage("%s #DEBUG: End_Timer; close handle; runTimer = %d", PLUGIN_TAG, runTimer);	
		#endif
	}
}

stock GetAnyClient()
{
	new i;
	for (i = 1; i <= GetMaxClients(); i++)
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i))) 
			return i;
	return 0;
}

stock FindEntityByClassname2(startEnt, const String:classname[]) // version 1.4
{
	while (startEnt < GetMaxEntities() && !IsValidEntity(startEnt)) startEnt++;
	return FindEntityByClassname(startEnt, classname);
}

public GetCountAliveWitches() // version 1.1 & version 1.4
{	
	new countWitchAlive = 0;	
	new index = -1;
	while ((index = FindEntityByClassname2(index, "witch")) != -1)
	{		
		countWitchAlive++;
		#if DEBUGFUll
		LogMessage("%s #DEBUG: witch ID = %i (alive witches = %i)", PLUGIN_TAG, index, countWitchAlive);
		#endif	
		if (WitchDistance > 0)
		{
			decl Float: WitchPos[3], Float: PlayerPos[3];
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", WitchPos);
			new k = 0;
			new maxRealClients = 0;	
			for (new i = 1; i <= GetMaxClients(); i++)
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
				{
					maxRealClients++;
					GetClientAbsOrigin(i, PlayerPos);
					new Float: distance = GetVectorDistance(WitchPos, PlayerPos);
					#if DEBUGFUll
					LogMessage("%s #DEBUG: distance from the witch = %f; max distance = %f", PLUGIN_TAG, distance, WitchDistance);
					#endif
					if (distance > WitchDistance) k++;											
				}
			if (k == maxRealClients) 
			{
				AcceptEntityInput(index, "Kill"); //RemoveEdict(index); //Version 1.5
				countWitchAlive--;					
			}
		}
	}	
	#if DEBUGFUll
	LogMessage("%s #DEBUG: Alive witches = %d, max count alive witches = %d", PLUGIN_TAG, countWitchAlive, maxCountWitchAlive);		
	#endif
	return countWitchAlive;
}

stock SpawnCommand(client, String:command[], String:arguments[] = "") // version 1.1
{
	if (client)
	{		
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
}

public Action: SpawnAWitch(Handle:timer)
{	
	if (runTimer)
	{		
		if (maxCountWitchInRound > 0 && countWitch >= maxCountWitchInRound)
		{
			#if DEBUGFUll
			LogMessage("%s #DEBUG: Witch = %d, max count witch = %d; End_Timer()", PLUGIN_TAG, countWitch, maxCountWitchInRound);		
			#endif
			End_Timer(true);
			return;
		}
		if (maxCountWitchAlive > 0 && countWitch >= maxCountWitchAlive && GetCountAliveWitches() >= maxCountWitchAlive)
		{
			Start_Timer();
			return;
		}
		new anyclient = GetAnyClient()
		if (anyclient == 0)
		{
			anyclient = CreateFakeClient("Bot");
			if (anyclient == 0)
			{
				#if DEBUGFUll
				LogMessage("%s #DEBUG: anyclient = 0", PLUGIN_TAG);		
				#endif
				Start_Timer();
				return;
			}
		}	
		PluginWitch	= true; // version 1.3
		SpawnCommand(anyclient, "z_spawn_old", "witch auto");
		#if DEBUGFUll
		LogMessage("%s #DEBUG: plugin's witch", PLUGIN_TAG);		
		#endif
		PluginWitch	= false; // version 1.3
		Start_Timer();
	}
	else return;
}