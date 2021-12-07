/*
*	Original plugin by DarthNinja - March 11, 2009
*   https://forums.alliedmods.net/showthread.php?t=108251
*
*	Updated syntax and minor fixes by ratawar - August 27, 2020
*	https://forums.alliedmods.net/member.php?u=282996
*/


/* Dependencies */

#include <sourcemod>
#include <autoexecconfig>
#include <multicolors>

#define PLUGIN_VERSION "3.0"

#pragma semicolon 1
#pragma newdecls required

/* Plugin Info */

public Plugin myinfo =  {
	
	name = "[Any] Deluxe Godmode", 
	author = "DarthNinja", 
	description = "Adds advanced godmode controls for clients/admins", 
	version = PLUGIN_VERSION, 
	url = "DarthNinja.com"
	
};

/* Globals */

ConVar v_Announce, v_Remember, v_Spawn, v_SpawnAdminOnly;
int g_iState[MAXPLAYERS + 1];

/* Plugin Start */

public void OnPluginStart() {
	
	AutoExecConfig_SetCreateFile(true);
	AutoExecConfig_SetFile("Godmode");
	
	RegAdminCmd("sm_god", Command_God, 0, "sm_god [#userid|name] [0/1] - Toggles godmode on player(s)");
	RegAdminCmd("sm_buddha", Command_Buddha, 0, "sm_buddha [#userid|name] [0/1] - Toggles buddha mode on player(s)");
	RegAdminCmd("sm_mortal", Command_Mortal, 0, "sm_mortal [#userid|name] - Makes specified players mortal");
	
	CreateConVar("sm_godmode_version", PLUGIN_VERSION, "Plugin Version");
	
	v_Spawn = AutoExecConfig_CreateConVar("sm_godmode_spawn", "0", "1 = Players spawn with godmode, 2 = Players spawn with buddha, 0 = Players spawn mortal", 0, true, 0.0, true, 2.0);
	v_Remember = AutoExecConfig_CreateConVar("sm_godmode_remember", "0", "1 = When players respawn the plugin will return their godmode to whatever it was set to prior to death. 0 = Players will respawn with godmode off.", 0, true, 0.0, true, 1.0);
	v_Announce = AutoExecConfig_CreateConVar("sm_godmode_announce", "1", "Tell players if an admin gives/removes their godmode", 0, true, 0.0, true, 1.0);
	v_SpawnAdminOnly = AutoExecConfig_CreateConVar("sm_godmode_spawn_admins", "0", "1 = Only admins spawn with godmode, 0 = All players spawn with godmode.\n Requires sm_godmode_spawn to be set to a non-zero value", 0, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", OnPlayerSpawned);
	LoadTranslations("common.phrases");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
}

/* Commands */

public Action Command_God(int client, int args) {
	
	if (args != 0 && !CheckCommandAccess(client, "sm_godmode_admin", ADMFLAG_SLAY, true)) {
		
		CReplyToCommand(client, "[SM] Usage: sm_god");
		return Plugin_Handled;
		
	}
	
	if (args > 2) {
		
		CReplyToCommand(client, "[SM] Usage: sm_god [#userid|name] [0/1]");
		return Plugin_Handled;
		
	}
	
	if (!args) {
		
		if (!IsClientConnected(client) || !IsPlayerAlive(client))
			return Plugin_Handled;
		
		//Mortal or Buddha
		if (g_iState[client] != 1) {
			
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			CReplyToCommand(client, "[SM] God Mode {green}ON");
			g_iState[client] = 1;
			
		}
		
		// GodMode on
		else {
			
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			CReplyToCommand(client, "[SM] God Mode {red}OFF");
			g_iState[client] = 0;
			
		}
		
		return Plugin_Handled;
	}
	
	// Player is an admin and is using 1 or more args
	char target[32];
	char toggle[3];
	GetCmdArg(1, target, sizeof(target));
	
	int iToggle = -1;
	
	if (args > 1) {
		
		GetCmdArg(2, toggle, sizeof(toggle));
		iToggle = StringToInt(toggle);
		
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
		
	}
	
	bool bAnnounce = v_Announce.BoolValue;
	
	//Turn on godmode
	if (iToggle == 1) {
		
		CShowActivity2(client, "[SM] ", "{green}Enabled {default}God Mode on {green}%s", target_name);
		for (int i = 0; i < target_count; i++) {
			
			if (bAnnounce)
				CPrintToChat(target_list[i], "[SM] An admin has {green}given {default}you God Mode!");
			
			LogAction(client, target_list[i], "%L enabled godmode on %L", client, target_list[i]);
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
			g_iState[target_list[i]] = 1;
			
		}
		
	}
	
	//Turn off godmode
	else if (iToggle == 0) {
		
		CShowActivity2(client, "[SM] ", "{red}Disabled {default}God Mode on {green}%s", target_name);
		for (int i = 0; i < target_count; i++) {
			
			if (bAnnounce)
				CPrintToChat(target_list[i], "[SM] An admin has {red}removed {default}your God Mode!");
			
			LogAction(client, target_list[i], "%L disabled godmode on %L", client, target_list[i]);
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			g_iState[target_list[i]] = 0;
			
		}
		
	}
	
	else {
		
		for (int i = 0; i < target_count; i++) {
			
			//Mortal or Buddha -> Turn on godmode
			if (g_iState[target_list[i]] != 1) {
				
				CShowActivity2(client, "[SM] ", "{green}Toggled {default}God Mode on {green}%s", target_name);
				
				if (bAnnounce)
					CPrintToChat(target_list[i], "[SM] An admin has {green}given {default}you God Mode!");
				
				LogAction(client, target_list[i], "%L enabled godmode on %L", client, target_list[i]);
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 0, 1);
				g_iState[target_list[i]] = 1;
				
			}
			
			//Turn off godmode
			else {
				
				CShowActivity2(client, "[SM] ", "{red}Removed {default}God Mode from {green}%s", target_name);
				
				if (bAnnounce)
					CPrintToChat(target_list[i], "[SM] An admin has {red}removed {default}your God Mode!");
				
				LogAction(client, target_list[i], "%L disabled godmode on %L", client, target_list[i]);
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
				g_iState[target_list[i]] = 0;
				
			}
			
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action Command_Buddha(int client, int args) {
	
	if (args != 0 && !CheckCommandAccess(client, "sm_buddhamode_admin", ADMFLAG_SLAY, true)) {
		
		CReplyToCommand(client, "[SM] Usage: sm_buddha");
		return Plugin_Handled;
		
	}
	
	if (args > 2) {
		
		CReplyToCommand(client, "[SM] Usage: sm_buddha [#userid|name] [0/1]");
		return Plugin_Handled;
		
	}
	
	if (!args) {
		
		if (!IsClientConnected(client) || !IsPlayerAlive(client))
			return Plugin_Handled;
		
		//Mortal or God
		if (g_iState[client] != 2) {
			
			SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
			CReplyToCommand(client, "[SM] Buddha Mode {green}ON");
			g_iState[client] = 2;
			
		}
		
		// GodMode on
		else {
			
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
			CReplyToCommand(client, "[SM] Buddha Mode {red}OFF");
			g_iState[client] = 0;
			
		}
		
		return Plugin_Handled;
	}
	
	// Player is an admin and is using 1 or more args
	char target[32];
	char toggle[3];
	GetCmdArg(1, target, sizeof(target));
	int iToggle = -1;
	if (args > 1) {
		
		GetCmdArg(2, toggle, sizeof(toggle));
		iToggle = StringToInt(toggle);
		
	}
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
		
	}
	
	bool bAnnounce = v_Announce.BoolValue;
	
	//Turn on Buddha
	if (iToggle == 1) {
		
		CShowActivity2(client, "[SM] ", "{green}Enabled {default}Buddha Mode on {green}%s", target_name);
		
		for (int i = 0; i < target_count; i++) {
			
			if (bAnnounce)
				CPrintToChat(target_list[i], "[SM] An admin has {green}given {default}you Buddha Mode!");
			
			LogAction(client, target_list[i], "%L enabled buddha mode on %L", client, target_list[i]);
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 1, 1);
			g_iState[target_list[i]] = 2;
			
		}
		
	}
	
	//Turn off Buddha
	else if (iToggle == 0) {
		
		CShowActivity2(client, "[SM] ", "{red}Disabled {default}Buddha Mode on {green}%s", target_name);
		
		for (int i = 0; i < target_count; i++) {
			
			if (bAnnounce)
				CPrintToChat(target_list[i], "[SM] An admin has {red}removed {default}your Buddha Mode!");
			
			LogAction(client, target_list[i], "%L disabled buddha mode on %L", client, target_list[i]);
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			g_iState[target_list[i]] = 0;
			
		}
		
	}
	
	else {
		
		for (int i = 0; i < target_count; i++) {
			
			//Mortal or God -> Turn on Buddha
			if (g_iState[target_list[i]] != 2) {
				
				CShowActivity2(client, "[SM] ", "{green}Toggled {default}Buddha Mode on {green}%s", target_name);
				
				if (bAnnounce)
					CPrintToChat(target_list[i], "[SM] An admin has {green}given {default}you Buddha Mode!");
				
				LogAction(client, target_list[i], "%L enabled buddha mode on %L", client, target_list[i]);
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 1, 1);
				g_iState[target_list[i]] = 2;
				
			}
			
			//Turn off godmode
			else {
				
				CShowActivity2(client, "[SM] ", "{red}Removed {default}Buddha Mode from {green}%s", target_name);
				
				if (bAnnounce)
					CPrintToChat(target_list[i], "[SM] An admin has {red}removed {default}your Buddha Mode!");
				
				LogAction(client, target_list[i], "%L disabled buddha mode on %L", client, target_list[i]);
				SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
				g_iState[target_list[i]] = 0;
				
			}
			
		}
		
	}
	
	return Plugin_Handled;
	
}

