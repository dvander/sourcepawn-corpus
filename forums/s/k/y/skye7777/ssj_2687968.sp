#include <sdktools>
#include <sdkhooks>
#include <clientprefs>

#undef REQUIRE_PLUGIN
#include <shavit>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "SSJ: Advanced",
	author = "AlkATraZ",
	description = "Strafe gains/efficiency etc.",
	version = SHAVIT_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=287039"
}

#define BHOP_FRAMES 10

#define USAGE_SIXTH 0
#define USAGE_EVERY 1
#define USAGE_EVERY_SIXTH 2

Handle gH_CookieEnabled = null;
Handle gH_CookieUsageMode = null;
Handle gH_CookieCurrentSpeed = null;
Handle gH_CookieHeightDiff = null;
Handle gH_CookieSpeedDiff = null;
Handle gH_CookieGainStats = null;
Handle gH_CookieEfficiency = null;
Handle gH_CookieStrafeSync = null;
Handle gH_CookieDefaultsSet = null;

int gI_UsageMode[MAXPLAYERS+1];
bool gB_Enabled[MAXPLAYERS+1] = {true, ...};
bool gB_CurrentSpeed[MAXPLAYERS+1] = {true, ...};
bool gB_SpeedDiff[MAXPLAYERS+1];
bool gB_HeightDiff[MAXPLAYERS+1];
bool gB_GainStats[MAXPLAYERS+1] = {true, ...};
bool gB_Efficiency[MAXPLAYERS+1];
bool gB_StrafeSync[MAXPLAYERS+1];
bool gB_TouchesWall[MAXPLAYERS+1];

int gI_TicksOnGround[MAXPLAYERS+1];
int gI_TouchTicks[MAXPLAYERS+1];
int gI_StrafeTick[MAXPLAYERS+1];
int gI_SyncedTick[MAXPLAYERS+1];
int gI_Jump[MAXPLAYERS+1];

float gF_InitialSpeed[MAXPLAYERS+1];
float gF_InitialHeight[MAXPLAYERS+1];
float gF_OldHeight[MAXPLAYERS+1];
float gF_OldSpeed[MAXPLAYERS+1];
float gF_RawGain[MAXPLAYERS+1];
float gF_Trajectory[MAXPLAYERS+1];
float gF_TraveledDistance[MAXPLAYERS+1][3];

float gF_Tickrate = 0.01;

// misc settings
bool gB_Late = false;
bool gB_Shavit = false;
EngineVersion gEV_Type = Engine_Unknown;

chatstrings_t gS_ChatStrings;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	gB_Late = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_ssj", Command_SSJ, "Open the Speed @ Sixth Jump menu.");
	
	gH_CookieEnabled = RegClientCookie("ssj2_enabled", "ssj2_enabled", CookieAccess_Public);
	gH_CookieUsageMode = RegClientCookie("ssj2_displaymode", "ssj2_displaymode", CookieAccess_Public);
	gH_CookieCurrentSpeed = RegClientCookie("ssj2_currentspeed", "ssj2_currentspeed", CookieAccess_Public);
	gH_CookieSpeedDiff = RegClientCookie("ssj2_speeddiff", "ssj2_speeddiff", CookieAccess_Public);
	gH_CookieHeightDiff = RegClientCookie("ssj2_heightdiff", "ssj2_heightdiff", CookieAccess_Public);
	gH_CookieGainStats = RegClientCookie("ssj2_gainstats", "ssj2_gainstats", CookieAccess_Public);
	gH_CookieEfficiency = RegClientCookie("ssj2_efficiency", "ssj2_efficiency", CookieAccess_Public);
	gH_CookieStrafeSync = RegClientCookie("ssj2_strafesync", "ssj2_strafesync", CookieAccess_Public);
	gH_CookieDefaultsSet = RegClientCookie("ssj2_defaults", "ssj2_defaults", CookieAccess_Public);

	HookEvent("player_jump", Player_Jump);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
			OnClientCookiesCached(i);
		}
	}

	if(gB_Late)
	{
		Shavit_OnChatConfigLoaded();
	}

	gB_Shavit = LibraryExists("shavit");
	gEV_Type = GetEngineVersion();
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "shavit"))
	{
		gB_Shavit = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "shavit"))
	{
		gB_Shavit = false;
	}
}

