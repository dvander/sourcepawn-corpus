#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>

#define PLUGIN_NAME "[L4D2] Defib Death Model"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Defib death models like in Rayman's admin system."
#define PLUGIN_VERSION "1.1.6"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2691204"
#define PLUGIN_NAME_SHORT "Defib Death Model"
#define PLUGIN_NAME_TECH "defib_death_model"
// Fixed black and white cvar not applying to autodefibbing when there is no temporary godmode
#define DEATH_MODEL_CLASS "survivor_death_model"

#define GAMEDATA "l4d2_defibmodel"
#define AUTOEXEC_CFG "l4d2_defibmodel_cvars"

#define INCAP_CVAR "survivor_max_incapacitated_count"
ConVar incap_cvar;

static int g_iSelectedTarget[MAXPLAYERS+1] = -1;
// Credits to Silvers V
//static Handle g_hTimerRespawn[MAXPLAYERS+1] = null;
//static Handle g_hTempGod[MAXPLAYERS+1] = null;
// end
static float g_fTimerRespawn[MAXPLAYERS+1] = -1.0;
static bool g_bTimerRespawn[MAXPLAYERS+1] = false;
static int g_iChosenBody[MAXPLAYERS+1] = -1;

static bool g_bIsVScript[MAXPLAYERS+1] = false;

static float g_fTempGod[MAXPLAYERS+1] = -1.0;
static bool g_bTempGod[MAXPLAYERS+1] = false;

// v To prevent survivors from getting defibbed over and over again if they fell into a death zone
static float g_fTimeTilSafe[MAXPLAYERS+1] = -1.0;
static int g_iNumOfDeathOnAD[MAXPLAYERS+1] = 0;

static float g_vPeriodicLoc[MAXPLAYERS+1][3];

#define POST_THINK_HOOK SDKHook_PostThink

static float g_fClientWait[MAXPLAYERS+1] = 0.0;
#define THINK_WAITTIME 0.5

TopMenu hTopMenu;

//static const String:MODEL_NICK[] = "models/survivors/survivor_gambler.mdl";
//static const String:MODEL_ROCHELLE[] = "models/survivors/survivor_producer.mdl";
//static const String:MODEL_COACH[] = "models/survivors/survivor_coach.mdl";
//static const String:MODEL_ELLIS[] = "models/survivors/survivor_mechanic.mdl";
//static const String:MODEL_BILL[] = "models/survivors/survivor_namvet.mdl";
//static const String:MODEL_ZOEY[] = "models/survivors/survivor_teenangst.mdl";
//static const String:MODEL_LOUIS[] = "models/survivors/survivor_manager.mdl";
//static const String:MODEL_FRANCIS[] = "models/survivors/survivor_biker.mdl";

ConVar Defib_AutoTimer;
ConVar Defib_AutoTimerMode;
ConVar Defib_TempGodTimer;
ConVar Defib_AutoTimerTeleport;
ConVar Defib_AutoTimerBAW;
ConVar Defib_AutoTimerSpawnKill;
ConVar Defib_AutoTimerSafety;

#define BITFLAG_BAW_AUTO (1 << 0)
#define BITFLAG_BAW_NONAUTO (1 << 1)

Handle hConf = null;
static Handle hOnRevivedByDefibrillator = null;
#define NAME_OnRevivedByDefibrillator "CTerrorPlayer::OnRevivedByDefibrillator"

#define SIG_OnRevivedByDefibrillator_LINUX "@_ZN13CTerrorPlayer24OnRevivedByDefibrillatorEPS_P19CSurvivorDeathModel"
#define SIG_OnRevivedByDefibrillator_WINDOWS "\\x55\\x8B\\x2A\\x83\\x2A\\x34\\x53\\x56\\x8B\\x2A\\x8A"

// PUBLIC Start // -------------------------------------------------------- //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

ConVar version_cvar;

