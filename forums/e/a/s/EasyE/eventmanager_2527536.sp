#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <morecolors>
//Comment out these includes if you don't use on them on your server(and comment at line 448)
#include <basecomm>
#include <sourcecomms>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION		"1.0"

ConVar eventTalkEnable;

bool bLocationSet = false;
bool rLocationSet = false;
bool sLocationSet = false;
bool eventStart = false;
bool skipHook = false;
bool skipChat = false;
bool s1 = false;
bool s2 = false;
bool s3 = false;
bool s4 = false;
bool s5 = false;

int classArray[] =  {0, 1, 3, 7, 4, 6, 9, 5, 2, 8};
int eventClass = 0;

char classStringArray[][] =  {"Any", "Scout", "Soldier", "Pyro", "Demo", "Heavy", "Engineer", "Medic", "Sniper", "Spy"};

float bLocation[3];
float rLocation[3];
float sLocation[3];

Menu eventMenu;
Menu configureEventMenu;
Menu stripMenu;

public Plugin myinfo = {
	name = "[TF2] Event-Manager",
	author = "EasyE / TheXeon",
	description = "Plugin for automating events, made for event hosters.",
	version = PLUGIN_VERSION,
	url = "https://neogenesisnetwork.net/"
}


public void OnPluginStart() {
	// Commands
	RegAdminCmd("sm_startevent", Command_StartEvent, ADMFLAG_GENERIC, "Start's an event.");
	RegAdminCmd("sm_stopevent", Command_StopEvent, ADMFLAG_GENERIC, "Closes the joining period for the event.");
	RegAdminCmd("sm_blocation", Command_SetBluLocation, ADMFLAG_GENERIC, "Set's the location where blu will teleport to.");
	RegAdminCmd("sm_rlocation", Command_SetRedLocation, ADMFLAG_GENERIC, "Set's the location where red will teleport to.");
	RegAdminCmd("sm_setspectate", Command_SetSpectateLocation, ADMFLAG_GENERIC, "Set's the location where spectators will teleport to.");
	RegAdminCmd("sm_setclass", Command_SetClass, ADMFLAG_GENERIC, "Set's the class the player will be set to before joining the event.");
	RegAdminCmd("sm_event", Command_EventMenu, ADMFLAG_GENERIC, "Opens the menu interface for event manager plugin.");
	
	RegConsoleCmd("sm_joinevent", Command_JoinEvent, "When an event is started, use this to join it!");
	RegConsoleCmd("sm_spectate", Command_Spectate, "Spectate an event.");
	
	
	// Menus
	eventMenu = new Menu(EventMenuHandler);
	eventMenu.SetTitle("=== Event Menu ===");
	
	configureEventMenu = new Menu(ConfigureMenuHandler);
	configureEventMenu.SetTitle("=== Event Types ===");
	SetMenuExitBackButton(configureEventMenu, true);
	
	stripMenu = new Menu(StripMenuHandler);
	stripMenu.SetTitle("=== Strip Weapons ===");
	StripMenuBuilder();
	SetMenuExitBackButton(stripMenu, true);
	
	
	// ConVars
	CreateConVar("sm_eventmanager_version", PLUGIN_VERSION, "*DONT MANUALLY CHANGE*Event-Manager Plugin Version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	eventTalkEnable = CreateConVar("sm_eventtalk_enable", "0", "Mutes non admins, from eventmanager plugin.");
	eventTalkEnable.AddChangeHook(OnConVarChange);
}

public void OnAllPluginsLoaded() {
	EventMenuBuilder();
	ConfigureMenuBuilder();
}

public void OnClientPostAdminCheck(int client) {
	if (eventTalkEnable.BoolValue) {
		if (GetUserAdmin(client) !=INVALID_ADMIN_ID)
			PrintToChat(client, "\x04[Event]\x01 Event talk enabled, all non admins have been muted. You have not been muted");
		else {
			PrintToChat(client, "\x04[Event]\x01 Event talk enabled, all non admins have been muted. You have been muted");
			SetClientListeningFlags(client, VOICE_MUTED);
		}  
	}
}


/********************************************
			Command Callbacks
********************************************/


public Action Command_EventMenu(int client, int args) {
	if (!IsValidClient(client))return Plugin_Handled;
	eventMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_StartEvent(int client, int args) {
	if (eventStart) {
		CPrintToChat(client, "{GREEN}[Event]{Default} There is already an event running.");
		return Plugin_Handled;
	}
	else if (!bLocationSet && !rLocationSet) {
		CPrintToChat(client, "{GREEN}[Event]{Default} Blu/red spawn has not been set");
		return Plugin_Handled;
	}
	else if (sLocationSet) {
		CPrintToChatAll("{GREEN}[Event]{Default} An event has been started, do !joinevent to join, or !spectate to spectate.");
		eventStart = true;
		return Plugin_Handled;
	}
	else {
		CPrintToChatAll("{GREEN}[Event]{Default} An event has been started, do !joinevent to join.");
		eventStart = true;
		return Plugin_Handled;
	}
}

public Action Command_StopEvent(int client, int args) {
	if (eventStart) {
		CPrintToChatAll("{GREEN}[Event]{DEFAULT} The event joining time is over.");
		eventStart = false;
		bLocationSet = false;
		rLocationSet = false;
		ConfigureMenuBuilder();
	} 
	else
		CPrintToChat(client, "{GREEN}[Event]{DEFAULT} There is no event to stop.");
	return Plugin_Handled;
}

public Action Command_SetBluLocation(int client, int args) {
	if (!IsValidClient(client))return Plugin_Handled;
	if (eventStart) {
		CPrintToChatAll("{GREEN}[Event]{Default} You can not modify event parameters while an event is running");
		return Plugin_Handled;
	}
	if (!bLocationSet) {
		GetClientAbsOrigin(client, bLocation);
		CReplyToCommand(client, "{GREEN}[Event]{DEFAULT} Location has been set.");
		bLocationSet = true;
	}
	else {
		bLocationSet = false;
		CReplyToCommand(client, "{GREEN}[Event]{DEFAULT} Location has been removed.");
	}
	ConfigureMenuBuilder();
	return Plugin_Handled;
}

public Action Command_SetRedLocation(int client, int args) {
	if (!IsValidClient(client))return Plugin_Handled;
	if (eventStart) {
		CPrintToChatAll("{GREEN}[Event]{Default} You can not modify event parameters while an event is running");
		return Plugin_Handled;
	}
	if (!rLocationSet) {
		GetClientAbsOrigin(client, rLocation);
		CReplyToCommand(client, "{GREEN}[Event]{DEFAULT} Location has been set.");
		rLocationSet = true;
	}
	else {
		rLocationSet = false;
		CReplyToCommand(client, "{GREEN}[Event]{DEFAULT} Location has been removed.");
	}
	ConfigureMenuBuilder();
	return Plugin_Handled;
}

public Action Command_SetSpectateLocation(int client, int args) {
	if (!IsValidClient(client))return Plugin_Handled;
	if (!sLocationSet) {
		GetClientAbsOrigin(client, sLocation);
		CPrintToChat(client, "{GREEN}[Event]{Default} Location has been set");
		sLocationSet = true;
	}
	else {
		CPrintToChat(client, "{GREEN}[Event]{Default} Location has been removed.");
		sLocationSet = false;
	}
	ConfigureMenuBuilder();
	return Plugin_Handled;
}

public Action Command_SetClass(int client, int args) {
	if(eventStart) {
		CPrintToChat(client, "{GREEN}[Event]{Default} You can not modify event parameters while an event is running");
		return Plugin_Handled;
	}
	char arg1[32];
	int iBuffer;
	if (args >= 1 && GetCmdArg(1, arg1, sizeof(arg1))) {
		iBuffer = StringToInt(arg1);
		if(iBuffer >= 0 && iBuffer < 10) {
			eventClass = iBuffer;
			if(!skipChat)
				CPrintToChatAll("{GREEN}[Event]{Default} Class selected: %s", classStringArray[eventClass]);
		}
		else {
			CPrintToChat(client, "{GREEN}[Event]{Default} Paramater out of bounds, enter 0 for no class, 1-9 for classes(in order).");
			return Plugin_Handled;
		}
	}
	else {
		if (eventClass < 9)eventClass++;
		else eventClass = 0;
		if(!skipChat)
			CPrintToChatAll("{GREEN}[Event]{Default} Class selected: %s", classStringArray[eventClass]);
	}
	skipChat = false;
	ConfigureMenuBuilder();
	return Plugin_Handled;
}

public Action Command_JoinEvent(int client, int args) {
	if (!IsValidClient(client))return Plugin_Handled;
	if (eventStart) {
		if (bLocationSet) {
			if (!rLocationSet)
				EventPrep(client, 1);
			else {
				if (GetClientTeam(client) == 3) EventPrep(client, 1);
				else EventPrep(client, 2);
			}
		}
		else if (rLocationSet)
			EventPrep(client, 2);
	}
	else
		CPrintToChat(client, "{GREEN}[Event]{DEFAULT} There is no event available to join.");
	return Plugin_Handled;
}

public Action Command_Spectate(int client, int args) {
	if (!IsValidClient(client))return Plugin_Handled;
	if (!eventStart) {
		CPrintToChat(client, "{GREEN}[Event]{Default} There is no event to spectate.");
		return Plugin_Handled;
	}
	else if (!sLocationSet) {
		CPrintToChat(client, "{GREEN}[Event]{Default} Spectating is disabled.");
		return Plugin_Handled;
	}
	else {
		TeleportEntity(client, sLocation, NULL_VECTOR, NULL_VECTOR);
		return Plugin_Handled;
	}
}


/********************************************
			Hook Callbacks
********************************************/


public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
	if (!skipHook) {
		EventTalk();
		EventMenuBuilder();
	}
	else
		skipHook = false;
}


/********************************************
			Menu Handlers
********************************************/


public int EventMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char info[32];
		eventMenu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "startevent", false))
			FakeClientCommand(param1, "sm_startevent");
		if (StrEqual(info, "stopevent", false))
			FakeClientCommand(param1, "sm_stopevent");
			
		if (StrEqual(info, "configureevent", false))
				configureEventMenu.Display(param1, MENU_TIME_FOREVER);
		if (StrEqual(info, "eventtalk", false)) {
			if (eventTalkEnable.BoolValue) {
				skipHook = true;
				eventTalkEnable.SetInt(0); 
			}
			else {
				skipHook = true;
				eventTalkEnable.SetInt(1);
			}
			EventTalk();
			EventMenuBuilder();
			eventMenu.Display(param1, MENU_TIME_FOREVER);
		}
	}
}

