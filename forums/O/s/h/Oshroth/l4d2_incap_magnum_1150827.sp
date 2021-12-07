#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.3"

new incap_replace[MAXPLAYERS+1];
new Handle:incap_mode = INVALID_HANDLE;
new g_offsHang;

public Plugin:myinfo = {
	name = "Incapped Magnum",
	author = "Oshroth",
	description = "Gives incapped players a magnum or dual pistols.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart() {
	decl String:game[12];
	new Handle:incap_version = INVALID_HANDLE;
	
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Incapped Magnum will only work with Left 4 Dead 2!");
	
	HookEvent("player_incapacitated", Event_Incap);
	HookEvent("player_incapacitated_start", Event_MeleeCheck);
	HookEvent("revive_success", Event_Revive);
	
	g_offsHang = FindSendPropOffs("CTerrorPlayer", "m_isHangingFromLedge");
	
	incap_version = CreateConVar("sm_incapmagnum_version", PLUGIN_VERSION, "Incapped Magnum plugin version.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	incap_mode = CreateConVar("sm_incapmagnum_mode", "1", "Incap Mode - 0 disables plugin, 1 replaces melee with magnum, 2 replaces melee with dual pistols, 3 replaces pistols and melee with magnum, 4 replaces pistols and melee with dual pistols.", FCVAR_REPLICATED|FCVAR_NOTIFY, true, 0.0, true, 4.0);
	
	AutoExecConfig();
	
	SetConVarString(incap_version, PLUGIN_VERSION, true);
}

public Action:Event_MeleeCheck(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	new slot;
	decl String:weapon[64];
	new mode = GetConVarInt(incap_mode);
	
	if(mode == 0) {
		return Plugin_Continue;
	}
	
	slot = GetPlayerWeaponSlot(client, 1);
	if (slot > -1) {
		GetEdictClassname(slot, weapon, sizeof(weapon));
		//PrintToChatAll("%N is holding a %s", client, weapon);
		if(StrContains(weapon, "melee", false) != -1) {
			incap_replace[client] = 1;
		}
		if(StrContains(weapon, "chainsaw", false) != -1) {
			incap_replace[client] = 1;
		}
		if(StrContains(weapon, "pistol", false) != -1) {
			incap_replace[client] = 2;
		}
		if(StrContains(weapon, "pistol_magnum", false) != -1) {
			incap_replace[client] = 3;
		}
	} else {
		incap_replace[client] = 0;
	}
	
	return Plugin_Continue;
}

public Action:Event_Incap(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	new flags = GetCommandFlags("give");
	new weapon = GetPlayerWeaponSlot(client, 1);
	new mode = GetConVarInt(incap_mode);
	//new ClientHang = GetEntProp(client, Prop_Send, g_iIsHanging);
	decl String:edict[64];
	
	//PrintToChatAll("%d got incapped.", client);
	
	if(mode == 0) {
		return Plugin_Continue;
	}
	if(!IsClientConnected(client) || !IsClientInGame(client) || !(GetClientTeam(client) == 2)){
		return Plugin_Continue;
	}
	new entvalue=GetEntData(client,g_offsHang,1);
	
	if(entvalue == 1) {
		PrintToChatAll("%d is hanging...", client);
	} else {
		PrintToChatAll("%d is not hanging...", client);
	}
	if((incap_replace[client] != 1) && (mode == 1 || mode == 2)) {
		return Plugin_Continue;
	}
	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	if(weapon > -1) {
		GetEdictClassname(weapon, edict, sizeof(edict));
		if(incap_replace[client] == 1) {
			if(StrContains(edict, "pistol", false) != -1) {
				//Player doesn't appear to be hanging
				PrintToChatAll("Replacing %N's Incap Pistol...", client);
				RemovePlayerItem(client, weapon);
			} else {
				//Player still has melee when incapped, possibly ledge hang?
				//Display message and stop early
				PrintToChatAll("%N is keeping his melee during incap.", client);
				SetCommandFlags("give", flags|FCVAR_CHEAT);
				
				return Plugin_Continue;
			}
		} else {
			PrintToChatAll("Replacing %N's weapon while incapped", client);
			RemovePlayerItem(client, weapon);
		}
	}
	switch (mode) {
		case 1: {
			/* Replace Melee With Magnum Magnum */
			if(incap_replace[client] == 1) {
				FakeClientCommand(client, "give pistol_magnum");
			}
		}
		case 2: {
			/* Replace Melee With Dual Pistols */
			if(incap_replace[client] == 1) {
				FakeClientCommand(client, "give pistol");
				FakeClientCommand(client, "give pistol");
			}
		}
		case 3: {
			/* Replace Weapon With Magnum */
			FakeClientCommand(client, "give pistol_magnum");
		}
		case 4: {
			/* Replace Weapon With Dual Pistols */
			FakeClientCommand(client, "give pistol");
			FakeClientCommand(client, "give pistol");
		}
		default: {
			/* Give Single Pistol (default) */
			FakeClientCommand(client, "give pistol");
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	
	return Plugin_Continue;
}

public Action:Event_Revive(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "subject");
	new client = GetClientOfUserId(userId);
	new flags = GetCommandFlags("give");
	new weapon = GetPlayerWeaponSlot(client, 1);
	new mode = GetConVarInt(incap_mode);
	
	if(mode == 0 || mode == 1 || mode == 2 || incap_replace[client] == 1) {
		incap_replace[client] = 0;
		if(weapon == -1) {
			SetCommandFlags("give", flags & ~FCVAR_CHEAT);
			FakeClientCommand(client, "give pistol");
			FakeClientCommand(client, "give pistol");
			SetCommandFlags("give", flags|FCVAR_CHEAT);
		}
		return Plugin_Continue;
	}
	if(!IsClientConnected(client) || !IsClientInGame(client) || !(GetClientTeam(client) == 2)){
		return Plugin_Continue;
	}
	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	if(weapon > -1) {
		RemovePlayerItem(client, weapon);
	}
	if(incap_replace[client] == 2) {
		FakeClientCommand(client, "give pistol");
		FakeClientCommand(client, "give pistol");
	}
	if(incap_replace[client] == 3) {
		FakeClientCommand(client, "give pistol_magnum");
	}
	weapon = GetPlayerWeaponSlot(client, 1);
	if(weapon == -1) {
		SetCommandFlags("give", flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "give pistol");
		FakeClientCommand(client, "give pistol");
		SetCommandFlags("give", flags|FCVAR_CHEAT);
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
	incap_replace[client] = 0;
	
	return Plugin_Continue;
}
