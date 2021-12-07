#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zombiereloaded>
#include <leader>

#define PLUGIN_VERSION "2.9"
#pragma newdecls required

int leaderMVP, leaderScore, currentSprite = -1, spriteEntities[MAXPLAYERS+1], markerEntities[MAXPLAYERS+1], leaderClient = -1;
int voteCount[MAXPLAYERS+1], votedFor[MAXPLAYERS+1];

bool markerActive = false, beaconActive = false, allowVoting = false;

ConVar g_cVDefendVTF = null;
ConVar g_cVDefendVMT = null;
ConVar g_cVFollowVTF = null;
ConVar g_cVFollowVMT = null;

ConVar g_cVAllowVoting = null;

char DefendVMT[PLATFORM_MAX_PATH];
char DefendVTF[PLATFORM_MAX_PATH];
char FollowVMT[PLATFORM_MAX_PATH];
char FollowVTF[PLATFORM_MAX_PATH];
char leaderTag[64];

int g_BeamSprite = -1;
int g_HaloSprite = -1;
int greyColor[4] = {128, 128, 128, 255};
int g_BeaconSerial[MAXPLAYERS+1] = { 0, ... };
int g_Serial_Gen = 0;

public Plugin myinfo = {
	name = "Leader",
	author = "AntiTeal",
	description = "Allows for a human to be a leader, and give them special functions with it.",
	version = PLUGIN_VERSION,
	url = "https://antiteal.com"
};

public void OnPluginStart()
{
	CreateConVar("sm_leader_version", PLUGIN_VERSION, "Leader Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");

	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	AddCommandListener(HookPlayerChat, "say");

	RegConsoleCmd("sm_leader", Leader);
	RegConsoleCmd("sm_currentleader", CurrentLeader);
	RegConsoleCmd("sm_voteleader", VoteLeader);
	RegAdminCmd("sm_removeleader", RemoveTheLeader, ADMFLAG_GENERIC);

	g_cVDefendVMT = CreateConVar("sm_leader_defend_vmt", "materials/sg/sgdefend.vmt", "The defend here .vmt file");
	g_cVDefendVTF = CreateConVar("sm_leader_defend_vtf", "materials/sg/sgdefend.vtf", "The defend here .vtf file");
	g_cVFollowVMT = CreateConVar("sm_leader_follow_vmt", "materials/sg/sgfollow.vmt", "The follow me .vmt file");
	g_cVFollowVTF = CreateConVar("sm_leader_follow_vtf", "materials/sg/sgfollow.vtf", "The follow me .vtf file");
	g_cVAllowVoting = CreateConVar("sm_leader_allow_votes", "1", "Determines whether players can vote for leaders.");

	g_cVDefendVMT.AddChangeHook(ConVarChange);
	g_cVDefendVTF.AddChangeHook(ConVarChange);
	g_cVFollowVMT.AddChangeHook(ConVarChange);
	g_cVFollowVTF.AddChangeHook(ConVarChange);
	g_cVAllowVoting.AddChangeHook(ConVarChange);

	AutoExecConfig(true, "leader");

	g_cVDefendVTF.GetString(DefendVTF, sizeof(DefendVTF));
	g_cVDefendVMT.GetString(DefendVMT, sizeof(DefendVMT));
	g_cVFollowVTF.GetString(FollowVTF, sizeof(FollowVTF));
	g_cVFollowVMT.GetString(FollowVMT, sizeof(FollowVMT));

	AddFileToDownloadsTable(DefendVTF);
	AddFileToDownloadsTable(DefendVMT);
	AddFileToDownloadsTable(FollowVTF);
	AddFileToDownloadsTable(FollowVMT);

	PrecacheGeneric(DefendVTF, true);
	PrecacheGeneric(DefendVMT, true);
	PrecacheGeneric(FollowVTF, true);
	PrecacheGeneric(FollowVMT, true);

	allowVoting = g_cVAllowVoting.BoolValue;

	RegPluginLibrary("leader");

	AddCommandListener(Radio, "compliment");
	AddCommandListener(Radio, "coverme");
	AddCommandListener(Radio, "cheer");
	AddCommandListener(Radio, "takepoint");
	AddCommandListener(Radio, "holdpos");
	AddCommandListener(Radio, "regroup");
	AddCommandListener(Radio, "followme");
	AddCommandListener(Radio, "takingfire");
	AddCommandListener(Radio, "thanks");
	AddCommandListener(Radio, "go");
	AddCommandListener(Radio, "fallback");
	AddCommandListener(Radio, "sticktog");
	AddCommandListener(Radio, "getinpos");
	AddCommandListener(Radio, "stormfront");
	AddCommandListener(Radio, "report");
	AddCommandListener(Radio, "roger");
	AddCommandListener(Radio, "enemyspot");
	AddCommandListener(Radio, "needbackup");
	AddCommandListener(Radio, "sectorclear");
	AddCommandListener(Radio, "inposition");
	AddCommandListener(Radio, "reportingin");
	AddCommandListener(Radio, "getout");
	AddCommandListener(Radio, "negative");
	AddCommandListener(Radio, "enemydown");
}

