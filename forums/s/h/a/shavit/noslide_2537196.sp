/*
 * noslide
 * by: shavit
 *
 * This file is part of noslide.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
*/

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <shavit>

#define NOSLIDE_VERSION "1.1"

// Uncommenting will result in an unnecessary message per land.
// #define DEBUG

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "noslide",
	author = "shavit",
	description = "Stops sliding on easybhop styles upon landing. Designed for kz_bhop maps.",
	version = NOSLIDE_VERSION,
	url = "https://github.com/shavitush/noslide"
}

// cookies
Handle gH_NoslideCookie = null;

// cvars
ConVar gCV_Enabled = null;

#if defined DEBUG
bool gB_Enabled = true;
#else
bool gB_Enabled = false;
#endif

// cache
ConVar sv_friction = null;
float gF_DefaultFriction = 4.0;
char gS_DefaultFriction[16];

EngineVersion gEV_Type;
bool gB_Shavit = false;
bool gB_Late = false;
float gF_Tickrate = 0.01; // 100 tickrate.
any gA_StyleSettings[STYLE_LIMIT][STYLESETTINGS_SIZE];
int gBS_Style[MAXPLAYERS+1];
bool gB_EnabledPlayers[MAXPLAYERS+1];
int gI_GroundTicks[MAXPLAYERS+1];
bool gB_StuckFriction[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	gB_Late = late;

	MarkNativeAsOptional("Shavit_GetBhopStyle");
	MarkNativeAsOptional("Shavit_GetStyleCount");
	MarkNativeAsOptional("Shavit_GetStyleSettings");
	MarkNativeAsOptional("Shavit_PrintToChat");

	return APLRes_Success;
}

public void OnPluginStart()
{
	gEV_Type = GetEngineVersion();

	gH_NoslideCookie = RegClientCookie("noslide_enabled", "Noslide settings", CookieAccess_Protected);

	gCV_Enabled = CreateConVar("noslide_enabled", "0", "Is noslide enabled?\nIt's recommended to set to 0 as default,\nbut use map-configs to enable it for specific maps.\n\n0 - Disabled\n1 - Enabled", 0, true, 0.0, true, 2.0);
	gCV_Enabled.AddChangeHook(OnConVarChanged);

	AutoExecConfig();

	RegConsoleCmd("sm_noslide", Command_Noslide, "Toggles noslide.");
	RegConsoleCmd("sm_kz", Command_Noslide, "Toggles noslide. Alias for sm_noslide.");
	RegConsoleCmd("sm_kzmode", Command_Noslide, "Toggles noslide. Alias for sm_noslide.");

	gB_Shavit = LibraryExists("shavit");

	if(gB_Late)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && AreClientCookiesCached(i))
			{
				OnClientPutInServer(i);
				OnClientCookiesCached(i);
			}
		}

		if(gB_Shavit)
		{
			Shavit_OnStyleConfigLoaded(-1);
		}
	}

	sv_friction = FindConVar("sv_friction");
	sv_friction.Flags &= ~(FCVAR_NOTIFY | FCVAR_REPLICATED);
	sv_friction.GetString(gS_DefaultFriction, 16);
	gF_DefaultFriction = sv_friction.FloatValue;
}

public void OnMapStart()
{
	gF_Tickrate = GetTickInterval();
}

