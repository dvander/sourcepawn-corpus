/*
#						CODE BY SIMON						#
# 	 			 	 	MADE FOR CS:GO						#
#															#
# Please do not edit and distribute	any part of this code	#
# without my permission.									#
#		CONSOLE CVARS:										#
#				sm_hud_health_version						#
#				sm_hud_health_enable -> 1					#
#				sm_hud_health_team -> 4						#
#				sm_hud_health_mode -> 1						#
#				sm_hud_health_flag -> d						#
#				sm_hud_health_ad -> 1						#
#		CLIENT COMMANDS:									#
#				!hudhealth or !hh							#
# 															#
# Thanks!													#
# Give suggestions/requests at yash1441@yahoo.com			#
#															#				
# Credits to Graffiti for his Show nickname in HUD plugin	#
#															#
#	CHANGELOG:												#
- 2017-08-24 ~ Added MultiColors support, simplified and added more ConVars. Also added a chat prefix. v3.3
-
- 2017-08-14 ~ Updated with new syntax and clientprefs, and added ShowHudText instead of PrintHintText. v3.2
-
- 2015-12-25 ~ Added sm_hud_health_enable & Merry Christmas! v3.1
-
- 2015-09-25 ~ Fixed issues after the new CS:GO update. v3.0
-
- 2015-08-22 ~ Minor Fixes. v2.7
-
- 2015-08-21 ~ Minor Fixes. v2.6
-
- 2015-08-20 ~ Added  sm_hud_health_mode, !hudhealth(sm_hudhealth), sm_hud_health_team 5 for spectators/dead & Advertisement. v2.5
-
- 2015-08-18 ~ Initial Release. v1.0
-
*/

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Simon"
#define PLUGIN_VERSION "3.3"
#define CHAT_PREFIX "[HH]"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <multicolors>

ConVar g_Cvar_Default;
ConVar g_Cvar_Team;
ConVar g_Cvar_Mode;
ConVar g_Cvar_Flag;
ConVar g_Cvar_Ad;

ConVar g_Cvar_X;
ConVar g_Cvar_Y;
ConVar g_Cvar_HoldTime;
ConVar g_Cvar_R;
ConVar g_Cvar_G;
ConVar g_Cvar_B;
ConVar g_Cvar_A;
ConVar g_Cvar_Effect;
ConVar g_Cvar_Effect_Duration;
ConVar g_Cvar_FadeIn_Duration;
ConVar g_Cvar_FadeOut_Duration;


