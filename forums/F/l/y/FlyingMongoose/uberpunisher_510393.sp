// Force all lines to require a semi-colon to signify the end of the line
#pragma semicolon 1
// core includes
#define REQUIRE_PLUGIN
#include <sourcemod>
#undef REQUIRE_PLUGIN
#define REQUIRE_EXTENSIONS
#include <sdktools>

#define UBERPUNISHER_VERSION "1.5.2"

// Plugin definitions
public Plugin:myinfo =
{
	name = "UberPunisher",
	author = "FlyingMongoose",
	description = "Numerous repeatative damage slays and slaps",
	version = UBERPUNISHER_VERSION,
	url = "http://www.steamfriends.com/"
};

new Handle:UberSlapTime[MAXPLAYERS+1];
new bool:BeingUberSlapped[MAXPLAYERS+1];
new Handle:UberSlamTime[MAXPLAYERS+1];
new bool:BeingUberSlammed[MAXPLAYERS+1];


new g_Lightning;
new g_ExplosionFire;
new g_Smoke1;
new g_Smoke2;
new g_FireBurst;

public OnPluginStart(){
	LoadTranslations("uberpunisher.phrases");
	LoadTranslations("common.phrases");

	CreateConVar("uberpunisher_version",UBERPUNISHER_VERSION, _,FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	
	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer){
	HookEvent("player_death",ev_PlayerDeath);
	HookEvent("player_spawn",ev_PlayerSpawn);
	RegAdminCmd("sm_uberslap",Command_UberSlap,ADMFLAG_SLAY);
	RegAdminCmd("sm_uberslam",Command_UberSlam,ADMFLAG_SLAY);
}

public Action:Command_UberSlam(client,args){
	new String:arg1[65], String:arg2[32];
	new damage = 0;
	if(args < 1){
		ReplyToCommand(client,"[SM] Usage: sm_uberslam <#userid|name> <to or below health value>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
		damage = StringToInt(arg2);
		if(damage < 0){
			ReplyToCommand(client,"Invalid Health Value to UberSlam To");
			return Plugin_Handled;
		}
	}
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS+1], target_count;
	new bool:tn_is_ml;
		
	target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS+1,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml);
	if(target_count <= 0)
	{
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}else{
		for(new i = 0; i < target_count; ++i)
		{
			if(BeingUberSlammed[target_list[i]])
			{
				ReplyToCommand(client,"%t","Being UberSlammed");
				return Plugin_Handled;
			}
			if(!IsPlayerAlive(target_list[i]))
			{
				ReplyToCommand(client,"%t","UberSlam Dead");
				return Plugin_Handled;
			}
			UberSlam(target_list[i], damage);
		}
	}
	if(tn_is_ml){
		ShowActivity(client,"%t","Was UberSlammed",target_name);
		LogMessage("\"%L\" UberSlammed \"%L\"", client, target_name);
	}else{
		ShowActivity(client,"%t","Was UberSlammed","_s",target_name);
		LogMessage("\"%L\" UberSlammed \"%L\"", client, target_name);
	}
	return Plugin_Handled;
}

UberSlam(client,damage){
	new Handle:ClientDamagePack = CreateDataPack();
	WritePackCell(ClientDamagePack,client);
	WritePackCell(ClientDamagePack,damage);
	BeingUberSlammed[client] = true;
	SetEntityGravity(client,10.0);
	UberSlamTime[client] = CreateTimer(0.5,UberSlamTimer,ClientDamagePack,TIMER_REPEAT);
	
}

