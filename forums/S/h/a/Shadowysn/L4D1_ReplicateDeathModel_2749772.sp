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
#define PLUGIN_VERSION "1.0.5"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=333027"
#define PLUGIN_NAME_SHORT "Replicate L4D2 Death Animation"
#define PLUGIN_NAME_TECH "sequel_death_anim"

#define DEATH_MODEL_CLASS "survivor_death_model"
#define DEATH_MODEL_EXTRA "survivor_turning_to_inf"
#define TEMP_ENT "plugin_temp_timer_ent"
#define DEATH_MODEL_VIS "plugin_sdm_vismdl_%i"

#define DEFIB_CLASS "weapon_defibrillator"
#define KIT_CLASS "weapon_first_aid_kit"

#define DEATH_MODEL_HP_PREVENTKILL 999999

#define COMMON_MALE "models/infected/common_male01.mdl"
#define COMMON_FEMALE "models/infected/common_female01.mdl"
#define COMMON_VISMDL_TARGETNAME "infected_survivor_%i"

//#define GAMEDATA "l4d1_replicate_death_model"
#define AUTOEXEC_CFG "l4d1_replicate_death_model"

#define POST_THINK_HOOK SDKHook_PostThinkPost

float g_fClientWait[MAXPLAYERS+1];
#define THINK_WAITTIME 0.5

#define BITFLAG_BEHAVIOR_HP	(1 << 0)
#define BITFLAG_BEHAVIOR_VEL	(1 << 1)
#define BITFLAG_BEHAVIOR_ZOMB	(1 << 2)

TopMenu hTopMenu;

ConVar RDeathModel_Enable,
//RDeathModel_EnableDefib,
RDeathModel_DefibColor,
RDeathModel_Behavior,
RDeathModel_ZombieSurvHP,
RDeathModel_GetUpTime,
RDeathModel_DefibUseTime;
bool g_bEnable;
int g_iBehavior, g_iZSurvHP;
float g_fGetUpTime, g_fDefibUseTime;
static char g_strDefibColor[16];

int g_iDeathModel[MAXPLAYERS+1];
int g_iTargetBody[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE};
int g_iTargetClient[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE};
float g_fDefibUsedTimer[MAXPLAYERS+1];

float g_fAnimToDoTimer[MAXPLAYERS+1];
int g_iAnimToDo[MAXPLAYERS+1];

bool g_bIsIncapped[MAXPLAYERS+1];

float g_fSecondaryDelay[MAXPLAYERS+1];
float g_fCmdFindBody[MAXPLAYERS+1];

// Vocalize for Left 4 Dead
static const char g_GetUpBill[][] =
{
	"scenes/NamVet/AreaClear01.vcd",	//Clear
	"scenes/NamVet/PlayerTransitionClose04.vcd",	//That was a little closer than I'da liked.
	"scenes/NamVet/ReviveFriendA04.vcd",	//You gonna make it?
	"scenes/NamVet/ReviveFriendB05.vcd",	//I got ya.
	"scenes/NamVet/ReviveFriendLoud05.vcd",	//Hang on, I gotcha!
	"scenes/NamVet/ReviveFriendLoud09.vcd",	//Come on! This fight ain't over!
};
static const char g_GetUpFrancis[][] =
{
	"scenes/Biker/AreaClear01.vcd",	//Clear.
	"scenes/Biker/AreaClear05.vcd",	//Clear.
	"scenes/Biker/HurryUp08.vcd",	//Let's go, let's go!
	"scenes/Biker/HurryUp09.vcd",	//Come on, let's go!
	"scenes/Biker/ReviveFriendA04.vcd",	//You gonna make it?
	"scenes/Biker/ReviveFriendLoud12.vcd",	//Come on, come on! Get up!
};
static const char g_GetUpLouis[][] =
{
	"scenes/Manager/AreaClear01.vcd",	//Clear!
	"scenes/Manager/HurryUp10.vcd",	//Let's go let's go let's go!
	"scenes/Manager/ReviveFriendLoud10.vcd",	//We gotta get your ass up, man.
	"scenes/Manager/ReviveFriendLoud11.vcd",	//Get up now, come on!
};
static const char g_GetUpZoey[][] =
{
	"scenes/TeenGirl/AreaClear01.vcd",	//Clear!
	"scenes/TeenGirl/AreaClear04.vcd",	//Clear.
	"scenes/TeenGirl/ReviveFriendB03.vcd",	//Come on get up.
};

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
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_enable", PLUGIN_NAME_TECH);
	RDeathModel_Enable = CreateConVar(cmd_str, "1.0", "Enable replacing survivor ragdolls with death models?", FCVAR_NONE, true, 0.0, true, 1.0);
	RDeathModel_Enable.AddChangeHook(CC_DM_Enable);
	
	//Format(cmd_str, sizeof(cmd_str), "sm_%s_defib_enable", PLUGIN_NAME_TECH);
	//RDeathModel_EnableDefib = CreateConVar(cmd_str, "1.0", "Enable first-aid-kit defibrillators colored yellow?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_defib_color", PLUGIN_NAME_TECH);
	RDeathModel_DefibColor = CreateConVar(cmd_str, "0 255 0", "The color to give the Defibrillators.", FCVAR_NONE);
	RDeathModel_DefibColor.AddChangeHook(CC_DM_DefibColor);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_behavior", PLUGIN_NAME_TECH);
	RDeathModel_Behavior = CreateConVar(cmd_str, "0.0", "Behavior for death models. 0 = L4D2-Style. 1 | Vulnerable Bodies with Health + 2 | Keep Player Velocity + 4 | Zombification", FCVAR_NONE, true, 0.0, true, 
	7.0);
	RDeathModel_Behavior.AddChangeHook(CC_DM_Behavior);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_zombie_surv_hp", PLUGIN_NAME_TECH);
	RDeathModel_ZombieSurvHP = CreateConVar(cmd_str, "500.0", "How much HP will zombified survivors have?", FCVAR_NONE, true, 0.1);
	RDeathModel_ZombieSurvHP.AddChangeHook(CC_DM_ZSurvHP);
	
	RDeathModel_GetUpTime = CreateConVar("defibrillator_return_to_life_time", "3.0", "How long the plugin holds newly-defibbed players in place?", FCVAR_NONE, true, 0.0);
	RDeathModel_GetUpTime.AddChangeHook(CC_DM_GetUpTime);
	RDeathModel_DefibUseTime = CreateConVar("defibrillator_use_duration", "3", "How long the plugin's defibrillator takes to revive someone back to life?", FCVAR_NONE, true, 0.0);
	RDeathModel_DefibUseTime.AddChangeHook(CC_DM_DefibUseTime);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvarValues();
	
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	HookEvent("player_incapacitated", player_incapacitated, EventHookMode_Post);
	HookEvent("revive_success", revive_success, EventHookMode_Post);
	HookEvent("player_bot_replace", player_bot_replace);
	HookEvent("bot_player_replace", bot_player_replace);
	//HookEvent("player_now_it", player_now_it, EventHookMode_Post);
	HookEvent("heal_begin", heal_begin);
	HookEvent("item_pickup", item_pickup);
	HookEvent("player_use", player_use);
	
	//HookEvent("infected_hurt", infected_hurt, EventHookMode_Post);
	
	RegAdminCmd("sm_defiballbodies", RDeathModelCmd_DefibAll, ADMFLAG_SLAY, "Defib all bodies.");
	RegAdminCmd("sm_convertallbodies", RDeathModelCmd_ConvertAll, ADMFLAG_SLAY, "Turn all bodies to infected.");
	RegAdminCmd("sm_createdeathmodel", RDeathModelCmd_CreateDeathModel, ADMFLAG_CHEATS, "Spawn a death model of yourself.");
	
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
}

