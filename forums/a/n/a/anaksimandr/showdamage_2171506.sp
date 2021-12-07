#include <sourcemod>
#include <clientprefs>

#define PLUGIN_VERSION "1.0.7"

public Plugin:myinfo = 
{
	name = "Show Damage",
	author = "exvel",
	description = "Shows damage in the center of the screen.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

new player_old_health[MAXPLAYERS + 1];
new player_damage[MAXPLAYERS + 1];
new bool:block_timer[MAXPLAYERS + 1] = {false,...};
new bool:FrameMod = true;
new String:DamageEventName[16];
new MaxDamage = 10000000;
new bool:option_show_damage[MAXPLAYERS + 1] = {true,...};
new Handle:cookie_show_damage = INVALID_HANDLE;

//CVars' handles
new Handle:cvar_show_damage = INVALID_HANDLE;
new Handle:cvar_show_damage_ff = INVALID_HANDLE;
new Handle:cvar_show_damage_own_dmg = INVALID_HANDLE;
new Handle:cvar_show_damage_text_area = INVALID_HANDLE;

//CVars' varibles
new bool:show_damage = true;
new bool:show_damage_ff = false;
new bool:show_damage_own_dmg = false;
new show_damage_text_area = 1;


public OnPluginStart()
{
	decl String:gameName[80];
	GetGameFolderName(gameName, 80);
	
	if (StrEqual(gameName, "cstrike") || StrEqual(gameName, "insurgency"))
	{
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		DamageEventName = "dmg_health";
		FrameMod = false;
	}
	else if (StrEqual(gameName, "left4dead") || StrEqual(gameName, "left4dead2"))
	{
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
		MaxDamage = 2000;
		DamageEventName = "dmg_health";
		FrameMod = false;
	}
	else if (StrEqual(gameName, "dod") || StrEqual(gameName, "hidden"))
	{
		HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
		DamageEventName = "damage";
		FrameMod = false;
	}
	else
	{
		HookEvent("player_hurt", Event_PlayerHurt_FrameMod, EventHookMode_Pre);
		FrameMod = true;
	}
	
	CreateConVar("sm_show_damage_version", PLUGIN_VERSION, "Show Damage Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_show_damage = CreateConVar("sm_show_damage", "1", "Enabled/Disabled show damage functionality, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_show_damage_ff = CreateConVar("sm_show_damage_ff", "0", "Show friendly fire damage, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_show_damage_own_dmg = CreateConVar("sm_show_damage_own_dmg", "0", "Show your own damage, 0 = off/1 = on", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_show_damage_text_area = CreateConVar("sm_show_damage_text_area", "1", "Defines the area for damage text:\n 1 = in the center of the screen\n 2 = in the hint text area \n 3 = in chat area of screen", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	
	HookConVarChange(cvar_show_damage, OnCVarChange);
	HookConVarChange(cvar_show_damage_ff, OnCVarChange);
	HookConVarChange(cvar_show_damage_own_dmg, OnCVarChange);
	HookConVarChange(cvar_show_damage_text_area, OnCVarChange);
	
	AutoExecConfig(true, "plugin.showdamage");
	LoadTranslations("common.phrases");
	LoadTranslations("showdamage.phrases");
	
	cookie_show_damage = RegClientCookie("Show Damage On/Off", "", CookieAccess_Private);
	new info;
	SetCookieMenuItem(CookieMenuHandler_ShowDamage, any:info, "Show Damage");
}

public CookieMenuHandler_ShowDamage(client, CookieMenuAction:action, any:info, String:buffer[], maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		decl String:status[10];
		if (option_show_damage[client])
		{
			Format(status, sizeof(status), "%T", "On", client);
		}
		else
		{
			Format(status, sizeof(status), "%T", "Off", client);
		}
		
		Format(buffer, maxlen, "%T: %s", "Cookie Show Damage", client, status);
	}
	// CookieMenuAction_SelectOption
	else
	{
		option_show_damage[client] = !option_show_damage[client];
		
		if (option_show_damage[client])
		{
			SetClientCookie(client, cookie_show_damage, "On");
		}
		else
		{
			SetClientCookie(client, cookie_show_damage, "Off");
		}
		
		ShowCookieMenu(client);
	}
}

public OnClientCookiesCached(client)
{
	option_show_damage[client] = GetCookieShowDamage(client);
}

bool:GetCookieShowDamage(client)
{
	decl String:buffer[10];
	GetClientCookie(client, cookie_show_damage, buffer, sizeof(buffer));
	
	return !StrEqual(buffer, "Off");
}

public OnConfigsExecuted()
{
	GetCVars();
}

public OnClientConnected(client)
{
	block_timer[client] = false;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	block_timer[client] = false;
	
	return Plugin_Continue;
}

//This is for games that have no damage information in player_hurt event
public OnGameFrame()
{
	if (FrameMod && show_damage)
	{
		for (new client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				player_old_health[client] = GetClientHealth(client);
			}
		}
	}
}

public Action:ShowDamage(Handle:timer, any:client)
{
	block_timer[client] = false;
	
	if (player_damage[client] <= 0 || !client)
	{
		return;
	}
	
	if (!IsClientInGame(client))
	{
		return;
	}
	
	switch (show_damage_text_area)
	{
		case 1:
		{
			PrintCenterText(client, "%t", "CenterText Damage Text", player_damage[client]);
		}
		
		case 2:
		{
			PrintHintText(client, "%t", "HintText Damage Text", player_damage[client]);
		}
		
		case 3:
		{
			PrintToChat(client, "%t", "Chat Damage Text", player_damage[client]);
		}
	}
	
	player_damage[client] = 0;
}

public Action:Event_PlayerHurt_FrameMod(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = player_old_health[client] - GetClientHealth(client);
	
	CalcDamage(client, client_attacker, damage);
	
	return Plugin_Continue;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new damage = GetEventInt(event, DamageEventName);
	
	CalcDamage(client, client_attacker, damage);
	
	return Plugin_Continue;
}

public Action:Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client_attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "amount");
	
	CalcDamage(0, client_attacker, damage);
	
	return Plugin_Continue;
}



CalcDamage(client, client_attacker, damage)
{
	if (!show_damage || !option_show_damage[client_attacker])
	{
		return;
	}
	
	if (client_attacker == 0)
	{
		return;
	}
	
	if (IsFakeClient(client_attacker) || !IsClientInGame(client_attacker))
	{
		return;
	}
	
	//If client == 0 than skip this verifying. It can be an infected or something else without client index.
	if (client != 0)
	{
		if (client == client_attacker)
		{
			if (!show_damage_own_dmg)
			{
				return;
			}
		}
		else if (GetClientTeam(client) == GetClientTeam(client_attacker))
		{
			if (!show_damage_ff)
			{
				return;
			}
		}
	}
	
	//This is a fix for Left 4 Dead. When tank dies the game fires hurt event with 5000 dmg that is a bug.
	if (damage > MaxDamage)
	{
		return;
	}
	
	player_damage[client_attacker] += damage;
	
	if (block_timer[client_attacker])
	{
		return;
	}
	
	CreateTimer(0.01, ShowDamage, client_attacker);
	block_timer[client_attacker] = true;
}

public OnCVarChange(Handle:convar_hndl, const String:oldValue[], const String:newValue[])
{
	GetCVars();
}

GetCVars()
{
	show_damage = GetConVarBool(cvar_show_damage);
	show_damage_ff = GetConVarBool(cvar_show_damage_ff);
	show_damage_own_dmg = GetConVarBool(cvar_show_damage_own_dmg);
	show_damage_text_area = GetConVarInt(cvar_show_damage_text_area);
}
