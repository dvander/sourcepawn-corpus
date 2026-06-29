#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define TEAM_SURVIVORS 2
#define PLUGIN_VERSION "2.0h"

float g_flMANextTime[MAXPLAYERS+1] = {-1.0, ...};

int g_iMAEntid[MAXPLAYERS+1] = {-1, ...};
int g_iMAEntid_notmelee[MAXPLAYERS+1] = {-1, ...};
int g_iMAAttCount[MAXPLAYERS+1] = {-1, ...};

Handle g_hMA_maxpenalty = null;

int g_iMeleeFatigueO = -1;
int g_iNextPAttO = -1;
int g_iActiveWO	= -1;

public Plugin myinfo = 
{
	name = "Martial Artist",
	author = "Cookie! modded by Huck. Made from Perkmod2",
	description = "Swing a melee weapon twice in rapid succession.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=889437"
}

public void OnPluginStart()
{
	g_hMA_maxpenalty = CreateConVar("ma_max_penalty", "5", "Based on z_gun_swing_coop_min/max_penalty. Min=5, Max=8 and is ~2.0secs)",0 ,true, 5.0, true, 8.0);
	
	g_iActiveWO	= FindSendPropInfo("CBaseCombatCharacter", "m_hActiveWeapon");
	g_iNextPAttO = FindSendPropInfo("CBaseCombatWeapon", "m_flNextPrimaryAttack");
	g_iMeleeFatigueO = FindSendPropInfo("CTerrorPlayer", "m_iShovePenalty");

	AutoExecConfig(true, "martial_artist");
}

public void OnGameFrame()
{
	int iEntid;
	float flNextTime_calc;
	float flNextTime_ret;
	float flGameTime=GetGameTime();

	for(int i=1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVORS && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			iEntid = GetEntDataEnt2(i, g_iActiveWO);
			if(iEntid == -1) continue;
			
			flNextTime_ret = GetEntDataFloat(iEntid, g_iNextPAttO);
			if(GetEntData(i, g_iMeleeFatigueO) > GetConVarInt(g_hMA_maxpenalty))
			{
				SetEntData(i, g_iMeleeFatigueO,  GetConVarInt(g_hMA_maxpenalty));
			}

			if(iEntid == g_iMAEntid_notmelee[i])
			{
				g_iMAAttCount[i] = 0;
				continue;
			}

			int iMAEntid = g_iMAEntid[i];
			int iMAAttCount = g_iMAAttCount[i];

			if(iMAEntid == iEntid && iMAAttCount != 0 && (flGameTime - flNextTime_ret) > 0.8)
			{
				g_iMAAttCount[i] = 0;
			}
		
			float flMANextTime = g_flMANextTime[i];
			if(iMAEntid == iEntid && flMANextTime >= flNextTime_ret)
			{
				continue;
			}

			if(iMAEntid == iEntid && flMANextTime < flNextTime_ret)
			{
				float flInterval = flNextTime_ret-flGameTime;
				if(flInterval > 0.7331 && flInterval < 0.7335)
				{
					g_flMANextTime[i] = flNextTime_ret;
					continue;
				}
				if(flInterval < 0.534)
				{
					g_flMANextTime[i] = flNextTime_ret;
					continue;
				}

				g_iMAAttCount[i]++;
				if(g_iMAAttCount[i] > 2)
				{
					g_iMAAttCount[i] = 0;
				}				
				iMAAttCount = g_iMAAttCount[i];
				
				if(iMAAttCount == 1 || iMAAttCount == 1)
				{
					flNextTime_calc = flGameTime + 0.3;
					g_flMANextTime[i] = flNextTime_calc;
					SetEntDataFloat(iEntid, g_iNextPAttO, flNextTime_calc, true);
					continue;
				}
				
				if(g_iMAAttCount[i] == 0)
				{
					g_flMANextTime[i] = flNextTime_ret;
					continue;
				}
			}

			char stName[32];
			GetEntityNetClass(iEntid, stName, sizeof(stName));
			if(StrEqual(stName, "CTerrorMeleeWeapon", false))
			{
				g_iMAEntid[i] = iEntid;
				g_flMANextTime[i] = flNextTime_ret;
				continue;
			}
			else
			{
				g_iMAEntid_notmelee[i] = iEntid;
				continue;
			}
		}
	}
	return;
}