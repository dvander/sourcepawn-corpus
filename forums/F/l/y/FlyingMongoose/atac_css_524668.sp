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
	name = "ATAC Counter-Strike: Source",
	author = "FlyingMongoose",
	description = "CS: Source Karma Plugin",
	version = ATAC_VERSION,
	url = "http://www.steamfriends.com/"
};

new Handle:cvarHostageRescuedKarma;
new Handle:cvarBombPlantedKarma;
new Handle:cvarBombExplodedKarma;
new Handle:cvarBombDefusedKarma;

public OnPluginStart(){
	cvarHostageRescuedKarma = CreateConVar("atac_hostagerescuedkarma","1","Karma value gained when a hostage is rescued",FCVAR_PLUGIN,true,0.0,false);
	cvarBombPlantedKarma = CreateConVar("atac_bombplantedkarma","1","Karma value gained when the bomb has been planted",FCVAR_PLUGIN,true,0.0,false);
	cvarBombExplodedKarma = CreateConVar("atac_bombexplodedkarma","2","Karma value gained when the bomb successfully explodes",FCVAR_PLUGIN,true,0.0,false);
	cvarBombDefusedKarma = CreateConVar("atac_bombdefusedkarma","3","Karma value gained when the bomb has been successfully defused",FCVAR_PLUGIN,true,0.0,false);
}

public OnATACLoaded(){
	HookEvent("hostage_rescued",ev_HostageRescued);
	HookEvent("bomb_planted",ev_BombPlanted);
	HookEvent("bomb_exploded",ev_BombExploded);
	HookEvent("bomb_defused",ev_BombDefused);
}

public ev_HostageRescued(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarHostageRescuedKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0){
		new Rescuer = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,Rescuer);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,Rescuer,newKarma)){
			PrintToChat(Rescuer,"%c[ATAC]%c You have earned %d/%d karma for rescuing a hostage.",GREEN,YELLOW,newKarma,maxKarma);
		}
	}
}

public ev_BombPlanted(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarBombPlantedKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0){
		new planter = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,planter);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,planter,newKarma)){
			PrintToChat(planter,"%c[ATAC]%c You have earned %d/%d karma for planting the bomb.",GREEN,YELLOW,newKarma,maxKarma);
		}
	}
}

public ev_BombExploded(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarBombExplodedKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0){
		new planter = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,planter);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,planter,newKarma)){
			PrintToChat(planter,"%c[ATAC]%c You have earned %d/%d karma for detonating the bomb.",GREEN,YELLOW,newKarma,maxKarma);
		}
	}
}

public ev_BombDefused(Handle:event, const String:name[], bool:dontBroadcast){
	new karmaPoints = GetConVarInt(cvarBombDefusedKarma);
	new maxKarma = ATACGetMax(KARMA);
	if(maxKarma != 0 && karmaPoints > 0){
		new defuser = GetClientOfUserId(GetEventInt(event,"userid"));
		new currKarma = ATACGetClient(KARMA,defuser);
		new newKarma = currKarma + karmaPoints;
		if(!ATACSetClient(KARMA,defuser,newKarma)){
			PrintToChat(defuser,"%c[ATAC]%c You have earned %d/%d karma for defusing the bomb.",GREEN,YELLOW,newKarma,maxKarma);
		}
	}
}