public void OnConfigsExecuted()
{
	if(sv_friction != null)
	{
		sv_friction.GetString(gS_DefaultFriction, 16);
		gF_DefaultFriction = sv_friction.FloatValue;
	}
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	gB_Enabled = gCV_Enabled.BoolValue;
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

public void OnClientPutInServer(int client)
{
	gI_GroundTicks[client] = 3;
	gB_StuckFriction[client] = false;

	if(!AreClientCookiesCached(client))
	{
		gB_EnabledPlayers[client] = false;
	}

	if(gEV_Type == Engine_CSGO)
	{
		SDKHook(client, SDKHook_PreThinkPost, PreThinkPost);
	}
}

public void PreThinkPost(int client)
{
	if(IsPlayerAlive(client))
	{
		sv_friction.FloatValue = (gB_StuckFriction[client])? 50.0:gF_DefaultFriction;
	}
}

public void OnClientCookiesCached(int client)
{
	char[] sSetting = new char[8];
	GetClientCookie(client, gH_NoslideCookie, sSetting, 8);

	if(strlen(sSetting) == 0)
	{
		SetClientCookie(client, gH_NoslideCookie, "0");
		gB_EnabledPlayers[client] = false;
	}

	else
	{
		gB_EnabledPlayers[client] = view_as<bool>(StringToInt(sSetting));
	}

	if(gB_Shavit)
	{
		gBS_Style[client] = Shavit_GetBhopStyle(client);
	}
}

public void Shavit_OnStyleConfigLoaded(int styles)
{
	if(styles == -1)
	{
		styles = Shavit_GetStyleCount();
	}

	for(int i = 0; i < styles; i++)
	{
		Shavit_GetStyleSettings(i, gA_StyleSettings[i]);
	}
}

public void Shavit_OnStyleChanged(int client, int oldstyle, int newstyle)
{
	gBS_Style[client] = newstyle;
}

public Action Command_Noslide(int client, int args)
{
	gB_EnabledPlayers[client] = !gB_EnabledPlayers[client];

	char[] message = new char[32];
	FormatEx(message, 32, "Noslide is now %s.", (gB_EnabledPlayers[client])? "enabled":"disabled");

	if(gB_Shavit)
	{
		Shavit_PrintToChat(client, "%s", message);
	}

	else
	{
		PrintToChat(client, "[SM] %s", message);
	}

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!gB_Enabled || !IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}

	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == -1)
	{
		gI_GroundTicks[client] = 0;

		return Plugin_Continue;
	}

	if(!gB_EnabledPlayers[client] || (gB_Shavit && !gA_StyleSettings[gBS_Style[client]][bEasybhop]) || (buttons & IN_JUMP) > 0)
	{
		return Plugin_Continue;
	}

	float fStamina = GetEntPropFloat(client, Prop_Send, "m_flStamina");

	#if defined DEBUG
	// PrintToChat(client, "m_flFriction: %f", GetEntPropFloat(client, Prop_Send, "m_flFriction"));
	#endif

	// Noslide when a jump is imperfect. Your jump is only perfect when you jump at the same tick you land!
	if(++gI_GroundTicks[client] == ((gEV_Type == Engine_CSS)? 3:5) && (gEV_Type != Engine_CSS || fStamina <= 350.0)) // 350.0 is a sweetspoot for me.
	{
		if(gEV_Type == Engine_CSS)
		{
			SetEntPropFloat(client, Prop_Send, "m_flStamina", 1320.0); // 1320.0 is highest stamina in CS:S.
		}

		else
		{
			gB_StuckFriction[client] = true;
			sv_friction.ReplicateToClient(client, "50");
		}

		DataPack pack = new DataPack();
		pack.WriteCell(GetClientSerial(client));
		pack.WriteFloat(fStamina);

		CreateTimer((gEV_Type == Engine_CSS)? (gF_Tickrate * 5):gF_Tickrate, Timer_ApplyNewStamina, pack, TIMER_FLAG_NO_MAPCHANGE);

		#if defined DEBUG
		if(gB_Shavit)
		{
			Shavit_PrintToChat(client, "Applied new %s.", (gEV_Type == Engine_CSS)? "stamina":"friction");
		}
		#endif
	}

	return Plugin_Continue;
}

public Action Timer_ApplyNewStamina(Handle timer, DataPack data)
{
	data.Reset();
	int iSerial = data.ReadCell();
	float fStamina = data.ReadFloat();
	delete data;

	int client = GetClientFromSerial(iSerial);

	if(client != 0)
	{
		if(gEV_Type == Engine_CSS)
		{
			SetEntPropFloat(client, Prop_Send, "m_flStamina", fStamina);
		}

		else
		{
			sv_friction.ReplicateToClient(client, gS_DefaultFriction);
			gB_StuckFriction[client] = false;
		}
	}

	return Plugin_Stop;
}
