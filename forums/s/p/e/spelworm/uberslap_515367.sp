// Force all lines to require a semi-colon to signify the end of the line
#pragma semicolon 1
// core includes
#define REQUIRE_PLUGIN
#include <sourcemod>
#undef REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#include <sdktools>

#define UBERSLAP_VERSION "1.0.1"
#define MAX_PLAYERS 64

// Plugin definitions
public Plugin:myinfo = 
{
	name = "UberSlap",
	author = "FlyingMongoose",
	description = "Slaps player continually until death with effects.",
	version = UBERSLAP_VERSION,
	url = "http://www.steamfriends.com/"
};

new Handle:UberSlapTime[MAX_PLAYERS+1];
new bool:BeingUberSlapped[MAX_PLAYERS+1];

new g_Lightning;
new g_ExplosionFire;
new g_Smoke1;
new g_Smoke2;
new g_FireBurst;

public OnPluginStart(){
	LoadTranslations("uberslap.phrases");
	
	CreateConVar("uberslap_version",UBERSLAP_VERSION, _,FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	
	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer){
	HookEvent("player_death",ev_PlayerDeath);
	HookEvent("player_spawn",ev_PlayerSpawn);
	RegAdminCmd("sm_uberslap",Command_UberSlap,ADMFLAG_SLAY);
}

public Action:Command_UberSlap(client,args){
	if(args < 1){
		ReplyToCommand(client,"[SM] Usage: sm_uberslap <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[65];
	GetCmdArg(1,arg,sizeof(arg));
	
	new target = FindTarget(client,arg);
	if(target <= 0){
		return Plugin_Handled;
	}
	
	if(BeingUberSlapped[target]){
		ReplyToCommand(client,"%t","Being UberSlapped");
		return Plugin_Handled;
	}
	
	if(!IsPlayerAlive(target)){
		ReplyToCommand(client,"%t","UberSlap Dead");
		return Plugin_Handled;
	}
	GetClientName(target, arg, sizeof(arg));
	
	UberSlap(target);

	ShowActivity(client, "%t","Was UberSlapped", arg);
	LogMessage("\"%L\" UberSlapped \"%L\"", client, target);
	
	return Plugin_Handled;
}

UberSlap(client){
	UberSlapTime[client] = CreateTimer(0.1,UberSlapTimer,client,TIMER_REPEAT);
	BeingUberSlapped[client] = true;
}

public Action:UberSlapTimer(Handle:timer, any:client){
	if(GetClientHealth(client) <= 1){
		SlayEffects(client);
	}
	Lightning(client);
	SlapPlayer(client,1);
}

public ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(BeingUberSlapped[client]){
		BeingUberSlapped[client] = false;
	}
	if(IsValidHandle(UberSlapTime[client])){
		// close uberslap timers
		CloseHandle(UberSlapTime[client]);
	}
}

public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(BeingUberSlapped[client]){
		BeingUberSlapped[client] = false;
	}
	if(IsValidHandle(UberSlapTime[client])){
		// close uberslap timers
		CloseHandle(UberSlapTime[client]);
	}
}

public OnMapEnd(){
	for(new client = 1; client <= GetMaxClients(); ++client){
		if(BeingUberSlapped[client]){
			// change uberslap
			BeingUberSlapped[client] = false;
		}
		if(IsValidHandle(UberSlapTime[client])){
			// close uberslap timers
			CloseHandle(UberSlapTime[client]);
		}
	}
}

public OnMapStart(){
	g_Lightning = PrecacheModel("materials/sprites/tp_beam001.vmt", false);
	// Precache explosion
	g_ExplosionFire = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	// precache smoke
	g_Smoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	// precache another smoke
	g_Smoke2 = PrecacheModel("materials/effects/fire_cloud2.vmt",false);
	// precache a little fire
	g_FireBurst = PrecacheModel("materials/sprites/fireburst.vmt",false);
	// precache the explosion sound (used with slay)
	PrecacheSound("ambient/explosions/explode_8.wav",false);
	// Make sure everything loaded right
	if(g_Lightning == 0 || g_Smoke1 == 0 || g_Smoke2 == 0 || g_FireBurst == 0 || g_ExplosionFire == 0 || !IsSoundPrecached("ambient/explosions/explode_8.wav")){
		SetFailState("[UberSlap] Precache Failed");
	}
}

// nifty pretties
stock SlayEffects(client)
{
	// get player position
	new Float:playerpos[3];
	GetClientAbsOrigin(client,playerpos);
	
	// set lightning settings
	// set the top coordinates of the lightning effect
	new Float:toppos[3];
	toppos[0] = playerpos[0];
	toppos[1] = playerpos[1];
	toppos[2] = playerpos[2]+1000;
	// set the color of the lightning
	new lightningcolor[4];
	lightningcolor[0] = 255;
	lightningcolor[1] = 255;
	lightningcolor[2] = 255;
	lightningcolor[3] = 255;
	// how long lightning lasts
	new Float:lightninglife = 2.0;
	// width of lightning at top
	new Float:lightningwidth = 5.0;
	// width of lightning at bottom
	new Float:lightningendwidth = 5.0;
	// lightning start frame
	new lightningstartframe = 0;
	// lightning frame rate
	new lightningframerate = 1;
	// how long it takes for lightning to fade
	new lightningfadelength = 1;
	// how bright lightning is
	new Float:lightningamplitude = 1.0;
	// how fast the effect is drawn
	new lightningspeed = 250;
	
	// set smoke settings
	// how wide a 360 degree radius of smoke should be used
	new Float:smokescale = 50.0;
	// frame rate for smoke
	new smokeframerate = 2;
	
	// coordinates for smoke effecet
	new Float:SmokePos[3];
	SmokePos[0] = playerpos[0];
	SmokePos[1] = playerpos[1];
	SmokePos[2] = playerpos[2] + 10;
	
	// coordinates for uppy body/head smoke efect
	new Float:PlayerHeadPos[3];
	PlayerHeadPos[0] = playerpos[0];
	PlayerHeadPos[1] = playerpos[1];
	PlayerHeadPos[2] = playerpos[2] + 100;
	
	// should the smoke be "blown" somewhere.
	new Float:direction[3];
	direction[0] = 0.0;
	direction[1] = 0.0;
	direction[2] = 0.0;
	
	new Float:sparkstart[3];
	sparkstart[0] = playerpos[0];
	sparkstart[1] = playerpos[1];
	sparkstart[2] = playerpos[2] + 13.0;
	
	new Float:sparkdir[3];
	sparkdir[0] = playerpos[0];
	sparkdir[1] = playerpos[1];
	sparkdir[2] = playerpos[2] + 23.0;
	
	// create lightning effects and sparks, and explosion
	TE_SetupBeamPoints(toppos, playerpos, g_Lightning, g_Lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	TE_SetupExplosion(playerpos, g_ExplosionFire, 10.0, 10, TE_EXPLFLAG_NONE, 200, 255);
	TE_SetupSmoke(playerpos, g_Smoke1, smokescale, smokeframerate);
	TE_SetupSmoke(playerpos, g_Smoke2, smokescale, smokeframerate);
	TE_SetupMetalSparks(sparkstart,sparkdir);
	
	
	TE_SendToAll(0.0);
	EmitAmbientSound("ambient/explosions/explode_8.wav", playerpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
}

stock Lightning(client)
{
	// get player position
	new Float:playerpos[3];
	GetClientAbsOrigin(client,playerpos);
	
	// set lightning settings
	// set the top coordinates of the lightning effect
	new Float:toppos[3];
	toppos[0] = playerpos[0];
	toppos[1] = playerpos[1];
	toppos[2] = playerpos[2]+1000;
	// set the color of the lightning
	new lightningcolor[4];
	lightningcolor[0] = 255;
	lightningcolor[1] = 255;
	lightningcolor[2] = 255;
	lightningcolor[3] = 255;
	
	// how long lightning lasts
	new Float:lightninglife = 0.1;
	// width of lightning at top
	new Float:lightningwidth = 5.0;
	// width of lightning at bottom
	new Float:lightningendwidth = 5.0;
	// lightning start frame
	new lightningstartframe = 0;
	// lightning frame rate
	new lightningframerate = 1;
	// how long it takes for lightning to fade
	new lightningfadelength = 1;
	// how bright lightning is
	new Float:lightningamplitude = 1.0;
	// how fast the effect is drawn
	new lightningspeed = 250;
	
	TE_SetupBeamPoints(toppos, playerpos, g_Lightning, g_Lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	
	TE_SendToAll(0.0);
}