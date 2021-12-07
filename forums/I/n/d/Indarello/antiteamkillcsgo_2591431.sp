#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <csgo_colors>


#define PLUGIN_VERSION "1.1"

new bool:has_admflag[MAXPLAYERS+1];
new cankill[MAXPLAYERS+1];
new bool:cantbepunished[MAXPLAYERS+1];
new bool:canbekill[MAXPLAYERS+1];
new teamattack[MAXPLAYERS+1];
new Ztime;
new Float:g_GameTime[MAXPLAYERS + 1];
new Handle:g_SteamIDTk = INVALID_HANDLE;
new Handle:g_TkAmount = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "Simple Anti Team kill",
	author = "mad_hamster, modified by Snake 60 & Geel9, Vdova",
	description = "Anti Team kill",
	version = PLUGIN_VERSION,
	url = "http://pro-css.co.il"
};

public OnPluginStart() 
{
	g_SteamIDTk = CreateArray(64);
	g_TkAmount = CreateArray(64);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("round_start", Event_RoundStart);
	
}

public OnMapStart() 
{
	ClearArray(g_SteamIDTk);
	ClearArray(g_TkAmount);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Ztime = GetTime();
}

public OnClientPostAdminCheck(client)
{
	if (!IsClientInGame(client) || IsFakeClient(client)) 
	{
		return;
	}

	teamattack[client] = 0;
	cankill[client] = 0;
	g_GameTime[client] = 0.0;
	cantbepunished[client] = false;
	canbekill[client] = false;
	
	decl String:steamID[64];
	GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
	new index = FindStringInArray(g_SteamIDTk, steamID);

	if (index != -1)
	{
		decl String:zzz[64];
		GetArrayString(g_TkAmount, index, zzz, sizeof(zzz));
		teamattack[client] = StringToInt(zzz);
		
		RemoveFromArray(g_SteamIDTk, index);
		RemoveFromArray(g_TkAmount, index);
	}
	
	has_admflag[client] = false;
	new iFlags = GetUserFlagBits(client);
	if(iFlags & ADMFLAG_RESERVATION || iFlags & ADMFLAG_ROOT)
	{
		has_admflag[client] = true;
	}
}

public OnClientDisconnect(client) 
{
	if (!IsClientInGame(client) || IsFakeClient(client)) 
	{
		return;
	}


	ForgiveTeamAttack(client);

	
	if (canbekill[client])
	{	
		ServerCommand("sm_ban #%i 20 \"Убийство товарищей по команде\"", GetClientUserId(client));
	}
	else if (teamattack[client] > 0)
	{
		decl String:buffer[64];
		GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
		PushArrayString(g_SteamIDTk, buffer);
		
		IntToString(teamattack[client], buffer, sizeof(buffer));
		PushArrayString(g_TkAmount, buffer);
	}		
}

