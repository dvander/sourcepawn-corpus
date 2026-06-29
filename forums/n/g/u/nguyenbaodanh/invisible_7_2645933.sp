#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <sdkhooks>
#include <csgo_colors>


#define PLUGIN_VERSION "1.3"
#define msg "{GREEN}[Invisible Mod] %t"
#define msg2 "{GREEN}[Invisible Mod] %t %t"
new player_tD;
new TeamRand_weapon;
new xd;
new timerender;
new Invisible[MAXPLAYERS+1];
new Bonus[MAXPLAYERS+1];
new Handle:BonusMenu;

public Plugin:myinfo = 
{
	name		= "Invisible Mod",
	author		= "Str1k3r. Fix By https://vk.com/sdrcsgo",
	description = "Invisible Mod for Counter-Strike: Global Offensive",
	version		= PLUGIN_VERSION,
	url			= "https://steamcommunity.com/id/TheVampireDiaries0/"
}

public OnPluginStart() 
{
	LoadTranslations("plugin.invisible");
	RegConsoleCmd("jointeam", cmd_jointeam);
	RegConsoleCmd("joinclass", cmd_suicide);
	RegConsoleCmd("spectate", cmd_spectate);
	RegConsoleCmd("kill", cmd_suicide);
	RegConsoleCmd("explode", cmd_suicide);
	HookEvent("round_end", Event_RoundEndX);
	HookEvent("round_start", Event_RoundStartX);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	ServerCommand("mp_round_restart_delay 5.0");
	
	BonusMenu = CreateMenu(BHandler);
	SetMenuTitle(BonusMenu, "[Invisible]Bonus menu:");
	AddMenuItem(BonusMenu, "1", "Tang hinh mot phan");
	AddMenuItem(BonusMenu, "2", "Speed");
	AddMenuItem(BonusMenu, "3", "Health");
	SetMenuExitButton(BonusMenu, true);
}

public OnMapStart()
{
	new ent = CreateEntityByName("func_hostage_rescue");
	if (ent > 0)
	{
		new Float:orign[3] = {-1000.0,...};
		DispatchKeyValue(ent, "targetname", "invisible_roundend");
		DispatchKeyValueVector(ent, "orign", orign);
		DispatchSpawn(ent);
	}
}

public BHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (IsClientInGame(param1) && IsPlayerAlive(param1) && GetClientTeam(param1) == 3)
		{
			decl String:info[256];
			GetMenuItem(menu, param2, info, sizeof(info));
			if (StrEqual(info, "1"))
			{
				if (Bonus[param1] > 0)
				{
					SetEntityRenderColor(param1, 255, 255, 255, 65);
					SetEntityRenderMode(param1, RENDER_TRANSCOLOR);
					Bonus[param1]--;
					CGOPrintToChat(param1, "{DEFAULT}[{RED}Invisible{DEFAULT}]: {BLUE}Partial invisibility activated.");
				}
			}
			else if (StrEqual(info, "2"))
			{
				if (Bonus[param1] > 0)
				{
					SetEntPropFloat(param1, Prop_Data, "m_flLaggedMovementValue", 1.3);
					Bonus[param1]--;
					CGOPrintToChat(param1, "{DEFAULT}[{RED}Invisible{DEFAULT}]: {BLUE}Speed activated.");
				}
			}
			else if (StrEqual(info, "3"))
			{
				if (Bonus[param1] > 0)
				{
					SetEntityHealth(param1, GetClientHealth(param1) + 50);
					Bonus[param1]--;
					CGOPrintToChat(param1, "{DEFAULT}[{RED}Invisible{DEFAULT}]: {BLUE}Health gained.");
				}
			}
			if (Bonus[param1] > 0)
			{
				DisplayMenu(BonusMenu, param1, 20);
			}
		}
	}
}

public Action:PlayerDisconnect_Event(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) == 2) 
		{
			CGOPrintToChatAll(msg, "selecting random terrorist");
			CreateTimer(4.5, randominv);
		}
	}
}

public Action:randominv(Handle:timer)
{
	new t = GetRandomPlayer();
	for (new i=1;i<=MaxClients;i++) 
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				CS_SwitchTeam(i, 3);
			}
		}
	}
	if (t != -1)
	{
		xd = GetAlivePlayers();
		if (xd > 10)
		{
			for (new y=1;y<=2;y++)
			{
				CGOPrintToChatAll(msg, "2 t's", xd++);
				CS_SwitchTeam(t, 2);
				CS_RespawnPlayer(t);
				CGOPrintToChatAll(msg, "player go to terrorists", t);
				PrintCenterTextAll("Player %N is selected to be the next stealth!", t);
			}
		}
		else
		{
			if (IsClientInGame(t))
			{
				CGOPrintToChatAll(msg, "need more players for more t's", xd++);
				CS_SwitchTeam(t, 2);
				CS_RespawnPlayer(t);
				CGOPrintToChatAll(msg, "player go to terrorists", t);
				PrintCenterTextAll("Player  %N selected next stealth!", t);
			}
		}
	}
}

