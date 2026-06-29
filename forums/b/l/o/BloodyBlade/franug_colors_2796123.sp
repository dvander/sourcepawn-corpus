/*  SM Franug Player Colors
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#undef REQUIRE_PLUGIN
//#include <zombiereloaded>

#define DATA "1.3"

Handle timers[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "SM Franug Player Colors",
	author = "Franc1sco franug",
	description = "",
	version = DATA,
	url = "http://steamcommunity.com/id/franug"
};

// I think that I get these color codes from advcommands :D
int g_iTColors[26][4] = {{255, 255, 255, 255}, {0, 0, 0, 255}, {255, 0, 0, 255},    {0, 255, 0, 255}, {0, 0, 255, 255}, {255, 255, 0, 255}, {255, 0, 255, 255}, {0, 255, 255, 255}, {255, 128, 0, 255}, {255, 0, 128, 255}, {128, 255, 0, 255}, {0, 255, 128, 255}, {128, 0, 255, 255}, {0, 128, 255, 255}, {192, 192, 192, 255}, {210, 105, 30, 255}, {139, 69, 19, 255}, {75, 0, 130, 255}, {248, 248, 255, 255}, {216, 191, 216, 255}, {240, 248, 255, 255}, {70, 130, 180, 255}, {0, 128, 128, 255},	{255, 215, 0, 255}, {210, 180, 140, 255}, {255, 99, 71, 255}};
char g_sTColors[26][32];

int g_color[MAXPLAYERS + 1];

static Cookie c_color;

ConVar cvar_alpha;

public void OnPluginStart()
{
	LoadTranslations("franug_colors.phrases");

	CreateConVar("sm_fcolors_version", DATA, "", FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_DONTRECORD);

	c_color = new Cookie("Colors", "Colors", CookieAccess_Private);
	RegAdminCmd("sm_colors", Colores, ADMFLAG_RESERVATION);
	
	HookEvent("player_hurt", Playerh);
	HookEvent("player_spawn", PlayerSpawn);

	cvar_alpha = FindConVar("sv_disable_immunity_alpha");

	if(cvar_alpha != null)
	{
	    cvar_alpha.SetInt(1);
	}

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}

		if(AreClientCookiesCached(client))
		{
		    OnClientCookiesCached(client);
		}
		else
		{
		    g_color[client]  = 0;
		}
	}
}

public Action Playerh(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(g_color[client] != 0)
    {
    	if (timers[client] != null)
    	{
    	    delete timers[client];
    	}
    
    	timers[client] = CreateTimer(0.5, Colort, client);
    }
    
    return Plugin_Continue;
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if(g_color[client] != 0)
    {
    	if (timers[client] != null)
    	{
    	    delete timers[client];
    	}
    
    	timers[client] = CreateTimer(2.5, Colort, client);
    }
    
    return Plugin_Continue;
}

public Action Colort(Handle timer, any client)
{
    if(IsPlayerAlive(client) && g_color[client] != 0)
    {
    	SetEntityRenderColor(client, g_iTColors[g_color[client]][0], g_iTColors[g_color[client]][1], g_iTColors[g_color[client]][2], g_iTColors[g_color[client]][3]);
    }
    
    timers[client] = null;
    
    return Plugin_Stop;
}

/*public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(g_color[client] != 0)
	{
		if (timers[client] != null)
		{
		    delete timers[client];
		}

		timers[client] = CreateTimer(1.0, Colort, client);
	}
}

public int ZR_OnClientHumanPost(int client, bool respawn, bool protect)
{
	if(g_color[client] != 0)
	{
		if (timers[client] != null)
		{
		    delete timers[client];
		}

		timers[client] = CreateTimer(1.0, Colort, client);
	}
}*/

public void OnClientCookiesCached(int client)
{
	char SprayString[12];
	c_color.Get(client, SprayString, sizeof(SprayString));

	if(StringToInt(SprayString) == 0)
	{
		g_color[client]  = 0;
		return;
	}

	g_color[client]  = StringToInt(SprayString);
}

public void OnClientDisconnect(int client)
{
    if(AreClientCookiesCached(client))
    {
    	char SprayString[12];
    	Format(SprayString, sizeof(SprayString), "%i", g_color[client]);
    
    	c_color.Set(client, SprayString);
    }
    
    if (timers[client] != null)
    {
        delete timers[client];
    }
}


public Action Colores(int client, int args)
{
    Menu menu = new Menu(DIDMenuHandler);
    
    char title[64];
    Format(title, 64, "%T", "menu_title", client);
    menu.SetTitle(title);
    SetupRGBA(client);
    
    char temp[4];
    for(int i = 0; i < 26; i++)
    {
    	Format(temp, 4, "%i", i);
    	menu.AddItem(temp, g_sTColors[i]);
    }
    
    menu.ExitButton = true;
    menu.Display(client, 0);
    
    return Plugin_Handled;
}

public int DIDMenuHandler(Menu menu, MenuAction action, int client, int itemNum) 
{
    if ( action == MenuAction_Select ) 
    {
    	char info[32];
    
    	menu.GetItem(itemNum, info, sizeof(info));
    
    	int g = StringToInt(info);
    
    	if(IsPlayerAlive(client))
    	{
    	    SetEntityRenderColor(client, g_iTColors[g][0], g_iTColors[g][1], g_iTColors[g][2], g_iTColors[g][3]);
    	}
    
    	g_color[client] = g;
    
    	SetupRGBA(client);
    	PrintToChat(client, " \x04[SM_COLORS]\x01 %T","choosen", client, g_sTColors[g]);
    
    	Colores(client, 0);
    }
    else if (action == MenuAction_End)
    {
    	delete menu;
    }
    
    return 0;
}


void SetupRGBA(int client)
{
	char colorTemp[32];

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
