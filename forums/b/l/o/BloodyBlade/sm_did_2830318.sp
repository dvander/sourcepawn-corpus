#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define Version "1.3.5b"
#define DEBUGMODE 0
#define BaseDisplayMode 2
#define BaseDisplayOnDeathMode 2

ConVar Allowed;
ConVar cvarAnnounce;
ConVar DefaultMode;
ConVar DefaultOnDeathMode;
ConVar SurvivorBlockMode;
ConVar CurrentGameMode;
KeyValues kvDIDUS; //handle for user settings

int DisplayMode[MAXPLAYERS + 1] = {BaseDisplayMode, ...};
int DisplayOnDeathMode[MAXPLAYERS + 1] = {BaseDisplayOnDeathMode, ...};
int Damage[MAXPLAYERS+1][MAXPLAYERS + 1];
int CurrentDamage[MAXPLAYERS + 1][MAXPLAYERS + 1];
int TotalDamageDone[MAXPLAYERS + 1] = {0, ...};
int TotalDamageReceived[MAXPLAYERS + 1] = {0, ...};
int TotalDamageDoneTA[MAXPLAYERS + 1] = {0, ...};
int TotalDamageReceivedTA[MAXPLAYERS + 1] = {0, ...};
int TotalDamageReceivedInfected[MAXPLAYERS + 1] = {0, ...};
int CurTotalDamageDone[MAXPLAYERS + 1] = {0, ...};
int CurTotalDamageReceived[MAXPLAYERS + 1] = {0, ...};
int CurTotalDamageDoneTA[MAXPLAYERS + 1] = {0, ...};
int CurTotalDamageReceivedTA[MAXPLAYERS + 1] = {0, ...};
int CurTotalDamageReceivedInfected[MAXPLAYERS + 1] = {0, ...};
int InfectedKills[MAXPLAYERS + 1]  = {0, ...};
int CurInfectedKills[MAXPLAYERS + 1]  = {0, ...};
int PlayerKills[MAXPLAYERS + 1] = {0, ...};
int CurPlayerKills[MAXPLAYERS + 1]  = {0, ...};
int FirstHurt[MAXPLAYERS + 1][MAXPLAYERS + 1]; // Fix incorrect calculation CurrentDamage at round change
int PlayerReachedSafeRoom[MAXPLAYERS + 1] = {0, ...};

bool ReachedSafeRoom = false;	// (Coop) Start counting number of survivors in saferoom
bool HasRoundEnded = false;		// Prevent duplicate RoundEnd events
bool lateLoaded = false;		// Check plugin was late loaded
bool bHooked = false;

int iDefaultMode = 0;
int iDefaultOnDeathMode = 0;
bool bSurvivorBlockMode = false;
bool bCvarAnnounce = false;

char fileDIDUS[128]; //file for user settings