public int ConfigureMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		char info[32];
		configureEventMenu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "blocation", false)) {
			FakeClientCommand(param1, "sm_blocation");
			configureEventMenu.Display(param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info, "rlocation", false)) {
			FakeClientCommand(param1, "sm_rlocation");
			configureEventMenu.Display(param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info, "slocation", false)) {
			FakeClientCommand(param1, "sm_setspectate");
			configureEventMenu.Display(param1, MENU_TIME_FOREVER);
		}
		if (StrEqual(info, "class", false)) {
			skipChat = true;
			FakeClientCommand(param1, "sm_setclass");
			configureEventMenu.Display(param1, MENU_TIME_FOREVER);
			skipChat = false;
		}
		if (StrEqual(info, "stripmenu", false))
			if (!eventStart)
				stripMenu.Display(param1, MENU_TIME_FOREVER);
			else {
				CPrintToChat(param1, "{GREEN}[Event]{Default} You can not modify event parameters while an event is running");
				configureEventMenu.Display(param1, MENU_TIME_FOREVER);
			}
		if (StrEqual(info, "startevent", false)) {
			FakeClientCommand(param1, "sm_startevent");
		}
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		eventMenu.Display(param1, MENU_TIME_FOREVER);
}

public int StripMenuHandler(Menu menu, MenuAction action, int param1, int param2) {
	if (action == MenuAction_Select) {
		if(!eventStart) {
			char info[32];
			stripMenu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, "strip1", false)) {
				if (s1)s1 = false;
				else s1 = true;
			}
			if (StrEqual(info, "strip2", false)) {
				if (s2)s2 = false;
				else s2 = true;
			}
			if (StrEqual(info, "strip3", false)) {
				if (s3)s3 = false;
				else s3 = true;
			}
			if (StrEqual(info, "strip4", false)) {
				if (s4)s4 = false;
				else s4 = true;
			}
			if (StrEqual(info, "strip5", false)) {
				if (s5)s5 = false;
				else s5 = true;
			}
		}
		else
			CPrintToChat(param1, "{GREEN}[Event]{Default} You can not modify event parameters while an event is running");
		StripMenuBuilder();
		stripMenu.Display(param1, MENU_TIME_FOREVER);
	}
	else if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack)
		configureEventMenu.Display(param1, MENU_TIME_FOREVER);
}


