#pragma semicolon 1

#include <sourcemod>
#include <gungame>
#include <colors>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "GunGame:SM Buy Level",
	author = "PhO3n1X",
	description = "Allows players to buy a new level",
	version = PLUGIN_VERSION,
	url = "http://www.gungame.lv"
};

new g_iAccount = -1;
new bool:g_Players[MAXPLAYERS + 1] = {false, ...};
new Handle:g_Price;

public OnPluginStart()
{
	CreateConVar("gungame_buy_version", PLUGIN_VERSION, "GunGame buy version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Price = CreateConVar("gg_buy_price", "16000", "New level buy price", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_PROTECTED, true, 0.0, true, 16000.0);
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	
	RegConsoleCmd("sm_buy", Command_Buy);
	HookEvent("round_start", Round_Start, EventHookMode_PostNoCopy);
	
	LoadTranslations("gungame_buy");
}

public OnClientPutInServer(client)
{
	g_Players[client] = false;
}

public Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i=1; i<=MaxClients; i++) {
		g_Players[i] = false;
	}
}

public Action:Command_Buy(client, args)
{
	if ( !client || !IsClientInGame(client) || g_iAccount == -1 ) {
		return Plugin_Handled;
	}
	
	if ( GG_IsWarmupInProgress() ) {
		CPrintToChat(client, "%t", "You can not use this command");
		return Plugin_Handled;
	}
	
	if (g_Players[client]) {
		CPrintToChat(client, "%t", "Command limit reached");
		return Plugin_Handled;
	}
	
	new buy_price = GetConVarInt(g_Price);
	new money = GetEntData(client, g_iAccount);
	
	if ( money < buy_price ) {
		CPrintToChat(client, "%t", "Not enough money", buy_price);
		return Plugin_Handled;
	}
	
	new level = GG_GetClientLevel(client);
	decl String:weapon[64];
	GG_GetLevelWeaponName(level, weapon, sizeof(weapon));
	
	if ( StrEqual(weapon, "knife") ) {
		CPrintToChat(client, "%t", "This command can not be used on last level");
		return Plugin_Handled;
	}
	
	GG_AddALevel(client);
	SetEntData(client, g_iAccount, (money - buy_price));
	g_Players[client] = true;
	
	CPrintToChat(client, "%t", "You purchased new level");
	
	return Plugin_Handled;
}
