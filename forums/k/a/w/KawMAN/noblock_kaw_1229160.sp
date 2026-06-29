#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define cDefault 0x01
#define cLightGreen 0x03
#define cGreen 0x04
#define cDarkGreen 0x05

#define PLUGIN_VERSION "1.3.0K1"
#define RECHECKTIME 2.0

#define DEBUG 0
#define TURNEDOFF 0

#if DEBUG > 0
new LaserCache;
new LaserHalo;
new BeamColor[4] = {0, 0, 0, 200};
#endif

public Plugin:myinfo = 
{
	name = "NoBlock",
	author = "Otstrel.ru Team",
	description = "Removes player collisions.",
	version = PLUGIN_VERSION,
	url = "http://otstrel.ru"
};

new g_offsCollisionGroup;
new bool:g_enabled;
new Handle:sm_noblock;
new Handle:sm_noblock_allow_block;
new Handle:sm_noblock_allow_block_time;
new Handle:g_hTimer[MAXPLAYERS+1];

new Handle:sm_noblock_blockafterspawn_time;
new Float:g_blockTime;
new Float:g_blockTimeMAX;

new Float:mins[3] = { -20.0, -20.0, -20.0};
new Float:maxs[3] = { 20.0, 20.0, 20.0};


new Handle:ClientTraceHndl[MAXPLAYERS+1];
new Handle:ClientColCheckTimer[MAXPLAYERS+1];

public OnPluginStart()
{

	#if DEBUG > 0
	LogError("[DEBUG] Plugin started.");
	LaserCache = PrecacheModel("sprites/bluelaser1.vmt");
	LaserHalo = PrecacheModel("sprites/blueglow1.vmt");
	#endif
	sm_noblock = CreateConVar("sm_noblock", "1", "Removes player vs. player collisions", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	sm_noblock_allow_block = CreateConVar("sm_noblock_allow_block", "0.0", "Allow players to use say !block", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	sm_noblock_allow_block_time = CreateConVar("sm_noblock_allow_block_time", "20.0", "Time limit to say !block command", FCVAR_PLUGIN, true, 0.0, true, 600.0);
	sm_noblock_blockafterspawn_time = CreateConVar("sm_noblock_blockafterspawn_time", "7.0", "Disable blocking only for that time from spawn.", FCVAR_PLUGIN, true, 0.0, true, 600.0);
	AutoExecConfig(true, "noblock");
	new Handle:Cvar_Version = CreateConVar("sm_noblock_version", PLUGIN_VERSION,	"NoBlock Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	/* Just to make sure they it updates the convar version if they just had the plugin reload on map change */
	SetConVarString(Cvar_Version, PLUGIN_VERSION);
	
	g_offsCollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_offsCollisionGroup == -1)
	{
		SetFailState("[NoBlock] Failed to get offset for CBaseEntity::m_CollisionGroup.");
	}
	
	g_blockTime = GetConVarFloat(sm_noblock_blockafterspawn_time);
	
	g_enabled = GetConVarBool(sm_noblock);
	HookConVarChange(sm_noblock, OnConVarChange);
	HookConVarChange(sm_noblock_blockafterspawn_time, OnConVarChange);

	HookEvent("player_spawn", OnSpawn, EventHookMode_Post);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
} 

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	#if DEBUG > 0
	LogError("[DEBUG] Cvar changed.");
	#endif
	if ( hCvar == sm_noblock )
	{
		g_enabled = GetConVarBool(sm_noblock);
		if ( g_enabled )
		{
			UnblockClientAll();
		}
		else
		{
			BlockClientAll();
		}
	}
	else if ( hCvar == sm_noblock_blockafterspawn_time )
	{
		g_blockTime = GetConVarFloat(sm_noblock_blockafterspawn_time);
		g_blockTimeMAX += 2.0 ;
	}
}

public OnSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if DEBUG > 0
	LogError("[DEBUG] Player spawned.");
	#endif
	if ( !g_enabled )
	{
		return;
	}
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

	#if DEBUG > 0
		LogError("[DEBUG] ... player %i.", client);
	#endif

	if ( g_hTimer[client] != INVALID_HANDLE )
	{
		CloseHandle(g_hTimer[client]);
		g_hTimer[client] = INVALID_HANDLE;
		PrintToChat(client, "%c[NoBlock] %cBlocking has been Disabled because of respawn", cLightGreen, cDefault);
	}

	UnblockClient(client);
	
	if ( g_blockTime )
	{
		#if TURNEDOFF > 0
		if(ClientColCheckTimer[client] != INVALID_HANDLE) {
			CloseHandle(ClientColCheckTimer[client]);
			ClientColCheckTimer[client] = INVALID_HANDLE;
		}
		#endif
		
		//CPU usage reduce
		if (g_blockTime>=g_blockTimeMAX) {
			g_blockTime = GetConVarFloat(sm_noblock_blockafterspawn_time);
		} else {
			g_blockTime += 0.1;
		}
		ClientColCheckTimer[client] = CreateTimer(g_blockTime, Timer_PlayerBlock, client);
	}
}

