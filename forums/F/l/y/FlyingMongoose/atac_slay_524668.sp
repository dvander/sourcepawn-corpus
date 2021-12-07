#pragma semicolon 1
#pragma dynamic 65536
#define REQUIRE_PLUGIN
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <atac>
#define REQUIRE_EXTENSIONS
#include <sdktools>
#undef REQUIRE_EXTENSIONS

#define YELLOW 0x01
#define TEAMCOLOR 0X03
#define GREEN 0x04
#define ATAC_VERSION "2.0.0"

public Plugin:myinfo =
{
	name = "ATAC Punishment Slay",
	author = "FlyingMongoose",
	description = "Slay punishment for ATAC",
	version = ATAC_VERSION,
	url = "http://www.steamfriends.com/"
};

new bool:SlayNextSpawn[MAXPLAYERS+1];

new bool:deadpunished[MAXPLAYERS+1][MAXPLAYERS+1];

new Handle:TimerHandle[MAXPLAYERS+1];

new g_Lightning;
new g_ExplosionFire;
new g_Smoke1;
new g_Smoke2;
new g_FireBurst;


public OnATACLoaded(){
	HookEvent("player_spawn",ev_PlayerSpawn);
	
	decl String:SlayStr[128];
	Format(SlayStr,sizeof(SlayStr),"Slay");
	RegisterPunishment("MenuSlay",SlayStr);
}

public MenuSlay(victim,attacker){
	new CurrTKValue = ATACGetClient(TEAMKILLS,attacker);
	new newTKValue = CurrTKValue + 1;
	ATACSetClient(TEAMKILLS,attacker,newTKValue);
	if(IsClientInGame(attacker)){
		decl String:attackerName[64];
		GetClientName(attacker,attackerName,sizeof(attackerName));
		if(IsPlayerAlive(attacker)){
			NiftySlay(attacker);
			PrintToConsole(victim,"[ATAC] %s has been slain for team killing and now has %d/%d team kills.",attackerName,newTKValue,ATACGetMax(TEAMKILLS));
			PrintToChat(victim,"%c[ATAC]%c %s has been slain for team killing and now has %d/%d team kills.",GREEN,YELLOW,attackerName,newTKValue,ATACGetMax(TEAMKILLS));
			PrintToConsole(attacker,"[ATAC] You have been slain for team killing you now have %d/%d team kills.",newTKValue,ATACGetMax(TEAMKILLS));
			PrintToChat(attacker,"%c[ATAC]%c You have been slain for team killing you now have %d/%d team kills.",GREEN,YELLOW,newTKValue,ATACGetMax(TEAMKILLS));
		}else{
			PrintToConsole(victim,"[ATAC] %s will be slain next spawn.",attackerName);
			PrintToChat(victim,"%c[ATAC]%c %s will be slain next spawn.",GREEN,YELLOW,attackerName);
			SlayNextSpawn[attacker] = true;
			deadpunished[attacker][victim] = true;
		}
	}
}

public ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(SlayNextSpawn[client]){
		new Float:delay = float(ATACGetPunishDelay());
		TimerHandle[client] = CreateTimer(delay,SlayDelay);
	}
}

public Action:SlayDelay(Handle:timer){
	decl String:attackerName[64];
	for(new attacker = 1; attacker <= GetMaxClients(); ++attacker){
		if(SlayNextSpawn[attacker]){
			GetClientName(attacker,attackerName,sizeof(attackerName));
			NiftySlay(attacker);
			for(new victim = 1; victim <= GetMaxClients(); ++victim){
				if(deadpunished[attacker][victim]){
					PrintToConsole(victim,"[ATAC] %s has been slain for team killing and now has %d/%d team kills.",attackerName,ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
					PrintToChat(victim,"%c[ATAC]%c %s has been slain for team killing and now has %d/%d team kills.",GREEN,YELLOW,attackerName,ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
					deadpunished[attacker][victim] = false;
				}
			}
			PrintToConsole(attacker,"[ATAC] You have been slain for team killing you now have %d/%d team kills.",ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
			PrintToChat(attacker,"%c[ATAC]%c You have been slain for team killing you now have %d/%d team kills.",GREEN,YELLOW,ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
			SlayNextSpawn[attacker] = false;
		}
	}
}

public OnClientDisconnect(client){
	if(TimerHandle[client] != INVALID_HANDLE){
		CloseHandle(TimerHandle[client]);
	}
}

public OnMapStart(){
	g_Lightning = PrecacheModel("materials/sprites/tp_beam001.vmt", false);
	g_ExplosionFire = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	g_Smoke1 = PrecacheModel("materials/effects/fire_cloud1.vmt",false);
	g_Smoke2 = PrecacheModel("materials/effects/fire_cloud2.vmt",false);
	g_FireBurst = PrecacheModel("materials/sprites/fireburst.vmt",false);
	PrecacheSound("ambient/explosions/explode_8.wav",false);
	if(g_Lightning == 0 || g_Smoke1 == 0 || g_Smoke2 == 0 || g_FireBurst == 0 || g_ExplosionFire == 0){
		SetFailState("[ATAC] Slay Precache Failed");
	}
}

stock SlayEffects(client)
{
	new Float:playerpos[3];
	GetClientAbsOrigin(client,playerpos);
	new Float:toppos[3];
	toppos[0] = playerpos[0];
	toppos[1] = playerpos[1];
	toppos[2] = playerpos[2]+1000;
	new lightningcolor[4];
	lightningcolor[0] = 255;
	lightningcolor[1] = 255;
	lightningcolor[2] = 255;
	lightningcolor[3] = 255;
	new Float:lightninglife = 2.0;
	new Float:lightningwidth = 5.0;
	new Float:lightningendwidth = 5.0;
	new lightningstartframe = 0;
	new lightningframerate = 1;
	new lightningfadelength = 1;
	new Float:lightningamplitude = 1.0;
	new lightningspeed = 250;

	new Float:smokescale = 50.0;
	new smokeframerate = 2;

	new Float:SmokePos[3];
	SmokePos[0] = playerpos[0];
	SmokePos[1] = playerpos[1];
	SmokePos[2] = playerpos[2] + 10;

	new Float:PlayerHeadPos[3];
	PlayerHeadPos[0] = playerpos[0];
	PlayerHeadPos[1] = playerpos[1];
	PlayerHeadPos[2] = playerpos[2] + 100;

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

	TE_SetupBeamPoints(toppos, playerpos, g_Lightning, g_Lightning, lightningstartframe, lightningframerate, lightninglife, lightningwidth, lightningendwidth, lightningfadelength, lightningamplitude, lightningcolor, lightningspeed);
	TE_SetupExplosion(playerpos, g_ExplosionFire, 10.0, 10, TE_EXPLFLAG_NONE, 200, 255);
	TE_SetupSmoke(playerpos, g_Smoke1, smokescale, smokeframerate);
	TE_SetupSmoke(playerpos, g_Smoke2, smokescale, smokeframerate);
	TE_SetupMetalSparks(sparkstart,sparkdir);

	TE_SendToAll(0.0);
	EmitAmbientSound("ambient/explosions/explode_8.wav", playerpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
}

NiftySlay(client){
	SlayEffects(client);
	ForcePlayerSuicide(client);	
}