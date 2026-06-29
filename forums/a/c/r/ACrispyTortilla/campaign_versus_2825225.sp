#define PLUGIN_VERSION "1.1b"

#include <sourcemod>
#include <left4dhooks>
#include <left4dhooks_anim>
#include <left4dhooks_lux_library>
#include <left4dhooks_silver>
#include <left4dhooks_stocks>

// ConVars
ConVar g_cvConVars[7];
bool g_cvEnabled, g_cvBots, g_cvHintText, g_cvCenterText, g_cvEndRound, g_cvAdmins;
char g_cvAdminFlags[10];
float g_cvRespawnTime;

// Arrays
ArrayList g_alAdminFlags;

// Booleans
bool g_bRoundActive = true;

// Handles
Handle g_hTimer[MAXPLAYERS+1];

public Plugin myinfo = {
	name 		= "[L4D2] Campaign Versus/Respawn Timer",
	author 		= "Sgt. Gremulock, Techy/Seamusmario",
	description = "Control the player infected respawn time in campaign with custom values. (Originally made for TF2, now it's made for L4D2 Campaign Mode!)",
	version 	= PLUGIN_VERSION,
	url 		= "https://steamcommunity.com/profiles/76561198202095595/"
};

Handle hRoundRespawn;
Handle hGameConf;
public void OnPluginStart()
{
	CreateConVar("sm_campaignversus_version", PLUGIN_VERSION, "Plugin's version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvConVars[0] = CreateConVar("sm_campaignversus_enable", "1", "Enable/disable the plugin.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	g_cvConVars[1] = CreateConVar("sm_campaignversus_bots", "0", "Enable/disable the respawn timer for bots.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	g_cvConVars[2] = CreateConVar("sm_campaignversus_time", "15.0", "Time it should take (in seconds) to respawn a player.", _, true, 0.01);
	g_cvConVars[3] = CreateConVar("sm_campaignversus_hint_text", "1", "Enable/disable displaying the time (with hint text) until the player will respawn.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	g_cvConVars[4] = CreateConVar("sm_campaignversus_center_text", "0", "Enable/disable displaying the time (with center text) until the player will respawn.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);
	g_cvConVars[5] = CreateConVar("sm_campaignversus_admin_flags", "", "Restrict the respawn timer to only affect players with certain admin flag(s).\nIf using multiple flags (you can use up to 5), seperate each with a comma (,) and make sure to end with a comma.\nLeave this blank to disable.");
	g_cvConVars[6] = CreateConVar("sm_campaignversus_end_round", "0", "Enable/disable respawning after a round ends.\n(1 = Enable, 0 = Disable)", _, true, 0.0, true, 1.0);

	for (int i = 0; i < sizeof(g_cvConVars); i++)
	{
		g_cvConVars[i].AddChangeHook(ConVar_Update); // Hook ConVar changes.
	}

	RegAdminCmd("sm_infected", Menu_Test1, ADMFLAG_ROOT);
	RegAdminCmd("sm_survivor", Menu_Test1, ADMFLAG_ROOT);
	RegAdminCmd("sm_survivors", Menu_Test1, ADMFLAG_ROOT);
	
	AutoExecConfig(true, "campaignversus");

	HookEvent("player_spawn", Event_PlayerSpawn); // Hook the player death event.
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn); // Hook the player death event.
	HookEvent("player_team", Event_PlayerTeam); // Hook the player death event.
	HookEvent("player_death", Event_PlayerDeath); // Hook the player death eve3
	HookEvent("mission_lost", Event_RoundWin); // Hook the round end event.
	HookEvent("player_left_start_area", Event_RoundStart); // Hook the round start event.
	HookEvent("player_left_safe_area", Event_RoundStart); // Hook the round start event.

	LoadTranslations("campaignversus.phrases");
	SetCommandFlags("kill", FCVAR_NONE);
	SetCommandFlags("explode", FCVAR_NONE);
	/*
	
	char name[256];
	GetClientName(client,name,sizeof(name));
	if (GetClientTeam(client) == 3){ 
		PrintToChatAll("%s is joining the Infected",name);
	} else {
		PrintToChatAll("%s is joining the Survivors",name);
	}
	
	*/
}

Action sm_infected(int client, int args)
{	
	ChangeClientTeam(client, 3);
	CreateRespawnTimer(client);
	char name[256];
	GetClientName(client,name,sizeof(name));
	return Plugin_Handled;
}

Action sm_survivor(int client, int args)
{	
	L4D_ReplaceWithBot(client);
	ChangeClientTeam(client, 0);	
	L4D_SetHumanSpec(GetRandomBot(2),client);
	L4D_TakeOverBot(client);
	return Plugin_Handled;
}

void L4D_OnSpawnTank_Post(int client, const float vecPos[3], const float vecAng[3])
{
	if (IsFakeClient(client)) {
	
		int inf = GetRandomPlayer(3);
	
		char name[256];
		GetClientName(inf,name,sizeof(name));
		L4D_ReplaceWithBot(inf);
		L4D_TakeOverZombieBot(inf, client);
		g_hTimer[client] = null;
	
	}
}
public void OnConfigsExecuted()
{
	g_cvEnabled 	= g_cvConVars[0].BoolValue;
	g_cvBots 		= g_cvConVars[1].BoolValue;
	g_cvRespawnTime = g_cvConVars[2].FloatValue;
	g_cvHintText 	= g_cvConVars[3].BoolValue;
	g_cvCenterText 	= g_cvConVars[4].BoolValue;
	g_cvConVars[5].GetString(g_cvAdminFlags, sizeof(g_cvAdminFlags));
	g_cvEndRound 	= g_cvConVars[6].BoolValue;

	if (g_cvEnabled && !StrEqual(g_cvAdminFlags, "", false))
	{
		g_cvAdmins 		= true;
		g_alAdminFlags 	= new ArrayList(1);
		AdminFlag g_admAdminFlag;
		char g_sAdminFlags[10];
		strcopy(g_sAdminFlags, sizeof(g_sAdminFlags), g_cvAdminFlags);

		for (int i = 0; i < strlen(g_sAdminFlags); i++)
		{
			if (StrContains(g_sAdminFlags, ",", false) != -1)
			{
				char g_sSplitString[3];

				if (SplitString(g_sAdminFlags, ",", g_sSplitString, sizeof(g_sSplitString)) != -1)
				{
					if (!FindFlagByChar(g_sSplitString[0], g_admAdminFlag))
					{
						LogError("ERROR: Invalid admin flag '%s'. Skipping...", g_sSplitString);
					}
					else
					{
						g_alAdminFlags.PushString(g_sSplitString);
						LogMessage("Added admin flag requirement '%s'.", g_sSplitString);
					}

					Format(g_sSplitString, sizeof(g_sSplitString), "%s,", g_sSplitString);
					ReplaceString(g_sAdminFlags, sizeof(g_sAdminFlags), g_sSplitString, "", false);
				}
			}
			else
			{
				if (!FindFlagByChar(g_cvAdminFlags[0], g_admAdminFlag))
				{
					SetFailState("ERROR: Invalid admin flag '%s'.", g_cvAdminFlags);
				}

				g_alAdminFlags.PushString(g_cvAdminFlags);

				LogMessage("Set required admin flag to '%s'.", g_cvAdminFlags);
			}
		}
	}
	else
	{
		if (g_alAdminFlags != null)
		{
			g_alAdminFlags.Clear();
			g_alAdminFlags = null;
		}

		g_cvAdmins 		= false;
	}
}

public void ConVar_Update(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	OnConfigsExecuted();

	if (!g_cvEnabled)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i, g_cvBots))
			{
				continue;
			}

			OnClientDisconnect(i);
		}
	}
}

