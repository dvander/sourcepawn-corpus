#include <cstrike>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1
#define VERSION "0.6"

int g_iAccount = -1;
int g_iType = 0;
int g_iMoney[MAXPLAYERS + 1] = -1;

Handle g_hCvarType = null;

public Plugin myinfo = 
{
	name = "Revolver Control", 
	author = "SM9 (xCoderx)", 
	description = "Increases price of Revolver otherwise replaces it with the Desert Eagle.", 
	version = VERSION, 
	url = "www.fragdeluxe.com"
}

public void OnPluginStart()
{
	HookConVarChange(g_hCvarType = CreateConVar("sm_rc_type", "0", "The amount to increase price by, otherwise <= 0 to replace with deagle"), OnCvarChanged);
	CreateConVar("sm_rc_version", VERSION, "", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	g_iAccount = FindSendPropInfo("CCSPlayer", "m_iAccount");
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) {
		if (!IsClientConnected(iClient)) {
			continue;
		}
		
		OnClientPutInServer(iClient);
	}
	
	g_iType = GetConVarInt(g_hCvarType);
	
	AutoExecConfig(true, "sm_revolver_control");
}

public void OnCvarChanged(Handle hConvar, const char[] chOldValue, const char[] chNewValue) {
	g_iType = StringToInt(chNewValue);
}

public void OnClientPutInServer(int iClient) {
	SDKHook(iClient, SDKHook_WeaponEquip, OnWeaponEquip);
}

public Action CS_OnBuyCommand(int iClient, const char[] chWeapon)
{
	if (StrContains(chWeapon, "revolver") != -1 || StrContains(chWeapon, "deagle") != -1) {
		g_iMoney[iClient] = GetEntData(iClient, g_iAccount);
		return Plugin_Continue;
	}
	
	g_iMoney[iClient] = -1;
	return Plugin_Continue;
}

public Action OnWeaponEquip(int iClient, int iWeapon)
{
	if (GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex") != 64) {
		return Plugin_Continue;
	}
	
	int iMoney = GetEntData(iClient, g_iAccount);
	
	if (g_iMoney[iClient] == -1) {
		if (g_iType <= 0) {
			SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", 1);
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	
	if (g_iType > 0) {
		if (g_iMoney[iClient] < g_iType + 850) {
			AcceptEntityInput(iWeapon, "Kill");
			PrintToChat(iClient, "[SM] You don't have enough money for the Revolver.");
			PrintToChat(iClient, "[SM] Price: $%d.", g_iType + 850);
			SetEntData(iClient, g_iAccount, g_iMoney[iClient]);
			
			g_iMoney[iClient] = -1;
			return Plugin_Continue;
		}
		
		SetEntData(iClient, g_iAccount, iMoney - g_iType);
		g_iMoney[iClient] = -1;
		return Plugin_Continue;
	}
	
	SetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex", 1);
	
	if (iMoney + 850 != g_iMoney[iClient]) {
		return Plugin_Continue;
	}
	
	SetEntData(iClient, g_iAccount, iMoney + 150);
	g_iMoney[iClient] = -1;
	
	return Plugin_Continue;
}