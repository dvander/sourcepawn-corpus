#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <morecolors>

#define PLUGIN_VERSION "1.0.0"

new Handle:cvarEnabled = INVALID_HANDLE;
new Handle:cvarGlobal = INVALID_HANDLE;
new Handle:cvarValue = INVALID_HANDLE;

new bool:Enabled;
new bool:lateLoaded;

new maxSection;
new String:sectionName[PLATFORM_MAX_PATH][PLATFORM_MAX_PATH];
new Float:sectionValue[PLATFORM_MAX_PATH];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	lateLoaded = late;
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) {
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo = {
	name = "[TF2] Taunt Speed Modifier",
	author = "Tak (Chaosxk)",
	description = "Changes the taunt speed of a player.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

public OnPluginStart() {
	CreateConVar("tauntspeed_version", PLUGIN_VERSION, "Taunt Speed Modifier Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarEnabled = CreateConVar("tauntspeed_enabled", "1", "Enable or Disable this plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarGlobal = CreateConVar("tauntspeed_automatic", "0", "Should taunt speed be automatically enabled for all players?\n0 - None\n1 - Public\n2 - Admin", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvarValue = CreateConVar("tauntspeed_value", "1.5", "How fast should players be? Used with tauntspeed_automatic.");
	
	RegAdminCmd("sm_tauntspeedme", TauntMe, ADMFLAG_CUSTOM3, "Opens a menu for players to change their taunt speed.");
	RegAdminCmd("sm_tauntspeed", Taunt, ADMFLAG_GENERIC, "Sets taunt speed on other players.");
	RegAdminCmd("sm_tauntspeed_reload", TauntReload, ADMFLAG_GENERIC, "Reloads the menu config.");
	
	HookConVarChange(cvarEnabled, cvarChange);
	HookConVarChange(cvarGlobal, cvarChange);
	HookConVarChange(cvarValue, cvarChange);
	
	AutoExecConfig(true, "tauntspeed");
	LoadTranslations("common.phrases");
	SetUpTauntSpeedMenu("taunt_speed.cfg");
}

public OnPluginEnd() {
	for(new i = 1; i <= MaxClients; i++) {
		if(IsValidClient(i)) {
			RemoveAttribute(i, "gesture speed increase");
		}
	}
}

public OnConfigsExecuted() {
	Enabled = GetConVarBool(cvarEnabled);
	if(!Enabled) return;
	if(lateLoaded) {
		switch(GetConVarInt(cvarGlobal)) {
			case 0: return;
			case 1: {
				for(new i = 1; i <= MaxClients; i++) {
					if(IsValidClient(i)) {
						AddAttribute(i, "gesture speed increase", GetConVarFloat(cvarValue));
					}
				}
			}
			case 2: {
				for(new i = 1; i <= MaxClients; i++) {
					if(IsValidClient(i)) {
						if(CheckCommandAccess(i, "tauntspeed_override", ADMFLAG_CUSTOM2)) {
							AddAttribute(i, "gesture speed increase", GetConVarFloat(cvarValue));
						}
					}
				}
			}
		}
		lateLoaded = false;
	}
}

public cvarChange(Handle:convar, String:oldValue[], String:newValue[]) {
	if(convar == cvarEnabled) {
		Enabled = GetConVarBool(cvarEnabled);
		if(!Enabled) {
			for(new i = 1; i <= MaxClients; i++) {
				RemoveAttribute(i, "gesture speed increase");
			}
		}
	}
	else if(convar == cvarGlobal) {
		switch(GetConVarInt(cvarGlobal)) {
			case 0: {
				for(new i = 1; i <= MaxClients; i++) {
					if(IsValidClient(i)) {
						RemoveAttribute(i, "gesture speed increase");
					}
				}
			}
			case 1: {
				for(new i = 1; i <= MaxClients; i++) {
					if(IsValidClient(i)) {
						AddAttribute(i, "gesture speed increase", GetConVarFloat(cvarValue));
					}
				}
			}
			case 2: {
				for(new i = 1; i <= MaxClients; i++) {
					if(IsValidClient(i)) {
						RemoveAttribute(i, "gesture speed increase");
						if(CheckCommandAccess(i, "tauntspeed_override", ADMFLAG_CUSTOM2)) {
							AddAttribute(i, "gesture speed increase", GetConVarFloat(cvarValue));
						}
					}
				}
			}
		}
	}
	else if(convar == cvarValue) {
		switch(GetConVarInt(cvarGlobal)) {
			case 1: {
				for(new i = 1; i <= MaxClients; i++) {
					if(IsValidClient(i)) {
						AddAttribute(i, "gesture speed increase", GetConVarFloat(cvarValue));
					}
				}
			}
			case 2: {
				for(new i = 1; i <= MaxClients; i++) {
					if(IsValidClient(i)) {
						RemoveAttribute(i, "gesture speed increase");
						if(CheckCommandAccess(i, "tauntspeed_override", ADMFLAG_CUSTOM2)) {
							AddAttribute(i, "gesture speed increase", GetConVarFloat(cvarValue));
						}
					}
				}
			}
		}
	}
}

public OnClientDisconnect(client) {
	RemoveAttribute(client, "gesture speed increase");
}

public OnClientPostAdminCheck(client) {
	switch(GetConVarInt(cvarGlobal)) {
		case 1: {
			AddAttribute(client, "gesture speed increase", GetConVarFloat(cvarValue));
		}
		case 2: {
			if(CheckCommandAccess(client, "tauntspeed_override", ADMFLAG_CUSTOM2)) {
				AddAttribute(client, "gesture speed increase", GetConVarFloat(cvarValue));
			}
		}
	}
}

public Action:TauntMe(client, args) {
	if(!Enabled) return Plugin_Handled;
	if(!IsValidClient(client)) return Plugin_Handled;
	OpenMenu(client);
	return Plugin_Handled;
}

OpenMenu(client) {
	new Handle:ShowMenu = CreateMenu(MenuMainHandler);
	SetMenuTitle(ShowMenu, "Taunt Speed");
	for(new i = 0; i < maxSection; i++) {
		decl String:info[32];
		Format(info, sizeof(info), "%d", i);
		AddMenuItem(ShowMenu, info, sectionName[i]);
	}
	SetMenuExitButton(ShowMenu, true);
	DisplayMenu(ShowMenu, client, 30);
}

public MenuMainHandler(Handle:menu, MenuAction:action, client, slot) {
	switch(action) {
		case MenuAction_Select: {
			decl String:info[32];
			GetMenuItem(menu, slot, info, sizeof(info));
			new value = StringToInt(info);
			AddAttribute(client, "gesture speed increase", sectionValue[value]);
			new bool:isTrue = sectionValue[value] > 1.0;
			if(sectionValue[value] == 1.0) {
				CPrintToChat(client, "{gold}[SM] {greenyellow}Your taunt speed is set to normal.");
			}
			else if(sectionValue[value] > 1.0 || sectionValue[value] < 1.0) {
				CPrintToChat(client, "{gold}[SM] {greenyellow}Your taunt speed is {gold}%.2fx {greenyellow}%s.", sectionValue[value], isTrue ? "faster" : "slower");
			}
		}
		case MenuAction_End: {
			if(slot == MenuCancel_ExitBack) {
				OpenMenu(client);
			}
			CloseHandle(menu);
		}
	}
}

public Action:Taunt(client, args) {
	if(!Enabled) return Plugin_Handled;
	decl String:arg1[65], String:arg2[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new Float:value = StringToFloat(arg2);
	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	if((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(args < 2) {
		CReplyToCommand(client, "{gold}Format: !tauntspeed <player> <speed>");
		return Plugin_Handled;
	}
	
	if(args == 2) {
		for(new i = 0; i < target_count; i++) {
			new target = target_list[i];
			if(IsValidClient(target)) {
				AddAttribute(target, "gesture speed increase", value);
				new bool:isTrue = value > 1.0;
				if(value == 1.0) {
					CPrintToChat(target, "{gold}[SM] {greenyellow}Your taunt speed is set to normal.");
				}
				else if(value > 1.0 || value < 1.0) {
					CPrintToChat(target, "{gold}[SM] {greenyellow}Your taunt speed is {gold}%.2fx {greenyellow}%s.", value, isTrue ? "faster" : "slower");
				}
				if(target_count == 1) {
					CReplyToCommand(client, "{gold}[SM] {greenyellow}You have given {gold}%N {greenyellow}%s taunt speed.", target, isTrue ? "faster" : "slower");
				}
			}
		}
		if(target_count > 1) {
			CReplyToCommand(client, "{gold}[SM] {greenyellow}You have changed other players taunt speed.");
		}
	}
	return Plugin_Handled;
}

public Action:TauntReload(client, args) {
	SetUpTauntSpeedMenu("taunt_speed.cfg");
	return Plugin_Handled;
}

stock AddAttribute(client, String:attribute[], Float:value) {
	if(IsValidClient(client)) {
		TF2Attrib_SetByName(client, attribute, value);
	}
}

stock RemoveAttribute(client, String:attribute[]) {
	if(IsValidClient(client)) {
		TF2Attrib_RemoveByName(client, attribute);
	}
}

stock SetUpTauntSpeedMenu(const String:sFile[]) {
	new String:sPath[PLATFORM_MAX_PATH]; 
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if(!FileExists(sPath)) {
		LogError("Error: Can not find filepath %s", sPath);
		SetFailState("Error: Can not find filepath %s", sPath);
	}
	new Handle:kv = CreateKeyValues("Taunt Speed");
	FileToKeyValues(kv, sPath);

	if(!KvGotoFirstSubKey(kv)) SetFailState("Could not read file: %s", sPath);
	
	maxSection = 0;
	do {
		KvGetSectionName(kv, sectionName[maxSection], sizeof(sectionName[]));
		sectionValue[maxSection] = KvGetFloat(kv, "speed", 0.0);
		if(sectionValue[maxSection] <= 0.0) {
			SetFailState("Error: Cannot set speed less than 0.0 for section - (%s)", sectionName[maxSection]);
		}
		//LogMessage("Section Name: %s ; Float: %f", sectionName[maxSection], sectionValue[maxSection]);
		maxSection++;
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
	LogMessage("Loaded Taunt Speed Config Successfully."); 
}

stock bool:IsValidClient(iClient, bool:bReplay = true) {
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}