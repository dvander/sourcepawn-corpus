#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <PathFollower>
#pragma newdecls optional
#include <tf2_flag>
#include <tf2_meter>
#include <weapons>

int g_bPathFinding[MAXPLAYERS+1];

float g_flGoal[MAXPLAYERS + 1][3];
float g_flClientEyePos[MAXPLAYERS + 1][3];
float g_flClientPos[MAXPLAYERS + 1][3];
float g_flLookPos[MAXPLAYERS + 1][3];

float g_flDemoAttackTimer[MAXPLAYERS + 1];

float g_flRedFlagCapPoint[3];
float g_flBluFlagCapPoint[3];

int g_bMedicAllHaveTasks[MAXPLAYERS+1];

int g_bFindNewDefendSpot[MAXPLAYERS+1];

float g_flDefendPosChangeTimer[MAXPLAYERS + 1];

float g_flRandomDefendArea[MAXPLAYERS + 1][3];
float g_flSelectedDefendArea[MAXPLAYERS + 1][3];

int g_bAfkbot[MAXPLAYERS+1];
float g_flLookAtLastKnownEnemyPos[MAXPLAYERS + 1][3];
float g_flSpawnLocation[MAXPLAYERS + 1][3];
float g_flLastDiedArea[MAXPLAYERS + 1][3];
int g_bIsSlowThink[MAXPLAYERS+1];
int g_bSpyAlert[MAXPLAYERS+1];
int g_bISeeSpy[MAXPLAYERS+1];
int g_bFindLastDiedArea[MAXPLAYERS+1];
int g_bUseTeleporter[MAXPLAYERS + 1];
Handle AttackTimer;
Handle SnipeTimer;
Handle RepeartAttackTimer;

int g_bFindNewDefendPayloadSpot[MAXPLAYERS+1];

float g_flPayloadDefendPosChangeTimer[MAXPLAYERS + 1];

float g_flRandomPayloadDefendArea[MAXPLAYERS + 1][3];
float g_flSelectedPayloadDefendArea[MAXPLAYERS + 1][3];

float g_flJumpTimer[MAXPLAYERS + 1];
float g_flWaitJumpTimer[MAXPLAYERS + 1];

float g_flFindNearestHealthTimer[MAXPLAYERS + 1];
float g_flFindNearestAmmoTimer[MAXPLAYERS + 1];

float g_flNearestAmmoOrigin[MAXPLAYERS + 1][3];
float g_flNearestHealthOrigin[MAXPLAYERS + 1][3];

float g_flEngineerPickNewSpotTimer[MAXPLAYERS + 1];

float g_flIdlingTime[MAXPLAYERS + 1];

bool g_bIdleTime[MAXPLAYERS+1];

bool g_bRepairSentry[MAXPLAYERS+1];
bool g_bRepairDispenser[MAXPLAYERS+1];

bool g_bBuildSentry[MAXPLAYERS+1];
bool g_bBuildDispenser[MAXPLAYERS+1];

int g_bPickUnUsedSentrySpot[MAXPLAYERS + 1];

float g_bSentryBuildPos[MAXPLAYERS + 1][3];
float g_bSentryBuildAngle[MAXPLAYERS + 1][3];

int g_bPickRandomSniperSpot[MAXPLAYERS+1];
int g_bCamping[MAXPLAYERS+1];

float g_flSniperChangeSpotTimer[MAXPLAYERS + 1];

float g_flSniperLookTimer[MAXPLAYERS + 1];

float g_flSniperFastShotTimer[MAXPLAYERS + 1];
float g_flSniperPerfectShotTimer[MAXPLAYERS + 1];

float g_flSniperRange[MAXPLAYERS + 1];

float g_flRandomSniperSpotPos[MAXPLAYERS + 1][3];
float g_flSniperSpotPos[MAXPLAYERS + 1][3];
float g_flSniperCurrentAim[MAXPLAYERS + 1][3];
float g_flSniperAim1[MAXPLAYERS + 1][3];
float g_flSniperAim2[MAXPLAYERS + 1][3];
float g_flSniperAim3[MAXPLAYERS + 1][3];
float g_flSniperAim4[MAXPLAYERS + 1][3];

float g_flLookTimer[MAXPLAYERS + 1];

int g_bSentryBuilded[MAXPLAYERS + 1];
int g_bSentryIsMaxLevel[MAXPLAYERS + 1];
int g_bSentryHealthIsFull[MAXPLAYERS + 1];
int g_bCanBuildSentryGun[MAXPLAYERS + 1];
int g_bDispenserBuilded[MAXPLAYERS + 1];
int g_bDispenserIsMaxLevel[MAXPLAYERS + 1];
int g_bDispenserHealthIsFull[MAXPLAYERS + 1];
int g_bCanBuildDispenser[MAXPLAYERS + 1];
int g_bCanBuildTeleporter[MAXPLAYERS + 1];
int g_bTeleporterEnterBuilded[MAXPLAYERS + 1];
int g_bTeleporterEnterHealthIsFull[MAXPLAYERS + 1];
int g_bTeleporterEnterIsMaxLevel[MAXPLAYERS + 1];
int g_bTeleporterExitHealthIsFull[MAXPLAYERS + 1];
int g_bTeleporterExitIsMaxLevel[MAXPLAYERS + 1];
int g_bTeleporterExitBuilded[MAXPLAYERS + 1];

int g_bBotIsDied[MAXPLAYERS + 1];

int g_bHealthIsLow[MAXPLAYERS + 1];
int g_bAmmoIsLow[MAXPLAYERS + 1];
int g_bMoveSentry[MAXPLAYERS + 1];
int g_bSapBuildings[MAXPLAYERS + 1];
int g_bSpyHaveAnyTask[MAXPLAYERS + 1];
int g_bBackStabVictim[MAXPLAYERS + 1];
int g_bMaxStickies[MAXPLAYERS + 1];
int g_bMakeStickyTrap[MAXPLAYERS + 1];

float g_flVoiceNoTimer[MAXPLAYERS + 1];

float g_flAutoLookTimer[MAXPLAYERS + 1];

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

