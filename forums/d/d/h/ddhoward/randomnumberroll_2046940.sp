#include <sourcemod>

#define CHAT_PREFIX "[Roll]"

new Handle:hcvar_version = INVALID_HANDLE;
new Handle:hcvar_minimum = INVALID_HANDLE;
new Handle:hcvar_maximum = INVALID_HANDLE;
new Handle:hcvar_cooldown = INVALID_HANDLE;
new Handle:hcvar_cooldowntype = INVALID_HANDLE;
new Handle:hcvar_print = INVALID_HANDLE;

new Float:CooldownTimer[MAXPLAYERS+1];
new Float:AllCooldownTimer;


public Plugin:myinfo = {
	name = "Random Number Roll",
	author = "Derek Howard",
	description = "Allows players to roll a random number.",
	version = "13.1009.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart() {
	hcvar_version = CreateConVar("sm_randomnumberroll_version", PLUGIN_VERSION, "Random Number Roll Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_PLUGIN);
	SetConVarString(hcvar_version, PLUGIN_VERSION);
	HookConVarChange(hcvar_version, cvarChange);
	hcvar_minimum = CreateConVar("sm_randomnumberroll_minimum", "1", "Minimum Value", FCVAR_PLUGIN);
	hcvar_maximum = CreateConVar("sm_randomnumberroll_maximum", "100", "Maximum Value", FCVAR_PLUGIN);
	hcvar_cooldown = CreateConVar("sm_randomnumberroll_cooldown", "60", "Time between rolls", FCVAR_PLUGIN);
	hcvar_cooldowntype = CreateConVar("sm_randomnumberroll_cooldowntype", "0", "How does the cooldown work? 0 = When a player rolls, ONLY HE cannot roll for a while. 1 = A roll means that no one else can roll for a while.", FCVAR_PLUGIN);
	hcvar_print = CreateConVar("sm_randomnumberroll_print", "2", "Where should the result be displayed? 1 = console, 2 = chat, 3 = both", FCVAR_PLUGIN);
	RegAdminCmd("sm_roll", Command_Roll, 0);
}

public cvarChange(Handle:hHandle, const String:strOldValue[], const String:strNewValue[]) {
	if (hHandle == hcvar_version) {
		SetConVarString(hcvar_version, PLUGIN_VERSION);
	}
}

public Action:Command_Roll(client, args) {
	new Float:rolltime = GetEngineTime();
	if ((!GetConVarBool(hcvar_cooldowntype) && rolltime < CooldownTimer[client])
	|| (GetConVarBool(hcvar_cooldowntype) && rolltime < AllCooldownTimer)) {
		if (!CheckCommandAccess(client, "sm_randomnumberroll_cooldownimmune", ADMFLAG_BAN, true)) {
			ReplyToCommand(client, "%s You must wait %d seconds.", CHAT_PREFIX, RoundToCeil(CooldownTimer[client] - rolltime));
			return Plugin_Handled;
		}
	}
	AllCooldownTimer = rolltime + GetConVarFloat(hcvar_cooldown);
	CooldownTimer[client] = AllCooldownTimer;
	new rollednumber = GetRandomInt(GetConVarInt(sm_randomnumberroll_minimum), GetConVarInt(sm_randomnumberroll_maximum));
	if (GetConVarInt(hcvar_print) & 1) {
		for (new client = 1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && !IsFakeClient(client)) {
				PrintToConsole(client, "%s %N just rolled %i", CHAT_PREFIX, client, rollednumber);
			}
		}
	}
	if (GetConVarInt(hcvar_print) & 2) {
		PrintToChatAll("%s %N just rolled %i!", CHAT_PREFIX, client, rollednumber);
}