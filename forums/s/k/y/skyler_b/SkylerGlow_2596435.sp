#define PLUGIN_AUTHOR "Skyler"
#define PLUGIN_VERSION "4.92"
#define PREFIX " \x0E[\x0CSkylerGlow\x0E] \x04"
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <smlib>
#include <hl_gangs>
#include <skyler>
Database DB = null;
char sError[512], sGangs[512][512], sColors[512];
char targetinfo[64];
char colorinfo[64];
char ga_sGangName[MAXPLAYERS + 1][128];
char paricaltargetinfo[64];
char cs_clientid[64];
char c_clientid[64];
bool g_samecolor[MAXPLAYERS + 1] = false;
bool b_start = false;
int g_iGangs, g_iRandomColors[512][4];
GangRank ga_iRank[MAXPLAYERS + 1] =  { Rank_Invalid, ... };
int ga_iGangSize[MAXPLAYERS + 1] =  { -1, ... };
bool ga_bHasGang[MAXPLAYERS + 1] =  { false, ... };
public int Native_GetGangName(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}
	
	SetNativeString(2, ga_sGangName[client], GetNativeCell(3));
	return 0;
}

public int Native_GetGangRank(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}
	
	return view_as<int>(ga_iRank[client]);
}

public int Native_HasGang(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}
	
	return view_as<int>(ga_bHasGang[client]);
}