/********************************************
				Extras
********************************************/


//1 for blu, 2 for red
public void EventPrep(int client, int location) {
	InstantTeamChanger(client, location);
	TF2_RespawnPlayer(client);
	if(eventClass != 0) TF2_SetPlayerClass(client, view_as<TFClassType>(classArray[eventClass]));
	TF2_RespawnPlayer(client);
	
	if (s1)TF2_RemoveWeaponSlot(client, 0);
	if (s2)TF2_RemoveWeaponSlot(client, 1);
	if (s3)TF2_RemoveWeaponSlot(client, 2);
	if (s4)TF2_RemoveWeaponSlot(client, 3);
	if (s5)TF2_RemoveWeaponSlot(client, 4);
	
	if (location == 1)TeleportEntity(client, bLocation, NULL_VECTOR, NULL_VECTOR);
	else TeleportEntity(client, rLocation, NULL_VECTOR, NULL_VECTOR);
}

//1 for blu, 2 for red
public void InstantTeamChanger(int client, int team) {
	if (IsValidClient(client)) {
		if (team == 1) {
			if (GetClientTeam(client) == 3)
				TF2_ChangeClientTeam(client, TFTeam_Blue);
			else
				TF2_ChangeClientTeam(client, TFTeam_Blue);
		}
		else if (team == 2) {
			if (GetClientTeam(client) == 2)
				TF2_ChangeClientTeam(client, TFTeam_Red);
			else
				TF2_ChangeClientTeam(client, TFTeam_Red);
		}
		CreateTimer(0.0001, TeamChangerCallback, client);
	}
}

