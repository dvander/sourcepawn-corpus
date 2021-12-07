#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.1.5"

public Plugin:myinfo = {
	name = "[CSGO] BuyZone Simulator",
	author = "KawMAN",
	description = "Enable buyzones on maps that don't have them",
	version = PLUGIN_VERSION,
	url = "http://www.wsciekle.pl"
};

static const String:bz_classname[]	 		= "func_buyzone";
static const Float:PosRefreshEvery			= 1.0; // Position Refresh Time, sec

//{ ConVars Handles & Value Holders
new Handle:hcBuyZoneRange		= INVALID_HANDLE;
new Handle:hcEnabled			= INVALID_HANDLE;

//Value Holders
new bool:cEnabled								= false;
new Float:cBuyZoneRange								= 0.0;
//}
new bool:MapStarted										= false;
new gSpawnedBuyzone 								= -1;
new bool:gSDKHook_IsBuyZoneHooked[MAXPLAYERS+1]		= { false, ... };
new bool:gSimulatorEnabled							= false;

new Handle:ghCvarMpBuyTime							= INVALID_HANDLE;
new Handle:tPosRefresh[MAXPLAYERS+1]				= { INVALID_HANDLE, ... };
new Float:gPlrSpawnPos[MAXPLAYERS+1][3]				;
new bool:gCanBuy[MAXPLAYERS+1]						= { false, ... };

public OnPluginStart() {
	//Preset & Check compability
	if(!LibraryExists("sdkhooks")) 					{ PrintToServer("[BuyZone Simulator] ERROR: No SDKHooks ")				; 	SetFailState("No SDKHooks")				;}
	if(!HookEventEx("round_start",  ecRoundStart))	{ PrintToServer("[BuyZone Simulator] ERROR: Can't hook round_start ")	; 	SetFailState("Can't hook round_start")	;}
	if(!HookEventEx("player_spawn", ecPlayerSpawn))	{ PrintToServer("[BuyZone Simulator] ERROR: Can't hook player_spawn ")	; 	SetFailState("Can't hook player_spawn")	;}
	if(!HookEventEx("player_death", ecPlayerDeath))	{ PrintToServer("[BuyZone Simulator] ERROR: Can't hook player_death ")	; 	SetFailState("Can't hook player_death")	;}
	if(!HookEventEx("round_end",    ecRoundEnd))	{ PrintToServer("[BuyZone Simulator] ERROR: Can't hook round_end ")		; 	SetFailState("Can't hook round_end")	;}
	ghCvarMpBuyTime = FindConVar("mp_buytime"); if( ghCvarMpBuyTime == INVALID_HANDLE ) { PrintToServer("[BuyZone Simulator] ERROR: Can't find mp_buytime cvar "); SetFailState("Can't find mp_buytime cvar"); }
	
	hcBuyZoneRange = CreateConVar("sm_bzsimulator_range", "20.0", "BuyZone range, 0 = everywhere ", FCVAR_PLUGIN,true,0.0);
	hcEnabled = CreateConVar("sm_bzsimulator", "1.0", "BuyZone Simulator", FCVAR_PLUGIN,true,0.0,true,1.0);
	CreateConVar("sm_bzsimulator_v", PLUGIN_VERSION, "[CSGO]BuyZone Simulaotr Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookConVarChange(hcEnabled, MyCvarChange);
	HookConVarChange(hcBuyZoneRange, MyCvarChange);
	RefreshSettings();
}
//{ Settings Section
public MyCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strcmp(oldValue, newValue)==0) return; //No change
	RefreshSettings(convar);
}

RefreshSettings(Handle:convar=INVALID_HANDLE) {
	decl bool:boolval;

	if(convar == INVALID_HANDLE || convar == hcBuyZoneRange) {
		cBuyZoneRange = GetConVarFloat(hcBuyZoneRange); // Just change
		if(cBuyZoneRange<0.0) cBuyZoneRange = 0.0;
		cBuyZoneRange = cBuyZoneRange * 1000.0;
		if(convar != INVALID_HANDLE) return;
	}
	if(convar == INVALID_HANDLE || convar == hcEnabled) {
		boolval = GetConVarBool(hcEnabled);
		if(boolval != cEnabled) {
			if(boolval)	{ //Enable
				cEnabled = true;
				TryEnablePlugin();
			} else		{ //Disable
				DisablePlugin();
				cEnabled = false;
			}
		}
		if(convar != INVALID_HANDLE) return;
	}
}

