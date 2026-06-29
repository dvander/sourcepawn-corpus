#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0"
#define TEAM_SPECTATOR	1
#define TEAM_SURVIVOR	2

int		LastBot[MAXPLAYERS+1] = 1;
Handle	MenuTimer[MAXPLAYERS+1];

StringMap SteamIDs;

ConVar Cvar_PickBot;
ConVar Cvar_IdleBot;
ConVar Cvar_DeadBot;
ConVar Cvar_TimeBot;

public Plugin myinfo =
{
	name        = "Survivor Bot Select",
	author      = "Merudo",
	description = "Allows players to pick a bot to takeover in Left 4 Dead.",
	version     = PLUGIN_VERSION,
	url         = ""
}
public void OnPluginStart()
{
	CreateConVar("l4d_sbs_version", PLUGIN_VERSION, "Version of Survivor Bot Select", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Cvar_PickBot = CreateConVar("l4d_sbs_pick",  "1", "Enable use of commands to pick a bot? 1:Enable, 0:Disable", FCVAR_NOTIFY,true,0.00,true,1.00);
	Cvar_IdleBot = CreateConVar("l4d_sbs_idle",  "1", "Allow survivors to change idle bot with right mouse button? 1:Enable, 0:Disable", FCVAR_NOTIFY,true,0.00,true,1.00);
	Cvar_TimeBot = CreateConVar("l4d_sbs_time", "-1", "Time that survivors have to change bots. -1: Disable", FCVAR_NOTIFY,true,-1.00);
	Cvar_DeadBot = CreateConVar("l4d_sbs_dead",  "1", "Always allow dead survivors to change bots? 1:Enable, 0:Disable", FCVAR_NOTIFY,true,0.00,true,1.00);

	AddCommandListener(Cmd_spec_prev, "spec_prev");
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);	

	RegConsoleCmd("sm_nextbot", Next_Bot, "Gain control of next bot");	
	RegConsoleCmd("sm_prevbot", Prev_Bot, "Gain control of previous bot");
	RegConsoleCmd("sm_pickbot", Pick_Bot, "Show menu to take a bot");	

	SteamIDs = new StringMap();
	
	AutoExecConfig(true, "l4d_sbs");
}

// *********************************************************************************
// METHODS TO BLOCK BOT PICK AFTER TIMER RAN OUT
// *********************************************************************************

public void OnMapEnd() {GameEnd();}
public void Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast) { GameEnd();}
void GameEnd()
{	
	SteamIDs.Clear();
}

// ------------------------------------------------------------------------
//  Each time a survivor spawns, setup timer to disable bot picking
// ------------------------------------------------------------------------
public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int userid =  GetEventInt(event, "userid")
	int client =  GetClientOfUserId(userid);

	if (GetClientTeam(client) == TEAM_SURVIVOR && !IsFakeClient(client) && Cvar_TimeBot.FloatValue >= 0)
	{
		char SteamID[64];
		bool valid = GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));
		if (!valid) return;
		
		int Allowed;
		if (!SteamIDs.GetValue(SteamID, Allowed) || Allowed == 1)  // If can't find the entry in map or is allow but not yet timed
		{
			SteamIDs.SetValue(SteamID, 2, true);
			Handle datapack = CreateDataPack(); WritePackString(datapack,SteamID); WritePackCell(datapack,userid);
			CreateTimer(Cvar_TimeBot.FloatValue, Timer_RecordSteamID, datapack, TIMER_FLAG_NO_MAPCHANGE);		
			if (Cvar_TimeBot.FloatValue > 2 && Cvar_PickBot.BoolValue) PrintToChat(client, "\x04[SBS]\x01 You have %d seconds to takeover another bot using !pickbot", Cvar_TimeBot.IntValue);
		}
	}
}

// ------------------------------------------------------------------------
// Returns true if SteamID is in array, and this bot pick is blocked
// ------------------------------------------------------------------------
int PickAllowed(int client)
{
	if(!IsClientInGame(client) || IsFakeClient(client)) return false;
		
	char SteamID[64];
	bool valid = GetClientAuthId(client, AuthId_Steam2, SteamID, sizeof(SteamID));		

	if (valid == false) return false;

	int Allowed;
	if (!SteamIDs.GetValue(SteamID, Allowed))  // If can't find the entry in map
	{
		SteamIDs.SetValue(SteamID, 1, true);
		return true;
	}
	return Allowed;
}

