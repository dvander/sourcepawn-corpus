#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "[L4D] Replicate L4D2 Death Animation"
#define PLUGIN_AUTHOR "Shadowysn"
//#define PLUGIN_DESC "Replicates the death animation and defibrillator from L4D2."
#define PLUGIN_DESC "Replicates the death animation from L4D2."
#define PLUGIN_VERSION "1.0.1"
#define PLUGIN_URL ""
#define PLUGIN_NAME_SHORT "Replicate L4D2 Death Animation"
#define PLUGIN_NAME_TECH "sequel_death_anim"

#define DEATH_MODEL_CLASS "survivor_death_model"
#define DEATH_MODEL_EXTRA "survivor_turning_to_inf"
#define TEMP_ENT "plugin_temp_timer_ent"
#define DEATH_MODEL_VIS "plugin_sdm_vismdl_%i"

#define DEFIB_CLASS "weapon_defibrillator"

#define DEATH_MODEL_HP_PREVENTKILL 999999

#define COMMON_MALE "models/infected/common_male01.mdl"
#define COMMON_FEMALE "models/infected/common_female01.mdl"
#define COMMON_VISMDL_TARGETNAME "infected_survivor_%i"

//#define GAMEDATA "l4d1_replicate_death_model"
#define AUTOEXEC_CFG "l4d1_replicate_death_model"

#define POST_THINK_HOOK SDKHook_PostThinkPost

static float g_fClientWait[MAXPLAYERS+1] = 0.0;
#define THINK_WAITTIME 0.5

#define BITFLAG_BEHAVIOR_HP		(1 << 0)
#define BITFLAG_BEHAVIOR_VEL	(1 << 1)
#define BITFLAG_BEHAVIOR_ZOMB	(1 << 2)

TopMenu hTopMenu;

ConVar RDeathModel_Enable;
//ConVar RDeathModel_EnableDefib;
ConVar RDeathModel_Behavior;
ConVar RDeathModel_ZombieSurvHP;
ConVar RDeathModel_GetUpTime;

static int g_iDeathModel[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;

static float g_fAnimToDoTimer[MAXPLAYERS+1] = -1.0;
static int g_iAnimToDo[MAXPLAYERS+1] = -1;

static bool g_bIsIncapped[MAXPLAYERS+1] = false;

// LMC
native int LMC_GetClientOverlayModel(int client);// remove this and enable the include to compile with the include this is just here for AM compiler


// PUBLIC Start // -------------------------------------------------------- //

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead)
	{
		// LMC
		MarkNativeAsOptional("LMC_GetClientOverlayModel");
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead");
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
	Format(temp_str, sizeof(temp_str), "%s version.", PLUGIN_NAME_SHORT);
	char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, temp_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_enable", PLUGIN_NAME_TECH);
	RDeathModel_Enable = CreateConVar(temp_str, "1.0", "Enable replacing survivor ragdolls with death models?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	//Format(temp_str, sizeof(temp_str), "sm_%s_enable_defib", PLUGIN_NAME_TECH);
	//RDeathModel_EnableDefib = CreateConVar(temp_str, "1.0", "Enable first-aid-kit defibrillators colored yellow?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_behavior", PLUGIN_NAME_TECH);
	RDeathModel_Behavior = CreateConVar(temp_str, "0.0", "Behavior for death models. 0 = L4D2-Style. 1 | Vulnerable Bodies with Health + 2 | Keep Player Velocity + 4 | Zombification", FCVAR_NONE, true, 0.0, true, 
	7);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_zombie_surv_hp", PLUGIN_NAME_TECH);
	RDeathModel_ZombieSurvHP = CreateConVar(temp_str, "500.0", "How much HP will zombified survivors have?", FCVAR_NONE, true, 0.1);
	
	RDeathModel_GetUpTime = CreateConVar("defibrillator_return_to_life_time", "3.0", "How long the plugin holds newly-defibbed players in place?", FCVAR_NONE, true, 0.0);
	
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	HookEvent("player_incapacitated", player_incapacitated, EventHookMode_Post);
	HookEvent("revive_success", revive_success, EventHookMode_Post);
	HookEvent("player_bot_replace", player_bot_replace);
	HookEvent("bot_player_replace", bot_player_replace);
	//HookEvent("player_now_it", player_now_it, EventHookMode_Post);
	
	//HookEvent("infected_hurt", infected_hurt, EventHookMode_Post);
	
	RegAdminCmd("sm_defiballbodies", RDeathModelCmd_DefibAll, ADMFLAG_SLAY, "Defib all bodies.");
	RegAdminCmd("sm_convertallbodies", RDeathModelCmd_ConvertAll, ADMFLAG_SLAY, "Turn all bodies to infected.");
	RegAdminCmd("sm_createdeathmodel", RDeathModelCmd_CreateDeathModel, ADMFLAG_CHEATS, "Spawn a death model of yourself.");
	
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
	AutoExecConfig(true, AUTOEXEC_CFG);
}

/*void player_now_it(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client)) return;
	
	IsOccupied(client);
}*/

/*void infected_hurt(Event event, const char[] name, bool dontBroadcast)
{
	int damage = event.GetInt("amount");
	if (damage <= 0) return;
	
	int infected = event.GetInt("entityid");
	if (!RealValidEntity(infected)) return;
	
	int health = GetEntProp(infected, Prop_Data, "m_iHealth"); //PrintToChatAll("%i", GetEntProp(infected, Prop_Data, "m_lifeState"));
	if ((health - damage) > 0) return;
	
	char temp_str[128];
	Format(temp_str, sizeof(temp_str), COMMON_VISMDL_TARGETNAME, infected);
	
	int vismdl = FindEntityByTargetname(0, temp_str);
	if (!RealValidEntity(vismdl)) return;
	
	AcceptEntityInput(vismdl, "BecomeRagdoll");
	AcceptEntityInput(infected, "Kill");
}*/

public void OnPluginEnd()
{
	int temp_ent = FindEntityByTargetname(0, TEMP_ENT);
	if (RealValidEntity(temp_ent))
	{
		//AcceptEntityInput(temp_ent, "Kill");
	}
	for (int i = 1; i <= MaxClients+1; i++ )
	{
		int body = EntRefToEntIndex(g_iDeathModel[i]);
		
		if (RealValidEntity(body))
		{ AcceptEntityInput(body, "Kill"); }
	}
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

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_fClientWait[i] >= THINK_WAITTIME)
		{
			g_fClientWait[i] = 0.0;
		}
	}
}

