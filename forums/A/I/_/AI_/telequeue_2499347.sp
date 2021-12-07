#pragma semicolon 1

// #define DEBUG

#define PLUGIN_AUTHOR "AI"
#define PLUGIN_VERSION "1.0.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib/arrays>
#include <smlib/clients>
#include <tf2>
#include <tf2_stocks>

#define DONOR_ACCESS_OVERRIDE "telequeue_donor"
#define MAXSKIP_WEIGHT 100
#define DONOR_WEIGHT 50

ConVar g_hQueueClass;
ConVar g_hQueueOrder;
ConVar g_hQueueMax;

StringMap g_hTeleMap;
int g_iQueuing[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};
int g_iQueueInfo[MAXPLAYERS + 1] = {0, ...};
int g_iClassOrder[10] = {-1, ...};

public Plugin myinfo = 
{
	name = "Teleporter Queue",
	author = PLUGIN_AUTHOR,
	description = "Sorted teleporter use order",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=294492"
};

public void OnPluginStart()
{
	CreateConVar("sm_telequeue_version", PLUGIN_VERSION, "Teleporter Queue version -- Do not modify", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hQueueClass = CreateConVar("sm_telequeue_class", "engineer medic soldier heavy pyro demoman spy sniper scout", "Teleporter queue class order/whitelist", FCVAR_PLUGIN);
	g_hQueueOrder = CreateConVar("sm_telequeue_order", "2", "Teleporter queue order (0:default, 1:FIFO, 2:class+FIFO)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	g_hQueueMax = CreateConVar("sm_telequeue_max", "5", "Auto increase player priority after waiting for this many players ahead (0:disable)", FCVAR_PLUGIN, true, 0.0);
	
#if defined DEBUG	
	RegConsoleCmd("sm_teleinfo", Command_TeleInfo, "List your teleporter queue");
#endif	

	HookEvent("teamplay_round_start", OnRoundStart);
	
	g_hTeleMap = new StringMap();
	
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "obj_teleporter")) != INVALID_ENT_REFERENCE) {
		OnEntityCreated(iEntity, "obj_teleporter");
	}
	
	AutoExecConfig(); // plugin.telequeue.cfg
}

public void OnConfigsExecuted() {
	char sValue[64];
	g_hQueueClass.GetString(sValue, sizeof(sValue));
	
	Array_Fill(g_iClassOrder, sizeof(g_iClassOrder), -1);
	
	char sClasses[10][10] = {"unknown", "scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"};
	
	char sArg[16];
	int iIdx = 0;
	int iOrder = 0;
	int iLength = strlen(sValue);
	
	while (iIdx < iLength) {
		BreakString(sValue[iIdx], sArg, sizeof(sArg));
		int iClass = Array_FindString(sClasses, sizeof(sClasses), sArg);
		g_iClassOrder[iClass] = iOrder++;
		iIdx += strlen(sArg)+1;
	}
}

public void OnClientDisconnect(int iClient) {
	removeFromTeleQueue(iClient);
}

public void OnEntityCreated(int iEntity, const char[] sClassName) {
	if (StrEqual(sClassName, "obj_teleporter") && view_as<TFObjectMode>(GetEntProp(iEntity, Prop_Send, "m_iObjectMode")) == TFObjectMode_Entrance) {
		char sKey[5];
		sKey[0] = (iEntity      ) & 0xFF;
		sKey[1] = (iEntity >>  8) & 0xFF;
		sKey[2] = (iEntity >> 16) & 0xFF;
		sKey[3] = (iEntity >> 24) & 0xFF;
		g_hTeleMap.SetValue(sKey, new ArrayList());
		SDKHookEx (iEntity, SDKHook_Touch, Hook_OnTouch);
		SDKHookEx (iEntity, SDKHook_StartTouch, Hook_OnStartTouch);
		SDKHookEx (iEntity, SDKHook_EndTouch, Hook_OnEndTouch);
	}
}

public void OnEntityDestroyed(int iEntity) {
	char sClassName[32];
	GetEntityClassname(iEntity, sClassName, sizeof(sClassName));
	
	if (StrEqual(sClassName, "obj_teleporter") && view_as<TFObjectMode>(GetEntProp(iEntity, Prop_Send, "m_iObjectMode")) == TFObjectMode_Entrance) {
		SDKUnhook(iEntity, SDKHook_Touch, Hook_OnTouch);
		
		
		char sKey[5];
		sKey[0] = (iEntity      ) & 0xFF;
		sKey[1] = (iEntity >>  8) & 0xFF;
		sKey[2] = (iEntity >> 16) & 0xFF;
		sKey[3] = (iEntity >> 24) & 0xFF;
		
		ArrayList hTeleQueue = null;
		g_hTeleMap.GetValue(sKey, hTeleQueue);
		
		if (hTeleQueue != null) {
			for (int i = 1; i <= MaxClients; i++) {
				if (g_iQueuing[i] == iEntity) {
					g_iQueuing[i] = INVALID_ENT_REFERENCE;
					g_iQueueInfo[i] = 0;
				}
			}
			
			g_hTeleMap.Remove(sKey);
			delete hTeleQueue;
		}
	}
}

public Action OnRoundStart(Handle hEvent, const char[] sName, bool bDontBroadcast) {
	Array_Fill(g_iQueuing, sizeof(g_iQueuing), INVALID_ENT_REFERENCE);
}