public Action Command_Mortal(int client, int args) {
	
	if (args != 0 && !CheckCommandAccess(client, "sm_mortalmode_admin", ADMFLAG_SLAY, true)) {
		
		CReplyToCommand(client, "[SM] Usage: sm_mortal");
		return Plugin_Handled;
		
	}
	
	if (args < 0 || args > 1) {
		
		CReplyToCommand(client, "[SM] Usage: sm_mortal [#userid|name]");
		return Plugin_Handled;
		
	}
	
	if (!args) {
		
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		CReplyToCommand(client, "[SM] You are now {red}mortal{default}!");
		g_iState[client] = 0;
		return Plugin_Handled;
		
	}
	
	char target[32];
	GetCmdArg(1, target, sizeof(target));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0) {
		
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
		
	}
	
	bool chat = v_Announce.BoolValue;
	
	CShowActivity2(client, "[SM] ", "{default}Made {green}%s {red}mortal{default}!", target_name);
	
	for (int i = 0; i < target_count; i++) {
		
		//Not mortal
		if (g_iState[target_list[i]] != 0) {
			
			if (chat)
				CPrintToChat(target_list[i], "[SM] An admin has made you {red}mortal{default}!");
			
			SetEntProp(target_list[i], Prop_Data, "m_takedamage", 2, 1);
			LogAction(client, target_list[i], "%L made %L mortal", client, target_list[i]);
			g_iState[target_list[i]] = 0;
			
		}
		
	}
	
	return Plugin_Handled;
	
}

