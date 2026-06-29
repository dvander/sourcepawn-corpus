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

new g_bPathFinding[MAXPLAYERS+1];

float g_flGoal[MAXPLAYERS + 1][3];
float g_flClientEyePos[MAXPLAYERS + 1][3];
float g_flClientPos[MAXPLAYERS + 1][3];
float g_flLookPos[MAXPLAYERS + 1][3];

float g_flDemoAttackTimer[MAXPLAYERS + 1];

float g_flRedFlagCapPoint[3];
float g_flBluFlagCapPoint[3];

bool g_bBeFriend[MAXPLAYERS+1];

new g_bMedicAllHaveTasks[MAXPLAYERS+1];

new g_bFindNewDefendSpot[MAXPLAYERS+1];

float g_flDefendPosChangeTimer[MAXPLAYERS + 1];

float g_flRandomDefendArea[MAXPLAYERS + 1][3];
float g_flSelectedDefendArea[MAXPLAYERS + 1][3];

float g_flPyroAirblastTimer[MAXPLAYERS + 1];

float g_flSniperBowTimer[MAXPLAYERS + 1];

float g_flHeavySpinMinigunTimer[MAXPLAYERS + 1];

new g_bAfkbot[MAXPLAYERS+1];
float g_flLookAtLastKnownEnemyPos[MAXPLAYERS + 1][3];
float g_flSpawnLocation[MAXPLAYERS + 1][3];
float g_flLastDiedArea[MAXPLAYERS + 1][3];
new g_bIsSlowThink[MAXPLAYERS+1];
new g_bSpyAlert[MAXPLAYERS+1];
new g_bISeeSpy[MAXPLAYERS+1];
new g_bFindLastDiedArea[MAXPLAYERS+1];
new g_bUseTeleporter[MAXPLAYERS + 1];
new Handle:AttackTimer;
new Handle:SnipeTimer;
new Handle:RepeartAttackTimer;

bool g_bHideFromTheTarget[MAXPLAYERS+1];
bool g_bFindNewHidingSpot[MAXPLAYERS+1];
float g_flHidingTime[MAXPLAYERS + 1];
float g_flBestHidingOrigin[MAXPLAYERS + 1][3];
float g_flHidingTargetOrigin[MAXPLAYERS + 1][3];

new g_bFindNewDefendPayloadSpot[MAXPLAYERS+1];

float g_flPayloadDefendPosChangeTimer[MAXPLAYERS + 1];

float g_flRandomPayloadDefendArea[MAXPLAYERS + 1][3];
float g_flSelectedPayloadDefendArea[MAXPLAYERS + 1][3];

bool g_bJump[MAXPLAYERS+1];
bool g_bCrouch[MAXPLAYERS+1];

bool g_bEngineerTasksFinished[MAXPLAYERS+1];

float g_flJumpTimer[MAXPLAYERS + 1];

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

bool g_bHuntEnemiens[MAXPLAYERS+1];

new g_bPickUnUsedSentrySpot[MAXPLAYERS + 1];

float g_bSentryBuildPos[MAXPLAYERS + 1][3];
float g_bSentryBuildAngle[MAXPLAYERS + 1][3];

new g_bPickRandomSniperSpot[MAXPLAYERS+1];
new g_bCamping[MAXPLAYERS+1];

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

float g_flLastKnownSentryArea[MAXPLAYERS + 1][3];

float g_flLookTimer[MAXPLAYERS + 1];

new g_bSentryBuilded[MAXPLAYERS + 1];
new g_bSentryIsMaxLevel[MAXPLAYERS + 1];
new g_bSentryHealthIsFull[MAXPLAYERS + 1];
new g_bCanBuildSentryGun[MAXPLAYERS + 1];
new g_bDispenserBuilded[MAXPLAYERS + 1];
new g_bDispenserIsMaxLevel[MAXPLAYERS + 1];
new g_bDispenserHealthIsFull[MAXPLAYERS + 1];
new g_bCanBuildDispenser[MAXPLAYERS + 1];
new g_bCanBuildTeleporter[MAXPLAYERS + 1];
new g_bTeleporterEnterBuilded[MAXPLAYERS + 1];
new g_bTeleporterEnterHealthIsFull[MAXPLAYERS + 1];
new g_bTeleporterEnterIsMaxLevel[MAXPLAYERS + 1];
new g_bTeleporterExitHealthIsFull[MAXPLAYERS + 1];
new g_bTeleporterExitIsMaxLevel[MAXPLAYERS + 1];
new g_bTeleporterExitBuilded[MAXPLAYERS + 1];

new g_bBotIsDied[MAXPLAYERS + 1];

new g_bHealthIsLow[MAXPLAYERS + 1];
new g_bAmmoIsLow[MAXPLAYERS + 1];
new g_bMoveSentry[MAXPLAYERS + 1];
new g_bSapBuildings[MAXPLAYERS + 1];
new g_bFindLastKnownSentries[MAXPLAYERS + 1];
new g_bSpyHaveAnyTask[MAXPLAYERS + 1];
new g_bBackStabVictim[MAXPLAYERS + 1];
new g_bMakeStickyTrap[MAXPLAYERS + 1];
int g_iPipeCount[MAXPLAYERS + 1];
float g_flPipeOrigin[MAXPLAYERS + 1][3];

float g_flVoiceHelpTimer[MAXPLAYERS + 1];

float g_flVoiceNoTimer[MAXPLAYERS + 1];

float g_flAutoLookTimer[MAXPLAYERS + 1];

bool PathAim[MAXPLAYERS+1];

float EnemyAlertTimer[MAXPLAYERS + 1];

int g_bIsSetupTime = 0;

char g_PlayerDefalutName[MAXPLAYERS+1][MAX_NAME_LENGTH];
char g_PlayerNameWithTag[MAXPLAYERS+1][MAX_NAME_LENGTH];

Float:moveForward(Float:vel[3],Float:MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
}

Float:moveBackwards(Float:vel[3],Float:MaxSpeed)
{
	vel[0] = -MaxSpeed;
	return vel;
}

Float:moveRight(Float:vel[3],Float:MaxSpeed)
{
	vel[1] = MaxSpeed;
	return vel;
}

Float:moveLeft(Float:vel[3],Float:MaxSpeed)
{
	vel[1] = -MaxSpeed;
	return vel;
}

#define PLUGIN_VERSION  "1.2"
#define PLUGIN_CONFIG "cfg/sourcemod/plugin.afkbot.cfg"

