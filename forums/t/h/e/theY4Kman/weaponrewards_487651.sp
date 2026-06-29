#pragma semicolon 1

#include <sourcemod>
#include <entity>
#include <clients>

// Colors
#define GREEN 0x04
#define DEFAULTCOLOR 0x01

public Plugin:myinfo = 
{
	name = "WeaponRewards ADVANCED",
	author = "FlyingMongoose/theY4Kman",
	description = "Weapon Rewards",
	version = "2.0.0",
	url = "http://www.gameconnect.info/"
};

new g_MoneyOffset;
new Handle:weaponsKeys;
new bool:g_isHooked;
new Handle:cvarWeaponRewards;
new bool:g_weaponRewardsOn = true;

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
		g_weaponRewardsOn = true;
		PrintToServer("* FATAL ERROR: Failed to get offset for CCSPlayer::m_iAccount");
	}else{
		// Creates console variables
		cvarWeaponRewards = CreateConVar("sm_weaponrewards","1","Enables cash rewards for using specific weapons",FCVAR_PLUGIN,true,0.0,true,1.0);
		// If offsets are all found, start a timer to hook events
		CreateTimer(3.0, OnPluginStart_Delayed);
		if(g_weaponRewardsOn){
      weaponsKeys = CreateKeyValues("WeaponRewards");
      decl String:WepRewFile[PLATFORM_MAX_PATH];
      BuildPath(Path_SM,WepRewFile,sizeof(WepRewFile),"configs/weapon_rewards.cfg");
      FileToKeyValues(weaponsKeys,WepRewFile);
      if(weaponsKeys){
        KvGotoFirstSubKey(weaponsKeys);
        decl String:section[16];
        KvGetSectionName(weaponsKeys, section, sizeof(section));
      }
		}
	}
}

public OnPluginEnd(){
  CloseHandle(weaponsKeys);
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
/*
public PrintToAllConsoles(String:format[]){
  for(new a=1;a<=GetMaxClients();a++){
    if(IsClientConnected(a)) PrintToConsole(a,format);
  }
}*/

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
				
				// Create a string to hold the weapon name
				decl String:weaponName[100];
				decl Float:ao[3];
				decl Float:vo[3];
				decl Float:dist;
				new Float:distmod = 1.0;
        
        GetClientAbsOrigin(killer, ao);
        GetClientAbsOrigin(victim, vo);
        dist = SquareRoot(FloatMul((ao[0]-vo[0]),(ao[0]-vo[0])) + FloatMul((ao[1]-vo[1]),(ao[1]-vo[1])) + FloatMul((ao[2] - vo[2]),(ao[2] - vo[2])));
				
				new weaponValue = 0;
				
				// Get the name of the weapon used to kill the victim and put it in weaponName
				GetEventString(event,"weapon",weaponName,100);
				
				// Get the weapon's value
				KvRewind(weaponsKeys);
				if(!KvJumpToKey(weaponsKeys, weaponName)){
          weaponValue = 300;
        }else{
          weaponValue = KvGetNum(weaponsKeys, "cash", 300);
          if(!KvGetNum(weaponsKeys,"disableranges",0)){
            if(dist < 175){
              distmod = KvGetFloat(weaponsKeys,"kniferange",1.0);
            }else if(dist < 800){
              distmod = KvGetFloat(weaponsKeys,"shortrange",1.0);
            }else if(dist < 1600){
              distmod = KvGetFloat(weaponsKeys,"mediumrange",1.0);
            }else{
              distmod = KvGetFloat(weaponsKeys,"longrange",1.0);
            }
          }
          weaponValue = FloatMul(distmod,weaponValue);
        }
        
				new rewardCash = (killerCash - 300) + weaponValue;
				
				if(rewardCash > 16000) SetPlayerCash(killer,16000);
				else SetPlayerCash(killer,rewardCash);
			}
		}
	}
}
