#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.3"
new Handle:g_hEnabled = INVALID_HANDLE;
new bool:g_bEnabled = true;
new g_remCount;
new String:g_remArray[128][64];
public Plugin:myinfo = 
{
	name = "WpnBlock",
	author = "MikeJS",
	description = "Block usage of certain weapons.",
	version = PLUGIN_VERSION,
	url = "http://mikejs.byethost18.com/"
}
public OnPluginStart() {
	CreateConVar("sm_wpnblock_version", PLUGIN_VERSION, "WpnBlock version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled = CreateConVar("sm_wpnblock", "1", "Enable WpnBlock.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_wpnblock_add", Command_add, ADMFLAG_KICK, "Add a blocked weapon.");
	RegAdminCmd("sm_wpnblock_clear", Command_clear, ADMFLAG_KICK, "Clear list of blocked weapons.");
	RegAdminCmd("sm_wpnblock_list", Command_list, ADMFLAG_KICK, "Show blocked weapons.");
	HookConVarChange(g_hEnabled, Cvar_enabled);
}
public OnMapStart() {
	CreateTimer(5.0, WpnCheck);
}
public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hEnabled);
}
public Cvar_enabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_bEnabled = GetConVarBool(g_hEnabled);
	if(g_bEnabled) {
		WpnCheck(INVALID_HANDLE);
	}
}
public Action:WpnCheck(Handle:timer) {
	new ent;
	decl String:wpn[64];
	for(new x=1;x<=MaxClients;x++) {
		if(IsClientConnected(x) && IsClientInGame(x) && IsPlayerAlive(x)) {
			for(new y=0;y<6;y++) {
				if((ent = GetPlayerWeaponSlot(x, y))!=-1) {
					GetEdictClassname(ent, wpn, sizeof(wpn));
					for(new z=0;z<g_remCount;z++) {
						if(StrEqual(wpn, g_remArray[z])) {
							new weaponIndex;
							while((weaponIndex = GetPlayerWeaponSlot(x, y))!=-1) {
								RemovePlayerItem(x, weaponIndex);
								RemoveEdict(weaponIndex);
							}
							PrintToChat(x, "\x01[SM] Weapon \"\x04%s\x01\" has been disabled.", wpn);
						}
					}
				}
			}
		}
	}
	if(g_bEnabled) {
		CreateTimer(5.0, WpnCheck);
	}
}
public Action:Command_add(client, args) {
	decl String:argstr[64];
	GetCmdArgString(argstr, sizeof(argstr));
	StripQuotes(argstr);
	TrimString(argstr);
	g_remArray[g_remCount++] = argstr;
	return Plugin_Handled;
}
public Action:Command_clear(client, args) {
	g_remCount = 0;
	return Plugin_Handled;
}
public Action:Command_list(client, args) {
	ReplyToCommand(client, "Blocked weapons:");
	for(new i=0;i<g_remCount;i++) {
		ReplyToCommand(client, "%s", g_remArray[i]);
	}
	ReplyToCommand(client, "Total blocked: %i", g_remCount);
	return Plugin_Handled;
}