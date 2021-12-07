#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <zombiereloaded>

#define DATA "1.3CT"

Handle timers[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "SM Franug Player Colors",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

// I think that I get these color codes from advcommands :D
new g_iTColors[26][4] = {{255, 255, 255, 255}, {0, 0, 0, 255}, {255, 0, 0, 255},    {0, 255, 0, 255}, {0, 0, 255, 255}, {255, 255, 0, 255}, {255, 0, 255, 255}, {0, 255, 255, 255}, {255, 128, 0, 255}, {255, 0, 128, 255}, {128, 255, 0, 255}, {0, 255, 128, 255}, {128, 0, 255, 255}, {0, 128, 255, 255}, {192, 192, 192, 255}, {210, 105, 30, 255}, {139, 69, 19, 255}, {75, 0, 130, 255}, {248, 248, 255, 255}, {216, 191, 216, 255}, {240, 248, 255, 255}, {70, 130, 180, 255}, {0, 128, 128, 255},	{255, 215, 0, 255}, {210, 180, 140, 255}, {255, 99, 71, 255}};
new String:g_sTColors[26][32];

new g_color[MAXPLAYERS + 1];

new Handle:c_color = INVALID_HANDLE;

new Handle:cvar_alpha;

public OnPluginStart()
{
	LoadTranslations("franug_colors.phrases");
	
	CreateConVar("sm_fcolors_version", DATA, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_color = RegClientCookie("Colors", "Colors", CookieAccess_Private);
	RegConsoleCmd("sm_colors", Colores);
	
	HookEvent("player_hurt", Playerh);
	HookEvent("player_spawn", PlayerSpawn);
	
	cvar_alpha = FindConVar("sv_disable_immunity_alpha");
	
	if(cvar_alpha != INVALID_HANDLE) SetConVarInt(cvar_alpha, 1);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
			
		if(AreClientCookiesCached(client)) OnClientCookiesCached(client);
		
	}
}

public Action:Playerh(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_color[client] != 0)
	{
		if (timers[client] != INVALID_HANDLE) KillTimer(timers[client]);
		
		timers[client] = CreateTimer(0.5, Colort, client);
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(g_color[client] != 0)
	{
		if (timers[client] != INVALID_HANDLE) KillTimer(timers[client]);

		timers[client] = GetClientTeam(client) == 3 ? CreateTimer(2.5, Colort, client):INVALID_HANDLE;
	}
}

public Action:Colort(Handle:timer, any:client)
{
	if(IsPlayerAlive(client) && g_color[client] != 0 && GetClientTeam(client) == 3) 
		SetEntityRenderColor(client, g_iTColors[g_color[client]][0], g_iTColors[g_color[client]][1], g_iTColors[g_color[client]][2], g_iTColors[g_color[client]][3]);
		
	timers[client] = INVALID_HANDLE;
}

public int ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	if(g_color[client] != 0)
	{
		if (timers[client] != INVALID_HANDLE) KillTimer(timers[client]);
		
		timers[client] = INVALID_HANDLE;
	}
}

public int ZR_OnClientHumanPost(client, bool:respawn, bool:protect)
{
	if(g_color[client] != 0)
	{
		if (timers[client] != INVALID_HANDLE) KillTimer(timers[client]);
		
		timers[client] = CreateTimer(1.0, Colort, client);
	}
}

public OnClientCookiesCached(client)
{
	new String:SprayString[12];
	GetClientCookie(client, c_color, SprayString, sizeof(SprayString));
	
	if(StringToInt(SprayString) == 0)
	{
		g_color[client]  = 0;
		return;
	}
		
	g_color[client]  = StringToInt(SprayString);
}

public OnClientDisconnect(client)
{
	if(AreClientCookiesCached(client))
	{
		new String:SprayString[12];
		Format(SprayString, sizeof(SprayString), "%i", g_color[client]);
		
		SetClientCookie(client, c_color, SprayString);
	}
	
	if (timers[client] != INVALID_HANDLE) KillTimer(timers[client]);
	timers[client] = INVALID_HANDLE;
}


public Action:Colores(client, args)
{
	if (client)
	{
		if (GetClientTeam(client) == 3)
		{
			new Handle:menu = CreateMenu(DIDMenuHandler);
			char title[64];
			Format(title, 64, "%T", "menu_title", client);
			SetMenuTitle(menu, title);
			SetupRGBA(client);
			decl String:temp[4];
			for(new i=0; i<26; i++)
			{
				Format(temp, 4, "%i", i);
				AddMenuItem(menu, temp, g_sTColors[i]);
			}
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, 0);
		}
		//else PrintToChat(client, "Вы должны быть КТ, чтобы использовать данную команду!");
	}
	return Plugin_Handled;
}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		decl String:info[32];
		
		GetMenuItem(menu, itemNum, info, sizeof(info));
		
		new g = StringToInt(info);
		
		if(IsPlayerAlive(client)) SetEntityRenderColor(client, g_iTColors[g][0], g_iTColors[g][1], g_iTColors[g][2], g_iTColors[g][3]);
		
		g_color[client] = g;
		
		SetupRGBA(client);
		PrintToChat(client, " \x04[SM_COLORS]\x01 %T","choosen", client, g_sTColors[g]);
		
		DisplayMenuAtItem(menu, client, GetMenuSelectionPosition(), 90);
		
	}
	else if (action == MenuAction_End && client != MenuEnd_Selected)
	{
		CloseHandle(menu);
	}
}


SetupRGBA(client)
{
	new String:colorTemp[32];
	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_normal", client);
	g_sTColors[0] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_black", client);
	g_sTColors[1] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_red", client);
	g_sTColors[2] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_green", client);
	g_sTColors[3] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_blue", client);
	g_sTColors[4] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_yellow", client);
	g_sTColors[5] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_purple", client);
	g_sTColors[6] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_cyan", client);
	g_sTColors[7] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_orange", client);
	g_sTColors[8] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_pink", client);
	g_sTColors[9] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_olive", client);
	g_sTColors[10] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_lime", client);
	g_sTColors[11] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_violet", client);
	g_sTColors[12] = colorTemp;	
	Format(colorTemp, sizeof(colorTemp), "%T", "color_lightblue", client);
	g_sTColors[13] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_silver", client);
	g_sTColors[14] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_chocolate", client);
	g_sTColors[15] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_saddlebrown", client);
	g_sTColors[16] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_indigo", client);
	g_sTColors[17] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_ghostwhite", client);
	g_sTColors[18] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_thistle", client);
	g_sTColors[19] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_aliceblue", client);
	g_sTColors[20] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_steelblue", client);
	g_sTColors[21] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_teal", client);
	g_sTColors[22] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_gold", client);
	g_sTColors[23] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_tan", client);
	g_sTColors[24] = colorTemp;
	Format(colorTemp, sizeof(colorTemp), "%T", "color_tomato", client);
	g_sTColors[25] = colorTemp;
}