void CC_DM_Enable(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_bEnable =	convar.BoolValue;	}
void CC_DM_Behavior(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iBehavior =	convar.IntValue;	}
void CC_DM_ZSurvHP(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_iZSurvHP =	convar.IntValue;	}
void CC_DM_GetUpTime(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_fGetUpTime =	convar.FloatValue;	}
void CC_DM_DefibUseTime(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_fDefibUseTime =	convar.FloatValue;	}
void CC_DM_DefibColor(ConVar convar, const char[] oldValue, const char[] newValue)
{
	convar.GetString(g_strDefibColor, sizeof(g_strDefibColor));
	
	if (IsValidEntity(0))
	{
		int foundEnt = FindEntityByClassname(MAXPLAYERS, DEFIB_CLASS);
		if (foundEnt != -1)
		{
			for (foundEnt = MAXPLAYERS; foundEnt < GetMaxEntities(); foundEnt++)
			{
				if (!RealValidEntity(foundEnt)) continue;
				static char classname[21];
				GetEntityClassname(foundEnt, classname, sizeof(classname));
				if (classname[0] != 'w' || strcmp(classname, DEFIB_CLASS, false) != 0) continue;
				SetVariantString(g_strDefibColor);
				AcceptEntityInput(foundEnt, "Color");
			}
		}
	}
}
void SetCvarValues()
{
	CC_DM_Enable(RDeathModel_Enable, "", "");
	CC_DM_Behavior(RDeathModel_Behavior, "", "");
	CC_DM_ZSurvHP(RDeathModel_ZombieSurvHP, "", "");
	CC_DM_GetUpTime(RDeathModel_GetUpTime, "", "");
	CC_DM_DefibUseTime(RDeathModel_DefibUseTime, "", "");
	CC_DM_DefibColor(RDeathModel_DefibColor, "", "");
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
	
	static char temp_str[128];
	Format(temp_str, sizeof(temp_str), COMMON_VISMDL_TARGETNAME, infected);
	
	int vismdl = FindEntityByTargetname(MAXPLAYERS, temp_str);
	if (!RealValidEntity(vismdl)) return;
	
	AcceptEntityInput(vismdl, "BecomeRagdoll");
	AcceptEntityInput(infected, "Kill");
}*/

public void OnPluginEnd()
{
	int tempEnt = FindEntityByTargetname(MAXPLAYERS, TEMP_ENT);
	if (RealValidEntity(tempEnt))
	{
		AcceptEntityInput(tempEnt, "Kill");
	}
	for (int i = 1; i <= MaxClients; i++ )
	{
		int body = EntRefToEntIndex(g_iDeathModel[i]);
		
		if (RealValidEntity(body))
		{ AcceptEntityInput(body, "Kill"); }
	}
}

