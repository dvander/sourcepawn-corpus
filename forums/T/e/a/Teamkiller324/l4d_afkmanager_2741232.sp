#pragma		semicolon	1
#pragma		newdecls	required

#include	<sdktools>

/***************************/

//Imported from Tklib (TK Libraries)

enum	L4DTeam
{
	L4DTeam_Unassigned	=	0,
	L4DTeam_Spectator	=	1,
	L4DTeam_Survivor	=	2,
	L4DTeam_Infected	=	3
}

/**
 * Gets a client's current team.
 *
 * @param client		Client index.
 * @return				Current L4DTeam of client.
 * @error				Invalid client index.
 */
stock L4DTeam L4D_GetClientTeam(int client)	{
	if(!IsValidClient(client))
		ThrowError("Client index %d is invalid", client);
	
	return	view_as<L4DTeam>(GetClientTeam(client));
}

/**
 * Changes a client's current team.
 *
 * @param client		Client index.
 * @param team			L4DTeam team symbol.
 * @error				Invalid client index.
 */
stock void L4D_ChangeClientTeam(int client, L4DTeam team)	{
	if(!IsValidClient(client))
		ThrowError("Client index %d is invalid", client);
	
	ChangeClientTeam(client,	view_as<int>(team));
}

/****************************/

// Lets make sure clients are valid

bool IsValidClient(int client, bool CheckAlive=true)	{
	if(client == 0)
		return	false;
	if(client == -1)
		return	false;
	if(client < 1 || client > MaxClients)
		return	false;
	if(!IsClientConnected(client))
		return	false;
	if(!IsClientInGame(client))
		return	false;
	if(CheckAlive)	{
		if(!IsPlayerAlive(client))
			return	false;
	}
	if(IsClientReplay(client))
		return	false;
	if(IsClientSourceTV(client))
		return	false;
	return	true;
}

/****************************/

#define		PLUGIN_VERSION	"1.3.1"

public	Plugin	myinfo	=	{
	name		=	"[L4D(2)] AFK Manager",
	author		=	"Matthias Vance",
	description	=	"",
	version		=	PLUGIN_VERSION,
	url			=	"http://www.matthiasvance.com/"
};

char		immuneFlagChar[] = "z";
AdminFlag	immuneFlag = Admin_Root;

float		advertiseInterval = 120.0;
Handle		advertiseTimer = INVALID_HANDLE;

char		ads[][] = {
    "Use !idle if you plan to go AFK for a while.",
    "Use !team if you want to change your team."
};
int		adCount = 0;
int		adIndex = 0;

float	specTime[MAXPLAYERS+1];
float	afkTime[MAXPLAYERS+1];

float	checkInterval = 2.0;
float	maxAfkSpecTime = 20.0;
float	maxAfkKickTime = 40.0;
float	joinTeamInterval = 5.0;
float	timeLeftInterval = 5.0;

float	lastMessage[MAXPLAYERS+1];

float	clientPos[MAXPLAYERS+1][3];
float	clientAngles[MAXPLAYERS+1][3];

int		messageLevel = 3;

Handle hSetHumanSpec, hTakeOverBot;