/*public void OnEntityCreated(int entity, const char[] classname)
{
	// No need for this.
	if (!GetConVarBool(RDeathModel_Enable))
		return;
	
	if (classname[0] != 'c')
		return;
	
	if (StrEqual(classname, "cs_ragdoll", false))
	{
		//SDKHook(entity, SDKHook_Spawn, SpawnHook_Ragdoll);
		//RequestFrame(SpawnHook_Ragdoll, entity);
		//int possible_owner = GetSurvivorInSameVector();
	}
}*/

/*int GetSurvivorInSameVector(const float posToCheck[3])
{
	int result = -1;
	for (int client = 1; client <= MaxClients; client++) // Get Clients
	{
		if (!IsSurvivor(client)) return;
		
		float origin[3];
		GetClientAbsOrigin(client, origin);
		
		if (origin[0] != posToCheck[0] || origin[1] != posToCheck[1] || origin[2] != posToCheck[2]) continue;
		
		result = client;
		break;
	}
	return result;
}*/

/*void SpawnHook_Ragdoll(int entity)
{
	// This method won't work because the ragdoll already spawned by the time it removes it
	SDKUnhook(entity, SDKHook_Spawn, SpawnHook_Ragdoll);
	if (!RealValidEntity(entity)) return;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
	//PrintToChatAll("m_hPlayer: %i", owner);
	if (!IsSurvivor(owner)) return;
	
	AcceptEntityInput(entity, "Kill");
}*/

// PUBLIC End // -------------------------------------------------------- //
// MENU Start // -------------------------------------------------------- //

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	// Block us from being called twice
	if (topmenu == hTopMenu)
	{ return; }
	
	hTopMenu = topmenu;
	
	if (topmenu == null)
	{ return; }
	
	TopMenuObject player_commands = FindTopMenuCategory(topmenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(topmenu, "sm_givedefibmenu", TopMenuObject_Item, AdminMenu_GiveDefib, player_commands, "sm_givedefibmenu", ADMFLAG_SLAY);
	}
}

public void AdminMenu_GiveDefib(TopMenu topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Give Defibrillator", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		InitiateMenuAdminDefib_GiveDefib(param);
	}
}

//Action InitiateMenuAdminDefib_GiveDefib(int client, int args)
Action InitiateMenuAdminDefib_GiveDefib(int client)
{
	if (!IsValidClient(client))  
	{
		ShowWarning(client, -1);
		return;
	}
	
	char name[MAX_NAME_LENGTH]; char number[10];
	
	Handle menu = CreateMenu(ShowMenu_GiveDefib);
	SetMenuTitle(menu, "Give Defibrillator to:"); 
	
	bool hasEnt = false;
	for (int i = 1; i <= MaxClients; i++) // Get Clients
	{
		if (!IsSurvivor(i) || !IsPlayerAlive(i)) continue;
		
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
		
		int character = GetEntProp(i, Prop_Send, "m_survivorCharacter");
		
		char charletter[6];
		GetCharacterLetter(character, charletter, sizeof(charletter));
		Format(charletter, sizeof(charletter), " %s", charletter); 
		
		char name_and_hp[MAX_NAME_LENGTH+64];
		Format(name_and_hp, sizeof(name_and_hp), "%s (%s%s%s)", name, status, temphp, charletter);
		
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

int ShowMenu_GiveDefib(Handle menu, MenuAction action, int client, int param2)  
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(client)) return;
			
			char number[4]; 
			GetMenuItem(menu, param2, number, sizeof(number)); 
			
			int target = GetClientOfUserId(StringToInt(number));
			if (!IsValidClient(target))
			{ ShowWarning(client, 0); return; }
			
			PrintToChat(client, "[SM] Gave a defibrillator to %N", target);
			
			InitiateMenuAdminDefib_GiveDefib(client);
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

// MENU End // -------------------------------------------------------- //
// CMDS Start // -------------------------------------------------------- //

Action RDeathModelCmd_DefibAll(int client, int args)
{
	/*if (!IsValidClient(client))  
	{
		ShowWarning(client, -1);
		return Plugin_Handled;
	}*/
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsSurvivor(i) || IsPlayerAlive(i)) continue;
		
		DefibSurvivorOnDeathModel(i, EntRefToEntIndex(g_iDeathModel[i]), client);
	}
	
	return Plugin_Handled;
}

Action RDeathModelCmd_ConvertAll(int client, int args)
{
	/*if (!IsValidClient(client))  
	{
		ShowWarning(client, -1);
		return Plugin_Handled;
	}*/
	
	/*for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsSurvivor(i) || IsPlayerAlive(i)) continue;
		
		TurnDeathModelIntoZombie(i, EntRefToEntIndex(g_iDeathModel[i]));
	}*/
	for (int i = 1; i <= GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i)) continue;
		
		if (!HasTargetname(i, DEATH_MODEL_CLASS)) continue;
		
		TurnDeathModelIntoZombie(-1, i);
	}
	
	return Plugin_Handled;
}

Action RDeathModelCmd_CreateDeathModel(int client, int args)
{
	if (!IsValidClient(client))  
	{
		ShowWarning(client, -1);
		return Plugin_Handled;
	}
	
	CreateDeathModel(client);
	
	return Plugin_Handled;
}

// CMDS End // -------------------------------------------------------- //

/*void round_end(Event event, const char[] name, bool dontBroadcast)
{
	
}*/

void player_bot_replace(Event event, const char[] name, bool dontBroadcast) // Bot replaced a player
{
	//PrintToChatAll("player_bot_replace:");
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	
	SwapTimers(client, bot);
	if (g_fAnimToDoTimer_Active(client)) HookThink(client);
	if (g_fAnimToDoTimer_Active(bot)) HookThink(bot);
}