public Action:Command_Say(client, args)
{
	#if DEBUG > 0
	LogError("[DEBUG] Player %i sayd something.", client);
	#endif
	if ( !g_enabled || !client || !GetConVarFloat(sm_noblock_allow_block) )
	{
		return Plugin_Continue;
	}

	decl String:text[192], String:command[64];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
 
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}

	if ( (strcmp(text[startidx], "!block", false) == 0) && !g_blockTime )
	{
		if ( g_hTimer[client] != INVALID_HANDLE )
		{
			CloseHandle(g_hTimer[client]);
			g_hTimer[client] = INVALID_HANDLE;			
			PrintToChat(client, "%c[NoBlock] %cBlocking has been Disabled by the client", cLightGreen, cDefault);
			
			UnblockClient(client);
			return Plugin_Continue;
		}
		
		new Float:fTime = GetConVarFloat(sm_noblock_allow_block_time);
		
		g_hTimer[client] = CreateTimer(fTime, Timer_PlayerUnblock, client);
		PrintToChat(client, "%c[NoBlock] %cBlocking has been Enabled for %.0f seconds", cLightGreen, cDefault, fTime);
		
		BlockClient(client);
	}
 
	return Plugin_Continue;
}

//Player Blocking Expires
public Action:Timer_PlayerUnblock(Handle:timer, any:client)
{
	#if DEBUG > 0
	LogError("[DEBUG] Timer unblocks client %i.", client);
	#endif
	//Disable Blocking on the Client
	g_hTimer[client] = INVALID_HANDLE;			
	if ( !g_enabled || !client || !IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return Plugin_Continue;
	}
	
	PrintToChat(client, "%c[NoBlock] %cBlocking is now Disabled", cLightGreen, cDefault);
	
	UnblockClient(client);
	return Plugin_Continue;
}