public Action Hook_OnTouch(int iEntity, int iOther) {
	if (Client_IsValid(iOther)) {
		if (g_hQueueOrder.IntValue) {
			ArrayList hQueue = getTeleQueue(iEntity);
			if (hQueue.Length > 0 && hQueue.Get(0) == iOther && GetEntProp(iEntity, Prop_Send, "m_iState") == 2) {
				return Plugin_Continue;
			}
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Hook_OnStartTouch(int iEntity, int iOther) {
	if (Client_IsValid(iOther)) {
		if (g_hQueueOrder.IntValue) {
			int iBuilder = GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder");
			TFClassType iClass = TF2_GetPlayerClass(iOther);
			if (g_iClassOrder[iClass] != -1 && (GetClientTeam(iBuilder) == GetClientTeam(iOther) || iClass == TFClass_Spy)) {
				ArrayList hQueue = getTeleQueue(iEntity);
				hQueue.Push(iOther);
				g_iQueuing[iOther] = iEntity;
				g_iQueueInfo[iOther] = GetEntProp(iEntity, Prop_Send, "m_iTimesUsed");
				
				SortADTArrayCustom(hQueue, Sort_TeleOrder, view_as<Handle>(iEntity));
			}
			
			return Plugin_Handled;
		} else {
			TFClassType iClass = TF2_GetPlayerClass(iOther);
			if (g_iClassOrder[iClass] == -1) {
				return Plugin_Handled;
			}
		}
		
	}
	
	return Plugin_Continue;
}

public Action Hook_OnEndTouch(int iEntity, int iOther) {
	if (!Client_IsValid(iOther)) {
		return Plugin_Continue;
	}
	
	removeFromTeleQueue(iOther);
	
	return Plugin_Handled;
}


// Commands
#if defined DEBUG
public Action Command_TeleInfo(int iClient, int iArgs) {
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "obj_teleporter")) != INVALID_ENT_REFERENCE) {
		if (GetEntPropEnt(iEntity, Prop_Send, "m_hBuilder") == iClient && view_as<TFObjectMode>(GetEntProp(iEntity, Prop_Send, "m_iObjectMode")) == TFObjectMode_Entrance) {
			ArrayList hQueue = getTeleQueue(iEntity);
			if (hQueue.Length) {
				ReplyToCommand(iClient, "Your teleporter queue:");
				for (int i = 0; i < hQueue.Length; i++) {
					ReplyToCommand(iClient, "  %d. %N", i+1, hQueue.Get(i));
				}
			} else {
				ReplyToCommand(iClient, "Your teleporter queue is empty");
			}
			
			return Plugin_Handled;
		}
	}
	
	ReplyToCommand(iClient, "Your have no teleporter entrances");
	
	return Plugin_Handled;
}
#endif

// Helpers

ArrayList getTeleQueue(int iEntity) {
	char sKey[5];
	sKey[0] = (iEntity      ) & 0xFF;
	sKey[1] = (iEntity >>  8) & 0xFF;
	sKey[2] = (iEntity >> 16) & 0xFF;
	sKey[3] = (iEntity >> 24) & 0xFF;
	
	ArrayList hTeleQueue = null;
	g_hTeleMap.GetValue(sKey, hTeleQueue);
	
	return hTeleQueue;
}

void removeFromTeleQueue(int iClient) {
	int iEntity = g_iQueuing[iClient];
	if (iEntity != INVALID_ENT_REFERENCE) {
		ArrayList hQueue = getTeleQueue(iEntity);
		if (hQueue != null) {
			int iIdx;
			while ((iIdx = hQueue.FindValue(iClient)) != -1) {
				hQueue.Erase(iIdx);
			}
		}
	}
	
	g_iQueuing[iClient] = INVALID_ENT_REFERENCE;
}

public int Sort_TeleOrder(int iIdxA, int iIdxB, Handle hArray, Handle hHandle) {
	ArrayList hQueue = view_as<ArrayList>(hArray);
	int iClientA = hQueue.Get(iIdxA);
	int iClientB = hQueue.Get(iIdxB);
	
	int iEntity = view_as<int>(hHandle); // Teleporter
	
	int iCompare = 0;
	
	int iMax = g_hQueueMax.IntValue;
	if (iMax) {
		int iTeleUsed = GetEntProp(iEntity, Prop_Send, "m_iTimesUsed");
		if ((iTeleUsed - g_iQueueInfo[iClientA]) > iMax) {
			iCompare -= MAXSKIP_WEIGHT;
		}
		
		if ((iTeleUsed - g_iQueueInfo[iClientB]) > iMax) {
			iCompare += MAXSKIP_WEIGHT;
		}
	}
	
	
	if (CheckCommandAccess(iClientA, DONOR_ACCESS_OVERRIDE, ADMFLAG_ROOT)) {
		iCompare -= DONOR_WEIGHT;
	}
	
	if (CheckCommandAccess(iClientB, DONOR_ACCESS_OVERRIDE, ADMFLAG_ROOT)) {
		iCompare += DONOR_WEIGHT;
	}
	
	
	TFClassType iClassA = TF2_GetPlayerClass(iClientA);
	TFClassType iClassB = TF2_GetPlayerClass(iClientB);
	
	if (g_hQueueOrder.IntValue < 2) {
		return iCompare;
	}
	
	return iCompare + (g_iClassOrder[view_as<int>(iClassA)] - g_iClassOrder[view_as<int>(iClassB)]);
}