void bot_player_replace(Event event, const char[] name, bool dontBroadcast) // Player replaced a bot
{
	//PrintToChatAll("bot_player_replace:");
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	
	SwapTimers(bot, client);
	if (g_fAnimToDoTimer_Active(bot)) HookThink(bot);
	if (g_fAnimToDoTimer_Active(client)) HookThink(client);
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
	int g_iDeathModel_backup = EntRefToEntIndex(g_iDeathModel[other]);
	
	float g_fAnimToDoTimer_backup = g_fAnimToDoTimer[other];
	int g_iAnimToDo_backup = g_iAnimToDo[other];
	
	bool g_bIsIncapped_backup = g_bIsIncapped[other];
	// Backup the timers for other
	
	// Set the timers of 'other' to 'client'
	g_iDeathModel[other] = g_iDeathModel[client];
	
	g_fAnimToDoTimer[other] = g_fAnimToDoTimer[client];
	g_iAnimToDo[other] = g_iAnimToDo[client];
	
	g_bIsIncapped[other] = g_bIsIncapped[client];

	
	// Then use the backed-up 'other' variables for 'client'
	if (RealValidEntity(g_iDeathModel_backup))
	{ g_iDeathModel[client] = EntIndexToEntRef(g_iDeathModel_backup); }
	
	g_fAnimToDoTimer[client] = g_fAnimToDoTimer_backup;
	g_iAnimToDo[client] = g_iAnimToDo_backup;

	g_bIsIncapped[client] = g_bIsIncapped_backup;
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

void player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client) || !IsIncapacitated(client, false)) return;
	
	g_bIsIncapped[client] = true;
}

void revive_success(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (!IsValidClient(client) || IsIncapacitated(client, false)) return;
	
	g_bIsIncapped[client] = false;
}

void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client)) return;
	
	if (IsIncapacitated(client, false))
	{ g_bIsIncapped[client] = true; }
	else
	{ g_bIsIncapped[client] = false; }
	
	RemoveDeathModel(client);
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int infected = event.GetInt("entityid");
	if (RealValidEntity(infected) && !IsValidClient(infected))
	{
		int attacker = event.GetInt("attacker");
		if (!IsValidClient(attacker))
		{ attacker = event.GetInt("attackerentid"); }
		//int health = GetEntProp(infected, Prop_Data, "m_iHealth"); PrintToChatAll("%i", GetEntProp(infected, Prop_Data, "m_lifeState"));
		//if (health > 0) return;
		
		char temp_str[128];
		Format(temp_str, sizeof(temp_str), COMMON_VISMDL_TARGETNAME, infected);
		
		int vismdl = FindEntityByTargetname(0, temp_str);
		if (!RealValidEntity(vismdl)) return;
		//PrintToChatAll("%i", GetEntProp(vismdl, Prop_Data, "m_bForceServerRagdoll"));
		//AcceptEntityInput(vismdl, "Kill");
		CreateRagdollForInfected(vismdl, infected, attacker);
		AcceptEntityInput(infected, "Kill");
		
		//AddOutputToTimerEnt(infected, "OnUser2 !activator:Kill::0.1:1", "FireUser2");
		
		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(vismdl, "AddOutput");
		AcceptEntityInput(vismdl, "FireUser1");
		return;
	}
	
	bool cvar_enable = GetConVarBool(RDeathModel_Enable);
	if (!cvar_enable) return;
	//PrintToChatAll("%i", GetEntProp(client, Prop_Send, "m_isIncapacitated"));
	//g_bTimerRespawn[client] = false;
	//g_bTempGod[client] = false;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client)) return;
	
	if (!IsSurvivor(client) || IsPlayerAlive(client)) return;
	
	//float game_time = GetGameTime();
	
	//g_fTimerRespawn[client] = game_time+cvar_time;
	//g_bTimerRespawn[client] = true;
	
	int prev_ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (RealValidEntity(prev_ragdoll))
	{ AcceptEntityInput(prev_ragdoll, "Kill"); }
	CreateDeathModel(client);
	
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

// Death-Model Functions Start // -------------------------------------------------------- //

