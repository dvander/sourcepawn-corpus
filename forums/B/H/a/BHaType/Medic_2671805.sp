#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CHAT_TAG "\x01\x05[Medic]\x01"

bool g_bLoaded, g_bLateload;
int g_iMedic, g_iHaloMaterial, g_iLaserMaterial, g_iHealCount, g_iMaxHeal;
float g_flDistance, g_flAlive;
ConVar cDistance, cHeal, cMaxHeal, cLaserAliveTime;

public APLRes AskPluginLoad2(Handle hPlugin, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	cDistance = CreateConVar("sm_medic_heal_distance", "600.0", "Distance of heal", FCVAR_NONE);
	cHeal = CreateConVar("sm_medic_heal_count", "5", "Heal count", FCVAR_NONE);
	cMaxHeal = CreateConVar("sm_medic_max_heal", "100", "Max heal count", FCVAR_NONE);
	cLaserAliveTime = CreateConVar("sm_medic_laser_alive_time", "3.5", "Laser alive time", FCVAR_NONE);
	
	g_flDistance = cDistance.FloatValue;
	g_flAlive = cLaserAliveTime.FloatValue;
	g_iHealCount = cHeal.IntValue;
	g_iMaxHeal = cMaxHeal.IntValue;
	
	cDistance.AddChangeHook(ConVarChanged);
	cHeal.AddChangeHook(ConVarChanged);
	cMaxHeal.AddChangeHook(ConVarChanged);
	cLaserAliveTime.AddChangeHook(ConVarChanged);
	
	HookEvent("player_left_start_area", eMedic, EventHookMode_PostNoCopy);
	HookEvent("round_start", eMedic, EventHookMode_PostNoCopy);
	
	HookEvent("round_end", eReset, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", eReset, EventHookMode_PostNoCopy);
	
	HookEvent("weapon_fire", eFire);
	
	if (g_bLateload)
	{
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && GetClientTeam(i) == 2)
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);

		SetupMedic();
	}
	
	RegConsoleCmd("sm_m", eBecome);
	RegConsoleCmd("sm_who", eWho);
}

public void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_flAlive = cLaserAliveTime.FloatValue;
	g_flDistance = cDistance.FloatValue;
	g_iHealCount = cHeal.IntValue;
	g_iMaxHeal = cMaxHeal.IntValue;
}

public void eFire (Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!client || GetClientOfUserId(g_iMedic) != client)
		return;
	
	int iCurrentWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (iCurrentWeapon <= MaxClients)
		return;
		
	char szName[32];
	GetEntityClassname(iCurrentWeapon, szName, sizeof szName);
	
	if(strcmp(szName, "weapon_pistol_magnum") != 0)
		return;
	
	float vOrigin[3], vAngles[3], vResult[3];
	
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vOrigin);
	
	GetAngleVectors(vAngles, vAngles, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vAngles, vAngles);
	ScaleVector(vAngles, g_flDistance);
	AddVectors(vOrigin, vAngles, vResult);
	TE_SendBeam(vOrigin, vResult, g_flAlive);
	
	int iTarget = GetClientAimTarget(client);
	
	if (iTarget <= 0 || iTarget > MaxClients || GetClientTeam(iTarget) != 2)
		return;
	
	float vPos[3];
	GetClientEyePosition(iTarget, vPos);
	
	if (GetVectorDistance(vOrigin, vResult) + 25.0 < GetVectorDistance(vOrigin, vPos))
		return;
	
	int iHealth = GetClientHealth(iTarget);
	
	if (iHealth + g_iHealCount > g_iMaxHeal)
		SetEntityHealth(iTarget, g_iMaxHeal);
	else
		SetEntityHealth(iTarget, g_iHealCount + iHealth);

	PrintHintText(iTarget, "You got healed by %N on %i", client, g_iHealCount);
	PrintHintText(client, "You healed %N on %i", iTarget, g_iHealCount);
}

public void eReset (Event event, const char[] name, bool dontbroadcast)
{
	g_iMedic = 0;
	
	if (!g_bLoaded)
		return;
}

public void eMedic (Event event, const char[] name, bool dontbroadcast)
{
	if (!g_bLoaded)
		return;
		
	SetupMedic();
}