public void OnMapStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_fClientWait[i] >= THINK_WAITTIME)
		{
			g_fClientWait[i] = 0.0;
		}
	}
	
	// Precache sounds
	static char temp[PLATFORM_MAX_PATH];
	for( int i = 0; i < sizeof(g_GetUpBill); i++ )
	{
		strcopy(temp, sizeof(temp), g_GetUpBill[i]);
		ReplaceStringEx(temp, sizeof(temp), ".vcd", ".wav");
		ReplaceStringEx(temp, sizeof(temp), "scenes/", "player/survivor/voice/");
		PrecacheSound(temp);
	}
	for( int i = 0; i < sizeof(g_GetUpFrancis); i++ )
	{
		strcopy(temp, sizeof(temp), g_GetUpFrancis[i]);
		ReplaceStringEx(temp, sizeof(temp), ".vcd", ".wav");
		ReplaceStringEx(temp, sizeof(temp), "scenes/", "player/survivor/voice/");
		PrecacheSound(temp);
	}
	for( int i = 0; i < sizeof(g_GetUpLouis); i++ )
	{
		strcopy(temp, sizeof(temp), g_GetUpLouis[i]);
		ReplaceStringEx(temp, sizeof(temp), ".vcd", ".wav");
		ReplaceStringEx(temp, sizeof(temp), "scenes/", "player/survivor/voice/");
		PrecacheSound(temp);
	}
	for( int i = 0; i < sizeof(g_GetUpZoey); i++ )
	{
		strcopy(temp, sizeof(temp), g_GetUpZoey[i]);
		ReplaceStringEx(temp, sizeof(temp), ".vcd", ".wav");
		ReplaceStringEx(temp, sizeof(temp), "scenes/", "player/survivor/voice/");
		PrecacheSound(temp);
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

// Fix defibrillator getting removed on death
public void OnEntityDestroyed(int entity)
{
	static char classname[22];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (classname[0] != 'w' || strcmp(classname, DEFIB_CLASS, false) != 0) return;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	//PrintToServer("owner: %i", owner);
	if (owner == -1 || owner > MaxClients || IsPlayerAlive(owner)) return;
	
	float origin[3], angles[3];
	GetClientEyePosition(owner, origin);
	GetClientAbsAngles(owner, angles);
	CreateDefib(origin, angles);
	//RequestFrame(FrameChangeVelocity, EntIndexToEntRef(defib));
}

/*void FrameChangeVelocity(int defib)
{
	defib = EntRefToEntIndex(defib);
	if (defib == -1) return;
	
	float randAngVel[3];
	randAngVel[0] = (GetRandomInt(-900, 900) + 0.0);
	randAngVel[1] = (GetRandomInt(-900, 900) + 0.0);
	randAngVel[2] = (GetRandomInt(-900, 900) + 0.0);
	SetEntPropVector(defib, Prop_Data, "m_vecAngVelocity", randAngVel);
	
	SetEntPropVector(defib, Prop_Data, "m_vecAbsVelocity", {0.0, 0.0, 45.0});
}*/

/*public void OnEntityCreated(int entity, const char[] classname)
{
	// No need for this.
	if (!g_bEnable)
		return;
	
	if (classname[0] != 'c')
		return;
	
	if (strcmp(classname, "cs_ragdoll", false) == 0)
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
		if (!IsValidClient(client) || !IsSurvivor(client)) return;
		
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
	if (!IsValidClient(owner) || !IsSurvivor(owner)) return;
	
	AcceptEntityInput(entity, "Kill");
}*/

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon/*, int subtype, int cmdnum*/)
{
	if (client == 0) return Plugin_Continue;
	//if (weapon > 0) // If a weapon has been switched to
	//{ PreventHeal(client, weapon, true); return Plugin_Continue; }
	
	//if (!IsFakeClient(client)) PrintToServer("buttons: %i", buttons);
	
	float game_time = GetGameTime();
	bool buttsChanged = false;
	
	bool isAttack2 = view_as<bool>(buttons & IN_ATTACK2);
	bool isAttack = view_as<bool>(buttons & IN_ATTACK);
	
	if (g_fCmdFindBody[client] <= game_time)
	{
		bool useDefaultTimer = true;
		if (isAttack || isAttack2)
		{
			int activeWep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			bool isDefibActive = false;
			if (activeWep != -1)
			{
				static char classname[22];
				GetEntityClassname(activeWep, classname, sizeof(classname));
				isDefibActive = (strcmp(classname, DEFIB_CLASS, false) == 0);
			}
			
			bool onGround = view_as<bool>(GetEntityFlags(client) & FL_ONGROUND);
			bool isOccup = IsOccupied(client);
			int targetBody = EntRefToEntIndex(g_iTargetBody[client]);
			int targetClient = GetClientOfUserId(g_iTargetClient[client]);
			if ((targetBody == -1 || 
					targetClient == 0) && 
					isDefibActive && onGround && !isOccup)
			{
				FindBodyToDefib(client, activeWep);
				//PrintToServer("Defib begin!");
				g_fCmdFindBody[client] = game_time+0.1; useDefaultTimer = false;
			}
			else if (g_fDefibUsedTimer[client] != 0.0)
			{
				if (targetBody != -1 && 
					targetClient != 0 && 
					isDefibActive && onGround && !isOccup)
				{
					if (g_fDefibUsedTimer[client] + g_fDefibUseTime <= game_time)
					{
						DoDefibWithUser(client, targetBody, targetClient, activeWep);
						//PrintToServer("Successful defib!");
					}
				}
				else { ToggleDefibProgress(client, -1, -1, false); /*PrintToServer("Defib interrupted!");*/ }
				g_fCmdFindBody[client] = game_time+0.1; useDefaultTimer = false;
			}
		}
		else if (g_fDefibUsedTimer[client] != 0.0)
		{
			//int targetClient = GetClientOfUserId(g_iTargetClient[client]);
			ToggleDefibProgress(client, -1, -1, false);
			//PrintToServer("Defib button stopped!");
		}
		if (useDefaultTimer) g_fCmdFindBody[client] = game_time+0.5;
	}
	
	if (isAttack2 && (g_fSecondaryDelay[client] > game_time || g_fDefibUsedTimer[client] != 0.0))
	{ buttons &= ~IN_ATTACK2; buttsChanged = true; }
	if (isAttack && g_fDefibUsedTimer[client] != 0.0) { buttons &= ~IN_ATTACK; buttsChanged = true; }
	
	if (buttsChanged) return Plugin_Changed;
	return Plugin_Continue;
}

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
		return Plugin_Continue;
	}
	
	static char name[MAX_NAME_LENGTH], number[10];
	
	Handle menu = CreateMenu(ShowMenu_GiveDefib);
	SetMenuTitle(menu, "Give Defibrillator to:"); 
	
	bool hasEnt = false;
	for (int i = 1; i <= MaxClients; i++) // Get Clients
	{
		if (!IsValidClient(i) || !IsSurvivor(i) || !IsPlayerAlive(i)) continue;
		
		GetClientName(i, name, sizeof(name));
		
		static char temphp[32]; temphp[0] = '\0';
		if (IsPlayerAlive(i) && HasEntProp(i, Prop_Send, "m_healthBuffer"))
		{
			float temphp_fl = GetEntPropFloat(i, Prop_Send, "m_healthBuffer");
			if (temphp_fl > 0.0)
			Format(temphp, sizeof(temphp), "+T%i", RoundToCeil(temphp_fl));
		}
		
		int hp = GetClientHealth(i);
		
		static char status[32]; status[0] = '\0';
		if (IsPlayerAlive(i) && IsIncapacitated(i))
		{ Format(status, sizeof(status), "[DOWN] %i", hp); }
		else if (IsPlayerAlive(i))
		{ Format(status, sizeof(status), "%i", hp); }
		else
		{ strcopy(status, sizeof(status), "DEAD"); }
		
		int character = GetEntProp(i, Prop_Send, "m_survivorCharacter");
		
		static char charletter[6];
		GetCharacterLetter(character, charletter, sizeof(charletter));
		Format(charletter, sizeof(charletter), " %s", charletter); 
		
		static char name_and_hp[MAX_NAME_LENGTH+64];
		Format(name_and_hp, sizeof(name_and_hp), "%s (%s%s%s)", name, status, temphp, charletter);
		
		Format(number, sizeof(number), "%i", GetClientUserId(i)); 
		AddMenuItem(menu, number, name_and_hp);
		if (!hasEnt) hasEnt = true;
	}
	if (!hasEnt) 
	ShowWarning(client, 5);
	
	SetMenuExitButton(menu, true); 
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	
	return Plugin_Continue;
}