void CreateDeathModel(int client)
{
	if (!IsValidClient(client)) return;
	
	int corpse = CreateEntityByName("prop_dynamic_override");
	if (!RealValidEntity(corpse))
	{ return; }
	g_iDeathModel[client] = EntIndexToEntRef(corpse);
	
	DispatchKeyValue(corpse, "targetname", DEATH_MODEL_CLASS);
	
	float origin[3];
	float angles[3];
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, angles);
	angles[0] = 0.0; angles[2] = 0.0;
	
	float velfloat[3];
	if (GetConVarInt(RDeathModel_Behavior) & BITFLAG_BEHAVIOR_VEL)
	{
		velfloat[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		velfloat[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		velfloat[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	}
	
	TeleportEntity(corpse, origin, angles, velfloat);
	
	char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	
	SetEntityModel(corpse, cl_model);
	
	//DispatchKeyValue(corpse, "solid", "0");
	//SetEntityRenderMode(corpse, RENDER_GLOW);
	//DispatchKeyValue(corpse, "renderamt", "1");
	DispatchKeyValue(corpse, "fademindist", "1");
	DispatchKeyValue(corpse, "fademaxdist", "1");
	
	DispatchSpawn(corpse);
	ActivateEntity(corpse);
	
	SetEntityMoveType(corpse, MOVETYPE_STEP);
	
	// movable
	if (GetConVarInt(RDeathModel_Behavior) & BITFLAG_BEHAVIOR_HP)
	{
		SetEntProp(corpse, Prop_Send, "m_nSolidType", 1);
		SetEntProp(corpse, Prop_Send, "m_CollisionGroup", 0);
		//SetEntPropFloat(corpse, Prop_Data, "m_iszBreakableModel", 1.0);
		SetEntProp(corpse, Prop_Data, "m_iHealth", DEATH_MODEL_HP_PREVENTKILL+50);
		SetEntProp(corpse, Prop_Data, "m_iMaxHealth", 50);
		SetEntProp(corpse, Prop_Data, "m_takedamage", 2);
		
		HookSingleEntityOutput(corpse, "OnHealthChanged", Output_OnHealthChanged, false);
	}
	else
	{
		SetEntProp(corpse, Prop_Send, "m_nSolidType", 0);
		SetEntProp(corpse, Prop_Send, "m_CollisionGroup", 1);
	}
	// movable end
	
	SetEntPropVector(corpse, Prop_Send, "m_vecMins", view_as<float>({-16.0, -16.0, 0.0}));
	SetEntPropVector(corpse, Prop_Send, "m_vecMaxs", view_as<float>({16.0, 16.0, 71.0}));
	DispatchKeyValue(corpse, "nextthink", "0.5");
	SetEntityGravity(corpse, 1.0);
	
	//SetEntProp(corpse, Prop_Send, "m_bClientSideAnimation", 1);
	
	if (g_bIsIncapped[client])
	{
		SetVariantString("ACT_IDLE_INCAP");
		AcceptEntityInput(corpse, "SetAnimation");
		
		SetVariantString("OnUser1 !self:SetAnimation:Death:0.01:1");
		AcceptEntityInput(corpse, "AddOutput");
		
		SetVariantString("OnUser1 !self:AddOutput:playbackrate 12:0.02:1");
		AcceptEntityInput(corpse, "AddOutput");
		
		SetVariantString("OnUser1 !self:AddOutput:playbackrate 1:0.12:1");
		AcceptEntityInput(corpse, "AddOutput");
		
		AcceptEntityInput(corpse, "FireUser1");
	}
	else
	{
		SetVariantString("Death");
		AcceptEntityInput(corpse, "SetAnimation");
	}
	
	//AcceptEntityInput(corpse, "FireUser1");
	
	int corpse_vis = CreateEntityByName("commentary_dummy");
	if (!RealValidEntity(corpse_vis))
	{
		AcceptEntityInput(corpse, "Kill");
		return;
	}
	
	// LMC
	int iOverlayModel = LMC_GetClientOverlayModel(client);
	if (RealValidEntity(iOverlayModel))
	{
		GetEntPropString(iOverlayModel, Prop_Data, "m_ModelName", cl_model, sizeof(cl_model));
	}
	
	SetEntityModel(corpse_vis, cl_model);
	TeleportEntity(corpse_vis, origin, angles, NULL_VECTOR);
	
	char temp_str[64];
	Format(temp_str, sizeof(temp_str), DEATH_MODEL_VIS, corpse);
	DispatchKeyValue(corpse_vis, "targetname", temp_str);
	//PrintToChatAll(temp_str);
	
	DispatchSpawn(corpse_vis);
	ActivateEntity(corpse_vis);
	
	SetEntProp(corpse_vis, Prop_Data, "m_bForceServerRagdoll", 1);
	
	SetEntProp(corpse_vis, Prop_Send, "m_fEffects", 1|512); //EF_BONEMERGE|EF_PARENT_ANIMATES
	SetVariantString("!activator");
	AcceptEntityInput(corpse_vis, "SetParent", corpse);
	
	SetVariantString("ACT_DIERAGDOLL");
	AcceptEntityInput(corpse_vis, "SetAnimation");
	
	//SetVariantString("OnHealthChanged !self:AddOutput:playbackrate 1:0.12:1");
	//AcceptEntityInput(corpse, "AddOutput");
	
	/*if (g_bIsIncapped[client])
	{
		SetVariantString("ACT_IDLE_INCAP");
		AcceptEntityInput(corpse_vis, "SetAnimation");
	}
	else
	{
		SetVariantString("Death");
		AcceptEntityInput(corpse_vis, "SetAnimation");
	}
	
	SetVariantString("OnUser1 !self:SetAnimation:ACT_DIERAGDOLL:0.01:1");
	AcceptEntityInput(corpse_vis, "AddOutput");
	AcceptEntityInput(corpse_vis, "FireUser1");*/
	
	/*int blood_ef = CreateEntityByName("info_particle_system");
	if (!RealValidEntity(blood_ef))
	{ return; }
	
	TeleportEntity(blood_ef, origin, angles, NULL_VECTOR);
	
	char blood_ef_name[32];
	Format(blood_ef_name, sizeof(blood_ef_name), "plugin_sdm_blood_ef_%i", EntRefToEntIndex(corpse));
	DispatchKeyValue(blood_ef, "targetname", blood_ef_name);
	
	DispatchSpawn(blood_ef);
	ActivateEntity(blood_ef);
	
	SetVariantString("!activator");
	AcceptEntityInput(blood_ef, "SetParent", corpse);
	
	char temp_str[64];
	Format(temp_str, sizeof(temp_str), "OnTakeDamage %s:Start:ACT_DIERAGDOLL:0.01:1", EntRefToEntIndex(corpse));
	SetVariantString("OnTakeDamage !self:SetAnimation:ACT_DIERAGDOLL:0.01:1");
	AcceptEntityInput(corpse, "AddOutput");*/
}

void RemoveDeathModel(int client)
{
	int body = EntRefToEntIndex(g_iDeathModel[client]);
	if (!RealValidEntity(body) || !HasTargetname(body, DEATH_MODEL_CLASS)) return;
	
	AcceptEntityInput(body, "Kill");
	g_iDeathModel[client] = INVALID_ENT_REFERENCE;
}

void Output_OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
	if (!RealValidEntity(caller) || !HasTargetname(caller, DEATH_MODEL_CLASS)) return;
	
	int health = GetEntProp(caller, Prop_Data, "m_iHealth");
	
	// The body has taken enough damage; time to make it ragdoll
	if (health <= DEATH_MODEL_HP_PREVENTKILL)
	{
		//SetIHealth(caller, 1000000); // Set it to a high amount of health so it won't be removed
		SetEntProp(caller, Prop_Data, "m_takedamage", 0); // Disable it from taking damage
		
		char temp_str[64];
		Format(temp_str, sizeof(temp_str), DEATH_MODEL_VIS, caller);
		int vismdl = FindEntityByTargetname(0, temp_str);
		char vismdl_mdl[128];
		if (RealValidEntity(vismdl))
		{
			GetEntPropString(vismdl, Prop_Data, "m_ModelName", vismdl_mdl, sizeof(vismdl_mdl));
			AcceptEntityInput(vismdl, "Kill");
		}
		//PrintToChatAll(temp_str);
		
		char caller_mdl[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", caller_mdl, sizeof(caller_mdl));
		
		if (!StrEqual(caller_mdl, vismdl_mdl, false)) SetEntityModel(caller, vismdl_mdl);
		
		AcceptEntityInput(caller, "BecomeRagdoll");
		
		float velocity[3];
		GetEntPropVector(caller, Prop_Data, "m_vecVelocity", velocity);
		velocity[0] *= 20.0;
		velocity[1] *= 20.0;
		velocity[2] *= 20.0;
		SetEntPropVector(caller, Prop_Send, "m_vecForce", velocity);
		
		SetVariantString("OnUser2 !self:Kill::1.0:1");
		AcceptEntityInput(caller, "AddOutput");
		AcceptEntityInput(caller, "FireUser2", activator);
	}
}

void DefibSurvivorOnDeathModel(int client, int body, int savior = -1)
{
	if (!IsSurvivor(client) || IsPlayerAlive(client) || !RealValidEntity(body) || !HasTargetname(body, DEATH_MODEL_CLASS)) return;
	
	float origin[3];
	float angles[3];
	GetEntPropVector(body, Prop_Data, "m_vecOrigin", origin);
	GetEntPropVector(body, Prop_Data, "m_angRotation", angles);
	angles[0] = 0.0; angles[2] = 0.0;
	
	RemoveDeathModel(client);
	
	// We respawn the player via rescue entity; we don't need a signature at all!
	int rescue_ent = CreateEntityByName("info_survivor_rescue");
	if (!RealValidEntity(rescue_ent))
	{ return; }
	
	TeleportEntity(rescue_ent, origin, angles, NULL_VECTOR);
	
	char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	SetEntityModel(rescue_ent, cl_model);
	
	DispatchSpawn(rescue_ent);
	ActivateEntity(rescue_ent);
	
	DispatchKeyValue(rescue_ent, "nextthink", "10.0");
	
	SetEntPropEnt(rescue_ent, Prop_Send, "m_survivor", client);
	AcceptEntityInput(rescue_ent, "Rescue", savior);
	
	AcceptEntityInput(rescue_ent, "Kill");
	
	/*SetVariantString("OnUser1 !activator:DispatchResponse:PlayerThanks:2.0:1");
	AcceptEntityInput(rescue_ent, "AddOutput");
	
	SetVariantString("OnUser1 !self:Kill::2.5:1");
	AcceptEntityInput(rescue_ent, "AddOutput");
	AcceptEntityInput(rescue_ent, "FireUser1", client);*/
	
	AddOutputToTimerEnt(client, "OnUser1 !activator:DispatchResponse:PlayerThanks:2.0:1", "FireUser1");
	
	if (!IsPlayerAlive(client)) return;
	
	float cvar_getup = GetConVarFloat(RDeathModel_GetUpTime);
	if (cvar_getup > 0.0) HookThink(client);
	
	for (int i = 0; i <= 4; i++)
	{
		int wep = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (RealValidEntity(wep))
		{
			/*char temp_str[128];
			GetEntityClassname(wep, temp_str, sizeof(temp_str));
			PrintToChatAll("slot %i, %s", i, temp_str);*/
			SetEntProp(client, Prop_Send, "m_hMyWeapons", -1, i);
			AcceptEntityInput(wep, "Kill");
			
			if (i == 0)
			{
				GiveWeapon(client, "weapon_pistol");
			}
		}
	}
	
	AcceptEntityInput(client, "ClearContext");
	
	SetVariantString("PainLevel:Major:0.25");
	AcceptEntityInput(client, "AddContext");
	SetVariantString("Pain");
	AcceptEntityInput(client, "DispatchResponse");
}

void GiveWeapon(int client, const char[] wep_class)
{
	int new_weapon = CreateEntityByName(wep_class);
	if (!RealValidEntity(new_weapon)) return;
	
	float cl_origin[3];
	GetClientEyePosition(client, cl_origin);
	
	TeleportEntity(new_weapon, cl_origin, NULL_VECTOR, NULL_VECTOR);
	
	DispatchSpawn(new_weapon);
	ActivateEntity(new_weapon);
	
//	SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", new_weapon, i);
//	SetEntPropEnt(new_weapon, Prop_Send, "m_hOwnerEntity", client);
//	SetEntPropEnt(new_weapon, Prop_Send, "moveparent", client);
//	SetEntProp(new_weapon, Prop_Send, "m_isDualWielding", 0);
//	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", new_weapon);
//	SetEntProp(new_weapon, Prop_Send, "m_inInitialPickup", 1);
	//AcceptEntityInput(new_weapon, "Use", client, new_weapon);
	
	DataPack data = CreateDataPack();
	data.WriteCell(client);
	data.WriteCell(new_weapon);
	RequestFrame(NewWeapon_RequestFrame, data);
}

void NewWeapon_RequestFrame(DataPack data)
{
	data.Reset();
	int client = data.ReadCell();
	int new_weapon = data.ReadCell();
	if (data != null)
	{ CloseHandle(data); }
	
	if (!IsValidClient(client) || !RealValidEntity(new_weapon)) return;
	
	AcceptEntityInput(new_weapon, "Use", client, new_weapon);
	
	char temp_str[24];
	GetEntityClassname(new_weapon, temp_str, sizeof(temp_str));
	if (StrEqual(temp_str, "weapon_pistol", false))
	{ RequestFrame(PreventShooting_RequestFrame, client); }
	
	//float game_time = GetGameTime();
	//float cvar_getup = GetConVarFloat(RDeathModel_GetUpTime);
	//SetEntPropFloat(new_weapon, Prop_Send, "m_flNextPrimaryAttack", game_time+cvar_getup);
	//SetEntPropFloat(new_weapon, Prop_Send, "m_flNextSecondaryAttack", game_time+cvar_getup);
}
void PreventShooting_RequestFrame(int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client)) return;
	
	float game_time = GetGameTime();
	float cvar_getup = GetConVarFloat(RDeathModel_GetUpTime);
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", game_time+cvar_getup);
}