public void OnPluginStart()
{
	char temp_str[128];
	char desc_str[1024];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	version_cvar = CreateConVar("sm_defib_death_model_new_version", PLUGIN_VERSION, desc_str, FCVAR_NONE|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	incap_cvar = FindConVar(INCAP_CVAR);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_autotimer", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "0.0 = Off. | Automatic timer for defibbing each player that died within the defined time limit.");
	Defib_AutoTimer = CreateConVar(temp_str, "0.0", desc_str, FCVAR_NONE, true, 0.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_autotimer_mode", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "0 = VScript. 1 = Signature. | Choose an automatic timer mode.");
	Defib_AutoTimerMode = CreateConVar(temp_str, "1", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_autodefib_god", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "0.0 = Off. | How long the temporary godmode lasts from autodefib, in seconds.");
	Defib_TempGodTimer = CreateConVar(temp_str, "5.0", desc_str, FCVAR_NONE, true, 0.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_autodefib_teleport", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "0 = Off. 1 = Teleport autodefibbed survivors to closest survivor on ground. 2 = Periodically save location on ground.");
	Defib_AutoTimerTeleport = CreateConVar(temp_str, "0", desc_str, FCVAR_NONE, true, 0.0, true, 2.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_blackandwhite", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "Whether to make players defibbed by this plugin black-and-white. 0 = Disable. 1 | BaW on AutoDefib + 2 | BaW on Manual Defib");
	Defib_AutoTimerBAW = CreateConVar(temp_str, "0", desc_str, FCVAR_NONE, true, 0.0, true, 3.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_autodefib_spawnkill", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "0 = Off. | How much spawnkill deaths are allowed until auto-defib stops defibbing a victim dying after defib/godmode ends?");
	Defib_AutoTimerSpawnKill = CreateConVar(temp_str, "2", desc_str, FCVAR_NONE, true, 0.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_autodefib_safetytimer", PLUGIN_NAME_TECH);
	strcopy(desc_str, sizeof(desc_str), "How long the 'check for safety' timer lasts.");
	Defib_AutoTimerSafety = CreateConVar(temp_str, "1.5", desc_str, FCVAR_NONE, true, 0.5);
	
	// Credits to Silvers V
	HookEvent("round_end", round_end);
	// end
	HookEvent("player_death", player_death);
	HookEvent("player_bot_replace", player_bot_replace);
	HookEvent("bot_player_replace", bot_player_replace);
	
	RegAdminCmd("sm_defib", InitiateMenuAdminDefib_ChooseModel, ADMFLAG_SLAY, "Open a menu with a list of dead bodies to defibrillate. Defibs via Signature.");
	RegAdminCmd("sm_vdefib", InitiateMenuAdminDefib_VScript, ADMFLAG_SLAY, "Open a menu with a list of dead bodies to defibrillate. Defibs via VScript.");
	RegAdminCmd("sm_autodefib", InitiateAdminDefib_Auto, ADMFLAG_SLAY, "sm_autodefib <mode> - 0 | nearest index. 1 <default> | check for same character. 2 | check for same model. - Choose a dead person and body to defib. Defibs via Signature.");
	RegAdminCmd("sm_telebody", TeleBody, ADMFLAG_SLAY, "Teleport all dead bodies to your position.");
	GetGamedata();
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	
	CreateTimer(1.0, PeriodicVecCheck, _, TIMER_REPEAT);
}

public void OnMapStart()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (g_fClientWait[client] >= THINK_WAITTIME)
		{
			g_fClientWait[client] = 0.0;
		}
	}
}

// Credits to Silvers V
public void OnMapEnd()
{
	/*for (int i = 1; i <= MaxClients; i++ )
	{
		CloseHandle(g_hTimerRespawn[i]);
		CloseHandle(g_hTempGod[i]);
	}*/
	for (int i = 1; i <= MaxClients; i++ )
	{
		g_bTimerRespawn[i] = false;
		g_bTempGod[i] = false;
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_fClientWait[i] >= THINK_WAITTIME)
		{
			g_fClientWait[i] = 0.0;
		}
	}
}
// end

// PUBLIC End // -------------------------------------------------------- //

#define PLUGIN_SCRIPTLOGIC "plugin_scripting_logic_entity"

void Logic_RunScript(const char[] sCode, any ...) 
{
	int iScriptLogic = FindEntityByTargetname(-1, PLUGIN_SCRIPTLOGIC);
	if (!iScriptLogic || !IsValidEntity(iScriptLogic))
	{
		iScriptLogic = CreateEntityByName("logic_script");
		DispatchKeyValue(iScriptLogic, "targetname", PLUGIN_SCRIPTLOGIC);
		DispatchSpawn(iScriptLogic);
	}
	
	char sBuffer[512]; 
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2); 
	
	SetVariantString(sBuffer); 
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

int FindEntityByTargetname(int index, const char[] findname, bool onlyNetworked = false)
{
	for (int i = index; i < (onlyNetworked ? GetMaxEntities() : (GetMaxEntities()*2)); i++) {
		if (!IsValidEntity(i)) continue;
		char name[128];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (!StrEqual(name, findname, false)) continue;
		return i;
	}
	return -1;
}

// SIGNATURE Start // -------------------------------------------------------- //

void DefibSurvivorAndModel(int client, int reviver, int model)
{
	if (!IsValidClient(client) || !IsValidClient(reviver) || !IsValidEntity(model)) return;
	
	char class[64];
	GetEntityClassname(model, class, sizeof(class));
	if (!StrEqual(class, DEATH_MODEL_CLASS, false)) return;
	
	SDKCall(hOnRevivedByDefibrillator, client, reviver, model);
	
	if (IsPlayerAlive(client) && (GetConVarInt(Defib_AutoTimerBAW) & BITFLAG_BAW_NONAUTO))
	{
		int incap_cv_int = GetConVarInt(incap_cvar);
		
		if (incap_cv_int > 0)
		{ Logic_RunScript("GetPlayerFromUserID(%d).SetReviveCount(%i)", GetClientUserId(client), incap_cv_int); }
		ConvertHPToTemp(client);
	}
}

Action InitiateMenuAdminDefib_ChooseModel(int client, int args)  
{
	if (!IsValidClient(client))  
	{ 
		ShowWarning(client, -1);
		return Plugin_Handled; 
	} 
	
	char name[32]; char number[10];
	
	Handle menu = CreateMenu(ShowMenu_ChooseModel);
	//SetMenuTitle(menu, "Defib survivor:"); 
	SetMenuTitle(menu, "Choose dead body:"); 
	
	bool hasEnt = false;
	for (int i = 1; i <= GetMaxEntities()*2; i++) // Get Survivor Models
	{
		if (!IsValidEntity(i)) continue;
		char class[64];
		GetEntityClassname(i, class, sizeof(class));
		if (!StrEqual(class, DEATH_MODEL_CLASS, false)) continue;
		
		int character = GetEntProp(i, Prop_Send, "m_nCharacterType");
		
		GetCharacterName(character, name, sizeof(name));
		
		Format(number, sizeof(number), "%i", EntRefToEntIndex(i));
		AddMenuItem(menu, number, name);
		if (!hasEnt) hasEnt = true;
		//PrintToChat(client, "Entity: %i, Converted: %s", i, number);
	}
	if (!hasEnt) 
	ShowWarning(client, 4);
	
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER); 
	
	return Plugin_Handled;
}

int ShowMenu_ChooseModel(Handle menu, MenuAction action, int client, int param2)  
{ 
	switch (action)  
	{ 
		case MenuAction_Select:
		{
			if (!IsValidClient(client)) return;
			
			char param2_str[12];
			GetMenuItem(menu, param2, param2_str, sizeof(param2_str));
			
			int chosen_mdl = StringToInt(param2_str);
			
			if (!IsValidEntity(chosen_mdl))
			{ CreateTimer(0.15, TimerOpenMenu_Sig, client); ShowWarning(client, 1); return; }
			
			char class[128];
			GetEntityClassname(chosen_mdl, class, sizeof(class));
			if (!StrEqual(class, DEATH_MODEL_CLASS, false)) { ShowWarning(client, 1); return; }
			
			g_iSelectedTarget[client] = EntIndexToEntRef(chosen_mdl);
			
			//PrintToChat(client, "[SM] Selected a dead body with index: %i", StringToInt(param2_str));
			
			InitiateMenuAdminDefib_ChooseClient(client);
		} 
		case MenuAction_Cancel: 
		{ 
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
			}
		} 
		case MenuAction_End:  
		{
			CloseHandle(menu); 
		}
	}
}

void InitiateMenuAdminDefib_ChooseClient(int client)
{
	if (!IsValidClient(client))  
	{
		ShowWarning(client, -1);
		return;
	}
	
	char name[MAX_NAME_LENGTH]; char number[10];
	
	Handle menu = CreateMenu(ShowMenu_ChooseClient);
	SetMenuTitle(menu, "Defib survivor:"); 
	
	bool hasEnt = false;
	for (int i = 1; i <= MaxClients; i++) // Get Clients
	{
		if (!IsSurvivor(i) || IsPlayerAlive(i)) continue;
		
		GetClientName(i, name, sizeof(name));
		
		char temphp[32];
		if (IsPlayerAlive(i) && HasEntProp(i, Prop_Send, "m_healthBuffer"))
		{
			float temphp_fl = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
			if (temphp_fl > 0.0)
			Format(temphp, sizeof(temphp), "+T%i", RoundToCeil(temphp_fl));
		}
		
		int hp = GetClientHealth(i);
		
		char status[128]; strcopy(status, sizeof(status), "");
		if (IsPlayerAlive(i) && IsIncapacitated(i))
		{ Format(status, sizeof(status), "[DOWN] %i", hp); }
		else if (IsPlayerAlive(i))
		{ Format(status, sizeof(status), "%i", hp); }
		else
		{ strcopy(status, sizeof(status), "DEAD"); }
		
		char team_str[16]; strcopy(team_str, sizeof(team_str), "");
		if (IsPassingSurvivor(i))
		{ strcopy(team_str, sizeof(team_str), "T4 "); }
		
		int character = GetEntProp(i, Prop_Send, "m_survivorCharacter");
		
		char charletter[6];
		GetCharacterLetter(character, charletter, sizeof(charletter));
		Format(charletter, sizeof(charletter), " %s", charletter); 
		
		char name_and_hp[MAX_NAME_LENGTH+64];
		Format(name_and_hp, sizeof(name_and_hp), "%s (%s%s%s%s)", name, team_str, status, temphp, charletter);
		
		Format(number, sizeof(number), "%i", GetClientUserId(i)); 
		AddMenuItem(menu, number, name_and_hp);
		if (!hasEnt) hasEnt = true;
	}
	if (!hasEnt) 
	ShowWarning(client, 5);
	
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return;
}

int ShowMenu_ChooseClient(Handle menu, MenuAction action, int client, int param2)  
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(client)) return;
			
			char number[4]; 
			GetMenuItem(menu, param2, number, sizeof(number)); 
			
			int body = EntRefToEntIndex(g_iSelectedTarget[client]);
			if (!IsValidEntity(body))
			{ ShowWarning(client, 2); return; }
			
			int target = GetClientOfUserId(StringToInt(number));
			if (!IsValidClient(target))
			{ ShowWarning(client, 0); return; }
			
			PrintToChat(client, "[SM] Revived %N using a dead body with index: %i", target, EntRefToEntIndex(body));
			
			DefibSurvivorAndModel(target, client, body);
			CreateTimer(0.15, TimerOpenMenu_Sig, client);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu); 
		}
	}
}

