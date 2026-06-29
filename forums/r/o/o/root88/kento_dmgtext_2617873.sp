#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <kento_csgocolors>
#include <clientprefs>
#include <smlib>

#pragma newdecls required

Handle Cookie_Show, Cookie_Size_Normal, Cookie_Size_Kill, Cookie_Color_Normal, Cookie_Color_Kill;
bool text_show[MAXPLAYERS + 1];
char text_size_normal[MAXPLAYERS + 1][64];
char text_size_kill[MAXPLAYERS + 1][64];
char text_color_normal[MAXPLAYERS + 1][64];
char text_color_kill[MAXPLAYERS + 1][64];
int SayingSettings[MAXPLAYERS + 1];

ConVar Cvar_Flag;
char Flag[AdminFlags_TOTAL];
ConVar Cvar_Size;
int MaxSize;

Handle db = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "[CS:GO] Damage Text",
	author = "Kento, Kxnrl, IT-KiLLER",
	version = "1.6",
	description = "Show damage text like RPG games :D",
	url = "http://steamcommunity.com/id/kentomatoryoshika/"
};

public void OnPluginStart() 
{
	RegConsoleCmd("sm_dmgtext", Command_DmgText, "Damage Text Settings");
	RegConsoleCmd("say", Command_Say);
	
	Cookie_Show = RegClientCookie("dmgtext_show", "Show damage text or not", CookieAccess_Private);
	Cookie_Size_Normal = RegClientCookie("dmgtext_size_normal", "Normal Damage text size", CookieAccess_Private);
	Cookie_Size_Kill = RegClientCookie("dmgtext_size_kill", "Kill damage text size", CookieAccess_Private);
	Cookie_Color_Normal = RegClientCookie("dmgtext_normal_color", "Noraml damage text rgb", CookieAccess_Private);
	Cookie_Color_Kill = RegClientCookie("dmgtext_kill_color", "Kill damage text rgb", CookieAccess_Private);
	
	LoadTranslations("kento.dmgtext.phrases");
	
	Cvar_Flag = CreateConVar("sm_dmgtext_flag", "", "Flag to use damage text, blank = disabled");
	Cvar_Flag.AddChangeHook(OnConVarChanged);
	
	Cvar_Size = CreateConVar("sm_dmgtext_size", "20", "Max size of damage text, 0 = disabled");
	Cvar_Size.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig(true, "kento_dmgtext");
	
	for(int i = 1; i <= MaxClients; i++)
	{ 
		if(IsValidClient(i))
		{	
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			if(!IsFakeClient(i))	OnClientCookiesCached(i);
		}
	}
}

public void OnMapStart()
{
	char[] error = new char[PLATFORM_MAX_PATH];
	db = SQL_Connect("clientprefs", true, error, PLATFORM_MAX_PATH);
	
	if (!LibraryExists("clientprefs") || db == INVALID_HANDLE)	SetFailState("clientpref error: %s", error);
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		if (!IsFakeClient(client))	OnClientCookiesCached(client);
	}
}

public void OnClientCookiesCached(int client)
{
	SayingSettings[client] = 0;
	
	char scookie[64];
	GetClientCookie(client, Cookie_Show, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		text_show[client] = view_as<bool>(StringToInt(scookie));
	}
	else	text_show[client] = true;
		
	GetClientCookie(client, Cookie_Size_Normal, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		text_size_normal[client] = scookie;
	}
	else	text_size_normal[client] = "5";
	
	GetClientCookie(client, Cookie_Size_Kill, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		text_size_kill[client] = scookie;
	}
	else	text_size_kill[client] = "8";
	
	GetClientCookie(client, Cookie_Color_Normal, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		text_color_normal[client] = scookie;
	}
	else text_color_normal[client] = "255 255 255"
	
	GetClientCookie(client, Cookie_Color_Kill, scookie, sizeof(scookie));
	if(!StrEqual(scookie, ""))
	{
		text_color_kill[client] = scookie;
	}
	else text_color_kill[client] = "255 0 0"
}