public int Native_GetGangSize(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	if (!IsValidClient(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}
	
	return ga_iGangSize[client];
}
public Plugin myinfo = 
{
	name = "SkylerGlow", 
	author = PLUGIN_AUTHOR, 
	description = "Skyler Glow Menu", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnPluginStart()
{
	ConnectToDB();
	RegConsoleCmd("sm_glow", Command_Glow, "");
}
public Action Command_Glow(int client, args)
{
	if (IsClientInGame(client) && GetClientTeam(client) != CS_TEAM_CT && GetUserAdmin(client) == INVALID_ADMIN_ID)
	{
		char Error[4096];
		Format(Error, sizeof(Error), "<font color='#013ADF' size='25'><u>SkylerGlow</u></font>\n<font color='#E7159C' size='15'>You must be on Ct's side to use the Glow</font>");
		PrintHintText(client, Error);
		return Plugin_Handled;
	}
	if (IsClientInGame(client) && GetClientTeam(client) != CS_TEAM_CT && GetUserAdmin(client) == INVALID_ADMIN_ID && !IsPlayerAlive(client))
	{
		char Error[4096];
		Format(Error, sizeof(Error), "<font color='#013ADF' size='25'><u>SkylerGlow</u></font>\n<font color='#E7159C' size='15'>You must be alive to use the Glow</font>");
		PrintHintText(client, Error);
		return Plugin_Handled;
	}
	Menu glow = CreateMenu(GlowMenuHandler);
	glow.SetTitle("[SkylerGlow] Select players to glow \n \n");
	glow.AddItem("reset", "Reset all Players");
	glow.AddItem("partical", "Glow the same color multiple Players");
	glow.AddItem("gangs", "Glow the gangs by random color");
	glow.AddItem("all", "Glow all Players \n \n");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			char name[512];
			char string[512];
			GetClientName(i, name, sizeof(name));
			Format(string, sizeof(string), "%d", i);
			glow.AddItem(string, name);
		}
	}
	glow.ExitButton = true;
	glow.Display(client, MENU_TIME_FOREVER);
	return Plugin_Continue;
}
public int GlowMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		menu.GetItem(item, targetinfo, sizeof(targetinfo));
		if (StrEqual(targetinfo, "reset"))
		{
			for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
			{
				SetClientGlowToAll(255, 255, 255, 255);
			}
			PrintToChatAll("%s all terrorists glow has reset!", PREFIX);
		}
		if (StrEqual(targetinfo, "gangs"))
		{
			PaintClients();
			PrintToChatAll("%s all gangs has glow now!", PREFIX);
		}
		if (StrEqual(targetinfo, "partical"))
		{
			Menu select = CreateMenu(SelectHandler);
			select.SetTitle("[SkylerGlow] Select players to glow \n \n");
			for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
			{
				char name[512];
				char string[512];
				GetClientName(i, name, sizeof(name));
				Format(string, sizeof(string), "%d", i);
				select.AddItem(string, name);
			}
			if (ActiveBoolenNum() > 1)
				select.AddItem("done", "done! select their color");
			else
				select.AddItem("done", "done! select their color", ITEMDRAW_DISABLED);
			select.Display(client, MENU_TIME_FOREVER);
		}
		if (StrEqual(targetinfo, "all"))
		{
			Menu color = CreateMenu(ColorMenuHandler);
			color.SetTitle("[SkylerGlow] Select color to glow players \n \n");
			color.AddItem("black", "Black");
			color.AddItem("grey", "Grey");
			color.AddItem("brown", "Chocolate");
			color.AddItem("red", "Red");
			color.AddItem("green", "Green");
			color.AddItem("blue", "Blue");
			color.AddItem("cyan", "Cyan");
			color.AddItem("yellow", "Yellow");
			color.AddItem("orange", "Orange");
			color.AddItem("pink", "Pink");
			color.AddItem("purple", "Purple");
			color.ExitButton = true;
			color.Display(client, MENU_TIME_FOREVER);
		}
		
		if (!StrEqual(targetinfo, "gangs")
			 && !StrEqual(targetinfo, "all")
			 && !StrEqual(targetinfo, "reset")
			 && !StrEqual(targetinfo, "partical"))
		{
			Menu color = CreateMenu(ColorMenuHandler);
			color.SetTitle("[SkylerGlow] Select color to glow players \n \n");
			color.AddItem("black", "Black");
			color.AddItem("grey", "Grey");
			color.AddItem("brown", "Chocolate");
			color.AddItem("red", "Red");
			color.AddItem("green", "Green");
			color.AddItem("blue", "Blue");
			color.AddItem("cyan", "Cyan");
			color.AddItem("yellow", "Yellow");
			color.AddItem("orange", "Orange");
			color.AddItem("pink", "Pink");
			color.AddItem("purple", "Purple");
			color.ExitButton = true;
			color.Display(client, MENU_TIME_FOREVER);
		}
	}
}
public int SelectHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		menu.GetItem(item, paricaltargetinfo, sizeof(paricaltargetinfo));
		if (!StrEqual(paricaltargetinfo, "done"))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				IntToString(i, cs_clientid, sizeof(cs_clientid));
				if (StrEqual(paricaltargetinfo, cs_clientid))
				{
					char name[255];
					GetClientName(i, name, sizeof(name));
					menu.RemoveAllItems();
					for (int y = 1; y <= MaxClients; y++)
					if (IsValidClient(y) && GetClientTeam(y) == CS_TEAM_T && IsPlayerAlive(y))
					{
						char string[512];
						GetClientName(y, name, sizeof(name));
						if (!g_samecolor[y] && StrEqual(paricaltargetinfo, cs_clientid))
						{
							if (!g_samecolor[y] && y == i)
							{
								g_samecolor[y] = true;
								Format(string, sizeof(string), "%d", y);
								Format(name, sizeof(name), "%s[selected]", name);
								menu.AddItem(string, name);
							}
							else if (!g_samecolor[y] && y != i)
							{
								Format(string, sizeof(string), "%d", y);
								Format(name, sizeof(name), "%s", name);
								menu.AddItem(string, name);
							}
						}
						else
						{
							if (g_samecolor[y] && y == i)
							{
								g_samecolor[y] = false;
								Format(string, sizeof(string), "%d", y);
								Format(name, sizeof(name), "%s", name);
								menu.AddItem(string, name);
							}
							else if (g_samecolor[y] && y != i)
							{
								if (g_samecolor[y])
								{
									Format(string, sizeof(string), "%d", y);
									Format(name, sizeof(name), "%s[selected]", name);
									menu.AddItem(string, name);
								}
								else
								{
									Format(string, sizeof(string), "%d", y);
									Format(name, sizeof(name), "%s", name);
									menu.AddItem(string, name);
								}
							}
						}
					}
				}
			}
			if (ActiveBoolenNum() > 1)
				menu.AddItem("done", "done! select their color");
			else
				menu.AddItem("done", "done! select their color", ITEMDRAW_DISABLED);
			menu.Display(client, MENU_TIME_FOREVER);
		}
	}
	if (StrEqual(paricaltargetinfo, "done"))
	{
		Menu color = CreateMenu(ColorHandler);
		color.SetTitle("[SkylerGlow] Select color to glow players \n \n");
		color.AddItem("black", "Black");
		color.AddItem("grey", "Grey");
		color.AddItem("brown", "Chocolate");
		color.AddItem("red", "Red");
		color.AddItem("green", "Green");
		color.AddItem("blue", "Blue");
		color.AddItem("cyan", "Cyan");
		color.AddItem("yellow", "Yellow");
		color.AddItem("orange", "Orange");
		color.AddItem("pink", "Pink");
		color.AddItem("purple", "Purple");
		color.ExitButton = true;
		color.Display(client, MENU_TIME_FOREVER);
		b_start = true;
	}
	
	if (action == MenuAction_Cancel)
		for (int i = 1; i <= MaxClients; i++)
	if (IsValidClient(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		g_samecolor[i] = false;
	
}
public int ColorHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		menu.GetItem(item, colorinfo, sizeof(colorinfo));
		if (b_start)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (g_samecolor[i])
				{
					if (StrEqual(colorinfo, "black"))
						SetClientGlow(i, 0, 0, 0, 255);
					if (StrEqual(colorinfo, "grey"))
						SetClientGlow(i, 128, 128, 128, 255);
					if (StrEqual(colorinfo, "brown"))
						SetClientGlow(i, 210, 105, 30, 255);
					if (StrEqual(colorinfo, "red"))
						SetClientGlow(i, 255, 0, 0, 255);
					if (StrEqual(colorinfo, "green"))
						SetClientGlow(i, 0, 255, 0, 255);
					if (StrEqual(colorinfo, "blue"))
						SetClientGlow(i, 0, 0, 255, 255);
					if (StrEqual(colorinfo, "cyan"))
						SetClientGlow(i, 0, 255, 255, 255);
					if (StrEqual(colorinfo, "yellow"))
						SetClientGlow(i, 255, 255, 0, 255);
					if (StrEqual(colorinfo, "orange"))
						SetClientGlow(i, 255, 165, 0, 255);
					if (StrEqual(colorinfo, "pink"))
						SetClientGlow(i, 255, 20, 147, 255);
					if (StrEqual(colorinfo, "purple"))
						SetClientGlow(i, 128, 0, 128, 255);
					
					g_samecolor[i] = false;
				}
			}
		}
	}
	if (action == MenuAction_End)
	{
		b_start = false;
		targetinfo = "";
		colorinfo = "";
		paricaltargetinfo = "";
		cs_clientid = "";
		c_clientid = "";
	}
}
public int ColorMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		menu.GetItem(item, colorinfo, sizeof(colorinfo));
		if (StrEqual(targetinfo, "all"))
		{
			if (StrEqual(colorinfo, "black"))
				SetClientGlowToAll(0, 0, 0, 255);
			if (StrEqual(colorinfo, "grey"))
				SetClientGlowToAll(128, 128, 128, 255);
			if (StrEqual(colorinfo, "brown"))
				SetClientGlowToAll(210, 105, 30, 255);
			if (StrEqual(colorinfo, "red"))
				SetClientGlowToAll(255, 0, 0, 255);
			if (StrEqual(colorinfo, "green"))
				SetClientGlowToAll(0, 255, 0, 255);
			if (StrEqual(colorinfo, "blue"))
				SetClientGlowToAll(0, 0, 255, 255);
			if (StrEqual(colorinfo, "cyan"))
				SetClientGlowToAll(0, 255, 255, 255);
			if (StrEqual(colorinfo, "yellow"))
				SetClientGlowToAll(255, 255, 0, 255);
			if (StrEqual(colorinfo, "orange"))
				SetClientGlowToAll(255, 165, 0, 255);
			if (StrEqual(colorinfo, "pink"))
				SetClientGlowToAll(255, 20, 147, 255);
			if (StrEqual(colorinfo, "purple"))
				SetClientGlowToAll(128, 0, 128, 255);
		}
		if (!StrEqual(targetinfo, "all") && !StrEqual(paricaltargetinfo, "done"))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				IntToString(i, c_clientid, sizeof(c_clientid));
				if (StrEqual(targetinfo, c_clientid))
				{
					if (StrEqual(colorinfo, "black"))
						SetClientGlow(i, 0, 0, 0, 255);
					if (StrEqual(colorinfo, "grey"))
						SetClientGlow(i, 128, 128, 128, 255);
					if (StrEqual(colorinfo, "brown"))
						SetClientGlow(i, 210, 105, 30, 255);
					if (StrEqual(colorinfo, "red"))
						SetClientGlow(i, 255, 0, 0, 255);
					if (StrEqual(colorinfo, "green"))
						SetClientGlow(i, 0, 255, 0, 255);
					if (StrEqual(colorinfo, "blue"))
						SetClientGlow(i, 0, 0, 255, 255);
					if (StrEqual(colorinfo, "cyan"))
						SetClientGlow(i, 0, 255, 255, 255);
					if (StrEqual(colorinfo, "yellow"))
						SetClientGlow(i, 255, 255, 0, 255);
					if (StrEqual(colorinfo, "orange"))
						SetClientGlow(i, 255, 165, 0, 255);
					if (StrEqual(colorinfo, "pink"))
						SetClientGlow(i, 255, 20, 147, 255);
					if (StrEqual(colorinfo, "purple"))
						SetClientGlow(i, 128, 0, 128, 255);
				}
			}
		}
		if (!StrEqual(targetinfo, "all") && StrEqual(paricaltargetinfo, "done"))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (g_samecolor[i])
				{
					if (StrEqual(colorinfo, "black"))
						SetClientGlow(i, 0, 0, 0, 255);
					if (StrEqual(colorinfo, "grey"))
						SetClientGlow(i, 128, 128, 128, 255);
					if (StrEqual(colorinfo, "brown"))
						SetClientGlow(i, 210, 105, 30, 255);
					if (StrEqual(colorinfo, "red"))
						SetClientGlow(i, 255, 0, 0, 255);
					if (StrEqual(colorinfo, "green"))
						SetClientGlow(i, 0, 255, 0, 255);
					if (StrEqual(colorinfo, "blue"))
						SetClientGlow(i, 0, 0, 255, 255);
					if (StrEqual(colorinfo, "cyan"))
						SetClientGlow(i, 0, 255, 255, 255);
					if (StrEqual(colorinfo, "yellow"))
						SetClientGlow(i, 255, 255, 0, 255);
					if (StrEqual(colorinfo, "orange"))
						SetClientGlow(i, 255, 165, 0, 255);
					if (StrEqual(colorinfo, "pink"))
						SetClientGlow(i, 255, 20, 147, 255);
					if (StrEqual(colorinfo, "purple"))
						SetClientGlow(i, 128, 0, 128, 255);
					g_samecolor[i] = false;
				}
			}
		}
	}
	if (action == MenuAction_End)
	{
		targetinfo = "";
		colorinfo = "";
		paricaltargetinfo = "";
		cs_clientid = "";
		c_clientid = "";
	}
}
stock void ConnectToDB()
{
	DB = SQL_Connect("hl_gangs", true, sError, sizeof(sError));
	if (DB == null)
	{
		SetFailState("Could not connect to database, error: %s", sError);
	}
	GetGangsCount();
}
stock void GetGangsCount()
{
	char gB_Query[512];
	FormatEx(gB_Query, 512, "SELECT gang FROM hl_gangs_groups;");
	DB.Query(SQL_GetGangs_Callback, gB_Query, _, DBPrio_Normal);
}
public void SQL_GetGangs_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[SkylerGlow] Cant use client data on insert. Reason: %s", error);
		return;
	}
	while (results.FetchRow())
	{
		g_iGangs++;
		results.FetchString(0, sGangs[g_iGangs], sizeof(sGangs));
		g_iRandomColors[g_iGangs] = GetRandomColor();
		char sTest[32];
		Format(sTest, sizeof(sTest), "%d %d %d %d", g_iRandomColors[g_iGangs][0], g_iRandomColors[g_iGangs][1], g_iRandomColors[g_iGangs][2], g_iRandomColors[g_iGangs][3]);
		while (StrContains(sColors, sTest) != -1)
		{
			g_iRandomColors[g_iGangs] = GetRandomColor();
			Format(sTest, sizeof(sTest), "%d %d %d %d", g_iRandomColors[g_iGangs][0], g_iRandomColors[g_iGangs][1], g_iRandomColors[g_iGangs][2], g_iRandomColors[g_iGangs][3]);
		}
		Format(sColors, sizeof(sColors), "%s;%s", sColors, sTest);
	}
}
stock int GetRandomColor()
{
	int iRandom = GetRandomInt(1, 32);
	int color[4];
	switch (iRandom) {
		case 1:color =  { 255, 0, 0, 255 };
		case 2:color =  { 0, 255, 0, 255 };
		case 3:color =  { 0, 0, 255, 255 };
		case 4:color =  { 255, 0, 255, 255 };
		case 5:color =  { 0, 255, 255, 255 };
		case 6:color =  { 255, 128, 0, 255 };
		case 7:color =  { 255, 255, 0, 255 };
		case 8:color =  { 255, 100, 0, 255 };
		case 9:color =  { 0, 150, 255, 255 };
		case 10:color =  { 220, 255, 166, 255 };
		case 11:color =  { 200, 100, 200, 255 };
		case 12:color =  { 153, 0, 153, 255 };
		case 13:color =  { 0, 153, 153, 255 };
		case 14:color =  { 255, 128, 0, 255 };
		case 15:color =  { 205, 192, 176, 255 };
		case 16:color =  { 240, 248, 255, 255 };
		case 17:color =  { 0, 255, 255, 255 };
		case 18:color =  { 189, 183, 107, 255 };
		case 19:color =  { 178, 34, 34, 255 };
		case 20:color =  { 240, 240, 240, 255 };
		case 21:color =  { 35, 142, 35, 255 };
		case 22:color =  { 218, 112, 214, 255 };
		case 23:color =  { 175, 238, 238, 255 };
		case 24:color =  { 221, 160, 221, 255 };
		case 25:color =  { 180, 82, 45, 255 };
		case 26:color =  { 244, 164, 96, 255 };
		case 27:color =  { 0, 128, 128, 255 };
		case 28:color =  { 148, 0, 211, 255 };
		case 29:color =  { 35, 107, 142, 255 };
		case 30:color =  { 128, 255, 165, 255 };
		case 31:color =  { 192, 192, 192, 255 };
		case 32:color =  { 140, 23, 23, 255 };
	}
	return color;
}
stock void PaintClients()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && Gangs_HasGang(i))
		{
			char sClientGang[512];
			Gangs_GetGangName(i, sClientGang, sizeof(sClientGang));
			for (int k = 1; k <= g_iGangs; k++)
			{
				if (StrEqual(sClientGang, sGangs[k]))
					SetEntityRenderColor(i, g_iRandomColors[k][0], g_iRandomColors[k][1], g_iRandomColors[k][2], g_iRandomColors[k][3]);
			}
		}
	}
}
stock void SetClientGlowToAll(int red, int green, int blue, int alpha)
{
	if((0 > red > 255) 
	|| (0 > green > 255) 
	|| (0 > blue > 255) 
	|| (0 > alpha > 255))
		PrintToChatAll("%s RGBA params cant be higher then 255!", PREFIX);
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
			SetEntityRenderColor(i, red, green, blue, alpha);
	}
}
stock void SetClientGlow(int client, int red, int green, int blue, int alpha)
{
	if((0 > red > 255) 
	|| (0 > green > 255) 
	|| (0 > blue > 255) 
	|| (0 > alpha > 255))
		PrintToChatAll("%s RGBA params cant be higher then 255 or less then 0!", PREFIX);
	else if (IsValidClient(client) && IsPlayerAlive(client))
		SetEntityRenderColor(client, red, green, blue, alpha);
}
stock int ActiveBoolenNum()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	if (g_samecolor[i])
		count++;
	return count;
} 