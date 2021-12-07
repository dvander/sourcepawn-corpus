#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

/* general.inc */
#define MAXCLIENTS MAXPLAYERS + 1
/* ----------- */

/* left4dead.inc */
#define L4D_TEAM_UNASSIGNED 0
#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3
/* ------------- */

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = {
	name = "[L4D(2)] AFK Manager",
	author = "Matthias Vance",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.matthiasvance.com/"
};

new String:immuneFlagChar[] = "z";
new AdminFlag:immuneFlag = Admin_Root;

new Float:advertiseInterval = 120.0;
new Handle:advertiseTimer = INVALID_HANDLE;
new String:ads[][] = {
	"Use !idle if you plan to go AFK for a while.",
	"Use !team if you want to change your team."
};
new adCount = 0;
new adIndex = 0;

new Float:specTime[MAXCLIENTS];
new Float:afkTime[MAXCLIENTS];

new Float:checkInterval = 2.0;
new Float:maxAfkSpecTime = 20.0;
new Float:maxAfkKickTime = 40.0;
new Float:joinTeamInterval = 5.0;
new Float:timeLeftInterval = 5.0;

new Float:lastMessage[MAXCLIENTS];

new Float:clientPos[MAXCLIENTS][3];
new Float:clientAngles[MAXCLIENTS][3];

new messageLevel = 3;

new Handle:hSetHumanSpec, Handle:hTakeOverBot;

