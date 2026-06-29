#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
    name = "Zombie Riot Alpha Fix",
};


public OnPluginStart(){
	HookEvent("player_spawn",PlayerSpawn, EventHookMode_Post);
}

//Player Spawns
public Action:PlayerSpawn(Handle:event,const String:name[], bool:dontBroadcast){
	//Creete Spawn Timer Event
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	CreateTimer(0.1, SpawnTimerSettings, client);
}

//Player Spawn Event Handle
public Action:SpawnTimerSettings(Handle:timer, any:client){
	
	//Check if Player is Valid 
	if(client > 0 ){
	
		//Check if player is Ingame and is connected also checks if player is not a bot
		if(IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		{
			//Checks if Player is Alive and is on CT Team
			if(IsPlayerAlive(client) && (GetClientTeam(client) == 3)){
			
				//Sets Weapon Alpha to Visable
				SetWeaponAlpha(client);
				
				//Repeat Timer to Prevent Alpha Glitching
				CreateTimer(1.0, SpawnTimerSettings, client);
			}
		}
	}
}

//Set Weapon Alpha
Void:SetWeaponAlpha(client)
{
	new wepIdx;
	
	//Loop through Weapons
	for (new s = 0; s < 5; s++){
	
		//Get Weapon in that Slot
		if ((wepIdx = GetPlayerWeaponSlot(client, s)) != -1){
		
			//Set Alpha to Visable
			SetEntityRenderColor(wepIdx, 255, 255, 255, 255);
			SetEntityRenderMode(wepIdx, RENDER_TRANSCOLOR); 
		}
	}
}