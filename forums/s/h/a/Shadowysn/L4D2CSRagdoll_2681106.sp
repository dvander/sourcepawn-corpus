#define PLUGIN_NAME "[L4D2] Consistent Client-sided Survivor Ragdolls"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Enable survivor ragdolls on all deaths!"
#define PLUGIN_VERSION "1.0.9"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2673001"
#define PLUGIN_NAME_SHORT "Consistent Client-sided Survivor Ragdolls"
#define PLUGIN_NAME_TECH "c_survivor_ragdoll"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <adminmenu>

#pragma newdecls required
#pragma semicolon 1

//#define EF_NODRAW 32

ConVar version_cvar;
ConVar RagdollModeEnabled;
ConVar RemoveStaticBody;
ConVar RagdollNoLimit;
//ConVar DropSecondary;
ConVar LedgeEnabled;
static bool g_IsSequel;

bool g_Falling[MAXPLAYERS+1] = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		g_IsSequel = true;
		return APLRes_Success;
	}
	else if(GetEngineVersion() == Engine_Left4Dead)
	{
		g_IsSequel = false;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
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

TopMenu hTopMenu;

public void OnPluginStart()
{
	version_cvar = CreateConVar("sm_custom_survivor_ragdoll_ver", PLUGIN_VERSION, "Consistent-Survivor Ragdoll plugin version", 0|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	if (g_IsSequel)
	{
		char temp_str[128];
		
		RagdollModeEnabled = CreateConVar("sm_custom_survivor_ragdoll", "1", "Toggle usage of non-ledge based ragdoll deaths.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
		
		Format(temp_str, sizeof(temp_str), "sm_%s_staticbody", PLUGIN_NAME_TECH);
		RemoveStaticBody = CreateConVar(temp_str, "0", "0 - Make static body invisible. 1 - Remove static body. 2 - Do nothing.", FCVAR_ARCHIVE, true, 0.0, true, 2.0);
		Format(temp_str, sizeof(temp_str), "sm_%s_nolimit", PLUGIN_NAME_TECH);
		RagdollNoLimit = CreateConVar(temp_str, "0", "0 - Use game's preferred ragdoll limits. 1 - Use CI ragdoll limits. (Beware - this could wreak havoc on older computers!)", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
		//DropSecondary = CreateConVar("sm_c_survivor_ragdoll_drop_pistol", "0", "Toggle whether players should drop their pistol slot upon death.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
		
		Format(temp_str, sizeof(temp_str), "sm_%s_ledge", PLUGIN_NAME_TECH);
		LedgeEnabled = CreateConVar(temp_str, "1", "Toggle preventing ledge deaths from making victims unrevivable.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
		
		HookEvent("player_death", Player_Death, EventHookMode_Pre);
		//HookEvent("player_death", Player_Death_Pre, EventHookMode_Pre);
		//HookEvent("player_hurt", Player_Hurt_Pre, EventHookMode_Pre);
		//HookEvent("player_ledge_release", Player_LedgeRelease, EventHookMode_Post);
		HookEvent("player_ledge_grab", Player_LedgeGrab, EventHookMode_Post);
	}
	RegAdminCmd("sm_ragdoll", Command_Ragdoll, ADMFLAG_CHEATS, "Spawn a client ragdoll on yourself.");
	//RegAdminCmd("sm_testrag_ply", Command_RagdollPly, ADMFLAG_CHEATS, "Ragdoll Test on Players");
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
	AutoExecConfig(true);
}

public void OnPluginEnd()
{
	UnhookEvent("player_death", Player_Death, EventHookMode_Pre);
	//UnhookEvent("player_death", Player_Death_Pre, EventHookMode_Pre);
	//UnhookEvent("player_ledge_release", Player_LedgeRelease, EventHookMode_Post);
	UnhookEvent("player_ledge_grab", Player_LedgeGrab, EventHookMode_Post);
	for (int loopclient = 1; loopclient <= MAXPLAYERS; loopclient++)
	{
		if (!IsValidClient(loopclient)) continue;
		if (!IsSurvivor(loopclient)) continue;
		SDKUnhook(loopclient, SDKHook_PostThinkPost, PlayerCheckRelease);
	}
}

public void CreateRagdoll(int client)
{
	if (!IsValidClient(client) || (!IsSurvivor(client) && GetClientTeam(client) != 3))
	return;
	
	int Ragdoll = CreateEntityByName("cs_ragdoll");
	float fPos[3];
	float fAng[3];
	//GetEntPropVector(client, Prop_Data, "m_vecOrigin", fPos);
	//GetEntPropVector(client, Prop_Data, "m_angRotation", fAng);
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	
	TeleportEntity(Ragdoll, fPos, fAng, NULL_VECTOR);
	
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollOrigin", fPos);
	SetEntProp(Ragdoll, Prop_Send, "m_nModelIndex", GetEntProp(client, Prop_Send, "m_nModelIndex"));
	SetEntProp(Ragdoll, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntPropEnt(Ragdoll, Prop_Send, "m_hPlayer", client);
	SetEntProp(Ragdoll, Prop_Send, "m_iDeathPose", GetEntProp(client, Prop_Send, "m_nSequence"));
	SetEntProp(Ragdoll, Prop_Send, "m_iDeathFrame", GetEntProp(client, Prop_Send, "m_flAnimTime"));
	SetEntProp(Ragdoll, Prop_Send, "m_nForceBone", 0);
	/*float velfloat[3];
	if (g_IsSequel)
	{
		velfloat[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]")*30;
		velfloat[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]")*30;
		velfloat[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]")*30;
	}
	else
	{
		velfloat[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
		velfloat[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
		velfloat[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
	}
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecForce", velfloat);*/
	
	if (IsSurvivor(client))
	{
		if (!GetConVarBool(RagdollNoLimit))
		{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 4); }
		else
		{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 1); }
		SetEntProp(Ragdoll, Prop_Send, "m_survivorCharacter", GetEntProp(client, Prop_Send, "m_survivorCharacter", 1), 1);
	}
	else if (GetClientTeam(client) == 3)
	{
		int infclass = GetEntProp(client, Prop_Send, "m_zombieClass", 1);
		if (GetConVarBool(RagdollNoLimit))
		{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 1); }
		else if (infclass == 8)
		{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 3); }
		else
		{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 2); }
		SetEntProp(Ragdoll, Prop_Send, "m_zombieClass", infclass, 1);
		
		int effect = GetEntPropEnt(client, Prop_Send, "m_hEffectEntity");
		if (IsValidEntity(effect))
		{
			char effectclass[64]; 
			GetEntityClassname(effect, effectclass, sizeof(effectclass));
			if (StrEqual(effectclass, "entityflame"))
			{ SetEntProp(Ragdoll, Prop_Send, "m_bOnFire", 1, 1); }
		}
	}
	else
	{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 1); }
	
	int prev_ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (!IsPlayerAlive(client) && !IsValidEntity(prev_ragdoll))
	{
		//SetEntProp(client, Prop_Send, "m_bClientSideRagdoll", 1);
		SetEntPropEnt(client, Prop_Send, "m_hRagdoll", Ragdoll);
	}
	else
	{
		//CreateTimer(1.5, Timer_RemoveInvis, client, TIMER_FLAG_NO_MAPCHANGE);
		//int EFlags = GetEntProp(client, Prop_Send, "m_fEffects");
		//EFlags &= EF_NODRAW;
		//SetEntProp(client, Prop_Send, "m_fEffects", EFlags);
		SetVariantString("OnUser1 !self:Kill::1.0:1");
		AcceptEntityInput(Ragdoll, "AddOutput");
		AcceptEntityInput(Ragdoll, "FireUser1");
	}
}