public Action:Event_ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl client;
	decl String:item[65];
	client = GetClientOfUserId(GetEventInt(event,"userid"));
	GetEventString(event,"item",item,sizeof(item));
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (GetClientTeam(client) == 2)
		{
			if(!StrEqual(item,"knife"))
			{
				decl entity;
				entity = GetPlayerWeaponSlot(client,2);
				if(entity != -1)
				{
					RemovePlayerWeapons(client);
					GivePlayerItem(client, "weapon_knife");
				}
			}
			else if (StrEqual(item,"weapon_knife"))
			{
				decl entity;
				entity = GetPlayerWeaponSlot(client,2);
				if(entity != -1)
				{
					SetEntityRenderMode(entity, RENDER_NONE);
					SetEntityRenderColor(entity, 255, 255, 255, 0);
					Invisible[2] = 0;
				}
			}
		}		
	}
}

public Action:cmd_jointeam(client, args) 
{
	if (IsClientInGame(client))
	{
		if (GetClientTeam(client) != CS_TEAM_T)
		{
			if (GetAliveT() > 0)
			{
				ChangeClientTeam(client, 3);
				CGOPrintToChat(client, msg2, "auto force", "ct");
				return Plugin_Handled;
			}
			else
			{
				ChangeClientTeam(client, 2);
				CGOPrintToChat(client, msg2, "auto force", "t");
				return Plugin_Handled;
			}
		}
		else if (GetClientTeam(client) == CS_TEAM_T)
		{
			CGOPrintToChat(client, msg, "terrorist suicide");
			return Plugin_Handled;
		}
		else
		{
			CGOPrintToChat(client, msg, "only choosen can be a terrorist");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

GetAliveT()
{
	new tpt = 0;
	for (new x=1;x<=MaxClients;x++)
	{
		if (IsClientInGame(x))
		{
			if (GetClientTeam(x) == 2)
			{
				tpt++;
			}
		}
	}
	return tpt;
}

public Action:cmd_suicide(client, args) 
{
	if (GetClientTeam(client) == 2) 
	{
		if (IsPlayerAlive(client)) 
		{
			CGOPrintToChat(client, msg, "terrorist suicide");
			return Plugin_Handled;		
		}
	}
	return Plugin_Continue;
}

public Action:cmd_spectate(client, args) 
{
	if (GetClientTeam(client) == 2) 
	{
		if (IsPlayerAlive(client)) 
		{
			CGOPrintToChat(client, msg, "terrorist suicide");
			return Plugin_Handled;		
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_RoundEndX(Handle:event, const String:name[], bool:dontBroadcast)
{
	timerender = 1;
	for (new xxx = 1; xxx <= MaxClients; xxx++)
	{
		if (IsClientInGame(xxx) && GetClientTeam(xxx) == 2)
		{
			Invisible[xxx] = 0;
		}
	}
	if (player_tD == 1)
	{
		CGOPrintToChatAll(msg, "selecting random terrorist");
		CreateTimer(4.5, randominv);
	}
	else
	{
		for (new xxx=1;xxx<=MaxClients;xxx++)
		{
			if (IsClientInGame(xxx) && GetClientTeam(xxx) == 2)
			{
				CGOPrintToChatAll(msg, "Player dont death", xxx);
			}
		}
	}
	if (TeamRand_weapon == 0)
	{
		TeamRand_weapon = 1;
	}
	else if (TeamRand_weapon == 1)
	{
		TeamRand_weapon = 2;
	}
	else if (TeamRand_weapon == 2)
	{
		TeamRand_weapon = 3;
	}
	else if (TeamRand_weapon == 3)
	{
		TeamRand_weapon = 4;
	}
	else if (TeamRand_weapon == 4)
	{
		TeamRand_weapon = 0;
	}
	player_tD = 0;
}

public Action:Event_RoundStartX(Handle:event, const String:name[], bool:dontBroadcast)
{
	timerender = 0;
}

GetAlivePlayers()
{
	new fff = 0;
	for (new xsd=1;xsd<=MaxClients;xsd++)
	{
		if (IsClientInGame(xsd))
		{
			fff++;
		}
	}
	return fff;
}

RemovePlayerWeapons(client)
{
	for (new x=0; x<=4; x++)
	{
		if (GetPlayerWeaponSlot(client, x) != -1) 
		{
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, x));
		}
	}
}

public Action:InvisActivateT(Handle:timer)
{
	for (new x=1;x<=MaxClients;x++)
	{
		if (IsClientInGame(x) && IsPlayerAlive(x) && GetClientTeam(x) == 2)
		{
			CGOPrintToChat(x, msg, "invisible: activate invis");
			SetEntityRenderMode(x, RENDER_NONE);
			SetEntityRenderColor(x, 255, 255, 255, 0);
			Invisible[x] = 0;
		}
	}
}			

GetRandomPlayer() 
{
	new PlayerList[MaxClients];
	new PlayerCount;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == 3)
			{
				if (IsPlayerAlive(i))
				{
					PlayerList[PlayerCount++] = i;
				}
			}
		}
	}
	if (PlayerCount == 0) 
	{
		return -1;
	}
	return PlayerList[GetRandomInt(0, PlayerCount-1)];
}



public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) == 2)
	{
		RemovePlayerWeapons(client);
		CreateTimer(1.0, AddInvisToInvisible, client);
		GivePlayerItem(client, "weapon_knife");
		xd = GetAlivePlayers();
		if (xd > 15)
		{
			CreateTimer(1.0, RegenHP2, client, TIMER_REPEAT);
			SetEntityHealth(client, 300);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.6);
			SetEntityGravity(client, 0.35);
			CGOPrintToChat(client, msg, "Invisible!");
			CGOPrintToChatAll(msg, "super invisible", client, xd);	
		}
		else
		{
			CreateTimer(1.0, RegenHP, client, TIMER_REPEAT);
			SetEntityHealth(client, 200);
			SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.45);
			SetEntityGravity(client, 0.4);
			CGOPrintToChat(client, msg, "Invisible!");
		}
		if (Bonus[client] > 0)
		{
			CGOPrintToChatAll(msg, "player dont got bonus", client);
		}
	}
	else if (GetClientTeam(client) == 3)
	{
		CGOPrintToChat(client, msg, "CT's spawn msg");
		RemovePlayerWeapons(client);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityHealth(client, 100);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0);
		SetEntityGravity(client, 1.0);
		GivePlayerItem(client, "weapon_knife");	
		if (TeamRand_weapon == 0)
		{
			GivePlayerItem(client, "weapon_p90");
		}
		else if (TeamRand_weapon == 1)
		{
			GivePlayerItem(client, "weapon_galilar");
		}
		else if (TeamRand_weapon == 2)
		{
			GivePlayerItem(client, "weapon_m4a1_silencer");
		}
		else if (TeamRand_weapon == 3)
		{
			GivePlayerItem(client, "weapon_ak47");
		}
		else if (TeamRand_weapon == 4)
		{
			GivePlayerItem(client, "weapon_m4a1");
		}
		if (Bonus[client] > 0)
		{
			DisplayMenu(BonusMenu, client, 20);
			CreateTimer(1.0, RegenHPCT2, client, TIMER_REPEAT);
		}
		else
		{
			CreateTimer(1.0, RegenHPCT, client, TIMER_REPEAT);
		}
	}
}

