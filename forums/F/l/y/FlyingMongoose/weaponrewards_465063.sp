#pragma semicolon 1

#include <sourcemod>
#include <console>
#include <events>
#include <entity>
#include <string>
#include <clients>
#include <core>
#include <float>
#include <files>

// Colors
#define GREEN 0x04
#define DEFAULTCOLOR 0x01

public Plugin:myinfo = 
{
	name = "WeaponRewards",
	author = "FlyingMongoose",
	description = "Weapon Rewards",
	version = "1.0.2",
	url = "http://www.gameconnect.info/"
};

new g_MoneyOffset;
new g_WeaponCount;

new bool:g_isHooked;

new Handle:cvarWeaponRewards;

new bool:g_weaponRewardsOn;


new String:weaponLine[100][30];

public GetPlayerCash(entity)
{
	return GetEntData(entity, g_MoneyOffset);
}

public SetPlayerCash(entity, amount)
{
	SetEntData(entity, g_MoneyOffset, amount, 4, true);
}

public OnPluginStart(){
	g_MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
	if (g_MoneyOffset == -1)
	{
		g_isHooked = false;
		g_weaponRewardsOn = false;
		PrintToServer("* FATAL ERROR: Failed to get offset for CCSPlayer::m_iAccount");
	}else{
		// Creates console variabls
		cvarWeaponRewards = CreateConVar("sm_weaponrewards","1","Enables cash rewards for using specific weapons",FCVAR_PLUGIN,true,0.0,true,1.0);
		g_weaponRewardsOn = GetConVarBool(cvarWeaponRewards);
		if(g_weaponRewardsOn){
			// If offsets are all found, start a timer to hook events
				CreateTimer(3.0, OnPluginStart_Delayed);
		}
	}
}

public OnServerLoad(){
	if(g_weaponRewardsOn){
		// opens config file for reading and stores settings to an array
		new Handle:weaponsFile = OpenFile("addons/sourcemod/configs/weapon_rewards.txt","rt");
		new i = 1;
		while(!IsEndOfFile(weaponsFile)){
			ReadFileLine(weaponsFile,weaponLine[i],30);
			if((weaponLine[i][0] == '/' && weaponLine[i][1] == '/') || (weaponLine[i][0] == ';' || weaponLine[i][0] == '\0')){
				continue;
			}
			++i;
		}
		g_WeaponCount = i;
		// closes file
		CloseHandle(weaponsFile);
	}
}

public Action:OnPluginStart_Delayed(Handle:timer){
	if(g_weaponRewardsOn){
		// hooks player death event
		HookEvent("player_death",ev_PlayerDeath);
		HookConVarChange(cvarWeaponRewards,weaponsRewardChange);
		
		g_isHooked = true;
		
		PrintToServer("[WeaponRewards] - Loaded");
	}
}

public weaponsRewardChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if(!g_weaponRewardsOn){
		if(g_isHooked == true){
			UnhookEvent("player_death",ev_PlayerDeath);
			
			g_weaponRewardsOn = false;
			
			g_isHooked = false;
		}
	}else if(g_isHooked == false){
		HookEvent("player_death",ev_PlayerDeath);
		
		g_weaponRewardsOn = true;
		
		g_isHooked = true;
	}
}

public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	if(g_weaponRewardsOn){
		// get player userid
		new userid = GetEventInt(event, "userid");
		new userid2 = GetEventInt(event, "attacker");
		// get players entity ids
		new victim = GetClientOfUserId(userid);
		new killer = GetClientOfUserId(userid2);
		if(killer != 0){
			// get players teams
			new victimTeam = GetClientTeam(victim);
			new killerTeam = GetClientTeam(killer);
			// check if teams are not the same
			if(victimTeam != killerTeam){
				new killerCash = GetPlayerCash(killer);
				
				decl String:weaponName[100];
				
				new weaponValue = 0;
				
				GetEventString(event,"weapon",weaponName,100);
				for(new i = 0; i <= g_WeaponCount; ++i){
				 	if(!strncmp(weaponLine[i],weaponName,strlen(weaponName), false)){
						new weaponSpace = StrContains(weaponLine[i]," ",false);
						weaponValue = StringToInt(weaponLine[i][weaponSpace + 1]);
					}
				}
				new rewardCash = (killerCash - 300) + weaponValue;
				
				if(rewardCash > 16000){
					SetPlayerCash(killer,16000);
				}else{
					SetPlayerCash(killer,rewardCash);
				}
			}
		}
	}
}