/*Action Timer_RemoveInvis(Handle timer, int client)
{
	if (!IsValidEntity(client) || !IsClientInGame(client)) return;
	//if (IsPlayerAlive(client))
	//{
		int EFlags = GetEntProp(client, Prop_Send, "m_fEffects");
		EFlags &= ~EF_NODRAW;
		SetEntProp(client, Prop_Send, "m_fEffects", EFlags);
	//}
}*/

Action Command_Ragdoll(int client, any args)
{
	if (!IsClientInGame(client))
	{
		ReplyToCommand(client, "[SM] You are not in-game!");
		return Plugin_Handled;
	}
	if (!IsSurvivor(client) && GetClientTeam(client) != 3)
	{
		ReplyToCommand(client, "[SM] You are not on a valid team!");
		return Plugin_Handled;
	}
	
	CreateRagdoll(client);
	
	return Plugin_Handled;
}

/*public Action Command_RagdollPly(int client, any args)
{
	if (args < 1 || args > 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_testrag_ply <player> - test a ragdoll");
		return Plugin_Handled;
	}
	char plyent[64];
	GetCmdArg(1, plyent, sizeof(plyent));
	
	int player = FindTarget(client, plyent);
	
	if ( player == -1 )
	{
		ReplyToCommand(client, "[SM] There is no player!");
		return Plugin_Handled;
	}
	if ( !IsClientInGame(player) )
	{
		ReplyToCommand(client, "[SM] They are not in-game!");
		return Plugin_Handled;
	}
	if (!IsSurvivor(player) && GetClientTeam(player) != 3)
	{
		ReplyToCommand(client, "[SM] They are not on a valid team!");
		return Plugin_Handled;
	}
	
	CreateRagdoll(client);
	return Plugin_Handled;
}*/

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!g_IsSequel || !GetConVarBool(RagdollModeEnabled))
		return;
	
	if(classname[0] != 's' )
		return;
	
	if(StrEqual(classname, "survivor_death_model", false))
		SDKHook(entity, SDKHook_SpawnPost, SpawnPostDeathModel);
}