public Action:Timer_PlayerBlock(Handle:timer, any:client)
{
	//Enable Blocking on the Client
	if ( !g_enabled || !client || !IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return Plugin_Continue;
	}
	decl Float:vecClientEyePos[3],Float:vecClientEyeAng[3];
	GetClientAbsOrigin(client, vecClientEyePos);
	GetClientAbsAngles(client, vecClientEyeAng);
	
	vecClientEyeAng[0] = 0.0;
	vecClientEyeAng[2] = 0.0;
	
	#if DEBUG > 2
	PrintToChatAll("Running Code %f %f %f | %f %f %f", vecClientEyePos[0], vecClientEyePos[1], vecClientEyePos[2], vecClientEyeAng[0], vecClientEyeAng[1], vecClientEyeAng[2]);	 
	#endif
	
	#if TURNEDOFF > 0
	if(ClientTraceHndl[client] != INVALID_HANDLE) {
		CloseHandle(ClientTraceHndl[client]);
		ClientTraceHndl[client] = INVALID_HANDLE;
	}
	#endif
	new i=1,TRIndex, bool:CanBlock = false;
	while(i<=3) {
		#if DEBUG > 2
		TE_SetupBeamRingPoint(vecClientEyePos, 150.0, 250.0, LaserCache, LaserHalo, 1, 1, 3.0, 3.0, 0.0, BeamColor, 0, FBEAM_SOLID);
		TE_SendToAll();
		#endif
		
		ClientTraceHndl[client] = TR_TraceHullFilterEx(vecClientEyePos, vecClientEyeAng, mins, maxs, MASK_SHOT, TraceRayFilter, client);
		if (TR_DidHit(ClientTraceHndl[client]) && (TRIndex = TR_GetEntityIndex(ClientTraceHndl[client])) != 0)
		{
			
			UnblockClient(TRIndex);
			
			#if DEBUG > 1 
			new String:classname[64], Float:pos2[3];
			GetEdictClassname(TRIndex, classname, sizeof(classname));
			PrintToChatAll("Entity Found %i %s %f %f %f", TRIndex, classname, pos2[0],pos2[1],pos2[2]);
			#endif
			
			if(ClientTraceHndl[client] != INVALID_HANDLE) {
				CloseHandle(ClientTraceHndl[client]);
				ClientTraceHndl[client] = INVALID_HANDLE;
			}
			CanBlock=false;
			break;
		} else {
			CanBlock=true;
		}
		vecClientEyePos[2] += 20.0;
		i++;
	}
	if(CanBlock) {
		BlockClient(client);
		ClientColCheckTimer[client] = INVALID_HANDLE;
		#if DEBUG > 1
		PrintToChatAll("Can Block %d", client);
		#endif
	} else {
		#if TURNEDOFF > 0
		if(ClientColCheckTimer[client]!=INVALID_HANDLE) {
			CloseHandle(ClientColCheckTimer[client]);
			ClientColCheckTimer[client]=INVALID_HANDLE;
		}
		if(ClientColCheckTimer[TRIndex]!=INVALID_HANDLE) {
			CloseHandle(ClientColCheckTimer[TRIndex]);
			ClientColCheckTimer[TRIndex]=INVALID_HANDLE;
		}
		#endif
		ClientColCheckTimer[client] = CreateTimer(RECHECKTIME, Timer_PlayerBlock, client);
		ClientColCheckTimer[TRIndex] = CreateTimer(RECHECKTIME, Timer_PlayerBlock, TRIndex);
		
		#if DEBUG > 1
		PrintToChatAll("Can't Block %d", client);
		#endif
	}
	return Plugin_Continue;
}

public bool:TraceRayFilter(entity, mask, any:data)
{
	if ((entity!=data) && (entity > 0) && (entity <= MaxClients)) 
	{ 
		return true; 
	} 
	else 
	{ 
		return false; 
	}
}

BlockClient(client)
{
	#if DEBUG > 0
	LogError("[DEBUG] BLOCK client %i.", client);
	#endif
	SetEntData(client, g_offsCollisionGroup, 5, 4, true);
}

UnblockClient(client)
{
	#if DEBUG > 0
	LogError("[DEBUG] UNBLOCK client %i.", client);
	#endif
	SetEntData(client, g_offsCollisionGroup, 2, 4, true);
}

BlockClientAll()
{
	#if DEBUG > 0
	LogError("[DEBUG] Block all.");
	#endif

	for (new i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame(i) && IsPlayerAlive(i) )
		{
			BlockClient(i);
		}
	}
}

UnblockClientAll()
{
	#if DEBUG > 0
	LogError("[DEBUG] Unblock all.");
	#endif

	for (new i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame(i) && IsPlayerAlive(i) )
		{
			UnblockClient(i);
		}
	}
}