public void OnClientDisconnect(int client) {
	g_iState[client] = 0;
}

public void OnPlayerSpawned(Handle event, const char[] name, bool dontBroadcast) {
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Had godmode on before -> reapply
	if (g_iState[client] != 0 && v_Remember.BoolValue) {
		
		DataPack Packhead = new DataPack();
		CreateDataTimer(0.1, ApplyGodMode, Packhead);
		Packhead.WriteCell(client);
		Packhead.WriteCell(1);
		
	} else {
		
		g_iState[client] = 0;
		
		//admin only mode + not an admin
		if (v_SpawnAdminOnly.BoolValue && !CheckCommandAccess(client, "godmode_adminonly_override", ADMFLAG_SLAY, true))
			return;
		
		if (v_Spawn.IntValue != 0) {
			
			DataPack Packhead = new DataPack();
			CreateDataTimer(0.1, ApplyGodMode, Packhead);
			Packhead.WriteCell(client);
			Packhead.WriteCell(0);
			
		}
	}
}

public Action ApplyGodMode(Handle timer, DataPack Packhead) {
	
	Packhead.Reset();
	int client = Packhead.ReadCell();
	int saved = Packhead.ReadCell();
	delete Packhead;
	
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client)) {
		
		//Check to see if players are supposed to spawn with damage disabled:
		switch (v_Spawn.IntValue) {
			
			case 1: {
				
				CPrintToChat(client, "[SM] You have automatically spawned with {green}God Mode{default}!  You may type {orange}!mortal{default} to turn it off.");
				SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
				g_iState[client] = 1;
				return Plugin_Handled;
				
			}
			
			case 2: {
				
				CPrintToChat(client, "[SM] You have automatically spawned with {green}Buddha Mode{default}!  You may type {orange}!mortal{default} to turn it off.");
				SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
				g_iState[client] = 2;
				return Plugin_Handled;
				
			}
			
		}
		
		// Plugin is set to remember godmode states
		if (saved) {
			
			switch (g_iState[client]) {
				
				case 1: {
					
					SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); //Godmode
					CPrintToChat(client, "[SM] You have automatically respawned with {green}God Mode{default}!  You may type {orange}!mortal{default} to turn it off.");
					
				}
				
				case 2: {
					
					SetEntProp(client, Prop_Data, "m_takedamage", 1, 1); //Buddha
					CPrintToChat(client, "[SM] You have automatically respawned with {green}Buddha Mode{default}!  You may type {orange}!mortal{default} to turn it off.");
					
				}
				
			}
		}
	}
	
	return Plugin_Handled;
}

