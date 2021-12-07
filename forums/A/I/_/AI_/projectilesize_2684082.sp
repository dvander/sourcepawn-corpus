#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "0.3.0"

public Plugin myinfo = {
	name = "Projectile Size",
	author = "AI",
	description = "Projectile model size changer",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=321566"
}

ConVar g_hCVHealthKits;
ConVar g_hCVMinSize;
ConVar g_hCVMaxSize;

float g_fProjectileSize[MAXPLAYERS+1];

public void OnPluginStart() {
	CreateConVar("sm_projectilesize_version", "1", "Projectile Size version -- Do not modify", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCVHealthKits = CreateConVar("sm_projectilesize_healthkits", "1", "Resize spawned health kits like sandviches", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCVMinSize = CreateConVar("sm_projectilesize_minsize", "0.01", "Minimum size ratio", FCVAR_NOTIFY, true, 0.0);
	g_hCVMaxSize = CreateConVar("sm_projectilesize_maxsize", "500", "Maximum size ratio", FCVAR_NOTIFY, true, 0.0);
	
	RegAdminCmd("sm_ps", cmdPS, ADMFLAG_GENERIC, "Sets projectile size (no target applies to self)");
}

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		g_fProjectileSize[i] = 1.0;
	}
}

public void OnClientDisconnect(int iClient) {
	g_fProjectileSize[iClient] = 1.0;
}

public void OnEntityCreated(int iEntity, const char[] sClassName) {
	if (StrContains(sClassName, "tf_projectile") == 0 || (StrContains(sClassName, "item_healthkit") == 0 && g_hCVHealthKits.BoolValue)) {
		SDKHook(iEntity, SDKHook_Spawn, Hook_OnProjectileSpawn);
	}
}

public void Hook_OnProjectileSpawn(iEntity) {
	int iClient = GetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity");
	if (0 < iClient && iClient <= MaxClients) {
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", g_fProjectileSize[iClient]);
	}
}

public Action cmdPS(int iClient, int iArgC) {
	if (iArgC != 1 && iArgC != 2) {
		ReplyToCommand(iClient, "[SM] Usage: sm_ps [target] <ratio>");
		return Plugin_Handled;
	}
	char sArg1[32];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	
	if (iArgC == 1) {
		float fRatio = StringToFloat(sArg1);
		
		if (fRatio <= g_hCVMinSize.FloatValue || fRatio > g_hCVMaxSize.FloatValue) {
			ReplyToCommand(iClient, "[SM] Ratio must be between %.3f to %.3f", g_hCVMinSize.FloatValue, g_hCVMaxSize.FloatValue);
			return Plugin_Handled;
		}
		
		g_fProjectileSize[iClient] = fRatio;
		ReplyToCommand(iClient, "[SM] Set projectile size to %.3f", g_fProjectileSize[iClient]);
	} else {
		char sTargetName[MAX_TARGET_LENGTH];
		int iTargetList[MAXPLAYERS], iTargetCount;
		bool bTnIsML;
	 
		if ((iTargetCount = ProcessTargetString(
				sArg1,
				iClient,
				iTargetList,
				MAXPLAYERS,
				0,
				sTargetName,
				sizeof(sTargetName),
				bTnIsML)) <= 0) {
			ReplyToTargetError(iClient, iTargetCount);
			return Plugin_Handled;
		}
		
		char sArg2[32];
		GetCmdArg(2, sArg2, sizeof(sArg2));
		
		float fRatio = StringToFloat(sArg2);
		if (fRatio <= g_hCVMinSize.FloatValue || fRatio > g_hCVMaxSize.FloatValue) {
			ReplyToCommand(iClient, "[SM] Ratio must be between %.3f to %.3f", g_hCVMinSize.FloatValue, g_hCVMaxSize.FloatValue);
			return Plugin_Handled;
		}
		
		for (int i = 0; i < iTargetCount; i++) {
			g_fProjectileSize[iTargetList[i]] = fRatio;
		}
		
		if (bTnIsML) {
			ReplyToCommand(iClient, "[SM] Set projectile size for %t to %.1f", sTargetName, fRatio);
		} else {
			ReplyToCommand(iClient, "[SM] Set projectile size for %s to %.1f", sTargetName, fRatio);
		}
	}
	
	return Plugin_Handled;
}