void TurnDeathModelIntoZombie(int client, int body)
{
	if (!RealValidEntity(body) || !HasTargetname(body, DEATH_MODEL_CLASS)) return;
	
	if (IsValidClient(client) && g_iDeathModel[client] > INVALID_ENT_REFERENCE)
		g_iDeathModel[client] = INVALID_ENT_REFERENCE;
	
	DispatchKeyValue(body, "targetname", DEATH_MODEL_EXTRA);
	
	float origin[3];
	GetEntPropVector(body, Prop_Data, "m_vecOrigin", origin);
	
	//PrecacheScriptSound("Zombie.BecomeEnraged");
	EmitAmbientGenericSound(origin, "Zombie.Rage");
	
	SetVariantString("ACT_TERROR_INCAP_TO_STAND");
	AcceptEntityInput(body, "SetAnimation");
	
	//SetVariantString("OnUser1 !self:Kill::1.5:1");
	//AcceptEntityInput(body, "AddOutput");
	
	//AcceptEntityInput(body, "FireUser1");
	
	CreateTimer(1.5, Timer_TurnToZombie, body, TIMER_FLAG_NO_MAPCHANGE);
}

// Death-Model Functions End // -------------------------------------------------------- //
// Death-Model Timers Start // -------------------------------------------------------- //