Action TimerOpenMenu_Sig(Handle timer, int client)
{
	if (!DoesEntityWithClassExist(DEATH_MODEL_CLASS)) return;
	InitiateMenuAdminDefib_ChooseModel(client, 0);
}

// SIGNATURE End // -------------------------------------------------------- //
// VSCRIPT Start // -------------------------------------------------------- //

Action InitiateMenuAdminDefib_VScript(int client, int args)  
{ 
	if (!IsValidClient(client))  
	{ 
		ShowWarning(client, -1);
		return Plugin_Handled; 
	} 
	
	char name[32]; char number[10]; 
	
	Handle menu = CreateMenu(ShowMenu);
	//SetMenuTitle(menu, "Defib survivor:"); 
	SetMenuTitle(menu, "Defib dead body:"); 
	
	bool hasEnt = false;
	for (int i = 1; i <= GetMaxEntities()*2; i++) // Get Survivor Models
	{
		if (!IsValidEntity(i)) continue;
		char class[64];
		GetEntityClassname(i, class, sizeof(class));
		if (StrEqual(class, DEATH_MODEL_CLASS, false))
		{
			int character = GetEntProp(i, Prop_Send, "m_nCharacterType");
			
			GetCharacterName(character, name, sizeof(name));
			
			Format(number, sizeof(number), "%i", EntRefToEntIndex(i));
			AddMenuItem(menu, number, name);
			if (!hasEnt) hasEnt = true;
		}
	}
	if (!hasEnt) 
	ShowWarning(client, 4);
	
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER); 
	
	return Plugin_Handled;
}

int ShowMenu(Handle menu, MenuAction action, int client, int param2)  
{ 
	switch (action)  
	{ 
		case MenuAction_Select:  
		{ 
			char number[4]; 
			GetMenuItem(menu, param2, number, sizeof(number)); 
			
			int ref = EntIndexToEntRef(StringToInt(number));
			if (!IsValidEntity(ref))
			{ CreateTimer(0.15, TimerOpenMenu_VScript, client); return; }
					
			int character = GetEntProp(ref, Prop_Send, "m_nCharacterType");
			for (int i = 1; i <= MaxClients; i++) // Survivor Model
			{
				if (!IsSurvivor(i) || IsPlayerAlive(i)) continue;
				
				int cl_char = GetEntProp(i, Prop_Send, "m_survivorCharacter");
				if (cl_char != character)
				continue;
				
				Logic_RunScript("GetPlayerFromUserID(%d).ReviveByDefib()", GetClientUserId(i));
				CreateTimer(0.15, TimerOpenMenu_VScript, client);
				return;
			}
			/*int target = GetClientOfUserId(StringToInt(number));
			
			if (!IsClientInGame(target) || IsPlayerAlive(target) || (GetClientTeam(target) != 2 && GetClientTeam(target) != 4))
			return;
			
			Logic_RunScript("GetPlayerFromUserID(%d).ReviveByDefib()", GetClientUserId(target));*/
		} 
		case MenuAction_Cancel: 
		{ 
			if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
			{
				DisplayTopMenu(hTopMenu, client, TopMenuPosition_LastCategory);
			}			
		} 
		case MenuAction_End:  
		{ 
			CloseHandle(menu); 
		} 
	} 
}