public void ConVarChange(ConVar CVar, const char[] oldVal, const char[] newVal)
{
	g_cVDefendVTF.GetString(DefendVTF, sizeof(DefendVTF));
	g_cVDefendVMT.GetString(DefendVMT, sizeof(DefendVMT));
	g_cVFollowVTF.GetString(FollowVTF, sizeof(FollowVTF));
	g_cVFollowVMT.GetString(FollowVMT, sizeof(FollowVMT));

	AddFileToDownloadsTable(DefendVTF);
	AddFileToDownloadsTable(DefendVMT);
	AddFileToDownloadsTable(FollowVTF);
	AddFileToDownloadsTable(FollowVMT);

	PrecacheGeneric(DefendVTF, true);
	PrecacheGeneric(DefendVMT, true);
	PrecacheGeneric(FollowVTF, true);
	PrecacheGeneric(FollowVMT, true);

	allowVoting = g_cVAllowVoting.BoolValue;
}

public void OnMapStart()
{
	AddFileToDownloadsTable(DefendVTF);
	AddFileToDownloadsTable(DefendVMT);
	AddFileToDownloadsTable(FollowVTF);
	AddFileToDownloadsTable(FollowVMT);

	PrecacheGeneric(DefendVTF, true);
	PrecacheGeneric(DefendVMT, true);
	PrecacheGeneric(FollowVTF, true);
	PrecacheGeneric(FollowVMT, true);

	Handle gameConfig = LoadGameConfigFile("funcommands.games");
	if (gameConfig == null)
	{
		SetFailState("Unable to load game config funcommands.games");
		return;
	}

	char buffer[PLATFORM_MAX_PATH];
	if (GameConfGetKeyValue(gameConfig, "SpriteBeam", buffer, sizeof(buffer)) && buffer[0])
	{
		g_BeamSprite = PrecacheModel(buffer);
	}
	if (GameConfGetKeyValue(gameConfig, "SpriteHalo", buffer, sizeof(buffer)) && buffer[0])
	{
		g_HaloSprite = PrecacheModel(buffer);
	}
}

public void CreateBeacon(int client)
{
	g_BeaconSerial[client] = ++g_Serial_Gen;
	CreateTimer(1.0, Timer_Beacon, client | (g_Serial_Gen << 7), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void KillBeacon(int client)
{
	g_BeaconSerial[client] = 0;

	if (IsClientInGame(client))
	{
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

public void KillAllBeacons()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		KillBeacon(i);
	}
}

public void PerformBeacon(int client)
{
	if (g_BeaconSerial[client] == 0)
	{
		CreateBeacon(client);
		LogAction(client, client, "\"%L\" set a beacon on himself", client);
	}
	else
	{
		KillBeacon(client);
		LogAction(client, client, "\"%L\" removed a beacon on himself", client);
	}
}

public Action Timer_Beacon(Handle timer, any value)
{
	int client = value & 0x7f;
	int serial = value >> 7;

	if (!IsClientInGame(client) || !IsPlayerAlive(client) || g_BeaconSerial[client] != serial)
	{
		KillBeacon(client);
		return Plugin_Stop;
	}

	float vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;

	TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
	TE_SendToAll();

	int rainbowColor[4];
	float i = GetGameTime();
	float Frequency = 2.5;
	rainbowColor[0] = RoundFloat(Sine(Frequency * i + 0.0) * 127.0 + 128.0);
	rainbowColor[1] = RoundFloat(Sine(Frequency * i + 2.0943951) * 127.0 + 128.0);
	rainbowColor[2] = RoundFloat(Sine(Frequency * i + 4.1887902) * 127.0 + 128.0);
	rainbowColor[3] = 255;

	TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, rainbowColor, 10, 0);

	TE_SendToAll();

	GetClientEyePosition(client, vec);

	return Plugin_Continue;
}

public int AttachSprite(int client, char[] sprite) //https://forums.alliedmods.net/showpost.php?p=1880207&postcount=5
{
	if(!IsPlayerAlive(client))
	{
		return -1;
	}

	char iTarget[16], sTargetname[64];
	GetEntPropString(client, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));

	Format(iTarget, sizeof(iTarget), "Client%d", client);
	DispatchKeyValue(client, "targetname", iTarget);

	float Origin[3];
	GetClientEyePosition(client, Origin);
	Origin[2] += 45.0;

	int Ent = CreateEntityByName("env_sprite");
	if(!Ent) return -1;

	DispatchKeyValue(Ent, "model", sprite);
	DispatchKeyValue(Ent, "classname", "env_sprite");
	DispatchKeyValue(Ent, "spawnflags", "1");
	DispatchKeyValue(Ent, "scale", "0.1");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, Origin, NULL_VECTOR, NULL_VECTOR);
	SetVariantString(iTarget);
	AcceptEntityInput(Ent, "SetParent", Ent, Ent, 0);

	DispatchKeyValue(client, "targetname", sTargetname);

	return Ent;
}

