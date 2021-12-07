#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://epicpwnage.co.cc/sm_plugins/makemeinvisible.txt"

#define PLUGIN_VERSION 				"1.3.4"
#define INVIS					{255,255,255,0}
#define NORMAL					{255,255,255,255}

new bool:IsInvis[MAXPLAYERS+1] = { false, ...};
new PlayerTimer[MAXPLAYERS+1] = { 0, ...};

new Handle:sm_makemeinvis_broadcast = INVALID_HANDLE;
new Handle:sm_makemeinvis_time = INVALID_HANDLE;
new Handle:sm_makemeinvis_offkillcam = INVALID_HANDLE;
new Handle:sm_makemeinvis_defr = INVALID_HANDLE;
new Handle:sm_makemeinvis_defg = INVALID_HANDLE;
new Handle:sm_makemeinvis_defb = INVALID_HANDLE;
new Handle:sm_makemeinvis_defa = INVALID_HANDLE;
new Handle:sm_makemeinvis_offondeath = INVALID_HANDLE;
new Handle:sm_makemeinvis_offonswitch = INVALID_HANDLE;
new Handle:sm_makemeinvis_timerstyle = INVALID_HANDLE;

new g_wearableOffset, g_shieldOffset;

public Plugin:myinfo = {
    name = "[TF2] MakeMeInvisible",
    author = "bobomaster",
    description = "For maximum trolling and lulz.",
    version = PLUGIN_VERSION,
    url = "epicpwnage.co.cc"
}

public OnPluginStart() {
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_makemeinvis_version", PLUGIN_VERSION, "MakeMeInvisible version number", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_makemeinvis_broadcast = CreateConVar("sm_makemeinvis_broadcast", "1", "Visibility of invisibility changes", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 3.0);
	sm_makemeinvis_time = CreateConVar("sm_makemeinvis_time", "30", "Default timer for invisibility timed mode", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	sm_makemeinvis_offkillcam = CreateConVar("sm_makemeinvis_offkillcam", "0", "Option to turn off for deathcam", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_makemeinvis_defr = CreateConVar("sm_makemeinvis_defr", "0", "Default RED value for custom mode", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 255.0);
	sm_makemeinvis_defg = CreateConVar("sm_makemeinvis_defg", "0", "Default GREEN value for custom mode", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 255.0);
	sm_makemeinvis_defb = CreateConVar("sm_makemeinvis_defb", "0", "Default BLUE value for custom mode", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 255.0);
	sm_makemeinvis_defa = CreateConVar("sm_makemeinvis_defa", "255", "Default ALPHA value for custom mode", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 255.0);
	sm_makemeinvis_offondeath = CreateConVar("sm_makemeinvis_offondeath", "1", "Turn off invisibility on death", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_makemeinvis_offonswitch = CreateConVar("sm_makemeinvis_offonswitch", "1", "Turn off invisibility on class switch", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0, true, 0.0);
	sm_makemeinvis_timerstyle = CreateConVar("sm_makemeinvis_timerstyle", "0", "Invisibility timer style", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 4.0);

	RegAdminCmd("sm_makemeinvis_toggle", MakeMeInvisible, ADMFLAG_CHEATS);
	RegAdminCmd("sm_makemeinvis_timed", MakeMeInvisibleTimed, ADMFLAG_CHEATS);
	RegAdminCmd("sm_makemeinvis", MakeMeInvisibleOn, ADMFLAG_CHEATS);
	RegAdminCmd("sm_makemenormal", MakeMeInvisibleOff, ADMFLAG_CHEATS);
	RegAdminCmd("sm_makemecolored", MakeMeInvisibleCustom, ADMFLAG_CHEATS);

	HookEvent("player_changeclass", ChangeClass);
	HookEvent("player_death", PlayerDeath);

	AutoExecConfig(true);
	
	g_wearableOffset = FindSendPropInfo("CTFWearableItem", "m_hOwnerEntity");
	g_shieldOffset = FindSendPropInfo("CTFWearableItemDemoShield", "m_hOwnerEntity");
	
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL)
	}
	
	PrintToServer("[InvisBot]: MakeMeInvisible v%s loaded!", PLUGIN_VERSION);
}

public OnClientDisconnect(client) {
	IsInvis[client] = false;
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL)
	}
}