Action TimerOpenMenu_VScript(Handle timer, int client)
{
	if (!DoesEntityWithClassExist(DEATH_MODEL_CLASS)) return;
	InitiateMenuAdminDefib_VScript(client, 0);
}

// VSCRIPT End // -------------------------------------------------------- //
// AUTO SIG Start // -------------------------------------------------------- //

Action InitiateAdminDefib_Auto(int client, int args)  
{
	char arg[2];
	GetCmdArg(1, arg, sizeof(arg));
	int arg_int = -1;
	if (!arg[0])
	{ arg_int = 1; }
	else
	{ arg_int = StringToInt(arg); }
	
	int bodyEnt = -1;
	int clientEnt = -1;
	
	for (int i = 1; i <= MaxClients; i++) // Get Clients
	{
		if (!IsSurvivor(i) || IsPlayerAlive(i)) continue;
		
		clientEnt = i;
		break;
	}
	
	//int temp = FindEntityByClassname(-1, DEATH_MODEL_CLASS);
	//if (temp && IsValidEntity(temp)) bodyEnt = temp;
	for (int i = 1; i <= GetMaxEntities()*2; i++) // Get Survivor Models
	{
		if (!IsValidEntity(i)) continue;
		char class[64];
		GetEntityClassname(i, class, sizeof(class));
		if (!StrEqual(class, DEATH_MODEL_CLASS, false)) continue;
		
		if ((arg_int & 1) && !ClientAndBodySameChar(clientEnt, i)) continue;
		if ((arg_int & 2) && !ClientAndBodySameModel(clientEnt, i)) continue;
		
		bodyEnt = i;
		break;
	}
	
	bool hasFailed = false;
	if (!IsValidEntity(bodyEnt) && !IsValidClient(clientEnt))
	{ ShowWarning(client, 6); hasFailed = true; }
	else if (!IsValidClient(clientEnt))
	{ ShowWarning(client, 5); hasFailed = true; }
	else if (!IsValidEntity(bodyEnt))
	{ ShowWarning(client, 4); hasFailed = true; }
	
	if (hasFailed) return Plugin_Handled;
	
	DefibSurvivorAndModel(clientEnt, clientEnt, bodyEnt);
	
	return Plugin_Handled;
}

// AUTO SIG End // -------------------------------------------------------- //
// TELEBODY Start // -------------------------------------------------------- //

