#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
//#define USE_CONNECT

#if defined USE_CONNECT
#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
//#include <steamtools>
#include <connect>
new Handle:hCvarAllowAdmin = INVALID_HANDLE;
#endif

#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = {
	name = "[TF2] MvM Auto-lock Server",
	author = "FlaminSarge",
	description = "Automatically locks server when 6 or more people are connected for MvM",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

#if !defined USE_CONNECT
new Handle:hCvarPass = INVALID_HANDLE;
#endif
new currentplayers = 0;
public OnPluginStart()
{
	CreateConVar("mvmautolock_version", PLUGIN_VERSION, "[TF2] MvM Auto-lock Server version", FCVAR_NOTIFY|FCVAR_PLUGIN);
#if !defined USE_CONNECT
	hCvarPass = CreateConVar("mvm_password", "", "Password to set once MvM has 6 people", FCVAR_PLUGIN|FCVAR_PROTECTED);
	HookConVarChange(hCvarPass, cvarPassChanged);
#else
	hCvarAllowAdmin = CreateConVar("mvm_pass_admin", "b", "Allows an admin with this flag to always join", FCVAR_PLUGIN);
#endif
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i)) currentplayers++;
	}
}
public OnMapStart()
{
	IsMvM(true);
}
stock bool:IsMvM(bool:forceRecalc = false)
{
	static bool:found = false;
	static bool:ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}
#if !defined USE_CONNECT
public cvarPassChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	new Handle:pass = FindConVar("sv_password");
	decl String:strPass[32];
	GetConVarString(pass, strPass, sizeof(strPass));
	if (currentplayers < 6 && strPass[0] == '\0') return;
	if (StrEqual(oldVal, strPass)) SetConVarString(pass, newVal);
}

public OnConfigsExecuted()
{
	if (!IsMvM()) return;
	if (currentplayers >= 6)
	{
		new String:pass[32];
		GetConVarString(hCvarPass, pass, 32);
		SetConVarString(FindConVar("sv_password"), pass);
		PrintToChatAll("\x073EFF3E[MvM]\x01 Max of 6 players reached, locking server.");
	}
}
#endif
#if !defined USE_CONNECT
public OnClientConnected(client)
{
	if (!IsMvM()) return;
	if (!IsFakeClient(client))
	{
		currentplayers++;
		new Handle:hPassword = FindConVar("sv_password");
		new String:pass[32];
		GetConVarString(hPassword, pass, 32);
		if (currentplayers >= 6 && pass[0] == '\0')
		{
			GetConVarString(hCvarPass, pass, 32);
			if (pass[0] == '\0') return;
			SetConVarString(hPassword, pass);
			PrintToChatAll("\x073EFF3E[MvM]\x01 Max of 6 players reached, locking server.");
		}
	}
}
#endif
public OnClientDisconnect(client)
{
	if (!IsMvM()) return;
	if (!IsFakeClient(client))
	{
		currentplayers--;
#if !defined USE_CONNECT
		new Handle:hPassword = FindConVar("sv_password");
		new String:pass[32];
		new String:pass2[32];
		GetConVarString(hPassword, pass, 32);
		GetConVarString(hCvarPass, pass2, 32);
		if (currentplayers < 6 && StrEqual(pass, pass2))
		{
			SetConVarString(hPassword, "");
			PrintToChatAll("\x073EFF3E[MvM]\x01 Less than 6 players, unlocking server.");
		}
#endif
	}
}
#if defined USE_CONNECT
public bool:OnClientPreConnect(const String:name[], String:password[255], const String:ip[], const String:steamID[], String:rejectReason[255])
{
	if (!IsMvM()) return true;
	new AdminId:id = FindAdminByIdentity("steam", steamID);
	if (currentplayers < 6)
	{
		currentplayers++;
		return true;
	}
	if (id == INVALID_ADMIN_ID)
	{
		strcopy(rejectReason, 255, "MvM server is full.");
		return false;
	}
	decl String:strFlags[32];
	GetConVarString(hCvarAllowAdmin, strFlags, sizeof(strFlags));
	new flags = ReadFlagString(strFlags);
	if (GetAdminFlags(id, Access_Effective) & flags)
	{
		currentplayers++;
		return true;
	}
	strcopy(rejectReason, 255, "MvM server is full.");
	return false;
}
#endif
stock GetRealClientCount(bool:inGameOnly = true)
{
	new clients = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!inGameOnly)
		{
			if (IsClientInGame(i) && IsFakeClient(i)) continue;
			if (IsClientConnected(i)) clients++;
		}
		else if (IsClientInGame(i) && !IsFakeClient(i)) clients++;
	}
	return clients;
}