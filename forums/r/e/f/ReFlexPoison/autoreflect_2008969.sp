#pragma semicolon 1

// ====[ INCLUDES ]============================================================
#include <sourcemod>
#include <sdktools>

// ====[ DEFINES ]=============================================================
#define PLUGIN_NAME				"Pyro Auto Reflect"
#define PLUGIN_VERSION			"1.0"

// ====[ HANDLES | CVARS ]=====================================================
new Handle:g_hCvarEnabled,		bool:g_bCvarEnabled;
new Handle:g_hCvarAimClients,	bool:g_bCvarAimClients;

// ====[ VARIABLES ]===========================================================
new g_iOffsetActiveWeapon;
new g_bAutoReflecting			[MAXPLAYERS + 1];

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Auto Reflect",
	author = "ReFlexPoison",
	description = "Automatically reflect projectiles coming toward you as Pyro",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ EVENTS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_autoreflect_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	g_hCvarEnabled = CreateConVar("sm_autoreflect_enabled", "1", "Enable Pyro Auto Reflect\n0 = Disabled\n1 = Enabled", _, true, 0.0, true, 1.0);
	g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	HookConVarChange(g_hCvarEnabled, OnConVarChange);

	g_hCvarAimClients = CreateConVar("sm_autoreflect_aimclients", "1", "Aim at closest clients?\n0 = No\n1 = Yes", _, true, 0.0, true, 1.0);
	g_bCvarAimClients = GetConVarBool(g_hCvarAimClients);
	HookConVarChange(g_hCvarAimClients, OnConVarChange);

	RegAdminCmd("sm_autoreflect", AutoReflectCmd, ADMFLAG_GENERIC);

	g_iOffsetActiveWeapon = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");

	for(new i = 1; i <= MaxClients; i++) if(IsValidClient(i))
		OnClientConnected(i);
}

public OnConVarChange(Handle:hConvar, const String:strOldValue[], const String:strNewValue[])
{
	if(hConvar == g_hCvarEnabled)
		g_bCvarEnabled = GetConVarBool(g_hCvarEnabled);
	if(hConvar == g_hCvarAimClients)
		g_bCvarAimClients = GetConVarBool(g_hCvarAimClients);
}

public OnClientConnected(iClient)
{
	g_bAutoReflecting[iClient] = false;
}

public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	if(!g_bCvarEnabled || !IsValidClient(iClient) || !g_bAutoReflecting[iClient])
		return Plugin_Continue;

	if(!IsPlayerAlive(iClient))
		return Plugin_Continue;

	new iCurrentWeapon = GetEntDataEnt2(iClient, g_iOffsetActiveWeapon);
	if(iCurrentWeapon == -1)
		return Plugin_Continue;

	decl Float:fClientEyePosition[3];
	GetClientEyePosition(iClient, fClientEyePosition);

	new iEntity = -1;
	while((iEntity = FindEntityByClassname(iEntity, "tf_projectile_*")) != INVALID_ENT_REFERENCE)
	{
		decl Float:fEntityLocation[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fEntityLocation);

		decl Float:fVector[3];
		MakeVectorFromPoints(fEntityLocation, fClientEyePosition, fVector);

		decl Float:fAngle[3];
		GetVectorAngles(fVector, fAngle);
		fAngle[0] *= -1.0;
		fAngle[1] += 180.0;

		if(GetVectorLength(fVector) < 350.0)
		{
			ModRateOfFire(iClient, iCurrentWeapon);
			TeleportEntity(iClient, NULL_VECTOR, fAngle, NULL_VECTOR);
			iButtons |= IN_ATTACK2;
			return Plugin_Changed;
		}
	}

	if(g_bCvarAimClients)
	{
		new iClosest = GetClosestClient(iClient);
		if(!IsValidClient(iClosest))
			return Plugin_Continue;

		decl Float:fClosestLocation[3];
		GetClientAbsOrigin(iClosest, fClosestLocation);
		fClosestLocation[2] += 90;

		decl Float:fVector[3];
		MakeVectorFromPoints(fClosestLocation, fClientEyePosition, fVector);

		decl Float:fAngle[3];
		GetVectorAngles(fVector, fAngle);
		fAngle[0] *= -1.0;
		fAngle[1] += 180.0;

		TeleportEntity(iClient, NULL_VECTOR, fAngle, NULL_VECTOR);
	}

	return Plugin_Continue;
}