Action TeleBody(int client, int args)
{
	if (!IsValidClient(client))  
	{
		ShowWarning(client, -1);
		return Plugin_Handled;
	}
	
	for (int i = 1; i <= GetMaxEntities()*2; i++) // Get Survivor Models
	{
		if (!IsValidEntity(i)) continue;
		char class[64];
		GetEntityClassname(i, class, sizeof(class));
		if (!StrEqual(class, DEATH_MODEL_CLASS, false)) continue;
		
		float origin[3];
		GetClientAbsOrigin(client, origin);
		
		TeleportEntity(i, origin, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Handled;
}

// TELEBODY End // -------------------------------------------------------- //
// AUTOTIMER Start // -------------------------------------------------------- //

// Credits to Silvers V
void round_end(Event event, const char[] name, bool dontBroadcast)
{
	/*for (int i = 1; i <= MaxClients; i++)
	{
		CloseHandle(g_hTimerRespawn[i]);
		CloseHandle(g_hTempGod[i]);
	}*/
	for (int i = 1; i <= MaxClients; i++ )
	{
		g_bTimerRespawn[i] = false;
		g_bTempGod[i] = false;
	}
}
// end

void player_bot_replace(Event event, const char[] name, bool dontBroadcast) // Bot replaced a player
{
	//PrintToChatAll("player_bot_replace:");
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	
	//PrintToChatAll("BEFORE: client g_fTimerRespawn: %f, bot g_fTimerRespawn: %f", g_fTimerRespawn[client], g_fTimerRespawn[bot]);
	SwapTimers(client, bot);
	HookThink(client);
	HookThink(bot);
	//PrintToChatAll("AFTER: client g_fTimerRespawn: %f, bot g_fTimerRespawn: %f", g_fTimerRespawn[client], g_fTimerRespawn[bot]);
}

void bot_player_replace(Event event, const char[] name, bool dontBroadcast) // Player replaced a bot
{
	//PrintToChatAll("bot_player_replace:");
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	
	//PrintToChatAll("BEFORE: client g_fTimerRespawn: %f, bot g_fTimerRespawn: %f", g_fTimerRespawn[client], g_fTimerRespawn[bot]);
	SwapTimers(bot, client);
	HookThink(bot);
	HookThink(client);
	//PrintToChatAll("AFTER: client g_fTimerRespawn: %f, bot g_fTimerRespawn: %f", g_fTimerRespawn[client], g_fTimerRespawn[bot]);
}

/*void Move1stTimersTo2ndTimers(int client, int other)
{
	g_fTimerRespawn[other] = g_fTimerRespawn[client];
	g_bTimerRespawn[other] = g_bTimerRespawn[client];
	g_iChosenBody[other] = g_iChosenBody[client];
	
	g_bIsVScript[other] = g_bIsVScript[client];
	
	g_fTempGod[other] = g_fTempGod[client];
	g_bTempGod[other] = g_bTempGod[client];
	g_fTimeTilSafe[other] = g_fTimeTilSafe[client];
	g_iNumOfDeathOnAD[other] = g_iNumOfDeathOnAD[client];
}*/

void SwapTimers(int client, int other)
{
	// yes, this is messy, but idk what else to do :(
	float g_fTimerRespawn_backup = g_fTimerRespawn[other];
	bool g_bTimerRespawn_backup = g_bTimerRespawn[other];
	int g_iChosenBody_backup = g_iChosenBody[other];
	
	bool g_bIsVScript_backup = g_bIsVScript[other];
	
	float g_fTempGod_backup = g_fTempGod[other];
	bool g_bTempGod_backup = g_bTempGod[other];
	float g_fTimeTilSafe_backup = g_fTimeTilSafe[other];
	int g_iNumOfDeathOnAD_backup = g_iNumOfDeathOnAD[other];
	// Backup the timers for other
	
	// Set the timers of 'other' to 'client'
	g_fTimerRespawn[other] = g_fTimerRespawn[client];
	g_bTimerRespawn[other] = g_bTimerRespawn[client];
	g_iChosenBody[other] = g_iChosenBody[client];
	
	g_bIsVScript[other] = g_bIsVScript[client];
	
	g_fTempGod[other] = g_fTempGod[client];
	g_bTempGod[other] = g_bTempGod[client];
	g_fTimeTilSafe[other] = g_fTimeTilSafe[client];
	g_iNumOfDeathOnAD[other] = g_iNumOfDeathOnAD[client];

	
	// Then use the backed-up 'other' variables for 'client'
	g_fTimerRespawn[client] = g_fTimerRespawn_backup;
	g_bTimerRespawn[client] = g_bTimerRespawn_backup;
	g_iChosenBody[client] = g_iChosenBody_backup;
	
	g_bIsVScript[client] = g_bIsVScript_backup;
	
	g_fTempGod[client] = g_fTempGod_backup;
	g_bTempGod[client] = g_bTempGod_backup;
	g_fTimeTilSafe[client] = g_fTimeTilSafe_backup;
	g_iNumOfDeathOnAD[client] = g_iNumOfDeathOnAD_backup;
}

/*void ClearTimers(int client)
{
	g_fTimerRespawn[client] = -1.0;
	g_bTimerRespawn[client] = false;
	g_iChosenBody[client] = -1;
	
	g_bIsVScript[client] = false;
	
	g_fTempGod[client] = -1.0;
	g_bTempGod[client] = false;
	g_fTimeTilSafe[client] = -1.0;
	g_iNumOfDeathOnAD[client] = 0;
}*/

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	float cvar_time = GetConVarFloat(Defib_AutoTimer);
	if (cvar_time <= 0.0) return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client)) return;
	
	//CloseHandle(g_hTimerRespawn[client]);
	//CloseHandle(g_hTempGod[client]);
	g_bTimerRespawn[client] = false;
	g_bTempGod[client] = false;
	
	if (!IsSurvivor(client) || IsPlayerAlive(client)) return;
	
	float game_time = GetGameTime();
	
	int max_deaths = GetConVarInt(Defib_AutoTimerSpawnKill);
	if (max_deaths > 0)
	{
		// Check if the 'time til safe' timer is still active when the player died...
		if (g_fTimeTilSafe[client] > game_time)
		{
			g_iNumOfDeathOnAD[client]++;
			if (g_iNumOfDeathOnAD[client] >= max_deaths)
			{
				PrintToChat(client, "You will no longer be auto-defibbed again.");
				g_fTimeTilSafe[client] = -1.0;
				g_iNumOfDeathOnAD[client] = 0;
				return;
			}
			else
			{
				int deaths_remaining = max_deaths-g_iNumOfDeathOnAD[client];
				
				char temp_str[2];
				if (deaths_remaining != 1)
				{ strcopy(temp_str, sizeof(temp_str), "s"); }
				
				PrintToChat(client, "You died whilst you were getting auto-defibbed. %i more death%s until your auto-defib stops.", 
				deaths_remaining, temp_str);
			}
		}
		else
		{
			g_iNumOfDeathOnAD[client] = 0;
		}
	}
	
	if (GetConVarBool(Defib_AutoTimerMode))
	{
		g_bIsVScript[client] = false;
		g_iChosenBody[client] = GetSpawnedBodyForSurvivor(client);
	}
	else
	{
		g_bIsVScript[client] = true;
	}
	
	g_fTimerRespawn[client] = game_time+cvar_time;
	g_bTimerRespawn[client] = true;
	
	HookThink(client);
	
	/*if (GetConVarBool(Defib_AutoTimerMode))
	{
		// If true, use Signature.
		int body = GetSpawnedBodyForSurvivor(client);
		
		DataPack data = CreateDataPack();
		data.WriteCell(client);
		data.WriteCell(body);
		g_hTimerRespawn[client] = CreateTimer(cvar_time, AutoTimer_Defib, data, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{ g_hTimerRespawn[client] = CreateTimer(cvar_time, AutoTimer_DefibVScript, client, TIMER_FLAG_NO_MAPCHANGE); } // Choose VScript*/
}

/*Action AutoTimer_DefibVScript(Handle timer, int client)
{
	if (!IsValidClient(client)) return;
	g_hTimerRespawn[client] = null;
	if (!IsSurvivor(client)) return;
	
	if (!IsPlayerAlive(client))
	{
		Logic_RunScript("GetPlayerFromUserID(%d).ReviveByDefib()", GetClientUserId(client));
		if (IsPlayerAlive(client))
		{ GiveTempGod(client); }
	}
}

Action AutoTimer_Defib(Handle timer, DataPack data)
{
	data.Reset();
	int client = data.ReadCell();
	int body = data.ReadCell();
	if (data != null)
	{ CloseHandle(data); }
	//PrintToChatAll("%i", body);
	if (!IsValidClient(client) || !IsValidEntity(body)) return;
	g_hTimerRespawn[client] = null;
	
	DefibSurvivorAndModel(client, client, body);
	GiveTempGod(client);
}*/
// end