//}

public OnMapStart() {
	MapStarted=true;
	RefreshSettings();
	TryEnablePlugin();
}

TryEnablePlugin() {
	if(CanStart()) {
		gSimulatorEnabled 		= true;
		gSpawnedBuyzone	= CreateEntityByName(bz_classname);
		DispatchKeyValue(gSpawnedBuyzone, "TeamNum", "2"); //Maybe unnecessary
		if(!DispatchSpawn(gSpawnedBuyzone)) {
			PrintToServer("[BuyZone Simulator] ERROR while attampting to create %s", bz_classname);
			DisablePlugin();
		}
		PrintToServer("[BuyZone Simulator] Enabled");
	}
}

DisablePlugin() { //Kill created buyzone and unhook PostThink
	if(gSpawnedBuyzone != -1) {
		decl String:classname[128];
		GetEntityClassname(gSpawnedBuyzone, classname, sizeof(classname));
		if(strcmp(bz_classname, classname, false) == 0) {
			AcceptEntityInput(gSpawnedBuyzone, "Kill");
		}
		gSpawnedBuyzone = -1;
	}
	for(new i=1; i<=MaxClients; i++) {
			UnHookBuyZone(i);
	}
	gSimulatorEnabled = false;

	PrintToServer("[BuyZone Simulator] Disabled");
}
public ecRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gSimulatorEnabled ) {
		CreateTimer(GetConVarFloat(ghCvarMpBuyTime), tcAfterBuyTime);
	}
}
public Action:tcAfterBuyTime(Handle:timer)
{
	//unhook BuyZone
	for(new i=1; i<=MaxClients; i++) {
			UnHookBuyZone(i);
	}
}
public ecPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(gSimulatorEnabled && GetEntProp(client, Prop_Send, "m_bIsControllingBot") != 1) { //Check if it's bot takeover or real spawn
		HookBuyZone(client);
	}
}
public ecPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gSimulatorEnabled) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		UnHookBuyZone(client);
	}
}
public ecRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(gSimulatorEnabled) {
		for(new i=1; i<=MaxClients; i++) {
			UnHookBuyZone(i);
		}
	}
}
public SDKHook_hcPostThinkSetBuyZone(client) {
	if(gCanBuy[client]) SetEntProp(client, Prop_Send, "m_bInBuyZone", 1);
}

HookBuyZone(client)	{
	if (IsClientInGame(client) ) {
			gCanBuy[client] = true;
			if(!gSDKHook_IsBuyZoneHooked[client]) gSDKHook_IsBuyZoneHooked[client] = SDKHookEx(client,SDKHook_PostThink, SDKHook_hcPostThinkSetBuyZone);
			GetClientAbsOrigin(client, gPlrSpawnPos[client]);
			if( cBuyZoneRange != 0.0 ) tPosRefresh[client] = CreateTimer(PosRefreshEvery, tcPosRefresh, client, TIMER_REPEAT);
	}
}
UnHookBuyZone(client) {
	if(gSDKHook_IsBuyZoneHooked[client]) {
		SDKUnhook(client, SDKHook_PostThink, SDKHook_hcPostThinkSetBuyZone); 
		gSDKHook_IsBuyZoneHooked[client] = false;
		tPosRefresh[client] = INVALID_HANDLE; //Timer will auto kill
	}
}
public Action:tcPosRefresh(Handle:timer, any:client)
{
	if(timer!=tPosRefresh[client]) return Plugin_Stop; //Auto Kill
	if(!IsClientInGame(client)) { tPosRefresh[client] = INVALID_HANDLE; return Plugin_Stop; }
	
	decl Float:PlrPos[3];
	GetClientAbsOrigin(client, PlrPos);
	if(GetVectorDistance(PlrPos, gPlrSpawnPos[client], true) > cBuyZoneRange) { gCanBuy[client] = false; } else { gCanBuy[client] = true; }
	
	return Plugin_Continue;
}

//Helpers 
bool:CanStart() {
	if(!cEnabled) return false;
	if(!MapStarted) return false;
	if(FindEntityByClassname(-1, "func_buyzone")==-1) {
		return true;
	}
	return false;
}

public OnMapEnd() {
	MapStarted=false;
	DisablePlugin();
}

public OnPluginEnd() {
	DisablePlugin();
}
public OnPluginPauseChange(bool:pause) {
	if(pause) {
		DisablePlugin();
	} else {
		OnMapStart();
	}
}