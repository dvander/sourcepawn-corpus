/**
 * 00. Includes
 * 01. Globals
 * 02. Forwards
 * 03. Events
 * 04. Functions
 */
 
// 00. Includes     
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

// 01. Globals
#define GOVIP_MAINLOOP_INTERVAL 0.1
#define GOVIP_MAXPLAYERS 64

enum VIPState {
	VIPState_WaitingForMinimumPlayers = 0,
	VIPState_Playing
};

new CurrentVIP = 0;
new LastVIP = 0;
new VIPState:CurrentState = VIPState_WaitingForMinimumPlayers;
new Handle:CVarMinCT = INVALID_HANDLE;
new Handle:CVarMinT = INVALID_HANDLE;
new Handle:CVarVIPWeapon = INVALID_HANDLE;
new MyWeaponsOffset = 0;
new Handle:RescueZones = INVALID_HANDLE;
new bool:RoundComplete = false;

// 02. Forwards
public OnPluginStart() {
	CVarMinCT = CreateConVar("govip_min_ct", "2", "Minimum number of CTs to play GOVIP");
	CVarMinT = CreateConVar("govip_min_t", "1", "Minimum number of Ts to play GOVIP");
	CVarVIPWeapon = CreateConVar("govip_weapon", "weapon_p250", "Weapon given to VIP");
	
	CurrentState = VIPState_WaitingForMinimumPlayers;
	
	CreateTimer(GOVIP_MAINLOOP_INTERVAL, GOVIP_MainLoop, INVALID_HANDLE, TIMER_REPEAT);

	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	MyWeaponsOffset = FindSendPropOffs("CBaseCombatCharacter", "m_hMyWeapons");
	
	RescueZones = CreateArray();
	
	RoundComplete = false;
}

public OnClientPutInServer(client) {
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
	return true;
}

public OnClientDisconnect(client) {
	if(CurrentState != VIPState_Playing || client != CurrentVIP || RoundComplete) {
		return;
	}
	
	RoundComplete = true;
	
	LastVIP = CurrentVIP;
	
	CurrentVIP = 0;
	
	PrintToChatAll("%s", "[GO:VIP] The VIP has left, round ends in a draw.");
	
	CS_TerminateRound(5.0, CSRoundEnd_Draw);
}

public OnMapStart() {
	new String:buffer[512];
	
	new trigger = -1;
	while((trigger = FindEntityByClassname(trigger, "trigger_multiple")) != -1) {
		GetEntPropString(trigger, Prop_Data, "m_iName", buffer, sizeof(buffer));
		if(StrContains(buffer, "vip_rescue_zone", false) == 0) {
			SDKHook(trigger, SDKHook_Touch, TouchRescueZone);
		}
	}
	
	ClearArray(RescueZones);
	
	GetCurrentMap(buffer, sizeof(buffer));
	
	new Handle:kv = CreateKeyValues("RescueZones");
	
	new String:path[1024];
	BuildPath(Path_SM, path, sizeof(path), "configs/rescue_zones.cfg");
	
	FileToKeyValues(kv, path);
	
	if(KvJumpToKey(kv, buffer)) {
		KvGotoFirstSubKey(kv);
		
		do {
			new Float:radius = KvGetFloat(kv, "radius", 200.0);
		
			KvGetString(kv, "coords", buffer, sizeof(buffer));
			new String:coords[3][128];
			ExplodeString(buffer, " ", coords, 3, 128);

			PrintToServer("[GO:VIP] Loading rescue zone at [%s, %s, %s] with radius of %f units.", coords[0], coords[1], coords[2], radius);
						
			new Handle:rescueZone = CreateArray();
			PushArrayCell(rescueZone, radius);
			PushArrayCell(rescueZone, StringToFloat(coords[0]));
			PushArrayCell(rescueZone, StringToFloat(coords[1]));
			PushArrayCell(rescueZone, StringToFloat(coords[2]));
			
			PushArrayCell(RescueZones, rescueZone);
		} while (KvGotoNextKey(kv));
	}	
	
	CloseHandle(kv);
}