Action Timer_TurnToZombie(Handle timer, int body)
{
	if (!RealValidEntity(body)) return;
	
	int infected = CreateEntityByName("infected");
	if (!RealValidEntity(infected))
	{ return; }
	
	float origin[3];
	float angles[3];
	GetEntPropVector(body, Prop_Data, "m_vecOrigin", origin);
	GetEntPropVector(body, Prop_Data, "m_angRotation", angles);
	angles[0] = 0.0; angles[2] = 0.0;
	
	TeleportEntity(infected, origin, angles, NULL_VECTOR);
	
	DispatchSpawn(infected);
	ActivateEntity(infected);
	
	//DispatchKeyValue(infected, "rendermode", "10");
	DispatchKeyValue(infected, "fademindist", "1");
	DispatchKeyValue(infected, "fademaxdist", "1");
	
	int health_to_set = GetConVarInt(RDeathModel_ZombieSurvHP);
	
	SetEntProp(infected, Prop_Data, "m_iHealth", health_to_set);
	SetEntProp(infected, Prop_Data, "m_iMaxHealth", health_to_set);
	
	char cl_model[PLATFORM_MAX_PATH];
	
	char temp_str[64];
	Format(temp_str, sizeof(temp_str), DEATH_MODEL_VIS, body);
	int vismdl = FindEntityByTargetname(0, temp_str);
	
	if (RealValidEntity(vismdl))
	{
		GetEntPropString(vismdl, Prop_Data, "m_ModelName", cl_model, sizeof(cl_model));
	}
	else
	{
		GetEntPropString(body, Prop_Data, "m_ModelName", cl_model, sizeof(cl_model));
	}
	
	// temp check
	if (IsZoey(body))
		SetEntityModel(infected, COMMON_FEMALE);
	else
		SetEntityModel(infected, COMMON_MALE);
	
	AcceptEntityInput(body, "Kill");
	
	AttachModelToInfected(infected, cl_model);
	
	//RequestFrame(Infected_RequestFrame, infected);
}

/*void Infected_RequestFrame(int infected)
{
	DispatchKeyValue(infected, "renderamt", "10");
}*/

void CreateRagdollForInfected(int entity, int owner, int attacker)
{
	if (!RealValidEntity(entity) || !RealValidEntity(owner))
	return;
	
	if (!RealValidEntity(attacker))
	{ attacker = entity; }
	
	float origin[3];
	float angles[3];
	GetEntPropVector(owner, Prop_Data, "m_vecOrigin", origin);
	GetEntPropVector(owner, Prop_Data, "m_angRotation", angles);
	angles[0] = 0.0; angles[2] = 0.0;
	
	AcceptEntityInput(entity, "ClearParent");
	TeleportEntity(entity, origin, angles, NULL_VECTOR);
	
	SetVariantString("deathpose_front");
	AcceptEntityInput(entity, "SetAnimation");
	
	int effect = GetEntPropEnt(owner, Prop_Send, "m_hEffectEntity");
	if (IsValidEntity(effect))
	{
		char effectclass[64]; 
		GetEntityClassname(effect, effectclass, sizeof(effectclass));
		if (StrEqual(effectclass, "entityflame"))
		{ AcceptEntityInput(entity, "Ignite"); }
	}
	
	SetEntProp(entity, Prop_Data, "m_iHealth", 1);
	SetEntProp(entity, Prop_Data, "m_iMaxHealth", 1);
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	SDKHooks_TakeDamage(entity, attacker, attacker, 100.0);
	
	SetEntProp(entity, Prop_Send, "m_nForceBone", 0);
	
	float velocity[3];
	GetEntPropVector(owner, Prop_Data, "m_vecVelocity", velocity);
	
	float velfloat[3];
	GetEntPropVector(owner, Prop_Send, "m_vecForce", velfloat);
	
	velfloat[0] += velocity[0];
	velfloat[1] += velocity[1];
	velfloat[2] += velocity[2];
	velfloat[0] *= 60.0;
	velfloat[1] *= 60.0;
	velfloat[2] *= 60.0;
	
	SetEntPropVector(entity, Prop_Send, "m_vecForce", velfloat);
}

/*void CreateRagdollForInfected(int entity, int owner)
{
	if (!RealValidEntity(entity) || !RealValidEntity(owner))
	return;
	
	int Ragdoll = CreateEntityByName("cs_ragdoll");
	float fPos[3];
	float fAng[3];
	GetEntPropVector(owner, Prop_Data, "m_vecOrigin", fPos);
	GetEntPropVector(owner, Prop_Data, "m_angRotation", fAng);
	
	TeleportEntity(Ragdoll, fPos, fAng, NULL_VECTOR);
	
	int team = GetEntProp(owner, Prop_Data, "m_iTeamNum");
	
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollOrigin", fPos);
	SetEntProp(Ragdoll, Prop_Send, "m_bInterpOrigin", 1);
	SetEntProp(Ragdoll, Prop_Send, "m_nModelIndex", GetEntProp(entity, Prop_Send, "m_nModelIndex"));
	SetEntProp(Ragdoll, Prop_Send, "m_iTeamNum", team);
	//if (IsValidClient(entity))
	//{ SetEntPropEnt(Ragdoll, Prop_Send, "m_hPlayer", entity); }
	SetEntPropEnt(Ragdoll, Prop_Send, "m_hPlayer", entity);
	SetEntProp(Ragdoll, Prop_Send, "m_iDeathPose", GetEntProp(entity, Prop_Send, "m_nSequence"));
	SetEntProp(Ragdoll, Prop_Send, "m_iDeathFrame", GetEntProp(entity, Prop_Send, "m_flAnimTime"));
	SetEntProp(Ragdoll, Prop_Send, "m_nForceBone", GetEntProp(owner, Prop_Send, "m_nForceBone"));
	
	float velfloat[3];
	GetEntPropVector(owner, Prop_Send, "m_vecForce", velfloat);
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecForce", velfloat);
	
	GetEntPropVector(owner, Prop_Data, "m_vecVelocity", velfloat);
	
	velfloat[0] *= 30.0;
	velfloat[1] *= 30.0;
	velfloat[2] *= 30.0;
	
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollVelocity", velfloat);
	
	SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 1);
	
	int effect = GetEntPropEnt(owner, Prop_Send, "m_hEffectEntity");
	if (IsValidEntity(effect))
	{
		char effectclass[64]; 
		GetEntityClassname(effect, effectclass, sizeof(effectclass));
		if (StrEqual(effectclass, "entityflame"))
		{ SetEntProp(Ragdoll, Prop_Send, "m_bOnFire", 1, 1); }
	}
	
	if (HasEntProp(entity, Prop_Send, "m_hRagdoll"))
	{
		int prev_ragdoll = GetEntPropEnt(entity, Prop_Send, "m_hRagdoll");
		if (!IsPlayerAlive(entity) && !IsValidEntity(prev_ragdoll))
		{
			//SetEntProp(entity, Prop_Send, "m_bClientSideRagdoll", 1);
			SetEntPropEnt(entity, Prop_Send, "m_hRagdoll", Ragdoll);
			return;
		}
	}
	SetVariantString("OnUser1 !self:Kill::1.0:1");
	AcceptEntityInput(Ragdoll, "AddOutput");
	AcceptEntityInput(Ragdoll, "FireUser1");
}*/

