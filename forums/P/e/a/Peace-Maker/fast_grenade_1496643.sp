#include <sourcemod>
#include <sdktools>

new Handle:g_hCVNade;
new Handle:g_hCVNadePrice;
new Handle:g_hCVAds;
new Handle:g_hCVAdPrefix;

public OnPluginStart()
{
	CreateConVar("fgrenade_ver", "Version 1.0", "Fast Grenade version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hCVNade = CreateConVar("fgrenade_nade", "weapon_hegrenade", "Which grenade to give when buying?", FCVAR_PLUGIN);
	g_hCVNadePrice = CreateConVar("fgrenade_nadeprice", "3500", "What's the price of that grenade?", FCVAR_PLUGIN, true, 0.0);
	g_hCVAds = CreateConVar("fgrenade_ads", "1", "Enable advert on round start?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVAdPrefix = CreateConVar("fgrenade_advertprefix", "[!fg]", "Chat prefix?", FCVAR_PLUGIN);
	
	HookEvent("round_start", Event_OnRoundStart);
	
	RegConsoleCmd("sm_fg", Cmd_FastGrenade, "Open fast grenade menu");
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_hCVAds))
	{
		decl String:sPrefix[32];
		GetConVarString(g_hCVAdPrefix, sPrefix, sizeof(sPrefix));
		PrintToChatAll("\x04%s: type !fg to buy a fast grenade.", sPrefix);
	}
}

public Action:Cmd_FastGrenade(client, args)
{
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Fast Grenade 1.0");
	DrawPanelText(hPanel, "");
	DrawPanelText(hPanel, "----------------");
	DrawPanelItem(hPanel, "Grenade");
	DrawPanelText(hPanel, "----------------");
	SetPanelCurrentKey(hPanel, 10);
	DrawPanelItem(hPanel, "Exit");
	
	SendPanelToClient(hPanel, client, Panel_GiveNade, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Panel_GiveNade(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			new iMoney = GetEntProp(param1, Prop_Send, "m_iAccount");
			new iCosts = GetConVarInt(g_hCVNadePrice);
			if(iMoney < iCosts)
			{
				decl String:sPrefix[32];
				GetConVarString(g_hCVAdPrefix, sPrefix, sizeof(sPrefix));
				PrintToChat(param1, "\x04%s: You do not have money to buy a grenade.  You have %d and a grenade costs %d.", sPrefix, iMoney, iCosts);
				return;
			}
			
			SetEntProp(param1, Prop_Send, "m_iAccount", (iMoney - iCosts));
			decl String:sGrenade[64];
			GetConVarString(g_hCVNade, sGrenade, sizeof(sGrenade));
			GivePlayerItem(param1, sGrenade);
			
			Cmd_FastGrenade(param1, 0);
		}
	}
}