int ShowMenu_GiveDefib(Handle menu, MenuAction action, int client, int param2)  
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!IsValidClient(client)) return 0;
			
			static char number[4]; 
			GetMenuItem(menu, param2, number, sizeof(number)); 
			
			int target = GetClientOfUserId(StringToInt(number));
			if (!IsValidClient(target))
			{ ShowWarning(client, 0); return 0; }
			if (!IsPlayerAlive(target))
			{ ShowWarning(client, 7); return 0; }
			
			float origin[3], angles[3];
			GetClientAbsOrigin(target, origin);
			GetClientAbsAngles(target, angles);
			CreateDefib(origin, angles, target);
			
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
	return 0;
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
		if (!IsValidClient(i) || !IsSurvivor(i) || IsPlayerAlive(i)) continue;
		
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
		if (!IsValidClient(i) || !IsSurvivor(i) || IsPlayerAlive(i)) continue;
		
		TurnDeathModelIntoZombie(i, EntRefToEntIndex(g_iDeathModel[i]));
	}*/
	for (int i = 1; i <= GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i) || !HasClassname(i, DEATH_MODEL_CLASS)) continue;
		
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
	int g_iDeathModel_backup = g_iDeathModel[other];
	
	float g_fAnimToDoTimer_backup = g_fAnimToDoTimer[other];
	int g_iAnimToDo_backup = g_iAnimToDo[other];
	
	bool g_bIsIncapped_backup = g_bIsIncapped[other];
	
	float g_fSecondaryDelay_backup = g_fSecondaryDelay[other];
	float g_fCmdFindBody_backup = g_fCmdFindBody[other];
	// Backup the timers for other
	
	// Set the timers of 'other' to 'client'
	g_iDeathModel[other] = g_iDeathModel[client];
	g_iTargetBody[other] = INVALID_ENT_REFERENCE;
	g_iTargetClient[other] = INVALID_ENT_REFERENCE;
	
	g_fAnimToDoTimer[other] = g_fAnimToDoTimer[client];
	g_iAnimToDo[other] = g_iAnimToDo[client];
	
	g_bIsIncapped[other] = g_bIsIncapped[client];
	
	g_fSecondaryDelay[other] = g_fSecondaryDelay[client];
	g_fCmdFindBody[other] = g_fCmdFindBody[client];
	
	// Then use the backed-up 'other' variables for 'client'
	g_iDeathModel[client] = g_iDeathModel_backup;
	g_iTargetBody[client] = INVALID_ENT_REFERENCE;
	g_iTargetClient[client] = INVALID_ENT_REFERENCE;
	
	g_fAnimToDoTimer[client] = g_fAnimToDoTimer_backup;
	g_iAnimToDo[client] = g_iAnimToDo_backup;

	g_bIsIncapped[client] = g_bIsIncapped_backup;
	
	g_fSecondaryDelay[client] = g_fSecondaryDelay_backup;
	g_fCmdFindBody[client] = g_fCmdFindBody_backup;
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
	if (client == 0 || !IsIncapacitated(client, false)) return;
	
	g_bIsIncapped[client] = true;
}

void revive_success(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	if (client == 0 || IsIncapacitated(client, false)) return;
	
	g_bIsIncapped[client] = false;
}