// Death-Model Timers End // -------------------------------------------------------- //
// Raise From The Dead Start // -------------------------------------------------------- //

void AttachModelToInfected(int infected, const char[] mdl)
{
	if (!RealValidEntity(infected)) return;
	
	int vismdl = CreateEntityByName("commentary_dummy");
	if (!RealValidEntity(vismdl))
	{ return; }
	
	//DispatchKeyValue(vismdl, "solid", "0");
	DispatchKeyValue(vismdl, "model", mdl);
	
	DispatchSpawn(vismdl);
	ActivateEntity(vismdl);
	
	SetEntProp(vismdl, Prop_Data, "m_bForceServerRagdoll", 1);
	
	char temp_str[128];
	Format(temp_str, sizeof(temp_str), COMMON_VISMDL_TARGETNAME, infected);
	DispatchKeyValue(vismdl, "targetname", temp_str);
	
	SetVariantString("!activator");
	AcceptEntityInput(vismdl, "SetParent", infected);
	
	SetEntProp(vismdl, Prop_Send, "m_fEffects", 1|128|512); //EF_BONEMERGE|EF_BONEMERGE_FASTCULL|EF_PARENT_ANIMATES
	SetEntProp(vismdl, Prop_Send, "m_fEffects", 1|512); //EF_BONEMERGE|EF_PARENT_ANIMATES
}

// Raise From The Dead End // -------------------------------------------------------- //
// Non-Handle Timers Start // -------------------------------------------------------- //

bool g_fAnimToDoTimer_Active(int client)
{
	if (GetConVarFloat(RDeathModel_GetUpTime) <= 0.0) return false;
	if (g_fAnimToDoTimer[client] > GetGameTime() && g_iAnimToDo[client] > 0) return true;
	return false;
}

void HookThink(int client, bool boolean = true)
{
    switch (boolean)
	{
		case true:
		{
			if (!IsValidClient(client)) return;
			
			float game_time = GetGameTime();
			float cvar_getup = GetConVarFloat(RDeathModel_GetUpTime);
			float gt_plus_getup = game_time+cvar_getup;
			//SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", cvar_getup);
			
			SetDTCountdownTimer(client, "m_stunTimer", cvar_getup);
			SetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil", gt_plus_getup);
			
			g_fAnimToDoTimer[client] = gt_plus_getup;
			g_iAnimToDo[client] = GetAnimation(client, "ACT_TERROR_INCAP_TO_STAND");
			SDKHook(client, POST_THINK_HOOK, Hook_OnThinkPost); g_fClientWait[client] = 0.0;
			SetEntPropFloat(client, Prop_Send, "m_mainSequenceStartTime", game_time);
			GotoThirdPerson(client);
		}
		case false:
		{
			g_fAnimToDoTimer[client] = -1.0;
			g_iAnimToDo[client] = -1;
			if (!IsValidClient(client)) return;
			
			SetDTCountdownTimer(client, "m_stunTimer", 0.0);
			SetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil", 0.0);
			
			SDKUnhook(client, POST_THINK_HOOK, Hook_OnThinkPost);
			GotoFirstPerson(client);
		}
	}
}

void Hook_OnThinkPost(int client)
{
	if (!IsServerProcessing()) return;
	
	if (GetGameTime() - g_fClientWait[client] >= 0.0)
	{
		UpdateTimers(client);
		g_fClientWait[client] = g_fClientWait[client] + THINK_WAITTIME;
	}
	
	if (IsSurvivor(client) && IsPlayerAlive(client) && !IsOccupied(client) && !IsIncapacitated(client) && 
	g_iAnimToDo[client] > 0 && HasEntProp(client, Prop_Send, "m_nSequence"))
	{
		int anim = g_iAnimToDo[client];
		
		SetEntProp(client, Prop_Send, "m_nSequence", anim);
		return;
	}
	HookThink(client, false);
}

void UpdateTimers(int client)
{
	if (!g_fAnimToDoTimer_Active(client))
	{
		HookThink(client, false);
	}
}

// Non-Handle Timers End // -------------------------------------------------------- //
// Player Get-Up Effects Start // -------------------------------------------------------- //

/*void BeginGetUpEffects(int client)
{
	
}*/

// Player Get-Up Effects End // -------------------------------------------------------- //
// Others Start // -------------------------------------------------------- //

// V Credits to Silvers, this was taken from his L4D2 incapped crawling plugin
// Link: https://forums.alliedmods.net/showthread.php?t=137381
void GotoThirdPerson(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
	int view_Entity = GetEntPropEnt(client, Prop_Send, "m_hViewEntity");
	if (!RealValidEntity(view_Entity))
	{ SetEntPropEnt(client, Prop_Send, "m_hViewEntity", client); }
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
}

void GotoFirstPerson(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	int view_Entity = GetEntPropEnt(client, Prop_Send, "m_hViewEntity");
	if (RealValidEntity(view_Entity))
	{ SetEntPropEnt(client, Prop_Send, "m_hViewEntity", -1); }
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}
// end

/*int GetNearestGroundSurvivor(const float posToCheck[3])
{
	int result = -1;
	float distance = -1.0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsIncapacitated(client, 1)) continue;
		if (!HasEntProp(client, Prop_Send, "m_hGroundEntity") || GetEntProp(client, Prop_Send, "m_hGroundEntity") < 0) continue;
		
		float cl_origin[3];
		GetClientAbsOrigin(client, cl_origin);
		
		float temp_dis = GetVectorDistance(posToCheck, cl_origin, true);
		if (distance > 0.0 && temp_dis > distance) continue;
		
		result = client;
		distance = temp_dis;
	}
	return result;
}*/

/*bool DoesEntityWithClassExist(const char[] class)
{
	int entity = FindEntityByClassname(-1, class);
	if (!RealValidEntity(entity)) return false;
	return true;
}*/