public void RemoveSprite(int client)
{
	if (spriteEntities[client] != -1 && IsValidEdict(spriteEntities[client]))
	{
		char m_szClassname[64];
		GetEdictClassname(spriteEntities[client], m_szClassname, sizeof(m_szClassname));
		if(strcmp("env_sprite", m_szClassname)==0)
		AcceptEntityInput(spriteEntities[client], "Kill");
	}
	spriteEntities[client] = -1;
}

public void RemoveMarker(int client)
{
	if (markerEntities[client] != -1 && IsValidEdict(markerEntities[client]))
	{
		char m_szClassname[64];
		GetEdictClassname(markerEntities[client], m_szClassname, sizeof(m_szClassname));
		if(strcmp("env_sprite", m_szClassname)==0)
		AcceptEntityInput(markerEntities[client], "Kill");
	}
	markerEntities[client] = -1;
}

public void SetLeader(int client)
{
	if(IsValidClient(leaderClient))
	{
		RemoveLeader(leaderClient);
		PrintToChatAll("[SM] The current leader has been removed!");
	}

	if(IsValidClient(client))
	{
		leaderClient = client;

		CS_GetClientClanTag(client, leaderTag, sizeof(leaderTag));
		//CS_SetClientClanTag(client, "[Leader]");

		leaderMVP = CS_GetMVPCount(client);
		CS_SetMVPCount(client, 99);

		leaderScore = CS_GetClientContributionScore(client);
		CS_SetClientContributionScore(client, 9999);

		currentSprite = -1;
	}
}

public void RemoveLeader(int client)
{
	//CS_SetClientClanTag(client, leaderTag);
	CS_SetMVPCount(client, leaderMVP);
	CS_SetClientContributionScore(client, leaderScore);

	RemoveSprite(client);
	RemoveMarker(client);

	if(beaconActive)
	{
		KillBeacon(client);
	}

	currentSprite = -1;
	leaderClient = -1;
	markerActive = false;
	beaconActive = false;
}

public int SpawnMarker(int client, char[] sprite)
{
	if(!IsPlayerAlive(client))
	{
		return -1;
	}

	float Origin[3];
	GetClientEyePosition(client, Origin);
	Origin[2] += 25.0;

	int Ent = CreateEntityByName("env_sprite");
	if(!Ent) return -1;

	DispatchKeyValue(Ent, "model", sprite);
	DispatchKeyValue(Ent, "classname", "env_sprite");
	DispatchKeyValue(Ent, "spawnflags", "1");
	DispatchKeyValue(Ent, "scale", "0.1");
	DispatchKeyValue(Ent, "rendermode", "1");
	DispatchKeyValue(Ent, "rendercolor", "255 255 255");
	DispatchSpawn(Ent);
	TeleportEntity(Ent, Origin, NULL_VECTOR, NULL_VECTOR);

	return Ent;
}

public Action CurrentLeader(int client, int args)
{
	if(IsValidClient(leaderClient))
	{
		PrintToChat(client, "[SM] The current leader is %N!", leaderClient);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, "[SM] There is no current leader!");
		return Plugin_Handled;
	}
}