public void OnPluginStart() {
	CreateConVar("l4d_afkmanager_version", PLUGIN_VERSION, "[L4D(2)] AFK Manager", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	FindConVar("l4d_afkmanager_version").SetString(PLUGIN_VERSION);
	
	GameData hConfig = new GameData("l4d_afkmanager");
	if(hConfig == INVALID_HANDLE)
		SetFailState("[AFK Manager] Could not load l4d_afkmanager gamedata.");
	
	// SetHumanSpec
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "SetHumanSpec")) {
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSetHumanSpec = EndPrepSDKCall();
	}
	if(hSetHumanSpec == INVALID_HANDLE)
		SetFailState("[AFK Manager] SetHumanSpec not found.");
	
	// TakeOverBot
	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "TakeOverBot")) {
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hTakeOverBot = EndPrepSDKCall();
	}
	if(hTakeOverBot == INVALID_HANDLE)
		SetFailState("[AFK Manager] TakeOverBot not found.");
	
	char temp[12];
	
	CreateConVar("afk_immuneflag", immuneFlagChar, "Admins with this flag have kick immunity.").AddChangeHook(convar_ImmuneFlag);
	FloatToString(advertiseInterval, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_adinterval", temp, "Interval in which the plugin will advertise the 'idle' command."), convar_AdvertiseTime);
	FloatToString(maxAfkSpecTime, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_spectime", temp, "AFK time after which you will be moved to the Spectator team."), convar_AfkSpecTime);
	FloatToString(maxAfkKickTime, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_kicktime", temp, "AFK time after which you will be kicked."), convar_AfkKickTime);
	CreateConVar("afk_messages", "2", "Control spec/kick messages. (0 = disable, 1 = spec, 2 = kick, 3 = spec + kick").AddChangeHook(convar_Messages);
	FloatToString(joinTeamInterval, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_joinmsg_time", temp), convar_JoinMsgTime);
	FloatToString(timeLeftInterval, temp, sizeof(temp)); HookConVarChange(CreateConVar("afk_warning_time", temp), convar_WarningTime);
	
	RegConsoleCmd("sm_idle", cmd_Idle, "Go AFK.");
	RegConsoleCmd("sm_team", cmd_Team, "Change team.");
	
	advertiseTimer = CreateTimer(advertiseInterval, timer_Advertise, _, TIMER_REPEAT);
	CreateTimer(checkInterval, timer_Check, _, TIMER_REPEAT);
	
	AutoExecConfig(true, "l4d_afkmanager");
	
	HookEvent("player_team", event_PlayerTeam);
}

void convar_JoinMsgTime(ConVar convar, const char[] oldValue, const char[] newValue)	{
    joinTeamInterval = StringToFloat(newValue);
}

void convar_WarningTime(ConVar convar, const char[] oldValue, const char[] newValue)	{
    timeLeftInterval = StringToFloat(newValue);
}

void convar_Messages(ConVar convar, const char[] oldValue, const char[] newValue)	{
	if(messageLevel <= 0) {
		convar.SetInt(0);
		return;
	}
	if(messageLevel >= 3) {
		convar.SetInt(3);
		return;
	}
	messageLevel = convar.IntValue;
}

Action cmd_Team(int client, int args) {
	Menu menu = new Menu(menu_Team);
	menu.SetTitle("Choose your team:");
	menu.AddItem("2", "Survivors");
	menu.AddItem("3", "Infected");
	menu.ExitButton = true ;
	menu.Display(client, MENU_TIME_FOREVER);
	return	Plugin_Handled;
}

int findBot(L4DTeam team) {
	int deadBot = 0;
	for(int client = 1; client < MaxClients; client++) {
		if(!IsValidClient(client, false) || L4D_GetClientTeam(client) != team)
			continue;
		if(IsPlayerAlive(client))
			return	client;
		else
			deadBot = client;
    }
	return	deadBot;
}

int menu_Team(Menu menu, MenuAction action, int client, int selection) {
    switch(action)	{
        case	MenuAction_Select: {
			char info[32];
			if(menu.GetItem(selection, info, sizeof(info))) {
				L4DTeam team = view_as<L4DTeam>(StringToInt(info));
				int bot;
				switch(team) {
					case	L4DTeam_Survivor: {
						bot = findBot(L4DTeam_Survivor);
						if(bot == 0)
							PrintToChat(client, "This team is full.");
						else	{
							SDKCall(hSetHumanSpec, bot, client);
							SDKCall(hTakeOverBot, client, true);
						}
                    }
                    case	L4DTeam_Infected:	L4D_ChangeClientTeam(client, L4DTeam_Infected);
				}
			}
		}
		case	MenuAction_End: delete menu;
	}
}

Action cmd_Idle(int client, int args)	{
	L4D_ChangeClientTeam(client, L4DTeam_Spectator);
	return	Plugin_Handled;
}

Action timer_Check(Handle timer) {
	float currentPos[3];
	float currentAngles[3];
	
	L4DTeam team;
	bool isAFK = false;
	AdminId id = INVALID_ADMIN_ID;
	int client, index;
	
	for(client = 1; client <= MaxClients; client++) {
		if(IsValidClient(client, false)) {
			team = L4D_GetClientTeam(client);
			if(team == L4DTeam_Spectator) {
				id = GetUserAdmin(client);
				if(id != INVALID_ADMIN_ID && GetAdminFlag(id, immuneFlag))	{
					if(GetClientTime(client) - lastMessage[client] >= joinTeamInterval)	{
						PrintToChat(client, "[AFK Manager] Say !team to choose a team.");
						lastMessage[client] = GetClientTime(client);
					}
					continue;
				}

				specTime[client] += checkInterval;
				if(specTime[client] >= maxAfkKickTime) {
					KickClient(client, "You were AFK for too long");
					if(messageLevel >= 2)
						PrintToChatAll("[AFK Manager] Player '%N' was kicked.", client);
                }
				else	{
					if(GetClientTime(client) - lastMessage[client] >= timeLeftInterval)	{
						PrintToChat(client, "[AFK Manager] You can spectate for %d more seconds before you will be kicked.", RoundToFloor(maxAfkKickTime - specTime[client]));
						lastMessage[client] = GetClientTime(client);
					}
					if(GetClientTime(client) - lastMessage[client] >= joinTeamInterval)	{
						PrintToChat(client, "[AFK Manager] Say !team to choose a team.");
						lastMessage[client] = GetClientTime(client);
					}
				}
			}
			else if(IsPlayerAlive(client) && (team == L4DTeam_Survivor || team == L4DTeam_Infected))	{
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
						L4D_ChangeClientTeam(client, L4DTeam_Spectator);
						if(messageLevel == 1 || messageLevel == 3)
							PrintToChatAll("[AFK Manager] Player '%N' was moved to Spectator team.", client);
					}
				}
				else
					afkTime[client] = 0.0;

				for(index = 0; index < 3; index++) {
					clientPos[client][index] = currentPos[index];
					clientAngles[client][index] = currentAngles[index];
				}
			}
		}
	}
	return	Plugin_Continue;
}

void convar_AfkSpecTime(ConVar convar, const char[] oldValue, const char[] newValue)	{
	maxAfkSpecTime = StringToFloat(newValue);
	if(maxAfkSpecTime == 0.0 || maxAfkSpecTime <= 10.0)	{
		convar.SetFloat(10.0);
		return;
	}
}

void convar_AfkKickTime(ConVar convar, const char[] oldValue, const char[] newValue)	{
	maxAfkKickTime = StringToFloat(newValue);
	if(maxAfkKickTime == 0.0 || maxAfkKickTime <= 10.0)	{
		convar.SetFloat(10.0);
		return;
	}
}

Action event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)	{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	L4DTeam team = view_as<L4DTeam>(event.GetInt("team"));
	
	switch(team)	{
		case	L4DTeam_Spectator:	specTime[client] = 0.0;
		case	L4DTeam_Survivor, L4DTeam_Infected:	afkTime[client] = 0.0;
	}
	
	if(event.GetBool("disconnected")) {
		clientPos[client] = view_as<float>({ 0.0, 0.0, 0.0 });
		clientAngles[client] = view_as<float>({ 0.0, 0.0, 0.0 });
	}
}