/* Client functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public void OnClientDisconnect(int client)
{
	if (g_hTimer[client] != null)
	{
		KillTimer(g_hTimer[client]);
		g_hTimer[client] = null;
	}
}

/* Events ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client != 0 && !IsFakeClient(client) && GetClientTeam(client) == 3) // Make sure the client is valid, they didn't fake their death with a dead ringer, etc.
	{	
		if (g_hTimer[client] != INVALID_HANDLE) {
			delete g_hTimer[client];
		}
		CreateRespawnTimer(client);
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled || (!g_cvEndRound && !g_bRoundActive))
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (GetClientTeam(client) == 3 && IsFakeClient(client)) {
	/*
		int inf = GetRandomPlayer(3);
		if (!IsPlayerAlive(inf)) {
			if (L4D2_GetPlayerZombieClass(client) == 7) 
				L4D_TakeOverZombieBot(inf, client);
		}
	*/
	}
}


public void Event_PlayerFirstSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled || (!g_cvEndRound && !g_bRoundActive))
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (GetClientTeam(client) == 3 && IsFakeClient(client)) {
	/*
		int inf = GetRandomPlayer(3);
		if (!IsPlayerAlive(inf)) {
			if (L4D2_GetPlayerZombieClass(client) == 7) 
				L4D_TakeOverZombieBot(inf, client);
		}
	*/
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled || (!g_cvEndRound && !g_bRoundActive))
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");
	
	char name[256];
	GetClientName(client,name,sizeof(name));
	if (!IsFakeClient(client)) {
		if (team == 3){ 
			PrintToServer("%s is joining the Infected",name);
		} else if (team == 2) {
			PrintToServer("%s is joining the Survivors",name);
		}
	}
}