public Action RemoveTheLeader(int client, int args)
{
	if(IsValidClient(leaderClient))
	{
		PrintToChatAll("[SM] The current leader has been removed!");
		RemoveLeader(leaderClient);
		return Plugin_Handled;
	}
	else
	{
		PrintToChat(client, "[SM] There is no current leader!");
		return Plugin_Handled;
	}
}

public Action Leader(int client, int args)
{
	if(CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC, false))
	{
		if(args == 1)
		{
			char arg1[65];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1, false, false);
			if (target == -1)
			{
				return Plugin_Handled;
			}

			if(target == leaderClient)
			{
				LeaderMenu(target);
			}
			else
			{
				if(IsPlayerAlive(target))
				{
					SetLeader(target);
					PrintToChatAll("[SM] %N is the new leader!", target);
					PrintToChat(target, "[SM] You are now the leader! Type !leader to open up the leader menu.");
					LeaderMenu(target);
				}
				else
				{
					ReplyToCommand(client, "[SM] The target has to be alive!");
				}
			}
		}
		else if(args == 0)
		{
			if(client == leaderClient)
			{
				LeaderMenu(client);
				return Plugin_Handled;
			}
			if(IsPlayerAlive(client))
			{
				SetLeader(client);
				PrintToChatAll("[SM] %N is the new leader!", client);
				PrintToChat(client, "[SM] You are now the leader! Type !leader to open up the leader menu.");
				LeaderMenu(client);
			}
			else
			{
				ReplyToCommand(client, "[SM] The target has to be alive!");
			}
		}
		else
		{
			ReplyToCommand(client, "[SM] Usage: sm_leader <optional: client|#userid>");
		}
	}
	if(client == leaderClient)
	{
		LeaderMenu(client);
	}
	return Plugin_Handled;
}