public void OnMapStart()
{
	gF_Tickrate = GetTickInterval();
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStrings(sMessageText, gS_ChatStrings.sText, sizeof(chatstrings_t::sText));
	Shavit_GetChatStrings(sMessageWarning, gS_ChatStrings.sWarning, sizeof(chatstrings_t::sWarning));
	Shavit_GetChatStrings(sMessageVariable, gS_ChatStrings.sVariable, sizeof(chatstrings_t::sVariable));
	Shavit_GetChatStrings(sMessageVariable2, gS_ChatStrings.sVariable2, sizeof(chatstrings_t::sVariable2));
	Shavit_GetChatStrings(sMessageStyle, gS_ChatStrings.sStyle, sizeof(chatstrings_t::sStyle));
}

public void OnClientCookiesCached(int client)
{
	char[] sCookie = new char[8];
	
	GetClientCookie(client, gH_CookieDefaultsSet, sCookie, 8);
	
	if(StringToInt(sCookie) == 0)
	{
		SetCookie(client, gH_CookieEnabled, true);
		SetCookie(client, gH_CookieUsageMode, USAGE_SIXTH);
		SetCookie(client, gH_CookieCurrentSpeed, true);
		SetCookie(client, gH_CookieSpeedDiff, false);
		SetCookie(client, gH_CookieHeightDiff, false);
		SetCookie(client, gH_CookieGainStats, true);
		SetCookie(client, gH_CookieEfficiency, false);
		SetCookie(client, gH_CookieStrafeSync, false);
		
		SetCookie(client, gH_CookieDefaultsSet, true);
	}
	
	GetClientCookie(client, gH_CookieEnabled, sCookie, 8);
	gB_Enabled[client] = view_as<bool>(StringToInt(sCookie));
	
	GetClientCookie(client, gH_CookieUsageMode, sCookie, 8);
	gI_UsageMode[client] = StringToInt(sCookie);
	
	GetClientCookie(client, gH_CookieCurrentSpeed, sCookie, 8);
	gB_CurrentSpeed[client] = view_as<bool>(StringToInt(sCookie));
	
	GetClientCookie(client, gH_CookieSpeedDiff, sCookie, 8);
	gB_SpeedDiff[client] = view_as<bool>(StringToInt(sCookie));
	
	GetClientCookie(client, gH_CookieHeightDiff, sCookie, 8);
	gB_HeightDiff[client] = view_as<bool>(StringToInt(sCookie));
	
	GetClientCookie(client, gH_CookieGainStats, sCookie, 8);
	gB_GainStats[client] = view_as<bool>(StringToInt(sCookie));
	
	GetClientCookie(client, gH_CookieEfficiency, sCookie, 8);
	gB_Efficiency[client] = view_as<bool>(StringToInt(sCookie));
	
	GetClientCookie(client, gH_CookieStrafeSync, sCookie, 8);
	gB_StrafeSync[client] = view_as<bool>(StringToInt(sCookie));
}

public void OnClientPutInServer(int client)
{
	gI_Jump[client] = 0;
	gI_StrafeTick[client] = 0;
	gI_SyncedTick[client] = 0;
	gF_RawGain[client] = 0.0;
	gF_InitialHeight[client] = 0.0;
	gF_InitialSpeed[client] = 0.0;
	gF_OldHeight[client] = 0.0;
	gF_OldSpeed[client] = 0.0;
	gF_Trajectory[client] = 0.0;
	gF_TraveledDistance[client] = NULL_VECTOR;
	gI_TicksOnGround[client] = 0;

	SDKHook(client, SDKHook_Touch, OnTouch);
}

public Action OnTouch(int client, int entity)
{
	if((GetEntProp(entity, Prop_Data, "m_usSolidFlags") & 12) == 0)
	{
		gB_TouchesWall[client] = true;
	}
}