public Action:MakeMeInvisible(client, args) {
	new String:arg1[32], String:ClientName[MAX_NAME_LENGTH], String:Target[MAX_NAME_LENGTH];
	new broadcast_type = GetConVarInt(sm_makemeinvis_broadcast);
	GetClientName(client, ClientName, sizeof(ClientName));
	
	if (args >= 1 && GetCmdArg(1, arg1, sizeof(arg1))) {
		new String:TargetName[MAX_TARGET_LENGTH];
		new TargetList[MAXPLAYERS], TargetCount;
		new bool:tn_is_ml
		
		if ((TargetCount = ProcessTargetString(
			arg1,
			client,
			TargetList,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			TargetName,
			sizeof(TargetName),
			tn_is_ml)) <= 0)
			{
			ReplyToTargetError(client, TargetCount);
			
			return Plugin_Handled;
		}
		
		for (new i = 0; i < TargetCount; i++) {
			if (IsInvis[TargetList[i]] == false) {
				Colorize(TargetList[i], INVIS);
				
				if (broadcast_type == 1) {
					PrintToChat(TargetList[1], "\x04[\x03InvisBot\x04]\x01: You are now invisible!");
				}
				
				IsInvis[TargetList[i]] = true;
			} else {
				Colorize(TargetList[i], NORMAL);
				
				if (broadcast_type == 1) {
					PrintToChat(TargetList[i], "\x04[\x03InvisBot\x04]\x01: You are now visible!");
				}
				
				IsInvis[TargetList[i]] = false;
			}
			GetClientName(TargetList[i], Target, sizeof(Target));
			LogAction(client, TargetList[i], "%s toggled invisibility on %s", ClientName, Target);
		}
		
		if (broadcast_type == 2) {
			PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has toggled invisibility on %s!", ClientName, TargetName);
		} else {
			if (client > 0) PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: The invisibility of %s has been toggled!", TargetName);
		}
		
		return Plugin_Handled;
	}
	
	if ((client <= 0) || !IsValidEntity(client)){
		ReplyToCommand(client, "If you are using this command from the console, you must supply a client as an argument!");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: You are not alive!");
		return Plugin_Handled;
	}
	
	if (!IsInvis[client]) {
		Colorize(client, INVIS);
		
		if (broadcast_type == 2) {
			PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has toggled invisibility on him or herself!", ClientName);
		} else {
			PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: You are now invisible!");
		}
		
		IsInvis[client] = true;
		
		LogAction(client, client, "%s made him or herself invisible", ClientName);
		
		return Plugin_Handled;
	}
	
	Colorize(client, NORMAL);
	
	if (broadcast_type == 2) {
		PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has toggled invisibility on him or herself!", ClientName);
	} else {
		PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: You are now visible!");
	}
	
	IsInvis[client] = false;
	LogAction(client, client, "%s made him or herself visible", ClientName);
	
	return Plugin_Handled;
}

public Action:MakeMeInvisibleOn(client, args) {
	new String:arg1[32], String:ClientName[MAX_NAME_LENGTH], String:Target[MAX_NAME_LENGTH];
	new broadcast_type = GetConVarInt(sm_makemeinvis_broadcast);
	GetClientName(client, ClientName, sizeof(ClientName));
	
	if (args >= 1 && GetCmdArg(1, arg1, sizeof(arg1))) {
		new String:TargetName[MAX_TARGET_LENGTH];
		new TargetList[MAXPLAYERS], TargetCount;
		new bool:tn_is_ml
		
		if ((TargetCount = ProcessTargetString(
			arg1,
			client,
			TargetList,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			TargetName,
			sizeof(TargetName),
			tn_is_ml)) <= 0)
			{
			ReplyToTargetError(client, TargetCount);
			
			return Plugin_Handled;
		}
		
		for (new i = 0; i < TargetCount; i++) {
			Colorize(TargetList[i], INVIS);
			
			if (broadcast_type == 1) {
				PrintToChat(TargetList[i], "\x04[\x03InvisBot\x04]\x01: You are now invisible!");
			}
			
			IsInvis[TargetList[i]] = true;
			GetClientName(TargetList[i], Target, sizeof(Target));
			LogAction(client, TargetList[i], "%s made %s invisible", ClientName, Target);
		}
		
		if (broadcast_type == 2) {
			PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has turned on invisibility on %s!", ClientName, TargetName);
		} else {
			if (client > 0) PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: Invisibility has been turned on for %s!", TargetName);
		}
		
		return Plugin_Handled;
	}
	
	if ((client <= 0) || !IsValidEntity(client)){
		ReplyToCommand(client, "If you are using this command from the console, you must supply a client as an argument!");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: You are not alive!");
		return Plugin_Handled;
	}
	
	Colorize(client, INVIS);
	
	if (broadcast_type == 2) {
		PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has turned on invisibility on him or herself!", ClientName);
	} else {
		PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: You are now invisible!");
	}
	
	IsInvis[client] = true;
	LogAction(client, client, "%s made him or herself invisible", ClientName);
	
	return Plugin_Handled;
}