public Plugin myinfo = 
{
	name = "Damage Info Display",
	author = "Dionys && -pk- && sheleu",
	description = "Display the damage info.",
	version = Version,
	url = "skiner@inbox.ru"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	if(test == Engine_Left4Dead || test == Engine_Left4Dead2)
	{
		lateLoaded = true;
	}
	else
	{
		lateLoaded = false;
		strcopy(error, err_max, "Plugin only supports Left 4 Dead(2) game.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_did_version", Version, "Version of Display Damage plugin.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Allowed = CreateConVar("sm_did_enabled","1","Enables Display Damage to players.", FCVAR_NOTIFY);
	CurrentGameMode = FindConVar("mp_gamemode");
	DefaultMode = CreateConVar("sm_did_defhint","2","Default Display Damage mode. 1 = all; 2 = damage done; 3 = damage received; any other = no display.", FCVAR_NOTIFY);
	DefaultOnDeathMode = CreateConVar("sm_did_deftotal","2","Default Display Damage on Death mode. 1 = Display Total Damage; 2 = Display Damage Since Last Spawn; any other = no display.", FCVAR_NOTIFY);
	SurvivorBlockMode = CreateConVar("sm_did_survivor_block","0","Block HintInfo about infected damages for survivor. 0 = off; 1 = on.", FCVAR_NOTIFY);
	cvarAnnounce = CreateConVar("sm_did_announce","1","Enables Display Damage to advertise to players.", FCVAR_NOTIFY);

	Allowed.AddChangeHook(OnConVarPluginOnChange);
	CurrentGameMode.AddChangeHook(OnCVGameModeChange);
	DefaultMode.AddChangeHook(OnConVarsChange);
	DefaultOnDeathMode.AddChangeHook(OnConVarsChange);
	SurvivorBlockMode.AddChangeHook(OnConVarsChange);
	cvarAnnounce.AddChangeHook(OnConVarsChange);

	LoadTranslations("plugin.sm_did");
	AutoExecConfig(true, "sm_did");

	RegConsoleCmd("sm_did_hmode", DIDMenu);
	RegConsoleCmd("sm_did_tmode", DIDOnDeathMenu);
	RegConsoleCmd("sm_did", CallDIDTotalMenu, "Call DID Total Panel");
	RegConsoleCmd("sm_did_clear", cmdClearDID, "Clear all Damages");

	// initialize client settings
	kvDIDUS = new KeyValues("didUserSettings");
	BuildPath(Path_SM, fileDIDUS, 128, "data/sm_did_settings.txt");
	if (!FileToKeyValues(kvDIDUS, fileDIDUS))
		KeyValuesToFile(kvDIDUS, fileDIDUS);

	// if the plugin was loaded late we have a bunch of initialization that needs to be done
	if (lateLoaded)
	{
		// First need to do whatever we would have done at OnMapStart()
		SaveUserSettings();
		// Next need to whatever we would have done as each client authorized
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				PrepareClient(i);
			}
		}
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, char[] OldValue, char[] NewValue)
{
	IsAllowed();
}

void OnConVarsChange(ConVar cvar, char[] OldValue, char[] NewValue)
{
	GetCvars();
}

void IsAllowed()
{
	bool bPluginOn = Allowed.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		GetCvars();
		SaveUserSettings();
		HookEvent("player_hurt", Event_PlayerHurt);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("infected_death", Event_InfectedDeath);
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("finale_vehicle_ready", Event_RoundEnd_Finale, EventHookMode_PostNoCopy);

		if (l4d_gamemode() == 2)
		{
			HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		}
		else if (l4d_gamemode() == 1)
		{
			HookEvent("mission_lost", Event_MissionLost, EventHookMode_PostNoCopy);
			HookEvent("map_transition", Event_Maptransition, EventHookMode_PostNoCopy);
			HookEvent("player_entered_checkpoint", Event_PlayerEnterRescueZone);
			HookEvent("player_left_checkpoint", Event_PlayerLeavesRescueZone);
		}
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("player_hurt", Event_PlayerHurt);
		UnhookEvent("player_death", Event_PlayerDeath);
		UnhookEvent("infected_death", Event_InfectedDeath);
		UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("finale_vehicle_ready", Event_RoundEnd_Finale, EventHookMode_PostNoCopy);

		if (l4d_gamemode() == 2)
		{
			UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		}
		else if (l4d_gamemode() == 1)
		{
			UnhookEvent("mission_lost", Event_MissionLost, EventHookMode_PostNoCopy);
			UnhookEvent("map_transition", Event_Maptransition, EventHookMode_PostNoCopy);
			UnhookEvent("player_entered_checkpoint", Event_PlayerEnterRescueZone);
			UnhookEvent("player_left_checkpoint", Event_PlayerLeavesRescueZone);
		}
	}
}