// AUTOTIMER End // -------------------------------------------------------- //
// Non-Handle Timers Start // -------------------------------------------------------- //

void HookThink(int entity, bool boolean = true)
{
    if (!IsValidClient(entity)) return;
    if (boolean)
    { SDKHook(entity, POST_THINK_HOOK, Hook_OnThinkPost); g_fClientWait[entity] = 0.0; }
    else
    { SDKUnhook(entity, POST_THINK_HOOK, Hook_OnThinkPost); }
}

void Hook_OnThinkPost(int client)
{
	if (!IsServerProcessing()) return;
	
	if (IsValidClient(client))
	{
		if (GetGameTime() - g_fClientWait[client] >= 0.0)
		{
			UpdateTimers(client);
			g_fClientWait[client] = g_fClientWait[client] + THINK_WAITTIME;
		}
	}
}

void UpdateTimers(int client)
{
	float game_time = GetGameTime();
	
	if (g_fTimerRespawn[client] <= game_time && g_bTimerRespawn[client])
	{
		Timer_TimerRespawn(client);
		g_bTimerRespawn[client] = false;
		g_fTimerRespawn[client] = -1.0;
	}
	if (g_fTempGod[client] <= game_time && g_bTempGod[client])
	{
		Timer_TempGod(client);
		g_bTempGod[client] = false;
		g_fTempGod[client] = -1.0;
	}
	
	if (!g_bTimerRespawn[client] && !g_bTempGod[client])
	{ HookThink(client, false); }
}

void Timer_TimerRespawn(int client)
{
	// We update the 'time til safe' timer when either this timer or the godmode timer ends
	float game_time = GetGameTime();
	g_fTimeTilSafe[client] = game_time+GetConVarFloat(Defib_AutoTimerSafety);
	
	if (g_bIsVScript[client])
	{ Timer_TimerRespawn_VScript(client); }
	else
	{ Timer_TimerRespawn_Sig(client); }
}

void Timer_TimerRespawn_Sig(int client)
{
	int body = g_iChosenBody[client];
	
	if (!IsSurvivor(client) || (body <= 0 || !IsValidEntity(body))) return;
	g_iChosenBody[client] = -1;
	
	DefibSurvivorAndModel(client, client, body);
	GiveTempGod(client);
	TimerRespawn_TeleClientToOther(client);
}

void Timer_TimerRespawn_VScript(int client)
{
	if (!IsSurvivor(client)) return;
	
	if (!IsPlayerAlive(client))
	{
		Logic_RunScript("GetPlayerFromUserID(%d).ReviveByDefib()", GetClientUserId(client));
		if (IsPlayerAlive(client))
		{
			GiveTempGod(client);
			TimerRespawn_TeleClientToOther(client);
		}
	}
}

void TimerRespawn_TeleClientToOther(int client)
{
	int cvar_int = GetConVarInt(Defib_AutoTimerTeleport);
	if (cvar_int <= 0) return;
	
	switch (cvar_int)
	{
		case 1:
		{
			float cl_origin[3];
			GetClientAbsOrigin(client, cl_origin);
			int nearest_surv = GetNearestGroundSurvivor(cl_origin);
			if (IsGameSurvivor(nearest_surv))
			{
				float other_origin[3];
				GetClientAbsOrigin(nearest_surv, other_origin);
				TeleportEntity(client, other_origin, NULL_VECTOR, NULL_VECTOR);
			}
			return;
		}
		case 2:
		{
			float periodic_Loc[3]; periodic_Loc = g_vPeriodicLoc[client];
			if (periodic_Loc[0] == 0.0 && periodic_Loc[1] == 0.0 && periodic_Loc[2] == 0.0) return;
			
			TeleportEntity(client, periodic_Loc, NULL_VECTOR, NULL_VECTOR);
			return;
		}
	}
}

void Timer_TempGod(int client)
{
	if (!IsSurvivor(client)) return;
	float game_time = GetGameTime();
	g_fTimeTilSafe[client] = game_time+GetConVarFloat(Defib_AutoTimerSafety);
	
	g_bTempGod[client] = false;
	
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	PrintToChat(client, "Your temporary godmode has ran out.");
	if (GetConVarInt(incap_cvar) > 0 && !(GetConVarInt(Defib_AutoTimerBAW) & BITFLAG_BAW_AUTO))
	{
		Logic_RunScript("GetPlayerFromUserID(%d).SetReviveCount(0)", GetClientUserId(client));
	}
	else if (GetConVarInt(Defib_AutoTimerBAW) & BITFLAG_BAW_AUTO)
	{
		ConvertHPToTemp(client);
	}
}

// Non-Handle Timers End // -------------------------------------------------------- //
// Teleport Mode 2 Start // -------------------------------------------------------- //

Action PeriodicVecCheck(Handle timer)
{
	if (!IsServerProcessing())
	{ return; }
	
	if (GetConVarInt(Defib_AutoTimerTeleport) < 2) return;
	
	Timer_PeriodicLoc();
}

void Timer_PeriodicLoc()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsIncapacitated(client)) continue;
		if (!HasEntProp(client, Prop_Send, "m_hGroundEntity") || GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0) continue;
		//int ground = GetEntProp(client, Prop_Send, "m_hGroundEntity");
		
		float game_time = GetGameTime();
		if (g_bTempGod[client] || (g_fTempGod[client]+1.0) > game_time) continue;
		
		float cl_origin[3];
		GetClientAbsOrigin(client, cl_origin);
		float cl_origin_end[3]; cl_origin_end[0] = cl_origin[0]; cl_origin_end[1] = cl_origin[1];cl_origin_end[2] = (cl_origin[2]-10.0);
		TR_TraceRayFilter(cl_origin, 
		cl_origin_end, 
		MASK_SOLID, 
		RayType_EndPoint, 
		TraceRayHitOnlyWorld);
		
		if (!TR_DidHit()) continue;
		
		g_vPeriodicLoc[client] = cl_origin;
	}
}