public void Player_Jump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsFakeClient(client))
	{
		return;
	}
	
	if(gI_Jump[client] > 0 && gI_StrafeTick[client] <= 0)
	{
		return;
	}
	
	gI_Jump[client]++;

	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);

	float origin[3];
	GetClientAbsOrigin(client, origin);

	velocity[2] = 0.0;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && 
			((!IsPlayerAlive(i) && GetEntPropEnt(i, Prop_Data, "m_hObserverTarget") == client &&
			GetEntProp(i, Prop_Data, "m_iObserverMode") != 7 && gB_Enabled[i]) ||
			((i == client && gB_Enabled[i] && ((gI_Jump[i] == 6 && gI_UsageMode[i] == USAGE_SIXTH) || gI_UsageMode[i] == USAGE_EVERY || 
			(gI_UsageMode[i] == USAGE_EVERY_SIXTH && (gI_Jump[i] % 6) == 0))))))
		{
			SSJ_PrintStats(i, client);
		}
	}

	if((gI_Jump[client] >= 6 && gI_UsageMode[client] == USAGE_SIXTH) || gI_UsageMode[client] == USAGE_EVERY || (gI_Jump[client] % 6) == 0 && gI_UsageMode[client] == USAGE_EVERY_SIXTH)
	{
		gF_RawGain[client] = 0.0;
		gI_StrafeTick[client] = 0;
		gI_SyncedTick[client] = 0;
		gF_OldHeight[client] = origin[2];
		gF_OldSpeed[client] = GetVectorLength(velocity);
		gF_Trajectory[client] = 0.0;
		gF_TraveledDistance[client] = NULL_VECTOR;
	}
	
	if((gI_Jump[client] == 1 && gI_UsageMode[client] == USAGE_SIXTH) || (gI_Jump[client] % 6 == 1 && gI_UsageMode[client] == USAGE_EVERY_SIXTH))
	{
		gF_InitialHeight[client] = origin[2];
		gF_InitialSpeed[client] = GetVectorLength(velocity);
		gF_TraveledDistance[client] = NULL_VECTOR;
	}
}

public Action Command_SSJ(int client, int args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game.");

		return Plugin_Handled;
	}

	return ShowSSJMenu(client);
}

public Action ShowSSJMenu(int client)
{
	Menu menu = new Menu(SSJ_MenuHandler);
	menu.SetTitle("Speed @ Sixth Jump\n ");
	
	menu.AddItem("usage", gB_Enabled[client]? "[x] Enabled":"[ ] Enabled");
	menu.AddItem("mode", (gI_UsageMode[client] == USAGE_SIXTH)? "[6th] Usage mode":((gI_UsageMode[client] == USAGE_EVERY)? "[Every] Usage mode":"[Every 6th] Usage mode"));
	menu.AddItem("curspeed", (gB_CurrentSpeed[client])? "[x] Current speed":"[ ] Current speed");
	menu.AddItem("speed", (gB_SpeedDiff[client])? "[x] Speed difference":"[ ] Speed difference");
	menu.AddItem("height", (gB_HeightDiff[client])? "[x] Height difference":"[ ] Height difference");
	menu.AddItem("gain", (gB_GainStats[client])? "[x] Gain percentage":"[ ] Gain percentage");
	menu.AddItem("efficiency", (gB_Efficiency[client])? "[x] Strafe efficiency":"[ ] Strafe efficiency");
	menu.AddItem("sync", (gB_StrafeSync[client])? "[x] Synchronization":"[ ] Synchronization");
	
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = true;

	menu.Display(client, 0);

	return Plugin_Handled;
}

