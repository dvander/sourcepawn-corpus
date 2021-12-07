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

new bool:punished[MAXPLAYERS+1][MAXPLAYERS+1];

new Handle:TimerHandle[MAXPLAYERS+1];

new g_Lightning;
new g_ExplosionFire;
new g_Smoke1;
new g_Smoke2;
new g_FireBurst;

new Handle:Punishment;

public OnPluginStart(){
	LoadTranslations("atac.phrases");
	LoadTranslations("atac_slay.phrases");
}

public OnATACLoaded(){
	HookEvent("player_spawn",ev_PlayerSpawn);
	decl String:SlayStr[128];
	Format(SlayStr,sizeof(SlayStr),"%t","Menu Slay");
	Punishment = RegisterPunishment("MenuSlay",SlayStr);
}

public OnPluginEnd(){
	UnregisterPunishment(Punishment);
}

public MenuSlay(victim,attacker){
	if(attacker != 0 && victim != 0){
		if(IsClientConnected(attacker) && IsClientInGame(attacker)){
			new CurrTKValue = ATACGetClient(TEAMKILLS,attacker);
			new newTKValue = CurrTKValue + 1;
			ATACSetClient(TEAMKILLS,attacker,newTKValue);
			decl String:attackerName[64];
			GetClientName(attacker,attackerName,sizeof(attackerName));
			if(IsPlayerAlive(attacker)){
				punished[attacker][victim] = true;
				NiftySlay(attacker,victim);
			}else{
				PrintToConsole(victim,"[ATAC] %t","Slay Next Spawn",attackerName);
				PrintToChat(victim,"%c[ATAC]%c %t",GREEN,YELLOW,"Slay Next Spawn",attackerName);
				SlayNextSpawn[attacker] = true;
				punished[attacker][victim] = true;
			}
		}
	}
}

public ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(SlayNextSpawn[client] && IsClientConnected(client)){
		new Float:delay = float(ATACGetPunishDelay());
		TimerHandle[client] = CreateTimer(delay,SlayDelay);
	}
}

public Action:SlayDelay(Handle:timer){
	decl String:attackerName[64];
	for(new attacker = 1; attacker <= GetMaxClients(); ++attacker){
		if(IsClientConnected(attacker) && IsClientInGame(attacker) && SlayNextSpawn[attacker]){
			GetClientName(attacker,attackerName,sizeof(attackerName));
			for(new victim = 1; victim <= GetMaxClients(); ++victim){
				// BEGIN MOD BY LAMDACORE this has to be there otherwise the attacker would be slayed for all players being victim
				if (punished[attacker][victim]){
				// END MOD BY LAMDACORE
					NiftySlay(attacker,victim);
					punished[attacker][victim] = false;
				// BEGIN MOD BY LAMDACORE
				}
				// END MOD BY LAMDACORE
			}
			//SlayNextSpawn[attacker] = false;
		}
		SlayNextSpawn[attacker] = false; // MOD BY LAMDACORE this has to be resetted even the client disconnects
	}
	return Plugin_Stop; // MOD BY LAMDACORE mabe important
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
	TE_SetupExplosion(playerpos, g_ExplosionFire, 10.0, 10, TE_EXPLFLAG_NONE,15,15);
	TE_SetupSmoke(playerpos, g_Smoke1, smokescale, smokeframerate);
	TE_SetupSmoke(playerpos, g_Smoke2, smokescale, smokeframerate);
	TE_SetupMetalSparks(sparkstart,sparkdir);

	TE_SendToAll(0.0);
	EmitAmbientSound("ambient/explosions/explode_8.wav", playerpos, SOUND_FROM_WORLD, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, 0.0);
}

NiftySlay(attacker,victim){
	if(IsClientInGame(attacker) && IsClientInGame(victim)){
		decl String:attackerName[64];
		GetClientName(attacker,attackerName,64);
		if(punished[attacker][victim]){
			PrintToConsole(victim,"[ATAC] %t","Punish Slay",attackerName,ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
			PrintToChat(victim,"%c[ATAC]%c %t",GREEN,YELLOW,"Punish Slay",attackerName,ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
			PrintToConsole(attacker,"[ATAC] %t","Were Slain",ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
			PrintToChat(attacker,"%c[ATAC]%c %t",GREEN,YELLOW,"Were Slain",ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
			punished[attacker][victim] = false;
		}
		// BEGIN MOD BY LAMDACORE
		new attackerTeam = GetClientTeam(attacker);
		new victimTeam = GetClientTeam(victim);
		decl String:victimName[64];
		GetClientName(victim,victimName,64);
		LogToGame("[ATAC] Slaying %s(Team:%d) for TKing %s(Team:%d)", attackerName, attackerTeam, victimName, victimTeam);
		// END MOD BY LAMDACORE
		SlayEffects(attacker);
		ForcePlayerSuicide(attacker);	
	}
}