bool TraceRayHitOnlyWorld(int entity, int mask)
{
	if (entity == 0)
	{
		return true;
	}
	return false;
}

// Teleport Mode 2 End // -------------------------------------------------------- //
// Others Start // -------------------------------------------------------- //

void ConvertHPToTemp(int client)
{
	int health = GetClientHealth(client);
	
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", health+1.0);
	SetEntityHealth(client, 1);
}

int GetNearestGroundSurvivor(const float posToCheck[3])
{
	int result = -1;
	float distance = -1.0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsGameSurvivor(client) || !IsPlayerAlive(client) || IsIncapacitated(client, 1)) continue;
		if (!HasEntProp(client, Prop_Send, "m_hGroundEntity") || GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0) continue;
		if (g_bTempGod[client]) continue;
		
		float cl_origin[3];
		GetClientAbsOrigin(client, cl_origin);
		
		float temp_dis = GetVectorDistance(posToCheck, cl_origin, true);
		if (distance > 0.0 && temp_dis > distance) continue;
		
		result = client;
		distance = temp_dis;
	}
	return result;
}

bool DoesEntityWithClassExist(const char[] class)
{
	int entity = FindEntityByClassname(-1, class);
	if (!entity || !IsValidEntity(entity)) return false;
	return true;
}

void GiveTempGod(int client)
{
	int incap_cv_int = GetConVarInt(incap_cvar);
	float cvar_time = GetConVarFloat(Defib_TempGodTimer);
	if (cvar_time <= 0.0)
	{
		if (GetConVarBool(Defib_AutoTimerBAW))
		{
			if (incap_cv_int > 0)
			{ Logic_RunScript("GetPlayerFromUserID(%d).SetReviveCount(%i)", GetClientUserId(client), incap_cv_int); }
			ConvertHPToTemp(client);
		}
		return;
	}
	
	if (!IsValidClient(client)) return;
	
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
	if (incap_cv_int > 0)
	{ Logic_RunScript("GetPlayerFromUserID(%d).SetReviveCount(%i)", GetClientUserId(client), incap_cv_int); }
	//g_hTempGod[client] = CreateTimer(cvar_time, TempGodTimer, client);
	
	float game_time = GetGameTime();
	
	g_fTempGod[client] = game_time+cvar_time;
	g_bTempGod[client] = true;
}

/*Action TempGodTimer(Handle timer, int client)
{
	if (!IsValidClient(client)) return;
	g_hTempGod[client] = null;
	
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	PrintToChat(client, "Your temporary godmode has ran out.");
	if (GetConVarInt(incap_cvar) > 0)
	{ Logic_RunScript("GetPlayerFromUserID(%d).SetReviveCount(0)", GetClientUserId(client)); }
}*/

void GetCharacterName(int character, char[] str, int maxlen)
{
	if (character == 0)
	{ strcopy(str, maxlen, "Nick"); }
	else
	if (character == 1)
	{ strcopy(str, maxlen, "Rochelle"); }
	else
	if (character == 2)
	{ strcopy(str, maxlen, "Coach"); }
	else
	if (character == 3)
	{ strcopy(str, maxlen, "Ellis"); }
	else
	if (character == 4)
	{ strcopy(str, maxlen, "Bill"); }
	else
	if (character == 5)
	{ strcopy(str, maxlen, "Zoey"); }
	else
	if (character == 6)
	{ strcopy(str, maxlen, "Francis"); }
	else
	if (character == 7)
	{ strcopy(str, maxlen, "Louis"); }
	else
	{ strcopy(str, maxlen, "Unknown"); }
}

void GetCharacterLetter(int character, char[] str, int maxlen)
{
	if (character == 0)
	{ strcopy(str, maxlen, "N"); }
	else
	if (character == 1)
	{ strcopy(str, maxlen, "R"); }
	else
	if (character == 2)
	{ strcopy(str, maxlen, "C"); }
	else
	if (character == 3)
	{ strcopy(str, maxlen, "E"); }
	else
	if (character == 4)
	{ strcopy(str, maxlen, "B"); }
	else
	if (character == 5)
	{ strcopy(str, maxlen, "Z"); }
	else
	if (character == 6)
	{ strcopy(str, maxlen, "F"); }
	else
	if (character == 7)
	{ strcopy(str, maxlen, "L"); }
	else
	{ strcopy(str, maxlen, "?"); }
}

void ShowWarning(int client, int mode = 0)
{
	if (!IsValidClient(client)) return;
	
	switch (mode)
	{
		case -1:
		{ PrintToChatOrServer(client, "[SM] Menu is in-game only."); }
		case 0:
		{ PrintToChatOrServer(client, "[SM] Invalid client!"); }
		case 1:
		{ PrintToChatOrServer(client, "[SM] Invalid body!"); }
		case 2:
		{ PrintToChatOrServer(client, "[SM] Chosen body has since been invalid!"); }
		case 3:
		{ PrintToChatOrServer(client, "[SM] Chosen client has since been invalid!"); }
		case 4:
		{ PrintToChatOrServer(client, "[SM] No dead body found!"); }
		case 5:
		{ PrintToChatOrServer(client, "[SM] No client found!"); }
		case 6:
		{ PrintToChatOrServer(client, "[SM] No client and dead body found!"); }
	}
}

void PrintToChatOrServer(int client, const char[] str, any ...)
{
	char sBuffer[512]; 
	VFormat(sBuffer, sizeof(sBuffer), str, 3); 
	if (IsValidClient(client))
	{
		PrintToChat(client, sBuffer);
	}
	else
	{
		PrintToServer(sBuffer);
	}
}