public void OnConfigsExecuted()
{
	Cvar_Flag.GetString(Flag, sizeof(Flag));
	MaxSize = Cvar_Size.IntValue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == Cvar_Flag)	Cvar_Flag.GetString(Flag, sizeof(Flag));
	
	else if (convar == Cvar_Size)
	{
		MaxSize = Cvar_Size.IntValue;
		
		if(MaxSize > 0)
		{
			char[] query = new char[512];
			FormatEx(query, 512, "UPDATE `sm_cookie_cache` SET `value`='%d' WHERE EXISTS( SELECT * FROM sm_cookies WHERE sm_cookie_cache.cookie_id = sm_cookies.id AND sm_cookies.name = 'dmgtext_size_normal') AND `value` > '%d';", MaxSize, MaxSize);
			SQL_TQuery(db, ClientPref_PurgeCallback, query);
	
			char[] query2 = new char[512];
			FormatEx(query2, 512, "UPDATE `sm_cookie_cache` SET `value`='%d' WHERE EXISTS( SELECT * FROM sm_cookies WHERE sm_cookie_cache.cookie_id = sm_cookies.id AND sm_cookies.name = 'dmgtext_size_kill') AND `value` > '%d';", MaxSize, MaxSize);
			SQL_TQuery(db, ClientPref_PurgeCallback, query2);
		}
	}
}

public void ClientPref_PurgeCallback(Handle owner, Handle handle, const char[] error, any data)
{
	if (SQL_GetAffectedRows(owner))
	{
		char sMaxSize[8];
		IntToString(MaxSize, sMaxSize, sizeof(sMaxSize));
		
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				if(StringToInt(text_size_normal[i]) > MaxSize)	text_size_normal[i] = sMaxSize;
				if(StringToInt(text_size_kill[i]) > MaxSize)	text_size_kill[i] = sMaxSize;
			}
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "func_physbox", false) || StrEqual(classname, "func_physbox_multiplayer", false) || StrEqual(classname, "func_breakable", false))
	{
		if (IsValidEntity(entity))	SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage (int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if (IsValidEntity(victim) && IsValidClient(attacker) && CanUseText(attacker) && text_show[attacker])
    {
		char sdamage[8];
		int idamage = RoundToZero(damage);
		IntToString(idamage, sdamage, sizeof(sdamage));
		
		if (idamage > 0)
        {
			int health = GetEntProp(victim, Prop_Data, "m_iHealth");
			float victimpos[3], clientAngle[3], clientpos[3];
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", victimpos);
			GetClientEyeAngles(attacker, clientAngle);
			GetClientAbsOrigin(attacker, clientpos);
			
			//PrintToChat(attacker, "weapon %d, type %d", weapon , damagetype);
			//PrintToChat(attacker, "Vic %f, %f, %f", victimpos[0], victimpos[1], victimpos[2]);
			//PrintToChat(attacker, "DMG %f, %f, %f", damagePosition[0], damagePosition[1], damagePosition[2]);
			//PrintToChat(attacker, "damageForce %f, %f, %f", damageForce[0], damageForce[1], damageForce[2]);

			if(damagetype == 8)	return;	// inferno doesn't have damageposition and damageForce :(
			
			if(weapon == -1 && damagetype == 64)	// grenades
			{
				if(idamage > health)	ShowDamageText(attacker, damagePosition, clientAngle, sdamage, true, victim);
				else	ShowDamageText(attacker, damagePosition, clientAngle, sdamage, false, victim);
			}
			else if(weapon != -1)	// normal weapons
			{
				if(idamage > health)	ShowDamageText(attacker, damagePosition, clientAngle, sdamage, true, victim);
				else	ShowDamageText(attacker, damagePosition, clientAngle, sdamage, false, victim);
			}
        }
    }
}  

// Edit from
// https://forums.alliedmods.net/showpost.php?p=2523113&postcount=8
stock int ShowDamageText(int client, float fPos[3], float fAngles[3], char[] sText, bool kill, int victim) 
{ 
	int entity = CreateEntityByName("point_worldtext"); 
	
	if(entity == -1)	return entity; 
	float distance;
	char stext_size_kill[8];
	char stext_size_normal[8];
	distance = Entity_GetDistance(client, victim);
	DispatchKeyValue(entity, "message", sText); 
	
	FloatToString(0.0015*distance*StringToFloat(text_size_kill[client]), stext_size_kill, sizeof(stext_size_kill));
	FloatToString(0.0015*distance*StringToFloat(text_size_normal[client]), stext_size_normal, sizeof(stext_size_normal));
	
	if(kill)
	{
		DispatchKeyValue(entity, "textsize", stext_size_kill);
		DispatchKeyValue(entity, "color", text_color_kill[client]); 
		//debug distance
		//PrintToChat(client, "Kill distance: %f", distance);
		//1500.0 - very long distance, <100 - very close distance
	}
	else
	{
		DispatchKeyValue(entity, "textsize", stext_size_normal);
		DispatchKeyValue(entity, "color", text_color_normal[client]); 
	}

	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);  
	SetFlags(entity);
	
	SDKHook(entity, SDKHook_SetTransmit, SetTransmit);
	TeleportEntity(entity, fPos, fAngles, NULL_VECTOR);
	
	CreateTimer(0.5, KillText, EntIndexToEntRef(entity));
    
	return entity; 
} 

