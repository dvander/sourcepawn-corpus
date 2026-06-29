#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <clientprefs>

bool Third_Melee[MAXPLAYERS+1];
bool SaveCookies[MAXPLAYERS + 1];

Handle l4d2_tm_cookies;
Handle ThirdMeleeCookie = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "[L4D2] Auto Thirdperson Melee",
	author = "MasterMind420",
	description = "Switches to thirdperson when melee is equipped",
	version = "1.7",
	url = ""
}

public void OnPluginStart()
{
	l4d2_tm_cookies = CreateConVar("l4d2_tm_cookies", "1","Store auto thirdperson melee preference? 1=Enable, 0=Disable",FCVAR_NOTIFY,true, 0.0, true, 1.0);

	RegConsoleCmd("sm_tm", sm_tm);

	ThirdMeleeCookie = RegClientCookie("tpm_cookie", "", CookieAccess_Private);

	AutoExecConfig(true, "l4d2_thirdperson_melee");

	CreateTimer(0.1, ThirdpersonMelee, _, TIMER_REPEAT);
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsClientInGame(client))
		return;

	if (IsFakeClient(client) || !IsFakeClient(client))
		SaveCookies[client] = false;
}

public Action sm_tm(int client, int args)
{
	if (client > 0)
	{
		Third_Melee[client]=!Third_Melee[client];
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);

		if(IsFakeClient(client) || !IsFakeClient(client))
			SaveCookies[client] = true;
	}
}

public Action ThirdpersonMelee(Handle Timer)
{
	if (!IsServerProcessing())
		return Plugin_Continue;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsSurvivor(client) || !IsPlayerAlive(client) || IsClientInKickQueue(client))
			continue;

		if(Third_Melee[client])
		{
			int Weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(Weapon == -1) continue;

			char sWeapon[64];
			GetEntityClassname(Weapon, sWeapon, sizeof(sWeapon));

			if(!(StrEqual(sWeapon, "weapon_melee") || StrEqual(sWeapon, "weapon_chainsaw")))
				GotoFirstPerson(client);
			else
				GotoThirdPerson(client);
		}
	}

	return Plugin_Continue;
}

public void OnClientCookiesCached(int client)
{
	if(IsFakeClient(client) || !IsFakeClient(client))
	{
		if (GetConVarInt(l4d2_tm_cookies) == 1)
			GetClientCookies(client);
	}
}

void GetClientCookies(int client)
{
	if(IsFakeClient(client) || !IsFakeClient(client))
	{
		char tm_cookie[2];
		GetClientCookie(client, ThirdMeleeCookie, tm_cookie, 2);

		if (!strlen(tm_cookie))
		{
			SetClientCookie(client, ThirdMeleeCookie, "0");
			Third_Melee[client] = false;
		}
		else
			Third_Melee[client] = (StringToInt(tm_cookie) == 0 ? false : true);
	}
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client) || !IsFakeClient(client))
	{
		if(SaveCookies[client])
			SaveClientCookies(client);
	}
}

void SaveClientCookies(int client)
{
	if(IsFakeClient(client) || !IsFakeClient(client))
	{
		if(AreClientCookiesCached(client))
		{
			char tm_cookie[2];
			IntToString(Third_Melee[client], tm_cookie, 2);
			SetClientCookie(client, ThirdMeleeCookie, tm_cookie);
			SaveCookies[client] = false;
		}
	}
}

void GotoFirstPerson(int client)
{
	int Incap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	if (Incap)
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
	else
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
}

void GotoThirdPerson(int client)
{
	int Incap = GetEntProp(client, Prop_Send, "m_isIncapacitated");

	if (Incap)
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 0.0);
	else
		SetEntPropFloat(client, Prop_Send, "m_TimeForceExternalView", 99999.3);
}

/*=====[ MY STOCKS ]=====*/
stock bool IsValidAdmin(int client)
{
	if (GetUserFlagBits(client) & ADMFLAG_ROOT) return true;
	return false;
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client)) return true;
	return false;
}

stock bool IsSpectator(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1) return true;
	return false;
}

stock bool IsSurvivor(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2) return true;
	return false;
}

stock bool IsInfected(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3) return true;
	return false;
}

stock bool IsPlayerIncapped(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
 	return false;
}

stock bool IsOnGround(int client)
{
	if(GetEntityFlags(client) & FL_ONGROUND) return true;
	return false;
}

stock bool IsValidEntityRef(int EntityRef)
{
    int entity = EntRefToEntIndex(EntityRef);
    return (EntityRef && entity != INVALID_ENT_REFERENCE && IsValidEntity(entity));
}