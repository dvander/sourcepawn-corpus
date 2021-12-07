/*  [CS:GO] tVip - Reserved Slots
 *
 *  Copyright (C) 2018 Daniel Sartor // kniv.com.br // plock@kniv.com.br
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdkhooks>
#include <autoexecconfig>

#pragma newdecls required

#define PLUGIN_AUTHOR "Plock, Totenfluch"
#define PLUGIN_VERSION "2.3"

int g_iReservedSlotsUsed = 0;
int g_iTotalPlayers = 0;
ArrayList g_aPlayersInGame;

ConVar g_ConVar_ReservedSlots;
ConVar g_ConVar_ServerSlots;
ConVar g_ConVar_Method;
ConVar g_ConVar_tVip;
ConVar g_ConVar_AdminFlag;
ConVar g_ConVar_VipFlag;
ConVar g_ConVar_PlayerJoin;
ConVar g_ConVar_PlayerLeft;
ConVar g_ConVar_AdminJoin;
ConVar g_ConVar_AdminLeft;
ConVar g_ConVar_RootBypass;
ConVar g_ConVar_CountSpectators;
ConVar g_ConVar_CountAdminSpectators;
ConVar g_ConVar_CountAdmins;
ConVar g_ConVar_CountVipSpectators;
ConVar g_ConVar_Debug;
ConVar g_ConVar_HiddenSlots;

bool g_bClientKicked[MAXPLAYERS + 1] =  { false, ... };
bool g_bIsVip[MAXPLAYERS + 1] =  { false, ... };
bool g_bIsAdmin[MAXPLAYERS + 1] =  { false, ... };

Handle g_hPlayerJoin;
Handle g_hPlayerLeft;

public Plugin myinfo =  {
	name = "tVip - Reserved Slots", 
	author = PLUGIN_AUTHOR, 
	version = PLUGIN_VERSION, 
	url = "https://kniv.com.br"
};

public void OnPluginStart() {
	
	AutoExecConfig_SetFile("tVip_ReservedSlots");
	AutoExecConfig_SetCreateFile(true);
	
	g_ConVar_ReservedSlots = AutoExecConfig_CreateConVar("tvip_reservedslots", "0", "Amount of reserved slots.", FCVAR_NONE);
	g_ConVar_ServerSlots = AutoExecConfig_CreateConVar("tvip_serverslots", "0", "Total amount of slots available.", FCVAR_NONE);
	g_ConVar_Method = AutoExecConfig_CreateConVar("tvip_method", "0", "0 = Default Reserved Slots. 1 = Kicks last player who joined the server (Until all reserved slots are occupied, after that it won't kick). 2 = Kick player with highest ping (Until all reserved slots are occupied, after that it won't kick). 3 = Default Reserved slots based on sv_visiblemaxplayers", FCVAR_NONE);
	g_ConVar_tVip = AutoExecConfig_CreateConVar("tvip_plugin", "1", "1 = Use tVip integration. Any other value will use OnClientPostAdminCheck verification.", FCVAR_NONE);
	g_ConVar_AdminFlag = AutoExecConfig_CreateConVar("tvip_adminflag", "d", "Flag to check Admin immunity.", FCVAR_NONE);
	g_ConVar_VipFlag = AutoExecConfig_CreateConVar("tvip_vipflag", "o", "Flag to check Vip permissions.", FCVAR_NONE);
	g_ConVar_PlayerJoin = AutoExecConfig_CreateConVar("tvip_playerjoin", "1", "Call forward when a player joined the server sucessfully.", FCVAR_NONE);
	g_ConVar_PlayerLeft = AutoExecConfig_CreateConVar("tvip_playerleft", "1", "Call forward when a player left the server, won't call on kick.", FCVAR_NONE);
	g_ConVar_AdminJoin = AutoExecConfig_CreateConVar("tvip_adminjoin", "1", "Call forward when an admin joined the server sucessfully.", FCVAR_NONE);
	g_ConVar_AdminLeft = AutoExecConfig_CreateConVar("tvip_adminleft", "1", "Call forward when an admin left the server, won't call on kick.", FCVAR_NONE);
	g_ConVar_RootBypass = AutoExecConfig_CreateConVar("tvip_rootbypass", "1", "Bypass root from flag check", FCVAR_NONE);
	g_ConVar_CountSpectators = AutoExecConfig_CreateConVar("tvip_countspectators", "1", "Count players in Spectators?", FCVAR_NONE);
	g_ConVar_CountAdminSpectators = AutoExecConfig_CreateConVar("tvip_countadminspectators", "1", "Count admins as players in Spectators?", FCVAR_NONE);
	g_ConVar_CountAdmins = AutoExecConfig_CreateConVar("tvip_countadmins", "1", "Count admins as players?", FCVAR_NONE);
	g_ConVar_CountVipSpectators = AutoExecConfig_CreateConVar("tvip_countvipspectators", "1", "Use reserved slots for VIPs in Specators?", FCVAR_NONE);
	g_ConVar_Debug = AutoExecConfig_CreateConVar("tvip_debug", "0", "Turn on debug messages for Reserved Slots", FCVAR_NONE);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("player_disconnect", Event_Player_Disc_Pre, EventHookMode_Pre);
	
	g_iReservedSlotsUsed = 0;
	
	g_aPlayersInGame = new ArrayList();
	
	LoadTranslations("tvip_reserved.phrases");
}

public void OnConfigsExecuted() {
	g_ConVar_HiddenSlots = FindConVar("sv_visiblemaxplayers");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_hPlayerJoin = CreateGlobalForward("tVip_ReservedSlotsJoin", ET_Ignore, Param_Cell);
	g_hPlayerLeft = CreateGlobalForward("tVip_ReservedSlotsLeft", ET_Ignore, Param_Cell);
}

public void OnMapStart() {
	g_aPlayersInGame = new ArrayList();
	
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i)) {
			continue;
		}
		
		if (HasClientFlags(i, g_ConVar_VipFlag)) {
			continue;
		}
		
		if (HasClientFlags(i, g_ConVar_AdminFlag)) {
			continue;
		}
		
		g_aPlayersInGame.Push(GetClientUserId(i));
		
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(i, "has been added to kick array list. Map Started, rebuilding array.");
		}
	}
}

public void tVip_OnClientLoadedPost(int client) {
	//We will use tVip! Yay \o/
	if (g_ConVar_tVip.IntValue == 1) {
		StartSlotReservationCheck(client);
	}
}

public void OnClientPostAdminCheck(int client) {
	//We will use OnClientPostAdminCheck! Eww :x
	if (g_ConVar_tVip.IntValue != 1) {
		StartSlotReservationCheck(client);
	}
}

public void StartSlotReservationCheck(int client) {
	if (g_ConVar_Debug.IntValue == 1) {
		logDebugMessages(client, "joined. Starting reserved slots check. Start Method: %s", g_ConVar_tVip.IntValue == 1 ? "tVip" : "OnClientPostAdminCheck");
	}
	
	g_bIsVip[client] = false;
	g_bIsAdmin[client] = false;
	
	if (HasClientFlags(client, g_ConVar_VipFlag)) {
		g_bIsVip[client] = true;
	}
	
	if (HasClientFlags(client, g_ConVar_AdminFlag)) {
		g_bIsAdmin[client] = true;
	}
	
	if (g_ConVar_Debug.IntValue == 1) {
		if (g_bIsAdmin[client] && g_bIsVip[client]) {
			logDebugMessages(client, "is Admin and VIP");
		} else if (g_bIsAdmin[client]) {
			logDebugMessages(client, "is Admin");
		} else if (g_bIsVip[client]) {
			logDebugMessages(client, "is VIP");
		} else {
			logDebugMessages(client, "is a Player");
		}
	}
	
	//If ConVars are set above 0
	if ((g_ConVar_ReservedSlots.IntValue > 0 && g_ConVar_ServerSlots.IntValue > 0) || (g_ConVar_Method.IntValue == 3 && g_ConVar_ServerSlots.IntValue > 0)) {
		
		//Count the number os players
		g_iTotalPlayers = 0;
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidClient(i)) {
				continue;
			}
			
			if (i == client) {
				continue;
			}
			
			if (!g_ConVar_CountSpectators.BoolValue && !g_bIsAdmin[i] && GetClientTeam(i) == 1) {
				continue;
			}
			
			if (!g_ConVar_CountAdminSpectators.BoolValue && g_bIsAdmin[i] && GetClientTeam(i) == 1) {
				continue;
			}
			
			if (!g_ConVar_CountAdmins.BoolValue && g_bIsAdmin[i]) {
				continue;
			}
			
			g_iTotalPlayers++;
		}
		if (IsValidClient(client)) {
			g_bClientKicked[client] = false;
			//Check drop methods
			if (g_ConVar_Debug.IntValue == 1) {
				logDebugMessages(client, "is going to Step 1. Kick Method? %s", g_ConVar_Method.IntValue == 0 ? "Default Reserved Slots" : (g_ConVar_Method.IntValue == 1 ? "Kick Latest Player" : "Kick Highest Ping"));
			}
			if (g_ConVar_Method.IntValue == 1 || g_ConVar_Method.IntValue == 2) {
				KickMethod(client);
			} else if (g_ConVar_Method.IntValue == 3) { 
				VisibleMaxPlayersMethod(client);
			} else {
				DefaultMethod(client);
			}
		}
	}
}

public Action Event_Player_Disc_Pre(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && g_bIsVip[client] && !g_bIsAdmin[client]) {
		g_iReservedSlotsUsed--;
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "(VIP) left");
		}
	} else if (IsValidClient(client) && !g_bIsVip[client] && g_bIsAdmin[client]) {
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "(ADMIN) left");
		}
	} 
	
	if (IsValidClient(client)) {
		int useridLeft = g_aPlayersInGame.FindValue(GetClientUserId(client));
		if (useridLeft != -1) {
			g_aPlayersInGame.Erase(useridLeft);
		}
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "left. Erasing client %N (%i) from array index %i (%i)", client, client, useridLeft, g_aPlayersInGame.Length);
		}
	}
	
	if (IsValidClient(client) && !g_bClientKicked[client]) {
		if ((g_ConVar_PlayerLeft.BoolValue && !g_bIsAdmin[client]) || (g_ConVar_AdminLeft.BoolValue && g_bIsAdmin[client])) {
			Call_StartForward(g_hPlayerLeft);
			Call_PushCell(client);
			Call_Finish();
		}
	}
}

public void KickMethod(int client) {
	//Count used reserved slots to keep it updated
	g_iReservedSlotsUsed = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i)) {
			continue;
		}
		
		if (i == client) {
			continue;
		}
		
		if (g_bIsAdmin[i]) {
			continue;
		}
		
		if (!g_bIsVip[i]) {
			continue;
		}
		
		if (g_iReservedSlotsUsed >= g_ConVar_ReservedSlots.IntValue) {
			continue;
		}
		
		if (!g_ConVar_CountVipSpectators.BoolValue && g_bIsVip[i] && GetClientTeam(i) == 1) {
			continue;
		}
		
		if (!g_ConVar_CountAdminSpectators.BoolValue && g_bIsAdmin[i] && GetClientTeam(i) == 1) {
			continue;
		}
		
		g_iReservedSlotsUsed++;
	}
	
	//Server can be full if there are free reserved slots
	if ((g_iTotalPlayers >= g_ConVar_ServerSlots.IntValue && g_iReservedSlotsUsed < g_ConVar_ReservedSlots.IntValue) || g_bIsAdmin[client]) {
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "is going to Step 2.1 (Kick). Total Players: %i/%i and Reserved Slots: %i/%i", g_iTotalPlayers, g_ConVar_ServerSlots.IntValue, g_iReservedSlotsUsed, g_ConVar_ReservedSlots.IntValue);
		}
		
		//Only kicks if server is full, it means reserved slots are free yet
		if (g_iTotalPlayers >= g_ConVar_ServerSlots.IntValue) {
			//He is a VIP, so we have to kick someone
			if (g_bIsVip[client] && !g_bIsAdmin[client]) {
				//He is still on the server
				if (g_ConVar_Method.IntValue == 1) {
					//Kick to free slot for VIP
					if (g_aPlayersInGame.Length > 0) {
						if (g_ConVar_Debug.IntValue == 1) {
							logDebugMessages(client, "is joining and kicking the latest player in array.");
						}
						
						int lastClient1 = GetClientOfUserId(g_aPlayersInGame.Get(g_aPlayersInGame.Length - 1));
						int lastClient2 = GetClientOfUserId(g_aPlayersInGame.Get(g_aPlayersInGame.Length - 2));
						
						if (IsValidClient(lastClient1) && 
								!g_bIsVip[lastClient1] && 
								!g_bIsAdmin[lastClient1]) {
							KickTheClient(lastClient1, "VIP Joined");
							
						} else if (IsValidClient(lastClient2) && 
									!g_bIsVip[lastClient2] && 
									!g_bIsAdmin[lastClient2]) {
							KickTheClient(lastClient2, "VIP Joined");
						} else {
							if (g_ConVar_Debug.IntValue == 1) {
								logDebugMessages(client, "Couldn't find a Player to Kick");
							}
						}
					}
				} else if (g_ConVar_Method.IntValue == 2) {
					if (g_ConVar_Debug.IntValue == 1) {
						logDebugMessages(client, "is joining and kicking the player with highest ping.");
					}
					//Find the one with highest ping
					FindHighestPingAndKick();
				}
				
				if ((g_ConVar_PlayerJoin.BoolValue && !g_bIsAdmin[client]) || (g_ConVar_AdminJoin.BoolValue && g_bIsAdmin[client])) {
					Call_StartForward(g_hPlayerJoin);
					Call_PushCell(client);
					Call_Finish();
				}
				//Server is full and he is not VIP to use reserved Slots.
			} else if (!g_bIsVip[client] && !g_bIsAdmin[client]) {
				if (g_ConVar_Debug.IntValue == 1) {
					logDebugMessages(client, "will be kicked. Server is full | Free reserved slots | Not VIP.");
				}
				//Make sure it won't kick an admin
				if (!HasClientFlags(client, g_ConVar_AdminFlag)) {
					//Server is full -> kick Client
					KickTheClient(client, "Server is Full");
				}
			}
			//Server is not full and player is not a VIP, then set as the last player who joined
		} else if (!g_bIsAdmin[client] && !g_bIsVip[client]) {
			if (g_ConVar_Debug.IntValue == 1) {
				logDebugMessages(client, "has been added to kick array list. Step 2.1.1");
			}
			
			g_aPlayersInGame.Push(GetClientUserId(client));
			
			if ((g_ConVar_PlayerJoin.BoolValue && !g_bIsAdmin[client]) || (g_ConVar_AdminJoin.BoolValue && g_bIsAdmin[client])) {
				Call_StartForward(g_hPlayerJoin);
				Call_PushCell(client);
				Call_Finish();
			}
		}
		//Server is full
	} else if ((g_iTotalPlayers >= g_ConVar_ServerSlots.IntValue && g_iReservedSlotsUsed >= g_ConVar_ReservedSlots.IntValue)) {
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "is going to Step 2.2 (Kick). Total Players: %i/%i and Reserved Slots: %i/%i", g_iTotalPlayers, g_ConVar_ServerSlots.IntValue, g_iReservedSlotsUsed, g_ConVar_ReservedSlots.IntValue);
		}
		//Make sure it won't kick an admin
		if (!g_bIsAdmin[client]) {
			//Server is full -> kick Client
			KickTheClient(client, "Server is Full");
		}
	} else {
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "is going to Step 2.3 (Kick). Total Players: %i/%i and Reserved Slots: %i/%i", g_iTotalPlayers, g_ConVar_ServerSlots.IntValue, g_iReservedSlotsUsed, g_ConVar_ReservedSlots.IntValue);
		}
		
		if (!g_bIsAdmin[client] && !g_bIsVip[client]) {
			if (g_ConVar_Debug.IntValue == 1) {
				logDebugMessages(client, "has been added to kick array list. Step 2.3.1");
			}
			
			g_aPlayersInGame.Push(GetClientUserId(client));
		}
		
		if ((g_ConVar_PlayerJoin.BoolValue && !g_bIsAdmin[client]) || (g_ConVar_AdminJoin.BoolValue && g_bIsAdmin[client])) {
			Call_StartForward(g_hPlayerJoin);
			Call_PushCell(client);
			Call_Finish();
		}
	}
}

public void VisibleMaxPlayersMethod(int client) {
	//Server must have an empty slot
	if (g_iTotalPlayers >= g_ConVar_ServerSlots.IntValue - (g_ConVar_ServerSlots.IntValue - g_ConVar_HiddenSlots.IntValue) && 
			g_iTotalPlayers < g_ConVar_ServerSlots.IntValue || 
				g_bIsAdmin[client]) {
					
		//Count used reserved slots to keep it updated
		g_iReservedSlotsUsed = g_iTotalPlayers - g_ConVar_HiddenSlots.IntValue;
		
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "is going to Step 3.1 (MaxVisiblePlayers). Total Players: %i/%i and Reserved Slots: %i/%i", g_iTotalPlayers, g_ConVar_HiddenSlots.IntValue, g_iReservedSlotsUsed, g_ConVar_ServerSlots.IntValue - g_ConVar_HiddenSlots.IntValue);
		}
		
		if (g_iReservedSlotsUsed >= 0 && g_iReservedSlotsUsed < g_ConVar_ServerSlots.IntValue - g_ConVar_HiddenSlots.IntValue) {
			if (g_ConVar_Debug.IntValue == 1) {
				logDebugMessages(client, "is going to Step 3.1.1 (MaxVisiblePlayers). There are free hidden slots.", g_iTotalPlayers, g_ConVar_ServerSlots.IntValue, g_iReservedSlotsUsed, g_ConVar_ReservedSlots.IntValue);
			}
		
			//Check player slots for non-vip only, because if he is VIP, he will join anyway, there are free slots
			if (!g_bIsVip[client] && !g_bIsAdmin[client]) {
				if (g_ConVar_Debug.IntValue == 1) {
					logDebugMessages(client, "is not VIP to use the Reserved Slots");
				}
				//Make sure it won't kick an admin
				if (!g_bIsAdmin[client]) {
					//Kick reason: reserved only
					KickTheClient(client, "Only VIP");
				}
			}
		} else {
			if (g_ConVar_Debug.IntValue == 1) {
				logDebugMessages(client, "will be kicked. Server is full.");
			}
			//Make sure it won't kick an admin
			if (!g_bIsAdmin[client]) {
				//Server is full -> kick Client
				KickTheClient(client, "Server is Full");
			}
		}
		
	//Server is full
	} else {
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "will be kicked. Server is full.");
		}
		//Make sure it won't kick an admin
		if (!g_bIsAdmin[client]) {
			//Server is full -> kick Client
			KickTheClient(client, "Server is Full");
		}
	}
}

public void DefaultMethod(int client) {
	//Server must have an empty slot
	if (g_iTotalPlayers < g_ConVar_ServerSlots.IntValue || HasClientFlags(client, g_ConVar_AdminFlag)) {
		//Count used reserved slots to keep it updated
		g_iReservedSlotsUsed = 0;
		for (int i = 1; i <= MaxClients; i++) {
			if (!IsValidClient(i)) {
				continue;
			}
			
			if (i == client) {
				continue;
			}
			
			if (g_bIsAdmin[i]) {
				continue;
			}
			
			if (!g_bIsVip[i]) {
				continue;
			}
			
			if (g_iReservedSlotsUsed >= g_ConVar_ReservedSlots.IntValue) {
				continue;
			}
			
			if (!g_ConVar_CountVipSpectators.BoolValue && g_bIsVip[i] && GetClientTeam(i) == 1) {
				continue;
			}
			
			if (!g_ConVar_CountAdminSpectators.BoolValue && g_bIsAdmin[i] && GetClientTeam(i) == 1) {
				continue;
			}
			
			g_iReservedSlotsUsed++;
		}
		
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "is going to Step 1.1 (Default). Total Players: %i/%i and Reserved Slots: %i/%i", g_iTotalPlayers, g_ConVar_ServerSlots.IntValue, g_iReservedSlotsUsed, g_ConVar_ReservedSlots.IntValue);
		}
		
		//Check player slots for non-vip only, because if he is VIP, he will join anyway, there are free slots
		if (!g_bIsVip[client] && !g_bIsAdmin[client]) {
			//Check if non-vip slots are free, if not, kick for reserved slots only.
			if ((g_iTotalPlayers - g_iReservedSlotsUsed) >= (g_ConVar_ServerSlots.IntValue - g_ConVar_ReservedSlots.IntValue)) {
				if (g_ConVar_Debug.IntValue == 1) {
					logDebugMessages(client, "is not VIP to use the Reserved Slots");
				}
				//Make sure it won't kick an admin
				if (!g_bIsAdmin[client]) {
					//Kick reason: reserved only
					KickTheClient(client, "Only VIP");
				}
			}
		}
		if (!g_bClientKicked[client]) {
			if ((g_ConVar_PlayerJoin.BoolValue && !g_bIsAdmin[client]) || (g_ConVar_AdminJoin.BoolValue && g_bIsAdmin[client])) {
				Call_StartForward(g_hPlayerJoin);
				Call_PushCell(client);
				Call_Finish();
			}
		}
		//Server is full
	} else {
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "is going to Step 1.2 (Default). Total Players: %i/%i and Reserved Slots: %i/%i", g_iTotalPlayers, g_ConVar_ServerSlots.IntValue, g_iReservedSlotsUsed, g_ConVar_ReservedSlots.IntValue);
		}
		//Make sure it won't kick an admin
		if (!g_bIsAdmin[client]) {
			//Server is full -> kick Client
			KickTheClient(client, "Server is Full");
		}
	}
}

public void FindHighestPingAndKick() {
	int unluckyGuy = -1;
	float ping = -1.0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && (GetClientAvgLatency(i, NetFlow_Both) >= ping) && !g_bIsAdmin[i] && !g_bIsVip[i]) {
			unluckyGuy = i;
			ping = GetClientAvgLatency(i, NetFlow_Both);
		}
	}
	
	KickTheClient(unluckyGuy, "VIP Joined Ping");
}

stock void KickTheClient(int client, char[] reason) {
	if (IsValidClient(client)) {
		if (g_ConVar_Debug.IntValue == 1) {
			logDebugMessages(client, "has been Kicked. Reason: %t", reason);
		}
		g_bClientKicked[client] = true;
		KickClientEx(client, "%t", reason);
	}
}

stock bool HasClientFlags(int client, ConVar convar)
{
	if (!IsValidClient(client)) {
		return false;
	}
	
	if (g_ConVar_RootBypass.BoolValue && (GetUserFlagBits(client) & ADMFLAG_ROOT)) {
		return true;
	}
	char flags[16];
	convar.GetString(flags, sizeof(flags));
	
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i]) == ReadFlagString(sflagNeed[i])))
		{
			bEntitled = true;
			break;
		}
	}
	
	return bEntitled;
}

stock bool logDebugMessages(int client, const char[] log, any...)
{
	if (g_ConVar_Debug.IntValue == 0) {
		return false;
	}
	
	if (!IsValidClient(client)) {
		return false;
	}
	
	char buffer[1024];
	VFormat(buffer, sizeof(buffer), log, 3);
	
	Handle myHandle = GetMyHandle();
	char sPlugin[PLATFORM_MAX_PATH];
	GetPluginFilename(myHandle, sPlugin, PLATFORM_MAX_PATH);
	
	char sPlayer[128];
	GetClientAuthId(client, AuthId_Steam2, sPlayer, sizeof(sPlayer));
	
	char sPlayerIp[32];
	GetClientIP(client, sPlayerIp, sizeof(sPlayerIp));
	Format(sPlayer, sizeof(sPlayer), "%N<%s><%s>", client, sPlayer, sPlayerIp);
	
	char sTime[64];
	FormatTime(sTime, sizeof(sTime), "%X", GetTime());
	Format(buffer, 1024, "[%s] %s: %s %s", sPlugin, sTime, sPlayer, buffer);
	
	char sDate[64];
	FormatTime(sDate, sizeof(sDate), "%y%m%d", GetTime());
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "logs/tvip_rs_%s.txt", sDate);
	File hFile = OpenFile(sPath, "a");
	if (hFile != INVALID_HANDLE)
	{
		WriteFileLine(hFile, buffer);
		delete hFile;
		return true;
	}
	else
	{
		LogError("Couldn't open Debug log file.");
		return false;
	}
}

stock bool IsValidClient(int client) {
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	if (IsFakeClient(client))
		return false;
	return true;
} 