void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0) return;
	
	if (IsIncapacitated(client, false))
	{ g_bIsIncapped[client] = true; }
	else
	{ g_bIsIncapped[client] = false; }
	
	RemoveDeathModel(client);
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int infected = event.GetInt("entityid");
	if (RealValidEntity(infected) && infected > MAXPLAYERS)
	{
		int attacker = event.GetInt("attacker");
		if (!IsValidClient(attacker))
		{ attacker = event.GetInt("attackerentid"); }
		//int health = GetEntProp(infected, Prop_Data, "m_iHealth"); PrintToChatAll("%i", GetEntProp(infected, Prop_Data, "m_lifeState"));
		//if (health > 0) return;
		
		static char temp_str[64];
		Format(temp_str, sizeof(temp_str), COMMON_VISMDL_TARGETNAME, infected);
		
		int vismdl = FindEntityByTargetname(MAXPLAYERS, temp_str);
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
	
	//PrintToChatAll("%i", GetEntProp(client, Prop_Send, "m_isIncapacitated"));
	//g_bTimerRespawn[client] = false;
	//g_bTempGod[client] = false;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0 || !IsSurvivor(client) || IsPlayerAlive(client)) return;
	
	if (!g_bEnable) return;
	
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
	//if (!IsValidClient(client)) return;
	
	int corpse = CreateEntityByName("prop_dynamic_override");
	if (!RealValidEntity(corpse))
	{ return; }
	g_iDeathModel[client] = EntIndexToEntRef(corpse);
	
	float origin[3];
	float angles[3];
	GetClientAbsOrigin(client, origin);
	GetClientEyeAngles(client, angles);
	angles[0] = 0.0; angles[2] = 0.0;
	
	float velfloat[3];
	if (g_iBehavior & BITFLAG_BEHAVIOR_VEL)
	{
		velfloat[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		velfloat[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		velfloat[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	}
	
	TeleportEntity(corpse, origin, angles, velfloat);
	
	static char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	
	SetEntityModel(corpse, cl_model);
	
	//DispatchKeyValue(corpse, "solid", "0");
	//SetEntityRenderMode(corpse, RENDER_GLOW);
	//DispatchKeyValue(corpse, "renderamt", "1");
	DispatchKeyValue(corpse, "fademindist", "1");
	DispatchKeyValue(corpse, "fademaxdist", "1");
	
	DispatchSpawn(corpse);
	ActivateEntity(corpse);
	
	DispatchKeyValue(corpse, "classname", DEATH_MODEL_CLASS);
	
	SetEntityMoveType(corpse, MOVETYPE_STEP);
	
	// movable
	if (g_iBehavior & BITFLAG_BEHAVIOR_HP)
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
	
	SetEntProp(corpse, Prop_Send, "m_bClientSideAnimation", 1);
	
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
	
	static char temp_str[64];
	Format(temp_str, sizeof(temp_str), DEATH_MODEL_VIS, corpse);
	DispatchKeyValue(corpse_vis, "targetname", temp_str);
	//PrintToChatAll(temp_str);
	
	DispatchSpawn(corpse_vis);
	ActivateEntity(corpse_vis);
	
	//SetEntProp(corpse_vis, Prop_Data, "m_bForceServerRagdoll", 1);
	
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
	
	static char blood_ef_name[32];
	Format(blood_ef_name, sizeof(blood_ef_name), "plugin_sdm_blood_ef_%i", EntRefToEntIndex(corpse));
	DispatchKeyValue(blood_ef, "targetname", blood_ef_name);
	
	DispatchSpawn(blood_ef);
	ActivateEntity(blood_ef);
	
	SetVariantString("!activator");
	AcceptEntityInput(blood_ef, "SetParent", corpse);
	
	static char temp_str[64];
	Format(temp_str, sizeof(temp_str), "OnTakeDamage %s:Start:ACT_DIERAGDOLL:0.01:1", EntRefToEntIndex(corpse));
	SetVariantString("OnTakeDamage !self:SetAnimation:ACT_DIERAGDOLL:0.01:1");
	AcceptEntityInput(corpse, "AddOutput");*/
}

void RemoveDeathModel(int client)
{
	int body = EntRefToEntIndex(g_iDeathModel[client]);
	if (!RealValidEntity(body) || !HasClassname(body, DEATH_MODEL_CLASS)) return;
	
	AcceptEntityInput(body, "Kill");
	g_iDeathModel[client] = INVALID_ENT_REFERENCE;
}

void Output_OnHealthChanged(const char[] output, int caller, int activator, float delay)
{
	if (!RealValidEntity(caller) || !HasClassname(caller, DEATH_MODEL_CLASS)) return;
	
	int health = GetEntProp(caller, Prop_Data, "m_iHealth");
	
	// The body has taken enough damage; time to make it ragdoll
	if (health <= DEATH_MODEL_HP_PREVENTKILL)
	{
		//SetIHealth(caller, 1000000); // Set it to a high amount of health so it won't be removed
		SetEntProp(caller, Prop_Data, "m_takedamage", 0); // Disable it from taking damage
		
		static char temp_str[64];
		Format(temp_str, sizeof(temp_str), DEATH_MODEL_VIS, caller);
		int vismdl = FindEntityByTargetname(MAXPLAYERS, temp_str);
		static char vismdl_mdl[128]; vismdl_mdl[0] = '\0';
		if (RealValidEntity(vismdl))
		{
			GetEntPropString(vismdl, Prop_Data, "m_ModelName", vismdl_mdl, sizeof(vismdl_mdl));
			AcceptEntityInput(vismdl, "Kill");
		}
		//PrintToChatAll(temp_str);
		
		static char caller_mdl[128];
		GetEntPropString(caller, Prop_Data, "m_ModelName", caller_mdl, sizeof(caller_mdl));
		
		if (strcmp(caller_mdl, vismdl_mdl, false) != 0) SetEntityModel(caller, vismdl_mdl);
		
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

int FindBodyOwner(int body)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iDeathModel[i] == INVALID_ENT_REFERENCE) continue;
		int entity = EntRefToEntIndex(g_iDeathModel[i]);
		if (!RealValidEntity(entity)) continue;
		
		if (entity == body) return i;
	}
	return -1;
}

void DoDefibWithUser(int client, int body, int bodyOwner = -1, int defib = -1)
{
	if (bodyOwner == -1)
	{
		bodyOwner = FindBodyOwner(body);
		if (bodyOwner == -1) return;
	}
	
	DefibSurvivorOnDeathModel(bodyOwner, body, client);
	
	if (defib == -1) return;
	float game_time_Delay = GetGameTime()+32767.0;
	SetEntPropFloat(defib, Prop_Send, "m_flNextPrimaryAttack", game_time_Delay);
	SetEntPropFloat(defib, Prop_Send, "m_flNextSecondaryAttack", game_time_Delay);
	AcceptEntityInput(defib, "Kill");
}

void DefibSurvivorOnDeathModel(int client, int body, int savior = -1)
{
	if (/*!IsValidClient(client) || */!IsSurvivor(client) || IsPlayerAlive(client) || 
	!RealValidEntity(body) || !HasClassname(body, DEATH_MODEL_CLASS)) return;
	
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
	
	static char cl_model[PLATFORM_MAX_PATH];
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
	
	if (g_fGetUpTime > 0.0) HookThink(client);
	
	for (int i = 0; i <= 4; i++)
	{
		int wep = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (wep == -1) continue;
		
		/*static char temp_str[64];
		GetEntityClassname(wep, temp_str, sizeof(temp_str));
		PrintToChatAll("slot %i, %s", i, temp_str);*/
		SetEntProp(client, Prop_Send, "m_hMyWeapons", -1, i);
		AcceptEntityInput(wep, "Kill");
	}
	GiveWeapon(client, "weapon_pistol");
	
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
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(EntIndexToEntRef(new_weapon));
	RequestFrame(NewWeapon_RequestFrame, data);
}

void NewWeapon_RequestFrame(DataPack data)
{
	data.Reset();
	int userid = data.ReadCell();
	int client = GetClientOfUserId(userid);
	int new_weapon = EntRefToEntIndex(data.ReadCell());
	if (data != null)
	{ CloseHandle(data); }
	
	if (client == 0 || new_weapon == -1) return;
	
	AcceptEntityInput(new_weapon, "Use", client, new_weapon);
	
	static char temp_str[24];
	GetEntityClassname(new_weapon, temp_str, sizeof(temp_str));
	if (strcmp(temp_str, "weapon_pistol") == 0)
	{ RequestFrame(PreventShooting_RequestFrame, userid); }
	
	//float game_time = GetGameTime();
	//float cvar_getup = g_fGetUpTime;
	//SetEntPropFloat(new_weapon, Prop_Send, "m_flNextPrimaryAttack", game_time+cvar_getup);
	//SetEntPropFloat(new_weapon, Prop_Send, "m_flNextSecondaryAttack", game_time+cvar_getup);
}
void PreventShooting_RequestFrame(int client)
{
	client = GetClientOfUserId(client);
	if (client == 0 || !IsPlayerAlive(client)) return;
	
	float gt_plus_getup = GetGameTime()+g_fGetUpTime;
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", gt_plus_getup);
	SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", gt_plus_getup);
}

void TurnDeathModelIntoZombie(int client, int body)
{
	if (!RealValidEntity(body) || !HasClassname(body, DEATH_MODEL_CLASS)) return;
	
	if (IsValidClient(client) && g_iDeathModel[client] != INVALID_ENT_REFERENCE)
		g_iDeathModel[client] = INVALID_ENT_REFERENCE;
	
	DispatchKeyValue(body, "classname", DEATH_MODEL_EXTRA);
	
	float origin[3];
	GetEntPropVector(body, Prop_Data, "m_vecOrigin", origin);
	
	//PrecacheScriptSound("Zombie.BecomeEnraged");
	EmitAmbientGenericSound(origin, "Zombie.Rage");
	
	SetVariantString("ACT_TERROR_INCAP_TO_STAND");
	AcceptEntityInput(body, "SetAnimation");
	
	//SetVariantString("OnUser1 !self:Kill::1.5:1");
	//AcceptEntityInput(body, "AddOutput");
	
	//AcceptEntityInput(body, "FireUser1");
	
	CreateTimer(1.5, Timer_TurnToZombie, EntIndexToEntRef(body), TIMER_FLAG_NO_MAPCHANGE);
}

// Death-Model Functions End // -------------------------------------------------------- //
// Death-Model Timers Start // -------------------------------------------------------- //

Action Timer_TurnToZombie(Handle timer, int body)
{
	body = EntRefToEntIndex(body);
	if (body == -1) return Plugin_Continue;
	
	int infected = CreateEntityByName("infected");
	if (!RealValidEntity(infected))
	{ return Plugin_Continue; }
	
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
	
	SetEntProp(infected, Prop_Data, "m_iHealth", g_iZSurvHP);
	SetEntProp(infected, Prop_Data, "m_iMaxHealth", g_iZSurvHP);
	
	static char cl_model[PLATFORM_MAX_PATH];
	
	static char temp_str[64];
	Format(temp_str, sizeof(temp_str), DEATH_MODEL_VIS, body);
	int vismdl = FindEntityByClassname(MAXPLAYERS, temp_str);
	
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
	return Plugin_Continue;
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
		static char effectclass[64]; 
		GetEntityClassname(effect, effectclass, sizeof(effectclass));
		if (strcmp(effectclass, "entityflame") == 0)
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
		static char effectclass[64]; 
		GetEntityClassname(effect, effectclass, sizeof(effectclass));
		if (strcmp(effectclass, "entityflame") == 0)
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
	
	//SetEntProp(vismdl, Prop_Data, "m_bForceServerRagdoll", 1);
	
	static char temp_str[64];
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
	if (g_fGetUpTime <= 0.0) return false;
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
			float gt_plus_getup = game_time+g_fGetUpTime;
			//SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", g_fGetUpTime);
			
			SetDTCountdownTimer(client, "CTerrorPlayer", "m_stunTimer", g_fGetUpTime);
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
			
			SetDTCountdownTimer(client, "CTerrorPlayer", "m_stunTimer", 0.0);
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
// Defibrillator Start // -------------------------------------------------------- //
// it seems that the defib gets removed on player death
// OnEntityDestroyed remedies this by spawning a new defib
int CreateDefib(const float origin[3], const float angles[3], int client = 0)
{
	int aid = CreateEntityByName(KIT_CLASS);
	if (!RealValidEntity(aid)) return -1;
	
	DispatchKeyValueVector(aid, "origin", origin);
	DispatchKeyValueVector(aid, "angles", angles);
	DispatchKeyValue(aid, "rendermode", "1");
	
	DispatchSpawn(aid);
	ActivateEntity(aid);
	
	DispatchKeyValue(aid, "classname", DEFIB_CLASS);
	
	SetVariantString(g_strDefibColor);
	AcceptEntityInput(aid, "Color");
	
	if (client != 0)
	{
		int slotMED = GetPlayerWeaponSlot(client, 3);
		if (slotMED == -1)
		{ AcceptEntityInput(aid, "Use", client); }
		else
		{
			Event player_use_ev = CreateEvent("player_use");
			player_use_ev.SetInt("userid", GetClientUserId(client));
			player_use_ev.SetInt("targetid", aid);
			player_use_ev.Fire();
		}
	}
	return aid;
}

void player_use(Event event, const char[] name, bool dontBroadcast) // Let defib and first aid be swappable
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0) return;
	int target = event.GetInt("targetid");
	if (!RealValidEntity(target)) return;
	
	int slotMED = GetPlayerWeaponSlot(client, 3);
	if (slotMED == -1) return;
	
	static char classname[21]; GetEntityClassname(target, classname, sizeof(classname));
	if (strcmp(classname, DEFIB_CLASS, false) != 0 && strcmp(classname, KIT_CLASS, false) != 0) return;
	
	static char slotClassname[21]; GetEntityClassname(slotMED, slotClassname, sizeof(slotClassname));
	if (strcmp(slotClassname, DEFIB_CLASS, false) != 0 && strcmp(slotClassname, KIT_CLASS, false) != 0) return;
	//PrintToServer("target: %s, slotMED: %s", classname, slotClassname);
	
	if (strcmp(classname, slotClassname, false) != 0)
	{
		float originTarget[3]; GetClientAbsOrigin(client, originTarget);
		SDKHooks_DropWeapon(client, slotMED, originTarget, NULL_VECTOR);
		AcceptEntityInput(target, "Use", client, target);
	}
}

void item_pickup(Event event, const char[] name, bool dontBroadcast) // Item pickup for defib
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0) return;
	static char item[32];
	event.GetString("item", item, sizeof(item));
	//PrintToServer("item: %s", item);
	
	if (strcmp(item, "defibrillator", false) == 0)
	{
		PrintHintText(client, "YOU PICKED UP A DEFIBRILLATOR");
	}
}