void convar_AdvertiseTime(ConVar convar, const char[] oldValue, const char[] newValue)	{
	if(advertiseTimer != INVALID_HANDLE) {
		delete advertiseTimer;
		advertiseTimer = INVALID_HANDLE;
	}
	advertiseInterval = StringToFloat(newValue);
	if(advertiseInterval <= 10.0)	{
		convar.SetFloat(10.0);
		return;
	}
	if(advertiseInterval > 0.0)
		advertiseTimer = CreateTimer(advertiseInterval, timer_Advertise, _, TIMER_REPEAT);
}

Action timer_Advertise(Handle timer)	{
	PrintToChatAll("[AFK Manager] %s", ads[adIndex++]);
	if(adIndex >= adCount)
		adIndex = 0;
	return	Plugin_Continue;
}

void convar_ImmuneFlag(ConVar convar, const char[] oldValue, const char[] newValue)	{
    if(strlen(newValue) != 1) {
        PrintToServer("[AFK Manager] Invalid flag value (%s).", newValue);
        convar.SetString(oldValue);
        return;
    }
    if(!FindFlagByChar(newValue[0], immuneFlag)) {
        PrintToServer("[AFK Manager] Invalid flag value (%s).", newValue);
        convar.SetString(oldValue);
        return;
    }
}  