public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled || g_cvEndRound)
	{
		return;
	}

	g_bRoundActive = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_cvEnabled || g_cvEndRound)
	{
		return;
	}

	g_bRoundActive = true;
	
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i) && GetClientTeam(i) == 3 && g_hTimer[i] == null)
        { 
            CreateRespawnTimer(i);
        } 
    } 
}
public void Event_TankSpawned(Event event, const char[] name, bool dontBroadcast)
{	
	if (IsHumanTankAlive())
		return;
		
	int tank = GetClientOfUserId(event.GetInt("userid"));
	int client = GetRandomPlayer(3);
	int surv = GetRandomPlayer(2);
	float pos[3];
	float ang[3];	
	GetClientAbsOrigin(surv,pos);
	GetClientAbsAngles(surv,ang);
	int special = GetRandomInt(0,6); 
	if (L4D_GetRandomPZSpawnPosition(client,special,7,pos) == true && !IsHumanTankAlive()) {		
		int bot = L4D2_SpawnTank(pos,ang);
		if (bot != -1) {
			
			L4D_TakeOverZombieBot(client, bot);
			g_hTimer[client] = null;
				
		} else {
			
			g_hTimer[client] = null;
			CreateRespawnTimer(client);
			
		}
	} else {
		g_hTimer[client] = null;
		CreateRespawnTimer(client);
	}
}

stock int GetRandomPlayer(int team) 
{ 
    int[] clients = new int[MaxClients]; 
    int clientCount; 
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (team == 3 && IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i) || team == 2 && IsClientInGame(i) && GetClientTeam(i) == team)
        { 
            clients[clientCount++] = i; 
        } 
    } 
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)]; 
}
stock int GetRandomTeamClient(int team) 
{ 
    int[] clients = new int[MaxClients]; 
    int clientCount; 
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (team == 3 && IsClientInGame(i) && GetClientTeam(i) == team || team == 2 && IsClientInGame(i) && GetClientTeam(i) == team)
        { 
            clients[clientCount++] = i; 
        } 
    } 
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)]; 
}

stock int GetRandomBot(int team) 
{ 
    int[] clients = new int[MaxClients]; 
    int clientCount; 
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (team == 3 && IsClientInGame(i) && GetClientTeam(i) == team && IsFakeClient(i) || team == 2 && IsClientInGame(i) && GetClientTeam(i) == team && IsFakeClient(i))
        { 
            clients[clientCount++] = i; 
        } 
    } 
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)]; 
}
stock bool IsHumanTankAlive() 
{ 
    int[] clients = new int[MaxClients]; 
    int clientCount; 
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i) && GetClientTeam(i) == 3 && !IsFakeClient(i))
        { 
			if (L4D2_GetPlayerZombieClass(i) == 7) 
				return true;
        } 
    } 
	return false;
}
stock int GetAliveTeamCount(int team)
{
    int number = 0;
    for (new i=1; i<=MaxClients; i++)
    { 
        if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team && !IsFakeClient(i)) 
            number++;
    }
    return number;
} 