public void OnMapStart()
{
	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");

	g_bLoaded = true;
}

public void OnMapEnd()
{
	g_bLoaded = false;
}

public Action eWho (int client, int args)
{
	if (g_iMedic == 0)
		ReplyToCommand(client, "%s\x04There is no \x03medic in the \x04team, \x03lead the team \x04!m \x03to become a \x04medic!", CHAT_TAG);
	else
		ReplyToCommand(client, "%s \x04Medic is \x03%N", CHAT_TAG, GetClientOfUserId(g_iMedic));
	
	return Plugin_Handled;
}

public Action eBecome (int client, int args)
{
	int iMedic = GetClientOfUserId(g_iMedic);
	if (!iMedic || !IsClientInGame(iMedic) || GetClientTeam(iMedic) != 2)
	{
		g_iMedic = GetClientUserId(client);
		PrintToChatAll("%s \x04%N \x03becomes a medic!", CHAT_TAG, client);
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponUse);
	}
	else
		PrintToChat(client, "%s Medic already choosen! (%N)", CHAT_TAG, GetClientOfUserId(g_iMedic));
	return Plugin_Handled;
}

public Action OnWeaponUse(int client, int weapon)
{
	if(g_iMedic && GetClientOfUserId(g_iMedic) == client)
	{
		int iEntity = GetPlayerWeaponSlot(client, 1);
		
		if (iEntity <= MaxClients)
			return Plugin_Continue;
		
		char szName[32], szClassname[32];
		
		GetEntityClassname(iEntity, szName, sizeof(szName));
		GetEntityClassname(weapon, szClassname, sizeof(szClassname));
		
		if(StrEqual(szName, "weapon_pistol_magnum"))
			if(StrEqual(szClassname, "weapon_melee") || StrEqual(szClassname, "weapon_pistol"))
				return Plugin_Handled;
	}
	return Plugin_Continue;
}

void SetupMedic()
{
	g_iMedic = GetRandomClient();
	
	if (!g_iMedic || !IsClientInGame(g_iMedic) || IsFakeClient(g_iMedic))
	{
		g_iMedic = 0;
		PrintToChatAll("%s \x04There is no \x03medic in the \x04team, \x03lead the team \x04!m \x03to become a \x04medic!", CHAT_TAG);
		return;
	}
	else
	{
		GiveFunction(g_iMedic, "pistol_magnum");
		PrintToChatAll("%s \x04%N \x03becomes a medic!", CHAT_TAG, g_iMedic);
		SDKHook(g_iMedic, SDKHook_WeaponCanUse, OnWeaponUse);
	}
	
	g_iMedic = GetClientUserId(g_iMedic);
}

public void OnClientPostAdminCheck(int client)
{
	if (GetClientTeam(client) == 2)
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)  
{
	if(victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && GetClientTeam(attacker) == 2 && g_iMedic && GetClientOfUserId(g_iMedic) == attacker)
	{
		int iCurrentWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
		if (iCurrentWeapon <= MaxClients)
			return Plugin_Continue;
			
		char szName[32];
		GetEntityClassname(iCurrentWeapon, szName, sizeof szName);
		
		if(strcmp(szName, "weapon_pistol_magnum") != 0)
			return Plugin_Continue;
		
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

int GetRandomClient (int client = -1)
{
	int[] g_iClients = new int[MaxClients];
	int iCounter;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) == 3 || client == i)
			continue;
			
		g_iClients[iCounter] = i;
		iCounter++;
	}

	return g_iClients[GetRandomInt(0, iCounter - 1)];
}

void TE_SendBeam(const float vStart[3], const float vEnd[3], float fTime = 5.0)
{
	TE_SetupBeamPoints(vStart, vEnd, g_iLaserMaterial, g_iHaloMaterial, 0, 0, fTime, 1.0, 1.0, 3, 1.5, { 25, 255, 25, 255 }, 0);
	TE_SendToAll();
}

public bool TraceFilter (int entity, int mask)
{
	return true;
}

void GiveFunction(int client, char[] name)
{
	char sBuf[32];
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FormatEx(sBuf, sizeof sBuf, "give %s", name);
	FakeClientCommand(client, sBuf);
	SetCommandFlags("give", flags);
}