// ------------------------------------------------------------------------
// Set SteamID to disallow once time runs out
// ------------------------------------------------------------------------
public Action Timer_RecordSteamID(Handle hTimer, Handle datapack)
{
	char SteamID[64];
	ResetPack(datapack);
	ReadPackString(datapack, SteamID, sizeof(SteamID));
	SteamIDs.SetValue(SteamID, 0, true);
	
	int client = GetClientOfUserId(ReadPackCell(datapack));	
	if (client && Cvar_TimeBot.FloatValue > 2 && Cvar_PickBot.BoolValue) PrintToChat(client, "\x04[SBS]\x01 You may no longer takeover a bot.", Cvar_TimeBot.FloatValue);
}

bool VerifyCommand(int client)
{
	//Verifiy is command is appropriate
	if (client == 0)  {  ReplyToCommand(client, "[SBS] Command is in-game only.");  return false;} 
	if (!IsClientInGame(client) || IsFakeClient(client)) return false;
	if (GetClientTeam(client) != TEAM_SURVIVOR)  {  ReplyToCommand(client, "[SBS] Only survivors may use this command.");  return false;} 	
	if (!Cvar_DeadBot.BoolValue || IsPlayerAlive(client) ) // Skip this if dead & l4d_sbs_dead is 1
	{
		if (!Cvar_PickBot.BoolValue) {ReplyToCommand(client, "[SBS] Command is disabled.");  return false;  }
		if (Cvar_TimeBot.FloatValue >= 0 && !PickAllowed(client)) {  ReplyToCommand(client, "[SBS] You may no longer use this command this round.");  return false;}	
	}
	
	int AvailableBots = CountAvailableSurvivorBots();
	if (AvailableBots == 0)
	{
		ReplyToCommand(client, "[SBS] No survivor bot available."); return false;
	}
	return true;
}

bool VerifyIdle(int client)
{
	if (client == 0)  return false;
	if (!IsClientInGame(client) || IsFakeClient(client)) return false;
	if (GetClientTeam(client) != TEAM_SPECTATOR) return false; 	
	if (!Cvar_IdleBot.BoolValue) return false; 
	if (Cvar_TimeBot.FloatValue >= 0 && !PickAllowed(client)) return false;
	return true;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	// Event is triggered when a player dies
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || IsFakeClient(client) || GetClientTeam(client) != TEAM_SURVIVOR) return;
	
	if (!Cvar_DeadBot.BoolValue || IsPlayerAlive(client) ) // Skip this if dead & l4d_sbs_dead is 1
	{
		if (!Cvar_PickBot.BoolValue) {return;}
		if (Cvar_TimeBot.FloatValue >= 0 && !PickAllowed(client)) {return;}	
	}
	int AvailableBots = CountAvailableSurvivorBots();
	if (AvailableBots == 0) return;
	
	PrintToChat(client, "\x04[SBS]\x01 You may takeover another bot by using the !pickbot command");
}

// *********************************************************************************
// BOT NEXT/PREV METHODS
// *********************************************************************************

public Action Next_Bot(int client, int args)
{
	if (!VerifyCommand(client)) {return Plugin_Continue;}

	int NextBot = GetNextBot(LastBot[client]);
	if (!NextBot) { if (IsSurvivorBotValid(LastBot[client]) && !GetIdlePlayer(LastBot[client])) NextBot = LastBot[client]; }
	if (NextBot)
	{
		LastBot[client] = NextBot;
		ChangeClientTeam(client, TEAM_SPECTATOR);
		SetHumanIdle(NextBot, client);
		TakeOverBot(client);
	}
	return Plugin_Handled;
}

