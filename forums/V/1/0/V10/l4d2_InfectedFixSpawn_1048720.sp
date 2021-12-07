
#include <sourcemod>
#include <sdktools>
#include <l4d2_InfectedSpawnApi>

#if defined InfectedApiVersion1_6
#else
	#error Plugin required Infected Api Version 1.6 (get it http://forums.alliedmods.net/showthread.php?t=114979)
#endif


/**
* ChangeLog
* 1.3.1 
* - Recompiled with new version of Infected API version 1.6.1
* 1.2
* - Speedup optimizations in InfectedSpawnApi
* 1.1
* - Fix IsPlayerAlive after ghost spawn (DLC bug)
* 1.0
* - Command sm_infectedchange allowed to use anytime with admin flag ROOT
* - Plugin name in plugins list corrected
* - Use Infected API version 1.5
* - Fix bug when plugin don't works correctly sometimes
* 0.8
* - Use Infected API version 1.4
* - Command sm_infectedchange compilation fixed
* - Simple fix compatiblity
* - Fixed MAXPLAYERS to MaxClients
* 0.7
* - Added cvar with version number. (l4d2_inffixspawn_version)
* - Added cvar for plugin wait(no actions) x seconds from round start. (sm_inffixspawn_wait)
* 0.6
* - All plugin code rewrited.
* - All bugs fixed.
* - Use Infected API version 1.3
* 0.5
* - Added debug log to file
* 0.4
* - Use Infected API version 1.2
* - Added cheking infected on finales
* - Added hard change class if director can't give another class more 5 times
* - Fixed bug with l4dtoolz and sv_force_normal_respawn (thanks to Visual77)
* - Added library for spawn ghost in finale without l4d2toolz (not required)
* 0.3
* - Fixed known bugs
* - Temporary infected not checked in finales
* 0.2
* -  Fix bug at round_end
* 0.1 
* - Initial release.
*/

#define PLUGIN_VERSION "1.3.1"
#define L4D_MAXPLAYERS 32
#define MAX_CLASS_RECHECKS 5
#define DEBUG 0

new LastClass[L4D_MAXPLAYERS+1];
new ClassRechecks[L4D_MAXPLAYERS+1];
new Handle:g_hCvarWait;
new bool:g_bWaiting=false;

public Plugin:myinfo =
{
	name = "[L4D2] Infected Fix Spawn",
	author = "V10",
	description = "Fixes the bug when infected spawn always same class",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1048720"
}

public OnPluginStart()
{
	//Look up what game we're running,
	decl String:game[64]
	GetGameFolderName(game, sizeof(game))
	//and don't load if it's not L4D2.
	if (!StrEqual(game, "left4dead2", false)) SetFailState("Plugin supports Left 4 Dead 2 only.")
	
	CreateConVar("l4d2_inffixspawn_version", PLUGIN_VERSION, "InfectedFixSpawn plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCvarWait=CreateConVar("sm_inffixspawn_wait", "5", "Plugin wait(no actions) this value seconds from round start.");
		
	HookEvent("ghost_spawn_time", Event_GhostSpawnTime);
	HookEvent("versus_round_start", Event_RoundStart)
	HookEvent("scavenge_round_start", Event_RoundStart)
	HookEvent("round_start", Event_RoundStart);
//	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post)
	RegAdminCmd("sm_infectedchange", Command_ChangeTest, ADMFLAG_ROOT);
	InitInfectedSpawnAPI();
}

public Action:Command_ChangeTest(client, args) 
{
	if (client==0) client=1;
	new CurrentClass=GenerateZombieId(LastClass[client]);
	InfectedChangeClass(client,CurrentClass);	
	LastClass[client]=CurrentClass;
}

public Action:Timer_StopWait(Handle:timer){ g_bWaiting=false; }

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++){
		LastClass[i]=0;
		ClassRechecks[i]=0;
	}
	if(GetConVarInt(g_hCvarWait)) {
		g_bWaiting=true;
		CreateTimer(GetConVarFloat(g_hCvarWait),Timer_StopWait);
	}
	
}

/*public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
}
*/
public Action:Event_GhostSpawnTime(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bWaiting) return;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new spawntime = GetEventInt(event, "spawntime");
	CreateTimer(float(spawntime)-1.0, PreDelayedTestClass, client)
	ClassRechecks[client] = 0;
	#if DEBUG
		DebugPrint("GhostSpawnTime, cl=%N, time=%d",client,spawntime);
	#endif
}

public Action:PreDelayedTestClass(Handle:timer, any:client)
{
	#if DEBUG
		DebugPrint("PreDelayed test class, cl=%N, alive=%d",client,IsPlayerAlive(client));
	#endif
	if (IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client)==TEAM_INFECTED) 
		CreateTimer(1.0, DelayedTestClass, client)
}

public Action:DelayedTestClass(Handle:timer, any:client)
{
	if (!IsClientConnected(client) || !IsClientInGame(client) || GetClientTeam(client)!=TEAM_INFECTED) return;

	//check class
	new CurrentClass= GetInfectedClass(client);	
	#if DEBUG
		DebugPrint("Delayed test class, cl=%N, class=%s, alive=%d",client,g_sBossNames[CurrentClass],IsPlayerAlive(client));
	#endif
	
	if (CurrentClass == ZC_TANK) return;
	
	if (!IsPlayerAlive(client)) {
		if (ClassRechecks[client] < MAX_CLASS_RECHECKS){
			//If player after spawn ghost and is not alive then recheck in 0.1
			CreateTimer(0.1, DelayedTestClass, client);
			ClassRechecks[client]++;
		}
		// if after max check steel not alive - do nothing
		return;
	}
	
	if (CurrentClass==LastClass[client]){
		CurrentClass=GenerateZombieId(LastClass[client]);
		InfectedChangeClass(client,CurrentClass);
		#if DEBUG
			DebugPrint("Delayed change class, cl=%N, change=%s",client,g_sBossNames[CurrentClass]);
		#endif
	}
	LastClass[client]=CurrentClass;
}

#if DEBUG

DebugPrint(const String:format[], any:...)
{
	decl String:buffer[300];
	static Handle:hLogFile=INVALID_HANDLE;
	VFormat(buffer, sizeof(buffer), format, 2);	
	if (hLogFile==INVALID_HANDLE){
		decl String:logPath[256];
		BuildPath(Path_SM, logPath, sizeof(logPath), "logs/l4d2_InfectedFixSpawn.log");
		hLogFile=OpenFile(logPath,"a");
	}
	LogToOpenFileEx(hLogFile,buffer);
}
#endif



