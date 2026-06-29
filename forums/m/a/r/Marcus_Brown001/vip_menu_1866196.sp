#include <sourcemod>
#include <sdktools>

new bool:Gun[MAXPLAYERS+1] = {false,...};
new Handle:VIP;

public Plugin:myinfo=
{
    name= "Vip_Ginklai",
    author= "unknown",
    description="VIP ginklai",
    version="1",
    url="www.FraG.Lt"
} 
public OnMapStart() {
	VIP = BuildVIPMenu();
}
public OnPluginStart() {
	RegAdminCmd("sm_vip", CommandVIP, ADMFLAG_CUSTOM1, "Displays the VIP menu");
	HookEvent("round_start", Event_RoundStart);
}
public OnClientAuthorized(client, const String:auth[]) {
	if (IsClientConnected(client)) {
		Gun[client] = false;
	}
}
public OnMapEnd() {
	if (VIP != INVALID_HANDLE) {
		CloseHandle(VIP);
		VIP = INVALID_HANDLE;
	}
}
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i = 1;i < MaxClients;i++) {
		if (!IsFakeClient(i)) {
			if (CheckCommandAccess(i, "sm_vip", ADMFLAG_CUSTOM1, false)) {
				DisplayMenu(VIP, i, 40);
			}
		}
	}
}
public Menu_VIP(Handle:vip, MenuAction:action, client, param2) {
	if (!Gun[client]) {
		if (action == MenuAction_Select) {
			decl String:info[32];
			GetMenuItem(vip, param2, info, sizeof(info));
			
			if (StrEqual(info, "1")) {
				GivePlayerItem(client, "weapon_deagle");
				GivePlayerItem(client, "weapon_m4a1");
			} else if (StrEqual(info, "2")) {
				GivePlayerItem(client, "weapon_deagle");
				GivePlayerItem(client, "weapon_ak47");
			} else if (StrEqual(info, "3")) {
				GivePlayerItem(client, "weapon_deagle");
				GivePlayerItem(client, "weapon_awp");
			}
			Gun[client] = true;
		}
	} else {
		PrintToChat(client, "[\x04WarShare\x01] Moznost si mozes vybrat iba raz za kolo.");
	}
}
Handle:BuildVIPMenu() {
	new Handle:vip = CreateMenu(Menu_VIP);
	SetMenuTitle(vip, "VIP Menu:");
	AddMenuItem(vip, "1", "M4A1 + Deagle");    
	AddMenuItem(vip,"2", "AK47 + Deagle");
	AddMenuItem(vip, "3" , "AWP + Deagle");
	return vip;
}
public Action:CommandVIP(client, args) {
	if (IsClientConnected(client) && IsPlayerAlive(client)) {
		DisplayMenu(VIP, client, 40);
	}
	return Plugin_Handled;
}