int GetSpawnedBodyForSurvivor(int client)
{
	int targetBody = -1;
	if (!IsValidClient(client)) { return targetBody; }
	//float deathTime = GetEntPropFloat(client, Prop_Send, "m_flDeathTime");
	
	for (int i = 1; i <= GetMaxEntities()*2; i++) // Get Survivor Models
	{
		if (!IsValidEntity(i)) continue;
		char class[64];
		GetEntityClassname(i, class, sizeof(class));
		if (!StrEqual(class, DEATH_MODEL_CLASS, false)) continue;
		
		/*float createTime = GetEntPropFloat(i, Prop_Send, "m_flCreateTime");
		PrintToChatAll("cT: %f, dT: %f", createTime, deathTime);
		if (createTime != deathTime) continue;*/
		
		if (!ClientAndBodySamePlace(client, i) || !ClientAndBodySameChar(client, i) || !ClientAndBodySameModel(client, i)) continue;
		
		targetBody = i;
		break;
	}
	//PrintToChatAll("%i", targetBody);
	return targetBody;
}

bool ClientAndBodySamePlace(int client, int body)
{
	if (!IsValidClient(client) || !IsValidEntity(body)) return false;
	
	float cl_origin[3], body_origin[3];
	GetClientAbsOrigin(client, cl_origin);
	GetEntPropVector(body, Prop_Send, "m_vecOrigin", body_origin);
	
	//PrintToChatAll("cO: %f %f %f, bO: %f %f %f", cl_origin[0],cl_origin[1],cl_origin[2], body_origin[0],body_origin[1],body_origin[2]);
	
	if (cl_origin[0] != body_origin[0] || cl_origin[1] != body_origin[1] || cl_origin[2] != body_origin[2]) return false;
	return true;
}

bool ClientAndBodySameChar(int client, int body)
{
	if (!IsValidClient(client) || !IsValidEntity(body)) return false;
	int clientChar = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	int bodyChar = -1;
	if (HasEntProp(body, Prop_Send, "m_nCharacterType"))
	{ bodyChar = GetEntProp(body, Prop_Send, "m_nCharacterType"); }
	
	if (clientChar != bodyChar) return false;
	return true;
}

bool ClientAndBodySameModel(int client, int body)
{
	if (!IsValidClient(client) || !IsValidEntity(body)) return false;
	
	/*char clientMDL[PLATFORM_MAX_PATH];
	GetClientModel(client, clientMDL, sizeof(clientMDL));
	char bodyMDL[PLATFORM_MAX_PATH];
	GetEntPropString(body, Prop_Data, "m_ModelName", bodyMDL, sizeof(bodyMDL));*/
	int clientMDL = GetEntProp(client, Prop_Send, "m_nModelIndex");
	int bodyMDL = -1;
	if (HasEntProp(body, Prop_Send, "m_nModelIndex"))
	{ bodyMDL = GetEntProp(body, Prop_Send, "m_nModelIndex"); }
	
	if (clientMDL != bodyMDL) return false;
	return true;
}

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) != 2 && GetClientTeam(client) != 4) return false;
	return true;
}

bool IsGameSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) != 2) return false;
	return true;
}

bool IsPassingSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) != 4) return false;
	return true;
}

bool IsIncapacitated(int client, int hanging = 2)
{
	bool isIncap = view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
	bool isHanging = view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"));
	
	switch (hanging)
	{
		// if hanging is 2, don't care about hanging
		case 2:
		{
			if (isIncap) return true;
		}
		// if 1, check for hanging too
		case 1:
		{
			if (isIncap && isHanging) return true;
		}
		// otherwise, must just be incapped to return true
		case 0:
		{
			if (isIncap && !isHanging) return true;
		}
	}
	return false;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

// Others End // -------------------------------------------------------- //
// Gamedata below // -------------------------------------------------------- //

void GetGamedata()
{
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(filePath) )
	{
		hConf = LoadGameConfigFile(GAMEDATA); // For some reason this doesn't return null even for invalid files, so check they exist first.
	}
	else
	{
		PrintToServer("[SM] %s plugin unable to get %i.txt gamedata file. Generating...", PLUGIN_NAME_SHORT, GAMEDATA);
		
		Handle fileHandle = OpenFile(filePath, "a+");
		if (fileHandle == null)
		{ SetFailState("[SM] Couldn't generate gamedata file!"); }
		
		WriteFileLine(fileHandle, "\"Games\"");
		WriteFileLine(fileHandle, "{");
		WriteFileLine(fileHandle, "	\"left4dead2\"");
		WriteFileLine(fileHandle, "	{");
		WriteFileLine(fileHandle, "		\"Signatures\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_OnRevivedByDefibrillator);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_OnRevivedByDefibrillator_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_OnRevivedByDefibrillator_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_OnRevivedByDefibrillator_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "		}");
		WriteFileLine(fileHandle, "	}");
		WriteFileLine(fileHandle, "}");
		
		CloseHandle(fileHandle);
		hConf = LoadGameConfigFile(GAMEDATA);
		if (hConf == null)
		{ SetFailState("[SM] Failed to load auto-generated gamedata file!"); }
		
		PrintToServer("[SM] %s successfully generated %s.txt gamedata file!", PLUGIN_NAME_SHORT, GAMEDATA);
	}
	PrepSDKCall();
}

void PrepSDKCall()
{
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_OnRevivedByDefibrillator))
	{
	//	if (!PrepSDKCall_SetSignature(SDKLibrary_Server, SIG_OnRevivedByDefibrillator_LINUX, sizeof(SIG_OnRevivedByDefibrillator_LINUX)))
	//	{
	//		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, SIG_OnRevivedByDefibrillator_WINDOWS, sizeof(SIG_OnRevivedByDefibrillator_WINDOWS)))
	//		{ SetFailState("[SM] Failed to set %s signature from config + hardcoded cfg!", NAME_OnRevivedByDefibrillator); }
	//	}
		SetFailState("[SM] Failed to set %s signature from gamedata!", NAME_OnRevivedByDefibrillator);
	}
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hOnRevivedByDefibrillator = EndPrepSDKCall();
	
	if (hOnRevivedByDefibrillator == null)
	{ SetFailState("[SM] Can't get %s SDKCall!", NAME_OnRevivedByDefibrillator); }
}