/*void GiveTempGod(int client)
{
	float cvar_time = GetConVarFloat(Defib_TempGodTimer);
	if (cvar_time <= 0.0) return;
	
	if (!IsValidClient(client)) return;
	
	int incap_cvar = GetConVarInt(FindConVar(INCAP_CVAR));
	
	SetEntProp(client, Prop_Data, "m_takedamage", 0);
	if (incap_cvar > 0)
	{ Logic_RunScript("GetPlayerFromUserID(%d).SetReviveCount(%i)", GetClientUserId(client), GetConVarInt(FindConVar(INCAP_CVAR))); }
	//g_hTempGod[client] = CreateTimer(cvar_time, TempGodTimer, client);
	
	float game_time = GetGameTime();
	
	g_fTempGod[client] = game_time+cvar_time;
	g_bTempGod[client] = true;
}

Action TempGodTimer(Handle timer, int client)
{
	if (!IsValidClient(client)) return;
	g_hTempGod[client] = null;
	
	int incap_cvar = GetConVarInt(FindConVar(INCAP_CVAR));
	
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	PrintToChat(client, "Your temporary godmode has ran out.");
	if (incap_cvar > 0)
	{ Logic_RunScript("GetPlayerFromUserID(%d).SetReviveCount(0)", GetClientUserId(client)); }
}*/

void GetCharacterLetter(int character, char[] str, int maxlen)
{
	switch (character)
	{
		case 0:
		{
			strcopy(str, maxlen, "B");
			return;
		}
		case 1:
		{
			strcopy(str, maxlen, "Z");
			return;
		}
		case 2:
		{
			strcopy(str, maxlen, "F");
			return;
		}
		case 3:
		{
			strcopy(str, maxlen, "L");
			return;
		}
		default:
		{
			strcopy(str, maxlen, "?");
			return;
		}
	}
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

/*int GetSpawnedBodyForSurvivor(int client)
{
	int targetBody = -1;
	if (!IsValidClient(client)) { return targetBody; }
	//float deathTime = GetEntPropFloat(client, Prop_Send, "m_flDeathTime");
	
	for (int i = 1; i <= GetMaxEntities(); i++) // Get Survivor Models
	{
		if (!RealValidEntity(i)) continue;
		char class[64];
		GetEntityClassname(i, class, sizeof(class));
		if (!StrEqual(class, DEATH_MODEL_CLASS, false)) continue;
		
		//float createTime = GetEntPropFloat(i, Prop_Send, "m_flCreateTime");
		//PrintToChatAll("cT: %f, dT: %f", createTime, deathTime);
		//if (createTime != deathTime) continue;
		
		if (!ClientAndBodySamePlace(client, i) || !ClientAndBodySameChar(client, i) || !ClientAndBodySameModel(client, i)) continue;
		
		targetBody = i;
		break;
	}
	//PrintToChatAll("%i", targetBody);
	return targetBody;
}*/

int GetAnimation(int entity, const char[] sequence)
{
	if (!RealValidEntity(entity)) return -1;
	
	int temp = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(temp, "solid", "0");
	
	char cl_model[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", cl_model, sizeof(cl_model));
	SetEntityModel(temp, cl_model);
	
	SetVariantString(sequence);
	AcceptEntityInput(temp, "SetAnimation");
	
	int sequence_int = GetEntProp(temp, Prop_Send, "m_nSequence");
	
	AcceptEntityInput(temp, "Kill");
	
	return sequence_int;
}

int FindEntityByTargetname(int index, const char[] findname)
{
	for (int i = index; i < GetMaxEntities(); i++) {
		if (!RealValidEntity(i)) continue;
		char name[128];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (!StrEqual(name, findname, false)) continue;
		return i;
	}
	return -1;
}

bool HasTargetname(int entity, const char[] targetname)
{
	char name[128];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	if (StrEqual(name, targetname, false)) return true;
	
	return false;
}

void EmitAmbientGenericSound(float[3] pos, const char[] snd_str)
{
	int snd_ent = CreateEntityByName("ambient_generic");
	
	TeleportEntity(snd_ent, pos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(snd_ent, "message", snd_str);
	DispatchKeyValue(snd_ent, "health", "10");
	DispatchKeyValue(snd_ent, "spawnflags", "48");
	DispatchSpawn(snd_ent);
	ActivateEntity(snd_ent);
	
	AcceptEntityInput(snd_ent, "PlaySound");
	
	AcceptEntityInput(snd_ent, "Kill");
}

void AddOutputToTimerEnt(int caller, const char[] output, const char[] user_call)
{
	int temp_ent = FindEntityByTargetname(0, TEMP_ENT);
	if (!RealValidEntity(temp_ent))
	{
		temp_ent = CreateEntityByName("info_teleport_destination");
		DispatchKeyValue(temp_ent, "targetname", TEMP_ENT);
		DispatchSpawn(temp_ent);
	}
	SetVariantString(output);
	AcceptEntityInput(temp_ent, "AddOutput");
	AcceptEntityInput(temp_ent, user_call, caller);
}

void SetDTCountdownTimer(int client, const char[] timer_str, float duration)
{
	SetEntDataFloat(client, (FindSendPropInfo("CTerrorPlayer", timer_str)+4), duration, true);
	SetEntDataFloat(client, (FindSendPropInfo("CTerrorPlayer", timer_str)+8), GetGameTime()+duration, true);
}

/*void SetIHealth(int entity, int health)
{
	SetEntProp(entity, Prop_Data, "m_iHealth", health);
}*/

bool IsDTCountdownTimerActive(float timestamp)
{
	float curTimeStamp = GetGameTime() - timestamp;
	if (curTimeStamp <= 0) return true;
	return false;
}

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) != 2) return false;
	return true;
}

bool IsZoey(int client)
{
	char cl_model[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", cl_model, sizeof(cl_model));
	
	if (StrContains(cl_model, "teenangst", false) >= 0) return true;
	return false;
}

bool IsOccupied(int client)
{
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if ((RealValidEntity(hunter)) || (RealValidEntity(smoker))) return true;
	
	char netprop_strs[2][24] = 
	{
		"m_knockdownTimer",
		"m_staggerTimer"
	};
	
	for (int i = 0; i < 2; i++) {
		//PrintToChatAll("%s", netprop_strs[i]);
		//float m_duration = GetEntDataFloat(client, (FindSendPropInfo("CTerrorPlayer", netprop_strs[i])+4));
		float m_timestamp = GetEntDataFloat(client, (FindSendPropInfo("CTerrorPlayer", netprop_strs[i])+8));
		//PrintToChatAll("%f, %f", m_duration, m_timestamp);
		
		if (IsDTCountdownTimerActive(m_timestamp)) return true;
	}
	return false;
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

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

// Others End // -------------------------------------------------------- //