Handle HudPrefs;
int IsHUDEnabled[MAXPLAYERS + 1] =  { 1, ... };
int TargetHealth[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "HUD Health",
	author = "Simon",
	description = "Show health on HUD for CSGO",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	CreateConVar("sm_hh_version", PLUGIN_VERSION, "Show health on HUD", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	g_Cvar_Default = CreateConVar("sm_hh_enable", "1", "Enabled by default or not. (0 = Disabled, 1 = Enabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_Team = CreateConVar("sm_hh_team", "3", "Show health to players in which team. (0 = No One, 1 = Terrorists, 2 = Counter-Terrorists, 3 = Both, 4 = Admin Only, 5 = Dead/Spectators Only)", FCVAR_NOTIFY, true, 0.0, true, 5.0);
	g_Cvar_Mode = CreateConVar("sm_hh_mode", "1", "Show health of players in which team. (0 = All, 1 = Enemy, 2 = Teammate)", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_Cvar_Flag = CreateConVar("sm_hh_flag", "d", "Admin flag(s) to use if admin only.", FCVAR_NOTIFY);
	g_Cvar_Ad = CreateConVar("sm_hh_ad", "1", "Enable/disable the display of the help message at the start of each round.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Cvar_X = CreateConVar("sm_hh_x", "-1.0", "X coordinate of HUD, 0 to 1. -1.0 is center.", 0, true, -1.0, true, 1.0);
	g_Cvar_Y = CreateConVar("sm_hh_y", "0.7", "Y coordinate of HUD, 0 to 1. -1.0 is center.", 0, true, -1.0, true, 1.0);
	g_Cvar_HoldTime = CreateConVar("sm_hh_duration", "0.5", "Number of seconds to hold the text.", 0, true, 0.0, false);
	g_Cvar_R = CreateConVar("sm_hh_r", "255", "Red color value.", 0, true, 0.0, true, 255.0);
	g_Cvar_G = CreateConVar("sm_hh_g", "150", "Green color value.", 0, true, 0.0, true, 255.0);
	g_Cvar_B = CreateConVar("sm_hh_b", "0", "Blue color value.", 0, true, 0.0, true, 255.0);
	g_Cvar_A = CreateConVar("sm_hh_a", "50", "Alpha transparency value.", 0, true, 0.0, true, 255.0);
	g_Cvar_Effect = CreateConVar("sm_hh_effect", "0", "0/1 causes the text to fade in and out. 2 causes the text to flash[?].", 0, true, 0.0, true, 2.0);
	g_Cvar_Effect_Duration = CreateConVar("sm_hh_effect_duration", "0", "Duration of chosen effect (May not apply to all effects).", 0, true, 0.0, false);
	g_Cvar_FadeIn_Duration = CreateConVar("sm_hh_fadein_duration", "0", "Number of seconds to spend in fading in.", 0, true, 0.0, false);
	g_Cvar_FadeOut_Duration = CreateConVar("sm_hh_fadeout_duration", "0", "Number of seconds to spend in fading out.", 0, true, 0.0, false);
	
	HookConVarChange(g_Cvar_X, OnConVarChanged);
	HookConVarChange(g_Cvar_Y, OnConVarChanged);
	HookConVarChange(g_Cvar_HoldTime, OnConVarChanged);
	HookConVarChange(g_Cvar_R, OnConVarChanged);
	HookConVarChange(g_Cvar_G, OnConVarChanged);
	HookConVarChange(g_Cvar_B, OnConVarChanged);
	HookConVarChange(g_Cvar_A, OnConVarChanged);
	HookConVarChange(g_Cvar_Effect, OnConVarChanged);
	HookConVarChange(g_Cvar_Effect_Duration, OnConVarChanged);
	HookConVarChange(g_Cvar_FadeIn_Duration, OnConVarChanged);
	HookConVarChange(g_Cvar_FadeOut_Duration, OnConVarChanged);
	
	HookEvent("round_start", Event_RoundStart);
	CreateTimer(0.5, HUDTimer, _, TIMER_REPEAT);
	RegConsoleCmd("sm_hudhealth", Cmd_Hud);
	RegConsoleCmd("sm_hh", Cmd_Hud);
	HudPrefs = RegClientCookie("HUD Preferences", "HUD Settings", CookieAccess_Public);
	SetCookieMenuItem(HUDPrefSelected, 0, "HUD Preferences");
	SetHudTextParams(GetConVarFloat(g_Cvar_X), GetConVarFloat(g_Cvar_Y), GetConVarFloat(g_Cvar_HoldTime), GetConVarInt(g_Cvar_R), GetConVarInt(g_Cvar_G), GetConVarInt(g_Cvar_B), GetConVarInt(g_Cvar_A), GetConVarInt(g_Cvar_Effect), GetConVarFloat(g_Cvar_Effect_Duration), GetConVarFloat(g_Cvar_FadeIn_Duration), GetConVarFloat(g_Cvar_FadeOut_Duration));
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	SetHudTextParams(GetConVarFloat(g_Cvar_X), GetConVarFloat(g_Cvar_Y), GetConVarFloat(g_Cvar_HoldTime), GetConVarInt(g_Cvar_R), GetConVarInt(g_Cvar_G), GetConVarInt(g_Cvar_B), GetConVarInt(g_Cvar_A), GetConVarInt(g_Cvar_Effect), GetConVarFloat(g_Cvar_Effect_Duration), GetConVarFloat(g_Cvar_FadeIn_Duration), GetConVarFloat(g_Cvar_FadeOut_Duration));
}

public void OnClientCookiesCached(int client)
{
	if(IsValidClient(client))
	{
		LoadClientCookies(client);
	}
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast) // Advertisement of the client command
{
	if (GetConVarBool(g_Cvar_Ad) && GetConVarBool(g_Cvar_Default))
	{
		CPrintToChatAll("{blue}%s {default}Type {green}!hudhealth {default}or {green}!hh {default}to see other players' health on your HUD.", CHAT_PREFIX);
	}
}

public Action HUDTimer(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		switch(g_Cvar_Team)
		{
			case 0:
			{
				return Plugin_Handled;
			}
			case 1: // T Team Alive -> sm_hud_health_team 1
			{
				if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i) && IsHUDEnabled[i])
				{
					int target = TraceClientViewEntity(i);
					if(target > 0 && target <= MaxClients && IsValidClient(target) && IsPlayerAlive(target))
					{
						switch(g_Cvar_Mode) {
							case 1: // enemy
							{
								if (GetClientTeam(target) == CS_TEAM_CT) {
									TargetHealth[target] = GetClientHealth(target);
									ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
								}
								break;
							}
							case 2: // team-mate
							{
								if (GetClientTeam(target) == CS_TEAM_T) {
									TargetHealth[target] = GetClientHealth(target);
									ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
								}
								break;
							}
							default: // both
							{
								TargetHealth[target] = GetClientHealth(target);
								ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
							}
						}
					}
				}
				break;
			}
			case 2: // CT Team Alive -> sm_hud_health_team 2
			{
				if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i) && IsHUDEnabled[i])
				{
					int target = TraceClientViewEntity(i);
					if(target > 0 && target <= MaxClients && IsValidClient(target) && IsPlayerAlive(target))
					{
						switch(g_Cvar_Mode) {
							case 1: // enemy
							{
								if (GetClientTeam(target) == CS_TEAM_T) {
									TargetHealth[target] = GetClientHealth(target);
									ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
								}
								break;
							}
							case 2: // team-mate
							{
								if (GetClientTeam(target) == CS_TEAM_CT) {
									TargetHealth[target] = GetClientHealth(target);
									ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
								}
								break;
							}
							default: // both
							{
								TargetHealth[target] = GetClientHealth(target);
								ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
							}
						}
					}
				}
				break;
			}
			case 3: // Both Teams Alive -> sm_hud_health_team 3
			{
				if (IsValidClient(i) && GetClientTeam(i) != CS_TEAM_SPECTATOR && IsPlayerAlive(i) && IsHUDEnabled[i])
				{
					int target = TraceClientViewEntity(i);
					if(target > 0 && target <= MaxClients && IsValidClient(target) && IsPlayerAlive(target))
					{
						switch(g_Cvar_Mode) {
							case 1: // enemy
							{
								if (GetClientTeam(i) != GetClientTeam(target)){
									TargetHealth[target] = GetClientHealth(target);
									ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
								}
								break;
							}
							case 2: // team-mate
							{
								if (GetClientTeam(i) == GetClientTeam(target)){
									TargetHealth[target] = GetClientHealth(target);
									ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
								}
								break;
							}
							default:
							{
								TargetHealth[target] = GetClientHealth(target);
								ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
							}
						}
					}
				}
				break;
			}
			case 4: // Admins -> sm_hud_health_team 4; not affected by sm_hud_health_mode
			{
				char g_sCharAdminFlag[32];
				GetConVarString(g_Cvar_Flag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));
				if (IsValidClient(i) && IsValidAdmin(i, g_sCharAdminFlag) && IsHUDEnabled[i])
				{
					int target = TraceClientViewEntity(i);
					if(target > 0 && target <= MaxClients && IsValidClient(target) && IsPlayerAlive(target))
					{
						TargetHealth[target] = GetClientHealth(target);
						ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
					}
				}
				break;
			}
			case 5: // Both Teams Dead or Spectators -> sm_hud_health_team 5; not affected by sm_hud_health_mode
			{
				if (IsValidClient(i) && IsHUDEnabled[i])
				{
					if (!IsPlayerAlive(i)  || GetClientTeam(i) == CS_TEAM_SPECTATOR) {
						int target = TraceClientViewEntity(i);
						if(target > 0 && target <= MaxClients && IsValidClient(target) && IsPlayerAlive(target))
						{
							TargetHealth[target] = GetClientHealth(target);
							ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
						}
					}
				}
				break;
			}
			default: // Everyone -> sm_hud_health_team x; x < 0 or x > 4
			{
				if (IsValidClient(i) && IsHUDEnabled[i])
				{
					int target = TraceClientViewEntity(i);
					if(target > 0 && target <= MaxClients && IsValidClient(target) && IsPlayerAlive(target))
					{
						switch(g_Cvar_Mode) {
							case 1:
							{
								if (GetClientTeam(target) == CS_TEAM_T) {
									TargetHealth[target] = GetClientHealth(target);
									ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
								}
								break;
							}
							case 2:
							{
								if (GetClientTeam(target) == CS_TEAM_CT) {
									TargetHealth[target] = GetClientHealth(target);
									ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
								}
								break;
							}
							default:
							{
								TargetHealth[target] = GetClientHealth(target);
								ShowHudText(i, -1, "Name: %N | HP: %i", target, TargetHealth[target]);
							}
						}
					}
				}
				break;
			}
		}
	}
	return Plugin_Continue; 
}