public void SetFlags(int entity) 
{ 
	if (GetEdictFlags(entity) & FL_EDICT_ALWAYS) 
	{ 
		SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS)); 
	} 
}

public Action KillText(Handle timer, int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity == INVALID_ENT_REFERENCE || !IsValidEntity(entity))	return;
	SDKUnhook(entity, SDKHook_SetTransmit, SetTransmit);
	AcceptEntityInput(entity, "kill");
}

public bool HitSelf(int entity, int contentsMask, any data)
{
	if (entity == data)	return false;
	return true;
}

//https://forums.alliedmods.net/showthread.php?p=2483070
//https://forums.alliedmods.net/showpost.php?p=2482807&postcount=16
//https://github.com/bbennett905/store-aura/blob/master/store-aura.sp#L509
public Action SetTransmit(int entity, int client) 
{ 
	SetFlags(entity);
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(client == owner) return Plugin_Continue;	// draw
	else return Plugin_Stop; // not draw
}  

public Action Command_DmgText(int client, int args)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		if(!CanUseText(client))	CPrintToChat(client, "%T", "No Access", client);
		else	ShowSettingsMenu(client);
	}
	return Plugin_Handled;
}

public void ShowSettingsMenu(int client)
{
	Menu dmg_menu = new Menu(DMGMenuHandler);
	
	char dmgmenutitle[512];
	Format(dmgmenutitle, sizeof(dmgmenutitle), "%T", "Menu Settings Title", client);
	dmg_menu.SetTitle(dmgmenutitle);
	
	char settings[PLATFORM_MAX_PATH];
	if(text_show[client])	Format(settings, sizeof(settings), "%T", "Menu Settings Show", client, text_size_normal[client], text_color_normal[client], text_size_kill[client], text_color_kill[client]);
	else	Format(settings, sizeof(settings), "%T", "Menu Settings Hide", client, text_size_normal[client], text_color_normal[client], text_size_kill[client], text_color_kill[client]);
	dmg_menu.AddItem("settings", settings);
		
	if(text_show[client])
	{
		char hide[PLATFORM_MAX_PATH];
		Format(hide, sizeof(hide), "%T", "Menu Hide Text", client);
		dmg_menu.AddItem("hide", hide);
	}
	else
	{
		char show[PLATFORM_MAX_PATH];
		Format(show, sizeof(show), "%T", "Menu Show Text", client);
		dmg_menu.AddItem("show", show);
	}
		
	char normal_size[PLATFORM_MAX_PATH];
	Format(normal_size, sizeof(normal_size), "%T", "Menu Normal Size", client);
	dmg_menu.AddItem("normal_size", normal_size);
	
	char kill_size[PLATFORM_MAX_PATH];
	Format(kill_size, sizeof(kill_size), "%T", "Menu Kill Size", client);
	dmg_menu.AddItem("kill_size", kill_size);
		
	char normal_color[PLATFORM_MAX_PATH];
	Format(normal_color, sizeof(normal_color), "%T", "Menu Noraml Color", client);
	dmg_menu.AddItem("normal_color", normal_color);
		
	char kill_color[PLATFORM_MAX_PATH];
	Format(kill_color, sizeof(kill_color), "%T", "Menu Kill Color", client);
	dmg_menu.AddItem("kill_color", kill_color);
		
	dmg_menu.Display(client, 0);
}