void heal_begin(Event event, const char[] name, bool dontBroadcast) // Heal begin.
{
	//PrintToChatAll("bot_player_replace:");
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (client == 0) return;
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (weapon == -1) return;
	// Stop defib from being used as a first aid
	PreventHeal(client, weapon, false, GetClientOfUserId(event.GetInt("subject")));
}

float g_fRefuseTime[MAXPLAYERS+1];

void PreventHeal(int client, int weapon, bool noBump = false, int target = 0)
{
	static char classname[22];
	GetEntityClassname(weapon, classname, sizeof(classname));
	if (strcmp(classname, DEFIB_CLASS, false) != 0) return;
	
	float game_time = GetGameTime();
	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", game_time+0.5);
	if (target != 0 && target != client)
	{
		SetEntPropFloat(client, Prop_Send, "m_flNextShoveTime", game_time+0.5);
		g_fSecondaryDelay[client] = game_time+0.5;
		// ^ Prevent medkit from being used, it's not restricted to shoving
	}
	
	if (!noBump && !IsFakeClient(client) && g_fDefibUsedTimer[client] == 0.0)
	{
		if (target != 0 && target != client)
		{
			SetVariantString("PlayerNo");
			AcceptEntityInput(client, "DispatchResponse");
		}
		else if (g_fRefuseTime[client] <= game_time)
		{
			//AddOutputToTimerEnt(client, "OnUser1 !activator:DispatchResponse:PlayerNo:0.5:1", "FireUser1");
			//g_fRefuseTime[client] = game_time+2.0;
			AddOutputToTimerEnt(client, "OnUser1 !activator:DispatchResponse:PlayerNo:0.5:1", "FireUser1");
			g_fRefuseTime[client] = GetGameTime()+2.0;
			//AddOutputToTimerEnt(client, "OnUser1 !activator:DispatchResponse:PlayerNo:0.5:1", "FireUser1");
			//g_fRefuseTime[client] = GetGameTime()+4.0;
			
			/*static char contextName[10];
			GetCharContextName(client, contextName, sizeof(contextName));
			static char contextStr[32];
			Format(contextStr, sizeof(contextStr), "%sAskForCover:1:5", contextName);
			SetVariantString(contextStr);
			AcceptEntityInput(client, "AddContext");*/
		}
		SetVariantString("worldTalk:1:1.0");
		AcceptEntityInput(client, "AddContext");
	}
	
	int eFlags = GetEntityFlags(client);
	if (!noBump && eFlags & FL_ONGROUND)
	{
		SetEntityFlags(client, eFlags &~ FL_ONGROUND);
		SetEntProp(client, Prop_Send, "m_hGroundEntity", -1);
		//TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, {0.0, 0.0, 100.0});
		float velocityJump[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocityJump);
		if (velocityJump[2] < 1.0)
		{
			velocityJump[2] = 1.0;
			SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocityJump);
			//SetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]", velocityJump[2]);
		}
		float origin[3];
		GetClientAbsOrigin(client, origin);
		origin[2] += 1.0;
		SetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		//SetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]", velocityJump[2]);
		
		//CreateTimer(0.5, TestTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		/*int buttons = GetEntProp(client, Prop_Data, "m_nButtons");
		if (buttons & IN_ATTACK)
		{
			buttons &= ~IN_ATTACK;
			SetEntProp(client, Prop_Data, "m_nButtons", buttons);
		}*/
	}
	
	if (!noBump && g_fDefibUsedTimer[client] == 0.0)
		PrintHintText(client, "THIS IS A DEFIBRILLATOR, USE IT ON DEAD TEAMMATES");
}