public Action Prev_Bot(int client, int args)
{
	if (!VerifyCommand(client)) {return Plugin_Continue;}

	int PrevBot = GetPrevBot(LastBot[client]);
	if (!PrevBot) { if (IsSurvivorBotValid(LastBot[client]) && !GetIdlePlayer(LastBot[client])) PrevBot = LastBot[client]; }
	if (PrevBot)
	{
		LastBot[client] = PrevBot;
		ChangeClientTeam(client, TEAM_SPECTATOR);
		SetHumanIdle(PrevBot, client);
		TakeOverBot(client);
	}
	return Plugin_Handled;
}

// ------------------------------------------------------------------------
// Returns the next bot available for idle/takeover
// ------------------------------------------------------------------------
int GetNextBot(int bot)
{
	for (int i = bot+1; i <= MaxClients; i++)
	{
		if (IsSurvivorBotValid(i) && !GetIdlePlayer(i)) return i;
	}
	for (int i = 1; i < bot; i++)
	{
		if (IsSurvivorBotValid(i) && !GetIdlePlayer(i)) return i;
	}
	return 0
}

// ------------------------------------------------------------------------
// Returns the previous bot available for idle/takeover
// ------------------------------------------------------------------------
int GetPrevBot(int bot)
{
	for (int i = bot-1; i >= 1; i--)
	{
		if (IsSurvivorBotValid(i) && !GetIdlePlayer(i)) return i;
	}
	for (int i = MaxClients; i > bot; i--)
	{
		if (IsSurvivorBotValid(i) && !GetIdlePlayer(i)) return i;
	}
	return 0
}

// *********************************************************************************
// PICK BOT MENU
// *********************************************************************************

public Action Pick_Bot(int client, int args)
{
	ShowMenu(client);
	return Plugin_Handled;
}

void ShowMenu(int client)
{
	if (!VerifyCommand(client)) return;
	
	int AvailableBots = CountAvailableSurvivorBots();

	char number[10]; char text_client[32];
	Menu menu = new Menu(MenuHandler1);
	menu.SetTitle("Select a bot:");

	for (int i = 1; i <= MaxClients; i++) 
	{
		if (!IsSurvivorBotValid(i) || GetIdlePlayer(i)) continue;
 
 		Format(number, sizeof(number), "%i", i); 
		char m_iHealth[MAX_TARGET_LENGTH];
		if (AvailableBots < 8) // if a one page menu
		{
			if(GetEntProp(i, Prop_Send, "m_isIncapacitated"))
			{
				Format(m_iHealth, sizeof(m_iHealth), "DOWN - %d HP - ", GetEntData(i, FindDataMapInfo(i, "m_iHealth"), 4));
			}
			else if(GetEntProp(i, Prop_Send, "m_currentReviveCount") == FindConVar("survivor_max_incapacitated_count").IntValue)
			{
				Format(m_iHealth, sizeof(m_iHealth), "BLWH - %d HP - ", GetEntData(i, FindDataMapInfo(i, "m_iHealth"), 4));
			}
			else
			{
				Format(m_iHealth, sizeof(m_iHealth), "%d HP - ", GetClientRealHealth(i));
			}
		}
		Format(text_client, sizeof(text_client), "%s%N", m_iHealth, i);		
		AddMenuItem(menu, number, text_client); 		
	}
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	if (AvailableBots < 8) MenuTimer[client] = CreateTimer(1.0, Timer_MenuHandler, client);
}

public Action Timer_MenuHandler(Handle hTimer, int client)
{
	MenuTimer[client] = null;
	ShowMenu(client);
}

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)  
	{ 
		case MenuAction_Select:  
		{
			int client = param1;	
			delete MenuTimer[client];
			char number[4]; 
			GetMenuItem(menu, param2, number, sizeof(number)); 
			int PickedBot = StringToInt(number);

			if (!VerifyCommand(client)) return;
			if (!PickedBot || !IsSurvivorBotValid(PickedBot) || GetIdlePlayer(PickedBot)) { PrintToChat(client, "[SBS] This survivor bot is no longer available.");  return;}

			ChangeClientTeam(client, TEAM_SPECTATOR);
			SetHumanIdle(PickedBot, client);
			TakeOverBot(client);
		}
		case MenuAction_Cancel:  {  delete MenuTimer[param1];} 
		case MenuAction_End:  	 {} 
	}
}