public int SSJ_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				gB_Enabled[param1] = !gB_Enabled[param1];
				SetCookie(param1, gH_CookieEnabled, gB_Enabled[param1]);
			}

			case 1:
			{
				gI_UsageMode[param1] = ((gI_UsageMode[param1] + 1) % 3);
				SetCookie(param1, gH_CookieUsageMode, gI_UsageMode[param1]);
			}

			case 2:
			{
				gB_CurrentSpeed[param1] = !gB_CurrentSpeed[param1];
				SetCookie(param1, gH_CookieCurrentSpeed, gB_CurrentSpeed[param1]);
			}

			case 3:
			{
				gB_SpeedDiff[param1] = !gB_SpeedDiff[param1];
				SetCookie(param1, gH_CookieSpeedDiff, gB_SpeedDiff[param1]);
			}

			case 4:
			{
				gB_HeightDiff[param1] = !gB_HeightDiff[param1];
				SetCookie(param1, gH_CookieHeightDiff, gB_HeightDiff[param1]);
			}

			case 5:
			{
				gB_GainStats[param1] = !gB_GainStats[param1];
				SetCookie(param1, gH_CookieGainStats, gB_GainStats[param1]);
			}

			case 6:
			{
				gB_Efficiency[param1] = !gB_Efficiency[param1];
				SetCookie(param1, gH_CookieEfficiency, gB_Efficiency[param1]);
			}

			case 7:
			{
				gB_StrafeSync[param1] = !gB_StrafeSync[param1];
				SetCookie(param1, gH_CookieStrafeSync, gB_StrafeSync[param1]);
			}
		}		

		ShowSSJMenu(param1);
	}

	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

void SSJ_GetStats(int client, float vel[3], float angles[3])
{
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);

	gI_StrafeTick[client]++;

	float speedmulti = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
	
	gF_TraveledDistance[client][0] += velocity[0] * gF_Tickrate * speedmulti;
	gF_TraveledDistance[client][1] += velocity[1] * gF_Tickrate * speedmulti;
	velocity[2] = 0.0;

	gF_Trajectory[client] += GetVectorLength(velocity) * gF_Tickrate * speedmulti;
	
	float fore[3];
	float side[3];
	GetAngleVectors(angles, fore, side, NULL_VECTOR);
	
	fore[2] = 0.0;
	NormalizeVector(fore, fore);

	side[2] = 0.0;
	NormalizeVector(side, side);

	float wishvel[3];
	float wishdir[3];
	
	for(int i = 0; i < 2; i++)
	{
		wishvel[i] = fore[i] * vel[0] + side[i] * vel[1];
	}

	float wishspeed = NormalizeVector(wishvel, wishdir);
	float maxspeed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");

	if(maxspeed != 0.0 && wishspeed > maxspeed)
	{
		wishspeed = maxspeed;
	}
	
	if(wishspeed > 0.0)
	{
		float wishspd = (wishspeed > 30.0)? 30.0:wishspeed;
		float currentgain = GetVectorDotProduct(velocity, wishdir);
		float gaincoeff = 0.0;

		if(currentgain < 30.0)
		{
			gI_SyncedTick[client]++;
			gaincoeff = (wishspd - FloatAbs(currentgain)) / wishspd;
		}

		if(gB_TouchesWall[client] && gI_TouchTicks[client] && gaincoeff > 0.5)
		{
			gaincoeff -= 1.0;
			gaincoeff = FloatAbs(gaincoeff);
		}

		gF_RawGain[client] += gaincoeff;
	}
}

public Action Shavit_OnUserCmdPre(int client, int &buttons, int &impulse, float vel[3], float angles[3], TimerStatus status, int track, int style, stylesettings_t stylesettings)
{
	if((GetEntityFlags(client) & FL_ONGROUND) > 0)
	{
		if(gI_TicksOnGround[client]++ > BHOP_FRAMES)
		{
			gI_Jump[client] = 0;
			gI_StrafeTick[client] = 0;
			gI_SyncedTick[client] = 0;
			gF_RawGain[client] = 0.0;
			gF_Trajectory[client] = 0.0;
			gF_TraveledDistance[client] = NULL_VECTOR;
		}
		
		if((buttons & IN_JUMP) > 0 && gI_TicksOnGround[client] == 1)
		{
			SSJ_GetStats(client, vel, angles);
			gI_TicksOnGround[client] = 0;
		}
	}

	else
	{
		MoveType movetype = GetEntityMoveType(client);

		if(movetype != MOVETYPE_NONE && movetype != MOVETYPE_NOCLIP && movetype != MOVETYPE_LADDER && GetEntProp(client, Prop_Data, "m_nWaterLevel") < 2)
		{
			SSJ_GetStats(client, vel, angles);
		}

		gI_TicksOnGround[client] = 0;
	}

	if(gB_TouchesWall[client])
	{
		gI_TouchTicks[client]++;
		gB_TouchesWall[client] = false;
	}

	else
	{
		gI_TouchTicks[client] = 0;
	}

	return Plugin_Continue;
}