float moveBackwards(float vel[3],float MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

float moveRight(float vel[3],float MaxSpeed)
{
	vel[1] = MaxSpeed;
	return vel;
}

float moveLeft(float vel[3],float MaxSpeed)
{
	vel[1] = -MaxSpeed;
	return vel;
}

#define PLUGIN_VERSION  "1.1"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.afkbot.cfg"

public Plugin:myinfo = 
{
	name = "[TF2] AFK Bot",
	author = "EfeDursun125",
	description = "AI for afk players",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198039186809"
}

Handle AFKBOT_MaxIdleTime;
Handle AFKBOT_FindLastDiedAreaChance;
Handle AFKBOT_MinAimSpeed;
Handle AFKBOT_MaxAimSpeed;
Handle AFKBOT_LookAroundMaxDown;
Handle AFKBOT_LookAroundMaxUp;
Handle AFKBOT_MinAimSpeedWhenZoomed;
Handle AFKBOT_MaxAimSpeedWhenZoomed;
Handle AFKBOT_PathTimer;
Handle AFKBOT_AimTimer;

public OnPluginStart()
{
	ServerCommand("sv_tags afkbot");
	AddServerTag("afkbot"); // This is not working, i know but, i'm trying this
	
	LoadTranslations("common.phrases.txt");
	RegConsoleCmd("sm_afk", Command_Afk);
	RegConsoleCmd("sm_bot_add", AutoAddBot);
	HookEvent("player_death", BotDeath, EventHookMode_Post);
	HookEvent("player_hurt", BotHurt, EventHookMode_Post);
	HookEvent("player_spawn", BotSpawn, EventHookMode_Post);
	
	CreateConVar("sm_afk_bot_version", PLUGIN_VERSION, "AFK-BOT Plugin Version", FCVAR_NONE);
	AFKBOT_MaxIdleTime = CreateConVar("sm_afk_bot_max_idle_time", "60.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_FindLastDiedAreaChance = CreateConVar("sm_afk_bot_find_last_died_area_chance", "50.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_MinAimSpeed = CreateConVar("sm_afk_bot_min_aim_speed", "0.075", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_MaxAimSpeed = CreateConVar("sm_afk_bot_max_aim_speed", "0.125", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_LookAroundMaxDown = CreateConVar("sm_afk_bot_look_around_max_down", "50.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_LookAroundMaxUp = CreateConVar("sm_afk_bot_look_around_max_up", "75.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_MinAimSpeedWhenZoomed = CreateConVar("sm_afk_bot_min_aim_speed_when_zoomed", "0.175", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_MaxAimSpeedWhenZoomed = CreateConVar("sm_afk_bot_max_aim_speed_when_zoomed", "0.225", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_PathTimer = CreateConVar("sm_afk_bot_path_timer", "1.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_AimTimer = CreateConVar("sm_afk_bot_aim_timer", "0.014", "", FCVAR_NONE, true, 0.0, false, _);
}

public OnMapStart()
{
	CreateTimer(5.0, TellYourInAFKMODE,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(900.0, InfoTimer,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if(StrContains(currentMap, "ctf_" , false) != -1)
	{
		int tmflag;
		while((tmflag = FindEntityByClassname(tmflag, "item_teamflag")) != INVALID_ENT_REFERENCE)
		{
			int iTeamNumObj = GetEntProp(tmflag, Prop_Send, "m_iTeamNum");
			if(IsValidEntity(tmflag))
			{
				if(iTeamNumObj == 2)
				{
					GetEntPropVector(tmflag, Prop_Send, "m_vecOrigin", g_flRedFlagCapPoint);
				}
				if(iTeamNumObj == 3)
				{
					GetEntPropVector(tmflag, Prop_Send, "m_vecOrigin", g_flBluFlagCapPoint);
				}
			}
		}
	}
	
	ServerCommand("sm_cvar sm plugins reload afk_bot");
}

public Action:InfoTimer(Handle timer)
{
	PrintToChatAll("[AFK BOT] This server is using AFK BOT plugin type to chat !afk");
}

public OnClientPutInServer(client)
{
	g_bAfkbot[client] = false;
	g_flAutoLookTimer[client] = GetGameTime() + 1.0;
}

public Action:Command_Afk(client, args)
{
	if(args != 0 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_afk <target> [0/1]");
		return Plugin_Handled;
	}

	if(args == 0)
	{
		if(!g_bAfkbot[client])
		{
			PrintToChat(client, "[SM] AfkBot enabled.");
			if(IsValidClient(client))
			{
				TF2_RespawnPlayer(client);
			}
			g_bAfkbot[client] = true;
			g_bIsSlowThink[client] = true;
		}
		else
		{
			PrintToChat(client, "[SM] AfkBot disabled.");
			PrintCenterText(client, "Your AfkBot is now Disabled");
			g_bAfkbot[client] = false;
		}
		return Plugin_Handled;
	}

	else if(args == 2)
	{
		char arg1[PLATFORM_MAX_PATH];
		GetCmdArg(1, arg1, sizeof(arg1));
		char arg2[8];
		GetCmdArg(2, arg2, sizeof(arg2));

		int value = StringToInt(arg2);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_afk <target> [0/1]");
			return Plugin_Handled;
		}

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS];
		int target_count;
		bool tn_is_ml;
		if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for(int i=0; i<target_count; i++) if(IsValidClient(target_list[i]))
		{
			if(value == 0)
			{
				if(CheckCommandAccess(client, "sm_afk_access", ADMFLAG_ROOT))
				{
					PrintToChat(target_list[i], "[SM] AfkBot disabled.");
					PrintCenterText(target_list[i], "Your AfkBot is now Disabled");
					g_bAfkbot[target_list[i]] = false;
				}
			}
			else
			{
				if(CheckCommandAccess(client, "sm_afk_access", ADMFLAG_ROOT))
				{
					PrintToChat(target_list[i], "[SM] AfkBot enabled.");
					if(IsValidClient(client))
					{
						TF2_RespawnPlayer(target_list[i]);
					}
					g_bAfkbot[target_list[i]] = true;
				}
			}
		}
	}

	return Plugin_Handled;
}

public Action:AutoAddBot(client, args)
{ 
	if(IsValidClient(client))
	{
		int bot = CreateFakeClient("Bot");
		DispatchKeyValue(bot, "classname", "player");
		DispatchSpawn(bot);
		
		if(bot != -1)
		{
			char currentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(currentMap, sizeof(currentMap));
			
			if(StrContains(currentMap, "mvm_" , false) != -1)
			{
				ChangeClientTeam(bot, 2);
			}
			else
			{
				if(GetTeamsCount(2) > GetTeamsCount(3))
				{
					ChangeClientTeam(bot, 3);
				}
				else
				{
					ChangeClientTeam(bot, 2);
				}
			}
		
			if(!IsPlayerAlive(bot))
			{
				TF2_RespawnPlayer(bot);
			}
		}
	}
}  

public Action:Command_AfkOff(client, const char[] command, argc)
{
	char args[5];
	GetCmdArgString(args, sizeof(args));
	if (!StrEqual(args, "0 0"))
	{
		return Plugin_Continue;
	}
	if(IsValidClient(client))
	{
		if(!g_bAfkbot[client])
			return Plugin_Continue;
		{
			if(IsPlayerAlive(client))
			{
				PrintToChat(client, "[SM] AfkBot disabled.");
				PrintCenterText(client, "Your AfkBot is now Disabled");
				g_bAfkbot[client] = false;
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	if(IsValidClient(client))
	{
		char playerName[64];
		GetClientName(client, playerName, 64);
		if(!IsFakeClient(client) && !g_bAfkbot[client])
		{
			if(IsPlayerAlive(client))
			{
				float buffer[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
				float bufferlength = GetVectorLength(buffer);
				
				if(bufferlength < 50.0)
				{
					if(g_flIdlingTime[client] < GetGameTime())
					{
						g_bAfkbot[client] = true;
					}
				}
				else
				{
					g_flIdlingTime[client] = GetGameTime() + GetConVarFloat(AFKBOT_MaxIdleTime);
				}
			}
			else
			{
				g_flIdlingTime[client] = GetGameTime() + GetConVarFloat(AFKBOT_MaxIdleTime);
			}
		}
		if(g_bAfkbot[client] || (StrContains(playerName, "Aimbot", false) == -1 && StrContains(playerName, "Bot", false) != -1 && IsFakeClient(client)))
		{
			if(IsPlayerAlive(client))
			{
				float RandomizeAim = GetRandomFloat(GetConVarFloat(AFKBOT_MinAimSpeed), GetConVarFloat(AFKBOT_MaxAimSpeed));
				float RandomizeAimWhenZoomed = GetRandomFloat(GetConVarFloat(AFKBOT_MinAimSpeedWhenZoomed), GetConVarFloat(AFKBOT_MaxAimSpeedWhenZoomed));
				new TFClassType:class = TF2_GetPlayerClass(client);
				char currentMap[PLATFORM_MAX_PATH];
				GetCurrentMap(currentMap, sizeof(currentMap));
				float clientEyes[3];
				GetClientEyePosition(client, clientEyes);
				GetClientEyePosition(client, g_flClientEyePos[client]);
				GetClientAbsOrigin(client, g_flClientPos[client]);
				int Ent = Client_GetClosest(clientEyes, client);
				int PrimID;
				int SecondID;
				if(IsValidEntity(GetPlayerWeaponSlot(client, 0)))
				{
					PrimID = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iItemDefinitionIndex");
				}
				if(IsValidEntity(GetPlayerWeaponSlot(client, 1)))
				{
					SecondID = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex");
				}
				int CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
				int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				
				int sentry = TF2_GetObject(client, TFObject_Sentry, TFObjectMode_None);
				int dispenser = TF2_GetObject(client, TFObject_Dispenser, TFObjectMode_None);
				int teleporterenter = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Entrance);
				int teleporterexit = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Exit);
				
				if(class == TFClass_Spy)
				{
					if(IsWeaponSlotActive(client, 2) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab"))
					{
						buttons |= IN_ATTACK;
					}
				}
				
				if(class != TFClass_Engineer)
				{
					g_bMoveSentry[client] = false;
				}
				
				if(class != TFClass_DemoMan)
				{
					g_bMakeStickyTrap[client] = false;
				}
				
				int teammateteleporterenter = GetNearestEntity(client, "obj_teleporter");
				
				if(teammateteleporterenter != -1)
				{
					if(TF2_GetObjectMode(teammateteleporterenter) == TFObjectMode_Entrance)
					{
						int TeleState = GetEntProp(teammateteleporterenter, Prop_Send, "m_iState");
						int TeleIsSapped = GetEntProp(teammateteleporterenter, Prop_Send, "m_bHasSapper");
						if(TeleState != 1 && TeleState != 0 && TeleIsSapped == 0)
						{
							float teammateteleorigin[3];
							GetEntPropVector(teammateteleporterenter, Prop_Send, "m_vecOrigin", teammateteleorigin);
							teammateteleorigin[2] += 15.0;
							if(IsPointVisibleTank(clientEyes, teammateteleorigin) && IsPointVisibleTank2(clientEyes, teammateteleorigin))
							{
								g_bUseTeleporter[client] = true;
							}
							else
							{
								g_bUseTeleporter[client] = false;
							}
						}
						
						if(g_bUseTeleporter[client] && !g_bHealthIsLow[client] && !TF2_HasTheFlag(client))
						{
							if(teammateteleporterenter != -1 && IsValidEntity(teammateteleporterenter) && TF2_GetObjectMode(teammateteleporterenter) == TFObjectMode_Entrance)
							{
								float clientOrigin[3];
								float teammateteleorigin[3];
								GetClientAbsOrigin(client, clientOrigin);
								GetEntPropVector(teammateteleporterenter, Prop_Send, "m_vecOrigin", teammateteleorigin);
						
								if(GetVectorDistance(clientOrigin, teammateteleorigin) > 25.0)
								{
									if (!(PF_Exists(client))) 
									{
										PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
									}
							
									PF_SetGoalVector(client, teammateteleorigin);
							
									PF_StartPathing(client);
						
									PF_EnableCallback(client, PFCB_Approach, Approach);
							
									if(!IsPlayerAlive(client) || !PF_Exists(client))
										return Plugin_Continue;
							
									TF2_MoveTo(client, g_flGoal[client], vel, angles);
								}
							}
						}
					}
					else
					{
						g_bUseTeleporter[client] = false;
					}
				}
				
				if(!g_bSentryBuilded[client] && g_bCanBuildSentryGun[client])
				{
					g_bBuildSentry[client] = true;
				}
				else
				{
					g_bBuildSentry[client] = false;
				}
				
				if(g_bSentryBuilded[client] && g_bSentryIsMaxLevel[client] && g_bSentryHealthIsFull[client] && !g_bDispenserBuilded[client] && g_bCanBuildDispenser[client])
				{
					g_bBuildDispenser[client] = true;
				}
				else
				{
					g_bBuildDispenser[client] = false;
				}
				
				if(g_bSentryBuilded[client] && (!g_bSentryHealthIsFull[client] || !g_bSentryIsMaxLevel[client]))
				{
					g_bRepairSentry[client] = true;
				}
				else
				{
					g_bRepairSentry[client] = false;
				}
				
				if(g_bDispenserBuilded[client] && (!g_bDispenserHealthIsFull[client] || !g_bDispenserIsMaxLevel[client]))
				{
					g_bRepairDispenser[client] = true;
				}
				else
				{
					g_bRepairDispenser[client] = false;
				}
				
				if(g_bSentryBuilded[client] && g_bSentryHealthIsFull[client] && g_bSentryIsMaxLevel[client] && g_bDispenserBuilded[client] && g_bDispenserHealthIsFull[client] && g_bDispenserIsMaxLevel[client])
				{
					g_bIdleTime[client] = true;
				}
				else
				{
					g_bIdleTime[client] = false;
				}
				
				if(class != TFClass_Sniper)
				{
					g_bCamping[client] = false;
				}
				
				if(StrContains(currentMap, "ctf_2fort" , false) == -1 && StrContains(currentMap, "ctf_turbine" , false) == -1)
				{
					int tmflag;
					while((tmflag = FindEntityByClassname(tmflag, "item_teamflag")) != INVALID_ENT_REFERENCE)
					{
						int iTeamNumObj = GetEntProp(tmflag, Prop_Send, "m_iTeamNum");
						if(IsValidEntity(tmflag) && GetClientTeam(client) == iTeamNumObj)
						{
							GetEntPropVector(tmflag, Prop_Send, "m_vecOrigin", g_bSentryBuildPos[client]);
							
							g_bSentryBuildPos[client][0] += GetRandomFloat(-1500.0, 1500.0);
							g_bSentryBuildPos[client][1] += GetRandomFloat(-1500.0, 1500.0);
						}
					}
				}
				
				if(RepeartAttackTimer == INVALID_HANDLE)
				{
					RepeartAttackTimer = CreateTimer(0.3, ResetRepeartAttackTimer);
				}
				
				if(SnipeTimer == INVALID_HANDLE)
				{
					SnipeTimer = CreateTimer(5.0, ResetSnipeTimer);
				}
				
				if(GetEntProp(client, Prop_Send, "m_bJumping"))
				{
					buttons |= IN_DUCK;
				}
				
				if(g_bSpyAlert[client])
				{
					if(class == TFClass_Spy)
					{
						if(TF2_IsPlayerInCondition(client, TFCond_Cloaked) && TF2_IsPlayerInCondition(client, TFCond_Disguising))
						{
							g_bSpyAlert[client] = false;
						}
					}
					else
					{
						g_bSpyAlert[client] = false;
					}
				}
				
				if(Ent == -1)
				{
					if(!g_bCamping[client])
					{
						TF2_LookAround(client);
					}
				}
				
				float buffer[3];
				GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
				float bufferlength = GetVectorLength(buffer);
				
				if(bufferlength < 100.0 && !TF2_IsPlayerInCondition(client, TFCond_Zoomed) && !TF2_IsPlayerInCondition(client, TFCond_Taunting) && !g_bUseTeleporter[client] && !g_bHealthIsLow[client] && g_bPathFinding[client])
				{
					if(g_flJumpTimer[client] < GetGameTime() && g_flWaitJumpTimer[client] < GetGameTime())
					{
						buttons |= IN_JUMP;
						
						g_flJumpTimer[client] = GetGameTime() + 1.5;
					}
				}
				else
				{
					g_flJumpTimer[client] = GetGameTime() + 2.0;
				}
				
				if(class != TFClass_DemoMan)
				{
					g_bMakeStickyTrap[client] = false;
				}
				
				if(class == TFClass_Spy)
				{
					if(TF2_IsPlayerInCondition(client, TFCond_Cloaked) && Ent == -1 && !IsPointVisible(clientEyes, g_flLookAtLastKnownEnemyPos[client]) && !IsPointVisible2(clientEyes, g_flLookAtLastKnownEnemyPos[client]))
					{
						buttons |= IN_ATTACK2;
					}
				}
				
				if(GetAmmo(client) != -1)
				{
					if(class == TFClass_Spy)
					{
						int CloakID;
						if(IsValidEntity(GetPlayerWeaponSlot(client, 4)))
						{
							CloakID = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iItemDefinitionIndex");

							if(TF2_GetCloakMeter(client) < 50.0 && CloakID != 59 && CloakID != 60)
							{
								g_bAmmoIsLow[client] = true;
							}
							else
							{
								g_bAmmoIsLow[client] = false;
							}
						}
					}
					else if(class == TFClass_Sniper || class == TFClass_Heavy)
					{
						if(IsWeaponSlotActive(client, 1))
						{
							g_bAmmoIsLow[client] = true;
						}
						else
						{
							g_bAmmoIsLow[client] = false;
						}
					}
					else
					{
						g_bAmmoIsLow[client] = false;
					}
				}
				else
				{
					g_bAmmoIsLow[client] = false;
				}
				
				if(class == TFClass_Engineer)
				{
					if(g_bIdleTime[client])
					{
						if(GetMetal(client) < 200)
						{
							g_bAmmoIsLow[client] = true;
						}
						else
						{
							g_bAmmoIsLow[client] = false;
						}
					}
					else if(sentry != INVALID_ENT_REFERENCE)
					{
						int iSentryLevel = GetEntProp(sentry, Prop_Send, "m_iUpgradeLevel");
					
						if(iSentryLevel == 3)
						{
							if(GetMetal(client) < 100)
							{
								g_bAmmoIsLow[client] = true;
							}
							else
							{
								g_bAmmoIsLow[client] = false;
							}
						}
						else
						{
							if(GetMetal(client) == 0)
							{
								g_bAmmoIsLow[client] = true;
							}
							else
							{
								g_bAmmoIsLow[client] = false;
							}
						}
					}
					else
					{
						if(GetMetal(client) < 130)
						{
							g_bAmmoIsLow[client] = true;
						}
						else
						{
							g_bAmmoIsLow[client] = false;
						}
					}
				}
				
				if(Ent == -1)
				{
					if(class != TFClass_Engineer && class != TFClass_Heavy)
					{
						PrepareForBattle(client);
					}
				}
				
				if(GetAmmo(client) != -1)
				{
					if(class == TFClass_Spy)
					{
						int CloakID;
						if(IsValidEntity(GetPlayerWeaponSlot(client, 4)))
						{
							CloakID = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iItemDefinitionIndex");

							if(TF2_GetCloakMeter(client) < 50.0 && CloakID != 59 && CloakID != 60)
							{
								g_bAmmoIsLow[client] = true;
							}
							else
							{
								g_bAmmoIsLow[client] = false;
							}
						}
					}
					else
					{
						g_bAmmoIsLow[client] = false;
					}
				}
				
				if((CurrentHealth < (MaxHealth / 1.5) || TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Bleeding)))
				{
					g_bHealthIsLow[client] = true;
				}
				else
				{
					g_bHealthIsLow[client] = false;
				}
				
				if(class != TFClass_Spy)
				{
					g_bSapBuildings[client] = false;
					g_bSpyHaveAnyTask[client] = false;
					g_bBackStabVictim[client] = false;
				}
				
				if(class == TFClass_Spy && !TF2_HasTheFlag(client) && !g_bAmmoIsLow[client] && !g_bHealthIsLow[client])
				{
					int EnemyBuilding = GetNearestEntity(client, "obj_*");
					if(EnemyBuilding != -1)
					{
						if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) != GetTeamNumber(EnemyBuilding))
						{
							float clientOrigin[3];
							float enemysentryOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
							
							clientOrigin[2] += 50.0;
							
							if(IsPointVisibleTank(clientOrigin, enemysentryOrigin))
							{
								g_bSapBuildings[client] = true;
								g_bBackStabVictim[client] = false;
							}
							
							if(!IsPointVisibleTank(clientOrigin, enemysentryOrigin))
							{
								g_bSapBuildings[client] = false;
								g_bBackStabVictim[client] = true;
							}
						}
						if(g_bSapBuildings[client])
						{
							if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) != GetTeamNumber(EnemyBuilding))
							{
								float clientOrigin[3];
								float enemysentryOrigin[3];
								GetClientAbsOrigin(client, clientOrigin);
								GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
							
								clientOrigin[2] += 50.0;
							
								float camangle[3];
								float fEntityLocation[3];
								float vec[3];
								float angle[3];
								GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", fEntityLocation);
								GetEntPropVector(EnemyBuilding, Prop_Data, "m_angRotation", angle);
								fEntityLocation[2] += 35.0;
								MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
								GetVectorAngles(vec, camangle);
								camangle[0] *= -1.0;
								camangle[1] += 180.0;
								ClampAngle(camangle);
								
								int iBuildingIsSapped = GetEntProp(EnemyBuilding, Prop_Send, "m_bHasSapper");
								
								if(iBuildingIsSapped != 0)
								{
									g_bSapBuildings[client] = false;
									g_bBackStabVictim[client] = true;
								}
								
								if(GetVectorDistance(clientOrigin, enemysentryOrigin) > 50.0 && iBuildingIsSapped == 0)
								{
									TF2_FindPath(client, enemysentryOrigin);
									
									if(PF_Exists(client) && IsPlayerAlive(client))
									{
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
								}
							
								if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 400.0 && IsWeaponSlotActive(client, 1) && iBuildingIsSapped == 0)
								{
									TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
									buttons |= IN_ATTACK;
								}
								else if(GetVectorDistance(clientOrigin, enemysentryOrigin) < 200.0 && iBuildingIsSapped == 0)
								{
									FakeClientCommandThrottled(client, "build 3 0");
								}
							}
						}
					}
					if(EnemyBuilding == -1)
					{
						g_bBackStabVictim[client] = true;
					}
					
					if(g_bBackStabVictim[client])
					{
						if(!g_bSapBuildings[client] && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
						{
							for (int search = 1; search <= MaxClients; search++)
							{
								if (IsValidClient(search) && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
								{
									float searchOrigin[3];
									GetClientAbsOrigin(search, searchOrigin);
									
									searchOrigin[2] += 50.0;
									
									if(!g_bUseTeleporter[client])
									{
										if(!IsPointVisible(clientEyes, searchOrigin) && !IsPointVisible2(clientEyes, searchOrigin))
										{
											TF2_FindPath(client, searchOrigin);
											
											if(PF_Exists(client) && IsPlayerAlive(client))
											{
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
										}
										else
										{
											for (int search2 = 1; search2 <= MaxClients; search2++)
											{
												if (IsValidClient(search2) && IsClientInGame(search2) && IsPlayerAlive(search2) && search2 != client && TF2_GetPlayerClass(search2) == TFClass_Sniper && (GetClientTeam(client) != GetClientTeam(search2)))
												{
													float searchOrigin2[3];
													GetClientAbsOrigin(search2, searchOrigin2);
													
													searchOrigin2[2] += 50.0;
													
													if(IsPointVisible(clientEyes, searchOrigin2) && IsPointVisible2(clientEyes, searchOrigin2))
													{
														TF2_FindPath(client, searchOrigin2);
														
														if(PF_Exists(client) && IsPlayerAlive(client))
														{
															TF2_MoveTo(client, g_flGoal[client], vel, angles);
														}
														
														if(PF_Exists(client))
														{
															g_bSpyHaveAnyTask[client] = true;
														}
														else
														{
															g_bSpyHaveAnyTask[client] = false;
														}
													}
												}
												else if (IsValidClient(search2) && IsClientInGame(search2) && IsPlayerAlive(search2) && search2 != client && TF2_GetPlayerClass(search2) == TFClass_Engineer && (GetClientTeam(client) != GetClientTeam(search2)))
												{
													float searchOrigin2[3];
													GetClientAbsOrigin(search2, searchOrigin2);
													
													searchOrigin2[2] += 50.0;
													
													if(IsPointVisible(clientEyes, searchOrigin2) && IsPointVisible2(clientEyes, searchOrigin2))
													{
														TF2_FindPath(client, searchOrigin2);
														
														if(PF_Exists(client) && IsPlayerAlive(client))
														{
															TF2_MoveTo(client, g_flGoal[client], vel, angles);
														}
														
														if(PF_Exists(client))
														{
															g_bSpyHaveAnyTask[client] = true;
														}
														else
														{
															g_bSpyHaveAnyTask[client] = false;
														}
													}
												}
												else if (IsValidClient(search2) && IsClientInGame(search2) && IsPlayerAlive(search2) && search2 != client && TF2_GetPlayerClass(search2) == TFClass_Medic && (GetClientTeam(client) != GetClientTeam(search2)))
												{
													float searchOrigin2[3];
													GetClientAbsOrigin(search2, searchOrigin2);
									
													searchOrigin2[2] += 50.0;
												
													if(IsPointVisible(clientEyes, searchOrigin2) && IsPointVisible2(clientEyes, searchOrigin2))
													{
														TF2_FindPath(client, searchOrigin2);
														
														if(PF_Exists(client) && IsPlayerAlive(client))
														{
															TF2_MoveTo(client, g_flGoal[client], vel, angles);
														}
														
														if(PF_Exists(client))
														{
															g_bSpyHaveAnyTask[client] = true;
														}
														else
														{
															g_bSpyHaveAnyTask[client] = false;
														}
													}
												}
												else if (IsValidClient(search2) && IsClientInGame(search2) && IsPlayerAlive(search2) && search2 != client && (GetClientTeam(client) != GetClientTeam(search2)))
												{
													float searchOrigin2[3];
													GetClientAbsOrigin(search2, searchOrigin2);
													
													searchOrigin2[2] += 50.0;
													
													if(IsPointVisible(clientEyes, searchOrigin2) && IsPointVisible2(clientEyes, searchOrigin2))
													{
														TF2_FindPath(client, searchOrigin2);
														
														if(PF_Exists(client) && IsPlayerAlive(client))
														{
															TF2_MoveTo(client, g_flGoal[client], vel, angles);
														}
														
														if(PF_Exists(client))
														{
															g_bSpyHaveAnyTask[client] = true;
														}
														else
														{
															g_bSpyHaveAnyTask[client] = false;
														}
													}
												}
												else
												{
													g_bSpyHaveAnyTask[client] = false;
												}
											}
										}
									}
									else
									{
										g_bSpyHaveAnyTask[client] = false;
									}
								}
							}
						}
						else
						{
							g_bSpyHaveAnyTask[client] = false;
						}
					}
				}
				
				if(Ent == -1 && class != TFClass_Spy)
				{
					int EnemyBuilding = GetNearestEntity(client, "obj_*");
					if(EnemyBuilding != -1)
					{
						if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) != GetTeamNumber(EnemyBuilding))
						{
							float clientOrigin[3];
							float enemysentryOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
							
							clientOrigin[2] += 50.0;
							
							float camangle[3];
							float fEntityLocation[3];
							float vec[3];
							float angle[3];
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", fEntityLocation);
							GetEntPropVector(EnemyBuilding, Prop_Data, "m_angRotation", angle);
							fEntityLocation[2] += 35.0;
							MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
							GetVectorAngles(vec, camangle);
							camangle[0] *= -1.0;
							camangle[1] += 180.0;
							ClampAngle(camangle);
							
							if(IsPointVisibleTank(clientOrigin, enemysentryOrigin))
							{
								TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
								buttons |= IN_ATTACK;
							}
						}
					}
				}
				else if(Ent == -1 && !g_bSapBuildings[client])
				{
					int EnemyBuilding = GetNearestEntity(client, "obj_*");
					if(EnemyBuilding != -1)
					{
						if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) != GetTeamNumber(EnemyBuilding))
						{
							float clientOrigin[3];
							float enemysentryOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
							
							clientOrigin[2] += 50.0;
							
							float camangle[3];
							float fEntityLocation[3];
							float vec[3];
							float angle[3];
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", fEntityLocation);
							GetEntPropVector(EnemyBuilding, Prop_Data, "m_angRotation", angle);
							fEntityLocation[2] += 35.0;
							MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
							GetVectorAngles(vec, camangle);
							camangle[0] *= -1.0;
							camangle[1] += 180.0;
							ClampAngle(camangle);
							
							int iBuildingIsSapped = GetEntProp(EnemyBuilding, Prop_Send, "m_bHasSapper");
							
							if(IsPointVisibleTank(clientOrigin, enemysentryOrigin) && iBuildingIsSapped == 0)
							{
								FakeClientCommandThrottled(client, "build 3 0");
								TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
								TF2_MoveTo(client, enemysentryOrigin, vel, angles);
								buttons |= IN_ATTACK;
							}
						}
					}
				}
				
				if(Ent == -1)
				{
					for (int myfriendisattacking = 1; myfriendisattacking <= MaxClients; myfriendisattacking++)
					{
						if (IsValidClient(myfriendisattacking) && IsClientInGame(myfriendisattacking) && IsPlayerAlive(myfriendisattacking) && myfriendisattacking != client && (GetClientTeam(myfriendisattacking) == GetClientTeam(myfriendisattacking)))
						{
							float myfriendisattackingorigin[3];
							GetClientEyePosition(myfriendisattacking, myfriendisattackingorigin);
							
							if(IsPointVisible(clientEyes, myfriendisattackingorigin) && IsPointVisible2(clientEyes, myfriendisattackingorigin))
							{
								if(GetClientButtons(client) == IN_ATTACK)
								{
									GetAimOrigin(myfriendisattacking, g_flLookAtLastKnownEnemyPos[client]);
								}
							}
						}
					}
				}
				
				for (int idiotspy = 1; idiotspy <= MaxClients; idiotspy++)
				{
					if (IsValidClient(idiotspy) && IsClientInGame(idiotspy) && IsPlayerAlive(idiotspy) && idiotspy != client && (GetClientTeam(client) != GetClientTeam(idiotspy)))
					{
						float idiotspyorigin[3];
						GetClientEyePosition(idiotspy, idiotspyorigin);
						
						if(TF2_GetPlayerClass(idiotspy) == TFClass_Spy)
						{
							if(GetVectorDistance(clientEyes, idiotspyorigin) < 50.0)
							{
								g_bISeeSpy[client] = true;
								g_bSpyAlert[idiotspy] = true;
							}
						}
					}
				}
				
				if(!TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Disguising) && !TF2_HasTheFlag(client))
				{
					if(GetClientTeam(client) == 2)
					{
						int randomdisguise = GetRandomInt(1,9);
						switch(randomdisguise)
						{
							case 1:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_Scout);
							}
							case 2:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_Soldier);
							}
							case 3:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_Pyro);
							}
							case 4:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_Engineer);
							}
							case 5:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_Heavy);
							}
							case 6:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_DemoMan);
							}
							case 7:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_Medic);
							}
							case 8:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_Sniper);
							}
							case 9:
							{
								TF2_DisguisePlayer(client, TFTeam_Blue, TFClass_Spy);
							}
						}
					}
					else
					{
						int randomdisguise = GetRandomInt(1,9);
						switch(randomdisguise)
						{
							case 1:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_Scout);
							}
							case 2:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_Soldier);
							}
							case 3:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_Pyro);
							}
							case 4:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_Engineer);
							}
							case 5:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_Heavy);
							}
							case 6:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_DemoMan);
							}
							case 7:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_Medic);
							}
							case 8:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_Sniper);
							}
							case 9:
							{
								TF2_DisguisePlayer(client, TFTeam_Red, TFClass_Spy);
							}
						}
					}
				}
				
				if(GetMetal(client) >= 50.0)
				{
					g_bCanBuildTeleporter[client] = true;
				}
				else
				{
					g_bCanBuildTeleporter[client] = false;
				}
				
				if(GetMetal(client) >= 130.0)
				{
					g_bCanBuildSentryGun[client] = true;
				}
				else
				{
					g_bCanBuildSentryGun[client] = false;
				}
				
				if(GetMetal(client) >= 100.0)
				{
					g_bCanBuildDispenser[client] = true;
				}
				else
				{
					g_bCanBuildDispenser[client] = false;
				}
				
				if(sentry != INVALID_ENT_REFERENCE)
				{
					g_bSentryBuilded[client] = true;
					
					int iSentryLevel = GetEntProp(sentry, Prop_Send, "m_iUpgradeLevel");
					int iSentryHealth = GetEntProp(sentry, Prop_Send, "m_iHealth");
					int iSentryMaxHealth = GetEntProp(sentry, Prop_Send, "m_iMaxHealth");
					
					int MeleeID;
					if(IsValidEntity(GetPlayerWeaponSlot(client, 2)))
					{
						MeleeID = GetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iItemDefinitionIndex");
						if(MeleeID == 142)
						{
							g_bSentryIsMaxLevel[client] = true;
						}
						else
						{
							if(iSentryLevel < 3)
							{
								g_bSentryIsMaxLevel[client] = false;
							}
							else
							{
								g_bSentryIsMaxLevel[client] = true;
							}
						}
					}
					
					if(iSentryHealth < iSentryMaxHealth)
					{
						g_bSentryHealthIsFull[client] = false;
					}
					else
					{
						g_bSentryHealthIsFull[client] = true;
					}
				}
				else
				{
					g_bSentryBuilded[client] = false;
				}
				
				if(teleporterenter != INVALID_ENT_REFERENCE)
				{
					g_bTeleporterEnterBuilded[client] = true;
					
					int iTeleporterEnterLevel = GetEntProp(teleporterenter, Prop_Send, "m_iUpgradeLevel");
					int iTeleporterEnterHealth = GetEntProp(teleporterenter, Prop_Send, "m_iHealth");
					int iTeleporterEnterMaxHealth = GetEntProp(teleporterenter, Prop_Send, "m_iMaxHealth");
					
					if(iTeleporterEnterLevel < 3)
					{
						g_bTeleporterEnterIsMaxLevel[client] = false;
					}
					else
					{
						g_bTeleporterEnterIsMaxLevel[client] = true;
					}
					
					if(iTeleporterEnterHealth < iTeleporterEnterMaxHealth)
					{
						g_bTeleporterEnterHealthIsFull[client] = false;
					}
					else
					{
						g_bTeleporterEnterHealthIsFull[client] = true;
					}
				}
				else
				{
					g_bTeleporterEnterBuilded[client] = false;
				}
				
				if(teleporterexit != INVALID_ENT_REFERENCE)
				{
					g_bTeleporterExitBuilded[client] = true;
					
					int iTeleporterExitLevel = GetEntProp(teleporterexit, Prop_Send, "m_iUpgradeLevel");
					int iTeleporterExitHealth = GetEntProp(teleporterexit, Prop_Send, "m_iHealth");
					int iTeleporterExitMaxHealth = GetEntProp(teleporterexit, Prop_Send, "m_iMaxHealth");
					
					if(iTeleporterExitLevel < 3)
					{
						g_bTeleporterExitIsMaxLevel[client] = false;
					}
					else
					{
						g_bTeleporterExitIsMaxLevel[client] = true;
					}
					
					if(iTeleporterExitHealth < iTeleporterExitMaxHealth)
					{
						g_bTeleporterExitHealthIsFull[client] = false;
					}
					else
					{
						g_bTeleporterExitHealthIsFull[client] = true;
					}
				}
				else
				{
					g_bTeleporterExitBuilded[client] = false;
				}
				
				if(dispenser != INVALID_ENT_REFERENCE)
				{
					g_bDispenserBuilded[client] = true;
					
					int iDispenserLevel = GetEntProp(dispenser, Prop_Send, "m_iUpgradeLevel");
					int iDispenserHealth = GetEntProp(dispenser, Prop_Send, "m_iHealth");
					int iDispenserMaxHealth = GetEntProp(dispenser, Prop_Send, "m_iMaxHealth");
					
					if(iDispenserLevel < 3)
					{
						g_bDispenserIsMaxLevel[client] = false;
					}
					else
					{
						g_bDispenserIsMaxLevel[client] = true;
					}
					
					if(iDispenserHealth < iDispenserMaxHealth)
					{
						g_bDispenserHealthIsFull[client] = false;
					}
					else
					{
						g_bDispenserHealthIsFull[client] = true;
					}
				}
				else
				{
					g_bDispenserBuilded[client] = false;
				}
				
				if(TF2_HasTheFlag(client))
				{
					if(StrContains(currentMap, "ctf_" , false) != -1)
					{
						if(GetClientTeam(client) == 2)
						{
							TF2_FindPath(client, g_flRedFlagCapPoint);
							
							if(PF_Exists(client) && IsPlayerAlive(client))
							{
								TF2_MoveTo(client, g_flGoal[client], vel, angles);
							}
						}
						if(GetClientTeam(client) == 3)
						{
							TF2_FindPath(client, g_flBluFlagCapPoint);
							
							if(PF_Exists(client) && IsPlayerAlive(client))
							{
								TF2_MoveTo(client, g_flGoal[client], vel, angles);
							}
						}
					}
				}
				else
				{
					if(g_bAmmoIsLow[client] && !g_bHealthIsLow[client] && !TF2_HasTheFlag(client) && !g_bUseTeleporter[client])
					{
						if(!g_bPathFinding[client])
						{
							g_bPathFinding[client] = true;
						}
						
						TF2_FindPath(client, g_flNearestAmmoOrigin[client]);
						
						if(PF_Exists(client) && IsPlayerAlive(client) && GetVectorDistance(g_flClientPos[client], g_flNearestAmmoOrigin[client]) > 25.0)
						{
							TF2_MoveTo(client, g_flGoal[client], vel, angles);
						}
					}
					
					// Find Health
					
					if(g_bHealthIsLow[client] && !TF2_HasTheFlag(client))
					{
						if(!g_bPathFinding[client])
						{
							g_bPathFinding[client] = true;
						}
						
						TF2_FindPath(client, g_flNearestHealthOrigin[client]);
						
						if(PF_Exists(client) && IsPlayerAlive(client) && GetVectorDistance(g_flClientPos[client], g_flNearestHealthOrigin[client]) > 25.0)
						{
							TF2_MoveTo(client, g_flGoal[client], vel, angles);
						}
					}
				}
				
				if(g_flFindNearestHealthTimer[client] < GetGameTime())
				{
					int healthpack = FindNearestHealth(client);
					
					if (healthpack != -1)
					{
						GetEntPropVector(healthpack, Prop_Send, "m_vecOrigin", g_flNearestHealthOrigin[client]);
						
						g_flFindNearestHealthTimer[client] = GetGameTime() + 20.0;
					}
				}
				
				if(g_flFindNearestAmmoTimer[client] < GetGameTime())
				{
					int ammopack2 = FindNearestAmmo(client);
				
					if(ammopack2 != -1)
					{
						GetEntPropVector(ammopack2, Prop_Send, "m_vecOrigin", g_flNearestAmmoOrigin[client]);
						
						g_flFindNearestAmmoTimer[client] = GetGameTime() + 20.0;
					}
				}
				
				if(class == TFClass_DemoMan)
				{
					int iSticky;
					while((iSticky = FindEntityByClassname(iSticky, "tf_projectile_pipe_remote")) != INVALID_ENT_REFERENCE)
					{
						if (IsValidEntity(iSticky) && GetEntityOwner(iSticky) == client)
						{
							for (int search = 1; search <= MaxClients; search++)
							{
								if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
								{
									float stickyOrigin[3];
									float searchOrigin[3];
									GetClientAbsOrigin(search, searchOrigin);
									GetEntPropVector(iSticky, Prop_Send, "m_vecOrigin", stickyOrigin);
									
									searchOrigin[2] += 50.0;
							
									float enemyDistance;
									enemyDistance = GetVectorDistance(stickyOrigin, searchOrigin);
							
									if(enemyDistance < 200.0 && !TF2_IsPlayerInCondition(search, TFCond_Ubercharged) && IsPointVisible(clientEyes, searchOrigin))
									{
										buttons |= IN_ATTACK2;
									}
								}
							}
						}
					}
				}
				
				if(g_bMakeStickyTrap[client])
				{
					if(class != TFClass_DemoMan)
					{
						g_bMakeStickyTrap[client] = false;
					}
				}
				
				if(class == TFClass_Heavy)
				{
					if(Ent == -1) // No Enemy
					{
						if(SecondID == 42 || SecondID == 159 || SecondID == 311 || SecondID == 433 || SecondID == 1002 || SecondID == 1190) // Sandwich ID's
						{
							if(g_bHealthIsLow[client])
							{
								EquipWeaponSlot(client, 1); // If sandwich is not ready = bot can't change weapon to sandwich
								
								if(!TF2_IsPlayerInCondition(client, TFCond_Taunting) && IsWeaponSlotActive(client, 1))
								{
									buttons |= IN_ATTACK;
								}
							}
						}
					}
				}
				
				if(class == TFClass_DemoMan && Ent == -1)
				{
					if(g_bMakeStickyTrap[client] && !g_bAmmoIsLow[client] && !g_bHealthIsLow[client])
					{
						int flag;
						while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
						{
							int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
							if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
							{
								float demoOrigin[3];
								float flagpos[3];
								float spotpos[3];
								GetClientAbsOrigin(client, demoOrigin);
								GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
								GetEntPropVector(flag, Prop_Send, "m_vecOrigin", spotpos);
								
								spotpos[0] += GetRandomFloat(-1500.0, 1500.0);
								spotpos[1] += GetRandomFloat(-1500.0, 1500.0);
								spotpos[2] += GetRandomFloat(-150.0, 150.0);
								
								if(GetVectorDistance(demoOrigin, flagpos) > 1000.0 || !IsPointVisible(clientEyes, flagpos))
								{
									TF2_FindPath(client, flagpos);
									
									if(PF_Exists(client) && IsPlayerAlive(client))
									{
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
								}
								else if(IsPointVisible(clientEyes, flagpos) && IsPointVisible2(clientEyes, flagpos))
								{
									PF_StopPathing(client);
									
									if(!g_bMaxStickies[client])
									{
										if(IsWeaponSlotActive(client, 1))
										{
											TF2_LookAtPos(client, spotpos, RandomizeAim);
											if(g_flDemoAttackTimer[client] < GetGameTime())
											{
												buttons |= IN_ATTACK;
												g_flDemoAttackTimer[client] = GetGameTime() + 0.5;
											}
										}
										else
										{
											EquipWeaponSlot(client, 1);
										}
									}
								}
							}
						}
					}
				}
				
				if(g_bHealthIsLow[client] || TF2_HasTheFlag(client))
				{
					if(TF2_IsPlayerInCondition(client, TFCond_Zoomed) && Ent == -1)
					{
						buttons |= IN_ATTACK2;
					}
				}
				
				if(class == TFClass_DemoMan)
				{
					int pipecount = GetClientEntityCount(client, "tf_projectile_pipe_remote");
					
					if(SecondID == 130)
					{
						if(pipecount < 12)
						{
							g_bMaxStickies[client] = false;
						}
						else
						{
							g_bMaxStickies[client] = true;
						}
					}
					else
					{
						if(pipecount < 8)
						{
							g_bMaxStickies[client] = false;
						}
						else
						{
							g_bMaxStickies[client] = true;
						}
					}
				}
				
				if(g_bCamping[client] && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && !TF2_HasTheFlag(client))
				{
					if(class == TFClass_Sniper)
					{
						if(Ent == -1)
						{
							if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
							{
								if(StrContains(currentMap, "ctf_2fort" , false) != -1 || StrContains(currentMap, "ctf_turbine" , false) != -1)
								{
									if(IsPointVisible(clientEyes, g_flSniperCurrentAim[client]) && IsPointVisible2(clientEyes, g_flSniperCurrentAim[client]))
									{
										TF2_LookAtPos(client, g_flSniperCurrentAim[client], RandomizeAimWhenZoomed);
									}
								}
								else
								{
									TF2_LookAroundForSnipe(client);
								}
							}
							else if(GetVectorDistance(clientEyes, g_flSniperSpotPos[client]) > 125.0)
							{
								TF2_LookAround(client);
								
								if(TF2_IsPlayerInCondition(client, TFCond_Zoomed) && Ent == -1)
								{
									buttons |= IN_ATTACK2;
								}
							}
						}
						else
						{
							if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
							{
								float headpos[3];
								GetClientEyePosition(Ent, headpos);
								TF2_LookAtPos(client, headpos, RandomizeAimWhenZoomed);
							}
						}
						
						if(StrContains(currentMap, "ctf_2fort" , false) != -1 || StrContains(currentMap, "ctf_turbine" , false) != -1)
						{
							TF2_FindPath(client, g_flSniperSpotPos[client]);
						}
						
						if(StrContains(currentMap, "koth_" , false) != -1)
						{
							TF2_FindSniperSpot(client);
							
							TF2_FindPath(client, g_flSniperSpotPos[client]);
							
							if(PF_Exists(client) && g_bPathFinding[client])
							{
								TF2_MoveTo(client, g_flGoal[client], vel, angles);
							}
						}
						
						if(StrContains(currentMap, "ctf_2fort" , false) != -1 || StrContains(currentMap, "ctf_turbine" , false) != -1)
						{
							if(GetVectorDistance(clientEyes, g_flSniperSpotPos[client]) > g_flSniperRange[client])
							{
								TF2_MoveTo(client, g_flGoal[client], vel, angles);
							}
							else
							{
								if(TF2_IsPlayerInCondition(client, TFCond_Zoomed) && Ent == -1)
								{
									if(g_flSniperLookTimer[client] < GetGameTime())
									{
										int randomselectaimpoint = GetRandomInt(1,4);
										switch(randomselectaimpoint)
										{
											case 1:
											{
												g_flSniperCurrentAim[client][0] = g_flSniperAim1[client][0];
												g_flSniperCurrentAim[client][1] = g_flSniperAim1[client][1];
												g_flSniperCurrentAim[client][2] = g_flSniperAim1[client][2];
											}
											case 2:
											{
												g_flSniperCurrentAim[client][0] = g_flSniperAim2[client][0];
												g_flSniperCurrentAim[client][1] = g_flSniperAim2[client][1];
												g_flSniperCurrentAim[client][2] = g_flSniperAim2[client][2];
											}
											case 3:
											{
												g_flSniperCurrentAim[client][0] = g_flSniperAim3[client][0];
												g_flSniperCurrentAim[client][1] = g_flSniperAim3[client][1];
												g_flSniperCurrentAim[client][2] = g_flSniperAim3[client][2];
											}
											case 4:
											{
												g_flSniperCurrentAim[client][0] = g_flSniperAim4[client][0];
												g_flSniperCurrentAim[client][1] = g_flSniperAim4[client][1];
												g_flSniperCurrentAim[client][2] = g_flSniperAim4[client][2];
											}
										}
										g_flSniperLookTimer[client] = GetGameTime() + GetRandomFloat(1.5, 3.0);
									}
									
									if(g_flSniperChangeSpotTimer[client] < GetGameTime())
									{
										if(Ent == -1)
										{
											g_bPickRandomSniperSpot[client] = true;
										}
										g_flSniperChangeSpotTimer[client] = GetGameTime() + GetRandomFloat(10.0, 20.0);
									}
								}
								else
								{
									if(IsWeaponSlotActive(client, 0) && !TF2_IsPlayerInCondition(client, TFCond_Zoomed))
									{
										buttons |= IN_ATTACK2;
									}
									else if(Ent == -1)
									{
										EquipWeaponSlot(client, 0);
									}
								}
							}
						}
						else
						{
							if(GetVectorDistance(clientEyes, g_flSniperSpotPos[client]) < 125.0)
							{
								if(IsWeaponSlotActive(client, 0) && !TF2_IsPlayerInCondition(client, TFCond_Zoomed))
								{
									buttons |= IN_ATTACK2;
								}
								else if(Ent == -1)
								{
									EquipWeaponSlot(client, 0);
								}
							}
							else
							{
								if(TF2_IsPlayerInCondition(client, TFCond_Zoomed) && Ent == -1)
								{
									buttons |= IN_ATTACK2;
								}
							}
						}
					}
				}
				else if(g_bCamping[client] && (g_bHealthIsLow[client] || g_bAmmoIsLow[client]))
				{
					TF2_LookAround(client);
				}
				
				if(class == TFClass_Sniper && PrimID != 56 && PrimID != 1005 && PrimID != 1092)
				{
					g_bCamping[client] = true;
				}
				else
				{
					g_bCamping[client] = false;
					g_bPickRandomSniperSpot[client] = false;
				}
				
				if(g_bPickRandomSniperSpot[client] && class != TFClass_Sniper)
				{
					g_bPickRandomSniperSpot[client] = false;
				}
				
				if(g_bPickRandomSniperSpot[client])
				{
					if(GetClientTeam(client) == 2)
					{
						if(StrContains(currentMap, "ctf_2fort" , false) != -1)
						{
							int randomsniperspot = GetRandomInt(1, 3);
							switch(randomsniperspot)
							{
								case 1:
								{
									float SniperSpotPos[3] = {237.0, 1039.0, 330.0};
									float SniperSpotAim1[3] = {267.0, -1065.0, 140.0};
									float SniperSpotAim2[3] = {-254.0, -1027.0, 300.0};
									float SniperSpotAim3[3] = {-267.0, -1065.0, 140.0};
									float SniperSpotAim4[3] = {254.0, -1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 2:
								{
									float SniperSpotPos[3] = {-237.0, 1039.0, 330.0};
									float SniperSpotAim1[3] = {267.0, -1065.0, 140.0};
									float SniperSpotAim2[3] = {-254.0, -1027.0, 300.0};
									float SniperSpotAim3[3] = {-267.0, -1065.0, 140.0};
									float SniperSpotAim4[3] = {254.0, -1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 3:
								{
									float SniperSpotPos[3] = {-0.0, 963.0, 324.0};
									float SniperSpotAim1[3] = {267.0, -1065.0, 140.0};
									float SniperSpotAim2[3] = {-254.0, -1027.0, 300.0};
									float SniperSpotAim3[3] = {-267.0, -1065.0, 140.0};
									float SniperSpotAim4[3] = {254.0, -1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
							}
						}
						else if(StrContains(currentMap, "ctf_turbine" , false) != -1)
						{
							int randomsniperspot = GetRandomInt(1, 4);
							switch(randomsniperspot)
							{
								case 1:
								{
									float SniperSpotPos[3] = {679.0, 292.0, 123.0};
									float SniperSpotAim1[3] = {-989.0, -399.0, -180.0};
									float SniperSpotAim2[3] = {-688.0, 449.0, -180.0};
									float SniperSpotAim3[3] = {-675.0, -273.0, 123.0};
									float SniperSpotAim4[3] = {-684.0, 257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 2:
								{
									float SniperSpotPos[3] = {680.0, 520.0, 123.0};
									float SniperSpotAim1[3] = {-989.0, -399.0, -180.0};
									float SniperSpotAim2[3] = {-688.0, 449.0, -180.0};
									float SniperSpotAim3[3] = {-675.0, -273.0, 123.0};
									float SniperSpotAim4[3] = {-684.0, 257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 3:
								{
									float SniperSpotPos[3] = {683.0, -316.0, 123.0};
									float SniperSpotAim1[3] = {-989.0, -399.0, -180.0};
									float SniperSpotAim2[3] = {-688.0, 449.0, -180.0};
									float SniperSpotAim3[3] = {-675.0, -273.0, 123.0};
									float SniperSpotAim4[3] = {-684.0, 257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 4:
								{
									float SniperSpotPos[3] = {677.0, -677.0, 123.0};
									float SniperSpotAim1[3] = {-989.0, -399.0, -180.0};
									float SniperSpotAim2[3] = {-688.0, 449.0, -180.0};
									float SniperSpotAim3[3] = {-675.0, -273.0, 123.0};
									float SniperSpotAim4[3] = {-684.0, 257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
							}
						}
						else if(StrContains(currentMap, "koth_" , false) != -1)
						{
							int capturepoint;
							if((capturepoint = FindEntityByClassname(capturepoint, "team_control_point")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(capturepoint))
								{
									float cappointpos[3];
									float cappointpos2[3];
									GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos);
									GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos2);
									
									cappointpos[0] += GetRandomFloat(-150.0, 150.0);
									cappointpos[1] += GetRandomFloat(-150.0, 150.0);
									cappointpos[2] += 15.0;
									
									cappointpos2[0] += GetRandomFloat(-500.0, 500.0);
									cappointpos2[1] += GetRandomFloat(-500.0, 500.0);
									cappointpos2[2] += 50.0;
									
									g_flSniperSpotPos[client] = cappointpos;
									g_flSniperAim1[client] = cappointpos;
									g_flSniperAim2[client] = g_flLookAtLastKnownEnemyPos[client];
									g_flSniperAim3[client] = cappointpos2;
									g_flSniperAim4[client] = cappointpos2;
									
									g_bPickRandomSniperSpot[client] = false;
								}
							}	
						}
					}
					else
					{
						if(StrContains(currentMap, "ctf_2fort" , false) != -1)
						{
							int randomsniperspot = GetRandomInt(1, 3);
							switch(randomsniperspot)
							{
								case 1:
								{
									float SniperSpotPos[3] = {-237.0, -1039.0, 330.0};
									float SniperSpotAim1[3] = {-267.0, 1065.0, 140.0};
									float SniperSpotAim2[3] = {254.0, 1027.0, 300.0};
									float SniperSpotAim3[3] = {267.0, 1065.0, 140.0};
									float SniperSpotAim4[3] = {-254.0, 1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 2:
								{
									float SniperSpotPos[3] = {237.0, -1039.0, 330.0};
									float SniperSpotAim1[3] = {-267.0, 1065.0, 140.0};
									float SniperSpotAim2[3] = {254.0, 1027.0, 300.0};
									float SniperSpotAim3[3] = {267.0, 1065.0, 140.0};
									float SniperSpotAim4[3] = {-254.0, 1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 3:
								{
									float SniperSpotPos[3] = {0.0, -963.0, 324.0};
									float SniperSpotAim1[3] = {-267.0, 1065.0, 140.0};
									float SniperSpotAim2[3] = {254.0, 1027.0, 300.0};
									float SniperSpotAim3[3] = {267.0, 1065.0, 140.0};
									float SniperSpotAim4[3] = {-254.0, 1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
							}
						}
						else if(StrContains(currentMap, "ctf_turbine" , false) != -1)
						{
							int randomsniperspot = GetRandomInt(1, 4);
							switch(randomsniperspot)
							{
								case 1:
								{
									float SniperSpotPos[3] = {-679.0, -292.0, 123.0};
									float SniperSpotAim1[3] = {989.0, 399.0, -180.0};
									float SniperSpotAim2[3] = {688.0, -449.0, -180.0};
									float SniperSpotAim3[3] = {675.0, 273.0, 123.0};
									float SniperSpotAim4[3] = {684.0, -257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 2:
								{
									float SniperSpotPos[3] = {-680.0, -520.0, 123.0};
									float SniperSpotAim1[3] = {989.0, 399.0, -180.0};
									float SniperSpotAim2[3] = {688.0, -449.0, -180.0};
									float SniperSpotAim3[3] = {675.0, 273.0, 123.0};
									float SniperSpotAim4[3] = {684.0, -257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 3:
								{
									float SniperSpotPos[3] = {-683.0, 316.0, 123.0};
									float SniperSpotAim1[3] = {989.0, 399.0, -180.0};
									float SniperSpotAim2[3] = {688.0, -449.0, -180.0};
									float SniperSpotAim3[3] = {675.0, 273.0, 123.0};
									float SniperSpotAim4[3] = {684.0, -257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 4:
								{
									float SniperSpotPos[3] = {-677.0, 677.0, 123.0};
									float SniperSpotAim1[3] = {989.0, 399.0, -180.0};
									float SniperSpotAim2[3] = {688.0, -449.0, -180.0};
									float SniperSpotAim3[3] = {675.0, 273.0, 123.0};
									float SniperSpotAim4[3] = {684.0, -257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
							}
						}
						else if(StrContains(currentMap, "koth_" , false) != -1)
						{
							int capturepoint;
							if((capturepoint = FindEntityByClassname(capturepoint, "team_control_point")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(capturepoint))
								{
									float cappointpos[3];
									float cappointpos2[3];
									GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos);
									GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos2);
									
									cappointpos[0] += GetRandomFloat(-150.0, 150.0);
									cappointpos[1] += GetRandomFloat(-150.0, 150.0);
									cappointpos[2] += 15.0;
									
									cappointpos2[0] += GetRandomFloat(-500.0, 500.0);
									cappointpos2[1] += GetRandomFloat(-500.0, 500.0);
									cappointpos2[2] += 50.0;
									
									g_flSniperSpotPos[client] = cappointpos;
									g_flSniperAim1[client] = cappointpos;
									g_flSniperAim2[client] = g_flLookAtLastKnownEnemyPos[client];
									g_flSniperAim3[client] = cappointpos2;
									g_flSniperAim4[client] = cappointpos2;
									
									g_bPickRandomSniperSpot[client] = false;
								}
							}
						}
					}
				}
				
				if(g_bPickUnUsedSentrySpot[client] && class != TFClass_Engineer)
				{
					g_bPickUnUsedSentrySpot[client] = false;
				}
				
				if(g_flEngineerPickNewSpotTimer[client] < GetGameTime())
				{
					if(class == TFClass_Engineer)
					{
						g_bPickUnUsedSentrySpot[client] = true;
						
						g_flEngineerPickNewSpotTimer[client] = GetGameTime() + 15.0;
					}
				}
				
				if(g_bPickUnUsedSentrySpot[client])
				{
					int BuildedSentryGun;
					if(GetClientTeam(client) == 2 && (BuildedSentryGun = FindEntityByClassname(BuildedSentryGun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
					{
						if(StrContains(currentMap, "pl_" , false) != -1)
						{
							int cart;
							while((cart = FindEntityByClassname(cart, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(cart))
								{
									float cartpos[3];
									float cartposaim[3];
									GetEntPropVector(cart, Prop_Send, "m_vecOrigin", cartpos);
									GetEntPropVector(cart, Prop_Send, "m_vecOrigin", cartposaim);
									
									cartpos[0] += GetRandomFloat(-1000.0, 1000.0);
									cartpos[1] += GetRandomFloat(-1000.0, 1000.0);
									
									g_bSentryBuildPos[client] = cartpos;
									g_bSentryBuildAngle[client] = cartposaim;
									g_bPickUnUsedSentrySpot[client] = false;
								}
							}
						}
						else if(StrContains(currentMap, "ctf_turbine" , false) != -1)
						{
							int randomsentryspot = GetRandomInt(1, 5);
							switch(randomsentryspot)
							{
								case 1:
								{
									float SentryPos[3] = {2013.0, 1543.0, -190.0};
									float SentryAngle[3] = {2231.0, 1312.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 2:
								{
									float SentryPos[3] = {2828.0, 1161.0, -222.0};
									float SentryAngle[3] = {2540.0, 1163.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 3:
								{
									float SentryPos[3] = {1274.0, 1454.0, -94.0};
									float SentryAngle[3] = {1273.0, 335.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 4:
								{
									float SentryPos[3] = {2905.0, 501.0, -190.0};
									float SentryAngle[3] = {2895.0, 863.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 5:
								{
									float SentryPos[3] = {1698.0, -439.0, 89.0};
									float SentryAngle[3] = {832.0, -447.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
							}
						}
						else if(StrContains(currentMap, "ctf_2fort" , false) != -1)
						{
							int randomsentryspot = GetRandomInt(1, 12);
							switch(randomsentryspot)
							{
							case 1:
								{
									float SentryPos[3] = {580.0, 1448.0, 321.0};
									float SentryAngle[3] = {673.0, 1606.0, 321.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 2:
								{
									float SentryPos[3] = {616.0, 2622.0, -126.0};
									float SentryAngle[3] = {417.0, 3126.0, -126.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 3:
								{
									float SentryPos[3] = {3.0, 1553.0, 126.0};
									float SentryAngle[3] = {-7.0, 1026.0, 129.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 4:
								{
									float SentryPos[3] = {765.0, 1765.0, -102.0};
									float SentryAngle[3] = {498.0, 1494.0, -132.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 5:
								{
									float SentryPos[3] = {-415.0, 3296.0, -110.0};
									float SentryAngle[3] = {39.0, 2968.0, -126.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 6:
								{
									float SentryPos[3] = {-1.0, 1457.0, 331.0};
									float SentryAngle[3] = {-5.0, 1192.0, 331.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 7:
								{
									float SentryPos[3] = {15.0, 2993.0, -116.0};
									float SentryAngle[3] = {-362.0, 3368.0, -100.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 8:
								{
									float SentryPos[3] = {-601.0, 2982.0, -100.0};
									float SentryAngle[3] = {24.0, 3432.0, -116.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 9:
								{
									float SentryPos[3] = {24.0, 3432.0, -116.0};
									float SentryAngle[3] = {-601.0, 2982.0, -100.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 10:
								{
									float SentryPos[3] = {213.0, 1334.0, 331.0};
									float SentryAngle[3] = {661.0, 1598.0, 331.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 11:
								{
									float SentryPos[3] = {655.0, 1417.0, 140.0};
									float SentryAngle[3] = {131.0, 1582.0, 137.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 12:
								{
									float SentryPos[3] = {-497.0, -1871.0, -92.0};
									float SentryAngle[3] = {-489.0, -1501.0, -127.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
							}
						}
					}
					else if((BuildedSentryGun = FindEntityByClassname(BuildedSentryGun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
					{
						if(StrContains(currentMap, "pl_" , false) != -1)
						{
							int cart;
							if((cart = FindEntityByClassname(cart, "mapobj_cart_dispenser")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(cart))
								{
									float cartpos[3];
									float cartposaim[3];
									GetEntPropVector(cart, Prop_Send, "m_vecOrigin", cartpos);
									GetEntPropVector(cart, Prop_Send, "m_vecOrigin", cartposaim);
									
									cartpos[0] += GetRandomFloat(-1000.0, 1000.0);
									cartpos[1] += GetRandomFloat(-1000.0, 1000.0);
									
									g_bSentryBuildPos[client] = cartpos;
									g_bSentryBuildAngle[client] = cartposaim;
									g_bPickUnUsedSentrySpot[client] = false;
								}
							}
						}
						else if(StrContains(currentMap, "ctf_turbine" , false) != -1)
						{
							int randomsentryspot = GetRandomInt(1, 5);
							switch(randomsentryspot)
							{
								case 1:
								{
									float SentryPos[3] = {-2013.0, -1543.0, -190.0};
									float SentryAngle[3] = {-2231.0, -1312.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 2:
								{
									float SentryPos[3] = {-2828.0, -1161.0, -222.0};
									float SentryAngle[3] = {-2540.0, -1163.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 3:
								{
									float SentryPos[3] = {-1274.0, -1454.0, -94.0};
									float SentryAngle[3] = {-1273.0, -335.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 4:
								{
									float SentryPos[3] = {-2905.0, -501.0, -190.0};
									float SentryAngle[3] = {-2895.0, -863.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 5:
								{
									float SentryPos[3] = {-1698.0, 439.0, 89.0};
									float SentryAngle[3] = {-832.0, 447.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
							}
						}
						else if(StrContains(currentMap, "ctf_2fort" , false) != -1)
						{
							int randomsentryspot = GetRandomInt(1, 12);
							switch(randomsentryspot)
							{
							case 1:
								{
									float SentryPos[3] = {-580.0, -1448.0, 321.0};
									float SentryAngle[3] = {-673.0, -1606.0, 321.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 2:
								{
									float SentryPos[3] = {-616.0, -2622.0, -126.0};
									float SentryAngle[3] = {-417.0, -3126.0, -126.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 3:
								{
									float SentryPos[3] = {-3.0, -1553.0, 126.0};
									float SentryAngle[3] = {7.0, -1026.0, 129.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 4:
								{
									float SentryPos[3] = {-765.0, -1765.0, -102.0};
									float SentryAngle[3] = {-498.0, -1494.0, -132.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 5:
								{
									float SentryPos[3] = {415.0, -3296.0, -110.0};
									float SentryAngle[3] = {-39.0, -2968.0, -126.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 6:
								{
									float SentryPos[3] = {1.0, -1457.0, 331.0};
									float SentryAngle[3] = {5.0, -1192.0, 331.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 7:
								{
									float SentryPos[3] = {-15.0, -2993.0, -116.0};
									float SentryAngle[3] = {362.0, -3368.0, -100.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 8:
								{
									float SentryPos[3] = {601.0, -2982.0, -100.0};
									float SentryAngle[3] = {-24.0, -3432.0, -116.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 9:
								{
									float SentryPos[3] = {-24.0, -3432.0, -116.0};
									float SentryAngle[3] = {601.0, -2982.0, -100.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 10:
								{
									float SentryPos[3] = {-213.0, -1334.0, 331.0};
									float SentryAngle[3] = {-661.0, -1598.0, 331.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 11:
								{
									float SentryPos[3] = {-655.0, -1417.0, 140.0};
									float SentryAngle[3] = {-131.0, -1582.0, 137.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
								case 12:
								{
									float SentryPos[3] = {497.0, -871.0, -92.0};
									float SentryAngle[3] = {489.0, 1501.0, -127.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										float BuildedSentryOrigin[3];
										GetEntPropVector(BuildedSentryGun, Prop_Send, "m_vecOrigin", BuildedSentryOrigin);
										if(GetVectorDistance(SentryPos, BuildedSentryOrigin) < 200.0)
										{
											g_bPickUnUsedSentrySpot[client] = true;
										}
										else
										{
											g_bSentryBuildPos[client] = SentryPos;
											g_bSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
							}
						}
					}
				}
				
				if(!g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && !TF2_HasTheFlag(client) && !g_bUseTeleporter[client])
				{
					if(class == TFClass_Engineer)
					{
						if(StrContains(currentMap, "ctf_" , false) != -1)
						{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									GetClientAbsOrigin(client, engiOrigin);
									
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
									
									//PrintToServer("FlagStatus %i", FlagStatus);
									
									if(g_bBuildSentry[client])
									{
										if(FlagStatus == 0 || FlagStatus == 1 || FlagStatus == 2)
										{
											if(GetVectorDistance(engiOrigin, g_bSentryBuildPos[client]) < 80.0)
											{
												if(IsWeaponSlotActive(client, 5))
												{
													buttons |= IN_ATTACK;
												}
												else
												{
													FakeClientCommandThrottled(client, "build 2");
												}
											}
											
											TF2_FindPath(client, g_bSentryBuildPos[client]);
											
											if(PF_Exists(client) && IsPlayerAlive(client))
											{
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
										}
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											EquipWeaponSlot(client, 2);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										TF2_FindPath(client, fEntityLocation);
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										TF2_FindPath(client, putdispenserpos);
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											EquipWeaponSlot(client, 2);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										TF2_FindPath(client, dispenserpos);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
								}
							}
						}
						if(StrContains(currentMap, "pl_" , false) != -1)
						{
							int flag;
							if((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(flag))
								{
									float engiOrigin[3];
									GetClientAbsOrigin(client, engiOrigin);
									float flagpos[3];
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
									
									if(g_flPayloadDefendPosChangeTimer[client] < GetGameTime())
									{
										g_bFindNewDefendPayloadSpot[client] = true;
										
										g_flPayloadDefendPosChangeTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
									}
									
									if((GetVectorDistance(clientEyes, g_flSelectedPayloadDefendArea[client]) > 100.0))
									{
										g_bPathFinding[client] = true;
									}
									else
									{
										g_bPathFinding[client] = false;
									}
									
									if(g_bFindNewDefendPayloadSpot[client])
									{
										g_flRandomPayloadDefendArea[client][0] = flagpos[0] + GetRandomFloat(-750.0, 750.0);
										g_flRandomPayloadDefendArea[client][1] = flagpos[1] + GetRandomFloat(-750.0, 750.0);
										
										if(GetClientTeam(client) == 2)
										{
											NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomPayloadDefendArea[client], true, 5000.0, false, false, GetClientTeam(client));
											if(area != NavArea_Null)
											{
												area.GetRandomPoint(g_flSelectedPayloadDefendArea[client]);
												
												g_bFindNewDefendPayloadSpot[client] = false;
											}
											else
											{
												g_bFindNewDefendPayloadSpot[client] = true;
											}
										}
									}
									
									if(g_bBuildSentry[client])
									{
										if(GetVectorDistance(engiOrigin, g_flSelectedPayloadDefendArea[client]) < 80.0)
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 2");
											}
										}
										
										TF2_FindPath(client, g_flSelectedPayloadDefendArea[client]);
										
										if(PF_Exists(client) && IsPlayerAlive(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											EquipWeaponSlot(client, 2);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										TF2_FindPath(client, fEntityLocation);
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											g_bPathFinding[client] = true;
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											g_bPathFinding[client] = false;
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										TF2_FindPath(client, putdispenserpos);
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											EquipWeaponSlot(client, 2);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										TF2_FindPath(client, dispenserpos);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											g_bPathFinding[client] = true;
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											g_bPathFinding[client] = false;
										}
									}
								}
							}
						}
						if(StrContains(currentMap, "arena_" , false) != -1 || StrContains(currentMap, "koth_" , false) != -1)
						{
							int engidefendcap;
							while((engidefendcap = FindEntityByClassname(engidefendcap, "team_control_point")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(engidefendcap))
								{
									float engiOrigin[3];
									float ecappos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(engidefendcap, Prop_Send, "m_vecOrigin", ecappos);
									
									ecappos[2] += 100.0;
									
									if(GetMetal(client) == 0.0 || (!g_bSentryBuilded[client] && !g_bCanBuildSentryGun[client] || g_bSentryBuilded[client] && g_bSentryIsMaxLevel[client] && !g_bDispenserBuilded[client] && !g_bCanBuildDispenser[client]))
									{
										int ammopack = FindNearestAmmo(client);
										
										if(IsValidEntity(ammopack))
										{
											if(ammopack != -1)
											{
												float clientOrigin[3];
												float ammopackorigin[3];
												GetClientAbsOrigin(client, clientOrigin);
												GetEntPropVector(ammopack, Prop_Send, "m_vecOrigin", ammopackorigin);
													
												if(GetVectorDistance(clientOrigin, ammopackorigin) > 10.0)
												{
													if (!(PF_Exists(client))) 
													{
														PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
													}
							
													PF_SetGoalVector(client, ammopackorigin);
							
													PF_StartPathing(client);
						
													PF_EnableCallback(client, PFCB_Approach, Approach);
									
													if(!IsPlayerAlive(client) || !PF_Exists(client))
														return Plugin_Continue;
												
													TF2_MoveTo(client, g_flGoal[client], vel, angles);
												}
											}
										}
									}
									
									if(g_bSentryBuilded[client])
									{
										if(GetMetal(client) > 0 && (!g_bSentryIsMaxLevel[client] || !g_bSentryHealthIsFull[client]) && (!g_bDispenserBuilded[client] || (g_bDispenserBuilded[client] && g_bDispenserHealthIsFull[client])))
										{
											float sentrypos[3];
											GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
											
											float camangle[3];
											float fEntityLocation[3];
											float vec[3];
											float angle[3];
											GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
											GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
											fEntityLocation[2] += 35.0;
											MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
											GetVectorAngles(vec, camangle);
											camangle[0] *= -1.0;
											camangle[1] += 180.0;
											ClampAngle(camangle);
											
											if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
											{
												EquipWeaponSlot(client, 2);
												TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
												buttons |= IN_DUCK;
												if(IsWeaponSlotActive(client, 2))
												{
													buttons |= IN_ATTACK;
												}
												if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
												{
													TF2_MoveTo(client, sentrypos, vel, angles);
												}
											}
											
											if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
											{
												if (!(PF_Exists(client))) 
												{
													PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
												}
							
												PF_SetGoalVector(client, sentrypos);
							
												PF_StartPathing(client);
							
												PF_EnableCallback(client, PFCB_Approach, Approach);
									
												if(!IsPlayerAlive(client) || !PF_Exists(client))
													return Plugin_Continue;
											
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
											else
											{
												PF_StopPathing(client);
											}
										}
									}
									
									if(g_bSentryBuilded[client] && g_bSentryIsMaxLevel[client] && g_bSentryHealthIsFull[client] && !g_bMoveSentry[client])
									{
										if(!g_bDispenserBuilded[client] && g_bCanBuildDispenser[client])
										{
											float sentrypos2[3];
											GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos2);
											
											if (!(PF_Exists(client))) 
											{
												PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
											}
							
											PF_SetGoalVector(client, sentrypos2);
							
											PF_StartPathing(client);
							
											PF_EnableCallback(client, PFCB_Approach, Approach);
									
											if(!IsPlayerAlive(client) || !PF_Exists(client))
												return Plugin_Continue;
											
											if(GetVectorDistance(engiOrigin, sentrypos2) < 500.0)
											{
												if(IsWeaponSlotActive(client, 5))
												{
													buttons |= IN_ATTACK;
												}
												else
												{
													FakeClientCommandThrottled(client, "build 0");
												}
											}
								
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else if(GetMetal(client) > 0 && (g_bDispenserBuilded[client] && (!g_bDispenserIsMaxLevel[client] || !g_bDispenserHealthIsFull[client])))
										{
											float dispenserpos[3];
											GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
											
											float camangle[3];
											float fEntityLocation[3];
											float vec[3];
											float angle[3];
											GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
											GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
											fEntityLocation[2] += 35.0;
											MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
											GetVectorAngles(vec, camangle);
											camangle[0] *= -1.0;
											camangle[1] += 180.0;
											ClampAngle(camangle);
											
											if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
											{
												EquipWeaponSlot(client, 2);
												TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
												buttons |= IN_DUCK;
												if(IsWeaponSlotActive(client, 2))
												{
													buttons |= IN_ATTACK;
												}
												if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
												{
													TF2_MoveTo(client, dispenserpos, vel, angles);
												}
											}
											
											if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
											{
												if (!(PF_Exists(client))) 
												{
													PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
												}
							
												PF_SetGoalVector(client, dispenserpos);
							
												PF_StartPathing(client);
							
												PF_EnableCallback(client, PFCB_Approach, Approach);
									
												if(!IsPlayerAlive(client) || !PF_Exists(client))
													return Plugin_Continue;
											
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
											else
											{
												PF_StopPathing(client);
											}
										}
									}

									if(!g_bSentryBuilded[client] && g_bCanBuildSentryGun[client] && !g_bMoveSentry[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
							
										PF_SetGoalVector(client, ecappos);
						
										PF_StartPathing(client);
							
										PF_EnableCallback(client, PFCB_Approach, Approach);
								
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(IsPointVisible(clientEyes, ecappos))
										{
											if(GetVectorDistance(engiOrigin, ecappos) < GetRandomFloat(25.0, 2500.0))
											{
												if(IsWeaponSlotActive(client, 5))
												{
													buttons |= IN_ATTACK;
												}
												else
												{
													FakeClientCommandThrottled(client, "build 2");
												}
											}
										}
								
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
								}
							}
						}
					}
				}
				
				// Map Support
				
				if(!g_bMedicAllHaveTasks[client] && !g_bCamping[client] && !g_bSpyHaveAnyTask[client] && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && class != TFClass_Engineer && !g_bMakeStickyTrap[client])
				{
					if(StrContains(currentMap, "mvm_" , false) != -1)
					{
						int tankboss;
						if((tankboss = FindEntityByClassname(tankboss, "tank_boss")) != INVALID_ENT_REFERENCE)
						{
							int iTeamNumObj = GetEntProp(tankboss, Prop_Send, "m_iTeamNum");
							if(IsValidEntity(tankboss) && GetClientTeam(client) != iTeamNumObj)
							{
								float tankbosspos[3];
								GetEntPropVector(tankboss, Prop_Send, "m_vecOrigin", tankbosspos);
							
								tankbosspos[0] += GetRandomFloat(-150.0, 150.0);
								tankbosspos[1] += GetRandomFloat(-150.0, 150.0);
								tankbosspos[2] += 15.0;
							
								if (!(PF_Exists(client))) 
								{
									PF_Create(client, 24.0, 72.0, 10000.0, 600.0, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
								}
							
								PF_SetGoalVector(client, tankbosspos);
							
								PF_StartPathing(client);
							
								PF_EnableCallback(client, PFCB_Approach, Approach);
							
								if(!IsPlayerAlive(client) || !PF_Exists(client))
									return Plugin_Continue;
							
								if(GetVectorDistance(clientEyes, tankbosspos) > 100.0)
								{
									TF2_MoveTo(client, g_flGoal[client], vel, angles);
								}
							}
						}
						else
						{
							for (int search = 1; search <= MaxClients; search++)
							{
								if (TF2_HasTheFlag(search) && IsValidClient(search) && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
								{
									float searchOrigin[3];
									GetClientAbsOrigin(search, searchOrigin);
									
									searchOrigin[0] += GetRandomFloat(-100.0, 100.0);
									searchOrigin[1] += GetRandomFloat(-100.0, 100.0);
									searchOrigin[2] += 50.0;
							
									if (!(PF_Exists(client)))
									{
										PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
									}
						
									PF_SetGoalVector(client, searchOrigin);
					
									PF_StartPathing(client);
						
									PF_EnableCallback(client, PFCB_Approach, Approach);
						
									if(PF_Exists(client))
									{
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
								}
								else if (IsValidClient(search) && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
								{
									float searchOrigin[3];
									GetClientAbsOrigin(search, searchOrigin);
								
									searchOrigin[0] += GetRandomFloat(-1000.0, 1000.0);
									searchOrigin[1] += GetRandomFloat(-1000.0, 1000.0);
									searchOrigin[2] += 50.0;
							
									if (!(PF_Exists(client))) 
									{
										PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
									}
						
									PF_SetGoalVector(client, searchOrigin);
					
									PF_StartPathing(client);
						
									PF_EnableCallback(client, PFCB_Approach, Approach);
						
									if(PF_Exists(client))
									{
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
								}
							}
						}
					}
					else if(StrContains(currentMap, "koth_" , false) != -1 || StrContains(currentMap, "arena_" , false) != -1)
					{
						int capturepoint;
						if((capturepoint = FindEntityByClassname(capturepoint, "team_control_point")) != INVALID_ENT_REFERENCE)
						{
							int iTeamNumObj = GetEntProp(capturepoint, Prop_Send, "m_iTeamNum");
							if(IsValidEntity(capturepoint) && GetClientTeam(client) != iTeamNumObj)
							{
								float cappointpos[3];
								GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos);
								
								if(g_flDefendPosChangeTimer[client] < GetGameTime())
								{
									g_bFindNewDefendSpot[client] = true;
									
									g_flDefendPosChangeTimer[client] = GetGameTime() + GetRandomFloat(2.0, 7.0);
								}
								
								if((GetVectorDistance(clientEyes, g_flSelectedDefendArea[client]) > 100.0))
								{
									g_bPathFinding[client] = true;
								}
								else
								{
									g_bPathFinding[client] = false;
								}
								
								if(g_bFindNewDefendSpot[client])
								{
									g_flRandomDefendArea[client][0] = cappointpos[0] + GetRandomFloat(-200.0, 200.0);
									g_flRandomDefendArea[client][1] = cappointpos[1] + GetRandomFloat(-200.0, 200.0);
									g_flRandomDefendArea[client][2] = cappointpos[2] + 50.0;
									
									NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomDefendArea[client], false, 5000.0, false, false, GetClientTeam(client));
									if(area != NavArea_Null)
									{
										area.GetRandomPoint(g_flSelectedDefendArea[client]);
										
										g_bFindNewDefendSpot[client] = false;
									}
									else
									{
										g_bFindNewDefendSpot[client] = true;
									}
								}
								
								TF2_FindPath(client, g_flSelectedDefendArea[client]);
								
								if(PF_Exists(client) && g_bPathFinding[client])
								{
									TF2_MoveTo(client, g_flGoal[client], vel, angles);
								}
							}
							else if(IsValidEntity(capturepoint) && GetClientTeam(client) == iTeamNumObj)
							{
								if(class == TFClass_Scout)
								{
									float cappointpos[3];
									GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos);
									
									if(GetVectorDistance(clientEyes, g_flSelectedDefendArea[client]) < 500.0)
									{
										g_bFindNewDefendSpot[client] = true;
									}
									
									if((GetVectorDistance(clientEyes, g_flSelectedDefendArea[client]) > 100.0))
									{
										g_bPathFinding[client] = true;
									}
									else
									{
										g_bPathFinding[client] = false;
									}
									
									if(g_bFindNewDefendSpot[client])
									{
										g_flRandomDefendArea[client][0] = cappointpos[0] + GetRandomFloat(-1000.0, 1000.0);
										g_flRandomDefendArea[client][1] = cappointpos[1] + GetRandomFloat(-1000.0, 1000.0);
										g_flRandomDefendArea[client][2] = cappointpos[2];
										
										NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomDefendArea[client], true, 5000.0, false, false, GetClientTeam(client));
										if(area != NavArea_Null)
										{
											area.GetRandomPoint(g_flSelectedDefendArea[client]);
											
											g_bFindNewDefendSpot[client] = false;
										}
										else
										{
											g_bFindNewDefendSpot[client] = true;
										}
									}
									
									TF2_FindPath(client, g_flSelectedDefendArea[client]);
									
									if(PF_Exists(client) && g_bPathFinding[client])
									{
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
								}
								else
								{
									float cappointpos[3];
									GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos);
									
									if(g_flDefendPosChangeTimer[client] < GetGameTime())
									{
										g_bFindNewDefendSpot[client] = true;
										
										g_flDefendPosChangeTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
									}
									
									if((GetVectorDistance(clientEyes, g_flSelectedDefendArea[client]) > 100.0))
									{
										g_bPathFinding[client] = true;
									}
									else
									{
										g_bPathFinding[client] = false;
									}
									
									if(g_bFindNewDefendSpot[client])
									{
										g_flRandomDefendArea[client][0] = cappointpos[0] + GetRandomFloat(-1000.0, 1000.0);
										g_flRandomDefendArea[client][1] = cappointpos[1] + GetRandomFloat(-1000.0, 1000.0);
										
										NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomDefendArea[client], true, 5000.0, false, false, GetClientTeam(client));
										if(area != NavArea_Null)
										{
											area.GetRandomPoint(g_flSelectedDefendArea[client]);
											
											g_bFindNewDefendSpot[client] = false;
										}
										else
										{
											g_bFindNewDefendSpot[client] = true;
										}
									}
									
									TF2_FindPath(client, g_flSelectedDefendArea[client]);
									
									if(PF_Exists(client) && g_bPathFinding[client])
									{
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
								}
							}
						}
    			    }
					else if(StrContains(currentMap, "cp_" , false) != -1)
					{
						int capturepoint;
						while((capturepoint = FindEntityByClassname(capturepoint, "team_control_point")) != INVALID_ENT_REFERENCE)
						{
							int Owner = GetEntProp(capturepoint, Prop_Send, "m_iOwner");
							int iTeamCanCap = GetEntProp(capturepoint, Prop_Send, "m_bTeamCanCap");
							if(IsValidEntity(capturepoint) && Owner != client && iTeamCanCap == 1)
							{
								float cappointpos[3];
								GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos);
								
								cappointpos[0] += GetRandomFloat(-150.0, 150.0);
								cappointpos[1] += GetRandomFloat(-150.0, 150.0);
								cappointpos[2] += 15.0;
							
								if (!(PF_Exists(client))) 
								{
									PF_Create(client, 24.0, 72.0, 10000.0, 600.0, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
								}
							
								PF_SetGoalVector(client, cappointpos);
							
								PF_StartPathing(client);
							
								PF_EnableCallback(client, PFCB_Approach, Approach);
							
								if(!IsPlayerAlive(client) || !PF_Exists(client))
									return Plugin_Continue;
							
								if(GetVectorDistance(clientEyes, cappointpos) > 150.0)
								{
									TF2_MoveTo(client, g_flGoal[client], vel, angles);
								}
							}
						}
    			    }
					else if(StrContains(currentMap, "ctf_" , false) != -1)
					{
						if(class != TFClass_Engineer)
						{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) != iTeamNumObj)
								{
									float clientOrigin[3];
									float flagpos[3];
									GetClientAbsOrigin(client, clientOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
							
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
							
									//PrintToServer("FlagStatus %i", FlagStatus);
							
									if(FlagStatus == 1)
									{
										if(!TF2_HasTheFlag(client))
										{
											for (int search = 1; search <= MaxClients; search++)
											{
												if (TF2_HasTheFlag(search) && IsValidClient(search) && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
												{
													float searchOrigin[3];
													GetClientEyePosition(search, searchOrigin);
													
													TF2_FindPath(client, searchOrigin);
													
													if(PF_Exists(client) && IsPlayerAlive(client))
													{
														TF2_MoveTo(client, g_flGoal[client], vel, angles);
													}
												}
												else if (IsValidClient(search) && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
												{
													float searchOrigin[3];
													GetClientAbsOrigin(search, searchOrigin);
													
													searchOrigin[0] += GetRandomFloat(-100.0, 100.0);
													searchOrigin[1] += GetRandomFloat(-100.0, 100.0);
													searchOrigin[2] += 50.0;
													
													TF2_FindPath(client, searchOrigin);
													
													if(PF_Exists(client) && IsPlayerAlive(client))
													{
														TF2_MoveTo(client, g_flGoal[client], vel, angles);
													}
												}
											}
										}
									}
									else if(FlagStatus == 0 || FlagStatus == 2)
									{
										TF2_FindPath(client, flagpos);
										
										if(PF_Exists(client) && IsPlayerAlive(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
								}
							}
						}
					}
					else
					{
						if(class != TFClass_Engineer)
						{
							int flag;
							if((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(flag))
								{
									float flagpos[3];
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
									
									if(g_flPayloadDefendPosChangeTimer[client] < GetGameTime())
									{
										g_bFindNewDefendPayloadSpot[client] = true;
										
										g_flPayloadDefendPosChangeTimer[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
									}
									
									if((GetVectorDistance(clientEyes, g_flSelectedPayloadDefendArea[client]) > 100.0))
									{
										g_bPathFinding[client] = true;
									}
									else
									{
										g_bPathFinding[client] = false;
									}
									
									if(g_bFindNewDefendPayloadSpot[client])
									{
										g_flRandomPayloadDefendArea[client][0] = flagpos[0] + GetRandomFloat(-500.0, 500.0);
										g_flRandomPayloadDefendArea[client][1] = flagpos[1] + GetRandomFloat(-500.0, 500.0);
										
										if(GetClientTeam(client) == 2)
										{
											NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomPayloadDefendArea[client], true, 5000.0, false, false, GetClientTeam(client));
											if(area != NavArea_Null)
											{
												area.GetRandomPoint(g_flSelectedPayloadDefendArea[client]);
												
												g_bFindNewDefendPayloadSpot[client] = false;
											}
											else
											{
												g_bFindNewDefendPayloadSpot[client] = true;
											}
										}
									}
									
									if(GetClientTeam(client) == 2)
									{
										TF2_FindPath(client, g_flSelectedPayloadDefendArea[client]);
										
										if(PF_Exists(client) && g_bPathFinding[client])
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
									
									if(GetClientTeam(client) == 3)
									{
										TF2_FindPath(client, flagpos);
										
										if(PF_Exists(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
								}
							}
						}
					}
				}
				else if(class == TFClass_Medic && Ent == -1)
				{
					for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)) && GetHealth(search) < 125.0)
						{
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							
							g_bMedicAllHaveTasks[client] = true;
							
							if(GetEntityFlags(search) & FL_ONGROUND)
							{
								TF2_FindPath(client, searchOrigin);
								
								if(PF_Exists(client) && IsPlayerAlive(client))
								{
									TF2_MoveTo(client, g_flGoal[client], vel, angles);
								}
							}
						}
						else if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)) && TF2_GetPlayerClass(search) != TFClass_Medic && !TF2_IsPlayerInCondition(search, TFCond_Cloaked) && !TF2_IsPlayerInCondition(search, TFCond_Disguised) && !IsWeaponSlotActive(search, 2) && !TF2_IsPlayerInCondition(search, TFCond_Zoomed) && !TF2_IsPlayerInCondition(search, TFCond_Teleporting) && !TF2_IsPlayerInCondition(search, TFCond_Disguising))
						{
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							
							g_bMedicAllHaveTasks[client] = true;
							
							if(GetEntityFlags(search) & FL_ONGROUND)
							{
								TF2_FindPath(client, searchOrigin);
								
								if(PF_Exists(client) && IsPlayerAlive(client))
								{
									TF2_MoveTo(client, g_flGoal[client], vel, angles);
								}
							}
						}
						else
						{
							g_bMedicAllHaveTasks[client] = false;
						}
					}
				}
				
				if(class != TFClass_Medic)
				{
					g_bMedicAllHaveTasks[client] = false;
				}
				
				if(class != TFClass_Spy)
				{
					g_bSpyHaveAnyTask[client] = false;
				}
				
				if(StrContains(currentMap, "ctf_" , false) != -1)
				{
					if(class == TFClass_DemoMan)
					{
						int flag;
						while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
						{
							int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
							if(IsValidEntity(flag) && GetClientTeam(client) != iTeamNumObj)
							{
								float clientOrigin[3];
								float flagpos[3];
								GetClientAbsOrigin(client, clientOrigin);
								GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
							
								int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
							
								if(FlagStatus == 2)
								{
									g_bMakeStickyTrap[client] = true;
								}
								else
								{
									g_bMakeStickyTrap[client] = false;
								}
							}
						}
					}
				}
				
				if(class != TFClass_Medic)
				{
					float camangle[3];
					float targetEyes[3];
					float targetEyes2[3];
					float targetEyesBase[3];

					if(Ent != -1)
					{
						float vec[3];
						float angle[3];
						GetClientAbsOrigin(Ent, targetEyes);
						GetClientAbsOrigin(Ent, targetEyes2);
						GetClientAbsOrigin(Ent, targetEyesBase);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
						
						float location_check[3];
						GetClientAbsOrigin(client, location_check);

						float chainDistance;
						chainDistance = GetVectorDistance(location_check,targetEyes);
						
						GetClientAbsOrigin(Ent, g_flLookAtLastKnownEnemyPos[client]);
						
						g_flLookAtLastKnownEnemyPos[client][2] += 75.0;
						
						new TFClassType:enemyclass = TF2_GetPlayerClass(Ent);
						
						float EntVec[3];
						GetEntPropVector(Ent, Prop_Data, "m_vecVelocity", EntVec);
						
						if(class == TFClass_Soldier)
						{
							if(IsWeaponSlotActive(client, 0))
							{
								targetEyes[2] += 5.0;
								targetEyes[1] += (EntVec[1] / 2);
							}
							else
							{
								targetEyes[2] += 50.0;
								targetEyes[1] += 0.0;
							}
							targetEyes2[2] += 50.0;
						}
						if(class == TFClass_DemoMan)
						{
							targetEyes2[2] += chainDistance;
							if(chainDistance < 500)
							{
								targetEyes[2] += 50.0;
							}
							if(chainDistance > 500 && chainDistance < 750)
							{
								targetEyes[2] += 100.0;
							}
							if(chainDistance > 750 && chainDistance < 1000)
							{
								targetEyes[2] += 150.0;
							}
							if(chainDistance > 1000 && chainDistance < 1250)
							{
								targetEyes[2] += 200.0;
							}
							if(chainDistance > 1250 && chainDistance < 1500)
							{
								targetEyes[2] += 250.0;
							}
							if(chainDistance > 1500)
							{
								targetEyes[2] += 300.0;
							}
						}
						if(class == TFClass_Pyro)
						{
							targetEyes[2] += 35.0;
						}
						if(class == TFClass_Scout || class == TFClass_Heavy || class == TFClass_Engineer || class == TFClass_Spy)
						{
							targetEyes[2] += 50.0;
						}
						if(class == TFClass_Sniper)
						{
							if(enemyclass == TFClass_Sniper || enemyclass == TFClass_Medic || enemyclass == TFClass_Spy || enemyclass == TFClass_DemoMan)
							{
								targetEyes[2] += 70.0;
							}
							if(enemyclass == TFClass_Soldier || enemyclass == TFClass_Pyro)
							{
								targetEyes[2] += 65.0;
							}
							if(enemyclass == TFClass_Scout || enemyclass == TFClass_Engineer)
							{
								targetEyes[2] += 60.0;
							}
							if(enemyclass == TFClass_Heavy)
							{
								targetEyes[2] += 79.0;
							}
						}
						
						MakeVectorFromPoints(targetEyes, clientEyes, vec);
						GetVectorAngles(vec, camangle);
						camangle[0] *= -1.0;
						camangle[1] += 180.0;

						ClampAngle(camangle);
						
						if(enemyclass == TFClass_Spy)
						{
							if(!TF2_IsPlayerInCondition(Ent, TFCond_Cloaked) && TF2_IsPlayerInCondition(Ent, TFCond_Disguising))
							{
								g_bSpyAlert[Ent] = true;
								g_bISeeSpy[client] = true;
							}
							if(!TF2_IsPlayerInCondition(Ent, TFCond_Disguised))
							{
								g_bSpyAlert[Ent] = true;
								g_bISeeSpy[client] = true;
							}
							if(TF2_IsPlayerInCondition(Ent, TFCond_CloakFlicker))
							{
								g_bSpyAlert[Ent] = true;
								g_bISeeSpy[client] = true;
							}
							if(TF2_IsPlayerInCondition(Ent, TFCond_Taunting))
							{
								g_bSpyAlert[Ent] = true;
								g_bISeeSpy[client] = true;
							}
							if(TF2_IsPlayerInCondition(Ent, TFCond_DisguiseRemoved))
							{
								g_bSpyAlert[Ent] = true;
								g_bISeeSpy[client] = true;
							}
							if(TF2_IsPlayerInCondition(Ent, TFCond_Disguised))
							{
								if(TF2_IsPlayerInCondition(Ent, TFCond_OnFire) || TF2_IsPlayerInCondition(Ent, TFCond_Jarated) || TF2_IsPlayerInCondition(Ent, TFCond_Bleeding) || TF2_IsPlayerInCondition(Ent, TFCond_Milked))
								{
									g_bSpyAlert[Ent] = true;
									g_bISeeSpy[client] = true;
								}
							}
							if(TF2_IsPlayerInCondition(Ent, TFCond_Cloaked) && TF2_IsPlayerInCondition(Ent, TFCond_Disguising))
							{
								g_bSpyAlert[Ent] = false;
								g_bISeeSpy[client] = true;
							}
						}
						
						if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						{
							TF2_LookAtPos(client, g_flClientEyePos[Ent], RandomizeAimWhenZoomed);
						}
						else if(class == TFClass_Scout)
						{
							TF2_LookAtPos(client, targetEyes, RandomizeAim);
						}
						else if(class == TFClass_DemoMan || class == TFClass_Soldier)
						{
							if(class == TFClass_Soldier)
							{
								if(IsPointVisible(clientEyes, targetEyesBase) && IsPointVisible2(clientEyes, targetEyesBase))
								{
									TF2_LookAtPos(client, targetEyes, RandomizeAim);
								}
								else
								{
									TF2_LookAtPos(client, targetEyes2, RandomizeAim);
								}
							}
							if(class == TFClass_DemoMan)
							{
								if(IsPointVisible(clientEyes, targetEyes) && IsPointVisible2(clientEyes, targetEyes))
								{
									TF2_LookAtPos(client, targetEyes, RandomizeAim);
								}
								else
								{
									TF2_LookAtPos(client, targetEyes2, RandomizeAim);
								}
							}
						}
						else if(class != TFClass_Spy)
						{
							TF2_LookAtPos(client, targetEyes, RandomizeAim);
						}
						
						if(class == TFClass_Spy)
						{
							if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								if(chainDistance < 300.0)
								{
									TF2_LookAtPos(client, targetEyes, RandomizeAim);
								}
								else if(chainDistance > 325.0)
								{
									if(ClientViews(Ent, client))
									{
										TF2_LookAround(client);
									}
									else
									{
										TF2_LookAtPos(client, targetEyes, RandomizeAim);
									}
								}
							}
							else
							{
								TF2_LookAtPos(client, targetEyes, RandomizeAim);
							}
						}
						
						if(class == TFClass_Heavy)
						{
							if(chainDistance < 200.0)
							{
								EquipWeaponSlot(client, 1);
							}
							else if(GetAmmo(client) > 0)
							{
								EquipWeaponSlot(client, 0);
							}
						}
						
						if(class == TFClass_Soldier)
						{
							if(enemyclass == TFClass_Pyro)
							{
								if(chainDistance < 512.0)
								{
									EquipWeaponSlot(client, 1);
								}
								else
								{
									EquipWeaponSlot(client, 0);
								}
							}
							else
							{
								if(chainDistance < 256.0)
								{
									EquipWeaponSlot(client, 1);
								}
								else
								{
									EquipWeaponSlot(client, 0);
								}
							}
							if(IsWeaponSlotActive(client, 0))
							{
								if(PrimID == 730)
								{
									int ClipAmmo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
									if(ClipAmmo == 3)
									{
										buttons &= ~IN_ATTACK;
									}
									else
									{
										buttons |= IN_ATTACK;
									}
								}
								else
								{
									buttons |= IN_ATTACK;
								}
							}
							else
							{
								buttons |= IN_ATTACK;
							}
						}
						
						if(class == TFClass_Engineer || class == TFClass_Scout)
						{
							if(chainDistance < 1024.0)
							{
								EquipWeaponSlot(client, 0);
							}
							else
							{
								EquipWeaponSlot(client, 1);
							}
						}
						
						if(class == TFClass_DemoMan)
						{
							if(PrimID == 996)
							{
								if(chainDistance < 64.0)
								{
									EquipWeaponSlot(client, 2);
								}
								else
								{
									EquipWeaponSlot(client, 0);
								}
							}
							else
							{
								if(chainDistance < 128.0)
								{
									EquipWeaponSlot(client, 2);
								}
								else
								{
									EquipWeaponSlot(client, 0);
								}
							}
							if(IsWeaponSlotActive(client, 0))
							{
								if(PrimID == 996)
								{
									if(RepeartAttackTimer == INVALID_HANDLE)
									{
										buttons |= IN_ATTACK;
									}
									else
									{
										buttons &= ~IN_ATTACK;
									}
								}
								else
								{
									buttons |= IN_ATTACK;
								}
							}
							else
							{
								buttons |= IN_ATTACK;
							}
						}
						
						if(class == TFClass_Sniper)
						{
							if(PrimID != 56 && PrimID != 1005 && PrimID != 1092)
							{
								if(!TF2_IsPlayerInCondition(client, TFCond_Zoomed))
								{
									if(chainDistance < 100.0)
									{
										EquipWeaponSlot(client, 2);
									}
									else if(chainDistance < 1000.0)
									{
										EquipWeaponSlot(client, 1);
									}
									else
									{
										EquipWeaponSlot(client, 0);
									}
								}
							}
							else if(PrimID == 56 || PrimID == 1005 || PrimID == 1092)
							{
								if(chainDistance < 200.0)
								{
									EquipWeaponSlot(client, 2);
								}
								if(chainDistance < 400.0)
								{
									EquipWeaponSlot(client, 1);
								}
								else
								{
									EquipWeaponSlot(client, 0);
								}
							}
						}
						
						if(class == TFClass_Sniper)
						{
							if(IsWeaponSlotActive(client, 0))
							{
								if(PrimID == 56 || PrimID == 1005 || PrimID == 1092 || PrimID == 1098)
								{
									if(GetClientAimTarget(client) > 0)
									{
										buttons &= ~IN_ATTACK;
									}
									else
									{
										buttons |= IN_ATTACK;
									}
								}
								else
								{
									if(g_flSniperPerfectShotTimer[client] < GetGameTime())
									{
										if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
										{
											buttons |= IN_ATTACK;
										}
										else
										{
											buttons |= IN_ATTACK2;
										}
										g_flSniperPerfectShotTimer[client] = GetGameTime() + 5.0;
									}
									
									if(g_flSniperFastShotTimer[client] < GetGameTime())
									{
										if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
										{
											if(GetClientAimTarget(client) > 0)
											{
												buttons |= IN_ATTACK;
											}
										}
										else
										{
											buttons |= IN_ATTACK2;
										}
										g_flSniperFastShotTimer[client] = GetGameTime() + 2.0;
									}
								}
							}
							else
							{
								buttons |= IN_ATTACK;
								buttons |= IN_ATTACK2;
							}
						}
						
						if(class != TFClass_Sniper && class != TFClass_Spy && class != TFClass_Pyro && class != TFClass_Heavy && class != TFClass_DemoMan && class != TFClass_Soldier)
						{
							buttons |= IN_ATTACK;
						}
						
						if(class == TFClass_Pyro || class == TFClass_Heavy)
						{
							if(IsWeaponSlotActive(client, 0))
							{
								if(GetAmmo(client) > 0)
								{
									buttons |= IN_ATTACK;
								}
								else
								{
									EquipWeaponSlot(client, 1);
								}
							}
							if((IsWeaponSlotActive(client, 2) || IsWeaponSlotActive(client, 1)) && (class == TFClass_Pyro || class == TFClass_Heavy))
							{
								buttons |= IN_ATTACK;
							}
						}
						
						if(class == TFClass_Spy)
						{
							if(TF2_IsPlayerInCondition(client, TFCond_Disguised) || chainDistance < 200.0)
							{
								EquipWeaponSlot(client, 2);
							}
							else if(!TF2_IsPlayerInCondition(client, TFCond_Disguised))
							{
								EquipWeaponSlot(client, 0);
							}
							
							if(g_bHealthIsLow[client] && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK2;
							}
							
							if(!g_bHealthIsLow[client] && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !g_bAmmoIsLow[client] && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK2;
							}
							
							if(GetClientAimTarget(client) == Ent && GetClientButtons(Ent) == IN_ATTACK && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_HasTheFlag(client))
							{
								buttons |= IN_ATTACK2;
							}
							else if(GetClientAimTarget(client) > 0 && GetClientButtons(Ent) == IN_ATTACK && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_HasTheFlag(client))
							{
								buttons |= IN_ATTACK2;
							}
							else if(!TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								buttons |= IN_ATTACK;
							}
							
							if(TF2_IsPlayerInCondition(client, TFCond_Cloaked) && chainDistance < 300.0)
							{
								TF2_FindPath(client, targetEyes);
								
								if(PF_Exists(client))
								{
									TF2_MoveOut(client, g_flGoal[client], vel, angles);
								}
							}
							else if(!g_bHealthIsLow[client] && TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								if(GetClientButtons(Ent) != IN_ATTACK && chainDistance < 300.0)
								{
									float flBotAng[3], flTargetAng[3];
									GetClientEyeAngles(client, flBotAng);
									GetClientEyeAngles(Ent, flTargetAng);
									int iAngleDiff = AngleDifference(flBotAng[1], flTargetAng[1]);
									
									if(GetClientAimTarget(Ent) == client)
									{
										vel = moveBackwards(vel,300.0);
									}
									else
									{
										vel = moveForward(vel,300.0);
									}
									
									g_bPathFinding[client] = false;

									if(iAngleDiff > 90)
									{
										vel = moveRight(vel,300.0);
									}
									else if(iAngleDiff < -90)
									{
										vel = moveLeft(vel,300.0);
									}
									else
									{
										vel = moveBackwards(vel,300.0);
									}
								}
								else if(GetClientButtons(Ent) == IN_ATTACK)
								{
									g_bPathFinding[client] = true;
									
									TF2_FindPath(client, targetEyes);
									
									if(PF_Exists(client))
									{
										TF2_MoveOut(client, g_flGoal[client], vel, angles);
									}
								}
							}
						}
						
						if(class == TFClass_Pyro)
						{
							if(IsWeaponSlotActive(client, 0) && chainDistance < 150.0 && (PrimID != 594 && PrimID != 40 && PrimID != 1146))
							{
								buttons |= IN_ATTACK2;
							}
							if(chainDistance < 400.0 && GetAmmo(client) > 0)
							{
								EquipWeaponSlot(client, 0);
							}
							if(chainDistance > 400.0)
							{
								EquipWeaponSlot(client, 1);
							}
							if(chainDistance < 512.0 && !g_bAmmoIsLow[client] && g_bHealthIsLow[client] && !TF2_HasTheFlag(client) && IsWeaponSlotActive(client, 0))
							{
								if(GetEntityFlags(client) & FL_ONGROUND)
								{
									if(GetEntityFlags(Ent) & FL_ONGROUND)
									{
										if(PrimID == 1146 || PrimID == 40)
										{
											float flBotAng[3], flTargetAng[3];
											GetClientEyeAngles(client, flBotAng);
											GetClientEyeAngles(Ent, flTargetAng);
											int iAngleDiff = AngleDifference(flBotAng[1], flTargetAng[1]);
											
											if(GetClientAimTarget(Ent) == client)
											{
												vel = moveBackwards(vel,300.0);
											}
											else
											{
												vel = moveForward(vel,300.0);
											}
											
											g_bPathFinding[client] = false;

											if(iAngleDiff > 90)
											{
												vel = moveRight(vel,300.0);
											}
											else if(iAngleDiff < -90)
											{
												vel = moveLeft(vel,300.0);
											}
											else
											{
												vel = moveBackwards(vel,300.0);
											}
										}
										else
										{
											g_bPathFinding[client] = true;
											
											TF2_FindPath(client, targetEyes);
											
											if(PF_Exists(client))
											{
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
										}
									}
								}
							}
						}
						
						Handle Wall;
						float direction[3];
						GetClientEyeAngles(client, camangle);
						camangle[0] = 0.0;
						camangle[2] = 0.0;
						camangle[1] -= 40.0;
						GetAngleVectors(camangle, direction, NULL_VECTOR, NULL_VECTOR);
						ScaleVector(direction, 75.0);
						AddVectors(clientEyes, direction, targetEyes);
						Wall = TR_TraceRayFilterEx(clientEyes,targetEyes,MASK_SOLID,RayType_EndPoint,Filter);
						if(TR_DidHit(Wall))
						{
							TR_GetEndPosition(targetEyes, Wall);
							float wallDistance;
							wallDistance = GetVectorDistance(clientEyes,targetEyes);
							if(wallDistance < 75.0 && !TF2_IsPlayerInCondition(client, TFCond_Zoomed))
							{
								buttons |= IN_JUMP;
							}
						}
						
						CloseHandle(Wall);
					}
					else
					{
						if(class == TFClass_Sniper)
						{
							if(PrimID == 56 || PrimID == 1005 || PrimID == 1092)
							{
								buttons |= IN_ATTACK2;
							}
						}
					}
				}

				if(class == TFClass_Medic)
				{
					if(Ent != -1)
					{
						float angle[3];
						float mediceye[3];
						float teammateeye[3];
						float targetEyes[3];
						GetClientEyePosition(Ent, targetEyes);
						GetClientEyeAngles(client, mediceye);
						GetClientEyePosition(Ent, teammateeye);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
						GetClientEyeAngles(Ent, g_flLookAtLastKnownEnemyPos[client]);
						
						g_bMedicAllHaveTasks[client] = true;
						
						float location_check[3];
						GetClientAbsOrigin(client, location_check);

						float chainDistance;
						chainDistance = GetVectorDistance(location_check,targetEyes);
						
						if(GetClientTeam(Ent) == GetClientTeam(client))
						{
							TF2_LookAtPos(client, teammateeye, RandomizeAim); // Smooth Aim
						}
						
						if(GetClientTeam(Ent) != GetClientTeam(client))
						{
							TF2_LookAtPos(client, targetEyes, RandomizeAim); // Smooth Aim
						}
						
						//TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR); // Aimbot

						if(AttackTimer == INVALID_HANDLE)
						{
							AttackTimer = CreateTimer(2.0, ResetAttackTimer);
						}
						else
						{
							if(GetClientTeam(Ent) == GetClientTeam(client) && IsWeaponSlotActive(client, 1))
							{
								buttons |= IN_ATTACK;
							}
							else if(GetClientTeam(Ent) != GetClientTeam(client))
							{
								buttons |= IN_ATTACK;
							}
						}
						
						if(GetClientButtons(Ent) & IN_ATTACK && GetHealth(client) < 50.0)
						{
							buttons |= IN_ATTACK2;
						}

						if(GetClientTeam(Ent) == GetClientTeam(client))
						{
							EquipWeaponSlot(client, 1);
						}
						else if(GetClientTeam(Ent) != GetClientTeam(client) && !g_bSpyAlert[Ent] && TF2_IsPlayerInCondition(Ent, TFCond_Disguised) && !TF2_IsPlayerInCondition(Ent, TFCond_Cloaked))
						{
							EquipWeaponSlot(client, 1);
						}
						else if(GetClientTeam(Ent) != GetClientTeam(client))
						{
							if(TF_GetUberLevel(client) >= 25.0 && (GetHealth(client) < 50.0 || GetHealth(Ent) < 125.0 && GetClientButtons(Ent) == IN_ATTACK))
							{
								EquipWeaponSlot(client, 1);
								buttons |= IN_ATTACK2;
							}
							else if(!g_bHealthIsLow[client] && chainDistance < 150.0 && GetHealth(client) > 100.0)
							{
								EquipWeaponSlot(client, 2);
							}
							else
							{
								EquipWeaponSlot(client, 0);
							}
						}
						
						if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged)) // For Save Ubercharge 3.9
						{
							buttons |= IN_ATTACK;
						}
						
						for (int search = 1; search <= MaxClients; search++)
						{
							if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && !TF2_HasTheFlag(client) && GetClientTeam(Ent) == GetClientTeam(client))
							{
								float searchOrigin[3];
								GetClientAbsOrigin(search, searchOrigin);
								
								searchOrigin[2] += 50.0;
								
								if(IsPointVisible(clientEyes, searchOrigin) && IsPointVisible2(clientEyes, searchOrigin))
								{
									float teammateOrigin[3];
									GetClientAbsOrigin(Ent, teammateOrigin);
									
									if(GetClientTeam(client) != GetClientTeam(search) && IsPointVisible(clientEyes, searchOrigin) && IsPointVisible(clientEyes, teammateOrigin) && IsPointVisible(teammateOrigin, searchOrigin))
									{
										float randomteammateOrigin[3];
										float selectedteammateOrigin[3];
										
										randomteammateOrigin[0] = teammateOrigin[0] + GetRandomFloat(-500.0, 500.0);
										randomteammateOrigin[1] = teammateOrigin[1] + GetRandomFloat(-500.0, 500.0);
										randomteammateOrigin[1] = teammateOrigin[2];
										
										if(IsPointVisible(clientEyes, searchOrigin))
										{
											NavArea area = TheNavMesh.GetNearestNavArea_Vec(randomteammateOrigin, true, 10000.0, false, false, GetClientTeam(client));
											if(area != NavArea_Null)
											{
												if(IsPointVisible(clientEyes, teammateOrigin) && !IsPointVisible(clientEyes, searchOrigin))
												{
													area.GetRandomPoint(selectedteammateOrigin);
												}
											}
										}
										
										if(GetVectorDistance(clientEyes, selectedteammateOrigin) > 100.0)
										{
											g_bPathFinding[client] = true;
											
											TF2_FindPath(client, selectedteammateOrigin);
											
											if(PF_Exists(client) && IsPlayerAlive(client))
											{
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
										}
										else
										{
											g_bPathFinding[client] = false;
										}
									}
									else if(GetClientTeam(Ent) == GetClientTeam(client))
									{
										if(GetVectorDistance(clientEyes, teammateOrigin) > 250.0)
										{
											g_bPathFinding[client] = true;
											
											TF2_FindPath(client, teammateOrigin);
											
											if(PF_Exists(client) && IsPlayerAlive(client))
											{
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
										}
										else
										{
											g_bPathFinding[client] = false;
										}
									}
								}
							}
						}

						if(chainDistance > 150.0 && GetClientTeam(Ent) != GetClientTeam(client) && !TF2_HasTheFlag(client) && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
						{
							TF2_FindPath(client, g_flSpawnLocation[client]);
							
							if(PF_Exists(client) && IsPlayerAlive(client))
							{
								TF2_MoveTo(client, g_flGoal[client], vel, angles);
							}
						}
						
						if(chainDistance >= 50.0)
						{
							if(GetClientButtons(Ent) & IN_JUMP && !TF2_IsPlayerInCondition(client, TFCond_Zoomed))
							{
								buttons |= IN_JUMP;
							}
							// Will not Duck if Enemy is target(3.4)
							if(GetClientButtons(Ent) & IN_DUCK  && GetClientTeam(Ent) == GetClientTeam(client))
							{
								buttons |= IN_DUCK;
							}
						}
					}
					else
					{
						if(StrContains(currentMap, "ctf_" , false) != -1)
						{
							for (int search = 1; search <= MaxClients; search++)
							{
								if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)) && GetHealth(search) < 125.0)
								{
									float searchOrigin[3];
									GetClientAbsOrigin(search, searchOrigin);
									
									if(GetEntityFlags(search) & FL_ONGROUND)
									{
										TF2_FindPath(client, searchOrigin);
										
										if(PF_Exists(client) && IsPlayerAlive(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
								}
								else if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)) && TF2_GetPlayerClass(search) != TFClass_Medic && !TF2_IsPlayerInCondition(search, TFCond_Cloaked) && !TF2_IsPlayerInCondition(search, TFCond_Disguised) && !IsWeaponSlotActive(search, 2) && !TF2_IsPlayerInCondition(search, TFCond_Zoomed) && !TF2_IsPlayerInCondition(search, TFCond_Teleporting) && !TF2_IsPlayerInCondition(search, TFCond_Disguising))
								{
									float searchOrigin[3];
									GetClientAbsOrigin(search, searchOrigin);
									
									if(GetEntityFlags(search) & FL_ONGROUND)
									{
										TF2_FindPath(client, searchOrigin);
										
										if(PF_Exists(client) && IsPlayerAlive(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
								}
							}
						}
						
						EquipWeaponSlot(client, 0);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:BotDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(botid))
	{
		GetClientAbsOrigin(botid, g_flLastDiedArea[botid]);
		
		g_bBotIsDied[botid] = true;
		
		for (int enemy = 1; enemy <= MaxClients; enemy++)
		{
			if (IsClientInGame(enemy) && IsPlayerAlive(enemy) && enemy != botid && (GetClientTeam(botid) != GetClientTeam(enemy)))
			{
				for (int friend = 1; friend <= MaxClients; friend++)
				{
					if (IsClientInGame(friend) && IsPlayerAlive(friend) && friend != botid && (GetClientTeam(botid) == GetClientTeam(friend)))
					{
						float friendOrigin[3];
						float botOrigin[3];
						float attackerOrigin[3];
						GetClientEyePosition(friend, friendOrigin);
						GetClientEyePosition(botid, botOrigin);
						GetClientEyePosition(enemy, attackerOrigin);
						
						if(IsPointVisible(botOrigin, friendOrigin))
						{
							if(IsPointVisible(friendOrigin, attackerOrigin))
							{
								if(ClientViews(friend, botid))
								{
									GetClientEyePosition(enemy, g_flLookAtLastKnownEnemyPos[friend]);
								}
								else
								{
									GetClientEyePosition(botid, g_flLookAtLastKnownEnemyPos[friend]);
								}
							}
							else
							{
								GetClientEyePosition(enemy, g_flLookAtLastKnownEnemyPos[friend]);
							}
						}
					}
				}
			}
		}
	}
}

public Action:BotHurt(Handle event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_bPickRandomSniperSpot[botid] = true;
	g_flSniperRange[botid] = GetRandomFloat(75.0, 125.0);
	
	if(IsValidClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			for (int enemy = 1; enemy <= MaxClients; enemy++)
			{
				if (IsClientInGame(enemy) && IsPlayerAlive(enemy) && enemy != botid && (GetClientTeam(botid) != GetClientTeam(enemy)))
				{
					GetClientEyePosition(enemy, g_flLookAtLastKnownEnemyPos[botid]);
					
					for (int friend = 1; friend <= MaxClients; friend++)
					{
						if (IsClientInGame(friend) && IsPlayerAlive(friend) && friend != botid && (GetClientTeam(botid) == GetClientTeam(friend)))
						{
							float friendOrigin[3];
							float botOrigin[3];
							float attackerOrigin[3];
							GetClientEyePosition(friend, friendOrigin);
							GetClientEyePosition(botid, botOrigin);
							GetClientEyePosition(enemy, attackerOrigin);
							
							if(IsPointVisible(botOrigin, friendOrigin))
							{
								if(IsPointVisible(friendOrigin, attackerOrigin))
								{
									if(ClientViews(friend, botid))
									{
										GetClientEyePosition(enemy, g_flLookAtLastKnownEnemyPos[friend]);
									}
									else
									{
										GetClientEyePosition(botid, g_flLookAtLastKnownEnemyPos[friend]);
									}
								}
								else
								{
									GetClientEyePosition(enemy, g_flLookAtLastKnownEnemyPos[friend]);
								}
							}
						}
					}
				}
			}
		}
	}
}

stock int GetTeamsCount(int team)
{
    int number = 0;
    for (int i=1; i<=MaxClients; i++)
    {
        if (GetClientTeam(i) == team) 
            number++;
    }
    return number;
}  

public Action:BotSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if(IsValidClient(botid))
	{
		g_bISeeSpy[botid] = false;
		g_bSpyAlert[botid] = false;
		g_bMoveSentry[botid] = false;
		g_bUseTeleporter[botid] = false;
		g_bMakeStickyTrap[botid] = false;
		g_bMoveSentry[botid] = false;
		g_flSniperRange[botid] = GetRandomFloat(75.0, 125.0);
		g_flWaitJumpTimer[botid] = GetGameTime() + 10.0;
		GetClientAbsOrigin(botid, g_flSpawnLocation[botid]);
		
		if(g_bBotIsDied[botid])
		{
			int randomFLDA = GetRandomInt(1,100);
			if(randomFLDA <= GetConVarFloat(AFKBOT_FindLastDiedAreaChance))
			{
				g_bFindLastDiedArea[botid] = true;
			}
			else
			{
				g_bFindLastDiedArea[botid] = false;
			}
		}
		
		if(TF2_GetPlayerClass(botid) == TFClass_Spy)
		{
			g_bBackStabVictim[botid] = true;
			g_bSapBuildings[botid] = false;
		}
		
		if(TF2_GetPlayerClass(botid) == TFClass_Sniper)
		{
			g_bPickRandomSniperSpot[botid] = true;
		}
		
		if(TF2_GetPlayerClass(botid) == TFClass_Engineer)
		{
			g_bPickUnUsedSentrySpot[botid] = true;
		}
	}
}

stock void PrepareForBattle(int client)
{
	int buttons = GetClientButtons(client);
	if(GetClip(GetPlayerWeaponSlot(client, 0)) == 0)
	{
		EquipWeaponSlot(client, 0);
		buttons |= IN_RELOAD;
	}
	else if(GetClip(GetPlayerWeaponSlot(client, 1)) == 0)
	{
		EquipWeaponSlot(client, 1);
		buttons |= IN_RELOAD;
	}
	else
	{
		EquipWeaponSlot(client, 0);
	}
}

public Action:ResetAttackTimer(Handle timer)
{
	AttackTimer = INVALID_HANDLE;
}

public Action:ResetSnipeTimer(Handle timer)
{
	SnipeTimer = INVALID_HANDLE;
}

public Action:ResetRepeartAttackTimer(Handle timer)
{
	RepeartAttackTimer = INVALID_HANDLE;
}

bool IsValidClient( client ) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

public Action:TellYourInAFKMODE(Handle timer,any:userid)
{
	for(int client=1;client<=MaxClients;client++)
	{
		if(g_bAfkbot[client] && IsValidClient(client) && !IsFakeClient(client))
		{
			PrintToChat(client,"[AFK Bot] You are set AFK.\nType '!afk' in chat to get out of it.");
			PrintCenterText(client, "You are being controlled by a bot. Type !afk to chat for exit.");
		}
	}
}

stock TFTeam GetEnemyTeam(int ent)
{
	TFTeam enemy_team = TF2_GetClientTeam(ent);
	switch(enemy_team)
	{
		case TFTeam_Red:  enemy_team = TFTeam_Blue;
		case TFTeam_Blue: enemy_team = TFTeam_Red;
	}
	
	return enemy_team;
}

public Action:EndSlowThink(Handle timer, client)
{
	if(IsValidClient(client))
	{
		g_bIsSlowThink[client] = true;
	}
}

stock int TF2_GetObject(int client, TFObjectType type, TFObjectMode mode)
{
	int iObject = INVALID_ENT_REFERENCE;
	while ((iObject = FindEntityByClassname(iObject, "obj_*")) != -1)
	{
		TFObjectType iObjType = TF2_GetObjectType(iObject);
		TFObjectMode iObjMode = TF2_GetObjectMode(iObject);
		
		if(GetEntPropEnt(iObject, Prop_Send, "m_hBuilder") == client && iObjType == type && iObjMode == mode 
		&& !GetEntProp(iObject, Prop_Send, "m_bPlacing")
		&& !GetEntProp(iObject, Prop_Send, "m_bDisposableBuilding"))
		{			
			return iObject;
		}
	}
	
	return iObject;
}

stock int TF2_GetTeamObject(int client, TFObjectType type, TFObjectMode mode)
{
	int iObject = INVALID_ENT_REFERENCE;
	while ((iObject = FindEntityByClassname(iObject, "obj_*")) != -1)
	{
		TFObjectType iObjType = TF2_GetObjectType(iObject);
		TFObjectMode iObjMode = TF2_GetObjectMode(iObject);
		
		if(GetEntPropEnt(iObject, Prop_Send, "m_iTeamNum") == GetClientTeam(client) && iObjType == type && iObjMode == mode 
		&& !GetEntProp(iObject, Prop_Send, "m_bPlacing")
		&& !GetEntProp(iObject, Prop_Send, "m_bDisposableBuilding"))
		{			
			return iObject;
		}
	}
	
	return iObject;
}

stock int GetEntityOwner(int entity)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
}

stock int GetObjTeam(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

stock int GetObjHealth(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock int GetAmmo(int client)
{
	return FindSendPropInfo("CTFPlayer", "m_iAmmo");
}

stock int GetMetal(int client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
}

int GetClientEntityCount(int client, const char[] search)
{
    if (!IsValidClient(client))
    {
        return 0;
    }
    
    int count;
    char classname[64];
    for (int i = MaxClients; i < GetMaxEntities(); i++)
    {
        if (!IsValidEntity(i))
        {
            continue;
        }
        
        GetEntityClassname(i, classname, sizeof(classname));
        if (!StrEqual(search, classname))
        {
            continue;
        }
        
        int owner = GetEntPropEnt(i, Prop_Data, "m_hOwnerEntity");
        if (owner != client)
        {
            continue;
        }
        
        count++;
    }
    
    return count;
}

stock Client_GetClosest(float vecOrigin_center[3], const client)
{
	float vecOrigin_edict[3];
	float vecOrigin_edict2[3];
	float aimpos[3];
	float client_origin[3];
	float distance = -1.0;
	int TeamMateBaseHealth = 99999;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict2);
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", client_origin);
		float PlayerDistance;
		GetClientEyePosition(i, vecOrigin_edict);
		GetAimOrigin(client, aimpos);
		PlayerDistance = GetVectorDistance(client_origin, vecOrigin_edict2);
		new TFClassType:medic = TF2_GetPlayerClass(client);
		int CurrentHealth = GetEntProp(i, Prop_Send, "m_iHealth");
		int MaxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
		if(GetClientTeam(i) == GetClientTeam(client) && medic == TFClass_Medic || !g_bSpyAlert[i] && GetClientTeam(i) != GetClientTeam(client) && TF2_IsPlayerInCondition(i, TFCond_Disguised) && !TF2_IsPlayerInCondition(i, TFCond_Cloaked))
		{
			new TFClassType:class = TF2_GetPlayerClass(i);
			// Cloaked and Disguised players should be now undetectable(3.2)
			if(CurrentHealth >= MaxHealth && class == TFClass_Medic || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || GetHealth(i) >= 125.0 && TF2_IsPlayerInCondition(i, TFCond_Disguised) || class == TFClass_Engineer && IsWeaponSlotActive(i,2) && GetHealth(i) >= 125.0 || GetHealth(i) >= 125.0 && TF2_IsPlayerInCondition(i, TFCond_Zoomed) || TF2_IsPlayerInCondition(i, TFCond_Teleporting) || TF2_IsPlayerInCondition(i, TFCond_Disguising))
				continue;
			if((IsPointVisible(vecOrigin_center, vecOrigin_edict) && IsPointVisible2(vecOrigin_center, vecOrigin_edict)) || (IsPointVisible(vecOrigin_center, vecOrigin_edict2) && IsPointVisible2(vecOrigin_center, vecOrigin_edict2)))
			{
				float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				int iHealth = GetEntProp(i, Prop_Send, "m_iHealth");
				if(PlayerDistance < 1000.0 && TeamMateBaseHealth > CurrentHealth && g_bHealthIsLow[i])
				{
					TeamMateBaseHealth = iHealth;
					closestEdict = i;
				}
				else if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
		else if(medic == TFClass_Sniper && ClientViews(client, i) && IsPointVisible(vecOrigin_center, vecOrigin_edict) && IsPointVisible2(vecOrigin_center, vecOrigin_edict) && GetClientTeam(i) != GetClientTeam(client))
		{
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Cloaked) && (TF2_IsPlayerInCondition(i, TFCond_OnFire) || TF2_IsPlayerInCondition(i, TFCond_Bleeding) || TF2_IsPlayerInCondition(i, TFCond_Milked) || TF2_IsPlayerInCondition(i, TFCond_Jarated))) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Disguised)) || TF2_IsPlayerInCondition(i, TFCond_Taunting))
				continue;
			if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
			{
				if((IsPointVisible(vecOrigin_center, vecOrigin_edict) && IsPointVisible2(vecOrigin_center, vecOrigin_edict)) || (IsPointVisible(vecOrigin_center, vecOrigin_edict2) && IsPointVisible2(vecOrigin_center, vecOrigin_edict2)))
				{
					if(PlayerDistance < 1000.0)
					{
						float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
						if((edict_distance < distance) || (distance == -1.0))
						{
							distance = edict_distance;
							closestEdict = i;
						}
					}
					else
					{
						new TFClassType:targetclass = TF2_GetPlayerClass(i);
						if(targetclass == TFClass_Sniper)
						{
							float NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							float edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
						else if(targetclass == TFClass_Medic && TF_GetUberLevel(client) > 50.0)
						{
							float NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							float edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
						else if(targetclass == TFClass_Spy)
						{
							float NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							float edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
						else if(targetclass == TFClass_Medic && TF_GetUberLevel(client) < 50.0)
						{
							float NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							float edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
						else
						{
							float NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							float edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
					}
				}
			}
			else
			{
				float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
		else if(GetClientTeam(i) != GetClientTeam(client) && ClientViews(client, i))
		{	
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Cloaked) && (TF2_IsPlayerInCondition(i, TFCond_OnFire) || TF2_IsPlayerInCondition(i, TFCond_Bleeding) || TF2_IsPlayerInCondition(i, TFCond_Milked) || TF2_IsPlayerInCondition(i, TFCond_Jarated))) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Disguised)) || TF2_IsPlayerInCondition(i, TFCond_Taunting))
				continue;
			if((IsPointVisible(vecOrigin_center, vecOrigin_edict) && IsPointVisible2(vecOrigin_center, vecOrigin_edict)) || (IsPointVisible(vecOrigin_center, vecOrigin_edict2) && IsPointVisible2(vecOrigin_center, vecOrigin_edict2)))
			{
				float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
	}
	return closestEdict;
}

stock TF2_GetNumHealers(client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

stock GetNearestClient(float vecOrigin_center[3], const client)
{    
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		GetClientEyePosition(i, vecOrigin_edict);
		if(IsValidClient(i))
		{	
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || TF2_IsPlayerInCondition(i, TFCond_Cloaked))
				continue;
			if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			{
				float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
	}
	return closestEdict;
}

public int GetNearestEnemiens(int client)
{
	float clientOrigin[3];
	float enemyOrigin[3];
	float distance = -1.0;
	int nearestEnemy = -1;
	//for(int i = 0; i <= MaxClients; i++)
	for(int i = 1; i <= MaxClients; i++) // possible fix?
	{
		if(IsPlayerAlive(i) && IsValidClient(i))
		{
			if(GetClientTeam(client) != GetClientTeam(i))
			{
				GetClientEyePosition(i, enemyOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				float edict_distance = GetVectorDistance(clientOrigin, enemyOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEnemy = i;
				}
			}
		}
	}
	return nearestEnemy;
}

public int FindNearestAmmo(int client)
{
	char ClassName[32];
	float clientOrigin[3];
	float entityOrigin[3];
	float distance = -1.0;
	int nearestEntity = -1;
	for(int x = 0; x <= GetMaxEntities(); x++)
	{
		if(IsValidEdict(x) && IsValidEntity(x))
		{
			GetEdictClassname(x, ClassName, 32);
			
			if(!HasEntProp(x, Prop_Send, "m_fEffects"))
				continue;
			
			if(GetEntProp(x, Prop_Send, "m_fEffects") != 0)
				continue;
			
			if(StrContains(ClassName, "item_ammo", false) != -1 || StrContains(ClassName, "tf_ammo_pack", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1)
			{
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEntity = x;
				}
			}
		}
	}
	return nearestEntity;
}

public int FindNearestHealth(int client)
{
	char ClassName[32];
	float clientOrigin[3];
	float entityOrigin[3];
	float distance = -1.0;
	int nearestEntity = -1;
	for(int x = 0; x <= GetMaxEntities(); x++)
	{
		if(IsValidEdict(x) && IsValidEntity(x))
		{
			GetEdictClassname(x, ClassName, 32);
			
			if(!HasEntProp(x, Prop_Send, "m_fEffects"))
				continue;
			
			if(GetEntProp(x, Prop_Send, "m_fEffects") != 0)
				continue;
			
			if(StrContains(ClassName, "item_health", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1)
			{
				GetEntPropVector(x, Prop_Data, "m_vecOrigin", entityOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEntity = x;
				}
			}
		}
	}
	return nearestEntity;
}

public int GetNearestEntity(int client, char[] classname)
{    
	float clientOrigin[3];
	float entityOrigin[3];
	float distance = -1.0;
	int nearestEntity = -1;
	int entity = -1;
	while((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
			GetClientAbsOrigin(client, clientOrigin);
			
			float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				nearestEntity = entity;
			}
		}
	}
	return nearestEntity;
}

stock FindEntityByTargetname(const char[] targetname, const char[] classname)
{
  char namebuf[32];
  int index = -1;
  namebuf[0] = '\0';
 
  while(strcmp(namebuf, targetname) != 0
    && (index = FindEntityByClassname(index, classname)) != -1)
    GetEntPropString(index, Prop_Data, "m_iName", namebuf, sizeof(namebuf));
 
  return(index);
}

stock void TF2_LookAtPos(int client, float flGoal[3], float flAimSpeed = 0.05)
{
	float flPos[3];
	GetClientEyePosition(client, flPos);

	float flAng[3];
	GetClientEyeAngles(client, flAng);
	
	// get normalised direction from target to client
	float desired_dir[3];
	MakeVectorFromPoints(flPos, flGoal, desired_dir);
	GetVectorAngles(desired_dir, desired_dir);
	
	// ease the current direction to the target direction
	flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
	flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;

	if(g_flAutoLookTimer[client] < GetGameTime())
	{
		TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
		
		g_flAutoLookTimer[client] = GetGameTime() + GetConVarFloat(AFKBOT_AimTimer);
	}
}

float g_flFindPathTimer[MAXPLAYERS + 1];
stock void TF2_FindPath(int client, float flTargetVector[3])
{
	if(g_flFindPathTimer[client] < GetGameTime())
	{
		if (!(PF_Exists(client)))
		{
			PF_Create(client, 48.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
		}
		
		if(!PF_IsPathToVectorPossible(client, flTargetVector))
			return;
		
		PF_SetGoalVector(client, flTargetVector);
		
		if(g_bPathFinding[client])
		{
			PF_StartPathing(client);
		}
		else
		{
			PF_StopPathing(client);
		}
		
		PF_EnableCallback(client, PFCB_Approach, Approach);
		
		g_flFindPathTimer[client] = GetGameTime() + GetConVarFloat(AFKBOT_PathTimer);
	}
}

stock void TF2_FindSniperSpot(int client)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	float clientEyes[3];
	int Ent = Client_GetClosest(clientEyes, client);
	GetClientEyePosition(client, clientEyes);
	float bestsniperspot[3];
	if(g_flSniperChangeSpotTimer[client] < GetGameTime())
	{
		if(Ent == -1)
		{
			g_bPickRandomSniperSpot[client] = true;
		}
		g_flSniperChangeSpotTimer[client] = GetGameTime() + GetRandomFloat(10.0, 20.0);
	}
	if(TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		if(StrContains(currentMap, "koth_" , false) != -1)
		{
			int capturepoint;
			if((capturepoint = FindEntityByClassname(capturepoint, "team_control_point")) != INVALID_ENT_REFERENCE)
			{
				float capturepointpos[3];
				float capturepointpos2[3];
				GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", capturepointpos);
				GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", capturepointpos2);
				
				capturepointpos[2] += GetRandomFloat(200.0, 400.0);
				
				if((GetVectorDistance(clientEyes, g_flSniperSpotPos[client]) > 100.0))
				{
					g_bPathFinding[client] = true;
				}
				else
				{
					g_bPathFinding[client] = false;
				}
				
				if(g_bPickRandomSniperSpot[client])
				{
					g_flRandomSniperSpotPos[client][0] = capturepointpos[0] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][1] = capturepointpos[1] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][2] = capturepointpos2[2] + 50.0;
					
					bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
					bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
					bestsniperspot[2] = clientEyes[2];
					
					NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
					if(area != NavArea_Null)
					{
						if(IsPointVisible(bestsniperspot, capturepointpos) && GetVectorDistance(bestsniperspot, capturepointpos2) > 600.0 && GetVectorDistance(bestsniperspot, g_flSpawnLocation[client]) < 3000.0)
						{
							area.GetRandomPoint(g_flSniperSpotPos[client]);
							
							g_bPickRandomSniperSpot[client] = false;
						}
						else
						{
							g_bPickRandomSniperSpot[client] = false;
						}
					}
					else
					{
						g_bPickRandomSniperSpot[client] = true;
					}
				}
			}
		}
	}
}

bool g_bLookAround[MAXPLAYERS+1];
stock void TF2_LookAround(int client)
{
	int Ent = Client_GetClosest(g_flClientEyePos[client], client);
	if(Ent == -1 && !g_bMakeStickyTrap[client])
	{
		float RandomizeAim = GetRandomFloat(GetConVarFloat(AFKBOT_MinAimSpeed), GetConVarFloat(AFKBOT_MaxAimSpeed));
		if(TF2_GetPlayerClass(client) == TFClass_Engineer && GetVectorDistance(g_flClientEyePos[client], g_bSentryBuildAngle[client]) < 500.0 && !g_bSentryBuilded[client] && g_bBuildSentry[client])
		{
			TF2_LookAtPos(client, g_bSentryBuildAngle[client], RandomizeAim);
		}
		else
		{
			for (int search = 1; search <= MaxClients; search++)
			{
				if (IsClientInGame(search) && IsPlayerAlive(search) && search != client)
				{
					float playerOrigin[3];
					GetClientEyePosition(search, playerOrigin);
					
					if(IsPointVisible(g_flClientEyePos[client], playerOrigin) && ClientViews(client, search) && ClientViews(search, client) && IsClientAimingTowardMe(client, search) && GetVectorDistance(g_flClientEyePos[client], playerOrigin) < 1000.0)
					{
						g_bLookAround[client] = false;
						
						if(GetClientButtons(search) == IN_ATTACK)
						{
							if(g_flVoiceNoTimer[client] < GetGameTime())
							{
								FakeClientCommandThrottled(client, "voicemenu 0 7");
								
								g_flVoiceNoTimer[client] = GetGameTime() + GetRandomFloat(10.0, 20.0);
							}
							
						}
						else
						{
							TF2_LookAtPos(client, playerOrigin, RandomizeAim);
						}
					}
					else
					{
						g_bLookAround[client] = true;
					}
				}
			}
		}
		
		if(g_bLookAround[client])
		{
			float BestLookPos[3];
			float SelectRandomNav[3];
			float SelectedLookPos[3];
			
			GetClientEyePosition(client, BestLookPos);
			
			BestLookPos[0] += GetRandomFloat(-1000.0, 1000.0);
			BestLookPos[1] += GetRandomFloat(-1000.0, 1000.0);
			
			NavArea area = TheNavMesh.GetNearestNavArea_Vec(BestLookPos, true, 5000.0, false, false, GetClientTeam(client));
			if(area != NavArea_Null)
			{
				area.GetRandomPoint(SelectRandomNav);
			}
			
			if(IsPointVisible(g_flClientEyePos[client], SelectRandomNav) && GetVectorDistance(g_flClientEyePos[client], SelectRandomNav) > 500.0)
			{
				SelectedLookPos[0] = SelectRandomNav[0];
				SelectedLookPos[1] = SelectRandomNav[1];
				SelectedLookPos[2] = SelectRandomNav[2] + GetRandomFloat(GetConVarFloat(AFKBOT_LookAroundMaxDown), GetConVarFloat(AFKBOT_LookAroundMaxUp));
			}
			
			if(IsPointVisible(g_flClientEyePos[client], SelectedLookPos))
			{
				if(g_flLookTimer[client] < GetGameTime())
				{
					g_flLookPos[client][0] = SelectedLookPos[0];
					g_flLookPos[client][1] = SelectedLookPos[1];
					g_flLookPos[client][2] = SelectedLookPos[2];
					
					g_flLookTimer[client] = GetGameTime() + GetRandomFloat(1.0, 2.5);
				}
			}
			
			TF2_LookAtPos(client, g_flLookPos[client], RandomizeAim);
		}
	}
}

stock void TF2_LookAroundForSnipe(int client)
{
	int Ent = Client_GetClosest(g_flClientEyePos[client], client);
	if(Ent == -1 && TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		float RandomizeAimWhenZoomed = GetRandomFloat(GetConVarFloat(AFKBOT_MinAimSpeedWhenZoomed), GetConVarFloat(AFKBOT_MaxAimSpeedWhenZoomed));
		
		float BestLookPos[3];
		float SelectRandomNav[3];
		float SelectedLookPos[3];
		
		GetClientEyePosition(client, BestLookPos);
		
		BestLookPos[0] += GetRandomFloat(-2500.0, 2500.0);
		BestLookPos[1] += GetRandomFloat(-2500.0, 2500.0);
		
		NavArea area = TheNavMesh.GetNearestNavArea_Vec(BestLookPos, true, 10000.0, false, false, GetClientTeam(client));
		if(area != NavArea_Null)
		{
			area.GetRandomPoint(SelectRandomNav);
		}
		
		if(IsPointVisible(g_flClientEyePos[client], SelectRandomNav) && GetVectorDistance(g_flClientEyePos[client], SelectRandomNav) > 1000.0)
		{
			SelectedLookPos[0] = SelectRandomNav[0];
			SelectedLookPos[1] = SelectRandomNav[1];
			SelectedLookPos[2] = SelectRandomNav[2] + GetRandomFloat(GetConVarFloat(AFKBOT_LookAroundMaxDown), GetConVarFloat(AFKBOT_LookAroundMaxUp));
		}
		
		if(IsPointVisible(g_flClientEyePos[client], SelectedLookPos))
		{
			if(g_flLookTimer[client] < GetGameTime())
			{
				g_flLookPos[client][0] = SelectedLookPos[0];
				g_flLookPos[client][1] = SelectedLookPos[1];
				g_flLookPos[client][2] = SelectedLookPos[2];
				
				g_flLookTimer[client] = GetGameTime() + GetRandomFloat(2.0, 4.0);
			}
		}
		
		TF2_LookAtPos(client, g_flLookPos[client], RandomizeAimWhenZoomed);
	}
}

stock bool IsClientAimingTowardMe(int client, int target)
{
	float flBotAng[3], flTargetAng[3];
	GetClientEyeAngles(client, flBotAng);
	GetClientEyeAngles(target, flTargetAng);
	int iAngleDiff = AngleDifference(flBotAng[1], flTargetAng[1]);
	
	if(iAngleDiff > 10 || iAngleDiff < -10)
		return true;
	
	return false;
}

stock int AngleDifference(float angle1, float angle2)
{
	int diff = RoundToNearest((angle2 - angle1 + 180)) % 360 - 180;
	return diff < -180 ? diff + 360 : diff;
}

stock float AngleNormalize(float angle)
{
	angle = fmodf(angle, 360.0);
	if (angle > 180) 
	{
		angle -= 360;
	}
	if (angle < -180)
	{
		angle += 360;
	}
	
	return angle;
}

stock float fmodf(float number, float denom)
{
	return number - RoundToFloor(number / denom) * denom;
}

stock void TF2_MoveTo(int client, float flGoal[3], float fVel[3], float fAng[3])
{
    float flPos[3];
    GetClientAbsOrigin(client, flPos);

    float newmove[3];
    SubtractVectors(flGoal, flPos, newmove);
    
    newmove[1] = -newmove[1];
    
    float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
    float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
    fVel[0] = cos * newmove[0] - sin * newmove[1];
    fVel[1] = sin * newmove[0] + cos * newmove[1];
    
    NormalizeVector(fVel, fVel);
    ScaleVector(fVel, 450.0);
}

stock void TF2_MoveOut(int client, float flGoal[3], float fVel[3], float fAng[3])
{
    float flPos[3];
    GetClientAbsOrigin(client, flPos);

    float newmove[3];
    SubtractVectors(flGoal, flPos, newmove);
    
    float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
    float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
    fVel[0] = cos * newmove[0] - sin * newmove[1];
    fVel[1] = sin * newmove[0] + cos * newmove[1];
    
    NormalizeVector(fVel, fVel);
    ScaleVector(fVel, 450.0);
}

public void Approach(int bot_entidx, const float dst[3])
{
    g_flGoal[bot_entidx][0] = dst[0];
    g_flGoal[bot_entidx][1] = dst[1];
    g_flGoal[bot_entidx][2] = dst[2];
}

stock void EyeVectors(int client, float fw[3] = NULL_VECTOR, float right[3] = NULL_VECTOR, float up[3] = NULL_VECTOR)
{
	GetAngleVectors(GetEyeAngles(client), fw, right, up);
}

stock float[] GetAbsOrigin(int client)
{
	if(client <= 0)
		return NULL_VECTOR;

	float v[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", v);
	return v;
}

stock float[] GetEyeAngles(int client)
{
	if(client <= 0)
		return NULL_VECTOR;

	float v[3];
	GetClientEyeAngles(client, v);
	return v;
}

stock void EquipWeaponSlot(int client, int slot)
{
	int iWeapon = GetPlayerWeaponSlot(client, slot);
	if(IsValidEntity(iWeapon))
		EquipWeapon(client, iWeapon);
}

stock void EquipWeapon(int client, int weapon)
{
	char class[80];
	GetEntityClassname(weapon, class, sizeof(class));

	Format(class, sizeof(class), "use %s", class);

	FakeClientCommandThrottled(client, class);
//	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
}

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}

float g_flNextCommand2[MAXPLAYERS + 1];
stock bool ClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand2[client] > GetGameTime())
		return false;
	
	ClientCommand(client, command);
	
	g_flNextCommand2[client] = GetGameTime() + 0.4;
	
	return true;
}

stock bool IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock int GetTeamNumber(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

stock ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

//Fixed the spamming error message about chargelevel(3.7)
stock float TF_GetUberLevel(client)
{
	int index = GetPlayerWeaponSlot(client, 1);
	if(IsValidEntity(index)
	&& (GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==29
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==211
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==35
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==411
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==663
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==796
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==805
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==885
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==894
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==903
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==912
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==961
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==970
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==998))
		return GetEntPropFloat(index, Prop_Send, "m_flChargeLevel")*100.0;
	else
		return 0.0;
}

stock TF_IsUberCharge(client)
{
	int index = GetPlayerWeaponSlot(client, 1);
	if(IsValidEntity(index)
	&& (GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==29
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==211
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==35
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==411
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==663
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==796
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==805
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==885
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==894
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==903
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==912
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==961
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==970
	|| GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex")==998))
		return GetEntProp(index, Prop_Send, "m_bChargeRelease", 1);
	else
		return 0;
}

stock GetAimOrigin(client, float hOrigin[3]) 
{
	float vAngles[3];
	float fOrigin[3];
	GetClientEyePosition(client,fOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace)) 
	{
		TR_GetEndPosition(hOrigin, trace);
		CloseHandle(trace);
		return 1;
	}

	CloseHandle(trace);
	return 0;
}

stock bool ClientViews(Viewer, Target, float fMaxDistance=0.0, float fThreshold=0.70) // Stock Link : https://forums.alliedmods.net/showpost.php?p=973411&postcount=4 | By Damizean
{
    // Retrieve view and target eyes position
    float fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    float fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    float fViewDir[3];
    float fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
    float fTargetDir[3];
    float fDistance[3];
	
    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    
    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0]-fViewPos[0];
    fDistance[1] = fTargetPos[1]-fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
            return false;
    }
    
    // Check dot product. If it's negative, that means the viewer is facing
    // backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    
    // Now check if there are no obstacles in between through raycasting
    Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
    CloseHandle(hTrace);
    
    // Done, it's visible
    return true;
}

stock bool ClientViewsOrigin(Viewer, float fTargetPos[3], float fMaxDistance=0.0, float fThreshold=0.70) // Stock Link : https://forums.alliedmods.net/showpost.php?p=973411&postcount=4 | By Damizean
{
    // Retrieve view and target eyes position
    float fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    float fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    float fViewDir[3];
    float fTargetDir[3];
    float fDistance[3];
	
    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    
    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0]-fViewPos[0];
    fDistance[1] = fTargetPos[1]-fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
            return false;
    }
    
    // Check dot product. If it's negative, that means the viewer is facing
    // backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    
    // Now check if there are no obstacles in between through raycasting
    Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
    CloseHandle(hTrace);
    
    // Done, it's visible
    return true;
}

public bool ClientViewsFilter(Entity, Mask, any:Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) return false;
    return true;
}

public bool TraceEntityFilterPlayer(entity, contentsMask) 
{
    return entity > MaxClients;
}

stock bool IsPointVisible(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

stock bool IsPointVisible2(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

public bool TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}

stock bool IsPointVisibleTank(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.99;
}

stock bool IsPointVisibleTank2(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.99;
}

public bool TraceEntityFilterStuffTank(entity, mask)
{
	int maxentities = GetMaxEntities();
	return entity > maxentities;
}

public bool Filter(entity,mask)
{
	return !(IsValidClient(entity));
}
  