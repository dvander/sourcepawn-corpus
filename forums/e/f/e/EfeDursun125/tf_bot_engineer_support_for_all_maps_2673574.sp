#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2_flag>
#include <PathFollower>

#define PLUGIN_VERSION  "1.3"

#pragma newdecls required

bool g_bSentryBuilded[MAXPLAYERS+1];
bool g_bSentryIsMaxLevel[MAXPLAYERS+1];
bool g_bSentryHealthIsFull[MAXPLAYERS+1];
bool g_bCanBuildSentryGun[MAXPLAYERS+1];
bool g_bDispenserBuilded[MAXPLAYERS+1];
bool g_bDispenserIsMaxLevel[MAXPLAYERS+1];
bool g_bDispenserHealthIsFull[MAXPLAYERS+1];
bool g_bCanBuildDispenser[MAXPLAYERS+1];

bool g_bIdleTime[MAXPLAYERS+1];

bool g_bRepairSentry[MAXPLAYERS+1];
bool g_bRepairDispenser[MAXPLAYERS+1];

bool g_bBuildSentry[MAXPLAYERS+1];
bool g_bBuildDispenser[MAXPLAYERS+1];

bool g_bHealthIsLow[MAXPLAYERS+1];
bool g_bAmmoIsLow[MAXPLAYERS+1];

float g_flWaitJumpTimer[MAXPLAYERS + 1];
float g_flChangeWeaponTimer[MAXPLAYERS + 1];

float g_flFindNearestHealthTimer[MAXPLAYERS + 1];
float g_flFindNearestAmmoTimer[MAXPLAYERS + 1];

float g_flNearestAmmoOrigin[MAXPLAYERS + 1][3];
float g_flNearestHealthOrigin[MAXPLAYERS + 1][3];

float g_flRedFlagCapPoint[3];
float g_flBluFlagCapPoint[3];

float g_flEngineerPickNewSpotTimer[MAXPLAYERS + 1];

bool g_bPickUnUsedSentrySpot[MAXPLAYERS + 1];

float g_flSentryBuildPos[MAXPLAYERS + 1][3];
float g_flSentryBuildAngle[MAXPLAYERS + 1][3];

public Plugin myinfo = 
{
	name = "[TF2] TFBot engineer support for all maps",
	author = "EfeDursun125",
	description = "Engineer bots now can play on all maps (and can work with other bots).",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
};

float g_flGoal[MAXPLAYERS + 1][3];