public void SpawnPostDeathModel(int entity)
{
	SDKUnhook(entity, SDKHook_SpawnPost, SpawnPostDeathModel);
	if(!IsValidEntity(entity)) return;
	
	int death_model = EntIndexToEntRef(entity);
	
	int conVar_body = GetConVarInt(RemoveStaticBody);
	if (conVar_body < 1)
	{ SetEntityRenderMode(death_model, RENDER_NONE); }
	else if (conVar_body == 1)
	{ AcceptEntityInput(death_model, "Kill"); }
}

/*public void Player_Death_Pre(Handle event, const char[] name, bool dontbroadcast)
{ // It's too late to drop the weapon, as it's already been removed.
	int userID = GetEventInt(event, "userid");
	int user = GetClientOfUserId(userID);
	if (!IsValidClient(user))
	return;
	
	if (!IsSurvivor(user))
	return;
	
	if (GetConVarBool(DropSecondary))
	{
		int weapon = GetPlayerWeaponSlot(user, 1); // 1 = Secondary
		if (IsValidEntity(weapon))
		{ SDKHooks_DropWeapon(user, weapon); }
	}
}*/

public void Player_Death(Handle event, const char[] name, bool dontbroadcast)
{
	int userID = GetEventInt(event, "userid");
	int user = GetClientOfUserId(userID);
	if (!IsValidClient(user))
	return;
	if (IsPlayerAlive(user))
	return;
	
	if (g_Falling[user])
	{ g_Falling[user] = false; }
	
	if(!g_IsSequel || !GetConVarBool(RagdollModeEnabled))
	return;
	
	if (!IsSurvivor(user) || IsValidEntity(GetEntPropEnt(user, Prop_Send, "m_hRagdoll")))
	return;
	
	CreateRagdoll(user);
}

/*public void Player_LedgeRelease(Handle event, const char[] name, bool dontbroadcast)
{
	PrintToChatAll("LedgeRelease");
	int userID = GetEventInt(event, "userid");
	int user = GetClientOfUserId(userID);
	if (!IsValidClient(user))
	return;
	
	PrintToChatAll("%i", user);
}*/