public Action:MakeMeInvisibleOff(client, args) {
	new String:arg1[32], String:ClientName[MAX_NAME_LENGTH], String:Target[MAX_NAME_LENGTH];
	new broadcast_type = GetConVarInt(sm_makemeinvis_broadcast);
	GetClientName(client, ClientName, sizeof(ClientName));
	
	if (args >= 1 && GetCmdArg(1, arg1, sizeof(arg1))) {
		new String:TargetName[MAX_TARGET_LENGTH];
		new TargetList[MAXPLAYERS], TargetCount;
		new bool:tn_is_ml
		
		if ((TargetCount = ProcessTargetString(
			arg1,
			client,
			TargetList,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			TargetName,
			sizeof(TargetName),
			tn_is_ml)) <= 0)
			{
			ReplyToTargetError(client, TargetCount);
			
			return Plugin_Handled;
		}
		
		for (new i = 0; i < TargetCount; i++) {
			Colorize(TargetList[i], NORMAL);
				
			if (broadcast_type == 1) {
				PrintToChat(TargetList[i], "\x04[\x03InvisBot\x04]\x01: You are now visible!");
			}
			
			IsInvis[TargetList[i]] = false;
			GetClientName(TargetList[i], Target, sizeof(Target));
			LogAction(client, TargetList[i], "%s made %s visible", ClientName, Target);
		}
		
		if (broadcast_type == 2) {
			PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has turned off invisibility on %s!", ClientName, TargetName);
		} else {
			if (client > 0) PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: Invisibility has been turned off for %s!", TargetName);
		}
		
		return Plugin_Handled;
	}
	
	if ((client <= 0) || !IsValidEntity(client)){
		ReplyToCommand(client, "If you are using this command from the console, you must supply a client as an argument!");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client)) {
		PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: You are not alive!");
		return Plugin_Handled;
	}
	
	Colorize(client, NORMAL);
	
	if (broadcast_type == 2) {
		PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has turned off invisibility on him or herself!", ClientName);
	} else {
		PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: You are now visible!");
	}
	
	IsInvis[client] = false;
	LogAction(client, client, "%s made him or herself visible", ClientName);
	
	return Plugin_Handled;
}