public void OnPluginStart()
{
	HookEvent("player_spawn", BotSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
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
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			char currentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(currentMap, sizeof(currentMap));
			TFClassType class = TF2_GetPlayerClass(client);
			if(IsPlayerAlive(client) && class == TFClass_Engineer && (StrContains(currentMap, "ctf_" , false) != -1 || StrContains(currentMap, "sd_" , false) != -1 || StrContains(currentMap, "pd_" , false) != -1 || StrContains(currentMap, "rd_" , false) != -1 || StrContains(currentMap, "plr_" , false) != -1 || StrContains(currentMap, "pass_" , false) != -1))
			{
				float clientEyes[3];
				float clientOrigin[3];
				GetClientEyePosition(client, clientEyes);
				GetClientAbsOrigin(client, clientOrigin);
				
				int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				
				int ammopack = FindNearestAmmo(client);
				int healthpack = FindNearestHealth(client);
				
				int sentry = TF2_GetObject(client, TFObject_Sentry);
				int dispenser = TF2_GetObject(client, TFObject_Dispenser);
				
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
				
				if(TF2_GetNumHealers(client) == 0 && (GetHealth(client) < (MaxHealth / 1.5) || TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Bleeding)))
				{
					g_bHealthIsLow[client] = true;
				}
				else
				{
					g_bHealthIsLow[client] = false;
				}
				
				if(g_flEngineerPickNewSpotTimer[client] < GetGameTime())
				{
					if(class == TFClass_Engineer)
					{
						g_bPickUnUsedSentrySpot[client] = true;
						
						g_flEngineerPickNewSpotTimer[client] = GetGameTime() + 15.0;
					}
				}
				
				if(g_flFindNearestHealthTimer[client] < GetGameTime())
				{
					if (healthpack != -1)
					{
						GetEntPropVector(healthpack, Prop_Send, "m_vecOrigin", g_flNearestHealthOrigin[client]);
						
						g_flFindNearestHealthTimer[client] = GetGameTime() + 20.0;
					}
				}
				
				if(g_flFindNearestAmmoTimer[client] < GetGameTime())
				{
					if(ammopack != -1)
					{
						GetEntPropVector(ammopack, Prop_Send, "m_vecOrigin", g_flNearestAmmoOrigin[client]);
						
						g_flFindNearestAmmoTimer[client] = GetGameTime() + 20.0;
					}
				}
				
				if(g_bHealthIsLow[client])
				{
					TF2_FindPath(client, g_flNearestHealthOrigin[client]);
					
					if(PF_Exists(client) && IsPlayerAlive(client) && GetVectorDistance(clientOrigin, g_flNearestHealthOrigin[client]) > 30.0)
					{
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
					}
				}
				
				if(g_bAmmoIsLow[client] && !g_bHealthIsLow[client])
				{
					TF2_FindPath(client, g_flNearestAmmoOrigin[client]);
					
					if(PF_Exists(client) && IsPlayerAlive(client) && GetVectorDistance(clientOrigin, g_flNearestAmmoOrigin[client]) > 30.0)
					{
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
					}
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
				
				if(GetMetal(client) != -1)
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
				
				if(g_flChangeWeaponTimer[client] < GetGameTime())
				{
					EquipWeaponSlot(client, 2);
					
					g_flChangeWeaponTimer[client] = GetGameTime() + 10.0;
				}
				
				if(g_bPickUnUsedSentrySpot[client])
				{
					int BuildedSentryGun;
					if(GetClientTeam(client) == 2 && (BuildedSentryGun = FindEntityByClassname(BuildedSentryGun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
					{
						if(StrContains(currentMap, "ctf_turbine" , false) != -1)
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
							}
						}
					}
					else if((BuildedSentryGun = FindEntityByClassname(BuildedSentryGun, "obj_sentrygun")) != INVALID_ENT_REFERENCE)
					{
						if(StrContains(currentMap, "ctf_turbine" , false) != -1)
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
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
											g_flSentryBuildPos[client] = SentryPos;
											g_flSentryBuildAngle[client] = SentryAngle;
											g_bPickUnUsedSentrySpot[client] = false;
										}
									}
								}
							}
						}
					}
				}
				
				if(GetEntProp(client, Prop_Send, "m_bJumping"))
				{
					buttons |= IN_DUCK;
				}
				
				if(IsWeaponSlotActive(client, 5))
				{
					if(!g_bSentryBuilded[client])
					{
						if(GetVectorDistance(clientEyes, g_flSentryBuildPos[client]) < 500.0)
						{
							TF2_LookAtPos(client, g_flSentryBuildAngle[client], 0.1);
						}
					}
				}
				
				if((StrContains(currentMap, "ctf_turbine" , false) != -1 || StrContains(currentMap, "ctf_2fort" , false) != -1))
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
						if(!TF2_HasTheFlag(client))
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
											if(GetVectorDistance(engiOrigin, g_flSentryBuildPos[client]) < 100.0)
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
											
											TF2_FindPath(client, g_flSentryBuildPos[client]);
											
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
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												buttons |= IN_ATTACK;
											}
											else
											{
												EquipWeaponSlot(client, 2);
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 75.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										else
										{
											TF2_RemoveCondition(client, TFCond_RestrictToMelee);
										}
										
										TF2_FindPath(client, sentrypos);
										
										if(PF_Exists(client) && IsPlayerAlive(client) && GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											TF2_MoveOut(client, g_flGoal[client], vel, angles);
										}
									}
									
									if(g_bBuildDispenser[client] && GetMetal(client) > 100.0)
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
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
										
										TF2_FindPath(client, putdispenserpos);
										
										if(PF_Exists(client) && IsPlayerAlive(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
									else if(!g_bDispenserBuilded[client] && GetMetal(client) < 100.0)
									{
										g_bAmmoIsLow[client] = true;
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
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												buttons |= IN_ATTACK;
											}
											else
											{
												EquipWeaponSlot(client, 2);
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 75.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										else
										{
											TF2_RemoveCondition(client, TFCond_RestrictToMelee);
										}
										
										TF2_FindPath(client, dispenserpos);
										
										if(PF_Exists(client) && IsPlayerAlive(client) && GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											TF2_MoveOut(client, g_flGoal[client], vel, angles);
										}
									}
								}
							}
						}
					}
				}
				else if(StrContains(currentMap, "ctf_turbine" , false) == -1 && StrContains(currentMap, "ctf_2fort" , false) == -1 && StrContains(currentMap, "ctf_" , false) != -1 && !TF2_HasTheFlag(client))
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
						if(IsWeaponSlotActive(client, 2) || IsWeaponSlotActive(client, 5))
						{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									float flagpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
									
									flagpos[2] += 100.0;
									
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
									
									//PrintToServer("FlagStatus %i", FlagStatus);
									
									if(g_bBuildSentry[client])
									{
										if(FlagStatus == 0 || FlagStatus == 1 || FlagStatus == 2)
										{
											TF2_FindPath(client, flagpos);
											
											if(PF_Exists(client) && IsPlayerAlive(client))
											{
												TF2_MoveTo(client, g_flGoal[client], vel, angles);
											}
											
											if(GetVectorDistance(engiOrigin, flagpos) < GetRandomFloat(75.0, 750.0))
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
										
										if(PF_Exists(client) && GetVectorDistance(engiOrigin, sentrypos) > 100.0)
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
										
										TF2_FindPath(client, putdispenserpos);
										
										if(PF_Exists(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
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
					}
				}
				else if(StrContains(currentMap, "rd_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
						if(IsWeaponSlotActive(client, 2) || IsWeaponSlotActive(client, 5))
						{
							int robot = GetNearestEntity(client, "tf_robot_destruction_robot");
							
							if(robot != -1)
							{
								int iTeamNumObj = GetEntProp(robot, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(robot) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									float robotpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(robot, Prop_Send, "m_vecOrigin", robotpos);
									
									robotpos[2] += 100.0;
									
									if(g_bBuildSentry[client])
									{
										TF2_FindPath(client, robotpos);
										
										if(GetVectorDistance(engiOrigin, robotpos) < GetRandomFloat(75.0, 750.0) && IsPointVisible(clientEyes, robotpos))
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
										
										if(PF_Exists(client))
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
										
										if(PF_Exists(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
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
					}
				}
				else if(StrContains(currentMap, "arena_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
						if(IsWeaponSlotActive(client, 2) || IsWeaponSlotActive(client, 5))
						{
							int capturepoint = GetNearestEntity(client, "item_ammopack_*"); // :(
							
							if(capturepoint != -1)
							{
								if(IsValidEntity(capturepoint))
								{
									float engiOrigin[3];
									float capturepointpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", capturepointpos);
									
									capturepointpos[2] += 100.0;
									
									if(g_bBuildSentry[client])
									{
										TF2_FindPath(client, capturepointpos);
										
										if(GetVectorDistance(engiOrigin, capturepointpos) < GetRandomFloat(250.0, 750.0) && IsPointVisible(clientEyes, capturepointpos))
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
										
										if(PF_Exists(client))
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
										
										TF2_FindPath(client, sentrypos);
										
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
										
										if(PF_Exists(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
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
					}
				}
				else if(StrContains(currentMap, "pd_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
						if(IsWeaponSlotActive(client, 2) || IsWeaponSlotActive(client, 5))
						{
							int pd_disp = GetNearestEntity(client, "pd_dispenser");
							
							if(pd_disp != -1)
							{
								int iTeamNumObj = GetEntProp(pd_disp, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(pd_disp) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									float pd_disppos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(pd_disp, Prop_Send, "m_vecOrigin", pd_disppos);
									
									pd_disppos[2] += 100.0;
									
									if(g_bBuildSentry[client])
									{
										TF2_FindPath(client, pd_disppos);
										
										if(GetVectorDistance(engiOrigin, pd_disppos) < GetRandomFloat(150.0, 500.0) && IsPointVisible(clientEyes, pd_disppos))
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
										
										if(PF_Exists(client))
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
										
										TF2_FindPath(client, sentrypos);
										
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
										
										if(PF_Exists(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
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
					}
				}
				else if(StrContains(currentMap, "pass_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
						if(IsWeaponSlotActive(client, 2) || IsWeaponSlotActive(client, 5))
						{
							int passtimeball = GetNearestEntity(client, "passtime_ball");
							
							if(passtimeball != -1)
							{
								if(IsValidEntity(passtimeball))
								{
									float engiOrigin[3];
									float passtimeballpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(passtimeball, Prop_Send, "m_vecOrigin", passtimeballpos);
									
									passtimeballpos[2] += 100.0;
									
									if(g_bBuildSentry[client])
									{
										TF2_FindPath(client, passtimeballpos);
										
										if(GetVectorDistance(engiOrigin, passtimeballpos) < GetRandomFloat(150.0, 1500.0) && IsPointVisible(clientEyes, passtimeballpos))
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
										
										if(PF_Exists(client))
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
										
										TF2_FindPath(client, sentrypos);
										
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
										
										if(PF_Exists(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
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
					}
				}
				else if(StrContains(currentMap, "plr_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
						if(IsWeaponSlotActive(client, 2) || IsWeaponSlotActive(client, 5))
						{	
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE) // if you using plr bots plugin (and if plugin spawning flag) = this works
							{
								int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									float flagpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
									
									flagpos[2] += 100.0;
									
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
									
									//PrintToServer("FlagStatus %i", FlagStatus);
									
									if(g_bBuildSentry[client])
									{
										if(FlagStatus == 0 || FlagStatus == 1 || FlagStatus == 2)
										{
											TF2_FindPath(client, flagpos);
											
											if(GetVectorDistance(engiOrigin, flagpos) < GetRandomFloat(200.0, 1200.0) && IsPointVisible(clientEyes, flagpos))
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
											
											if(PF_Exists(client))
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
										
										TF2_FindPath(client, sentrypos);
										
										if(PF_Exists(client) && GetVectorDistance(engiOrigin, sentrypos) > 100.0)
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
										
										if(PF_Exists(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
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
										
										if(PF_Exists(client) && GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
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
					}
				}
				else if(StrContains(currentMap, "sd_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
						if(IsWeaponSlotActive(client, 2) || IsWeaponSlotActive(client, 5))
						{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(flag))
								{
									float engiOrigin[3];
									float flagpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
									
									flagpos[2] += 100.0;
									
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
									
									//PrintToServer("FlagStatus %i", FlagStatus);
									
									if(g_bBuildSentry[client])
									{
										if(FlagStatus == 0 || FlagStatus == 1 || FlagStatus == 2)
										{
											TF2_FindPath(client, flagpos);
											
											if(GetVectorDistance(engiOrigin, flagpos) < GetRandomFloat(75.0, 750.0))
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
											
											if(PF_Exists(client))
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
										
										TF2_FindPath(client, sentrypos);
										
										if(PF_Exists(client) && GetVectorDistance(engiOrigin, sentrypos) > 100.0)
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
										
										if(PF_Exists(client))
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
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
										
										if(PF_Exists(client) && GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
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
					}
				}
				
				if(TF2_HasTheFlag(client) && StrContains(currentMap, "ctf_" , false) != -1)
				{
					if(GetClientTeam(client) == 2)
					{
						TF2_FindPath(client, g_flRedFlagCapPoint);
						
						if(PF_Exists(client))
						{
							TF2_MoveTo(client, g_flGoal[client], vel, angles);
						}
					}
					else
					{
						TF2_FindPath(client, g_flBluFlagCapPoint);
						
						if(PF_Exists(client))
						{
							TF2_MoveTo(client, g_flGoal[client], vel, angles);
						}
					}
				}
				else if(TF2_HasTheFlag(client))
				{
					if(StrContains(currentMap, "sd_" , false) != -1)
					{
						int capzone;
						while((capzone = FindEntityByClassname(capzone, "func_capturezone")) != INVALID_ENT_REFERENCE)
						{
							if(IsValidEntity(capzone))
							{
								float cappos[3];
								GetEntPropVector(capzone, Prop_Send, "m_vecOrigin", cappos);
								
								TF2_FindPath(client, cappos);
								
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
	}
	
	return Plugin_Continue;
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

public Action BotSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(botid))
	{
		if(TF2_GetPlayerClass(botid) == TFClass_Engineer)
		{
			EquipWeaponSlot(botid, 2);
			g_bPickUnUsedSentrySpot[botid] = true;
		}
		g_flWaitJumpTimer[botid] = GetGameTime() + 10.0;
	}
}

float g_flPathTimer[MAXPLAYERS + 1];
stock void TF2_FindPath(int client, float flTargetVector[3])
{
	if(g_flPathTimer[client] < GetGameTime())
	{
		if (!(PF_Exists(client)))
		{
			PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
		}
		
		PF_SetGoalVector(client, flTargetVector);
		
		PF_StartPathing(client);
		
		PF_EnableCallback(client, PFCB_Approach, Approach);
		
		g_flPathTimer[client] = GetGameTime() + 1.0;
	}
}

public int FindNearestAmmo(int client)
{
	char ClassName[32];
	float clientOrigin[3];
	float entityOrigin[3];
	float distance = -1.0;
	int nearestEntity = -1;
	for(int entity = 0; entity <= GetMaxEntities(); entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEdictClassname(entity, ClassName, 32);
			
			if(!HasEntProp(entity, Prop_Send, "m_fEffects"))
				continue;
			
			if(GetEntProp(entity, Prop_Send, "m_fEffects") != 0)
				continue;
				
			if(StrContains(ClassName, "item_healthammokit", false) != -1 || StrContains(ClassName, "tf_ammo_pack", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "item_ammopack", false) != -1)
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEntity = entity;
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
	for(int entity = 0; entity <= GetMaxEntities(); entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEdictClassname(entity, ClassName, 32);
			
			if(!HasEntProp(entity, Prop_Send, "m_fEffects"))
				continue;
			
			if(GetEntProp(entity, Prop_Send, "m_fEffects") != 0)
				continue;
				
			if(StrContains(ClassName, "item_health", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1)
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEntity = entity;
				}
			}
		}
	}
	return nearestEntity;
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

	TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
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

stock int TF2_GetNumHealers(int client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

stock bool IsPointVisible(float start[3], float end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
} 

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock int GetMetal(int client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
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

stock bool IsWeaponSlotActive(int client, int slot)
{
    return GetPlayerWeaponSlot(client, slot) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock int TF2_GetObject(int client, TFObjectType type)
{
	int iObject = INVALID_ENT_REFERENCE;
	while ((iObject = FindEntityByClassname(iObject, "obj_*")) != -1)
	{
		TFObjectType iObjType = TF2_GetObjectType(iObject);
		
		if(GetEntPropEnt(iObject, Prop_Send, "m_hBuilder") == client && iObjType == type 
		&& !GetEntProp(iObject, Prop_Send, "m_bPlacing")
		&& !GetEntProp(iObject, Prop_Send, "m_bDisposableBuilding"))
		{			
			return iObject;
		}
	}
	
	return iObject;
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

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}