public Action:UberSlamTimer(Handle:timer, Handle:ClientDamagePack){
	ResetPack(ClientDamagePack);
	new client = ReadPackCell(ClientDamagePack);
	new damage = ReadPackCell(ClientDamagePack);
	if(GetClientHealth(client) <= 0){
		SlayEffects(client);
		BeingUberSlammed[client] = false;
		SetEntityGravity(client,1.0);
		UberSlamTime[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(GetClientHealth(client) <= damage){
		BeingUberSlammed[client] = false;
		SetEntityGravity(client,1.0);
		UberSlamTime[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	SlamPlayer(client);
	return Plugin_Continue;
}

SlamPlayer(client){
	new Float:Origin[3];
	new Float:Angles[3];
	new Float:Velocity[3];
	GetClientAbsAngles(client,Angles);
	GetClientAbsOrigin(client,Origin);
	Velocity[0] = 0.0;
	Velocity[1] = 0.0;
	Velocity[2] += 1500.0;
	TeleportEntity(client,Origin,Angles,Velocity);
}

public Action:Command_UberSlap(client,args){
	new String:arg1[65], String:arg2[32];
	new damage = 0;
	if(args < 1){
		ReplyToCommand(client,"[SM] Usage: sm_uberslap <#userid|name> <to health value>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
		damage = StringToInt(arg2);
		if(damage < 0){
			ReplyToCommand(client,"Invalid Health Value to UberSlap To");
			return Plugin_Handled;
		}
	}
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS+1], target_count;
	new bool:tn_is_ml;
		
	target_count = ProcessTargetString(arg1,client,target_list,MAXPLAYERS+1,COMMAND_FILTER_ALIVE,target_name,sizeof(target_name),tn_is_ml);
	
	if(target_count <= 0)
	{
		ReplyToTargetError(client,target_count);
		return Plugin_Handled;
	}else{
		for(new i = 0; i < target_count; ++i)
		{
			if(BeingUberSlapped[target_list[i]])
			{
				ReplyToCommand(client,"%T","Being UberSlapped");
				return Plugin_Handled;
			}
			if(!IsPlayerAlive(target_list[i]))
			{
				ReplyToCommand(client,"%T","UberSlap Dead");
				return Plugin_Handled;
			}
			UberSlap(target_list[i], damage);
		}
	}
	if(tn_is_ml){
		ShowActivity(client,"%T","Was UberSlapped",target_name);
		LogMessage("\"%L\" UberSlapped \"%L\"", client, target_name);
	}else{
		ShowActivity(client,"%T","Was UberSlapped","_s",target_name);
		LogMessage("\"%L\" UberSlapped \"%L\"", client, target_name);
	}
	return Plugin_Handled;
}

UberSlap(client,damage){
	new Handle:ClientDamagePack = CreateDataPack();
	WritePackCell(ClientDamagePack,client);
	WritePackCell(ClientDamagePack,damage);
	UberSlapTime[client] = CreateTimer(0.1,UberSlapTimer,ClientDamagePack,TIMER_REPEAT);
	BeingUberSlapped[client] = true;
}

public Action:UberSlapTimer(Handle:timer, Handle:ClientDamagePack){
	ResetPack(ClientDamagePack);
	new client = ReadPackCell(ClientDamagePack);
	new damage = ReadPackCell(ClientDamagePack);
	if(GetClientHealth(client) <= 0){
		SlayEffects(client);
		BeingUberSlapped[client] = false;
		UberSlapTime[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(GetClientHealth(client) <= damage){
		BeingUberSlapped[client] = false;
		UberSlapTime[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	Lightning(client);
	SlapPlayer(client,1);
	return Plugin_Continue;
}

public ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(BeingUberSlapped[client]){
		BeingUberSlapped[client] = false;
	}
	if(UberSlapTime[client] != INVALID_HANDLE){
		// close uberslap timers
		CloseHandle(UberSlapTime[client]);
		UberSlapTime[client] = INVALID_HANDLE;
	}
	if(BeingUberSlammed[client]){
			BeingUberSlammed[client] = false;
		}
	if(UberSlamTime[client] != INVALID_HANDLE){
			CloseHandle(UberSlamTime[client]);
			UberSlamTime[client] = INVALID_HANDLE;
	}
	SetEntityGravity(client,1.0);
}

public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(BeingUberSlapped[client]){
		BeingUberSlapped[client] = false;
	}
	if(UberSlapTime[client] != INVALID_HANDLE){
		// close uberslap timers
		CloseHandle(UberSlapTime[client]);
		UberSlapTime[client] = INVALID_HANDLE;
	}
	if(BeingUberSlammed[client]){
		BeingUberSlammed[client] = false;
		}
	if(UberSlamTime[client] != INVALID_HANDLE){
		CloseHandle(UberSlamTime[client]);
		UberSlamTime[client] = INVALID_HANDLE;
	}
	SetEntityGravity(client,1.0);
}

public OnMapEnd(){
	for(new client = 1; client <= GetMaxClients(); ++client){
		if(BeingUberSlapped[client]){
			// change uberslap
			BeingUberSlapped[client] = false;
		}
		if(UberSlapTime[client] != INVALID_HANDLE){
			// close uberslap timers
			CloseHandle(UberSlapTime[client]);
			UberSlapTime[client] = INVALID_HANDLE;
		}
		if(BeingUberSlammed[client]){
			BeingUberSlammed[client] = false;
		}
		if(UberSlamTime[client] != INVALID_HANDLE){
			CloseHandle(UberSlamTime[client]);
			UberSlamTime[client] = INVALID_HANDLE;
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