// 03. Events
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	RoundComplete = false;
	
	CurrentVIP = GetRandomPlayerOnTeam(CS_TEAM_CT, LastVIP);
	
	if(CurrentState != VIPState_Playing) {
		return Plugin_Continue;
	}
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsPlayerAlive(i)) {
			new iWeapon = GetPlayerWeaponSlot(i, 4);
			if (iWeapon != -1 && IsValidEdict(iWeapon)) {
				decl String:szClassName[64];
				GetEdictClassname(iWeapon, szClassName, sizeof(szClassName));
				if (StrEqual(szClassName, "weapon_c4", false)) {
					RemovePlayerItem(i, iWeapon);
					RemoveEdict(iWeapon);
				}
			}
    	}
    }
		
	RemoveMapObj();
		
	if(CurrentVIP == 0 || !IsValidPlayer(CurrentVIP)) {
		return Plugin_Continue;
	}
	
	new String:VIPName[128];
	GetClientName(CurrentVIP, VIPName, sizeof(VIPName));
	
	PrintToChatAll("[GO:VIP] \"%s\" is the VIP, CTs protect the VIP from the Terrorists!", VIPName);
	
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	if(CurrentState != VIPState_Playing) {
		return Plugin_Continue;
	}
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if(client != CurrentVIP || RoundComplete) {
		return Plugin_Continue;
	}
	
	RoundComplete = true;
	
	CS_TerminateRound(5.0, CSRoundEnd_TerroristWin);
	
	PrintToChatAll("%s", "[GO:VIP] The VIP has died, Terrorists win!");
	
	LastVIP = CurrentVIP;
	
	CurrentVIP = 0;
	
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(CurrentState != VIPState_Playing) {
		return Plugin_Continue;
	}
	
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if(client != CurrentVIP) {
		return Plugin_Continue;
	}
	
	new String:VIPWeapon[256];
	GetConVarString(CVarVIPWeapon, VIPWeapon, sizeof(VIPWeapon));
	
	StripWeapons(client);
	
	new index = CreateEntityByName(VIPWeapon);
	
	new Float:PlayerLocation[3];
	GetClientAbsOrigin(client, PlayerLocation);
	
	if(index != -1) {
		TeleportEntity(index, PlayerLocation, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(index);
	}	
	
	return Plugin_Continue;
}

