#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <updater>

#define UPDATE_URL    "http://epicpwnage.co.cc/sm_plugins/consolestatus.txt"

#define PLUGIN_VERSION 				"1.0.0"
#define FLAG_STRINGS				14

new String:g_FlagNames[FLAG_STRINGS][20] = {
	"res",
	"admin",
	"kick",
	"ban",
	"unban",
	"slay",
	"map",
	"cvars",
	"cfg",
	"chat",
	"vote",
	"pass",
	"rcon",
	"cheat"
};

new TeamArray[MAXPLAYERS+1], ClassArray[MAXPLAYERS+1];
new Handle:sm_consolestatus_talert = INVALID_HANDLE;
new Handle:sm_consolestatus_calert = INVALID_HANDLE;


public Plugin:myinfo = {
    name = "[TF2] ConsoleStatus",
    author = "bobomaster",
    description = "Team joining and class switching show up in console",
    version = PLUGIN_VERSION,
    url = "epicpwnage.co.cc"
}

public OnPluginStart() {
	LoadTranslations("common.phrases");
	
	CreateConVar("sm_consolestatus_version", PLUGIN_VERSION, "ConsoleStatus version number", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_consolestatus_talert = CreateConVar("sm_consolestatus_talert", "1", "Team joining message toggle", FCVAR_PLUGIN);
	sm_consolestatus_calert = CreateConVar("sm_consolestatus_calert", "1", "Class switching message toggle", FCVAR_PLUGIN);
	
	HookEvent("player_team", Event_Team);
	HookEvent("player_changeclass", Event_Class);
	
	RegAdminCmd("sm_cstatus", CheckTeamStatus, ADMFLAG_SLAY);
	
	if (LibraryExists("updater")) {
		Updater_AddPlugin(UPDATE_URL)
	}
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "updater")) {
		Updater_AddPlugin(UPDATE_URL)
	}
}

public Event_Team(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!(GetEventBool(event, "disconnect"))) {
		new String:clientname[MAX_NAME_LENGTH];
		new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
		
		GetEventString(event, "name", clientname, sizeof(clientname));
		
		new bool:autoteam = GetEventBool(event, "autoteam");
		new newteam = GetEventInt(event, "team");
		new oldteam = GetEventInt(event, "oldteam");
		new String:newteamname[MAX_NAME_LENGTH], String:oldteamname[MAX_NAME_LENGTH];
		
		if (newteam == 1) {
			newteamname = "Spectator";
			ClassArray[clientid] = 0;
		}
		if (newteam == 2) newteamname = "RED";
		if (newteam == 3) newteamname = "BLU";
		
		if (oldteam == 1) oldteamname = "Spectator";
		if (oldteam == 2) oldteamname = "RED";
		if (oldteam == 3) oldteamname = "BLU";
		
		new talert = GetConVarInt(sm_consolestatus_talert);
		
		if (talert == 1) {
			if (oldteam == 0) {
				if (autoteam) PrintToServer("Player %s was automatically assigned to team %s", clientname, newteamname);
				else PrintToServer("Player %s joined team %s", clientname, newteamname);
			} else {
				if (autoteam) PrintToServer("Player %s left team %s and was automatically assigned to team %s", clientname, oldteamname, newteamname);
				else PrintToServer("Player %s left team %s and joined team %s", clientname, oldteamname, newteamname);
			}
		}
		
		TeamArray[clientid] = newteam;
	}
}

public Event_Class(Handle:event, const String:name[], bool:dontBroadcast) {
	new String:clientname[MAX_NAME_LENGTH], String:classname[MAX_NAME_LENGTH];
	
	new clientid = GetClientOfUserId(GetEventInt(event, "userid"));
	new class = GetEventInt(event, "class");
	GetClientName(clientid, clientname, sizeof(clientname));
	
	if (class == 1) classname = "Scout";
	if (class == 3) classname = "Soldier";
	if (class == 7) classname = "Pyro";
	if (class == 4) classname = "Demoman";
	if (class == 6) classname = "Heavy";
	if (class == 9) classname = "Engineer"
	if (class == 5) classname = "Medic";
	if (class == 2) classname = "Sniper";
	if (class == 8) classname = "Spy";
	
	new calert = GetConVarInt(sm_consolestatus_calert);
	
	if (calert == 1) PrintToServer("Player %s switched to the %s class!", clientname, classname);

	ClassArray[clientid] = class;
}

