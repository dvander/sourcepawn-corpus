#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>

public Plugin:myinfo = {
	name		= "[CS:GO] Per-Client Bullet Impact",
	author		= "Dr. McKay",
	description	= "Toggles sv_showimpacts per client preference",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

new Handle:g_cookieImpacts;
new Handle:g_cookieImpactsTime;
new Handle:g_cvarImpactTimeOptions;
new Handle:sv_showimpacts;
new Handle:sv_showimpacts_time;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	sv_showimpacts = FindConVar("sv_showimpacts");
	if(sv_showimpacts == INVALID_HANDLE) {
		strcopy(error, err_max, "ConVar sv_showimpacts does not exist");
		return APLRes_Failure;
	}
	
	sv_showimpacts_time = FindConVar("sv_showimpacts_time");
	if(sv_showimpacts_time == INVALID_HANDLE) {
		strcopy(error, err_max, "ConVar sv_showimpacts_time does not exist");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public OnPluginStart() {
	g_cookieImpacts = RegClientCookie("bullet_impacts", "", CookieAccess_Private);
	g_cookieImpactsTime = RegClientCookie("bullet_impacts_time", "", CookieAccess_Private);
	g_cvarImpactTimeOptions = CreateConVar("bullet_impacts_time_options", "0.04,0.08,0.16,0.32,0.64,1.28,2.56", "Comma-separated list of available options for sv_showimpacts_time");
	
	SetCookieMenuItem(Handler_TopMenu, 1, "Show Bullet Impacts");
	SetCookieMenuItem(Handler_TopMenu, 2, "Show Bullet Impacts Time");
	
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
}

public OnClientCookiesCached(client) {
	decl String:value[16];
	GetClientCookie(client, g_cookieImpacts, value, sizeof(value));
	if(value[0] == '0' || value[0] == '1') {
		SendConVarValue(client, sv_showimpacts, value);
	}
	
	GetClientCookie(client, g_cookieImpactsTime, value, sizeof(value));
	if(strlen(value) > 0) {
		SendConVarValue(client, sv_showimpacts_time, value);
	}
}

public Handler_TopMenu(client, CookieMenuAction:action, any:info, String:buffer[], maxlen) {
	if(action == CookieMenuAction_SelectOption) {
		if(info == 1) {
			new Handle:menu = CreateMenu(Handler_SelectBulletImpacts);
			SetMenuTitle(menu, "Show Bullet Impacts");
			
			AddMenuItem(menu, "1", "Yes");
			AddMenuItem(menu, "0", "No");
			
			DisplayMenu(menu, client, 0);
		} else if(info == 2) {
			decl String:options[128];
			GetConVarString(g_cvarImpactTimeOptions, options, sizeof(options));
			decl String:parts[32][16];
			new total = ExplodeString(options, ",", parts, sizeof(parts), sizeof(parts[]));
			
			new Handle:menu = CreateMenu(Handler_SelectBulletImpactsTime);
			SetMenuTitle(menu, "Show Bullet Impacts Time");
			
			for(new i = 0; i < total; i++) {
				AddMenuItem(menu, parts[i], parts[i]);
			}
			
			DisplayMenu(menu, client, 0);
		}
	}
}

public Handler_SelectBulletImpacts(Handle:menu, MenuAction:action, client, param) {
	if(action == MenuAction_End) {
		CloseHandle(menu);
	}
	
	if(action == MenuAction_Select) {
		decl String:value[16];
		GetMenuItem(menu, param, value, sizeof(value));
		SetClientCookie(client, g_cookieImpacts, value);
		OnClientCookiesCached(client);
	}
}

public Handler_SelectBulletImpactsTime(Handle:menu, MenuAction:action, client, param) {
	if(action == MenuAction_End) {
		CloseHandle(menu);
	}
	
	if(action == MenuAction_Select) {
		decl String:value[16];
		GetMenuItem(menu, param, value, sizeof(value));
		SetClientCookie(client, g_cookieImpactsTime, value);
		OnClientCookiesCached(client);
	}
}