public void HUDPrefSelected(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if(action == CookieMenuAction_SelectOption)
	{
		ShowHUDMenu(client);
	}
}

public Action Cmd_Hud(int client, int args)
{
	if (!GetConVarBool(g_Cvar_Default)) return Plugin_Handled;
	ShowHUDMenu(client);
	return Plugin_Handled;
}

public void ShowHUDMenu(int client)
{
	Handle menu = CreateMenu(HUDMenuHandler);
	char buffer[100];
	Format(buffer, sizeof(buffer), "HUD Health %f", PLUGIN_VERSION);
	SetMenuTitle(menu, buffer);
	if(IsHUDEnabled[client] == 0)
	{
		AddMenuItem(menu, "enable", "Enable");
	}
	else
	{
		AddMenuItem(menu, "disable", "Disable");
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
}

public int HUDMenuHandler(Handle menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)	
	{
		if(param2 == 0)
		{
			if(IsHUDEnabled[param1] == 0)
			{
				IsHUDEnabled[param1] = 1;
			}
			else
			{
				IsHUDEnabled[param1] = 0;
			}
		}
		char buffer[5];
		IntToString(IsHUDEnabled[param1], buffer, sizeof(buffer));
		SetClientCookie(param1, HudPrefs, buffer);
		Cmd_Hud(param1, 0);
	} 
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void LoadClientCookies(int client)
{
	char buffer[5];
	GetClientCookie(client, HudPrefs, buffer, sizeof(buffer));
	if(!StrEqual(buffer, ""))
	{
		IsHUDEnabled[client] = StringToInt(buffer);
	}
}

stock int TraceClientViewEntity(int client)
{
	float m_vecOrigin[3];
	float m_angRotation[3];

	GetClientEyePosition(client, m_vecOrigin);
	GetClientEyeAngles(client, m_angRotation);

	Handle tr = TR_TraceRayFilterEx(m_vecOrigin, m_angRotation, MASK_VISIBLE, RayType_Infinite, TRDontHitSelf, client);
	int pEntity = -1;

	if (TR_DidHit(tr))
	{
		pEntity = TR_GetEntityIndex(tr);
		CloseHandle(tr);
		return pEntity;
	}

	if(tr != INVALID_HANDLE)
	{
		CloseHandle(tr);
	}
	
	return -1;
}

public bool TRDontHitSelf(int entity, int mask, any data) // Don't ray trace ourselves -_-"
{
	return (1 <= entity <= MaxClients) && (entity != data);
}

stock bool IsValidAdmin(int client, const char[] flags) // Checks if admin has sm_hud_health_flag flag
{
	int ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(client) & ibFlags) == ibFlags)
	{
		return true;
	}
	if (GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		return true;
	}
	return false;
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}