public void LeaderMenu(int client)
{
	Handle menu = CreateMenu(LeaderMenu_Handler);

	char sprite[64], marker[64], beacon[64];

	switch (currentSprite)
	{
		case 0:
		sprite = "Defend";
		case 1:
		sprite = "Follow";
		default:
		sprite = "None";
	}

	if(markerActive)
	marker = "Yes";
	else
	marker = "No";

	if(beaconActive)
	beacon = "Yes";
	else
	beacon = "No";

	SetMenuTitle(menu, "Leader Menu\nSprite: %s\nMarker: %s\nBeacon: %s", sprite, marker, beacon);
	AddMenuItem(menu, "resign", "Resign from Leader");
	AddMenuItem(menu, "sprite", "Sprite Menu");
	AddMenuItem(menu, "marker", "Marker Menu");
	AddMenuItem(menu, "beacon", "Toggle Beacon");

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int LeaderMenu_Handler(Handle menu, MenuAction action, int client, int position)
{
	if(leaderClient == client && IsValidClient(client))
	{
		if(action == MenuAction_Select)
		{
			char info[32];
			GetMenuItem(menu, position, info, sizeof(info));

			if(StrEqual(info, "resign"))
			{
				RemoveLeader(client);
				PrintToChatAll("[SM] %N has resigned from being leader!", client);
			}
			if(StrEqual(info, "sprite"))
			{
				SpriteMenu(client);
			}
			if(StrEqual(info, "marker"))
			{
				MarkerMenu(client);
			}
			if(StrEqual(info, "beacon"))
			{
				ToggleBeacon(client);
				LeaderMenu(client);
			}
		}
		else if(action == MenuAction_End)
		{
			CloseHandle(menu);
		}
	}

}

public void ToggleBeacon(int client)
{
	if(beaconActive)
	beaconActive = false;
	else
	beaconActive = true;

	PerformBeacon(client);
}

public void SpriteMenu(int client)
{
	Handle menu = CreateMenu(SpriteMenu_Handler);

	char sprite[64], marker[64], beacon[64];

	switch (currentSprite)
	{
		case 0:
		sprite = "Defend";
		case 1:
		sprite = "Follow";
		default:
		sprite = "None";
	}

	if(markerActive)
	marker = "Yes";
	else
	marker = "No";

	if(beaconActive)
	beacon = "Yes";
	else
	beacon = "No";

	SetMenuTitle(menu, "Leader Menu\nSprite: %s\nMarker: %s\nBeacon: %s", sprite, marker, beacon);
	AddMenuItem(menu, "none", "No Sprite");
	AddMenuItem(menu, "defend", "Defend Here");
	AddMenuItem(menu, "follow", "Follow Me");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int SpriteMenu_Handler(Handle menu, MenuAction action, int client, int position)
{
	if(leaderClient == client && IsValidClient(client))
	{
		if(action == MenuAction_Select)
		{
			char info[32];
			GetMenuItem(menu, position, info, sizeof(info));

			if(StrEqual(info, "none"))
			{
				RemoveSprite(client);
				PrintToChat(client, "[SM] Sprite removed.");
				currentSprite = -1;
				LeaderMenu(client);
			}
			if(StrEqual(info, "defend"))
			{
				RemoveSprite(client);
				spriteEntities[client] = AttachSprite(client, DefendVMT);
				PrintToChat(client, "[SM] Sprite changed to 'Defend Here'.");
				currentSprite = 0;
				LeaderMenu(client);
			}
			if(StrEqual(info, "follow"))
			{
				RemoveSprite(client);
				spriteEntities[client] = AttachSprite(client, FollowVMT);
				PrintToChat(client, "[SM] Sprite changed to 'Follow Me'.");
				currentSprite = 1;
				LeaderMenu(client);
			}
		}
		else if(action == MenuAction_End)
		{
			CloseHandle(menu);
		}
		else if (action == MenuAction_Cancel && position == MenuCancel_ExitBack)
		{
			LeaderMenu(client);
		}
	}
}

public void MarkerMenu(int client)
{
	Handle menu = CreateMenu(MarkerMenu_Handler);

	char sprite[64], marker[64], beacon[64];

	switch (currentSprite)
	{
		case 0:
		sprite = "Defend";
		case 1:
		sprite = "Follow";
		default:
		sprite = "None";
	}

	if(markerActive)
	marker = "Yes";
	else
	marker = "No";

	if(beaconActive)
	beacon = "Yes";
	else
	beacon = "No";

	SetMenuTitle(menu, "Leader Menu\nSprite: %s\nMarker: %s\nBeacon: %s", sprite, marker, beacon);
	AddMenuItem(menu, "removemarker", "Remove Marker");
	AddMenuItem(menu, "defendmarker", "Defend Marker");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int MarkerMenu_Handler(Handle menu, MenuAction action, int client, int position)
{
	if(leaderClient == client && IsValidClient(client))
	{
		if(action == MenuAction_Select)
		{
			char info[32];
			GetMenuItem(menu, position, info, sizeof(info));

			if(StrEqual(info, "removemarker"))
			{
				RemoveMarker(client);
				PrintToChat(client, "[SM] Marker removed.");
				markerActive = false;
				LeaderMenu(client);
			}
			if(StrEqual(info, "defendmarker"))
			{
				RemoveMarker(client);
				markerEntities[client] = SpawnMarker(client, DefendVMT);
				PrintToChat(client, "[SM] 'Defend Here' marker placed.");
				markerActive = true;
				LeaderMenu(client);
			}
		}
		else if(action == MenuAction_End)
		{
			CloseHandle(menu);
		}
		else if (action == MenuAction_Cancel && position == MenuCancel_ExitBack)
		{
			LeaderMenu(client);
		}
	}
}
public void OnClientDisconnect(int client)
{
	if(client == leaderClient)
	{
		PrintToChatAll("[SM] The leader has disconnected!");
		RemoveLeader(client);
	}
	voteCount[client] = 0;
}

public Action Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(client == leaderClient)
	{
		PrintToChatAll("[SM] The leader has died!");
		RemoveLeader(client);
	}
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(client == leaderClient)
	{
		PrintToChatAll("[SM] The leader has been infected!");
		RemoveLeader(client);
	}
}

public void OnMapEnd()
{
	if(IsValidClient(leaderClient))
	{
		RemoveLeader(leaderClient);
	}
	leaderClient = -1;
	KillAllBeacons();
}

bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

public Action Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	if(IsValidClient(leaderClient))
	{
		RemoveLeader(leaderClient);
	}

	KillAllBeacons();
}

public Action HookPlayerChat(int client, char[] command, int args)
{
	if(IsValidClient(client) && leaderClient == client)
	{
		char LeaderText[256];
		GetCmdArgString(LeaderText, sizeof(LeaderText));
		StripQuotes(LeaderText);
		if(LeaderText[0] == '/' || LeaderText[0] == '@' || strlen(LeaderText) == 0 || IsChatTrigger())
		{
			return Plugin_Handled;
		}
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			PrintToChatAll("\x01[Leader] \x0C%N:\x02 %s", client, LeaderText);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Leader_CurrentLeader", Native_CurrentLeader);
	CreateNative("Leader_SetLeader", Native_SetLeader);
	return APLRes_Success;
}

public int Native_CurrentLeader(Handle plugin, int numParams)
{
	return leaderClient;
}

public int Native_SetLeader(Handle plugin, int numParams)
{
	SetLeader(GetNativeCell(1));
}

public Action Radio(int client, const char[] command, int argc)
{
	if(client == leaderClient)
	{
		if(StrEqual(command, "compliment")) PrintRadio(client, "Nice!");
		if(StrEqual(command, "coverme")) PrintRadio(client, "Cover Me!");
		if(StrEqual(command, "cheer")) PrintRadio(client, "Cheer!");
		if(StrEqual(command, "takepoint")) PrintRadio(client, "You take the point.");
		if(StrEqual(command, "holdpos")) PrintRadio(client, "Hold This Position.");
		if(StrEqual(command, "regroup")) PrintRadio(client, "Regroup Team.");
		if(StrEqual(command, "followme")) PrintRadio(client, "Follow me.");
		if(StrEqual(command, "takingfire")) PrintRadio(client, "Taking fire... need assistance!");
		if(StrEqual(command, "thanks"))  PrintRadio(client, "Thanks!");
		if(StrEqual(command, "go"))  PrintRadio(client, "Go go go!");
		if(StrEqual(command, "fallback"))  PrintRadio(client, "Team, fall back!");
		if(StrEqual(command, "sticktog"))  PrintRadio(client, "Stick together, team.");
		if(StrEqual(command, "report"))  PrintRadio(client, "Report in, team.");
		if(StrEqual(command, "roger"))  PrintRadio(client, "Roger that.");
		if(StrEqual(command, "enemyspot"))  PrintRadio(client, "Enemy spotted.");
		if(StrEqual(command, "needbackup"))  PrintRadio(client, "Need backup.");
		if(StrEqual(command, "sectorclear"))  PrintRadio(client, "Sector clear.");
		if(StrEqual(command, "inposition"))  PrintRadio(client, "I'm in position.");
		if(StrEqual(command, "reportingin"))  PrintRadio(client, "Reporting In.");
		if(StrEqual(command, "getout"))  PrintRadio(client, "Get out of there, it's gonna blow!.");
		if(StrEqual(command, "negative"))  PrintRadio(client, "Negative.");
		if(StrEqual(command, "enemydown"))  PrintRadio(client, "Enemy down.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public void PrintRadio(int client, char[] text)
{
	char szClantag[32], szMessage[64];
	CS_GetClientClanTag(client, szClantag, sizeof(szClantag));

	Format(szMessage, sizeof(szMessage), "\x01 \x02%s %N (RADIO): %s", szClantag, client, text);
	PrintToChatAll(szMessage);
}

public Action VoteLeader(int client, int argc)
{
	if(!allowVoting)
	{
		ReplyToCommand(client, "[SM] Voting for leader is disabled.");
		return Plugin_Handled;
	}
	if(IsValidClient(leaderClient))
	{
		ReplyToCommand(client, "[SM] There is already a leader!");
		return Plugin_Handled;
	}
	if(argc < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_voteleader <player>");
		return Plugin_Handled;
	}

	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	int target = FindTarget(client, arg, false, false);
	if (target == -1)
	{
		return Plugin_Handled;
	}

	if(GetClientFromSerial(votedFor[client]) == target)
	{
		ReplyToCommand(client, "[SM] You've already voted for this person!");
		return Plugin_Handled;
	}

	if(ZR_IsClientZombie(target))
	{
		ReplyToCommand(client, "[SM] You have to vote for a human!");
		return Plugin_Handled;
	}

	if(GetClientFromSerial(votedFor[client]) != 0)
	{
		if(IsValidClient(GetClientFromSerial(votedFor[client]))) {
			voteCount[GetClientFromSerial(votedFor[client])]--;
		}
	}
	voteCount[target]++;
	votedFor[client] = GetClientSerial(target);
	PrintToChatAll("[SM] %N has voted for %N to be the leader (%i/%i votes)", client, target, voteCount[target], GetClientCount(true)/10);

	if(voteCount[target] >= GetClientCount(true)/10)
	{
		SetLeader(target);
		PrintToChatAll("[SM] %N has been voted to be the new leader!", target);
		LeaderMenu(target);
	}

	return Plugin_Handled;
}