void SSJ_PrintStats(int client, int target)
{
	float velocity[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsVelocity", velocity);
	velocity[2] = 0.0;

	float origin[3];
	GetClientAbsOrigin(target, origin);
	
	float coeffsum = gF_RawGain[target];
	coeffsum /= gI_StrafeTick[target];
	coeffsum *= 100.0;
	
	float distance = GetVectorLength(gF_TraveledDistance[target]);

	if(distance > gF_Trajectory[target])
	{
		distance = gF_Trajectory[target];
	}

	float efficiency = 0.0;

	if(distance > 0.0)
	{
		efficiency = coeffsum * distance / gF_Trajectory[target];
	}
	
	coeffsum = RoundToFloor(coeffsum * 100.0 + 0.5) / 100.0;
	efficiency = RoundToFloor(efficiency * 100.0 + 0.5) / 100.0;
	
	char[] sMessage = new char[192];
	FormatEx(sMessage, 192, "Jump: %s%i", gS_ChatStrings.sVariable2, gI_Jump[target]);

	if(gB_CurrentSpeed[client])
	{
		Format(sMessage, 192, "%s %s| Speed: %s%i", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, RoundToFloor(GetVectorLength(velocity)));
	}

	if((gI_UsageMode[client] == USAGE_SIXTH && gI_Jump[target] == 6) || (gI_UsageMode[client] == USAGE_EVERY_SIXTH && (gI_Jump[client] % 6) == 0))
	{
		if(gB_SpeedDiff[client])
		{
			Format(sMessage, 192, "%s %s| Speed Δ: %s%i", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, RoundToFloor(GetVectorLength(velocity)) - RoundToFloor(gF_InitialSpeed[target]));
		}

		if(gB_HeightDiff[client])
		{
			Format(sMessage, 192, "%s %s| Height Δ: %s%i", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, RoundToFloor(origin[2]) - RoundToFloor(gF_InitialHeight[target]));
		}

		if(gB_GainStats[client])
		{
			Format(sMessage, 192, "%s %s| Gain: %s%.2f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, coeffsum);
		}

		if(gB_StrafeSync[client])
		{
			Format(sMessage, 192, "%s %s| Sync: %s%.2f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, 100.0 * gI_SyncedTick[target] / gI_StrafeTick[target]);
		}

		if(gB_Efficiency[client])
		{
			Format(sMessage, 192, "%s %s| Efficiency: %s%.2f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, efficiency);
		}
		
		Shavit_PrintToChat(client, "%s", sMessage, client);
	}

	else if(gI_UsageMode[client] == USAGE_EVERY)
	{
		if(gI_Jump[target] > 1)
		{
			if(gB_SpeedDiff[client])
			{
				Format(sMessage, 192, "%s %s| Speed Δ: %s%i", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, RoundToFloor(GetVectorLength(velocity)) - RoundToFloor(gF_OldSpeed[target]));
			}

			if(gB_HeightDiff[client])
			{
				Format(sMessage, 192, "%s %s| Height Δ: %s%i", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, RoundToFloor(origin[2]) - RoundToFloor(gF_OldHeight[target]));
			}

			if(gB_GainStats[client])
			{
				Format(sMessage, 192, "%s %s| Gain: %s%.2f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, coeffsum);
			}

			if(gB_StrafeSync[client])
			{
				Format(sMessage, 192, "%s %s| Sync: %s%.2f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, 100.0 * gI_SyncedTick[target] / gI_StrafeTick[target]);
			}

			if(gB_Efficiency[client])
			{
				Format(sMessage, 192, "%s %s| Efficiency: %s%.2f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, efficiency);
			}
		}
		
		Shavit_PrintToChat(client, "%s", sMessage, client);
	}
}

void SetCookie(int client, Handle hCookie, int n)
{
	char[] sCookie = new char[8];
	IntToString(n, sCookie, 8);

	SetClientCookie(client, hCookie, sCookie);
}