// 04. Functions
public Action:GOVIP_MainLoop(Handle:timer) {
	new CTCount = GetTeamClientCount(CS_TEAM_CT);
	new TCount = GetTeamClientCount(CS_TEAM_T);
	
	if(CurrentState == VIPState_WaitingForMinimumPlayers) {
		if(CTCount >= GetConVarInt(CVarMinCT) && TCount >= GetConVarInt(CVarMinT)) {
			CurrentState = VIPState_Playing;
			PrintToChatAll("%s", "[GO:VIP] Starting the game!");
			return Plugin_Continue;
		}
	}
	else if(CurrentState == VIPState_Playing) {
		if(TCount < GetConVarInt(CVarMinT) || CTCount < GetConVarInt(CVarMinCT)) {
			CurrentState = VIPState_WaitingForMinimumPlayers;
			PrintToChatAll("%s", "[GO:VIP] Game paused, waiting for more players.");
			return Plugin_Continue;
		}
		
		if(CurrentVIP == 0) {
			RoundComplete = true;
				
			CurrentVIP = GetRandomPlayerOnTeam(CS_TEAM_CT, LastVIP);
			
			CS_TerminateRound(5.0, CSRoundEnd_GameStart); 
		}
		else if(!RoundComplete && IsValidPlayer(CurrentVIP)) {
			new Float:vipOrigin[3];
			GetClientAbsOrigin(CurrentVIP, vipOrigin);
			
			new rescueZoneCount = GetArraySize(RescueZones);
			
			for(new rescueZoneIndex = 0; rescueZoneIndex < rescueZoneCount; rescueZoneIndex++) {
				new Handle:rescueZone = GetArrayCell(RescueZones, rescueZoneIndex);
				
				new Float:rescueZoneOrigin[3];
				rescueZoneOrigin[0] = GetArrayCell(rescueZone, 1);
				rescueZoneOrigin[1] = GetArrayCell(rescueZone, 2);
				rescueZoneOrigin[2] = GetArrayCell(rescueZone, 3);
				
				new Float:rescueZoneRadius = GetArrayCell(rescueZone, 0);
				
				if(GetVectorDistance(rescueZoneOrigin, vipOrigin) <= rescueZoneRadius) {
					RoundComplete = true;
					
					LastVIP = CurrentVIP;
					
					CurrentVIP = 0;
					
					CS_TerminateRound(5.0, CSRoundEnd_CTWin);
					
					PrintToChatAll("%s", "[GO:VIP] The VIP has been rescued, Counter-Terrorists win.");
					
					break;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnWeaponCanUse(client, weapon) {
	if(CurrentState != VIPState_Playing || client != CurrentVIP) {
		return Plugin_Continue;
	}
	
	new String:entityClassName[256];
	
	GetEntityClassname(weapon, entityClassName, sizeof(entityClassName));
	
	new String:VIPWeapon[256];
	GetConVarString(CVarVIPWeapon, VIPWeapon, sizeof(VIPWeapon));
	 
	if(StrEqual(entityClassName, "weapon_knife", false) || StrEqual(entityClassName, VIPWeapon, false)) {
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public Action:Command_JoinTeam(client, const String:command[], argc)  {
	if(CurrentState != VIPState_Playing || client != CurrentVIP) {
		return Plugin_Continue;
	}
	
	PrintToChat(client, "%s", "[GO:VIP] You are not allowed to change teams while you are the VIP.");
	return Plugin_Handled;
}

bool:IsValidPlayer(client) {
	if(!IsValidEntity(client) || !IsClientConnected(client) || !IsClientInGame(client)) {
		return false;
	}
	
	return true;
}

GetRandomPlayerOnTeam(team, ignore = 0) {
	new teamClientCount = GetTeamClientCount(team);
	
	if(teamClientCount <= 0) {
		return 0;
	}
	
	new client;
	
	do {
	    client = GetRandomInt(1, MaxClients);
	} while((teamClientCount > 1 && client == ignore) || !IsClientInGame(client) || GetClientTeam(client) != team);
	
	return client;
}

stock RemoveMapObj() {
	decl maxent,i;
	decl String:Class[65];
	maxent = GetMaxEntities();
	for (i=0;i<=maxent;i++)
	{
		if(IsValidEdict(i) && IsValidEntity(i))
		{
			GetEdictClassname(i, Class, sizeof(Class));
			if(StrContains("func_bomb_target_hostage_entity_func_hostage_rescue",Class) != -1)
			{
				RemoveEdict(i);
			}
		}
	}
}


StripWeapons(client) {
    new weaponID;
    
	for(new x = 0; x < 20; x = (x + 4)) {
        weaponID = GetEntDataEnt2(client, MyWeaponsOffset + x);
        
		if(weaponID <= 0) {
			continue;
		}
        
        new String:weaponClassName[128];
        GetEntityClassname(weaponID, weaponClassName, sizeof(weaponClassName));
        
        if(StrEqual(weaponClassName, "weapon_knife", false)) {
        	continue;
		}
        
		RemovePlayerItem(client, weaponID);
        RemoveEdict(weaponID);
    }
}

public TouchRescueZone(trigger, client) {
	if(!IsValidPlayer(client)) {
		return;
	} 
	
    if(CurrentState != VIPState_Playing || client != CurrentVIP || RoundComplete) {
    	return;
    }
    
    RoundComplete = true;
    
    CS_TerminateRound(5.0, CSRoundEnd_CTWin);
    
    LastVIP = CurrentVIP;
    
	CurrentVIP = 0;
	
	PrintToChatAll("[GO:VIP] The VIP has been rescued, Counter-Terrorists win.");
}