// ====[ COMMANDS ]============================================================
public Action:AutoReflectCmd(iClient, iArgs)
{
	if(!g_bCvarEnabled || !IsValidClient(iClient))
		return Plugin_Continue;

	if(iArgs != 0 && iArgs != 2)
	{
		ReplyToCommand(iClient, "[SM] Usage: sm_autoreflect <target> [0/1]");
		return Plugin_Handled;
	}

	if(iArgs == 0)
	{
		if(!g_bAutoReflecting[iClient])
		{
			PrintToChat(iClient, "[SM] Auto reflect enabled.");
			g_bAutoReflecting[iClient] = true;
		}
		else
		{
			PrintToChat(iClient, "[SM] Auto reflect disabled.");
			g_bAutoReflecting[iClient] = false;
		}
	}

	else if(iArgs == 2)
	{
		decl String:strArg1[PLATFORM_MAX_PATH];
		GetCmdArg(1, strArg1, sizeof(strArg1));
		decl String:strArg2[8];
		GetCmdArg(2, strArg2, sizeof(strArg2));

		new iValue = StringToInt(strArg2);
		if(iValue != 0 && iValue != 1)
		{
			ReplyToCommand(iClient, "[SM] Usage: sm_autoreflect <target> [0/1]");
			return Plugin_Handled;
		}

		new String:strTargetName[MAX_TARGET_LENGTH];
		new iTargetList[MAXPLAYERS];
		new iTargetCount;
		new bool:bTnIsMl;
		if((iTargetCount = ProcessTargetString(strArg1, iClient, iTargetList, MAXPLAYERS, 0, strTargetName, sizeof(strTargetName), bTnIsMl)) <= 0)
		{
			ReplyToTargetError(iClient, iTargetCount);
			return Plugin_Handled;
		}

		for(new i = 0; i < iTargetCount; i++) if(IsValidClient(iTargetList[i]))
		{
			if(iValue == 0)
			{
				PrintToChat(iTargetList[i], "[SM] Auto reflect disabled.");
				g_bAutoReflecting[iTargetList[i]] = false;
			}
			else
			{
				PrintToChat(iTargetList[i], "[SM] Auto reflect enabled.");
				g_bAutoReflecting[iTargetList[i]] = true;
			}
		}
	}

	return Plugin_Handled;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock GetClosestClient(iClient)
{
	decl Float:fClientLocation[3];
	GetClientAbsOrigin(iClient, fClientLocation);
	decl Float:fEntityOrigin[3];

	new iClosestEntity = -1;
	new Float:fClosestDistance = -1.0;
	for(new i = 1; i < MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) != GetClientTeam(iClient) && IsPlayerAlive(i) && i != iClient)
		{
			GetClientAbsOrigin(i, fEntityOrigin);
			new Float:fEntityDistance = GetVectorDistance(fClientLocation, fEntityOrigin);
			if((fEntityDistance < fClosestDistance) || fClosestDistance == -1.0)
			{
				fClosestDistance = fEntityDistance;
				iClosestEntity = i;
			}
		}
	}
	return iClosestEntity;
}

stock ModRateOfFire(iClient, iWeapon)
{
	new Float:m_flNextPrimaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
	new Float:m_flNextSecondaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack");
	SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", 10.0);

	new Float:fGameTime = GetGameTime();
	new Float:fPrimaryTime = ((m_flNextPrimaryAttack - fGameTime) - 0.99);
	new Float:fSecondaryTime = ((m_flNextSecondaryAttack - fGameTime) - 0.99);

	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fPrimaryTime + fGameTime);
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", fSecondaryTime + fGameTime);
}