#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.8"

public Plugin:myinfo = {
	name = "Killstreak",
	author = "Dr_Knuckles / Kredit",
	description = "Killstreak value toggle",
	version = PLUGIN_VERSION,
	url = "http://www.the-vaticancity.com"
};

new Handle:hKillstreakAmount = INVALID_HANDLE;
new bool:KSToggle[MAXPLAYERS + 1] = {};
new KSAmount[MAXPLAYERS + 1] = {};

//clientprefs
new Handle:hKSToggleCookie = INVALID_HANDLE;
new Handle:hKSAmountCookie = INVALID_HANDLE;

public OnPluginStart() {
	RegAdminCmd("sm_ks", CommandKillstreak, ADMFLAG_CUSTOM1, "Set your killstreak.");
	hKSToggleCookie = RegClientCookie("killstreak_kstoggle", "Killstreak Toggle", CookieAccess_Protected);
	hKSAmountCookie = RegClientCookie("killstreak_ksamount", "Killstreak Amount", CookieAccess_Protected);

	hKillstreakAmount = CreateConVar("sm_killstreak_amount", "10", "Default Killstreak Amount", FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoExecConfig();
	CreateConVar("sm_ks_version", PLUGIN_VERSION, "Killstreak modifier", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookEvent("player_spawn", Event_Spawn);

	for (new i = MaxClients; i > 0; --i) {
		if (!AreClientCookiesCached(i)) continue;
		OnClientCookiesCached(i);
	}
}

public OnClientCookiesCached(client) {
	new KSAmountValue = 0;
	new bool:bKSToggleValue = false;

	if (AreClientCookiesCached(client)) {
		//Get KSToggle boolean from clientprefs (if it exists)
		decl String:sKSToggleCookieValue[5];
		GetClientCookie(client, hKSToggleCookie, sKSToggleCookieValue, sizeof(sKSToggleCookieValue));
		bKSToggleValue = StrEqual(sKSToggleCookieValue, "true");

		//Get KSAmount int from clientprefs (if it exists)
		decl String:sKSAmountCookieValue[4];
		GetClientCookie(client, hKSAmountCookie, sKSAmountCookieValue, sizeof(sKSAmountCookieValue));
		KSAmountValue = StringToInt(sKSAmountCookieValue);
	}

	//Load them into local memory (faster)
	KSToggle[client] = bKSToggleValue;
	KSAmount[client] = KSAmountValue;

	refreshKillstreak(client);
}

public OnClientDisconnect(client) {
	if (IsClientInGame(client)) {
		new String:sToggleValue[5];
		new String:sAmountValue[4];

		sToggleValue = KSToggle[client] ? "true" : "false";
		IntToString(KSAmount[client], sAmountValue, sizeof(sAmountValue));

		//Save clientprefs on disconnect
		SetClientCookie(client, hKSToggleCookie, sToggleValue);
		SetClientCookie(client, hKSAmountCookie, sAmountValue);
	}
}

public Action:CommandKillstreak(client, args) {
	if(IsClientInGame(client) && IsPlayerAlive(client)) {
		new String:sAmount[4];
		GetCmdArg(1, sAmount, sizeof(sAmount));

		//Initialize amount to whatever the convar is
		KSAmount[client] = GetConVarInt(hKillstreakAmount);

		//If there's an argument for sm_ks, use that value instead
		if(strlen(sAmount) > 0) {
			KSToggle[client] = true;
			KSAmount[client] = StringToInt(sAmount);
			//but keep it between 0 and 100
			if(KSAmount[client] > 100) {
				KSAmount[client] = 100;
			}
			if(KSAmount[client] < 0) KSAmount[client] = 0;
		}
		//If there isn't an argument, invert the toggle
		else {
			KSToggle[client] = !KSToggle[client];
		}
		
		//If the client set their killstreak to 0
		if(KSAmount[client] == 0) {
			KSToggle[client] = false;
		}

		//Update killstreak amount if the plugin is disabled
		if(!KSToggle[client]) {
			KSAmount[client] = 0;
		}

		//Set killstreak to argument value
		refreshKillstreak(client);

		//nofity client of changes
		if(KSAmount[client] > 0) {
			PrintToChat(client, "[SM] Killstreak set to %d.", KSAmount[client]);
		}
		else {
			PrintToChat(client, "[SM] Killstreak reset.");
		}
	}
	return Plugin_Handled;
}

public Event_Spawn(Handle:hEvent, const String:sName[], bool:bNoBroadcast) {
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (IsClientInGame(client) && IsPlayerAlive(client)) {
		refreshKillstreak(client);
	}
}

public refreshKillstreak(client) {
	if(IsValidEntity(client) && IsClientInGame(client) && !IsFakeClient(client)) {
		if(KSToggle[client] || KSAmount[client] == 0) {
			SetEntProp(client, Prop_Send, "m_nStreaks", KSAmount[client], _, 0);
		}
	}
}