ForgiveTeamAttack(client)
{
	if(teamattack[client] != 0 && g_GameTime[client] > 0)
	{
		new zzz = RoundToFloor((GetGameTime() - g_GameTime[client]) / 20);
		teamattack[client] = teamattack[client] - zzz;
		if (teamattack[client] < 0)
		{
			teamattack[client] = 0;
		}
	}	
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new victim   = GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	new reflect_hp_dmg = GetEventInt(event, "dmg_health");
	new String: weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if( attacker > 0
		&& victim > 0
		&& IsClientInGame(attacker)
		&& IsClientInGame(victim)
		&& GetClientTeam(attacker) == GetClientTeam(victim)
		&& IsPlayerAlive(attacker)
		&& victim != attacker && reflect_hp_dmg > 2 && !(StrEqual(weapon, "inferno")))
	{
		ForgiveTeamAttack(attacker);
		
		new attacker_hp = GetClientHealth(attacker);
		new nowtime = GetTime();
				
		if (nowtime - Ztime < 10)
		{
			teamattack[attacker] = teamattack[attacker] + 9;
			if(teamattack[attacker] < 20 && !has_admflag[attacker] || teamattack[attacker] < 40)
			{
				ForcePlayerSuicide(attacker);
				CGOPrintToChatAllEx(attacker, "[SM]{TEAMCOLOR} %N {DEFAULT}был убит за атаку товарища по команде на спавне", attacker);
			}		
		}	
		
		if (reflect_hp_dmg >= attacker_hp)
		{
			teamattack[attacker]++;
			if(teamattack[attacker] < 20 && !has_admflag[attacker] || teamattack[attacker] > 20 && teamattack[attacker] < 40)
			{
				ForcePlayerSuicide(attacker);
				CGOPrintToChatAllEx(attacker, "[SM]{TEAMCOLOR} %N {DEFAULT}был убит за атаку товарища по команде", attacker);
			}		
		}	
		else 
		{
			teamattack[attacker]++;
			if(teamattack[attacker] < 20 && !has_admflag[attacker] || teamattack[attacker] > 20 && teamattack[attacker] < 40)
			{
				SetEntityHealth(attacker, attacker_hp - reflect_hp_dmg);
			}	
		}
		
		if (GetClientHealth(victim) <= 0)
		{
			teamattack[attacker] = teamattack[attacker] + 9;		
			if(teamattack[attacker] < 20 && !has_admflag[attacker] || teamattack[attacker] > 20 && teamattack[attacker] < 40)
			{
				CreateTKMenu(victim);
				cankill[victim] = attacker;
				canbekill[attacker] = true;
				CreateTimer(11.0, ForgiveTk, attacker);
			}	
		}
		
		if(teamattack[attacker] >= 20 && !has_admflag[attacker] && !cantbepunished[attacker] || teamattack[attacker] >= 40 && !cantbepunished[attacker])
		{
			teamattack[attacker] = 0;
			cantbepunished[attacker] = true;
			ServerCommand("sm_ban #%i 20 \"Убийство товарищей по команде\"", GetClientUserId(attacker));
		}
		g_GameTime[attacker] = GetGameTime();
	}
}

public Action:ForgiveTk(Handle:timer, any:client)
{
	canbekill[client] = false;
}

CreateTKMenu(victim)
{
	new Handle:menu = CreatePanel();
	SetPanelTitle(menu, "Выберите наказание:");

	DrawPanelText(menu, "Не жмите просто так 1,");
	DrawPanelText(menu, "подумайте стоит ли убивать или прощать игрока,");
	DrawPanelText(menu, "сделавшего это убийство");  
	DrawPanelItem(menu, "Убить");
	DrawPanelItem(menu, "Простить");	
	SendPanelToClient(menu, victim, Select_Panel, 10);
	CloseHandle(menu);
}

public Select_Panel(Handle:menu, MenuAction:action, client, option)
{
	if(action == MenuAction_Select && cankill[client] > 0)
	{
		if(IsClientInGame(cankill[client]) && canbekill[cankill[client]])
		{
			if(option == 1)
			{
				CGOPrintToChatAllEx(client, "[SM]{TEAMCOLOR} %N {DEFAULT}Убил {TEAMCOLOR}%N {DEFAULT}за тимкилл", client , cankill[client]);
				ForcePlayerSuicide(cankill[client]);
			}
			else if(option == 2)
			{
				CGOPrintToChatAllEx(client, "[SM]{TEAMCOLOR} %N {DEFAULT}Простил {TEAMCOLOR}%N {DEFAULT}за тимкилл", client , cankill[client]);
				teamattack[cankill[client]] = teamattack[cankill[client]] - 3;
				if(teamattack[cankill[client]] < 0)
				{
					teamattack[cankill[client]] = 0;
				}
			}
		}
		else
		{
			CGOPrintToChat(client, "[SM]{green} %N {DEFAULT}Вышел из игры, он должен был быть забанен", cankill[client]);
		}
		cankill[client] = 0;
	}
}