void GetCvars()
{
	iDefaultMode = DefaultMode.IntValue;
	iDefaultOnDeathMode = DefaultOnDeathMode.IntValue;
	bSurvivorBlockMode = SurvivorBlockMode.BoolValue;
	bCvarAnnounce = cvarAnnounce.BoolValue;
}

public void OnClientPutInServer(int client)
{
	if (client)
	{
		for (int Arg = 1; Arg <= MaxClients; Arg++)
		{
			FirstHurt[Arg][client] = 1;
			FirstHurt[client][Arg] = 1;
		}

		PrepareClient(client);

		TotalDamageDone[client] = 0;
		TotalDamageReceived[client] = 0;
		TotalDamageDoneTA[client] = 0;
		TotalDamageReceivedTA[client] = 0;
		TotalDamageReceivedInfected[client] = 0;
		InfectedKills[client] = 0;
		PlayerKills[client] = 0;
		CurTotalDamageDone[client] = 0;
		CurTotalDamageReceived[client] = 0;
		CurTotalDamageDoneTA[client] = 0;
		CurTotalDamageReceivedTA[client] = 0;
		CurTotalDamageReceivedInfected[client] = 0;
		CurInfectedKills[client] = 0;
		CurPlayerKills[client] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	char steamId[20];
	if (client && !IsFakeClient(client))
	{
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
		kvDIDUS.Rewind();
		if (KvJumpToKey(kvDIDUS, steamId))
		{
			char datestamp[60];
			FormatTime(datestamp, sizeof(datestamp), "%H:%M:%S / %d-%m-%Y", GetTime());
			kvDIDUS.SetString("last connect", datestamp);
		}
	}
}

int Handler_DeathPanel(Menu menu, MenuAction action, int param1, int param2)
{
	return 0;
}

// Mode switcher - DID Mode
int DIDMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	int ModeCheck = 0;
	if (param1 >= 0)
		ModeCheck = DisplayMode[param1];

	int selNum = param2 + 1;
	if (action == MenuAction_Select)
	{
		if (selNum == 4)
		{
			DisplayMode[param1] = 0;
		}
		else
		{
			DisplayMode[param1] = selNum;
		}

		char steamId[20];
		GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
		kvDIDUS.Rewind();
		kvDIDUS.JumpToKey(steamId);
		kvDIDUS.SetNum("hint preference", DisplayMode[param1]);

		if (ModeCheck == DisplayMode[param1])
		{
			PrintToChat(param1, "\x04[DID]\x03 %t", "menu stay mode");
		}
		else
		{
			switch (DisplayMode[param1])
			{
			  case 0:
				PrintToChat(param1, "\x04[DID]\x03 %t \x04%t\x03", "menu get mode", "menu disable mode");
			  case 1:
				PrintToChat(param1, "\x04[DID]\x03 %t \x04%t\x03", "menu get mode", "menu all mode");
			  case 2:
				PrintToChat(param1, "\x04[DID]\x03 %t \x04%t\x03", "menu get mode", "menu done mode");
			  case 3:
				PrintToChat(param1, "\x04[DID]\x03 %t \x04%t\x03", "menu get mode", "menu received mode");
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// nothing
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

//  This creates menu - DID mode
Action DIDMenu(int client, int args)
{
	Menu menu = new Menu(DIDMenuHandler);
	char mBuffer[100];
	
	Format(mBuffer, sizeof(mBuffer), "%t", "DID Menu", client);
	menu.SetTitle(mBuffer);

	if (DisplayMode[client] == 1)
		Format(mBuffer, sizeof(mBuffer), "%t [%t]", "menu all mode", "menu current use", client);
	else
		Format(mBuffer, sizeof(mBuffer), "%t", "menu all mode", client);
	menu.AddItem("mode_all", mBuffer);
	if (DisplayMode[client] == 2)
		Format(mBuffer, sizeof(mBuffer), "%t [%t]", "menu done mode", "menu current use", client);
	else
		Format(mBuffer, sizeof(mBuffer), "%t", "menu done mode", client);
	menu.AddItem("mode_done", mBuffer);
	if (DisplayMode[client] == 3)
		Format(mBuffer, sizeof(mBuffer), "%t [%t]", "menu received mode", "menu current use", client);
	else
		Format(mBuffer, sizeof(mBuffer), "%t", "menu received mode", client);
	menu.AddItem("mode_received", mBuffer);
	if (DisplayMode[client] == 0)
		Format(mBuffer, sizeof(mBuffer), "%t [%t]", "menu disable mode", "menu current use", client);
	else
		Format(mBuffer, sizeof(mBuffer), "%t", "menu disable mode", client);
	menu.AddItem("mode_off", mBuffer);
 
	menu.ExitButton = true;
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

// Mode switcher - Display on Death mode
int DIDOnDeathMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	int ModeCheck = 0;
	if (param1 >= 0)
		ModeCheck = DisplayOnDeathMode[param1];

	int selNum = param2 + 1;
	if (action == MenuAction_Select)
	{
		if (selNum == 3)
		{
			DisplayOnDeathMode[param1] = 0;
		}
		else
		{
			DisplayOnDeathMode[param1] = selNum;
		}

		char steamId[20];
		GetClientAuthId(param1, AuthId_Steam2, steamId, sizeof(steamId));
		kvDIDUS.Rewind();
		kvDIDUS.JumpToKey(steamId);
		kvDIDUS.SetNum("total preference", DisplayOnDeathMode[param1]);

		if (ModeCheck == DisplayOnDeathMode[param1])
		{
			PrintToChat(param1, "\x04[DID]\x03 %t", "menu stay mode");
		}
		else
		{
			switch (DisplayOnDeathMode[param1])
			{
			  case 0:
				PrintToChat(param1, "\x04[DID]\x03 %t \x04%t\x03", "menu get mode", "menu disable mode");
			  case 1:
				PrintToChat(param1, "\x04[DID]\x03 %t \x04%t\x03", "menu get mode", "menu PDeath total");
			  case 2:
				PrintToChat(param1, "\x04[DID]\x03 %t \x04%t\x03", "menu get mode", "menu PDeath current");
			}
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// nothing
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

//  This creates menu - Display on Death mode
Action DIDOnDeathMenu(int client, int args)
{
	Menu menu = new Menu(DIDOnDeathMenuHandler);
	char mBuffer[100];
	
	Format(mBuffer, sizeof(mBuffer), "%t", "DID PDeath Menu", client);
	menu.SetTitle(mBuffer);

	if (DisplayOnDeathMode[client] == 1)
		Format(mBuffer, sizeof(mBuffer), "%t [%t]", "menu PDeath total", "menu current use", client);
	else
		Format(mBuffer, sizeof(mBuffer), "%t", "menu PDeath total", client);
	menu.AddItem("mode_ptotal", mBuffer);
	if (DisplayOnDeathMode[client] == 2)
		Format(mBuffer, sizeof(mBuffer), "%t [%t]", "menu PDeath current", "menu current use", client);
	else
		Format(mBuffer, sizeof(mBuffer), "%t", "menu PDeath current", client);
	menu.AddItem("mode_pcurrent", mBuffer);
	if (DisplayOnDeathMode[client] == 0)
		Format(mBuffer, sizeof(mBuffer), "%t [%t]", "menu disable mode", "menu current use", client);
	else
		Format(mBuffer, sizeof(mBuffer), "%t", "menu disable mode", client);
	menu.AddItem("mode_disable", mBuffer);
 
	menu.ExitButton = true;
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

// Mode switcher - Select mode for call current total
int CallDIDTotalMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	int selNum = param2 + 1;
	if (action == MenuAction_Select)
	{
		if (selNum == 1)
		{
			DisplayTotal(param1);
		}
		if (selNum == 2)
		{
			DisplayCurrentTotal(param1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// nothing
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

//  This creates menu - Select mode for call current total
Action CallDIDTotalMenu(int client, int args)
{
	Menu menu = new Menu(CallDIDTotalMenuHandler);
	char mBuffer[100];

	Format(mBuffer, sizeof(mBuffer), "%t", "DID Current Total Menu", client);
	menu.SetTitle(mBuffer);

	Format(mBuffer, sizeof(mBuffer), "%t", "menu PDeath total", client);
	menu.AddItem("mode_tmode", mBuffer);
	Format(mBuffer, sizeof(mBuffer), "%t", "menu PDeath current", client);
	menu.AddItem("mode_cmode", mBuffer);
 
	menu.ExitButton = true;
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int DamageHealth = event.GetInt("dmg_health");

	//Total game event byte length must be < 1024
	if (DamageHealth < 1024)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));

		if (FirstHurt[attacker][victim] == 1)
		{
			Damage[attacker][victim] = 0;
			CurrentDamage[attacker][victim] = 0;
			FirstHurt[attacker][victim] = 0;
		}

		Damage[attacker][victim] += DamageHealth;
		CurrentDamage[attacker][victim] += DamageHealth;

		// Display info
		if (victim != 0 && attacker != 0)
		{
			if (victim == attacker)
			{
				PrintHintText(victim, "%t %iHP.", "Hint Noob Hurt", CurrentDamage[attacker][victim]);
			}
			else if (GetClientTeam(victim) == GetClientTeam(attacker))
			{
				TotalDamageReceivedTA[victim] += Damage[attacker][victim];
				TotalDamageDoneTA[attacker] += Damage[attacker][victim];
				CurTotalDamageReceivedTA[victim] += Damage[attacker][victim];
				CurTotalDamageDoneTA[attacker] += Damage[attacker][victim];

				if (DisplayMode[victim] == 1 || DisplayMode[victim] == 3)
					PrintHintText(victim, "友伤!!! %N %t %iHP.", attacker, "Hint EtoP Hurt", CurrentDamage[attacker][victim]);
				if (DisplayMode[attacker] == 1 || DisplayMode[attacker] == 2)
					PrintHintText(attacker, "停!!! %t %N: %iHP.", "Hint PtoE Hurt", victim, CurrentDamage[attacker][victim]);
			}
			else
			{
				TotalDamageReceived[victim] += Damage[attacker][victim];
				TotalDamageDone[attacker] += Damage[attacker][victim];
				CurTotalDamageReceived[victim] += Damage[attacker][victim];
				CurTotalDamageDone[attacker] += Damage[attacker][victim];

				if (DisplayMode[victim] == 1 || DisplayMode[victim] == 3)
					PrintHintText(victim, "%N %t %iHP.", attacker, "Hint EtoP Hurt", CurrentDamage[attacker][victim]);
				if ((DisplayMode[attacker] == 1 || DisplayMode[attacker] == 2) && (!bSurvivorBlockMode || (bSurvivorBlockMode && GetClientTeam(attacker) != 2)))
					PrintHintText(attacker, "%t %N: %iHP.", "Hint PtoE Hurt", victim, CurrentDamage[attacker][victim]);
			}
		}
		else
		{
			TotalDamageReceivedInfected[victim] += Damage[attacker][victim];
			CurTotalDamageReceivedInfected[victim] += Damage[attacker][victim];
		}

		Damage[attacker][victim] = 0;
	}
	return Plugin_Continue;
}

Action Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (attacker > 0 && !IsFakeClient(attacker))
	{
		InfectedKills[attacker] += 1;
		CurInfectedKills[attacker] += 1;
	}
	return Plugin_Continue;
}

Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	for (int Arg = 1; Arg <= MaxClients; Arg++)
	{
		CurrentDamage[Arg][victim] = 0;
		CurrentDamage[victim][Arg] = 0;
	}

	// Note: players can die from entities too (attacker=0) when they take fire or fall damage
	if (victim != 0 && attacker != victim)
	{
		// If a real player kills another player or bot
		if (attacker != 0 && !IsFakeClient(attacker))
		{
			PlayerKills[attacker] += 1;
			CurPlayerKills[attacker] += 1;
		}

		// If victim is a real player
		if (!IsFakeClient(victim))
		{
			switch (DisplayOnDeathMode[victim])
			{
			  case 1: // Total Damage
				DisplayTotal(victim);
			  case 2: // Current Total Damage
				DisplayCurrentTotal(victim);
			}

			ClearCurrentTotal(victim);	//must be cleared on each death
		}

		// (Coop) Check if all survivors are in saferoom
		if (ReachedSafeRoom)
		{
			if (IsClientInGame(victim) && GetClientTeam(victim) == 2)
			{
				#if DEBUGMODE
				PrintToChatAll("\x04survivor died (clientid %i)", victim);
				#endif

				// If player dies in the saferoom, remove them before we recount
				// Note: game automatically removes them from checkpoint after death, but this would happen after the survivor count causing an 'extra player' in saferoom.
				PlayerReachedSafeRoom[victim] = 0;

				if (SurvivorsSafe() >= SurvivorsAlive())
				{
					// Don't display if a survivor died after round has ended
					if (!HasRoundEnded)
					{
						#if DEBUGMODE
						PrintToChatAll("\x04All Survivors Reached SafeRoom.");
						#endif

						RoundEndMsg();
						return Plugin_Continue;
					}
				}
			}
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

Action Event_RoundStart (Event event, const char[] name, bool dontBroadcast)
{
	HasRoundEnded = false;
	ReachedSafeRoom = false;

	for (int i = 1; i <= MaxClients; i++)
	{
		PlayerReachedSafeRoom[i] = 0;
	}
	return Plugin_Continue;
}

Action Event_PlayerEnterRescueZone(Event event, const char[] name, bool dontBroadcast)
{
	char door[64];
	event.GetString("doorname", door, sizeof(door));

	if (StrEqual(door, "checkpoint_entrance", false) || StrEqual(door, "door_checkpointentrance", false))
	{
		int client = GetClientOfUserId(event.GetInt("userid"));

		if (client != 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
		{
			#if DEBUGMODE
			PrintToChatAll("\x04entered saferoom (clientid %i)", client);
			#endif

			PlayerReachedSafeRoom[client] = 1;

			//start counting survivors after the first survivor enters saferoom
			ReachedSafeRoom = true;

			if (SurvivorsSafe() >= SurvivorsAlive())
			{
				// dont display damage again
				if (!HasRoundEnded)
				{
					#if DEBUGMODE
					PrintToChatAll("\x04All Survivors Reached SafeRoom.");
					#endif

					RoundEndMsg();
					return Plugin_Continue;
				}
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

Action Event_PlayerLeavesRescueZone(Event event, const char[] name, bool dontBroadcast)
{
	if (ReachedSafeRoom)
	{
		//note: We must assume the checkpoint is the saferoom because "area" values wont match up.
		int client = GetClientOfUserId(event.GetInt("userid"));

		if (client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			PlayerReachedSafeRoom[client] = 0;

			#if DEBUGMODE
			PrintToChatAll("\x04left saferoom (clientid %i)", client);
			//SurvivorsSafe();
			//SurvivorsAlive();
			#endif

		}
	}
	return Plugin_Continue;
}

Action Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUGMODE
	PrintToChatAll("\x04All survivors have died.");
	#endif
	RoundEndMsg();
	return Plugin_Continue;
}

Action Event_Maptransition(Event event, const char[] name, bool dontBroadcast)
{
	//this is a backup display if the checkpoint system fails on custom maps
	if (!HasRoundEnded)
	{
		#if DEBUGMODE
		PrintToChatAll("\x04Warning: map_transition triggered, checkpoint system failed. Check if map has the correct checkpoints.");
		#endif

		RoundEndMsg();
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!HasRoundEnded)
	{
		#if DEBUGMODE
		PrintToChatAll("\x04RoundEnd Triggered.");
		#endif

		RoundEndMsg();
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

Action Event_RoundEnd_Finale(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUGMODE
	PrintToChatAll("\x04Finale End Triggered.");
	#endif
	RoundEndMsg();
	return Plugin_Continue;
}

int SurvivorsAlive()
{
	int Survivors = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
			Survivors++;
	}

	#if DEBUGMODE
	PrintToChatAll("\x04  survivors alive: %i ", Survivors);
	#endif

	return Survivors;
}

int SurvivorsSafe()
{
	int Survivors;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (PlayerReachedSafeRoom[i] == 1)
			Survivors++;
	}

	#if DEBUGMODE
	PrintToChatAll("\x04  survivors in saferoom: %i ", Survivors);
	#endif

	return Survivors;
}

void RoundEndMsg()
{
	HasRoundEnded = true;
	ReachedSafeRoom = false;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			// Dont display for infected waiting to spawn if they just saw Total Damage display
			// Always display for survivors incase they died early on
			if (!(GetClientTeam(client) == 3 && IsPlayerAlive(client) == false && DisplayOnDeathMode[1] == 1))
				DisplayTotal(client);
		}

		ClearTotal(client);
	}
}

Action cmdClearDID(int client, int args)
{
	ClearTotal(client);
	PrintToChat(client, "\x04[DID]\x03 DID now is clear.");
	return Plugin_Handled;
}

int l4d_gamemode()
{
	// 1 - coop / 2 - versus / 3 - survival / or false (thx DDR Khat for code)
	char gmode[32];
	FindConVar("mp_gamemode").GetString(gmode, sizeof(gmode));
	if (strcmp(gmode, "coop") == 0)
	{
		return 1;
	}
	else if (strcmp(gmode, "versus", false) == 0)
	{
		return 2;
	}
	else if (strcmp(gmode, "survival", false) == 0)
	{
		return 3;
	}
	else
	{
		return 0;
	}
}

void DisplayTotal(int client)
{
	char pDeath[100];
	Panel pDeathPanel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
	Format(pDeath, sizeof(pDeath), "%t", "DID Total Panel", client);
	pDeathPanel.SetTitle(pDeath);
	pDeathPanel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg done", TotalDamageDone[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg doneta", TotalDamageDoneTA[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg receive", TotalDamageReceived[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg zombie", TotalDamageReceivedInfected[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg receiveta", TotalDamageReceivedTA[client], client);
	pDeathPanel.DrawText(pDeath);
	pDeathPanel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	Format(pDeath, sizeof(pDeath), "%t: %i", "pnl kill zombie", InfectedKills[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %i", "pnl kill player", PlayerKills[client], client);
	pDeathPanel.DrawText(pDeath);
	pDeathPanel.Send(client, Handler_DeathPanel, 10);
	pDeathPanel.Close();
}

void DisplayCurrentTotal(int client)
{
	char pDeath[100];
	Panel pDeathPanel = new Panel(GetMenuStyleHandle(MenuStyle_Radio));
	Format(pDeath, sizeof(pDeath), "%t", "DID Current Panel", client);
	pDeathPanel.SetTitle(pDeath);
	pDeathPanel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg done", CurTotalDamageDone[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg doneta", CurTotalDamageDoneTA[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg receive", CurTotalDamageReceived[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg zombie", CurTotalDamageReceivedInfected[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %iHP", "pnl dmg receiveta", CurTotalDamageReceivedTA[client], client);
	pDeathPanel.DrawText(pDeath);
	pDeathPanel.DrawItem(" ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);
	Format(pDeath, sizeof(pDeath), "%t: %i", "pnl kill zombie", CurInfectedKills[client], client);
	pDeathPanel.DrawText(pDeath);
	Format(pDeath, sizeof(pDeath), "%t: %i", "pnl kill player", CurPlayerKills[client], client);
	pDeathPanel.DrawText(pDeath);
	pDeathPanel.Send(client, Handler_DeathPanel, 10);
	pDeathPanel.Close();
}

void ClearTotal(int client)
{
	TotalDamageDone[client] = 0;
	TotalDamageReceived[client] = 0;
	TotalDamageDoneTA[client] = 0;
	TotalDamageReceivedTA[client] = 0;
	TotalDamageReceivedInfected[client] = 0;
	InfectedKills[client] = 0;
	PlayerKills[client] = 0;

	// Need to clear CurrentTotal every time we clear the Total.  End of round and did_clear in chat.
	ClearCurrentTotal(client);
}

void ClearCurrentTotal(int client)
{
	CurTotalDamageDone[client] = 0;
	CurTotalDamageReceived[client] = 0;
	CurTotalDamageDoneTA[client] = 0;
	CurTotalDamageReceivedTA[client] = 0;
	CurTotalDamageReceivedInfected[client] = 0;
	CurInfectedKills[client] = 0;
	CurPlayerKills[client] = 0;
}

void SaveUserSettings()
{
	// Save user settings to a file
	kvDIDUS.Rewind();
	KeyValuesToFile(kvDIDUS, fileDIDUS);
}

void PrepareClient(int client)
{
	char steamId[20];

	if (!IsFakeClient(client))
	{
		GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

		// Get the users saved setting or create them if they don't exist
		kvDIDUS.Rewind();
		if (kvDIDUS.JumpToKey(steamId))
		{
			DisplayMode[client] = KvGetNum(kvDIDUS, "hint preference", iDefaultMode);
			DisplayOnDeathMode[client] = KvGetNum(kvDIDUS, "total preference", iDefaultOnDeathMode);
		}
		else
		{
			kvDIDUS.JumpToKey(steamId, true);
			kvDIDUS.SetNum("hint preference", iDefaultMode);
			kvDIDUS.SetNum("total preference", iDefaultOnDeathMode);
			char datestamp[60];
			FormatTime(datestamp, sizeof(datestamp), "%H:%M:%S / %d-%m-%Y", GetTime());
			kvDIDUS.SetString("last connect", datestamp);

			DisplayMode[client] = iDefaultMode;
			DisplayOnDeathMode[client] = iDefaultOnDeathMode;
		}
		kvDIDUS.Rewind();

		// Make the announcement in 30 seconds unless announcements are turned off
		if (bCvarAnnounce)
			CreateTimer(30.0, TimerAnnounce, client);
	}
}

void OnCVGameModeChange(ConVar convar, const char[] oldValue, const char[] intValue)
{
	//If game mode actually changed
	if (strcmp(oldValue, intValue) != 0 && (l4d_gamemode() == 1 || l4d_gamemode() == 2 || l4d_gamemode() == 3))
	{
		// initial game mode
		if (l4d_gamemode() == 2)
		{
			HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		}
		else if (l4d_gamemode() == 1)
		{
			HookEvent("mission_lost", Event_MissionLost, EventHookMode_PostNoCopy);
			HookEvent("map_transition", Event_Maptransition, EventHookMode_PostNoCopy);
			HookEvent("player_entered_checkpoint", Event_PlayerEnterRescueZone);
			HookEvent("player_left_checkpoint", Event_PlayerLeavesRescueZone);
		}
	}
}

Action TimerAnnounce(Handle timer, any client)
{
	if (IsClientInGame(client))
	{
		PrintToChat(client, "\x04[DID]\x03 %t \x04!did_hmode !did_tmode !did !did_clear", "About");
		if (bSurvivorBlockMode)
			PrintToChat(client, "\x04[DID]\x03 %t", "HintsTextBlocked");
	}
	return Plugin_Stop;
}