public int DMGMenuHandler(Menu menu, MenuAction action, int client,int param)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char menuitem[20];
			menu.GetItem(param, menuitem, sizeof(menuitem));
			
			if(StrEqual(menuitem, "settings"))
			{
				ShowSettingsMenu(client);
			}
			else if(StrEqual(menuitem, "show"))
			{
				text_show[client] = true;
				ShowSettingsMenu(client);
				SetClientCookie(client, Cookie_Show, "1");
			}
			else if(StrEqual(menuitem, "hide"))
			{
				text_show[client] = false;
				ShowSettingsMenu(client);
				SetClientCookie(client, Cookie_Show, "0");
			}
			else if(StrEqual(menuitem, "normal_size"))
			{
				CPrintToChat(client, "%T", "Say Normal Size", client);
				SayingSettings[client] = 1;
			}
			else if(StrEqual(menuitem, "kill_size"))
			{
				CPrintToChat(client, "%T", "Say Kill Size", client);
				SayingSettings[client] = 2;
			}
			else if(StrEqual(menuitem, "normal_color"))
			{
				CPrintToChat(client, "%T", "Say Normal Color", client);
				SayingSettings[client] = 3;
			}
			else if(StrEqual(menuitem, "kill_color"))
			{
				CPrintToChat(client, "%T", "Say Kill Color", client);
				SayingSettings[client] = 4;
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		SayingSettings[client] = 0;
	}
}

public Action Command_Say(int client, int args)
{
	if(!IsValidClient(client) || IsFakeClient(client) || SayingSettings[client] == 0)	return Plugin_Continue;
	
	char arg[64];
	GetCmdArgString(arg, sizeof(arg));
	StripQuotes(arg);
	
	if(StrEqual(arg, "!cancel"))
	{
		CPrintToChat(client, "%T", "Say Cancel", client);
		SayingSettings[client] = 0;
		ShowSettingsMenu(client);
	}
	else
	{
		char sMaxSize[8];
		IntToString(MaxSize, sMaxSize, sizeof(sMaxSize));
		
		if(SayingSettings[client] == 1)
		{
			SayingSettings[client] = 0;
			
			if(MaxSize > 0 && StringToInt(arg) > MaxSize)	text_size_normal[client] = sMaxSize;
			else	text_size_normal[client] = arg;

			SetClientCookie(client, Cookie_Size_Normal, text_size_normal[client]);
			CPrintToChat(client, "%T", "Normal Size Is", client, text_size_normal[client]);
			ShowSettingsMenu(client);
		}
		else if(SayingSettings[client] == 2)
		{
			SayingSettings[client] = 0;
			
			if(MaxSize > 0 && StringToInt(arg) > MaxSize)	text_size_kill[client] = sMaxSize;
			else	text_size_kill[client] = arg;
			
			SetClientCookie(client, Cookie_Size_Kill, text_size_kill[client]);
			CPrintToChat(client, "%T", "Kill Size Is", client, text_size_kill[client]);
			ShowSettingsMenu(client);
		}
		else if(SayingSettings[client] == 3)
		{
			SayingSettings[client] = 0;
			
			text_color_normal[client] = arg;
			SetClientCookie(client, Cookie_Color_Normal, text_color_normal[client]);
			CPrintToChat(client, "%T", "Normal RGB Color Is", client, text_color_normal[client]);
			ShowSettingsMenu(client);
		}
		else if(SayingSettings[client] == 4)
		{
			SayingSettings[client] = 0;
			
			text_color_kill[client] = arg;
			SetClientCookie(client, Cookie_Color_Kill, text_color_kill[client]);
			CPrintToChat(client, "%T", "Kill RGB Color Is", client, text_color_kill[client]);
			ShowSettingsMenu(client);
		}
	}
	return Plugin_Handled;
}

stock bool CanUseText(int client)
{
	if(StrEqual(Flag, "") || StrEqual(Flag, " "))	return true;
	else
	{
		if (CheckCommandAccess(client, "dmgtext", ReadFlagString(Flag), true))	return true;
		else return false;
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0) return false;
	if (client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