public Action TeamChangerCallback(any client) {
	if (IsValidClient(client))
		TF2_RespawnPlayer(client);
}

public void EventTalk() {	
	if (eventTalkEnable.BoolValue) {
		CPrintToChatAll("{GREEN}[Event]{Default} Event talk enabled, all non admins are muted");
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidClient(i))continue;
			if (GetUserAdmin(i) !=INVALID_ADMIN_ID)
				continue;
			else {
				if (!IsValidClient(i))continue;
				SetClientListeningFlags(i, VOICE_MUTED);
			}
		}
	}
	else {
		CPrintToChatAll("{GREEN}[Event]{Default} Event talk disabled, everyone has been unmuted.");
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidClient(i))continue;
			//Comment this if statement if you don't have sourcecomms!
			if(SourceComms_GetClientMuteType(i) == bNot)
				SetClientListeningFlags(i, VOICE_NORMAL);
			
			//Comment this if statement if you don't have basecomm!
			if (!BaseComm_IsClientMuted(i))
				SetClientListeningFlags(i, VOICE_NORMAL);
		}
	}
}

public void EventMenuBuilder() {
	char eventTalkStatus[32];
	Format(eventTalkStatus, sizeof(eventTalkStatus), "Mute non-admins: %s", eventTalkEnable.BoolValue ? "Enabled" : "Disabled");
	eventMenu.RemoveAllItems();
	eventMenu.AddItem("startevent", "Start an event");
	eventMenu.AddItem("stopevent", "Stop event");
	eventMenu.AddItem("configureevent", "Configure event settings");
	eventMenu.AddItem("eventtalk", eventTalkStatus);
	
}
public void ConfigureMenuBuilder() {
	configureEventMenu.RemoveAllItems();
	
	char bLocationStatus[32];
	char rLocationStatus[32];
	char sLocationStatus[32];
	char classStatus[32];
	
	Format(bLocationStatus, sizeof(bLocationStatus), "Set blu spawn: %s", bLocationSet ? "Enabled" : "Disabled");
	configureEventMenu.AddItem("blocation", bLocationStatus);
	Format(rLocationStatus, sizeof(rLocationStatus), "Red spawn: %s", rLocationSet ? "Enabled" : "Disabled");
	configureEventMenu.AddItem("rlocation", rLocationStatus);
	Format(sLocationStatus, sizeof(sLocationStatus), "Spectate: %s", sLocationSet ? "Enabled" : "Disabled");
	configureEventMenu.AddItem("slocation", sLocationStatus);
	Format(classStatus, sizeof(classStatus), "Select class: %s", classStringArray[eventClass]);
	configureEventMenu.AddItem("class", classStatus);
	configureEventMenu.AddItem("stripmenu", "Strip weapons");
	configureEventMenu.AddItem("startevent", "Start an event");
}

public void StripMenuBuilder() {
	stripMenu.RemoveAllItems();
	char strip1Status[32], strip2Status[32], strip3Status[32], strip4Status[32], strip5Status[32];
	Format(strip1Status, sizeof(strip1Status), "Strip primary: %s", s1 ? "Enabled" : "Disabled");
	Format(strip2Status, sizeof(strip2Status), "Strip secondary: %s", s2 ? "Enabled" : "Disabled");
	Format(strip3Status, sizeof(strip3Status), "Strip melee: %s", s3 ? "Enabled" : "Disabled");
	Format(strip4Status, sizeof(strip4Status), "Strip PDA1: %s", s4 ? "Enabled" : "Disabled");
	Format(strip5Status, sizeof(strip5Status), "Strip PDA2: %s", s5 ? "Enabled" : "Disabled");
	
	stripMenu.AddItem("strip1", strip1Status);
	stripMenu.AddItem("strip2", strip2Status);
	stripMenu.AddItem("strip3", strip3Status);
	stripMenu.AddItem("strip4", strip4Status);
	stripMenu.AddItem("strip5", strip5Status);
}

public bool IsValidClient(int client) {
	if (client > 4096) client = EntRefToEntIndex(client);
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	return true;
}