public Action:MakeMeInvisibleTimed(client, args) {
	if (args < 1 || args > 2) {
		ReplyToCommand(client, "[InvisBot]: This command requires 1 or 2 arguments.")
		return Plugin_Handled;
	}

	new String:arg1[32], String:arg2[32], String:ClientName[MAX_NAME_LENGTH], String:Target[MAX_NAME_LENGTH];
	new broadcast_type = GetConVarInt(sm_makemeinvis_broadcast);
	GetClientName(client, ClientName, sizeof(ClientName));
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (args == 2) GetCmdArg(2, arg2, sizeof(arg2));
	else GetConVarString(sm_makemeinvis_time, arg2, sizeof(arg2));
	
	new timeadded = StringToInt(arg2);
	
	new String:TargetName[MAX_TARGET_LENGTH];
	new TargetList[MAXPLAYERS], TargetCount;
	new bool:tn_is_ml
		
	if ((TargetCount = ProcessTargetString(
		arg1,
		client,
		TargetList,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		TargetName,
		sizeof(TargetName),
		tn_is_ml)) <= 0) {
		ReplyToTargetError(client, TargetCount);
		
		return Plugin_Handled;
	}
		
	for (new i = 0; i < TargetCount; i++) {
		Colorize(TargetList[i], INVIS);
		IsInvis[client] = true;
		PlayerTimer[TargetList[i]] = PlayerTimer[TargetList[i]] + timeadded;
		CreateTimer(1.0, InvisTimer, TargetList[i], TIMER_REPEAT);
		
		if (broadcast_type == 1) {
			PrintToChat(TargetList[i], "\x04[\x03InvisBot\x04]\x01: You will be invisible for %i seconds!", timeadded);
		}
		
		GetClientName(TargetList[i], Target, sizeof(Target));
		LogAction(client, TargetList[i], "%s made %s invisible for %i seconds", ClientName, Target, timeadded);
	}
	
	if (broadcast_type == 2) {
		PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has turned on invisibility on %s for %i seconds!", ClientName, TargetName, timeadded);
	} else {
		if (client > 0) PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: %s's invisibility has been turned on for %i seconds!", TargetName, timeadded);
	}
	
	return Plugin_Handled;
}

public Action:InvisTimer(Handle:timer, any:client) {
	new timerstyle = GetConVarInt(sm_makemeinvis_timerstyle);
	if (IsValidEntity(client) && PlayerTimer[client] > 0 && IsPlayerAlive(client) && IsInvis[client] == true) {
		if (timerstyle == 0 || timerstyle == 2) PrintHintText(client, "%i seconds of invisibility left", PlayerTimer[client]);
		if (timerstyle == 1 || timerstyle == 2) PrintCenterText(client, "%i seconds of invisibility left", PlayerTimer[client]);
		PlayerTimer[client]--;
		return Plugin_Continue;
	} else {
		PlayerTimer[client] = 0;
		if (IsInvis[client] == true) {
			Colorize(client, NORMAL);
			IsInvis[client] = false;
			if (timerstyle == 0 || timerstyle == 2) PrintHintText(client, "Invisibility period ended. You are now visible.");
			if (timerstyle == 1 || timerstyle == 2) PrintCenterText(client, "Invisibility period ended. You are now visible.");
		}
		
		return Plugin_Stop;
	}
}

public ChangeClass(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new offonswitch = GetConVarInt(sm_makemeinvis_offonswitch);
	if (offonswitch == 1) {
		IsInvis[client] = false;
	} else if (IsInvis[client] == true) {
		CreateTimer(0.5, Invisify, client);
	}
}

public Action:Invisify(Handle:event, any:client) {
	if (IsValidEntity(client) && IsPlayerAlive(client)) {
		Colorize(client, INVIS);
	}
}

public Action:Normify(Handle:timer, any:client) {
	if (IsValidEntity(client) && IsPlayerAlive(client)) {
		Colorize(client, NORMAL)
		CreateTimer(3.5, Invisify, client);
	}
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new offondeath = GetConVarInt(sm_makemeinvis_offondeath);
	new offonkillcam = GetConVarInt(sm_makemeinvis_offkillcam);
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (offondeath == 1) {
		new deathflags = GetEventInt(event, "death_flags");
		if (!(deathflags & 32)) {
			// Death was not feigned
			Colorize(client, NORMAL);
			IsInvis[client] = false;
		}
	}

	if (offonkillcam == 1) {
		new clientid = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (client != clientid) {
			if (IsInvis[clientid]) {
				CreateTimer(0.5, Normify, clientid);
			}
		}
	}
}

