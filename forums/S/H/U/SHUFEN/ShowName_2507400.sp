#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <clientprefs>
#include <colors_csgo>
#undef REQUIRE_PLUGIN
#include <zombiereloaded>
#define REQUIRE_PLUGIN

Handle hShowNameCookie;
int iClientShowHUD[MAXPLAYERS+1] = {false, ...};
bIsClientPressingLookAtWeapon[MAXPLAYERS+1] = {false, ...};

bool bLateLoad = false;
bool bValid_zombiereloaded = false;

public Plugin myinfo = {
	name = "[CS:GO] Simple Show Name",
	description = "Show name of aimed target under the crosshair",
	author = "SHUFEN from POSSESSION.tokyo",
	version = "1.1",
	url = "https://possession.tokyo"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("ShowName");

	bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTranslations("common.phrases");
	LoadTranslations("ShowName.phrases");

	RegConsoleCmd("sm_showname", Command_ShowHud);
	hShowNameCookie = RegClientCookie("ShowName", "ShowName Cookie", CookieAccess_Protected);

	SetCookieMenuItem(PrefMenu, 0, "");

	AddCommandListener(Command_LookAtWeaponPress, "+lookatweapon");
	AddCommandListener(Command_LookAtWeaponRelease, "-lookatweapon");

	if(bLateLoad) {
		for(int i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i)) {
				if(AreClientCookiesCached(i))
					OnClientCookiesCached(i);
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnAllPluginsLoaded() {
	bValid_zombiereloaded = LibraryExists("zombiereloaded");
}

public void OnClientCookiesCached(int client) {
	char sCookieValue[2];
	GetClientCookie(client, hShowNameCookie, sCookieValue, sizeof(sCookieValue));
	if(sCookieValue[0] == '\0') {
		SetClientCookie(client, hShowNameCookie, "0");
		strcopy(sCookieValue, sizeof(sCookieValue), "0");
	}
	iClientShowHUD[client] = StringToInt(sCookieValue);
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	bIsClientPressingLookAtWeapon[client] = false;
}

public void OnClientDisconnect(int client) {
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	iClientShowHUD[client] = 0;
	bIsClientPressingLookAtWeapon[client] = false;
}

public void PrefMenu(int client, CookieMenuAction actions, any info, char[] buffer, int maxlen) {
	if (actions == CookieMenuAction_DisplayOption) {
		switch(iClientShowHUD[client]) {
			case 0: FormatEx(buffer, maxlen, "%T: %T", "ShowName", client, "Disabled", client);
			case 1: FormatEx(buffer, maxlen, "%T: %T", "ShowName", client, "Enabled", client);
			case 2: FormatEx(buffer, maxlen, "%T: %T", "ShowName", client, "LookAtWeapon", client);
		}
	}

	if (actions == CookieMenuAction_SelectOption) {
		ToggleShowHud(client);
		ShowCookieMenu(client);
	}
}

public Action Command_ShowHud(int client, int args) {
	if(client < 1 || client > MaxClients) return Plugin_Handled;

	ToggleShowHud(client);
	return Plugin_Handled;
}

void ToggleShowHud(int client) {
	switch(iClientShowHUD[client]) {
		case 0: {
			iClientShowHUD[client] = 1;
			CReplyToCommand(client, "\x10[\x09ShowName\x10]\x05 %t", "EnabledMsg");
		}
		case 1: {
			iClientShowHUD[client] = 2;
			CReplyToCommand(client, "\x10[\x09ShowName\x10]\x05 %t", "LookAtWeaponMsg");
		}
		case 2: {
			iClientShowHUD[client] = 0;
			CReplyToCommand(client, "\x10[\x09ShowName\x10]\x05 %t", "DisabledMsg");
		}
	}
	
	char sCookieValue[2];
	IntToString(iClientShowHUD[client], sCookieValue, sizeof(sCookieValue));
	SetClientCookie(client, hShowNameCookie, sCookieValue);
}

public Action Command_LookAtWeaponPress(int client, const char[] command, int argc)
{
	if(!IsClientInGame(client))
		return Plugin_Continue;

	bIsClientPressingLookAtWeapon[client] = true;
	return Plugin_Continue;
}

public Action Command_LookAtWeaponRelease(int client, const char[] command, int argc)
{
	if(!IsClientInGame(client))
		return Plugin_Continue;

	bIsClientPressingLookAtWeapon[client] = false;
	return Plugin_Continue;
}

public void OnPostThinkPost(int client) {
	if ((iClientShowHUD[client] == 1 || (iClientShowHUD[client] == 2 && bIsClientPressingLookAtWeapon[client])) && IsClientInGame(client)) {
		int iClientTeam = GetClientTeam(client);
		int target = GetClientAimTarget2(client);
		if(target > 0 && target <= MaxClients && IsClientInGame(target) && IsPlayerAlive(target)) {
			if(bValid_zombiereloaded) {
				bool bIsClientHuman = false;
				if((IsPlayerAlive(client) && ZR_IsClientHuman(client)) || iClientTeam == CS_TEAM_CT) bIsClientHuman = true;
				bool bIsTargetHuman = ZR_IsClientHuman(target);
				if(bIsTargetHuman) {
					if(iClientTeam > 1 && iClientTeam <= CS_TEAM_CT)
						ShowName(client, "Human", {154, 205, 255, 255}, target, bIsClientHuman);
					else {
						char client_specmode[10];
						GetClientInfo(client, "cl_spec_mode", client_specmode, 9);
						if(StringToInt(client_specmode) == 6)
							ShowName(client, "Human", {154, 205, 255, 255}, target, true);
					}
				} else {
					if(iClientTeam > 1 && iClientTeam <= CS_TEAM_CT)
						ShowName(client, "Zombie", {255, 62, 62, 255}, target, !bIsClientHuman);
					else {
						char client_specmode[10];
						GetClientInfo(client, "cl_spec_mode", client_specmode, 9);
						if(StringToInt(client_specmode) == 6)
							ShowName(client, "Zombie", {255, 62, 62, 255}, target, true);
					}
				}
			} else {
				int iTargetTeam = GetClientTeam(target);
				if(iTargetTeam == CS_TEAM_CT) {
					if(iClientTeam == iTargetTeam)
						ShowName(client, "Friend", {154, 205, 255, 255}, target, true);
					else if(iClientTeam > 1 && iClientTeam <= CS_TEAM_CT)
						ShowName(client, "Enemy", {154, 205, 255, 255}, target, false);
					else {
						char client_specmode[10];
						GetClientInfo(client, "cl_spec_mode", client_specmode, 9);
						if(StringToInt(client_specmode) == 6)
							ShowName(client, "", {154, 205, 255, 255}, target, true);
					}
				}
				else {
					if(iClientTeam == iTargetTeam)
						ShowName(client, "Friend", {255, 62, 62, 255}, target, true);
					else if(iClientTeam > 1 && iClientTeam <= CS_TEAM_CT)
						ShowName(client, "Enemy", {255, 62, 62, 255}, target, false);
					else {
						char client_specmode[10];
						GetClientInfo(client, "cl_spec_mode", client_specmode, 9);
						if(StringToInt(client_specmode) == 6)
							ShowName(client, "", {255, 62, 62, 255}, target, true);
					}
				}
			}
		}
	}
}

stock int GetClientAimTarget2(int client) {
	float fPosition[3];
	float fAngles[3];
	GetClientEyePosition(client, fPosition);
	GetClientEyeAngles(client, fAngles);

	Handle hTrace = TR_TraceRayFilterEx(fPosition, fAngles, MASK_SOLID, RayType_Infinite, TraceRayFilter, client);

	if(TR_DidHit(hTrace)) {
		int entity = TR_GetEntityIndex(hTrace);
		delete hTrace;
		return entity;
	}

	delete hTrace;
	return -1;
}

public bool TraceRayFilter(int entity, int mask, any client) {
	if(entity == client)
		return false;

	return true;
}

void ShowName(int client, char[] sPhrase, int iColor[4], int target, bool bShowHealth) {
	SetHudTextParamsEx(-1.0, 0.52, 0.2, iColor, {0, 0, 0, 255}, 0, 0.0, 0.0, 0.0);
	char sBuffer[128];
	if(sPhrase[0] == '\0')
		FormatEx(sBuffer, sizeof(sBuffer), "%N %T: #%i %T: %i", target, "UserID", client, GetClientUserId(target), "Health", client, GetClientHealth(target));
	else if(bShowHealth)
		FormatEx(sBuffer, sizeof(sBuffer), "%T: %N %T: #%i %T: %i", sPhrase, client, target, "UserID", client, GetClientUserId(target), "Health", client, GetClientHealth(target));
	else
		FormatEx(sBuffer, sizeof(sBuffer), "%T: %N %T: #%i", sPhrase, client, target, "UserID", client, GetClientUserId(target));
	ShowHudText(client, 5, sBuffer);
}