public int MenuHandler1(Menu menu, MenuAction action, int param1, int param2)
{
  switch(action)
  {
    case MenuAction_Start:
    {
      PrintToServer("Displaying menu");
    }
 
    case MenuAction_Display:
    {
      char buffer[255];
      Format(buffer, sizeof(buffer), "Pick a Team");
 
      Panel panel = view_as<Panel>(param2);
      panel.SetTitle(buffer);
      PrintToServer("Client %d was sent menu with panel %x", param1, param2);
    }
 
    case MenuAction_Select:
    {
		  char info[32];
		  menu.GetItem(param2, info, sizeof(info));
		  if (StrEqual(info, "tip1") || StrEqual(info, "tip2") || StrEqual(info, "tip3"))
		  {
			PrintToServer("Client %d somehow selected %s despite it being disabled", param1, info);
		  }
		  else
		  {
			if (StrEqual(info, "Survivors") && GetClientTeam(param1) != 2) {					
				if (GetRandomBot(2) != -1) {
					ChangeClientTeam(param1, 0);
					L4D_SetHumanSpec(GetRandomBot(2),param1);
					L4D_TakeOverBot(param1);
				} else {
					new surv = GetRandomTeamClient(2);
					if (surv > 1) {
						
						int client = param1;
						float pos[3];
						float ang[3];	
						GetClientAbsOrigin(surv,pos);
						GetClientAbsAngles(surv,ang);
						ChangeClientTeam(param1, 2);
						L4D_RespawnPlayer(param1);
						TeleportEntity(param1,pos,NULL_VECTOR,NULL_VECTOR);
						int flags = GetCommandFlags("give");
						SetCommandFlags("give", flags & ~FCVAR_CHEAT);
						FakeClientCommand( client, "give smg" );
						FakeClientCommand( client, "give pistol" );
						FakeClientCommand( client, "give pistol" );
						SetCommandFlags( "give", flags|FCVAR_CHEAT );
						CreateTimer(8.0, PickATeam, client, TIMER_FLAG_NO_MAPCHANGE);
					} else {
						
						ChangeClientTeam(param1, 2);
						L4D_RespawnPlayer(param1);
						int client = param1;
						int flags = GetCommandFlags("give");
						SetCommandFlags("give", flags & ~FCVAR_CHEAT);
						FakeClientCommand( client, "give smg" );
						FakeClientCommand( client, "give pistol" );
						FakeClientCommand( client, "give pistol" );
						SetCommandFlags( "give", flags|FCVAR_CHEAT );
						CreateTimer(8.0, PickATeam, client, TIMER_FLAG_NO_MAPCHANGE);
					}
					float pos[3];
					float ang[3];	
					GetClientAbsOrigin(surv,pos);
					GetClientAbsAngles(surv,ang);
				}
			} else if (StrEqual(info, "Infected")) {					
				L4D_ReplaceWithBot(param1);	
				ChangeClientTeam(param1, 3);
				g_hTimer[param1] = CreateTimer(g_cvRespawnTime, Timer_Respawn, param1, TIMER_FLAG_NO_MAPCHANGE);
				CreateTimer(0.0, Timer_RespawnHint, param1, TIMER_FLAG_NO_MAPCHANGE);
				char name[256];
				GetClientName(param1,name,sizeof(name));
			} else if (StrEqual(info, "Random")) {					
				L4D_ReplaceWithBot(param1);		
					if (GetRandomInt(1,3) != 1 && GetClientTeam(param1) != 2) {
						if (GetRandomBot(2) > 1) {
							ChangeClientTeam(param1, 0);
							L4D_SetHumanSpec(GetRandomBot(2),param1);
							L4D_TakeOverBot(param1);
						} else {
							new surv = GetRandomSurvivor();
							float pos[3];
							float ang[3];	
							GetClientAbsOrigin(surv,pos);
							GetClientAbsAngles(surv,ang);
							ChangeClientTeam(param1, 2);
							L4D_RespawnPlayer(param1);
							if (L4D_GetRandomPZSpawnPosition(surv,1,100,pos) == true) {	
								TeleportEntity(param1,pos,NULL_VECTOR,NULL_VECTOR);
							}
						}
					} else {
						ChangeClientTeam(param1, 3);
						CreateTimer(16.0, Timer_Respawn, param1, TIMER_FLAG_NO_MAPCHANGE);
						CreateTimer(0.0, Timer_RespawnHint, param1, TIMER_FLAG_NO_MAPCHANGE);
						char name[256];
						GetClientName(param1,name,sizeof(name));
					}
			}
		}
    }
 
    case MenuAction_Cancel:
    {
      PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
    }
 
    case MenuAction_End:
    {
      delete menu;
    }
 
    case MenuAction_DrawItem:
    {
      int style;
      char info[32];
      menu.GetItem(param2, info, sizeof(info), style);
 
      if (StrEqual(info, "tip1") || StrEqual(info, "tip2") || StrEqual(info, "tip3"))
      {
        return ITEMDRAW_DISABLED;
      }
      else
      {
        return style;
      }
    }
  }
 
  return 0;
}
 
