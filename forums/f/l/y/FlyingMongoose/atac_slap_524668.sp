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
	name = "ATAC Punishment Slap",
	author = "FlyingMongoose",
	description = "Slap punishment for ATAC",
	version = ATAC_VERSION,
	url = "http://www.steamfriends.com/"
};

new Handle:cvarSlapDamage;
new bool:SlapNextSpawn[MAXPLAYERS+1];
new bool:deadpunished[MAXPLAYERS+1][MAXPLAYERS+1];

new Handle:TimerHandle[MAXPLAYERS+1];

public OnPluginStart(){
	cvarSlapDamage = CreateConVar("atac_slapdamage","50","Value to slap for when slap is selected from the punishment menu",FCVAR_PLUGIN,true,0.0,true,100.0);
}

public OnATACLoaded(){
	HookEvent("player_spawn",ev_PlayerSpawn);
	
	decl String:SlapStr[128];
	Format(SlapStr,sizeof(SlapStr),"Slap for %d damage",GetConVarInt(cvarSlapDamage));
	RegisterPunishment("MenuSlap",SlapStr);
}

public MenuSlap(victim,attacker){
	new CurrTKValue = ATACGetClient(TEAMKILLS,attacker);
	new newTKValue = CurrTKValue + 1;
	ATACSetClient(TEAMKILLS,attacker,newTKValue);
	if(IsClientInGame(attacker)){
		decl String:attackerName[64];
		GetClientName(attacker,attackerName,sizeof(attackerName));
		if(IsPlayerAlive(attacker)){
			SlapPlayer(attacker,GetConVarInt(cvarSlapDamage));
			PrintToConsole(victim,"[ATAC] %s has been slapped for team killing and now has %d/%d team kills.",attackerName,newTKValue,ATACGetMax(TEAMKILLS));
			PrintToChat(victim,"%c[ATAC]%c %s has been slapped for team killing and now has %d/%d team kills.",GREEN,YELLOW,attackerName,newTKValue,ATACGetMax(TEAMKILLS));
			PrintToConsole(attacker,"[ATAC] You have been slapped for team killing you now have %d/%d team kills.",newTKValue,ATACGetMax(TEAMKILLS));
			PrintToChat(attacker,"%c[ATAC]%c You have been slapped for team killing you now have %d/%d team kills.",GREEN,YELLOW,newTKValue,ATACGetMax(TEAMKILLS));
		}else{
			PrintToConsole(victim,"[ATAC] %s will be slapped next spawn.",attackerName);
			PrintToChat(victim,"%c[ATAC]%c %s will be slapped next spawn.",GREEN,YELLOW,attackerName);
			SlapNextSpawn[attacker] = true;
			deadpunished[attacker][victim] = true;
		}
	}
}

public ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(SlapNextSpawn[client]){
		new Float:delay = float(ATACGetPunishDelay());
		TimerHandle[client] = CreateTimer(delay,SlapDelay);
	}
}

public Action:SlapDelay(Handle:timer){
	decl String:attackerName[64];
	new slapDamage = GetConVarInt(cvarSlapDamage);
	for(new attacker = 1; attacker <= GetMaxClients(); ++attacker){
		if(SlapNextSpawn[attacker]){
			GetClientName(attacker,attackerName,sizeof(attackerName));
			SlapPlayer(attacker,slapDamage);
			for(new victim = 1; victim <= GetMaxClients(); ++victim){
				if(deadpunished[attacker][victim]){
					PrintToConsole(victim,"[ATAC] %s has been slapped for team killing and now has %d/%d team kills.",attackerName,ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
					PrintToChat(victim,"%c[ATAC]%c %s has been slapped for team killing and now has %d/%d team kills.",GREEN,YELLOW,attackerName,ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
					deadpunished[attacker][victim] = false;
				}
			}
			PrintToConsole(attacker,"[ATAC] You have been slapped for team killing you now have %d/%d team kills.",ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
			PrintToChat(attacker,"%c[ATAC]%c You have been slapped for team killing you now have %d/%d team kills.",GREEN,YELLOW,ATACGetClient(TEAMKILLS,attacker),ATACGetMax(TEAMKILLS));
			SlapNextSpawn[attacker] = false;
		}
	}
}

public OnClientDisconnect(client){
	if(TimerHandle[client] != INVALID_HANDLE){
		CloseHandle(TimerHandle[client]);
	}
}