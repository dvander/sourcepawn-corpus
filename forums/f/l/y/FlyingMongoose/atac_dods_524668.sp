#pragma semicolon 1
#pragma dynamic 65536
#define REQUIRE_PLUGIN
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <atac>

#define YELLOW 0x01
#define TEAMCOLOR 0X03
#define GREEN 0x04
#define ATAC_VERSION "2.0.0"

public Plugin:myinfo =
{
	name = "ATAC DoD: Source",
	author = "FlyingMongoose",
	description = "DoD: Source Karma Plugin",
	version = ATAC_VERSION,
	url = "http://www.steamfriends.com/"
};

new Handle:cvarPointCaptureKarma;
new Handle:cvarCaptureBlockedKarma;
new Handle:cvarBombPlantedKarma;
new Handle:cvarBombExplodedKarma;
new Handle:cvarBombDefusedKarma;
new Handle:cvarKillPlanterKarma;
new Handle:cvarKillDefuserKarma;
new Handle:cvarRoundWinKarma;

public OnPluginStart(){
	cvarPointCaptureKarma = CreateConVar("atac_pointcapturekarma","3","Amount of karma to award for a point capture",FCVAR_PLUGIN,true,0.0,false);
	cvarCaptureBlockedKarma = CreateConVar("atac_captureblockkarma","2","Amount of karma to award for preventing a point capture",FCVAR_PLUGIN,true,0.0,false);
	cvarBombPlantedKarma = CreateConVar("atac_bombplantedkarma","1","Amount of karma to award for planting TNT",FCVAR_PLUGIN,true,0.0,false);
	cvarBombExplodedKarma = CreateConVar("atac_bombexplodedkarma","2","Amount of karma to award for TNT successfully exploding",FCVAR_PLUGIN,true,0.0,false);
	cvarBombDefusedKarma = CreateConVar("atac_bombdefusedkarma","2","Amount of karma to award for defusing TNT",FCVAR_PLUGIN,true,0.0,false);
	cvarKillPlanterKarma = CreateConVar("atac_killplanterkarma","1","Amount of karma to award for killing bomb planter (during plant)",FCVAR_PLUGIN,true,0.0,false);
	cvarKillDefuserKarma = CreateConVar("atac_killdefuserkarma","1","Amount of karma to award for killing bomb defuser (during defuse)",FCVAR_PLUGIN,true,0.0,false);
	cvarRoundWinKarma = CreateConVar("atac_roundwinkarma","2","Amount of karma to award for team winning the round",FCVAR_PLUGIN,true,0.0,false);
}

public OnATACLoaded(){
	HookEvent("dod_point_captured",ev_PointCaptured);
	HookEvent("dod_capture_blocked",ev_CaptureBlocked);
	HookEvent("dod_bomb_planted",ev_BombPlanted);
	HookEvent("dod_bomb_exploded",ev_BombExploded);
	HookEvent("dod_bomb_defused",ev_BombDefused);
	HookEvent("dod_kill_planter",ev_KillPlanter);
	HookEvent("dod_kill_defuser",ev_KillDefuser);
	HookEvent("dod_round_win",ev_RoundWin);
	
	decl String:SlayStr[128];
	Format(SlayStr,sizeof(SlayStr),"Slay");
	RegisterPunishment("MenuSlay",SlayStr);
}

public ev_PointCaptured(Handle:event, const String:name[], bool:dontBroadcast){
	if(!GetEventBool(event,"bomb")){
		new karmaPoints = GetConVarInt(cvarPointCaptureKarma);
		new maxKarma = ATACGetMax(KARMA);
		if(maxKarma != 0 && karmaPoints > 0 ){
			decl String:Cappers[256];
			GetEventString(event,"cappers",Cappers,sizeof(Cappers));
			new capperlen = strlen(Cappers);
			for(new i; i < capperlen; i++){
				new target = Cappers[i];
				new currKarma = ATACGetClient(KARMA,target);
				new newKarma = currKarma + karmaPoints;
				if(!ATACSetClient(KARMA,target,newKarma)){
					PrintToChat(target,"%c[ATAC]%c You have earned %d/%d karma for capturing a point.",GREEN,YELLOW,newKarma,maxKarma);
				}
			}
		}
	}
}

public ev_CaptureBlocked(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarCaptureBlockedKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0 ){
		new blocker = GetClientOfUserId(GetEventInt(event,"blocker"));
		new currKarma = ATACGetClient(KARMA,blocker);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,blocker,newKarma)){
			PrintToChat(blocker,"%c[ATAC]%c You have earned %d/%d karma for blocking a capture.",GREEN,YELLOW,newKarma,maxKarma);
		}
	}
}

public ev_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarBombPlantedKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0 ){
		new planter = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,planter);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,planter,newKarma)){
			PrintToChat(planter,"%c[ATAC]%c You have earned %d/%d karma for planting the TNT.",GREEN,YELLOW,newKarma,maxKarma);
		}
	}
}

public ev_BombExploded(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarBombExplodedKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0 ){
		new planter = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,planter);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,planter,newKarma)){
			PrintToChat(planter,"%c[ATAC] You have earned %d/%d karma for a TNT explosion.",GREEN,YELLOW,newKarma,maxKarma);
		}
	}
}

public ev_BombDefused(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarBombDefusedKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0 ){
		new defuser = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,defuser);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,defuser,newKarma)){
			PrintToChat(defuser,"%c[ATAC] You have earned %d/%d karma for defusing the TNT.",GREEN,YELLOW,newKarma,maxKarma);
		}
	}
}

public ev_KillPlanter(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarKillPlanterKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0 ){
		new attacker = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,attacker);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,attacker,newKarma)){
			PrintToChat(attacker,"%c[ATAC]%c You have earned %d/%d karma for killing the planter.",GREEN, YELLOW, newKarma,maxKarma);
		}
	}
}

public ev_KillDefuser(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarKillDefuserKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0 ){
		new attacker = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,attacker);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,attacker,newKarma)){
			PrintToChat(attacker,"%c[ATAC]%c You have earned %d/%d karma for killing the defuser.",GREEN, YELLOW, newKarma,maxKarma);
		}
	}
}

public ev_RoundWin(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarRoundWinKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0 ){
		new WinningTeam = GetEventInt(event,"team");
		if(WinningTeam < 1) return;
		for(new player = 1; player <= GetMaxClients(); ++player){
			if(IsClientInGame(player) && GetClientTeam(player) == WinningTeam){
				new currKarma = ATACGetClient(KARMA,player);
				new newKarma = currKarma + karmaPoints;
				if(!ATACSetClient(KARMA,player,newKarma)){
					PrintToChat(player,"%c[ATAC]%c You have earned %d/%d karma for winning the round.",GREEN, YELLOW, newKarma,maxKarma);
				}
			}
		}
	}
}