public OnPluginStart() {
	CreateConVar("l4d_afkmanager_version", PLUGIN_VERSION, "[L4D(2)] AFK Manager", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	SetConVarString(FindConVar("l4d_afkmanager_version"), PLUGIN_VERSION);
	
	new Handle:hConfig = LoadGameConfigFile("l4d_afkmanager");
	if(hConfig == INVALID_HANDLE) SetFailState("[AFK Manager] Could not load l4d_afkmanager gamedata.");

	// SetHumanSpec
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "SetHumanSpec")) {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSetHumanSpec = EndPrepSDKCall();
	}
	if(hSetHumanSpec == INVALID_HANDLE) SetFailState("[AFK Manager] SetHumanSpec not found.");

	// TakeOverBot
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "TakeOverBot")) {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hTakeOverBot = EndPrepSDKCall();
	}
	if(hTakeOverBot == INVALID_HANDLE) SetFailState("[AFK Manager] TakeOverBot not found.");

	decl String:temp[12];

	HookConVarChange(CreateConVar("afk_immuneflag", immuneFlagChar, "Admins with this flag have kick immunity."), convar_ImmuneFlag);
	FloatToString(advertiseInterval, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_adinterval", temp, "Interval in which the plugin will advertise the 'idle' command."), convar_AdvertiseTime);
	FloatToString(maxAfkSpecTime, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_spectime", temp, "AFK time after which you will be moved to the Spectator team."), convar_AfkSpecTime);
	FloatToString(maxAfkKickTime, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_kicktime", temp, "AFK time after which you will be kicked."), convar_AfkKickTime);
	HookConVarChange(CreateConVar("afk_messages", "2", "Control spec/kick messages. (0 = disable, 1 = spec, 2 = kick, 3 = spec + kick"), convar_Messages);
	FloatToString(joinTeamInterval, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_joinmsg_time", temp), convar_JoinMsgTime);
	FloatToString(timeLeftInterval, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_warning_time", temp), convar_WarningTime);
	
	RegConsoleCmd("sm_idle", cmd_Idle, "Go AFK.");
	RegConsoleCmd("sm_team", cmd_Team, "Change team.");

	advertiseTimer = CreateTimer(advertiseInterval, timer_Advertise, _, TIMER_REPEAT);
	CreateTimer(checkInterval, timer_Check, _, TIMER_REPEAT);

	AutoExecConfig(true, "l4d_afkmanager");

	HookEvent("player_team", event_PlayerTeam);
}

public convar_JoinMsgTime(Handle:convar, const String:oldValue[], const String:newValue[]) {
	joinTeamInterval = StringToFloat(newValue);
}

public convar_WarningTime(Handle:convar, const String:oldValue[], const String:newValue[]) {
	timeLeftInterval = StringToFloat(newValue);
}

public convar_Messages(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(messageLevel <= 0) {
		SetConVarInt(convar, 0);
		return;
	}
	if(messageLevel >= 3) {
		SetConVarInt(convar, 3);
		return;
	}
	messageLevel = GetConVarInt(convar);
}

public Action:cmd_Team(client, argCount) {
	new Handle:menu = CreateMenu(menu_Team);
	SetMenuTitle(menu, "Choose your team:");
	AddMenuItem(menu, "2", "Survivors");
	AddMenuItem(menu, "3", "Infected");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
	return Plugin_Handled;
}

public findBot(team) {
	new deadBot = 0;
	for(new client = 1; client < MaxClients; client++) {
		if(!IsClientInGame(client) || !IsFakeClient(client) || GetClientTeam(client) != team) continue;
		if(IsPlayerAlive(client)) {
			return client;
		} else {
			deadBot = client;
		}
	}
	return deadBot;
	
}

public menu_Team(Handle:menu, MenuAction:action, param1, param2) {
	switch(action) {
		case MenuAction_Select: {
			new String:info[32];
			if(GetMenuItem(menu, param2, info, sizeof(info))) {
				new team = StringToInt(info);
				new bot;
				switch(team) {
					case L4D_TEAM_SURVIVOR: {
						bot = findBot(L4D_TEAM_SURVIVOR);
						if(bot == 0) {
							PrintToChat(param1, "This team is full.");
						} else {
							SDKCall(hSetHumanSpec, bot, param1);
							SDKCall(hTakeOverBot, param1, true);
						}
					}
					case L4D_TEAM_INFECTED: {
						ChangeClientTeam(param1, L4D_TEAM_INFECTED);
					}
				}
			}
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public Action:cmd_Idle(client, argCount) {
	ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
	return Plugin_Handled;
}

public Action:timer_Check(Handle:timer) {
	new Float:currentPos[3];
	new Float:currentAngles[3];

	new team;
	new bool:isAFK = false;
	new AdminId:id = INVALID_ADMIN_ID;
	new client, index;

	for(client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && !IsFakeClient(client)) {
			team = GetClientTeam(client);
			if(team == L4D_TEAM_SPECTATOR) {
				id = GetUserAdmin(client);
				if(id != INVALID_ADMIN_ID && GetAdminFlag(id, immuneFlag)) {
					if(GetClientTime(client) - lastMessage[client] >= joinTeamInterval) {
						PrintToChat(client, "[AFK Manager] Say !team to choose a team.");
						lastMessage[client] = GetClientTime(client);
					}
					continue;
				}

				specTime[client] += checkInterval;
				if(specTime[client] >= maxAfkKickTime) {
					KickClient(client, "You were AFK for too long");
					if(messageLevel >= 2) PrintToChatAll("[AFK Manager] Player '%N' was kicked.", client);
				} else {
					if(GetClientTime(client) - lastMessage[client] >= timeLeftInterval) {
						PrintToChat(client, "[AFK Manager] You can spectate for %d more seconds before you will be kicked.", RoundToFloor(maxAfkKickTime - specTime[client]));
						lastMessage[client] = GetClientTime(client);
					}
					if(GetClientTime(client) - lastMessage[client] >= joinTeamInterval) {
						PrintToChat(client, "[AFK Manager] Say !team to choose a team.");
						lastMessage[client] = GetClientTime(client);
					}
				}
			} else if(IsPlayerAlive(client) && (team == L4D_TEAM_SURVIVOR || team == L4D_TEAM_INFECTED)) {
				GetClientAbsOrigin(client, currentPos);
				GetClientAbsAngles(client, currentAngles);

				isAFK = true;
				for(index = 0; index < 3; index++) {
					if(currentPos[index] != clientPos[client][index]) {
						isAFK = false;
						break;
					}
				}
				if(isAFK) {
					for(index = 0; index < 3; index++) {
						if(currentAngles[index] != clientAngles[client][index]) {
							isAFK = false;
							break;
						}
					}
				}
				if(isAFK) {
					afkTime[client] += checkInterval;
					if(afkTime[client] >= maxAfkSpecTime) {
						ChangeClientTeam(client, L4D_TEAM_SPECTATOR);
						if(messageLevel == 1 || messageLevel == 3) PrintToChatAll("[AFK Manager] Player '%N' was moved to Spectator team.", client);
					}
				} else {
					afkTime[client] = 0.0;
				}

				for(index = 0; index < 3; index++) {
					clientPos[client][index] = currentPos[index];
					clientAngles[client][index] = currentAngles[index];
				}
			}
		}
	}
	return Plugin_Continue;
}

public convar_AfkSpecTime(Handle:convar, const String:oldValue[], const String:newValue[]) {
	maxAfkSpecTime = StringToFloat(newValue);
	if(maxAfkSpecTime == 0.0 || maxAfkSpecTime <= 10.0) {
		SetConVarFloat(convar, 10.0);
		return;
	}
}

public convar_AfkKickTime(Handle:convar, const String:oldValue[], const String:newValue[]) {
	maxAfkKickTime = StringToFloat(newValue);
	if(maxAfkKickTime == 0.0 || maxAfkKickTime <= 10.0) {
		SetConVarFloat(convar, 10.0);
		return;
	}
}

public Action:event_PlayerTeam(Handle:event, const String:eventName[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	switch(team) {
		case L4D_TEAM_SPECTATOR: {
			specTime[client] = 0.0;
		}
		case L4D_TEAM_SURVIVOR, L4D_TEAM_INFECTED: {
			afkTime[client] = 0.0;
		}
	}
	if(GetEventBool(event, "disconnected")) {
		clientPos[client] = Float:{ 0.0, 0.0, 0.0 };
		clientAngles[client] = Float:{ 0.0, 0.0, 0.0 };
	}
}

public convar_AdvertiseTime(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(advertiseTimer != INVALID_HANDLE) {
		CloseHandle(advertiseTimer);
		advertiseTimer = INVALID_HANDLE;
	}
	advertiseInterval = StringToFloat(newValue);
	if(advertiseInterval <= 10.0) {
		SetConVarFloat(convar, 10.0);
		return;
	}
	if(advertiseInterval > 0.0) advertiseTimer = CreateTimer(advertiseInterval, timer_Advertise, _, TIMER_REPEAT);
}

public Action:timer_Advertise(Handle:timer) {
	PrintToChatAll("[AFK Manager] %s", ads[adIndex++]);
	if(adIndex >= adCount) adIndex = 0;
	return Plugin_Continue;
}

public convar_ImmuneFlag(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(strlen(newValue) != 1) {
		PrintToServer("[AFK Manager] Invalid flag value (%s).", newValue);
		SetConVarString(convar, oldValue);
		return;
	}
	if(!FindFlagByChar(newValue[0], immuneFlag)) {
		PrintToServer("[AFK Manager] Invalid flag value (%s).", newValue);
		SetConVarString(convar, oldValue);
		return;
	}
}