public void Player_LedgeGrab(Handle event, const char[] name, bool dontbroadcast)
{
	//PrintToChatAll("LedgeGrab");
	
	if(!g_IsSequel || !GetConVarBool(RagdollModeEnabled) || !GetConVarBool(LedgeEnabled))
		return;
	
	int userID = GetEventInt(event, "userid");
	int user = GetClientOfUserId(userID);
	if (!IsValidClient(user))
	return;
	
	if (!IsPlayerAlive(user))
	return;
	
	if (!IsSurvivor(user))
	return;
	
	//PrintToChatAll("Hooked!");
	//SDKHook(user, SDKHook_TouchPost, PlayerCheckGround);
	SDKHook(user, SDKHook_PostThinkPost, PlayerCheckRelease);
}
/*
public void PlayerCheckGround(int client)
{
	//PrintToChatAll("LedgeTouch");
	if (!IsValidClient(client) || !IsPlayerAlive(client) || !g_Falling[client])
	{ SDKUnhook(client, SDKHook_TouchPost, PlayerCheckGround); g_Falling[client] = false; return; }
	
	int ground_ent = GetEntProp(client, Prop_Send, "m_hGroundEntity");
	if(IsValidClient(client) && IsSurvivor(client) && ground_ent > -1 && 
	g_Falling[client])
	{
		if (IsPlayerAlive(client))
		{
			//ForcePlayerSuicide(client);
			//PrintToChatAll("dead");
			//SetEntProp(client, Prop_Send, "m_currentReviveCount", GetConVarInt(FindConVar("survivor_max_incapacitated_count")));
			//SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
			SDKHooks_TakeDamage(client, client, client, 10000.0, DMG_FALL, -1);
			//SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0, 1);
			//SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			//AcceptEntityInput(client, "SetHealth", client, -1, 0);
		}
		SDKUnhook(client, SDKHook_TouchPost, PlayerCheckGround);
	}
}
*/
public void PlayerCheckRelease(int client) // The ledge release event hook didn't work for me, sorry about this code.
{
	//PrintToChatAll("LedgeThink");
	int GetIsHanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	int GetIsFalling = GetEntProp(client, Prop_Send, "m_isFallingFromLedge");
	if(IsValidClient(client) && IsSurvivor(client) && IsPlayerAlive(client))
	{
		if (GetIsFalling > 0)
		{
			//return;
			SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0, 1);
			//SetEntProp(client, Prop_Send, "m_currentReviveCount", GetConVarInt(FindConVar("survivor_max_incapacitated_count")));
			//SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
			//SetEntProp(client, Prop_Send, "m_isIncapacitated", 1, 1);
			//SetEntityHealth(client, 50);
			SetEntProp(client, Prop_Send, "m_hGroundEntity", -1);
			AcceptEntityInput(client, "DisableLedgeHang");
			g_Falling[client] = true;
		}
		if (GetIsFalling <= 0 && GetIsHanging <= 0 && !g_Falling[client])
		{ SDKUnhook(client, SDKHook_PostThinkPost, PlayerCheckRelease); }
		/*if (g_Falling[client] && GetIsHanging > 0)
		{
			SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0, 1);
			//SetEntProp(client, Prop_Send, "m_isIncapacitated", 0, 1);
		}*/
	}
	
	//PrintToChatAll("LedgeTouch");
	if (!IsValidClient(client) || !IsPlayerAlive(client))
	{ SDKUnhook(client, SDKHook_PostThinkPost, PlayerCheckRelease); g_Falling[client] = false; return; }
	
	int ground_ent = GetEntProp(client, Prop_Send, "m_hGroundEntity");
	int GetIsIncap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	if(IsValidClient(client) && IsSurvivor(client) && (ground_ent > -1 || GetIsIncap) && 
	g_Falling[client])
	{
		if (IsPlayerAlive(client))
		{
			//PrintToChatAll("dead");
			//SetEntProp(client, Prop_Send, "m_currentReviveCount", GetConVarInt(FindConVar("survivor_max_incapacitated_count")));
			//SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
			SetEntityHealth(client, 1);
			SDKHooks_TakeDamage(client, 0, 0, 10000.0, DMG_FALL, -1);
		}
		SDKUnhook(client, SDKHook_PostThinkPost, PlayerCheckRelease);
	}
}

// Below code is for the Menu.
public void AdminMenu_RagdollTest(TopMenu topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Spawn ragdoll on", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		TestRagdollMenu(param);
	}
}

void TestRagdollMenu(int client)
{
	Menu menu = new Menu(MenuHandler_TestRagdoll);
	
	char title[100];
	Format(title, sizeof(title), "Spawn ragdoll on:", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, false);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_TestRagdoll(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(client, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);
		
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(client, "[SM] Player no longer available");
		}
		else if (!CanUserTarget(client, target))
		{
			PrintToChat(client, "[SM] Unable to target");
		}
		else
		{
			CreateRagdoll(target);
		}
		
		if (IsClientInGame(client) && !IsClientInKickQueue(client))
		{
			TestRagdollMenu(client);
		}
	}
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if (topmenu == hTopMenu)
	{
		return;
	}
	
	hTopMenu = topmenu;
	
	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_testragmenu", AdminMenu_RagdollTest, player_commands, "sm_testragmenu", ADMFLAG_CHEATS);
	}
}

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) == 2 || GetClientTeam(client) == 4) return true;
	
	return false;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	//if (!IsValidEntity(client)) return false;
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}