public Action Menu_Test1(int client, int args)
{
  Menu menu = new Menu(MenuHandler1, MENU_ACTIONS_ALL);
  menu.SetTitle("Pick a Team");
  menu.AddItem("Survivors", "Survivors");
  menu.AddItem("Infected", "Infected");
  menu.AddItem("Random", "Random");
  menu.AddItem("tip1","Press 1, or 2 on your keyboard to pick a team.");
  menu.AddItem("tip2","Press 3 on your keyboard to pick a random team")
  menu.AddItem("tip3","Say !infected or !survivor to open this menu again")
  menu.ExitButton = false;
  menu.Display(client, 20);
 
  return Plugin_Handled;
}

/* Timers ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

public Action PickATeam(Handle timer, any client)
{
	Menu_Test1(client,0)
}
public Action Timer_Respawn(Handle timer, any client)
{
	if (!IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{		
		int surv = GetRandomPlayer(2);
		while (surv == 0 || !IsClientConnected(surv)) {
			surv = GetRandomPlayer(2);
		}
		float pos[3];
		float ang[3];	
		GetClientAbsOrigin(surv,pos);
		GetClientAbsAngles(surv,ang);
		int special = GetRandomInt(1,6); 
		
		if (L4D_GetRandomPZSpawnPosition(surv,special,100,pos) == true) {	
			L4D_SetClass(client,special);
			L4D_RespawnPlayer(client);
			TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
		}
		g_hTimer[client] = null;
					
		if (!IsPlayerAlive(client)) {
			g_hTimer[client] = CreateTimer(3.0, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
			CreateTimer(0.0, Timer_RespawnHint2, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
public Action Timer_Ghost(Handle timer, any client)
{
	if (IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{	
	}
}
public Action Timer_RespawnHint(Handle timer, any client)
{
	if (!IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{		
		if (g_cvHintText)
		{
			PrintHintText(client, "%t", "Respawn Text", g_cvRespawnTime);
		}

		if (g_cvCenterText)
		{
			PrintCenterText(client, "%t", "Respawn Text", g_cvRespawnTime);
		}
	}
}
public Action Timer_RespawnHint2(Handle timer, any client)
{
	if (!IsPlayerAlive(client) && GetClientTeam(client) == 3)
	{		
		if (g_cvHintText)
		{
			PrintHintText(client, "It's taking a bit longer than expected.\nYou might respawn in 3 seconds.");
		}

		if (g_cvCenterText)
		{
			PrintCenterText(client, "It's taking a bit longer than expected.\nYou might respawn in 3 seconds.");
		}
	}
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}
/* Stocks ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

// Check if a client is valid or not.
bool IsValidClient(int client, bool bots)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (!bots && IsFakeClient(client)))
	{
		return false;
	}

	return IsClientInGame(client);
}

// Check if a client has a required admin flag.
bool DoesClientHaveRequiredFlag(int client)
{
	AdminId g_admAdminId = GetUserAdmin(client);

	if (g_admAdminId != INVALID_ADMIN_ID)
	{
		char g_sAdminFlag[1];
		AdminFlag g_admAdminFlag;

		for (int i = 0; i < g_alAdminFlags.Length; i++)
		{
			g_alAdminFlags.GetString(i, g_sAdminFlag, sizeof(g_sAdminFlag));
			FindFlagByChar(g_sAdminFlag[0], g_admAdminFlag);

			if (g_admAdminId.HasFlag(g_admAdminFlag, Access_Effective) || g_admAdminId.HasFlag(Admin_Root, Access_Effective))
			{
				return true;
			}
			else
			{
				continue;
			}
		}
	}

	return false;
}

// Create the respawn timer.
void CreateRespawnTimer(int client)
{	
	g_hTimer[client] = CreateTimer(g_cvRespawnTime + 6.0, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(6.0, Timer_RespawnHint, client, TIMER_FLAG_NO_MAPCHANGE);

}