public Plugin:myinfo = 
{
	name = "[TF2] AFK Bot",
	author = "EfeDursun125",
	description = "AI for afk players",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

new Handle:AFKBOT_MaxIdleTime;
new Handle:AFKBOT_FindLastDiedAreaChance;
new Handle:AFKBOT_MinAimSpeed;
new Handle:AFKBOT_MaxAimSpeed;
new Handle:AFKBOT_LookAroundMaxDown;
new Handle:AFKBOT_LookAroundMaxUp;
new Handle:AFKBOT_MinAimSpeedWhenZoomed;
new Handle:AFKBOT_MaxAimSpeedWhenZoomed;
new Handle:AFKBOT_PathTimer;
new Handle:AFKBOT_AimTimer;
new Handle:AFKBOT_AFKLimit;
new Handle:AFKBOT_KickAFKPlayers;

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
	HookEvent("teamplay_round_start", SetupStarted);
	HookEvent("teamplay_setup_finished", RoundStarted);
	
	CreateConVar("sm_afk_bot_version", PLUGIN_VERSION, "AFK-BOT Plugin Version", FCVAR_NONE);
	AFKBOT_MaxIdleTime = CreateConVar("sm_afk_bot_max_idle_time", "60.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_FindLastDiedAreaChance = CreateConVar("sm_afk_bot_find_last_died_area_chance", "50.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_MinAimSpeed = CreateConVar("sm_afk_bot_min_aim_speed", "0.075", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_MaxAimSpeed = CreateConVar("sm_afk_bot_max_aim_speed", "0.150", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_LookAroundMaxDown = CreateConVar("sm_afk_bot_look_around_max_down", "50.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_LookAroundMaxUp = CreateConVar("sm_afk_bot_look_around_max_up", "75.0", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_MinAimSpeedWhenZoomed = CreateConVar("sm_afk_bot_min_aim_speed_when_zoomed", "0.175", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_MaxAimSpeedWhenZoomed = CreateConVar("sm_afk_bot_max_aim_speed_when_zoomed", "0.225", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_PathTimer = CreateConVar("sm_afk_bot_path_timer", "1.1", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_AimTimer = CreateConVar("sm_afk_bot_aim_timer", "0.014", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_AFKLimit = CreateConVar("sm_afk_bot_limit", "8", "", FCVAR_NONE, true, 0.0, false, _);
	AFKBOT_KickAFKPlayers = CreateConVar("sm_afk_bot_kick_afk_players_if_afk_limit_is_reached", "0", "", FCVAR_NONE, true, 0.0, false, _);
}

public OnMapStart()
{
	CreateTimer(5.0, TellYourInAFKMODE,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if(StrContains(currentMap, "ctf_" , false) != -1)
	{
		new tmflag;
		while((tmflag = FindEntityByClassname(tmflag, "item_teamflag")) != INVALID_ENT_REFERENCE)
		{
			new iTeamNumObj = GetEntProp(tmflag, Prop_Send, "m_iTeamNum");
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

public Action:InfoTimer(Handle:timer)
{
	PrintToChatAll("[AFK BOT] This server is using AFK BOT plugin type to chat !afk");
}

public OnClientPutInServer(client)
{
	g_bAfkbot[client] = false;
	g_flAutoLookTimer[client] = GetGameTime() + 1.0;
	g_bBeFriend[client] = false;
	GetClientName(client, g_PlayerDefalutName[client], 64);
	g_PlayerNameWithTag[client] = ("\"%s\" (AFK)", g_PlayerDefalutName[client]);
	SDKHook(client, SDKHook_OnTakeDamageAlive,    OnTakeDamageAlive);
}

public Action:Command_Afk(client, args)
{
	if(args != 0 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_afk <target> [0/1]");
		return Plugin_Handled;
	}

	if(args == 0) // For Pepole
	{
		if(!g_bAfkbot[client])
		{
			if(GetAFKCount() < GetConVarInt(AFKBOT_AFKLimit))
			{
				PrintToChat(client, "[SM] AfkBot enabled.");
				g_bAfkbot[client] = true;
				SetEntProp(client, Prop_Data, "m_bLagCompensation", false);
				SetEntProp(client, Prop_Data, "m_bPredictWeapons", false);
				SendConVarValue(client, FindConVar("sv_client_predict"), "0");
				if(IsValidClient(client))
				{
					TF2_RespawnPlayer(client);
				}
				g_bIsSlowThink[client] = true;
			}
			else if(GetAFKCount() >= GetConVarInt(AFKBOT_AFKLimit))
			{
				if(GetConVarInt(AFKBOT_KickAFKPlayers) == 0)
				{
					PrintToChat(client, "[SM] AFK Limit is %i", GetConVarInt(AFKBOT_AFKLimit));
					PrintCenterText(client, "Sorry, AFK Limit is reached!");
				}
				else if(GetConVarInt(AFKBOT_KickAFKPlayers) == 1)
				{
					PrintToChat(client, "[SM] AFK Limit is %i, Don't be afk!", GetConVarInt(AFKBOT_AFKLimit));
					PrintCenterText(client, "Sorry, AFK Limit is reached. If be afk, you will kicked from the server!");
				}
			}
		}
		else
		{
			PrintToChat(client, "[SM] AfkBot disabled.");
			PrintCenterText(client, "Your AfkBot is now Disabled");
			g_bAfkbot[client] = false;
			SendConVarValue(client, FindConVar("sv_client_predict"), "-1");
			SetEntProp(client, Prop_Data, "m_bLagCompensation", true);
			SetEntProp(client, Prop_Data, "m_bPredictWeapons", true);
		}
		return Plugin_Handled;
	}
	
	else if(args == 2)
	{
		decl String:arg1[PLATFORM_MAX_PATH];
		GetCmdArg(1, arg1, sizeof(arg1));
		decl String:arg2[8];
		GetCmdArg(2, arg2, sizeof(arg2));

		new value = StringToInt(arg2);
		if(value != 0 && value != 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_afk <target> [0/1]");
			return Plugin_Handled;
		}

		new String:target_name[MAX_TARGET_LENGTH];
		new target_list[MAXPLAYERS];
		new target_count;
		new bool:tn_is_ml;
		if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		for(new i=0; i<target_count; i++) if(IsValidClient(target_list[i]))
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
		new bot = CreateFakeClient("Bot");
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

public Action:Command_AfkOff(client, const String:command[], argc)
{
	new String:args[5];
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

public Action:RoundStarted(Handle: event , const String: name[] , bool: dontBroadcast)
{
	g_bIsSetupTime = 0;
}

public Action:SetupStarted(Handle: event , const String: name[] , bool: dontBroadcast)
{
	g_bIsSetupTime = 1;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(IsValidClient(client))
	{
		char playerName[64];
		GetClientName(client, playerName, 64);
		if(!IsFakeClient(client) && g_bAfkbot[client])
		{
			//SetClientName(client, g_PlayerNameWithTag[client]);
		}
		else if(!IsFakeClient(client) && !g_bAfkbot[client])
		{
			//SetClientName(client, g_PlayerDefalutName[client]);
		}
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
						if(GetAFKCount() < GetConVarInt(AFKBOT_AFKLimit))
						{
							if(GetTeamsCount(2) > GetTeamsCount(3))
							{
								ChangeClientTeam(client, 3);
							}
							else
							{
								ChangeClientTeam(client, 2);
							}
							g_bAfkbot[client] = true;
							SetEntProp(client, Prop_Data, "m_bLagCompensation", false);
							SetEntProp(client, Prop_Data, "m_bPredictWeapons", false);
							SendConVarValue(client, FindConVar("sv_client_predict"), "0");
						}
						else
						{
							if(GetConVarInt(AFKBOT_KickAFKPlayers) == 1)
							{
								KickClient(client, "AFK Limit is reached!, You were kicked for being AFK!");
							}
						}
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
				decl Float:clientEyes[3];
				GetClientEyePosition(client, clientEyes);
				GetClientEyePosition(client, g_flClientEyePos[client]);
				GetClientAbsOrigin(client, g_flClientPos[client]);
				new Ent = Client_GetClosest(clientEyes, client);
				new PrimID;
				new SecondID;
				new MeleeID;
				if(IsValidEntity(GetPlayerWeaponSlot(client, 0)))
				{
					PrimID = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iItemDefinitionIndex");
				}
				if(IsValidEntity(GetPlayerWeaponSlot(client, 1)))
				{
					SecondID = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex");
				}
				if(IsValidEntity(GetPlayerWeaponSlot(client, 2)))
				{
					MeleeID = GetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iItemDefinitionIndex");
				}
				new CurrentHealth = GetEntProp(client, Prop_Send, "m_iHealth");
				new MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				
				int sentry = TF2_GetObject(client, TFObject_Sentry, TFObjectMode_None);
				int dispenser = TF2_GetObject(client, TFObject_Dispenser, TFObjectMode_None);
				int teleporterenter = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Entrance);
				int teleporterexit = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Exit);
				
				if(class != TFClass_Engineer)
				{
					if(IsValidEdict(sentry) && IsValidEntity(sentry))
					{
						RemoveEdict(sentry);
					}
					
					if(IsValidEdict(dispenser) && IsValidEntity(dispenser))
					{
						RemoveEdict(dispenser);
					}
					
					if(IsValidEdict(teleporterenter) && IsValidEntity(teleporterenter))
					{
						RemoveEdict(teleporterenter);
					}
					
					if(IsValidEdict(teleporterexit) && IsValidEntity(teleporterexit))
					{
						RemoveEdict(teleporterexit);
					}
				}
				
				if(class == TFClass_Spy)
				{
					if(IsWeaponSlotActive(client, 2) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && GetEntProp(GetPlayerWeaponSlot(client, TFWeaponSlot_Melee), Prop_Send, "m_bReadyToBackstab"))
					{
						buttons |= IN_ATTACK;
					}
				}
				
				if(StrContains(currentMap, "pl_" , false) == -1)
				{
					g_bIsSetupTime = 0;
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
						new TeleIsSapped = GetEntProp(teammateteleporterenter, Prop_Send, "m_bHasSapper");
						if(TeleState != 1 && TeleState != 0 && TeleIsSapped == 0)
						{
							new Float:teammateteleorigin[3];
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
								new Float:clientOrigin[3];
								new Float:teammateteleorigin[3];
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
				
				if(StrContains(currentMap, "ctf_" , false) != -1 && StrContains(currentMap, "ctf_2fort" , false) == -1 && StrContains(currentMap, "ctf_turbine" , false) == -1)
				{
					new tmflag;
					while((tmflag = FindEntityByClassname(tmflag, "item_teamflag")) != INVALID_ENT_REFERENCE)
					{
						new iTeamNumObj = GetEntProp(tmflag, Prop_Send, "m_iTeamNum");
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
				
				if(bufferlength < 100.0 && !TF2_IsPlayerInCondition(client, TFCond_Zoomed) && !TF2_IsPlayerInCondition(client, TFCond_Taunting) && !g_bUseTeleporter[client] && !g_bHealthIsLow[client] && g_bPathFinding[client] && g_flJumpTimer[client] < GetGameTime())
				{
					NavArea jumparea = TheNavMesh.GetNearestNavArea_Vec(g_flClientPos[client], false, 250.0, false, false, GetClientTeam(client));
					if(jumparea != NavArea_Null)
					{
						if(!jumparea.HasAttributes(NAV_MESH_NO_JUMP))
						{
							if(g_flJumpTimer[client] < GetGameTime())
							{
								if(g_bIsSetupTime == 1 && StrContains(currentMap, "pl_" , false) != -1)
								{
									if(GetClientTeam(client) != 3)
									{
										g_bJump[client] = true;
									}
								}
								else
								{
									g_bJump[client] = true;
								}
								
								g_flJumpTimer[client] = GetGameTime() + 1.5;
								
								g_bHideFromTheTarget[client] = false;
							}
						}
					}
				}
				else if(!TF2_IsPlayerInCondition(client, TFCond_Zoomed) && !TF2_IsPlayerInCondition(client, TFCond_Taunting) && !g_bUseTeleporter[client] && g_flJumpTimer[client] < GetGameTime())
				{
					NavArea jumparea = TheNavMesh.GetNearestNavArea_Vec(g_flClientPos[client], false, 250.0, false, false, GetClientTeam(client));
					if(jumparea != NavArea_Null)
					{
						if(jumparea.HasAttributes(NAV_MESH_JUMP))
						{
							if(g_flJumpTimer[client] < GetGameTime())
							{
								g_bJump[client] = true;
								
								g_flJumpTimer[client] = GetGameTime() + 1.0;
							}
						}
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
				
				if(class == TFClass_Engineer)
				{
					if(g_bIdleTime[client])
					{
						if(GetMetal(client) < 200.0)
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
							if(GetMetal(client) < 100.0)
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
							if(GetMetal(client) < 25.0)
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
						if(GetMetal(client) < 130.0)
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
					if(TF2_GetPlayerClass(client) == TFClass_Spy)
					{
						g_bAmmoIsLow[client] = false;
					}
					else if(Ent != -1 && IsWeaponSlotActive(client, 2))
					{
						g_bAmmoIsLow[client] = true;
					}
					else
					{
						g_bAmmoIsLow[client] = false;
					}
				}
				
				if(Ent == -1)
				{
					if(class != TFClass_Engineer)
					{
						PrepareForBattle(client);
					}
				}
				
				if(class == TFClass_Spy && g_bHideFromTheTarget[client] && Ent != -1 && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && GetClientButtons(Ent) == IN_ATTACK)
				{
					buttons |= IN_ATTACK2;
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
					g_bFindLastKnownSentries[client] = false;
					g_bSpyHaveAnyTask[client] = false;
					g_bBackStabVictim[client] = false;
				}
				
				if(g_bFindLastKnownSentries[client])
				{
					int EnemyBuilding = GetNearestEntity(client, "obj_*");
					if(EnemyBuilding != -1)
					{
						if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) != GetTeamNumber(EnemyBuilding))
						{
							// Voiceline
						}
						else if(!IsValidEntity(EnemyBuilding) || GetClientTeam(client) == GetTeamNumber(EnemyBuilding))
						{
							TF2_FindPath(client, g_flLastKnownSentryArea[client]);
							
							if(PF_Exists(client) && IsPlayerAlive(client))
							{
								TF2_MoveTo(client, g_flGoal[client], vel, angles);
							}
						}
					}
					else
					{
						TF2_FindPath(client, g_flLastKnownSentryArea[client]);
						
						if(PF_Exists(client) && IsPlayerAlive(client))
						{
							TF2_MoveTo(client, g_flGoal[client], vel, angles);
						}
					}
					
					NavArea sentryarea = TheNavMesh.GetNearestNavArea_Vec(g_flLookAtLastKnownEnemyPos[client], true, 1000.0, false, false, GetClientTeam(client));
					if(sentryarea != NavArea_Null)
					{
						if(GetClientTeam(client) == 3)
						{
							if(!HasTFAttributes(sentryarea, RED_SENTRY) && !HasTFAttributes(sentryarea, BLUE_SPAWN_ROOM) && !HasTFAttributes(sentryarea, RED_SPAWN_ROOM))
							{
								sentryarea.GetRandomPoint(g_flLastKnownSentryArea[client]);
								
								g_bFindLastKnownSentries[client] = false;
							}
						}
						else
						{
							if(!HasTFAttributes(sentryarea, BLUE_SENTRY) && !HasTFAttributes(sentryarea, BLUE_SPAWN_ROOM) && !HasTFAttributes(sentryarea, RED_SPAWN_ROOM))
							{
								sentryarea.GetRandomPoint(g_flLastKnownSentryArea[client]);
								
								g_bFindLastKnownSentries[client] = false;
							}
						}
					}
				}
				else
				{
					NavArea sentryarea = TheNavMesh.GetNearestNavArea_Vec(g_flClientPos[client], true, 1000.0, false, false, GetClientTeam(client));
					if(sentryarea != NavArea_Null)
					{
						if(GetClientTeam(client) == 3)
						{
							if(HasTFAttributes(sentryarea, RED_SENTRY) && !HasTFAttributes(sentryarea, BLUE_SPAWN_ROOM) && !HasTFAttributes(sentryarea, RED_SPAWN_ROOM))
							{
								sentryarea.GetRandomPoint(g_flLastKnownSentryArea[client]);
								
								g_bFindLastKnownSentries[client] = true;
							}
						}
						else
						{
							if(HasTFAttributes(sentryarea, BLUE_SENTRY) && !HasTFAttributes(sentryarea, BLUE_SPAWN_ROOM) && !HasTFAttributes(sentryarea, RED_SPAWN_ROOM))
							{
								sentryarea.GetRandomPoint(g_flLastKnownSentryArea[client]);
								
								g_bFindLastKnownSentries[client] = true;
							}
						}
					}
				}
				
				if(class == TFClass_Spy && !TF2_HasTheFlag(client) && !g_bAmmoIsLow[client] && !g_bHealthIsLow[client] && g_bIsSetupTime == 0)
				{
					int EnemyBuilding = GetNearestEntity(client, "obj_*");
					if(EnemyBuilding != -1)
					{
						if(IsValidEntity(EnemyBuilding) && GetClientTeam(client) != GetTeamNumber(EnemyBuilding))
						{
							new Float:clientOrigin[3];
							new Float:enemysentryOrigin[3];
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
								new Float:clientOrigin[3];
								new Float:enemysentryOrigin[3];
								GetClientAbsOrigin(client, clientOrigin);
								GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
							
								clientOrigin[2] += 50.0;
							
								decl Float:camangle[3], Float:fEntityLocation[3];
								decl Float:vec[3],Float:angle[3];
								GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", fEntityLocation);
								GetEntPropVector(EnemyBuilding, Prop_Data, "m_angRotation", angle);
								fEntityLocation[2] += 35.0;
								MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
								GetVectorAngles(vec, camangle);
								camangle[0] *= -1.0;
								camangle[1] += 180.0;
								ClampAngle(camangle);
								
								new iBuildingIsSapped = GetEntProp(EnemyBuilding, Prop_Send, "m_bHasSapper");
								
								if(iBuildingIsSapped != 1)
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
					
					if(g_bBackStabVictim[client] && !g_bFindLastKnownSentries[client])
					{
						if(!g_bSapBuildings[client] && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && g_bIsSetupTime == 0)
						{
							for (new search = 1; search <= MaxClients; search++)
							{
								if (IsValidClient(search) && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
								{
									new Float:searchOrigin[3];
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
											for (new search2 = 1; search2 <= MaxClients; search2++)
											{
												if (IsValidClient(search2) && IsClientInGame(search2) && IsPlayerAlive(search2) && search2 != client && TF2_GetPlayerClass(search2) == TFClass_Sniper && (GetClientTeam(client) != GetClientTeam(search2)))
												{
													new Float:searchOrigin2[3];
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
													new Float:searchOrigin2[3];
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
													new Float:searchOrigin2[3];
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
													new Float:searchOrigin2[3];
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
							new Float:clientOrigin[3];
							new Float:enemysentryOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
							
							clientOrigin[2] += 50.0;
							
							decl Float:camangle[3], Float:fEntityLocation[3];
							decl Float:vec[3],Float:angle[3];
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
							new Float:clientOrigin[3];
							new Float:enemysentryOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", enemysentryOrigin);
							
							clientOrigin[2] += 50.0;
							
							decl Float:camangle[3], Float:fEntityLocation[3];
							decl Float:vec[3],Float:angle[3];
							GetEntPropVector(EnemyBuilding, Prop_Send, "m_vecOrigin", fEntityLocation);
							GetEntPropVector(EnemyBuilding, Prop_Data, "m_angRotation", angle);
							fEntityLocation[2] += 35.0;
							MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
							GetVectorAngles(vec, camangle);
							camangle[0] *= -1.0;
							camangle[1] += 180.0;
							ClampAngle(camangle);
							
							new iBuildingIsSapped = GetEntProp(EnemyBuilding, Prop_Send, "m_bHasSapper");
							
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
					for (new myfriendisattacking = 1; myfriendisattacking <= MaxClients; myfriendisattacking++)
					{
						if (IsValidClient(myfriendisattacking) && IsClientInGame(myfriendisattacking) && IsPlayerAlive(myfriendisattacking) && myfriendisattacking != client && (GetClientTeam(myfriendisattacking) == GetClientTeam(myfriendisattacking)))
						{
							new Float:myfriendisattackingorigin[3];
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
				
				for (new idiotspy = 1; idiotspy <= MaxClients; idiotspy++)
				{
					if (IsValidClient(idiotspy) && IsClientInGame(idiotspy) && IsPlayerAlive(idiotspy) && idiotspy != client && (GetClientTeam(client) != GetClientTeam(idiotspy)))
					{
						new Float:idiotspyorigin[3];
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
						new randomdisguise = GetRandomInt(1,9);
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
						new randomdisguise = GetRandomInt(1,9);
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
					
					new iSentryLevel = GetEntProp(sentry, Prop_Send, "m_iUpgradeLevel");
					new iSentryHealth = GetEntProp(sentry, Prop_Send, "m_iHealth");
					new iSentryMaxHealth = GetEntProp(sentry, Prop_Send, "m_iMaxHealth");
					
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
					
					new iTeleporterEnterLevel = GetEntProp(teleporterenter, Prop_Send, "m_iUpgradeLevel");
					new iTeleporterEnterHealth = GetEntProp(teleporterenter, Prop_Send, "m_iHealth");
					new iTeleporterEnterMaxHealth = GetEntProp(teleporterenter, Prop_Send, "m_iMaxHealth");
					
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
					
					new iTeleporterExitLevel = GetEntProp(teleporterexit, Prop_Send, "m_iUpgradeLevel");
					new iTeleporterExitHealth = GetEntProp(teleporterexit, Prop_Send, "m_iHealth");
					new iTeleporterExitMaxHealth = GetEntProp(teleporterexit, Prop_Send, "m_iMaxHealth");
					
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
					
					new iDispenserLevel = GetEntProp(dispenser, Prop_Send, "m_iUpgradeLevel");
					new iDispenserHealth = GetEntProp(dispenser, Prop_Send, "m_iHealth");
					new iDispenserMaxHealth = GetEntProp(dispenser, Prop_Send, "m_iMaxHealth");
					
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
					if(g_bAmmoIsLow[client] && !g_bHealthIsLow[client] && !TF2_HasTheFlag(client) && !g_bUseTeleporter[client] && !g_bHideFromTheTarget[client])
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
					
					if(g_bHealthIsLow[client] && !TF2_HasTheFlag(client) && !g_bHideFromTheTarget[client])
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
						if(PF_Exists(client) && PF_IsPathToVectorPossible(client, GetAbsOrigin(healthpack)))
						{
							GetEntPropVector(healthpack, Prop_Send, "m_vecOrigin", g_flNearestHealthOrigin[client]);
							
							g_flFindNearestHealthTimer[client] = GetGameTime() + 20.0;
						}
					}
				}
				
				if(g_flFindNearestAmmoTimer[client] < GetGameTime())
				{
					int ammopack2 = FindNearestAmmo(client);
					
					if (ammopack2 != -1)
					{
						if(PF_Exists(client) && PF_IsPathToVectorPossible(client, GetAbsOrigin(ammopack2)))
						{
							GetEntPropVector(ammopack2, Prop_Send, "m_vecOrigin", g_flNearestAmmoOrigin[client]);
							
							g_flFindNearestAmmoTimer[client] = GetGameTime() + 20.0;
						}
					}
				}
				
				if(class == TFClass_DemoMan)
				{
					for (new search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{
							float searchOrigin[3];
							GetClientEyePosition(search, searchOrigin);
							
							if(GetVectorDistance(g_flPipeOrigin[client], searchOrigin) < 200.0 && !TF2_IsPlayerInCondition(search, TFCond_Ubercharged) && IsPointVisible(clientEyes, searchOrigin))
							{
								buttons |= IN_ATTACK2;
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
				
				if(GetEntityFlags(client) & FL_ONGROUND)
				{
					NavArea jumparea = TheNavMesh.GetNearestNavArea_Vec(g_flClientPos[client], false, 250.0, false, false, GetClientTeam(client));
					if(jumparea != NavArea_Null)
					{
						if(jumparea.HasAttributes(NAV_MESH_JUMP) && !jumparea.HasAttributes(NAV_MESH_NO_JUMP))
						{
							g_bJump[client] = true;
						}
					}
				}
				
				if(g_bJump[client])
				{
					buttons |= IN_JUMP;
					g_bJump[client] = false;
				}
				
				if(!g_bCrouch[client] && GetEntityFlags(client) & FL_ONGROUND)
				{
					NavArea croucharea = TheNavMesh.GetNearestNavArea_Vec(g_flClientPos[client], false, 250.0, false, false, GetClientTeam(client));
					if(croucharea != NavArea_Null)
					{
						if(croucharea.HasAttributes(NAV_MESH_CROUCH))
						{
							g_bCrouch[client] = true;
						}
					}
				}
				
				if(g_bCrouch[client])
				{
					NavArea croucharea = TheNavMesh.GetNearestNavArea_Vec(g_flClientPos[client], false, 250.0, false, false, GetClientTeam(client));
					if(croucharea != NavArea_Null)
					{
						if(!croucharea.HasAttributes(NAV_MESH_CROUCH))
						{
							g_bCrouch[client] = false;
						}
					}
				}
				
				if(g_bCrouch[client])
				{
					if(GetEntityFlags(client) & FL_ONGROUND)
					{
						buttons |= IN_DUCK;
					}
				}
				
				// Demoman Sticky Logic
				
				if(class == TFClass_DemoMan && Ent == -1)
				{
					if(g_bMakeStickyTrap[client] && !g_bAmmoIsLow[client] && !g_bHealthIsLow[client] && !TF2_HasTheFlag(client))
					{
						new flag;
						if(StrContains(currentMap, "ctf_" , false) != -1)
						{
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								new iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
								{
									float spotpos[3];
									float SelectedLookPos[3];
									float SelectRandomNav[3];
									float capturepointpos[3];
									float capturepointpos2[3];
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", capturepointpos);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", capturepointpos2);
									
									if(!IsPointVisible(clientEyes, capturepointpos))
									{
										g_bPathFinding[client] = true;
										
										TF2_FindPath(client, capturepointpos);
										
										if(PF_Exists(client) && IsPlayerAlive(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
									else
									{
										capturepointpos2[0] += GetRandomFloat(-100.0, 100.0);
										capturepointpos2[1] += GetRandomFloat(-100.0, 100.0);
										
										g_bPathFinding[client] = false;
										
										NavArea area = TheNavMesh.GetNearestNavArea_Vec(capturepointpos2, true, 5000.0, false, false, GetClientTeam(client));
										if(area != NavArea_Null)
										{
											area.GetRandomPoint(SelectRandomNav);
										}
										
										if(IsPointVisible(g_flClientEyePos[client], SelectRandomNav))
										{
											SelectedLookPos[0] = SelectRandomNav[0];
											SelectedLookPos[1] = SelectRandomNav[1];
											SelectedLookPos[2] = SelectRandomNav[2];
										}
										
										if(IsPointVisible(g_flClientEyePos[client], SelectedLookPos))
										{
											if(g_flLookTimer[client] < GetGameTime())
											{
												spotpos[0] = SelectedLookPos[0];
												spotpos[1] = SelectedLookPos[1];
												spotpos[2] = SelectedLookPos[2];
												
												g_flLookTimer[client] = GetGameTime() + GetRandomFloat(1.0, 2.5);
											}
										}
										
										if(g_iPipeCount[client] < 8)
										{
											if(IsWeaponSlotActive(client, 1))
											{
												TF2_LookAtPos(client, spotpos, RandomizeAim);
												if(g_flDemoAttackTimer[client] < GetGameTime())
												{
													buttons |= IN_ATTACK;
													g_flDemoAttackTimer[client] = GetGameTime() + 0.5;
													spotpos[0] = g_flPipeOrigin[client][0];
													spotpos[1] = g_flPipeOrigin[client][1];
													spotpos[2] = g_flPipeOrigin[client][2];
												}
											}
											else
											{
												EquipWeaponSlot(client, 1);
											}
										}
										else
										{
											g_bMakeStickyTrap[client] = false;
										}
									}
								}
							}
						}
						if(StrContains(currentMap, "pl_" , false) != -1)
						{
							int payload;
							if((payload = FindEntityByClassname(payload, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								float spotpos[3];
								float SelectedLookPos[3];
								float SelectRandomNav[3];
								float capturepointpos[3];
								float capturepointpos2[3];
								GetEntPropVector(payload, Prop_Send, "m_vecOrigin", capturepointpos);
								GetEntPropVector(payload, Prop_Send, "m_vecOrigin", capturepointpos2);
								
								if(!IsPointVisible(clientEyes, capturepointpos))
								{
									g_bPathFinding[client] = true;
									
									TF2_FindPath(client, capturepointpos);
									
									if(PF_Exists(client) && IsPlayerAlive(client))
									{
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
								}
								else
								{
									capturepointpos2[0] += GetRandomFloat(-100.0, 100.0);
									capturepointpos2[1] += GetRandomFloat(-100.0, 100.0);
									
									g_bPathFinding[client] = false;
									
									NavArea area = TheNavMesh.GetNearestNavArea_Vec(capturepointpos2, true, 5000.0, false, false, GetClientTeam(client));
									if(area != NavArea_Null)
									{
										area.GetRandomPoint(SelectRandomNav);
									}
									
									if(IsPointVisible(g_flClientEyePos[client], SelectRandomNav))
									{
										SelectedLookPos[0] = SelectRandomNav[0];
										SelectedLookPos[1] = SelectRandomNav[1];
										SelectedLookPos[2] = SelectRandomNav[2];
									}
									
									if(IsPointVisible(g_flClientEyePos[client], SelectedLookPos))
									{
										if(g_flLookTimer[client] < GetGameTime())
										{
											spotpos[0] = SelectedLookPos[0];
											spotpos[1] = SelectedLookPos[1];
											spotpos[2] = SelectedLookPos[2];
											
											g_flLookTimer[client] = GetGameTime() + GetRandomFloat(1.0, 2.5);
										}
									}
									
									if(g_iPipeCount[client] < 8)
									{
										if(IsWeaponSlotActive(client, 1))
										{
											TF2_LookAtPos(client, spotpos, RandomizeAim);
											if(g_flDemoAttackTimer[client] < GetGameTime())
											{
												buttons |= IN_ATTACK;
												g_flDemoAttackTimer[client] = GetGameTime() + 0.5;
												spotpos[0] = g_flPipeOrigin[client][0];
												spotpos[1] = g_flPipeOrigin[client][1];
												spotpos[2] = g_flPipeOrigin[client][2];
											}
										}
										else
										{
											EquipWeaponSlot(client, 1);
										}
									}
									else
									{
										g_bMakeStickyTrap[client] = false;
									}
								}
							}
						}
					}
				}
				
				if(class == TFClass_DemoMan && Ent == -1)
				{
					if(g_iPipeCount[client] < 8)
					{
						if(!g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && !g_bHideFromTheTarget[client])
						{
							if(StrContains(currentMap, "pl_" , false) != -1)
							{
								if(GetClientTeam(client) == 2)
								{
									g_bMakeStickyTrap[client] = true;
								}
							}
						}
					}
					else
					{
						g_bMakeStickyTrap[client] = false;
					}
				}
				
				if(class == TFClass_DemoMan)
				{
					if(GetClientButtons(client) == IN_ATTACK2)
					{
						g_iPipeCount[client] = 0;
					}
					
					if(IsWeaponSlotActive(client, 1))
					{
						if(GetClientButtons(client) == IN_ATTACK)
						{
							g_iPipeCount[client] += 1;
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
						else if(StrContains(currentMap, "ctf_" , false) != -1)
						{
							TF2_FindSniperSpot(client);
							
							TF2_FindPath(client, g_flSniperSpotPos[client]);
							
							if(PF_Exists(client) && g_bPathFinding[client])
							{
								TF2_MoveTo(client, g_flGoal[client], vel, angles);
							}
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
						
						if(StrContains(currentMap, "pl_" , false) != -1)
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
								
								if(TF2_IsPlayerInCondition(client, TFCond_Zoomed) && Ent == -1)
								{
									buttons |= IN_ATTACK2;
								}
							}
							else
							{
								if(TF2_IsPlayerInCondition(client, TFCond_Zoomed) && Ent == -1)
								{
									if(g_flSniperLookTimer[client] < GetGameTime())
									{
										new randomselectaimpoint = GetRandomInt(1,4);
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
								
								g_bPathFinding[client] = false;
							}
							else
							{
								g_bPathFinding[client] = true;
								
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
							new randomsniperspot = GetRandomInt(1, 3);
							switch(randomsniperspot)
							{
								case 1:
								{
									new Float:SniperSpotPos[3] = {237.0, 1039.0, 330.0};
									new Float:SniperSpotAim1[3] = {267.0, -1065.0, 140.0};
									new Float:SniperSpotAim2[3] = {-254.0, -1027.0, 300.0};
									new Float:SniperSpotAim3[3] = {-267.0, -1065.0, 140.0};
									new Float:SniperSpotAim4[3] = {254.0, -1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 2:
								{
									new Float:SniperSpotPos[3] = {-237.0, 1039.0, 330.0};
									new Float:SniperSpotAim1[3] = {267.0, -1065.0, 140.0};
									new Float:SniperSpotAim2[3] = {-254.0, -1027.0, 300.0};
									new Float:SniperSpotAim3[3] = {-267.0, -1065.0, 140.0};
									new Float:SniperSpotAim4[3] = {254.0, -1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 3:
								{
									new Float:SniperSpotPos[3] = {-0.0, 963.0, 324.0};
									new Float:SniperSpotAim1[3] = {267.0, -1065.0, 140.0};
									new Float:SniperSpotAim2[3] = {-254.0, -1027.0, 300.0};
									new Float:SniperSpotAim3[3] = {-267.0, -1065.0, 140.0};
									new Float:SniperSpotAim4[3] = {254.0, -1027.0, 300.0};
									
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
							new randomsniperspot = GetRandomInt(1, 4);
							switch(randomsniperspot)
							{
								case 1:
								{
									new Float:SniperSpotPos[3] = {679.0, 292.0, 123.0};
									new Float:SniperSpotAim1[3] = {-989.0, -399.0, -180.0};
									new Float:SniperSpotAim2[3] = {-688.0, 449.0, -180.0};
									new Float:SniperSpotAim3[3] = {-675.0, -273.0, 123.0};
									new Float:SniperSpotAim4[3] = {-684.0, 257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 2:
								{
									new Float:SniperSpotPos[3] = {680.0, 520.0, 123.0};
									new Float:SniperSpotAim1[3] = {-989.0, -399.0, -180.0};
									new Float:SniperSpotAim2[3] = {-688.0, 449.0, -180.0};
									new Float:SniperSpotAim3[3] = {-675.0, -273.0, 123.0};
									new Float:SniperSpotAim4[3] = {-684.0, 257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 3:
								{
									new Float:SniperSpotPos[3] = {683.0, -316.0, 123.0};
									new Float:SniperSpotAim1[3] = {-989.0, -399.0, -180.0};
									new Float:SniperSpotAim2[3] = {-688.0, 449.0, -180.0};
									new Float:SniperSpotAim3[3] = {-675.0, -273.0, 123.0};
									new Float:SniperSpotAim4[3] = {-684.0, 257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 4:
								{
									new Float:SniperSpotPos[3] = {677.0, -677.0, 123.0};
									new Float:SniperSpotAim1[3] = {-989.0, -399.0, -180.0};
									new Float:SniperSpotAim2[3] = {-688.0, 449.0, -180.0};
									new Float:SniperSpotAim3[3] = {-675.0, -273.0, 123.0};
									new Float:SniperSpotAim4[3] = {-684.0, 257.0, 123.0};
									
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
							new randomsniperspot = GetRandomInt(1, 3);
							switch(randomsniperspot)
							{
								case 1:
								{
									new Float:SniperSpotPos[3] = {-237.0, -1039.0, 330.0};
									new Float:SniperSpotAim1[3] = {-267.0, 1065.0, 140.0};
									new Float:SniperSpotAim2[3] = {254.0, 1027.0, 300.0};
									new Float:SniperSpotAim3[3] = {267.0, 1065.0, 140.0};
									new Float:SniperSpotAim4[3] = {-254.0, 1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 2:
								{
									new Float:SniperSpotPos[3] = {237.0, -1039.0, 330.0};
									new Float:SniperSpotAim1[3] = {-267.0, 1065.0, 140.0};
									new Float:SniperSpotAim2[3] = {254.0, 1027.0, 300.0};
									new Float:SniperSpotAim3[3] = {267.0, 1065.0, 140.0};
									new Float:SniperSpotAim4[3] = {-254.0, 1027.0, 300.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 3:
								{
									new Float:SniperSpotPos[3] = {0.0, -963.0, 324.0};
									new Float:SniperSpotAim1[3] = {-267.0, 1065.0, 140.0};
									new Float:SniperSpotAim2[3] = {254.0, 1027.0, 300.0};
									new Float:SniperSpotAim3[3] = {267.0, 1065.0, 140.0};
									new Float:SniperSpotAim4[3] = {-254.0, 1027.0, 300.0};
									
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
							new randomsniperspot = GetRandomInt(1, 4);
							switch(randomsniperspot)
							{
								case 1:
								{
									new Float:SniperSpotPos[3] = {-679.0, -292.0, 123.0};
									new Float:SniperSpotAim1[3] = {989.0, 399.0, -180.0};
									new Float:SniperSpotAim2[3] = {688.0, -449.0, -180.0};
									new Float:SniperSpotAim3[3] = {675.0, 273.0, 123.0};
									new Float:SniperSpotAim4[3] = {684.0, -257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 2:
								{
									new Float:SniperSpotPos[3] = {-680.0, -520.0, 123.0};
									new Float:SniperSpotAim1[3] = {989.0, 399.0, -180.0};
									new Float:SniperSpotAim2[3] = {688.0, -449.0, -180.0};
									new Float:SniperSpotAim3[3] = {675.0, 273.0, 123.0};
									new Float:SniperSpotAim4[3] = {684.0, -257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 3:
								{
									new Float:SniperSpotPos[3] = {-683.0, 316.0, 123.0};
									new Float:SniperSpotAim1[3] = {989.0, 399.0, -180.0};
									new Float:SniperSpotAim2[3] = {688.0, -449.0, -180.0};
									new Float:SniperSpotAim3[3] = {675.0, 273.0, 123.0};
									new Float:SniperSpotAim4[3] = {684.0, -257.0, 123.0};
									
									g_flSniperSpotPos[client] = SniperSpotPos;
									g_flSniperAim1[client] = SniperSpotAim1;
									g_flSniperAim2[client] = SniperSpotAim2;
									g_flSniperAim3[client] = SniperSpotAim3;
									g_flSniperAim4[client] = SniperSpotAim4;
									
									g_bPickRandomSniperSpot[client] = false;
								}
								case 4:
								{
									new Float:SniperSpotPos[3] = {-677.0, 677.0, 123.0};
									new Float:SniperSpotAim1[3] = {989.0, 399.0, -180.0};
									new Float:SniperSpotAim2[3] = {688.0, -449.0, -180.0};
									new Float:SniperSpotAim3[3] = {675.0, 273.0, 123.0};
									new Float:SniperSpotAim4[3] = {684.0, -257.0, 123.0};
									
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
					new BuildedSentryGun;
					if(StrContains(currentMap, "pl_" , false) != -1)
					{
						TF2_FindSentrySpot(client);
					}
					else if(GetClientTeam(client) == 2 && (BuildedSentryGun = FindEntityByClassname(BuildedSentryGun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
					{
						if(StrContains(currentMap, "ctf_turbine" , false) != -1)
						{
							new randomsentryspot = GetRandomInt(1, 5);
							switch(randomsentryspot)
							{
								case 1:
								{
									new Float:SentryPos[3] = {2013.0, 1543.0, -190.0};
									new Float:SentryAngle[3] = {2231.0, 1312.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {2828.0, 1161.0, -222.0};
									new Float:SentryAngle[3] = {2540.0, 1163.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {1274.0, 1454.0, -94.0};
									new Float:SentryAngle[3] = {1273.0, 335.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {2905.0, 501.0, -190.0};
									new Float:SentryAngle[3] = {2895.0, 863.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {1698.0, -439.0, 89.0};
									new Float:SentryAngle[3] = {832.0, -447.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
							new randomsentryspot = GetRandomInt(1, 12);
							switch(randomsentryspot)
							{
							case 1:
								{
									new Float:SentryPos[3] = {580.0, 1448.0, 321.0};
									new Float:SentryAngle[3] = {673.0, 1606.0, 321.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {616.0, 2622.0, -126.0};
									new Float:SentryAngle[3] = {417.0, 3126.0, -126.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {3.0, 1553.0, 126.0};
									new Float:SentryAngle[3] = {-7.0, 1026.0, 129.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {765.0, 1765.0, -102.0};
									new Float:SentryAngle[3] = {498.0, 1494.0, -132.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-415.0, 3296.0, -110.0};
									new Float:SentryAngle[3] = {39.0, 2968.0, -126.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-1.0, 1457.0, 331.0};
									new Float:SentryAngle[3] = {-5.0, 1192.0, 331.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {15.0, 2993.0, -116.0};
									new Float:SentryAngle[3] = {-362.0, 3368.0, -100.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-601.0, 2982.0, -100.0};
									new Float:SentryAngle[3] = {24.0, 3432.0, -116.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {24.0, 3432.0, -116.0};
									new Float:SentryAngle[3] = {-601.0, 2982.0, -100.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {213.0, 1334.0, 331.0};
									new Float:SentryAngle[3] = {661.0, 1598.0, 331.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {655.0, 1417.0, 140.0};
									new Float:SentryAngle[3] = {131.0, 1582.0, 137.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-497.0, -1871.0, -92.0};
									new Float:SentryAngle[3] = {-489.0, -1501.0, -127.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
						else
						{
							TF2_FindSentrySpot(client);
						}
					}
					else if((BuildedSentryGun = FindEntityByClassname(BuildedSentryGun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
					{
						if(StrContains(currentMap, "ctf_turbine" , false) != -1)
						{
							new randomsentryspot = GetRandomInt(1, 5);
							switch(randomsentryspot)
							{
								case 1:
								{
									new Float:SentryPos[3] = {-2013.0, -1543.0, -190.0};
									new Float:SentryAngle[3] = {-2231.0, -1312.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-2828.0, -1161.0, -222.0};
									new Float:SentryAngle[3] = {-2540.0, -1163.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-1274.0, -1454.0, -94.0};
									new Float:SentryAngle[3] = {-1273.0, -335.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-2905.0, -501.0, -190.0};
									new Float:SentryAngle[3] = {-2895.0, -863.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-1698.0, 439.0, 89.0};
									new Float:SentryAngle[3] = {-832.0, 447.0, -190.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
							new randomsentryspot = GetRandomInt(1, 12);
							switch(randomsentryspot)
							{
							case 1:
								{
									new Float:SentryPos[3] = {-580.0, -1448.0, 321.0};
									new Float:SentryAngle[3] = {-673.0, -1606.0, 321.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-616.0, -2622.0, -126.0};
									new Float:SentryAngle[3] = {-417.0, -3126.0, -126.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-3.0, -1553.0, 126.0};
									new Float:SentryAngle[3] = {7.0, -1026.0, 129.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-765.0, -1765.0, -102.0};
									new Float:SentryAngle[3] = {-498.0, -1494.0, -132.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {415.0, -3296.0, -110.0};
									new Float:SentryAngle[3] = {-39.0, -2968.0, -126.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {1.0, -1457.0, 331.0};
									new Float:SentryAngle[3] = {5.0, -1192.0, 331.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-15.0, -2993.0, -116.0};
									new Float:SentryAngle[3] = {362.0, -3368.0, -100.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {601.0, -2982.0, -100.0};
									new Float:SentryAngle[3] = {-24.0, -3432.0, -116.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-24.0, -3432.0, -116.0};
									new Float:SentryAngle[3] = {601.0, -2982.0, -100.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-213.0, -1334.0, 331.0};
									new Float:SentryAngle[3] = {-661.0, -1598.0, 331.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {-655.0, -1417.0, 140.0};
									new Float:SentryAngle[3] = {-131.0, -1582.0, 137.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
									new Float:SentryPos[3] = {497.0, -871.0, -92.0};
									new Float:SentryAngle[3] = {489.0, 1501.0, -127.0};
									
									if(IsValidEntity(BuildedSentryGun))
									{
										new Float:BuildedSentryOrigin[3];
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
						else
						{
							TF2_FindSentrySpot(client);
						}
					}
				}
				
				// Engineer Logic
				
				if(class != TFClass_Engineer)
				{
					g_bEngineerTasksFinished[client] = true;
				}
				
				if(class == TFClass_Engineer)
				{
					if(g_bSentryBuilded[client] && g_bSentryHealthIsFull[client] && g_bSentryIsMaxLevel[client] && g_bDispenserBuilded[client] && g_bDispenserHealthIsFull[client] && g_bDispenserIsMaxLevel[client])
					{
						g_bEngineerTasksFinished[client] = true;
					}
					else
					{
						g_bEngineerTasksFinished[client] = false;
					}
				}
				
				if(!g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && !TF2_HasTheFlag(client) && !g_bUseTeleporter[client])
				{
					if(class == TFClass_Engineer && !g_bEngineerTasksFinished[client])
					{
						if(StrContains(currentMap, "ctf_" , false) != -1)
						{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
								{
									new Float:engiOrigin[3];
									new Float:ecappos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", ecappos);
									
									ecappos[2] += 100.0;
									
									if(GetMetal(client) == 0.0 || (!g_bSentryBuilded[client] && !g_bCanBuildSentryGun[client] || g_bSentryBuilded[client] && g_bSentryIsMaxLevel[client] && !g_bDispenserBuilded[client] && !g_bCanBuildDispenser[client]))
									{
										int ammopack = FindNearestAmmo(client);
										
										if(IsValidEntity(ammopack))
										{
											if(ammopack != -1)
											{
												new Float:clientOrigin[3];
												new Float:ammopackorigin[3];
												GetClientAbsOrigin(client, clientOrigin);
												GetEntPropVector(ammopack, Prop_Send, "m_vecOrigin", ammopackorigin);
													
												if(GetVectorDistance(clientOrigin, ammopackorigin) > 15.0)
												{
													TF2_FindPath(client, ammopackorigin);
													
													if(!IsPlayerAlive(client) || !PF_Exists(client))
														return Plugin_Continue;
													
													TF2_MoveTo(client, g_flGoal[client], vel, angles);
													
													g_bPathFinding[client] = true;
												}
												else
												{
													g_bPathFinding[client] = false;
												}
											}
										}
									}
									
									if(g_bSentryBuilded[client])
									{
										if(GetMetal(client) > 0 && (!g_bSentryIsMaxLevel[client] || !g_bSentryHealthIsFull[client]) && (!g_bDispenserBuilded[client] || (g_bDispenserBuilded[client] && g_bDispenserHealthIsFull[client])))
										{
											new Float:sentrypos[3];
											GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
											
											decl Float:camangle[3], Float:fEntityLocation[3];
											decl Float:vec[3],Float:angle[3];
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
												TF2_FindPath(client, sentrypos);
												
												g_bPathFinding[client] = true;
												
												if(!IsPlayerAlive(client) || !PF_Exists(client))
													return Plugin_Continue;
												
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
											else
											{
												g_bPathFinding[client] = false;
											}
										}
									}
									
									if(g_bSentryBuilded[client] && g_bSentryIsMaxLevel[client] && g_bSentryHealthIsFull[client] && !g_bMoveSentry[client])
									{
										if(!g_bDispenserBuilded[client] && g_bCanBuildDispenser[client])
										{
											new Float:sentrypos2[3];
											GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos2);
											
											TF2_FindPath(client, sentrypos2);
											
											g_bPathFinding[client] = true;
											
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
											new Float:dispenserpos[3];
											GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
											
											decl Float:camangle[3], Float:fEntityLocation[3];
											decl Float:vec[3],Float:angle[3];
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
												TF2_FindPath(client, dispenserpos);
												
												g_bPathFinding[client] = true;
												
												if(!IsPlayerAlive(client) || !PF_Exists(client))
													return Plugin_Continue;
												
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
											else
											{
												g_bPathFinding[client] = false;
											}
										}
									}
									
									if(!g_bSentryBuilded[client] && g_bCanBuildSentryGun[client] && !g_bMoveSentry[client])
									{
										TF2_FindPath(client, ecappos);
										
										g_bPathFinding[client] = true;
										
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
						if(StrContains(currentMap, "pl_" , false) != -1)
						{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(flag))
								{
									new Float:engiOrigin[3];
									new Float:ecappos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", ecappos);
									
									ecappos[2] += 100.0;
									
									if(GetMetal(client) == 0.0 || (!g_bSentryBuilded[client] && !g_bCanBuildSentryGun[client] || g_bSentryBuilded[client] && g_bSentryIsMaxLevel[client] && !g_bDispenserBuilded[client] && !g_bCanBuildDispenser[client]))
									{
										int ammopack = FindNearestAmmo(client);
										
										if(IsValidEntity(ammopack))
										{
											if(ammopack != -1)
											{
												new Float:clientOrigin[3];
												new Float:ammopackorigin[3];
												GetClientAbsOrigin(client, clientOrigin);
												GetEntPropVector(ammopack, Prop_Send, "m_vecOrigin", ammopackorigin);
												
												if(GetVectorDistance(clientOrigin, ammopackorigin) > 15.0)
												{
													TF2_FindPath(client, ammopackorigin);
													
													if(!IsPlayerAlive(client) || !PF_Exists(client))
														return Plugin_Continue;
													
													TF2_MoveTo(client, g_flGoal[client], vel, angles);
													
													g_bPathFinding[client] = true;
												}
												else
												{
													g_bPathFinding[client] = false;
												}
											}
										}
									}
									
									if(g_bSentryBuilded[client])
									{
										if(GetMetal(client) > 0 && (!g_bSentryIsMaxLevel[client] || !g_bSentryHealthIsFull[client]) && (!g_bDispenserBuilded[client] || (g_bDispenserBuilded[client] && g_bDispenserHealthIsFull[client])))
										{
											new Float:sentrypos[3];
											GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
											
											decl Float:camangle[3], Float:fEntityLocation[3];
											decl Float:vec[3],Float:angle[3];
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
												TF2_FindPath(client, sentrypos);
												
												g_bPathFinding[client] = true;
												
												if(!IsPlayerAlive(client) || !PF_Exists(client))
													return Plugin_Continue;
												
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
											else
											{
												g_bPathFinding[client] = false;
											}
										}
									}
									
									if(g_bSentryBuilded[client] && g_bSentryIsMaxLevel[client] && g_bSentryHealthIsFull[client] && !g_bMoveSentry[client])
									{
										if(!g_bDispenserBuilded[client] && g_bCanBuildDispenser[client])
										{
											new Float:sentrypos2[3];
											GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos2);
											
											TF2_FindPath(client, sentrypos2);
											
											g_bPathFinding[client] = true;
											
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
											new Float:dispenserpos[3];
											GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
											
											decl Float:camangle[3], Float:fEntityLocation[3];
											decl Float:vec[3],Float:angle[3];
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
												TF2_FindPath(client, dispenserpos);
												
												g_bPathFinding[client] = true;
												
												if(!IsPlayerAlive(client) || !PF_Exists(client))
													return Plugin_Continue;
												
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
											else
											{
												g_bPathFinding[client] = false;
											}
										}
									}
									
									if(!g_bSentryBuilded[client] && g_bCanBuildSentryGun[client] && !g_bMoveSentry[client])
									{
										TF2_FindPath(client, g_bSentryBuildPos[client]);
										
										g_bPathFinding[client] = true;
										
										if(IsPointVisible(clientEyes, g_bSentryBuildPos[client]))
										{
											if(GetVectorDistance(engiOrigin, g_bSentryBuildPos[client]) < GetRandomFloat(25.0, 125.0))
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
						if(StrContains(currentMap, "arena_" , false) != -1 || StrContains(currentMap, "koth_" , false) != -1)
						{
							new engidefendcap;
							while((engidefendcap = FindEntityByClassname(engidefendcap, "team_control_point")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(engidefendcap))
								{
									new Float:engiOrigin[3];
									new Float:ecappos[3];
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
												new Float:clientOrigin[3];
												new Float:ammopackorigin[3];
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
											new Float:sentrypos[3];
											GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
											
											decl Float:camangle[3], Float:fEntityLocation[3];
											decl Float:vec[3],Float:angle[3];
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
											new Float:sentrypos2[3];
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
											new Float:dispenserpos[3];
											GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
											
											decl Float:camangle[3], Float:fEntityLocation[3];
											decl Float:vec[3],Float:angle[3];
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
				
				// Hide From The Enemy
				
				if(g_bHideFromTheTarget[client])
				{
					if(TF2_IsPlayerInCondition(client, TFCond_Overhealed))
					{
						g_bHideFromTheTarget[client] = false;
					}
					
					if(Ent != -1 && !g_bFindNewHidingSpot[client])
					{
						g_bFindNewHidingSpot[client] = true;
					}
					
					if((GetVectorDistance(clientEyes, g_flBestHidingOrigin[client]) > 100.0))
					{
						g_bPathFinding[client] = true;
						
						if(g_bHealthIsLow[client])
						{
							g_flHidingTime[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
						}
						else
						{
							g_flHidingTime[client] = GetGameTime() + GetRandomFloat(2.5, 5.0);
						}
					}
					else
					{
						if(g_flVoiceHelpTimer[client] < GetGameTime())
						{
							FakeClientCommandThrottled(client, "voicemenu 2 0");
							
							g_flVoiceHelpTimer[client] = GetGameTime() + GetRandomFloat(10.0, 100.0);
						}
						
						if(class == TFClass_Heavy)
						{
							buttons |= IN_ATTACK2;
						}
						
						g_bPathFinding[client] = false;
						
						if(Ent != -1)
						{
							if(g_bHealthIsLow[client])
							{
								g_flHidingTime[client] = GetGameTime() + GetRandomFloat(5.0, 15.0);
							}
							else
							{
								g_flHidingTime[client] = GetGameTime() + GetRandomFloat(2.5, 5.0);
							}
						}
					}
					
					g_flHidingTargetOrigin[client][0] = clientEyes[0] + GetRandomFloat(-1000.0, 1000.0);
					g_flHidingTargetOrigin[client][1] = clientEyes[1] + GetRandomFloat(-1000.0, 1000.0);
					g_flHidingTargetOrigin[client][2] = clientEyes[2];
					
					NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flHidingTargetOrigin[client], true, 5000.0, false, false, GetClientTeam(client));
					if(area != NavArea_Null)
					{
						if(g_bFindNewHidingSpot[client])
						{
							if(!IsPointVisible(g_flLookAtLastKnownEnemyPos[client], g_flHidingTargetOrigin[client]))
							{
								if(!area.HasAttributes(NAV_MESH_DONT_HIDE) && !area.HasAttributes(NAV_MESH_AVOID) && !HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
								{
									area.GetRandomPoint(g_flBestHidingOrigin[client]);
									
									if(PF_Exists(client) && PF_IsPathToVectorPossible(client, g_flBestHidingOrigin[client]))
									{
										g_bFindNewHidingSpot[client] = false;
									}
									else
									{
										g_bFindNewHidingSpot[client] = true;
									}
								}
								else
								{
									g_bFindNewHidingSpot[client] = true;
								}
							}
							else
							{
								g_bFindNewHidingSpot[client] = true;
							}
						}
					}
					else
					{
						g_bFindNewHidingSpot[client] = false;
					}
					
					TF2_FindPath(client, g_flBestHidingOrigin[client]);
					
					if(PF_Exists(client) && g_bPathFinding[client])
					{
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
					}
					
					if(g_flHidingTime[client] < GetGameTime())
					{
						g_bHideFromTheTarget[client] = false;
						
						g_bSpyAlert[client] = false;
					}
				}
				else
				{
					if(Ent != -1)
					{
						if(g_bSpyAlert[client] && g_bISeeSpy[Ent])
						{
							g_bHideFromTheTarget[client] = true;
						}
						else if(TF2_IsPlayerInCondition(Ent, TFCond_Ubercharged) || TF2_IsPlayerInCondition(Ent, TFCond_Zoomed))
						{
							g_bHideFromTheTarget[client] = true;
						}
						else if(TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Bleeding) || TF2_IsPlayerInCondition(client, TFCond_Milked) || TF2_IsPlayerInCondition(client, TFCond_Jarated))
						{
							g_bHideFromTheTarget[client] = true;
						}
						else if(g_bHealthIsLow[client] && !g_bHealthIsLow[Ent])
						{
							g_bHideFromTheTarget[client] = true;
						}
						else if(g_bAmmoIsLow[client])
						{
							g_bHideFromTheTarget[client] = true;
						}
						else
						{
							if(GetClientHealth(client) < (GetClientHealth(Ent) / 2))
							{
								g_bHideFromTheTarget[client] = true;
							}
						}
					}
				}
				
				// Map Support
				
				if(!g_bMedicAllHaveTasks[client] && !g_bCamping[client] && !g_bSpyHaveAnyTask[client] && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && class != TFClass_Engineer && !g_bMakeStickyTrap[client] && !g_bHideFromTheTarget[client])
				{
					if(StrContains(currentMap, "ctf_" , false) != -1)
					{
						if(g_bEngineerTasksFinished[client])
						{
							new flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								new iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) != iTeamNumObj)
								{
									new Float:clientOrigin[3];
									new Float:flagpos[3];
									GetClientAbsOrigin(client, clientOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
							
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
							
									//PrintToServer("FlagStatus %i", FlagStatus);
							
									if(FlagStatus == 1)
									{
										if(!TF2_HasTheFlag(client))
										{
											new flag2;
											while((flag2 = FindEntityByClassname(flag2, "item_teamflag")) != INVALID_ENT_REFERENCE)
											{
												new iTeamNumObj2 = GetEntProp(flag2, Prop_Send, "m_iTeamNum");
												if(IsValidEntity(flag2) && GetClientTeam(client) == iTeamNumObj2)
												{
													int FlagStatus2 = GetEntProp(flag2, Prop_Send, "m_nFlagStatus");
													
													if (FlagStatus2 == 1)
													{
														new Float:flagpos2[3];
														GetEntPropVector(flag2, Prop_Send, "m_vecOrigin", flagpos2);
														
														TF2_FindPath(client, flagpos2);
														
														if(PF_Exists(client) && IsPlayerAlive(client))
														{
															TF2_MoveTo(client, g_flGoal[client], vel, angles);
														}
													}
													else
													{
														new FPlayer = GetPlayersHasTheFlag(clientEyes, client);
														
														if(FPlayer != -1)
														{
															if(GetClientTeam(client) != GetClientTeam(FPlayer))
															{
																g_bPathFinding[client] = true;
																
																TF2_FindPath(client, g_flRedFlagCapPoint);
																
																if(PF_Exists(client) && IsPlayerAlive(client))
																{
																	TF2_MoveTo(client, g_flGoal[client], vel, angles);
																}
															}
															else
															{
																float FPlayerOrigin[3];
																GetClientAbsOrigin(FPlayer, FPlayerOrigin);
																
																if(GetVectorDistance(clientEyes, FPlayerOrigin) > 300.0)
																{
																	g_bPathFinding[client] = true;
																	
																	TF2_FindPath(client, g_flRedFlagCapPoint);
																
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
											}
										}
										else
										{
											if(GetClientTeam(client) == 2)
											{
												g_bPathFinding[client] = true;
												
												TF2_FindPath(client, g_flRedFlagCapPoint);
												
												if(PF_Exists(client) && IsPlayerAlive(client))
												{
													TF2_MoveTo(client, g_flGoal[client], vel, angles);
												}
											}
											else
											{
												g_bPathFinding[client] = true;
												
												TF2_FindPath(client, g_flBluFlagCapPoint);
												
												if(PF_Exists(client) && IsPlayerAlive(client))
												{
													TF2_MoveTo(client, g_flGoal[client], vel, angles);
												}
											}
										}
									}
									else if(FlagStatus == 0 || FlagStatus == 2)
									{
										g_bPathFinding[client] = true;
										
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
					else if(StrContains(currentMap, "mvm_" , false) != -1)
					{
						new tankboss;
						if((tankboss = FindEntityByClassname(tankboss, "tank_boss")) != INVALID_ENT_REFERENCE)
						{
							new iTeamNumObj = GetEntProp(tankboss, Prop_Send, "m_iTeamNum");
							if(IsValidEntity(tankboss) && GetClientTeam(client) != iTeamNumObj)
							{
								new Float:tankbosspos[3];
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
							for (new search = 1; search <= MaxClients; search++)
							{
								if (TF2_HasTheFlag(search) && IsValidClient(search) && IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
								{
									new Float:searchOrigin[3];
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
									new Float:searchOrigin[3];
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
						new capturepoint;
						if((capturepoint = FindEntityByClassname(capturepoint, "team_control_point")) != INVALID_ENT_REFERENCE)
						{
							new iTeamNumObj = GetEntProp(capturepoint, Prop_Send, "m_iTeamNum");
							if(IsValidEntity(capturepoint) && GetClientTeam(client) != iTeamNumObj)
							{
								float cappointpos[3];
								GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", cappointpos);
								
								g_bPathFinding[client] = true;
								
								g_flRandomDefendArea[client][0] = cappointpos[0] + GetRandomFloat(-200.0, 200.0);
								g_flRandomDefendArea[client][1] = cappointpos[1] + GetRandomFloat(-200.0, 200.0);
								g_flRandomDefendArea[client][2] = cappointpos[2] + 50.0;
								
								TF2_FindPath(client, g_flRandomDefendArea[client]);
								
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
						new capturepoint;
						while((capturepoint = FindEntityByClassname(capturepoint, "team_control_point")) != INVALID_ENT_REFERENCE)
						{
							new Owner = GetEntProp(capturepoint, Prop_Send, "m_iTeamNum");
							if(IsValidEntity(capturepoint) && Owner != client)
							{
								new Float:cappointpos[3];
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
					else if(StrContains(currentMap, "pl_" , false) != -1)
					{
						if(g_bEngineerTasksFinished[client])
						{
							new flag;
							if((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(flag))
								{
									new Float:flagpos[3];
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
										g_flRandomPayloadDefendArea[client][2] = flagpos[2];
										
										if(GetClientTeam(client) == 2)
										{
											NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomPayloadDefendArea[client], true, 90000.0, false, false, TEAM_ANY);
											if(area != NavArea_Null)
											{
												if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
												{
													area.GetRandomPoint(g_flSelectedPayloadDefendArea[client]);
													
													if(PF_Exists(client) && PF_IsPathToVectorPossible(client, g_flSelectedPayloadDefendArea[client]))
													{
														g_bFindNewDefendPayloadSpot[client] = false;
													}
													else
													{
														g_bFindNewDefendPayloadSpot[client] = true;
													}
												}
												else
												{
													g_bFindNewDefendPayloadSpot[client] = true;
												}
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
										
										if(IsPointVisible(clientEyes, g_flSelectedPayloadDefendArea[client]) && class == TFClass_Heavy && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && !g_bHideFromTheTarget[client])
										{
											buttons |= IN_ATTACK2;
										}
									}
									
									if(GetClientTeam(client) == 3)
									{
										if(g_bIsSetupTime == 0)
										{
											TF2_FindPath(client, flagpos);
											
											if(PF_Exists(client))
											{
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
											
											if(GetVectorDistance(clientEyes, flagpos) < 200.0 && class == TFClass_Heavy && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client] && !g_bHideFromTheTarget[client])
											{
												buttons |= IN_ATTACK2;
											}
										}
									}
								}
							}
						}
					}
				}
				else if(class == TFClass_Medic && Ent == -1)
				{
					for (new search = 1; search <= MaxClients; search++)
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
						new flag;
						while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
						{
							new iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
							if(IsValidEntity(flag) && GetClientTeam(client) != iTeamNumObj)
							{
								new Float:clientOrigin[3];
								new Float:flagpos[3];
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
				
				if(TF2_GetPlayerClass(client) == TFClass_Sniper && (PrimID == 56 || PrimID == 1005 || PrimID == 1092))
				{
					if(g_flSniperBowTimer[client] < GetGameTime())
					{
						if(Ent != -1)
						{
							buttons &= ~IN_ATTACK;
						}
						else
						{
							buttons |= IN_ATTACK2;
						}
					}
					else
					{
						buttons |= IN_ATTACK;
					}
				}
				
				if(class != TFClass_Medic)
				{
					decl Float:camangle[3], Float:targetEyes[3], Float:targetEyes2[3], Float:targetEyesBase[3], Float:targetHead[3];

					if(Ent != -1)
					{
						decl Float:vec[3],Float:angle[3];
						GetClientAbsOrigin(Ent, targetEyes);
						GetClientAbsOrigin(Ent, targetEyes2);
						GetClientAbsOrigin(Ent, targetEyesBase);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
						GetClientEyePosition(Ent, targetHead);
						
						new Float:location_check[3];
						GetClientAbsOrigin(client, location_check);

						new Float:chainDistance;
						chainDistance = GetVectorDistance(location_check,targetEyes);
						
						GetClientAbsOrigin(Ent, g_flLookAtLastKnownEnemyPos[client]);
						
						g_flLookAtLastKnownEnemyPos[client][2] += 75.0;
						
						new TFClassType:enemyclass = TF2_GetPlayerClass(Ent);
						
						new Float:EntVec[3];
						GetEntPropVector(Ent, Prop_Data, "m_vecVelocity", EntVec);
						
						if(class == TFClass_Sniper && (PrimID == 56 || PrimID == 1005 || PrimID == 1092))
						{
							if(IsWeaponSlotActive(client, 0))
							{
								if(GetEntityFlags(Ent) & FL_ONGROUND)
								{
									targetEyes[2] = targetHead[2];
									targetEyes[1] += (EntVec[1] / 2.5);
									targetEyes[0] += (EntVec[0] / 2.5);
								}
								else
								{
									targetEyes[2] = targetHead[2] + (EntVec[1] / 2.0);
									targetEyes[1] += (EntVec[1] / 2.0);
									targetEyes[0] += (EntVec[0] / 2.0);
								}
							}
							else
							{
								targetEyes[2] += 40.0;
								targetEyes[1] += 0.0;
							}
						}
						if(class == TFClass_Soldier)
						{
							if(IsWeaponSlotActive(client, 0))
							{
								if(GetEntityFlags(Ent) & FL_ONGROUND)
								{
									targetEyes[2] += 5.0;
									targetEyes[1] += (EntVec[1] / 2);
									targetEyes[0] += (EntVec[0] / 2);
								}
								else
								{
									targetEyes[2] += EntVec[2];
									targetEyes[1] += (EntVec[1] / 1.5);
									targetEyes[0] += (EntVec[0] / 1.5);
								}
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
						if(class == TFClass_Scout || class == TFClass_Heavy || class == TFClass_Engineer)
						{
							targetEyes[2] += 50.0;
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
							TF2_LookAtPos(client, targetHead, RandomizeAimWhenZoomed);
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
						else if(class == TFClass_Spy)
						{
							if(ClientViews(client, Ent) && class == TFClass_Spy && (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) 
							|| TF2_IsPlayerInCondition(client, TFCond_TmpDamageBonus) 
							|| TF2_IsPlayerInCondition(client, TFCond_Buffed) 
							|| TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) 
							|| TF2_IsPlayerInCondition(client, TFCond_OnFire) 
							|| TF2_IsPlayerInCondition(client, TFCond_Jarated) 
							|| TF2_IsPlayerInCondition(client, TFCond_Bleeding) 
							|| TF2_IsPlayerInCondition(client, TFCond_Milked)) 
							|| TF2_IsPlayerInCondition(client, TFCond_CritCanteen) 
							|| TF2_IsPlayerInCondition(client, TFCond_CritOnWin) 
							|| TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) 
							|| TF2_IsPlayerInCondition(client, TFCond_CritOnKill) 
							|| TF2_IsPlayerInCondition(client, TFCond_CritOnDamage) 
							|| TF2_IsPlayerInCondition(client, TFCond_MiniCritOnKill) 
							|| TF2_IsPlayerInCondition(client, TFCond_CritRuneTemp) 
							|| TF2_IsPlayerInCondition(client, TFCond_Gas) 
							|| TF2_IsPlayerInCondition(client, TFCond_ObscuredSmoke) 
							|| TF2_IsPlayerInCondition(client, TFCond_HalloweenGiant) 
							|| TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) 
							|| TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) 
							|| TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) 
							|| TF2_IsPlayerInCondition(client, TFCond_HalloweenBombHead) 
							|| TF2_IsPlayerInCondition(client, TFCond_NoHealingDamageBuff) 
							|| TF2_IsPlayerInCondition(client, TFCond_RegenBuffed) 
							|| TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed) 
							|| TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly) 
							|| TF2_HasTheFlag(Ent))
							{
								buttons |= IN_ATTACK;
							}
							else
							{
								if(ClientViews(Ent, client))
								{
									if(chainDistance < 300.0 && TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
									{
										TF2_LookAtPos(client, targetHead, RandomizeAim);
									}
									else
									{
										TF2_LookAround(client);
									}
								}
								else
								{
									if(ClientViews(client, Ent))
									{
										TF2_LookAtPos(client, targetHead, RandomizeAim);
									}
									else
									{
										TF2_LookAround(client);
									}
								}
							}
						}
						else
						{
							TF2_LookAtPos(client, targetEyes, RandomizeAim);
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
							
							g_flHeavySpinMinigunTimer[client] = GetGameTime() + GetRandomFloat(2.0, 4.0);
						}
						
						if(class == TFClass_Soldier)
						{
							float aimpos[3];
							GetAimOrigin(client, aimpos);
							
							if(enemyclass == TFClass_Pyro)
							{
								if(chainDistance < 128.0)
								{
									EquipWeaponSlot(client, 2);
								}
								else if(chainDistance < 512.0)
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
								if(chainDistance < 128.0)
								{
									EquipWeaponSlot(client, 2);
								}
								else if(chainDistance < 256.0)
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
									new ClipAmmo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
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
									if(GetVectorDistance(clientEyes, aimpos) > 256.0)
									{
										buttons |= IN_ATTACK;
									}
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
									if(g_flDemoAttackTimer[client] < GetGameTime())
									{
										buttons |= IN_ATTACK;
										
										g_flDemoAttackTimer[client] = GetGameTime() + 0.2;
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
							if(PrimID != 56 && PrimID != 1005 && PrimID != 1092 && PrimID != 1098)
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
							else if(PrimID == 56 || PrimID == 1005 || PrimID == 1092 || PrimID == 1098)
							{
								if(chainDistance < 200.0)
								{
									EquipWeaponSlot(client, 2);
								}
								if(chainDistance < 800.0 && g_flSniperBowTimer[client] < GetGameTime())
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
									if(g_flSniperBowTimer[client] < GetGameTime())
									{
										g_flSniperBowTimer[client] = GetGameTime() + GetRandomFloat(1.25, 3.0);
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
										
										g_flSniperPerfectShotTimer[client] = GetGameTime() + GetRandomFloat(2.0, 7.0);
									}
									
									if(g_flSniperFastShotTimer[client] < GetGameTime())
									{
										if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
										{
											if(ClientViews(client, Ent, 0.9))
											{
												buttons |= IN_ATTACK;
											}
										}
										else
										{
											buttons |= IN_ATTACK2;
										}
										g_flSniperFastShotTimer[client] = GetGameTime() + GetRandomFloat(1.0, 3.0);
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
						
						if(ClientViews(client, Ent) && class == TFClass_Spy && (TF2_IsPlayerInCondition(client, TFCond_Ubercharged) 
						|| TF2_IsPlayerInCondition(client, TFCond_TmpDamageBonus) 
						|| TF2_IsPlayerInCondition(client, TFCond_Buffed) 
						|| TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) 
						|| TF2_IsPlayerInCondition(client, TFCond_OnFire) 
						|| TF2_IsPlayerInCondition(client, TFCond_Jarated) 
						|| TF2_IsPlayerInCondition(client, TFCond_Bleeding) 
						|| TF2_IsPlayerInCondition(client, TFCond_Milked)) 
						|| TF2_IsPlayerInCondition(client, TFCond_CritCanteen) 
						|| TF2_IsPlayerInCondition(client, TFCond_CritOnWin) 
						|| TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) 
						|| TF2_IsPlayerInCondition(client, TFCond_CritOnKill) 
						|| TF2_IsPlayerInCondition(client, TFCond_CritOnDamage) 
						|| TF2_IsPlayerInCondition(client, TFCond_MiniCritOnKill) 
						|| TF2_IsPlayerInCondition(client, TFCond_CritRuneTemp) 
						|| TF2_IsPlayerInCondition(client, TFCond_Gas) 
						|| TF2_IsPlayerInCondition(client, TFCond_ObscuredSmoke) 
						|| TF2_IsPlayerInCondition(client, TFCond_HalloweenGiant) 
						|| TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) 
						|| TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) 
						|| TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) 
						|| TF2_IsPlayerInCondition(client, TFCond_HalloweenBombHead) 
						|| TF2_IsPlayerInCondition(client, TFCond_NoHealingDamageBuff) 
						|| TF2_IsPlayerInCondition(client, TFCond_RegenBuffed) 
						|| TF2_IsPlayerInCondition(client, TFCond_DefenseBuffed) 
						|| TF2_IsPlayerInCondition(client, TFCond_SpeedBuffAlly) 
						|| TF2_HasTheFlag(Ent))
						{
							TF2_LookAtPos(client, targetHead, RandomizeAim);
							
							if(IsWeaponSlotActive(client, 0))
							{
								buttons |= IN_ATTACK;
							}
							else
							{
								EquipWeaponSlot(client, 0);
							}
						}
						else if(class == TFClass_Spy)
						{
							if(GetClientHealth(client) < GetClientHealth(Ent) && TF2_IsPlayerInCondition(Ent, TFCond_Disguised) && chainDistance < 512.0)
							{
								buttons |= IN_ATTACK;
							}
							else if(GetClientHealth(client) > GetClientHealth(Ent) && TF2_IsPlayerInCondition(Ent, TFCond_Disguised) && chainDistance < 128.0 && IsWeaponSlotActive(client, 2))
							{
								buttons |= IN_ATTACK;
							}
							
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
							
							if(ClientViews(Ent, client, 0.9) && GetClientButtons(Ent) == IN_ATTACK && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_HasTheFlag(client))
							{
								buttons |= IN_ATTACK2;
							}
							else if(ClientViews(Ent, client, 0.9) && GetClientButtons(Ent) == IN_ATTACK && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && !TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_HasTheFlag(client))
							{
								buttons |= IN_ATTACK2;
							}
							else if(!TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked) && ClientViews(client, Ent))
							{
								buttons |= IN_ATTACK;
							}
							
							if(TF2_IsPlayerInCondition(client, TFCond_Cloaked) && chainDistance < 300.0)
							{
								g_bHideFromTheTarget[client] = true;
							}
							else if(!g_bHealthIsLow[client] && TF2_IsPlayerInCondition(client, TFCond_Disguised) && !TF2_IsPlayerInCondition(client, TFCond_Cloaked))
							{
								if(GetClientButtons(Ent) != IN_ATTACK && chainDistance < 300.0 && !g_bHideFromTheTarget[client])
								{
									float flBotAng[3], flTargetAng[3];
									GetClientEyeAngles(client, flBotAng);
									GetClientEyeAngles(Ent, flTargetAng);
									int iAngleDiff = AngleDifference(flBotAng[1], flTargetAng[1]);
									
									if(ClientViews(Ent, client, 0.7))
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
								else if(ClientViews(Ent, client, 0.9) && GetClientButtons(Ent) == IN_ATTACK)
								{
									g_bHideFromTheTarget[client] = true;
								}
							}
						}
						
						if(class == TFClass_Pyro)
						{
							if(IsWeaponSlotActive(client, 0) && chainDistance < 150.0 && (PrimID != 594 && PrimID != 40 && PrimID != 1146))
							{
								if(g_flPyroAirblastTimer[client] < GetGameTime())
								{
									buttons |= IN_ATTACK2;
									
									g_flPyroAirblastTimer[client] = GetGameTime() + 10.0;
								}
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
											
											vel = moveForward(vel,300.0);
											
											g_bPathFinding[client] = false;
											
											if(iAngleDiff > 90)
											{
												vel = moveRight(vel,300.0);
											}
											else if(iAngleDiff < -90)
											{
												vel = moveLeft(vel,300.0);
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
						decl Float:direction[3];
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
							new Float:wallDistance;
							wallDistance = GetVectorDistance(clientEyes,targetEyes);
							if(wallDistance < 75.0 && !TF2_IsPlayerInCondition(client, TFCond_Zoomed))
							{
								g_bJump[client] = true;
							}
						}
						
						CloseHandle(Wall);
					}
					else
					{
						if(class == TFClass_Heavy)
						{
							if(g_flHeavySpinMinigunTimer[client] > GetGameTime())
							{
								if(!g_bHideFromTheTarget[client])
								{
									buttons |= IN_ATTACK2;
								}
							}
						}
						
						if(class == TFClass_Heavy && class == TFClass_Soldier)
						{
							if(g_bHealthIsLow[client])
							{
								if(!IsWeaponSlotActive(client, 2) && (MeleeID == 775 || MeleeID == 331))
								{
									EquipWeaponSlot(client, 2);
								}
							}
							
							if(g_bAmmoIsLow[client])
							{
								if(!IsWeaponSlotActive(client, 2) && (MeleeID == 775 || MeleeID == 239 || MeleeID == 426))
								{
									EquipWeaponSlot(client, 2);
								}
							}
						}
					}
				}

				if(class == TFClass_Medic)
				{
					if(Ent != -1)
					{
						decl Float:angle[3],Float:mediceye[3],Float:teammateeye[3],Float:targetEyes[3];
						GetClientEyePosition(Ent, targetEyes);
						GetClientEyeAngles(client, mediceye);
						GetClientEyePosition(Ent, teammateeye);
						GetEntPropVector(Ent, Prop_Data, "m_angRotation", angle);
						GetClientEyeAngles(Ent, g_flLookAtLastKnownEnemyPos[client]);
						
						g_bMedicAllHaveTasks[client] = true;
						
						new Float:location_check[3];
						GetClientAbsOrigin(client, location_check);

						new Float:chainDistance;
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
						
						for (new search = 1; search <= MaxClients; search++)
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
							if(g_bJump[client] && !TF2_IsPlayerInCondition(client, TFCond_Zoomed))
							{
								g_bJump[client] = true;
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
							for (new search = 1; search <= MaxClients; search++)
							{
								if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) == GetClientTeam(search)) && GetHealth(search) < 125.0)
								{
									new Float:searchOrigin[3];
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
									new Float:searchOrigin[3];
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

public Action:BotDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(botid))
	{
		GetClientAbsOrigin(botid, g_flLastDiedArea[botid]);
		
		g_bBotIsDied[botid] = true;
		
		for (new enemy = 1; enemy <= MaxClients; enemy++)
		{
			if (IsClientInGame(enemy) && IsPlayerAlive(enemy) && enemy != botid && (GetClientTeam(botid) != GetClientTeam(enemy)))
			{
				for (new friend = 1; friend <= MaxClients; friend++)
				{
					if (IsClientInGame(friend) && IsPlayerAlive(friend) && friend != botid && (GetClientTeam(botid) == GetClientTeam(friend)))
					{
						new Float:friendOrigin[3];
						new Float:botOrigin[3];
						new Float:attackerOrigin[3];
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

public Action:BotHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	g_bPickRandomSniperSpot[botid] = true;
	g_flSniperRange[botid] = GetRandomFloat(75.0, 125.0);
	
	if(IsValidClient(botid))
	{
		if(IsPlayerAlive(botid))
		{
			for (new enemy = 1; enemy <= MaxClients; enemy++)
			{
				if (IsClientInGame(enemy) && IsPlayerAlive(enemy) && enemy != botid && (GetClientTeam(botid) != GetClientTeam(enemy)))
				{
					GetClientEyePosition(enemy, g_flLookAtLastKnownEnemyPos[botid]);
					
					for (new friend = 1; friend <= MaxClients; friend++)
					{
						if (IsClientInGame(friend) && IsPlayerAlive(friend) && friend != botid && (GetClientTeam(botid) == GetClientTeam(friend)))
						{
							new Float:friendOrigin[3];
							new Float:botOrigin[3];
							new Float:attackerOrigin[3];
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

public Action:OnTakeDamageAlive(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(g_bAfkbot[client] || IsFakeClient(client))
	{
		g_flLookPos[client] = damagePosition;
		EnemyAlertTimer[client] = GetGameTime() + 10.0;
	}
}

stock int GetTeamsCount(int team)
{
  int count, i; count = 0;

  for(i = 1; i <= MaxClients; i++)
    if(IsClientInGame(i) && GetClientTeam(i) == team)
      count++;

  return count;
}

stock int GetAFKCount()
{
  int count, i; count = 0;

  for(i = 1; i <= MaxClients; i++)
    if(IsClientInGame(i) && g_bAfkbot[i] && !IsFakeClient(i))
      count++;

  return count;
}

public Action:BotSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new botid = GetClientOfUserId(GetEventInt(event, "userid"));
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if(IsValidClient(botid) && g_bAfkbot[botid])
	{
		g_bISeeSpy[botid] = false;
		g_bSpyAlert[botid] = false;
		g_bMoveSentry[botid] = false;
		g_bUseTeleporter[botid] = false;
		g_bHideFromTheTarget[botid] = false;
		g_bMakeStickyTrap[botid] = false;
		g_bMoveSentry[botid] = false;
		g_flSniperRange[botid] = GetRandomFloat(75.0, 125.0);
		g_iPipeCount[botid] = 0;
		g_bPickUnUsedSentrySpot[botid] = true;
		GetClientAbsOrigin(botid, g_flSpawnLocation[botid]);
		
		if(g_bBotIsDied[botid])
		{
			int randomFLDA = GetRandomInt(1,100);
			if(randomFLDA <= GetConVarFloat(AFKBOT_FindLastDiedAreaChance))
			{
				g_bFindLastDiedArea[botid] = true;
				g_bHuntEnemiens[botid] = true;
			}
			else
			{
				g_bFindLastDiedArea[botid] = false;
				g_bHuntEnemiens[botid] = false;
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
		
		if(StrContains(currentMap, "ctf_" , false) != -1)
		{
			g_bHealthIsLow[botid] = true;
		}
		
		if(IsPlayerAlive(botid))
		{
			new changeclass = GetRandomInt(1, 100);
			if(changeclass <= 35)
			{
				new random = GetRandomInt(1,9);
				switch(random)
				{
					case 1:
			    	{
			    		TF2_SetPlayerClass(botid, TFClass_Scout);
					}
					case 2:
			    	{
			    		TF2_SetPlayerClass(botid, TFClass_Soldier);
					}
					case 3:
			   	 	{
			    		TF2_SetPlayerClass(botid, TFClass_Pyro);
					}
					case 4:
			    	{
			    		TF2_SetPlayerClass(botid, TFClass_DemoMan);
					}
					case 5:
			    	{
			    		TF2_SetPlayerClass(botid, TFClass_Heavy);
					}
					case 6:
			 	  	{
			    		TF2_SetPlayerClass(botid, TFClass_Engineer);
					}
					case 7:
			   		{
			    		TF2_SetPlayerClass(botid, TFClass_Medic);
					}
					case 8:
			   		{
			  		 	TF2_SetPlayerClass(botid, TFClass_Sniper);
					}
					case 9:
			  	 	{
			    		TF2_SetPlayerClass(botid, TFClass_Spy);
					}
				}
				if(IsValidClient(botid))
				{
					TF2_RespawnPlayer(botid);
				}
			}
		}
	}
}

stock GetNearestEnemiens(Float:vecOrigin_center[3], const client)
{
	decl Float:vecOrigin_edict[3];
	new Float:distance = -1.0;
	new closestEdict = -1;
	for(new i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) != GetClientTeam(client))
		{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
		}
	}
	return closestEdict;
}

stock GetPlayersHasTheFlag(float vecOrigin_center[3], int client)
{
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
		if(TF2_HasTheFlag(i))
		{
			float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				closestEdict = i;
			}
		}
	}
	return closestEdict;
}

stock GetPlayersWhileShooting(float vecOrigin_center[3], int client)
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
		if(GetClientTeam(i) != GetClientTeam(client) && GetClientButtons(i) == IN_ATTACK)
		{
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

stock void PrepareForBattle(int client)
{
	//
}

public Action:ResetAttackTimer(Handle:timer)
{
	AttackTimer = INVALID_HANDLE;
}

public Action:ResetSnipeTimer(Handle:timer)
{
	SnipeTimer = INVALID_HANDLE;
}

public Action:ResetRepeartAttackTimer(Handle:timer)
{
	RepeartAttackTimer = INVALID_HANDLE;
}

bool:IsValidClient( client ) 
{
	if(!(1 <= client <= MaxClients ) || !IsClientInGame(client)) 
		return false; 
	return true; 
}

public Action:TellYourInAFKMODE(Handle:timer,any:userid)
{
	for(new client=1;client<=MaxClients;client++)
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

public Action:EndSlowThink(Handle:timer, client)
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

stock Client_GetClosest(Float:vecOrigin_center[3], const client)
{
	decl Float:vecOrigin_edict[3];
	decl Float:vecOrigin_edict2[3];
	decl Float:aimpos[3];
	decl Float:client_origin[3];
	new Float:distance = -1.0;
	new TeamMateBaseHealth = 99999;
	new closestEdict = -1;
	for(new i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict2);
		GetEntPropVector(client, Prop_Data, "m_vecOrigin", client_origin);
		new Float:PlayerDistance;
		GetClientEyePosition(i, vecOrigin_edict);
		GetAimOrigin(client, aimpos);
		PlayerDistance = GetVectorDistance(client_origin, vecOrigin_edict2);
		new TFClassType:medic = TF2_GetPlayerClass(client);
		new CurrentHealth = GetEntProp(i, Prop_Send, "m_iHealth");
		new MaxHealth = GetEntProp(i, Prop_Data, "m_iMaxHealth");
		if(GetClientTeam(i) == GetClientTeam(client) && medic == TFClass_Medic || !g_bSpyAlert[i] && GetClientTeam(i) != GetClientTeam(client) && TF2_IsPlayerInCondition(i, TFCond_Disguised) && !TF2_IsPlayerInCondition(i, TFCond_Cloaked) && !TF2_IsPlayerInCondition(i, TFCond_HalloweenGhostMode))
		{
			new TFClassType:class = TF2_GetPlayerClass(i);
			// Cloaked and Disguised players should be now undetectable(3.2)
			if(CurrentHealth >= MaxHealth && class == TFClass_Medic || TF2_IsPlayerInCondition(i, TFCond_Cloaked) || GetHealth(i) >= 125.0 && TF2_IsPlayerInCondition(i, TFCond_Disguised) || class == TFClass_Engineer && IsWeaponSlotActive(i,2) && GetHealth(i) >= 125.0 || GetHealth(i) >= 125.0 && TF2_IsPlayerInCondition(i, TFCond_Zoomed) || TF2_IsPlayerInCondition(i, TFCond_Teleporting) || TF2_IsPlayerInCondition(i, TFCond_Disguising))
				continue;
			if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			{
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				new iHealth = GetEntProp(i, Prop_Send, "m_iHealth");
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
		else if(medic == TFClass_Sniper && ClientViews(client, i) && GetClientTeam(i) != GetClientTeam(client))
		{
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Cloaked) && (TF2_IsPlayerInCondition(i, TFCond_OnFire) || TF2_IsPlayerInCondition(i, TFCond_Bleeding) || TF2_IsPlayerInCondition(i, TFCond_Milked) || TF2_IsPlayerInCondition(i, TFCond_Jarated))) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Disguised)) || TF2_IsPlayerInCondition(i, TFCond_Taunting) || TF2_IsPlayerInCondition(i, TFCond_HalloweenGhostMode))
				continue;
			if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
			{
				if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
				{
					if(PlayerDistance < 1000.0)
					{
						new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
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
							decl Float:NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							new Float:edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
						else if(targetclass == TFClass_Medic && TF_GetUberLevel(client) > 50.0)
						{
							decl Float:NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							new Float:edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
						else if(targetclass == TFClass_Spy)
						{
							decl Float:NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							new Float:edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
						else if(targetclass == TFClass_Medic && TF_GetUberLevel(client) < 50.0)
						{
							decl Float:NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							new Float:edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
							if((edict_distance < distance) || (distance == -1.0))
							{
								distance = edict_distance;
								closestEdict = i;
							}
						}
						else
						{
							decl Float:NearestToCroshair[3];
							GetAimOrigin(client, NearestToCroshair);
							new Float:edict_distance = GetVectorDistance(NearestToCroshair, vecOrigin_edict);
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
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
		else if(medic == TFClass_Spy && GetClientTeam(i) != GetClientTeam(client))
		{	
			// Cloaked and Disguised players should be now undetectable(3.2)
			if (TF_IsUberCharge(client) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Cloaked) && (TF2_IsPlayerInCondition(i, TFCond_OnFire) || TF2_IsPlayerInCondition(i, TFCond_Bleeding) || TF2_IsPlayerInCondition(i, TFCond_Milked) || TF2_IsPlayerInCondition(i, TFCond_Jarated))) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Disguised)) || TF2_IsPlayerInCondition(i, TFCond_Taunting) || TF2_IsPlayerInCondition(i, TFCond_HalloweenGhostMode))
				continue;
			if(GetVectorDistance(vecOrigin_center, vecOrigin_edict) < 200.0 && (IsPointVisible(vecOrigin_center, vecOrigin_edict) && IsPointVisible2(vecOrigin_center, vecOrigin_edict)) || (IsPointVisible(vecOrigin_center, vecOrigin_edict2) && IsPointVisible2(vecOrigin_center, vecOrigin_edict2)))
			{
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
			else if(ClientViews(client, i) && (IsPointVisible(vecOrigin_center, vecOrigin_edict) && IsPointVisible2(vecOrigin_center, vecOrigin_edict)) || (IsPointVisible(vecOrigin_center, vecOrigin_edict2) && IsPointVisible2(vecOrigin_center, vecOrigin_edict2)))
			{
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
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
			if (TF_IsUberCharge(client) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Cloaked) && (TF2_IsPlayerInCondition(i, TFCond_OnFire) || TF2_IsPlayerInCondition(i, TFCond_Bleeding) || TF2_IsPlayerInCondition(i, TFCond_Milked) || TF2_IsPlayerInCondition(i, TFCond_Jarated))) || (!g_bISeeSpy[client] && !g_bSpyAlert[i] && TF2_IsPlayerInCondition(i, TFCond_Disguised)) || TF2_IsPlayerInCondition(i, TFCond_Taunting) || TF2_IsPlayerInCondition(i, TFCond_HalloweenGhostMode))
				continue;
			if(IsPointVisible(vecOrigin_center, vecOrigin_edict))
			{
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
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

stock Client_GetClosest2(Float:vecOrigin_center[3], const client)
{
	decl Float:vecOrigin_edict[3];
	new Float:distance = -1.0;
	new closestEdict = -1;
	for(new i=1;i<=MaxClients;i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || (i == client))
			continue;
		GetClientEyePosition(i, vecOrigin_edict);
		if(GetClientTeam(i) == GetClientTeam(client))
		{
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

stock TF2_GetNumHealers(client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

stock GetNearestClient(Float:vecOrigin_center[3], const client)
{    
	decl Float:vecOrigin_edict[3];
	new Float:distance = -1.0;
	new closestEdict = -1;
	for(new i=1;i<=MaxClients;i++)
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
				new Float:edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
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

public int FindNearestAmmo(int client)
{
	decl String:ClassName[32];
	decl Float:clientOrigin[3];
	decl Float:entityOrigin[3];
	new Float:distance = -1.0;
	new nearestEntity = -1;
	for(new x = 0; x <= GetMaxEntities(); x++)
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
				
				new Float:edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
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
	decl String:ClassName[32];
	decl Float:clientOrigin[3];
	decl Float:entityOrigin[3];
	new Float:distance = -1.0;
	new nearestEntity = -1;
	for(new x = 0; x <= GetMaxEntities(); x++)
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
				
				new Float:edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
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
	decl Float:clientOrigin[3];
	decl Float:entityOrigin[3];
	new Float:distance = -1.0;
	new nearestEntity = -1;
	new entity = -1;
	while((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
			GetClientAbsOrigin(client, clientOrigin);
			
			new Float:edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				nearestEntity = entity;
			}
		}
	}
	return nearestEntity;
}

stock FindEntityByTargetname(const String:targetname[], const String:classname[])
{
  decl String:namebuf[32];
  new index = -1;
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

float StuckTimer[MAXPLAYERS + 1];

float g_flFindPathTimer[MAXPLAYERS + 1];
stock void TF2_FindPath(int client, float flTargetVector[3])
{
	if(g_flFindPathTimer[client] < GetGameTime())
	{
		if (!(PF_Exists(client)))
		{
			PF_Create(client, 24.0, 64.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, GetConVarFloat(AFKBOT_PathTimer), 1.5);
			
			PF_EnableCallback(client, PFCB_Approach, Approach);
			
			PF_EnableCallback(client, PFCB_ClimbUpToLedge, PF_ClibmUpToLedge);
		}
		
		if(!PF_IsPathToVectorPossible(client, flTargetVector))
		{
			if(StuckTimer[client] < GetGameTime())
			{
				int random = GetRandomInt(1,3);
				if(random == 1)
				{
					FakeClientCommandThrottled(client, "say I'm stuck");
				}
				else if(random == 2)
				{
					FakeClientCommandThrottled(client, "say Help me");
				}
				else if(random == 3)
				{
					FakeClientCommandThrottled(client, "say Navigation Problem");
				}
				
				StuckTimer[client] = GetGameTime() + 90.0;
			}
			
			return;
		}
		
		PF_SetGoalVector(client, flTargetVector);
		
		if(g_bPathFinding[client])
		{
			PF_StartPathing(client);
		}
		else
		{
			PF_StopPathing(client);
		}
		
		g_flFindPathTimer[client] = GetGameTime() + GetConVarFloat(AFKBOT_PathTimer);
	}
}

stock void TF2_FindSniperSpot(int client)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	float clientEyes[3];
	new Ent = Client_GetClosest(clientEyes, client);
	GetClientEyePosition(client, clientEyes);
	float bestsniperspot[3];
	if(g_flSniperChangeSpotTimer[client] < GetGameTime())
	{
		if(Ent == -1)
		{
			g_bPickRandomSniperSpot[client] = true;
		}
		if(StrContains(currentMap, "ctf_" , false) != -1)
		{
			g_flSniperChangeSpotTimer[client] = GetGameTime() + GetRandomFloat(15.0, 25.0);
		}
		else
		{
			g_flSniperChangeSpotTimer[client] = GetGameTime() + GetRandomFloat(10.0, 20.0);
		}
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
				
				if(g_bPickRandomSniperSpot[client])
				{
					g_flRandomSniperSpotPos[client][0] = capturepointpos[0] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][1] = capturepointpos[1] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][2] = capturepointpos2[2] + 2000.0;
					
					NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
					if(area != NavArea_Null)
					{
						if(!area.HasAttributes(NAV_MESH_DONT_HIDE) && !area.HasAttributes(NAV_MESH_AVOID) && !HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
						{
							area.GetRandomPoint(g_flSniperSpotPos[client]);
							
							bestsniperspot[0] = g_flSniperSpotPos[client][0];
							bestsniperspot[1] = g_flSniperSpotPos[client][1];
							bestsniperspot[2] = g_flSniperSpotPos[client][2] + 65.0;
							
							if(IsPointVisible(bestsniperspot, capturepointpos) && PF_IsPathToVectorPossible(client, g_flSniperSpotPos[client]))
							{
								g_bPickRandomSniperSpot[client] = false;
							}
							else
							{
								g_bPickRandomSniperSpot[client] = true;
							}
						}
						else
						{
							g_bPickRandomSniperSpot[client] = true;
						}
					}
					else
					{
						g_bPickRandomSniperSpot[client] = true;
					}
				}
			}
		}
		if(StrContains(currentMap, "pl_" , false) != -1)
		{
			int payload;
			if((payload = FindEntityByClassname(payload, "item_teamflag")) != INVALID_ENT_REFERENCE)
			{
				float capturepointpos[3];
				GetEntPropVector(payload, Prop_Send, "m_vecOrigin", capturepointpos);
				
				if(g_bPickRandomSniperSpot[client])
				{
					g_flRandomSniperSpotPos[client][0] = capturepointpos[0] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][1] = capturepointpos[1] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][2] = capturepointpos[2] + 2000.0;
					
					NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
					if(area != NavArea_Null)
					{
						if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
						{
							area.GetRandomPoint(g_flSniperSpotPos[client]);
							
							bestsniperspot[0] = g_flSniperSpotPos[client][0];
							bestsniperspot[1] = g_flSniperSpotPos[client][1];
							bestsniperspot[2] = g_flSniperSpotPos[client][2] + 65.0;
							
							if(IsPointVisible(bestsniperspot, capturepointpos) && PF_IsPathToVectorPossible(client, g_flSniperSpotPos[client]))
							{
								g_bPickRandomSniperSpot[client] = false;
							}
							else
							{
								g_bPickRandomSniperSpot[client] = true;
							}
						}
						else
						{
							g_bPickRandomSniperSpot[client] = true;
						}
					}
					else
					{
						g_bPickRandomSniperSpot[client] = true;
					}
				}
			}
		}
		if(StrContains(currentMap, "ctf_" , false) != -1)
		{
			int flag;
			while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
				if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
				{
					float capturepointpos[3];
					float capturepointpos2[3];
					GetEntPropVector(flag, Prop_Send, "m_vecOrigin", capturepointpos);
					GetEntPropVector(flag, Prop_Send, "m_vecOrigin", capturepointpos2);
					
					int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
					
					capturepointpos[2] += GetRandomFloat(200.0, 400.0);
					
					if(g_bPickRandomSniperSpot[client])
					{
						if(FlagStatus == 0)
						{
							g_flRandomSniperSpotPos[client][0] = g_flSpawnLocation[client][0] + GetRandomFloat(-3000.0, 3000.0);
							g_flRandomSniperSpotPos[client][1] = g_flSpawnLocation[client][1] + GetRandomFloat(-3000.0, 3000.0);
							g_flRandomSniperSpotPos[client][2] = clientEyes[2];
							
							bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
							bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
							bestsniperspot[2] = clientEyes[2];
							
							NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 500000.0, false, false, GetClientTeam(client));
							if(area != NavArea_Null)
							{
								if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
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
						else if(FlagStatus == 1)
						{
							g_flRandomSniperSpotPos[client][0] = capturepointpos[0] + GetRandomFloat(-1500.0, 1500.0);
							g_flRandomSniperSpotPos[client][1] = capturepointpos[1] + GetRandomFloat(-1500.0, 1500.0);
							g_flRandomSniperSpotPos[client][2] = capturepointpos2[2] + 50.0;
							
							bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
							bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
							bestsniperspot[2] = clientEyes[2];
							
							NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
							if(area != NavArea_Null)
							{
								if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
								{
									if(area.IsVisible(g_flClientEyePos[client], capturepointpos2))
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
							else
							{
								g_bPickRandomSniperSpot[client] = true;
							}
						}
						else if(FlagStatus == 2)
						{
							if(GetClientTeam(client) == 2)
							{
								g_flRandomSniperSpotPos[client][0] = g_flBluFlagCapPoint[0] + GetRandomFloat(-2000.0, 2000.0);
								g_flRandomSniperSpotPos[client][1] = g_flBluFlagCapPoint[1] + GetRandomFloat(-2000.0, 2000.0);
								g_flRandomSniperSpotPos[client][2] = g_flBluFlagCapPoint[2] + 50.0;
								
								bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
								bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
								bestsniperspot[2] = clientEyes[2];
								
								NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
								if(area != NavArea_Null)
								{
									if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
									{
										if(area.IsVisible(g_flClientEyePos[client], capturepointpos2))
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
								else
								{
									g_bPickRandomSniperSpot[client] = true;
								}
							}
							else
							{
								g_flRandomSniperSpotPos[client][0] = g_flRedFlagCapPoint[0] + GetRandomFloat(-2000.0, 2000.0);
								g_flRandomSniperSpotPos[client][1] = g_flRedFlagCapPoint[1] + GetRandomFloat(-2000.0, 2000.0);
								g_flRandomSniperSpotPos[client][2] = g_flRedFlagCapPoint[2] + 50.0;
								
								bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
								bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
								bestsniperspot[2] = clientEyes[2];
								
								NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
								if(area != NavArea_Null)
								{
									if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
									{
										if(IsPointVisible(bestsniperspot, g_flRedFlagCapPoint))
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
								else
								{
									g_bPickRandomSniperSpot[client] = true;
								}
							}
						}
					}
				}
			}
		}
		if(StrContains(currentMap, "plr_" , false) != -1)
		{
			int payload;
			if((payload = FindEntityByClassname(payload, "item_teamflag")) != INVALID_ENT_REFERENCE)
			{
				float capturepointpos[3];
				GetEntPropVector(payload, Prop_Send, "m_vecOrigin", capturepointpos);
				
				if(g_bPickRandomSniperSpot[client])
				{
					g_flRandomSniperSpotPos[client][0] = capturepointpos[0] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][1] = capturepointpos[1] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][2] = capturepointpos[2];
					
					bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
					bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
					bestsniperspot[2] = clientEyes[2];
					
					NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
					if(area != NavArea_Null)
					{
						if(IsPointVisible(bestsniperspot, capturepointpos))
						{
							if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
							{
								area.GetRandomPoint(g_flSniperSpotPos[client]);
								
								g_bPickRandomSniperSpot[client] = false;
							}
							else
							{
								g_bPickRandomSniperSpot[client] = true;
							}
						}
						else
						{
							g_bPickRandomSniperSpot[client] = true;
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

stock void TF2_FindSentrySpot(int client)
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	float clientEyes[3];
	GetClientEyePosition(client, clientEyes);
	float bestsniperspot[3];
	if(TF2_GetPlayerClass(client) == TFClass_Engineer)
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
						if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
						{
							if(IsPointVisible(bestsniperspot, capturepointpos) && GetVectorDistance(bestsniperspot, capturepointpos) < 1300.0)
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
					else
					{
						g_bPickRandomSniperSpot[client] = true;
					}
				}
			}
		}
		if(StrContains(currentMap, "pl_" , false) != -1)
		{
			int payload;
			if((payload = FindEntityByClassname(payload, "item_teamflag")) != INVALID_ENT_REFERENCE)
			{
				float capturepointpos[3];
				GetEntPropVector(payload, Prop_Send, "m_vecOrigin", capturepointpos);
				
				if(g_bPickUnUsedSentrySpot[client])
				{
					g_flRandomSniperSpotPos[client][0] = capturepointpos[0] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][1] = capturepointpos[1] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][2] = capturepointpos[2] + 200.0;
					
					bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
					bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
					bestsniperspot[2] = g_flClientPos[client][2];
					
					NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
					if(area != NavArea_Null)
					{
						if(GetVectorDistance(bestsniperspot, capturepointpos) < 1300.0)
						{
							if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
							{
								area.GetRandomPoint(g_bSentryBuildPos[client]);
								
								if(IsPointVisible(g_bSentryBuildPos[client], capturepointpos) && PF_IsPathToVectorPossible(client, g_bSentryBuildPos[client]))
								{
									g_bSentryBuildAngle[client][0] = capturepointpos[0];
									g_bSentryBuildAngle[client][1] = capturepointpos[1];
									g_bSentryBuildAngle[client][2] = capturepointpos[2];
									
									g_bPickUnUsedSentrySpot[client] = false;
								}
								else
								{
									g_bPickUnUsedSentrySpot[client] = true;
								}
							}
							else
							{
								g_bPickUnUsedSentrySpot[client] = true;
							}
						}
						else
						{
							g_bPickUnUsedSentrySpot[client] = true;
						}
					}
					else
					{
						g_bPickUnUsedSentrySpot[client] = true;
					}
				}
			}
		}
		if(StrContains(currentMap, "ctf_" , false) != -1)
		{
			int flag;
			while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
			{
				int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
				if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
				{
					float capturepointpos[3];
					float capturepointpos2[3];
					GetEntPropVector(flag, Prop_Send, "m_vecOrigin", capturepointpos);
					GetEntPropVector(flag, Prop_Send, "m_vecOrigin", capturepointpos2);
					
					int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
					
					capturepointpos[2] += GetRandomFloat(200.0, 400.0);
					
					if(g_bPickUnUsedSentrySpot[client])
					{
						if(FlagStatus == 0 || FlagStatus == 2)
						{
							g_flRandomSniperSpotPos[client][0] = g_flSpawnLocation[client][0] + GetRandomFloat(-3000.0, 3000.0);
							g_flRandomSniperSpotPos[client][1] = g_flSpawnLocation[client][1] + GetRandomFloat(-3000.0, 3000.0);
							g_flRandomSniperSpotPos[client][2] = clientEyes[2];
							
							bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
							bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
							bestsniperspot[2] = clientEyes[2];
							
							NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 500000.0, false, false, GetClientTeam(client));
							if(area != NavArea_Null)
							{
								if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
								{
									if(GetVectorDistance(bestsniperspot, g_flSpawnLocation[client]) > 1500.0)
									{
										area.GetRandomPoint(g_bSentryBuildPos[client]);
										
										g_bPickUnUsedSentrySpot[client] = false;
									}
									else
									{
										g_bPickUnUsedSentrySpot[client] = false;
									}
								}
								else
								{
									g_bPickUnUsedSentrySpot[client] = true;
								}
							}
							else
							{
								g_bPickUnUsedSentrySpot[client] = true;
							}
						}
						
						if(FlagStatus == 1)
						{
							g_flRandomSniperSpotPos[client][0] = capturepointpos[0] + GetRandomFloat(-1500.0, 1500.0);
							g_flRandomSniperSpotPos[client][1] = capturepointpos[1] + GetRandomFloat(-1500.0, 1500.0);
							g_flRandomSniperSpotPos[client][2] = capturepointpos2[2] + 50.0;
							
							bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
							bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
							bestsniperspot[2] = clientEyes[2];
							
							NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
							if(area != NavArea_Null)
							{
								if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
								{
									if(IsPointVisible(bestsniperspot, capturepointpos))
									{
										area.GetRandomPoint(g_bSentryBuildPos[client]);
										
										g_bPickUnUsedSentrySpot[client] = false;
									}
									else
									{
										g_bPickUnUsedSentrySpot[client] = false;
									}
								}
								else
								{
									g_bPickUnUsedSentrySpot[client] = true;
								}
							}
							else
							{
								g_bPickUnUsedSentrySpot[client] = true;
							}
						}
					}
				}
			}
		}
		if(StrContains(currentMap, "plr_" , false) != -1)
		{
			int payload;
			if((payload = FindEntityByClassname(payload, "item_teamflag")) != INVALID_ENT_REFERENCE)
			{
				float capturepointpos[3];
				GetEntPropVector(payload, Prop_Send, "m_vecOrigin", capturepointpos);
				
				if(g_bPickRandomSniperSpot[client])
				{
					g_flRandomSniperSpotPos[client][0] = capturepointpos[0] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][1] = capturepointpos[1] + GetRandomFloat(-2000.0, 2000.0);
					g_flRandomSniperSpotPos[client][2] = capturepointpos[2];
					
					bestsniperspot[0] = g_flRandomSniperSpotPos[client][0];
					bestsniperspot[1] = g_flRandomSniperSpotPos[client][1];
					bestsniperspot[2] = clientEyes[2];
					
					NavArea area = TheNavMesh.GetNearestNavArea_Vec(g_flRandomSniperSpotPos[client], true, 50000.0, false, false, GetClientTeam(client));
					if(area != NavArea_Null)
					{
						if(IsPointVisible(bestsniperspot, capturepointpos))
						{
							if(!HasTFAttributes(area, BLUE_SPAWN_ROOM) && !HasTFAttributes(area, RED_SPAWN_ROOM))
							{
								area.GetRandomPoint(g_flSniperSpotPos[client]);
								
								g_bPickRandomSniperSpot[client] = false;
							}
							else
							{
								g_bPickRandomSniperSpot[client] = true;
							}
						}
						else
						{
							g_bPickRandomSniperSpot[client] = true;
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
	new Ent = Client_GetClosest(g_flClientEyePos[client], client);
	
	if(Ent != -1)
	{
		PathAim[client] = false;
		return;
	}
	else if(TF2_HasTheFlag(client) || TF2_IsPlayerInCondition(client, TFCond_Disguised) || TF2_IsPlayerInCondition(client, TFCond_Cloaked) || (TF2_GetPlayerClass(client) == TFClass_Heavy && g_flHeavySpinMinigunTimer[client] > GetGameTime()))
	{
		PathAim[client] = true;
		return;
	}
	else
	{
		PathAim[client] = false;
	}
	
	if(TF2_GetPlayerClass(client) != TFClass_Spy && Ent == -1 && !g_bMakeStickyTrap[client])
	{
		float RandomizeAim = GetRandomFloat(GetConVarFloat(AFKBOT_MinAimSpeed), GetConVarFloat(AFKBOT_MaxAimSpeed));
		if(TF2_GetPlayerClass(client) == TFClass_Engineer && !g_bSentryBuilded[client] && g_bBuildSentry[client] && IsPointVisible(g_flClientEyePos[client], g_bSentryBuildAngle[client]))
		{
			TF2_LookAtPos(client, g_bSentryBuildAngle[client], RandomizeAim);
		}
		else
		{
			for (new search = 1; search <= MaxClients; search++)
			{
				if (IsClientInGame(search) && IsPlayerAlive(search) && search != client)
				{
					float playerOrigin[3];
					GetClientEyePosition(search, playerOrigin);
					
					if(IsPointVisible(g_flClientEyePos[client], playerOrigin) && ClientViews(client, search, 1000.0, 0.7) && ClientViews(search, client, 1000.0, 0.99) && GetVectorDistance(g_flClientEyePos[client], playerOrigin) < 1000.0)
					{
						g_bLookAround[client] = false;
						
						if(g_bIsSetupTime == 1)
						{
							if(g_flVoiceNoTimer[client] < GetGameTime())
							{
								FakeClientCommandThrottled(client, "taunt");
								
								g_flVoiceNoTimer[client] = GetGameTime() + GetRandomFloat(10.0, 20.0);
							}
							
							TF2_LookAtPos(client, playerOrigin, RandomizeAim);
						}
						else
						{
							TF2_LookAtPos(client, playerOrigin, RandomizeAim);
						}
					}
					else if(IsPointVisible(g_flClientEyePos[client], playerOrigin) && ClientViews(client, search, 1000.0, 0.7) && GetVectorDistance(g_flClientEyePos[client], playerOrigin) < 200.0 && TF2_IsPlayerInCondition(search, TFCond_Taunting))
					{
						g_bLookAround[client] = false;
						
						if(g_flVoiceNoTimer[client] < GetGameTime())
						{
							FakeClientCommandThrottled(client, "taunt");
							
							g_flVoiceNoTimer[client] = GetGameTime() + GetRandomFloat(1.0, 3.0);
						}
						
						TF2_LookAtPos(client, playerOrigin, RandomizeAim);
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
				area.GetCenter(SelectRandomNav);
			}
			
			if(IsPointVisible(g_flClientEyePos[client], SelectRandomNav) && GetVectorDistance(g_flClientEyePos[client], SelectRandomNav) > 400.0)
			{
				SelectedLookPos[0] = SelectRandomNav[0];
				SelectedLookPos[1] = SelectRandomNav[1];
				SelectedLookPos[2] = SelectRandomNav[2] + (g_flClientEyePos[client][2] - g_flClientPos[client][2]);
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
	else if(TF2_GetPlayerClass(client) == TFClass_Spy && !g_bMakeStickyTrap[client])
	{
		float RandomizeAim = GetRandomFloat(GetConVarFloat(AFKBOT_MinAimSpeed), GetConVarFloat(AFKBOT_MaxAimSpeed));
		for (new search = 1; search <= MaxClients; search++)
		{
			if (IsClientInGame(search) && IsPlayerAlive(search) && search != client)
			{
				float playerOrigin[3];
				GetClientEyePosition(search, playerOrigin);
				
				if(IsPointVisible(g_flClientEyePos[client], playerOrigin) && ClientViews(client, search, 1000.0, 0.7) && ClientViews(search, client, 1000.0, 0.99) && GetVectorDistance(g_flClientEyePos[client], playerOrigin) < 1000.0)
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
	new Ent = Client_GetClosest(g_flClientEyePos[client], client);
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	if(Ent == -1)
	{
		float RandomizeAimWhenZoomed = GetRandomFloat(GetConVarFloat(AFKBOT_MinAimSpeedWhenZoomed), GetConVarFloat(AFKBOT_MaxAimSpeedWhenZoomed));
		
		if(StrContains(currentMap, "pl_" , false) != -1)
		{
			int payload;
			if((payload = FindEntityByClassname(payload, "item_teamflag")) != INVALID_ENT_REFERENCE)
			{
				float capturepointpos[3];
				GetEntPropVector(payload, Prop_Send, "m_vecOrigin", capturepointpos);
				
				float SelectRandomNav[3];
				float SelectedLookPos[3];
				
				capturepointpos[0] += GetRandomFloat(-1000.0, 1000.0);
				capturepointpos[1] += GetRandomFloat(-1000.0, 1000.0);
				capturepointpos[2] += GetRandomFloat(-100.0, 100.0);
			
				NavArea area = TheNavMesh.GetNearestNavArea_Vec(capturepointpos, true, 10000.0, false, false, GetClientTeam(client));
				if(area != NavArea_Null)
				{
					area.GetRandomPoint(SelectRandomNav);
				}
				
				if(IsPointVisible(g_flClientEyePos[client], SelectRandomNav))
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
			}
		}
		else
		{
			float BestLookPos[3];
			float SelectRandomNav[3];
			float SelectedLookPos[3];
			
			GetClientEyePosition(client, BestLookPos);
			
			BestLookPos[0] += GetRandomFloat(-5000.0, 5000.0);
			BestLookPos[1] += GetRandomFloat(-5000.0, 5000.0);
			BestLookPos[2] += GetRandomFloat(-5000.0, 5000.0);
			
			NavArea area = TheNavMesh.GetNearestNavArea_Vec(BestLookPos, true, 10000.0, false, false, GetClientTeam(client));
			if(area != NavArea_Null)
			{
				area.GetRandomPoint(SelectRandomNav);
			}
			
			if(IsPointVisible(g_flClientEyePos[client], SelectRandomNav) && GetVectorDistance(g_flClientEyePos[client], SelectRandomNav) > 1500.0)
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
		}
		
		TF2_LookAtPos(client, g_flLookPos[client], RandomizeAimWhenZoomed);
	}
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
	
	if(GetVectorDistance(flPos, flGoal) > 20.0)
	{
		ScaleVector(fVel, 450.0);
	}
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
    
	if(GetVectorDistance(g_flClientPos[client], g_flGoal[client]) > 20.0)
	{
	    NormalizeVector(fVel, fVel);
    	ScaleVector(fVel, 450.0);
	}
}

public void Approach(int bot_entidx, const float dst[3])
{
    g_flGoal[bot_entidx][0] = dst[0];
    g_flGoal[bot_entidx][1] = dst[1];
    g_flGoal[bot_entidx][2] = dst[2];
	
	float AimPosition[3];
	
	if(PF_GetFutureSegment(bot_entidx, 1, AimPosition) && PathAim[bot_entidx])
	{
		float RandomizeAim = GetRandomFloat(GetConVarFloat(AFKBOT_MinAimSpeed), GetConVarFloat(AFKBOT_MaxAimSpeed));
		
		AimPosition[2] += (g_flClientEyePos[bot_entidx][2] - g_flClientPos[bot_entidx][2]);
		
		TF2_LookAtPos(bot_entidx, AimPosition, RandomizeAim);
	}
}

public bool PF_ClibmUpToLedge(int bot_entidx, const float dst[3], const float dir[3])
{
	g_bJump[bot_entidx] = true;
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

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock int GetTeamNumber(int entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum");
}

stock ClampAngle(Float:fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

//Fixed the spamming error message about chargelevel(3.7)
stock Float:TF_GetUberLevel(client)
{
	new index = GetPlayerWeaponSlot(client, 1);
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
	new index = GetPlayerWeaponSlot(client, 1);
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

stock GetAimOrigin(client, Float:hOrigin[3]) 
{
    new Float:vAngles[3], Float:fOrigin[3];
    GetClientEyePosition(client,fOrigin);
    GetClientEyeAngles(client, vAngles);

    new Handle:trace = TR_TraceRayFilterEx(fOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

    if(TR_DidHit(trace)) 
    {
        TR_GetEndPosition(hOrigin, trace);
        CloseHandle(trace);
        return 1;
    }

    CloseHandle(trace);
    return 0;
}

stock bool:ClientViews(Viewer, Target, Float:fMaxDistance=0.0, Float:fThreshold=0.60) // Stock Link : https://forums.alliedmods.net/showpost.php?p=973411&postcount=4 | By Damizean
{
    // Retrieve view and target eyes position
    decl Float:fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    decl Float:fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    decl Float:fViewDir[3];
    decl Float:fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
    decl Float:fTargetDir[3];
    decl Float:fDistance[3];
	
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
    new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
    CloseHandle(hTrace);
    
    // Done, it's visible
    return true;
}

stock bool:ClientViewsOrigin(Viewer, Float:fTargetPos[3], Float:fMaxDistance=0.0, Float:fThreshold=0.60) // Stock Link : https://forums.alliedmods.net/showpost.php?p=973411&postcount=4 | By Damizean
{
    // Retrieve view and target eyes position
    decl Float:fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    decl Float:fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    decl Float:fViewDir[3];
    decl Float:fTargetDir[3];
    decl Float:fDistance[3];
	
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
    new Handle:hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) { CloseHandle(hTrace); return false; }
    CloseHandle(hTrace);
    
    // Done, it's visible
    return true;
}

public bool:ClientViewsFilter(Entity, Mask, any:Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) return false;
    return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask) 
{
    return entity > MaxClients;
}

stock bool:IsPointVisible(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

stock bool:IsPointVisible2(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

public bool:TraceEntityFilterStuff(entity, mask)
{
	return entity > MaxClients;
}

stock bool:IsPointVisibleTank(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.99;
}

stock bool:IsPointVisibleTank2(const Float:start[3], const Float:end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.99;
}

public bool:TraceEntityFilterStuffTank(entity, mask)
{
	new maxentities = GetMaxEntities();
	return entity > maxentities;
}

public bool:Filter(entity,mask)
{
	return !(IsValidClient(entity));
}
  