public Action:CheckTeamStatus(client, args) {
	new String:arg1[32], String:clientname[MAX_NAME_LENGTH], String:TargetName[MAX_NAME_LENGTH];
	new TargetList[MAXPLAYERS], TargetCount, bool:tn_is_ml;
	
	if (args < 1) {
		arg1 = "@all";
	} else {
		GetCmdArg(1, arg1, sizeof(arg1));
	}
	
	TargetCount = ProcessTargetString(arg1, client, TargetList, MAXPLAYERS, 0, TargetName, sizeof(TargetName), tn_is_ml);
	
	if (TargetCount <= 0) {
		ReplyToTargetError(client, TargetCount);
		return Plugin_Handled;
	}
	
	PrintToConsole(client, "    %-18.17s%-14.13s%-13.12s%-10.9s Class", "Name", "Username", "Admin Type", "Team");
	
	for (new i = 0; i < TargetCount; i++) {
		GetClientName(TargetList[i], clientname, sizeof(clientname));
		new String:teamname[MAX_NAME_LENGTH], String:classname[MAX_NAME_LENGTH], String:username[MAX_NAME_LENGTH];
		new flags = GetUserFlagBits(TargetList[i]);
		new AdminId:adminid = GetUserAdmin(TargetList[i]);
		new String:flagstring[255];
		
		if (flags == 0) {
			strcopy(flagstring, sizeof(flagstring), "none");
		} else if (flags & ADMFLAG_ROOT) {
			strcopy(flagstring, sizeof(flagstring), "root");
		} else {
			FlagsToString(flagstring, sizeof(flagstring), flags);
		}
		
		if (adminid != INVALID_ADMIN_ID) {
			GetAdminUsername(adminid, username, sizeof(username));
		}
		
		new team = TeamArray[TargetList[i]];
		new class = ClassArray[TargetList[i]];
		
		if (team == 0) teamname = "";
		if (team == 1) teamname = "Spectator";
		if (team == 2) teamname = "RED";
		if (team == 3) teamname = "BLU";
		
		if (class == 0) classname = "";
		if (class == 1) classname = "Scout";
		if (class == 3) classname = "Soldier";
		if (class == 7) classname = "Pyro";
		if (class == 4) classname = "Demoman";
		if (class == 6) classname = "Heavy";
		if (class == 9) classname = "Engineer"
		if (class == 5) classname = "Medic";
		if (class == 2) classname = "Sniper";
		if (class == 8) classname = "Spy";
		
		PrintToConsole(client, "%2i. %-18.17s%-14.13s%-13.12s%-10.9s %s", TargetList[i], clientname, username, flagstring, teamname, classname);
	}
	
	if (GetCmdReplySource() == SM_REPLY_TO_CHAT) PrintToChat(client, "[StatusBot]: See console for output")
	
	return Plugin_Handled;
}

FlagsToString(String:buffer[], maxlength, flags) {
	decl String:joins[FLAG_STRINGS+1][32];
	new total;

	for (new i=0; i<FLAG_STRINGS; i++) {
		if (flags & (1<<i)) {
			strcopy(joins[total++], 32, g_FlagNames[i]);
		}
	}
	
	decl String:custom_flags[32];
	if (CustomFlagsToString(custom_flags, sizeof(custom_flags), flags)) {
		Format(joins[total++], 32, "custom(%s)", custom_flags);
	}

	ImplodeStrings(joins, total, ", ", buffer, maxlength);
}

CustomFlagsToString(String:buffer[], maxlength, flags) {
	decl String:joins[6][6];
	new total;
	
	for (new i=_:Admin_Custom1; i<=_:Admin_Custom6; i++) {
		if (flags & (1<<i)) {
			IntToString(i - _:Admin_Custom1 + 1, joins[total++], 6);
		}
	}
	
	ImplodeStrings(joins, total, ",", buffer, maxlength);
	
	return total;
}