/*void GetCharContextName(int client, char[] str, int charSize)
{
	int survChar = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	switch (survChar)
	{
		case 0: strcopy(str, charSize, "NamVet"); // bill
		case 1: strcopy(str, charSize, "TeenGirl"); //zoey
		case 2: strcopy(str, charSize, "Manager"); //louis
		case 3: strcopy(str, charSize, "Biker");//francis
	}
}*/

void FindBodyToDefib(int client, int defib = -1)
{
	if (FindEntityByClassname(MAXPLAYERS, DEATH_MODEL_CLASS) == -1) return;
	
	float origin[3];
	GetClientEyePosition(client, origin);
	
	int closestBody = -1;
	float distance = -1.0;
	for (int i = MAXPLAYERS; i < GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i) || !HasClassname(i, DEATH_MODEL_CLASS)) continue;
		
		float bodyOrigin[3];
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", bodyOrigin);
		float checkDist = GetVectorDistance(origin, bodyOrigin, true) / 2;
		if (closestBody == -1 || checkDist < distance)
		{
			closestBody = i;
			distance = checkDist;
		}
	}
	//PrintToServer("closestBody: %i, distance: %f", closestBody, distance);
	if (distance > 5000) return;
	
	static char model[31];
	GetEntPropString(client, Prop_Data, "m_ModelName", model, sizeof(model));
	switch( model[29] )
	{
		case 'v': VocalizeScene(client, g_GetUpBill[GetRandomInt(0, sizeof(g_GetUpBill) - 1)]);
		case 'e': VocalizeScene(client, g_GetUpFrancis[GetRandomInt(0, sizeof(g_GetUpFrancis) - 1)]);
		case 'a': VocalizeScene(client, g_GetUpLouis[GetRandomInt(0, sizeof(g_GetUpLouis) - 1)]);
		case 'n': VocalizeScene(client, g_GetUpZoey[GetRandomInt(0, sizeof(g_GetUpZoey) - 1)]);
	}
	
	if (g_fDefibUseTime <= 0.0)
	{ DoDefibWithUser(client, closestBody, -1, defib); }
	else
	{
		ToggleDefibProgress(client, closestBody);
		float velocityAbs[3];
		GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocityAbs);
		velocityAbs[0] = 0.0; velocityAbs[1] = 0.0;
		SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocityAbs);
	}
	
	//5000
	/*float origin[3], angles[3];
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	//angles[0] *= 400; angles[1] *= 400; angles[2] *= 400;
	TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);
	
	PrintToServer("Trace result: %i", TR_GetEntityIndex());*/
	
	//return closestBody;
}

void ToggleDefibProgress(int client, int body = -1, int bodyOwner = -1, bool boolean = true)
{
	switch (boolean)
	{
		case true:
		{
			if (body == -1) return;
			if (bodyOwner == -1)
			{
				bodyOwner = FindBodyOwner(body);
				if (bodyOwner == -1) return;
			}
			float game_time = GetGameTime();
			
			g_iTargetBody[client] = EntIndexToEntRef(body);
			g_iTargetClient[client] = GetClientUserId(bodyOwner);
			
			SetEntProp(client, Prop_Send, "m_iProgressBarDuration", RoundToNearest(g_fDefibUseTime));
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", game_time);
			static char defibStr[48];
			Format(defibStr, sizeof(defibStr), "USING DEFIBRILLATOR on %N", bodyOwner);
			SetEntPropString(client, Prop_Send, "m_progressBarText", defibStr);
			
			float gt_plus_usetime = game_time+g_fDefibUseTime;
			SetDTCountdownTimer(client, "CTerrorPlayer", "m_stunTimer", g_fDefibUseTime);
			SetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil", gt_plus_usetime);
			
			g_fAnimToDoTimer[client] = gt_plus_usetime;
			g_iAnimToDo[client] = GetAnimation(client, "Heal_Incap_Standing");
			SDKHook(client, POST_THINK_HOOK, Hook_OnThinkPost); g_fClientWait[client] = 0.0;
			SetEntPropFloat(client, Prop_Send, "m_mainSequenceStartTime", game_time);
			
			GotoThirdPerson(client);
			g_fDefibUsedTimer[client] = game_time;
			
			SetVariantString("worldTalk:1:1.0");
			AcceptEntityInput(client, "AddContext");
		}
		case false:
		{
			g_fAnimToDoTimer[client] = -1.0;
			g_iAnimToDo[client] = -1;
			
			g_iTargetBody[client] = INVALID_ENT_REFERENCE;
			g_iTargetClient[client] = INVALID_ENT_REFERENCE;
			
			SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
			SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
			SetEntPropString(client, Prop_Send, "m_progressBarText", "");
			
			SetDTCountdownTimer(client, "CTerrorPlayer", "m_stunTimer", 0.0);
			SetEntPropFloat(client, Prop_Send, "m_jumpSupressedUntil", 0.0);
			
			SDKUnhook(client, POST_THINK_HOOK, Hook_OnThinkPost);
			
			GotoFirstPerson(client);
			g_fDefibUsedTimer[client] = 0.0;
		}
	}
}