public Action:RegenHP(Handle:timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client) == 2 && timerender == 0)
	{
		if (GetClientHealth(client) < 200)
		{
			SetEntityHealth(client, GetClientHealth(client) + 5);
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:AddInvisToInvisible(Handle:timer, any:client)
{
	SetEntityRenderMode(client, RENDER_NONE);
	SetEntityRenderColor(client, 255, 255, 255, 0);
}	

public Action:RegenHP2(Handle:timer, any:client)
{
	xd = GetAlivePlayers();
	if (xd > 15)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2 && timerender == 0)
		{
			if (GetClientHealth(client) < 300)
			{
				SetEntityHealth(client, GetClientHealth(client) + 8);
			}
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else 
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:RegenHPCT(Handle:timer, any:client)
{
	if (timerender == 0)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 3)
		{
			if (GetClientHealth(client) < 100)
			{
				SetEntityHealth(client, GetClientHealth(client) + 2);
			}
		}
		else
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:RegenHPCT2(Handle:timer, any:client)
{
	if (timerender == 0)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 3)
		{
			if (GetClientHealth(client) < 150)
			{
				SetEntityHealth(client, GetClientHealth(client) + 4);
			}
		}
		else 
		{
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3)
	{
		player_tD = 1;
		CGOPrintToChatAll(msg, "ct kill invisible", attacker, victim);
		Bonus[attacker]++;
	}
	else if (GetClientTeam(victim) == 2)
	{
		player_tD = 1;
	}
	else
	{
		player_tD = 0;
	}
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim	= GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (attacker != 0)
	{
		if (Invisible[victim] == 0)
		{
			if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 3)
			{
				CGOPrintToChatAll(msg, "invisible hurt", attacker, victim);
				SetEntityRenderMode(victim, RENDER_TRANSCOLOR);
				SetEntityRenderColor(victim, 255, 255, 255, 65);
				CreateTimer(1.0, InvisActivateT);
				Invisible[victim] = 1;
			}
		}
	}
}