public Action:MakeMeInvisibleCustom(client, args) {
	if (args != 5 && args != 4 && args != 1) {
		ReplyToCommand(client, "[InvisBot]: You do not have the correct number of arguments! You need 5 or 1!");
		return Plugin_Handled;
	}
	new String:arg1[32], String:arg2[4], String:arg3[4], String:arg4[4], String:arg5[4], String:ClientName[MAX_NAME_LENGTH];
	new String:TargetName[MAX_TARGET_LENGTH], TargetList[MAXPLAYERS], TargetCount
	new bool:tn_is_ml
	new broadcast_type = GetConVarInt(sm_makemeinvis_broadcast);
	
	GetClientName(client, ClientName, sizeof(ClientName));

	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (args == 5) {
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		GetCmdArg(4, arg4, sizeof(arg4));
		GetCmdArg(5, arg5, sizeof(arg5));
	}
	
	if (args == 4) {
		GetCmdArg(2, arg2, sizeof(arg2));
		GetCmdArg(3, arg3, sizeof(arg3));
		GetCmdArg(4, arg4, sizeof(arg4));
	}
	
	if ((TargetCount = ProcessTargetString(
			arg1,
			client,
			TargetList,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			TargetName,
			sizeof(TargetName),
			tn_is_ml)) <= 0) {
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	
	new color[4];
	
	if (args == 4 || args == 5) {
		color[0] = StringToInt(arg2);
		color[1] = StringToInt(arg3);
		color[2] = StringToInt(arg4);
		if (args == 5) color[3] = StringToInt(arg5);
		else color[3] = GetConVarInt(sm_makemeinvis_defa);
	} else {
		color[0] = GetConVarInt(sm_makemeinvis_defr);
		color[1] = GetConVarInt(sm_makemeinvis_defg);
		color[2] = GetConVarInt(sm_makemeinvis_defb);
		color[3] = GetConVarInt(sm_makemeinvis_defa);
	}
	
	for (new i = 0; i < TargetCount; i++) {
		Colorize(TargetList[i], color);
		
		if (broadcast_type == 1) {
			PrintToChat(TargetList[i], "\x04[\x03InvisBot\x04]\x01: Your color has been changed (R:%i G:%i B:%i A:%i)!", color[0], color[1], color[2], color[3]);
		}
		
		IsInvis[TargetList[i]] = false;
		LogAction(client, TargetList[i], "%s changed the color of %s (R:%i G:%i B:%i A:%i)", ClientName, TargetList[i], color[0], color[1], color[2], color[3]);
	}
	
	if (broadcast_type == 2) {
		PrintToChatAll("\x04[\x03InvisBot\x04]\x01: %s has changed the color of %s (R:%i G:%i B:%i A:%i)!", ClientName, TargetName, color[0], color[1], color[2], color[3]);
	} else {
		if (client > 0) PrintToChat(client, "\x04[\x03InvisBot\x04]\x01: %s's color has been changed (R:%i G:%i B:%i A:%i)!", TargetName, color[0], color[1], color[2], color[3]);
	}
	return Plugin_Handled;
}

/* Credit to pheadxdll for invisibility code, taken from rtd plugin */
public Colorize(client, color[4]) {
	new maxents = GetMaxEntities();
	// Colorize player and weapons
	new m_hMyWeapons = FindSendPropOffs("CBasePlayer", "m_hMyWeapons");	

	for(new i = 0, weapon; i < 47; i += 4) {
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
	
		if (weapon > -1 ) {
			decl String:strClassname[250];
			GetEdictClassname(weapon, strClassname, sizeof(strClassname));
			if(StrContains(strClassname, "tf_weapon") == -1) continue;
			
			SetEntityRenderMode(weapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(weapon, color[0], color[1], color[2], color[3]);
		}
	}
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);	
	SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);
	
	// Colorize any wearable items
	for(new i=MaxClients+1; i <= maxents; i++)
	{
		if(!IsValidEntity(i)) continue;
		
		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		
		if(strcmp(netclass, "CTFWearableItem") == 0 || strcmp(netclass, "CTFWearableItem")) {
			if(GetEntDataEnt2(i, g_wearableOffset) == client) {
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		} else if(strcmp(netclass, "CTFWearableItemDemoShield") == 0) {
			if(GetEntDataEnt2(i, g_shieldOffset) == client) {
				SetEntityRenderMode(i, RENDER_TRANSCOLOR);
				SetEntityRenderColor(i, color[0], color[1], color[2], color[3]);
			}
		}
	}
	
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hDisguiseWeapon");
		if(iWeapon && IsValidEntity(iWeapon))
		{
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
			SetEntityRenderColor(iWeapon, color[0], color[1], color[2], color[3]);
		}
	}
	
	return;
}