/*bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if (entity == data) // Check if the TraceRay hit the itself.
		{ return false; } // Don't let the entity be hit
	return true; // It didn't hit itself
}*/

/*Action TestTimer(Handle timer, int client)
{
	PrintToServer("useEnt: %i", GetEntPropEnt(client, Prop_Data, "m_hUseEntity"));
}*/

/*void HudHint(int client, const char[] format, any ...)
{
	static char sBuffer[128]; 
	VFormat(sBuffer, sizeof(sBuffer), format, 2); 
	
	int hudHintEnt = CreateEntityByName("env_hudhint");
	DispatchKeyValue(hudHintEnt, "message", sBuffer);
	
	DispatchSpawn(hudHintEnt);
	AcceptEntityInput(hudHintEnt, "ShowHudHint", client);
	
	DataPack dataP = CreateDataPack();
	CreateDataTimer(5.0, DestroyHudHint, dataP, TIMER_FLAG_NO_MAPCHANGE);
	dataP.WriteCell(GetClientUserId(client));
	dataP.WriteCell(EntIndexToEntRef(hudHintEnt));
	
	//SetVariantString("OnUser1 !self:HideHudHint:!activator:8.0:1");
	//AcceptEntityInput(hudHintEnt, "AddOutput");
	//SetVariantString("OnUser1 !self:Kill::8.1:1");
	//AcceptEntityInput(hudHintEnt, "AddOutput");
	//AcceptEntityInput(hudHintEnt, "FireUser1", client);
}*/

/*Action DestroyHudHint(Handle timer, DataPack dataP)
{
	dataP.Reset();
	int client = GetClientOfUserId(dataP.ReadCell());
	int hudHintEnt = EntRefToEntIndex(dataP.ReadCell());
	if (client == 0 || hudHintEnt == -1) return Plugin_Continue;
	
	AcceptEntityInput(hudHintEnt, "HideHudHint", client);
	AcceptEntityInput(hudHintEnt, "Kill", client);
	
	return Plugin_Continue;
}*/

// Defibrillator End // -------------------------------------------------------- //
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
		if (!IsValidClient(client) || !IsSurvivor(client) || !IsPlayerAlive(client) || IsIncapacitated(client, 1)) continue;
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
		case 7:
		{ PrintToChatOrServer(client, "[SM] Client is dead!"); }
	}
}

void PrintToChatOrServer(int client, const char[] str, any ...)
{
	static char sBuffer[512]; 
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
		static char class[64];
		GetEntityClassname(i, class, sizeof(class));
		if (strcmp(class, DEATH_MODEL_CLASS, false) != 0) continue;
		
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
	
	static char cl_model[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", cl_model, sizeof(cl_model));
	SetEntityModel(temp, cl_model);
	
	SetVariantString(sequence);
	AcceptEntityInput(temp, "SetAnimation");
	
	int sequence_int = GetEntProp(temp, Prop_Send, "m_nSequence");
	
	RemoveEdict(temp);
	
	return sequence_int;
}

int FindEntityByTargetname(int index, const char[] findname)
{
	for (int i = index; i < GetMaxEntities(); i++) {
		if (!RealValidEntity(i)) continue;
		static char name[64];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (strcmp(name, findname, false) != 0) continue;
		return i;
	}
	return -1;
}

/*bool HasTargetname(int entity, const char[] targetname)
{
	static char name[64];
	GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	if (strcmp(name, targetname, false) == 0) return true;
	
	return false;
}*/

bool HasClassname(int entity, const char[] targetname)
{
	static char name[64];
	//GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
	GetEntityClassname(entity, name, sizeof(name));
	if (strcmp(name, targetname, false) == 0) return true;
	
	return false;
}

void VocalizeScene(int client, const char[] scenefile)
{
	int entity = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(entity, "SceneFile", scenefile);
	DispatchSpawn(entity);
	SetEntPropEnt(entity, Prop_Data, "m_hOwner", client);
	ActivateEntity(entity);
	AcceptEntityInput(entity, "Start", client, client);
}

void EmitAmbientGenericSound(float pos[3], const char[] snd_str)
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
	int temp_ent = FindEntityByTargetname(MAXPLAYERS, TEMP_ENT);
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

/*float GetDTCountdownTimer(int entity, const char[] classname, const char[] timer_str)
{
	int info = FindSendPropInfo(classname, timer_str);
	return GetEntDataFloat(entity, (info+4));
}*/

void SetDTCountdownTimer(int entity, const char[] classname, const char[] timer_str, float duration)
{
	int info = FindSendPropInfo(classname, timer_str);
	SetEntDataFloat(entity, (info+4), duration, true);
	SetEntDataFloat(entity, (info+8), GetGameTime()+duration, true);
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
{ return (GetClientTeam(client) == 2); }

bool IsZoey(int client)
{
	static char cl_model[PLATFORM_MAX_PATH];
	GetEntPropString(client, Prop_Data, "m_ModelName", cl_model, sizeof(cl_model));
	
	if (StrContains(cl_model, "teenangst", false) >= 0) return true;
	return false;
}

bool IsOccupied(int client)
{
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (hunter != -1 || smoker != -1) return true;
	
	static char netprop_strs[2][24] = 
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
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

// Others End // -------------------------------------------------------- //