// *********************************************************************************
// RIGHT MOUSE CLICK WHEN IDLE, IDLE NEXT SURVIVOR
// *********************************************************************************

public Action Cmd_spec_prev(int client, char[] command, int argc)
{
	if (!VerifyIdle(client)) return Plugin_Continue;
	
	int CurrentBot = GetBotOfIdle(client)
	if (CurrentBot)
	{
		int NextBot = GetNextBot(CurrentBot);
		if (NextBot) 
		{
			SetEntProp(CurrentBot, Prop_Send, "m_humanSpectatorUserID",0); // Remove idle from bot
			SetHumanIdle(NextBot, client); 	// Set idle to next bot
		}
	}
	return Plugin_Continue;
}

// *********************************************************************************
// BOT INFORMATION METHODS
// *********************************************************************************

// ------------------------------------------------------------------------
// Count the number of available bots
// ------------------------------------------------------------------------
int CountAvailableSurvivorBots()
{
	int count = 0
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsSurvivorBotValid(i) && !GetIdlePlayer(i)) count = count + 1;		
	}
	return count;
}

// ------------------------------------------------------------------------
// Returns the idle player of the bot, returns 0 if none
// ------------------------------------------------------------------------
int GetIdlePlayer(int bot)
{
	if(IsSurvivorBotValid(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR)
			{
				return client;
			}
		}
	}
	return 0;
}

// ------------------------------------------------------------------------
// Returns the bot of the idle client, returns 0 if none 
// ------------------------------------------------------------------------
int GetBotOfIdle(int client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (GetIdlePlayer(i) == client) return i;
	}
	return 0;
}

// ------------------------------------------------------------------------
// Returns if the survivor bot is valid (in game, bot, survivor, alive)
// ------------------------------------------------------------------------
bool IsSurvivorBotValid(int bot)
{
	if(bot > 0 && IsClientInGame(bot) && IsFakeClient(bot) && !IsClientInKickQueue(bot) && GetClientTeam(bot) == TEAM_SURVIVOR && IsPlayerAlive(bot))
		return true;
	return false;
}

// ------------------------------------------------------------------------
// Returns health of client
// ------------------------------------------------------------------------
int GetClientRealHealth(int client)
{
	if(!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		return -1;
	}
	if(GetClientTeam(client) != TEAM_SURVIVOR)
	{
		return GetClientHealth(client);
	}
  
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float TempHealth;
	int PermHealth = GetClientHealth(client);
	if(buffer <= 0.0)
	{
		TempHealth = 0.0;
	}
	else
	{
		float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		float decay = FindConVar("pain_pills_decay_rate").FloatValue;
		float constant = 1.0/decay;	TempHealth = buffer - (difference / constant);
	}
	
	if(TempHealth < 0.0)
	{
		TempHealth = 0.0;
	}
	return RoundToFloor(PermHealth + TempHealth);
}

// *********************************************************************************
// SIGNATURE METHODS
// *********************************************************************************

void SetHumanIdle(int bot, int client)
{
	static Handle hSpec = INVALID_HANDLE;
	if (hSpec == INVALID_HANDLE)
	{
		Handle hGameConf = LoadGameConfigFile("l4d_survivor_bot_select");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetHumanSpec");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hSpec = EndPrepSDKCall();
		if(hSpec == INVALID_HANDLE)
		{
			PrintToChatAll("[SBS] SetHumanSpec Signature broken. Make sure l4d_survivor_bot_select.txt is in /gamedata/");		
		}
	}
	SDKCall(hSpec, bot, client);
}

void TakeOverBot(int client)
{
	static Handle hSwitch = INVALID_HANDLE;
	if (hSwitch == INVALID_HANDLE)
	{
		Handle hGameConf = LoadGameConfigFile("l4d_survivor_bot_select");
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "TakeOverBot");
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hSwitch = EndPrepSDKCall();
		if (hSwitch == INVALID_HANDLE)
		{
			PrintToChatAll("[SBS] TakeOverBot Signature broken. Make sure l4d_survivor_bot_select.txt is in /gamedata/");	
		}	
	}
	SDKCall(hSwitch, client, true);
}