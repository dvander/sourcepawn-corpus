#include <sourcemod>
#include <sdktools>
#include <jwp>

#pragma semicolon 1
#pragma newdecls required

int g_Beam = -1, g_Halo = -1, g_MarkerColor[] =  { 0, 175, 255, 255 }, g_MarkerColorStat = 0, g_MarkerSpeed = 10, g_MarkerType = 0;
float g_MarkerPos[3], g_MarkerSize = 150.0, g_MarkerWidht = 3.0, g_MarkerAmplitude = 0.0, g_MarkerMesafe = 16.0, g_MarkerAna[3];
int CiftParca = 1;

public Plugin myinfo = 
{
	name = "Warden Marker", 
	author = "ByDexter", 
	description = "", 
	version = "1.3", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	AddCommandListener(CommandListener_Marker, "+lookatweapon");
	CreateTimer(1.0, Timer_MarkerOlusturma, _, TIMER_REPEAT);
	RegConsoleCmd("sm_marker", Command_Marker);
	HookEvent("round_start", Event_DeleteMarker, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_DeleteMarker, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	g_Beam = PrecacheModel("materials/sprites/laser_dexter.vmt");
	g_Halo = PrecacheModel("materials/sprites/light_glow02.vmt");
	g_MarkerType = 0;
	AddFileToDownloadsTable("materials/sprites/white_norez.vmt");
	AddFileToDownloadsTable("materials/sprites/laser_dexter.vmt");
}

public Action CommandListener_Marker(int client, const char[] command, int argc)
{
	if (JWP_IsWarden(client))
	{
		GetClientAimTargetPos(client, g_MarkerPos);
		g_MarkerPos[2] += 16.0;
	}
}

public Action Command_Marker(int client, int args)
{
	if (JWP_IsWarden(client))
	{
		Warden_Marker().Display(client, MENU_TIME_FOREVER);
		return Plugin_Handled;
	}
	else
	{
		ReplyToCommand(client, "[SM] \x01You do not have access to this menu.");
		return Plugin_Handled;
	}
}

Menu Warden_Marker()
{
	Menu menu = new Menu(Menu_CallBack);
	menu.SetTitle("▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬\n   ★ Marker - Properties ★\n▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬");
	
	if (g_MarkerSize == 100.0)
		menu.AddItem("1", "Boyut: Small");
	else if (g_MarkerSize == 150.0)
		menu.AddItem("1", "Boyut: Medium");
	else if (g_MarkerSize == 200.0)
		menu.AddItem("1", "Boyut: Large");
	else if (g_MarkerSize == 250.0)
		menu.AddItem("1", "Boyut: XLarge");
	else if (g_MarkerSize == 300.0)
		menu.AddItem("1", "Boyut: XXLarge");
	
	if (g_MarkerColorStat == 0)
		menu.AddItem("2", "Size: Blue");
	else if (g_MarkerColorStat == 1)
		menu.AddItem("2", "Size: Red");
	else if (g_MarkerColorStat == 2)
		menu.AddItem("2", "Size: Green");
	else if (g_MarkerColorStat == 3)
		menu.AddItem("2", "Size: Yellow");
	else if (g_MarkerColorStat == 4)
		menu.AddItem("2", "Size: White");
	else if (g_MarkerColorStat == 5)
		menu.AddItem("2", "Size: Pink");
	else if (g_MarkerColorStat == 6)
		menu.AddItem("2", "Size: Random");
	
	if (g_MarkerWidht == 3.0)
		menu.AddItem("3", "Widht: 3.0");
	else if (g_MarkerWidht == 5.0)
		menu.AddItem("3", "Widht: 5.0");
	else if (g_MarkerWidht == 8.0)
		menu.AddItem("3", "Widht: 8.0");
	else if (g_MarkerWidht == 10.0)
		menu.AddItem("3", "Widht: 10.0");
	
	if (g_MarkerType == 0 || g_MarkerType == 2)
	{
		if (g_MarkerSpeed == 0)
			menu.AddItem("4", "Speed: Off");
		else if (g_MarkerSpeed == 10)
			menu.AddItem("4", "Speed: Slow");
		else if (g_MarkerSpeed == 35)
			menu.AddItem("4", "Speed: Normal");
		else if (g_MarkerSpeed == 50)
			menu.AddItem("4", "Speed: Fast");
		else if (g_MarkerSpeed == 100)
			menu.AddItem("4", "Speed: High Fast");
	}
	else if (g_MarkerType == 1 || g_MarkerType == 3)
		menu.AddItem("4", "Speed: Closed", ITEMDRAW_DISABLED);
	
	if (g_MarkerAmplitude == 0.0)
		menu.AddItem("5", "Amplitude: Off");
	else if (g_MarkerAmplitude == 1.0)
		menu.AddItem("5", "Amplitude: Slow");
	else if (g_MarkerAmplitude == 3.0)
		menu.AddItem("5", "Amplitude: Normal");
	else if (g_MarkerAmplitude == 5.0)
		menu.AddItem("5", "Amplitude: Fast");
	else if (g_MarkerAmplitude == 10.0)
		menu.AddItem("5", "Amplitude: High Fast");
	
	if (g_MarkerType == 0)
		menu.AddItem("6", "Type: Beam (WH)");
	else if (g_MarkerType == 1)
		menu.AddItem("6", "Type: Smooth (WH)");
	else if (g_MarkerType == 2)
		menu.AddItem("6", "Type: Beam");
	else if (g_MarkerType == 3)
		menu.AddItem("6", "Type: Smooth");
	
	if (CiftParca == 1)
		menu.AddItem("7", "Piece: One");
	else if (CiftParca == 2)
		menu.AddItem("7", "Piece: Two");
	else if (CiftParca == 3)
		menu.AddItem("7", "Piece: Three");
	
	if (CiftParca == 1)
		menu.AddItem("8", "Piece Distance: Closed", ITEMDRAW_DISABLED);
	else
	{
		if (g_MarkerMesafe == 16.0)
			menu.AddItem("8", "Piece Distance: Short");
		else if (g_MarkerMesafe == 20.0)
			menu.AddItem("8", "Piece Distance: Normal");
		else if (g_MarkerMesafe == 24.0)
			menu.AddItem("8", "Piece Distance: Long");
	}
	return menu;
}

public int Menu_CallBack(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if (JWP_IsWarden(param1))
		{
			char Item[4];
			menu.GetItem(param2, Item, sizeof(Item));
			if (strcmp(Item, "1", false) == 0)
			{
				if (g_MarkerSize == 100.0)
					g_MarkerSize = 150.0;
				else if (g_MarkerSize == 150.0)
					g_MarkerSize = 200.0;
				else if (g_MarkerSize == 200.0)
					g_MarkerSize = 250.0;
				else if (g_MarkerSize == 250.0)
					g_MarkerSize = 300.0;
				else if (g_MarkerSize == 300.0)
					g_MarkerSize = 100.0;
			}
			else if (strcmp(Item, "2", false) == 0)
			{
				g_MarkerColorStat++;
				if (g_MarkerColorStat == 1)
					g_MarkerColor =  { 255, 50, 50, 255 };
				else if (g_MarkerColorStat == 2)
					g_MarkerColor =  { 0, 255, 0, 255 };
				else if (g_MarkerColorStat == 3)
					g_MarkerColor =  { 255, 251, 0, 255 };
				else if (g_MarkerColorStat == 4)
					g_MarkerColor =  { 255, 255, 255, 255 };
				else if (g_MarkerColorStat == 5)
					g_MarkerColor =  { 255, 0, 75, 255 };
				else if (g_MarkerColorStat == 7)
				{
					g_MarkerColorStat = 0;
					g_MarkerColor =  { 0, 175, 255, 255 };
				}
			}
			else if (strcmp(Item, "3", false) == 0)
			{
				if (g_MarkerWidht == 3.0)
					g_MarkerWidht = 5.0;
				else if (g_MarkerWidht == 5.0)
					g_MarkerWidht = 8.0;
				else if (g_MarkerWidht == 8.0)
					g_MarkerWidht = 10.0;
				else if (g_MarkerWidht == 10.0)
					g_MarkerWidht = 3.0;
			}
			else if (strcmp(Item, "4", false) == 0)
			{
				if (g_MarkerSpeed == 0)
					g_MarkerSpeed = 10;
				else if (g_MarkerSpeed == 10)
					g_MarkerSpeed = 35;
				else if (g_MarkerSpeed == 35)
					g_MarkerSpeed = 50;
				else if (g_MarkerSpeed == 50)
					g_MarkerSpeed = 100;
				else if (g_MarkerSpeed == 100)
					g_MarkerSpeed = 0;
			}
			else if (strcmp(Item, "5", false) == 0)
			{
				if (g_MarkerAmplitude == 0.0)
					g_MarkerAmplitude = 1.0;
				else if (g_MarkerAmplitude == 1.0)
					g_MarkerAmplitude = 3.0;
				else if (g_MarkerAmplitude == 3.0)
					g_MarkerAmplitude = 5.0;
				else if (g_MarkerAmplitude == 5.0)
					g_MarkerAmplitude = 10.0;
				else if (g_MarkerAmplitude == 10.0)
					g_MarkerAmplitude = 0.0;
			}
			else if (strcmp(Item, "6", false) == 0)
			{
				g_MarkerType++;
				if (g_MarkerType == 1)
					g_Beam = PrecacheModel("materials/sprites/white.vmt");
				else if (g_MarkerType == 2)
					g_Beam = PrecacheModel("materials/sprites/laserbeam.vmt");
				else if (g_MarkerType == 3)
					g_Beam = PrecacheModel("materials/sprites/white_norez.vmt");
				else if (g_MarkerType == 4)
				{
					g_MarkerType = 0;
					g_Beam = PrecacheModel("materials/sprites/laser_dexter.vmt");
				}
			}
			else if (strcmp(Item, "7", false) == 0)
			{
				CiftParca++;
				if (CiftParca == 4 || CiftParca == 0)
					CiftParca = 1;
			}
			else if (strcmp(Item, "8", false) == 0)
			{
				if (g_MarkerMesafe == 16.0)
					g_MarkerMesafe = 20.0;
				else if (g_MarkerMesafe == 20.0)
					g_MarkerMesafe = 24.0;
				else if (g_MarkerMesafe == 24.0)
					g_MarkerMesafe = 16.0;
			}
			Warden_Marker().Display(param1, MENU_TIME_FOREVER);
		}
		else
		{
			PrintToChat(param1, "[SM] \x01You do not have access to this menu.");
		}
	}
	else if (action == MenuAction_End)
		delete menu;
}

public Action Event_DeleteMarker(Event event, const char[] name, bool dontBroadcast)
{
	if (g_MarkerPos[0] == 0.0)
		return;
	Marker_Sifirla();
}

public Action Timer_MarkerOlusturma(Handle timer, any data)
{
	Marker_Olustur();
	return Plugin_Continue;
}

void Marker_Olustur()
{
	if (g_MarkerPos[0] == 0.0)return;
	if (CiftParca == 1)
	{
		if (g_MarkerColorStat == 6)
		{
			int G_Color[4];
			G_Color[0] = GetRandomInt(1, 255);
			G_Color[1] = GetRandomInt(1, 255);
			G_Color[2] = GetRandomInt(1, 255);
			G_Color[3] = 255;
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, G_Color, g_MarkerSpeed, 0);
			
		}
		else if (g_MarkerColorStat != 6)
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, g_MarkerColor, g_MarkerSpeed, 0);
		TE_SendToAll();
	}
	else if (CiftParca == 2)
	{
		g_MarkerAna[2] = g_MarkerPos[2];
		if (g_MarkerColorStat == 6)
		{
			int G_Color[4];
			G_Color[0] = GetRandomInt(1, 255);
			G_Color[1] = GetRandomInt(1, 255);
			G_Color[2] = GetRandomInt(1, 255);
			G_Color[3] = 255;
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, G_Color, g_MarkerSpeed, 0);
			TE_SendToAll();
			g_MarkerPos[2] += g_MarkerMesafe;
			G_Color[0] = GetRandomInt(1, 255);
			G_Color[1] = GetRandomInt(1, 255);
			G_Color[2] = GetRandomInt(1, 255);
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, G_Color, g_MarkerSpeed, 0);
			TE_SendToAll();
		}
		else if (g_MarkerColorStat != 6)
		{
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, g_MarkerColor, g_MarkerSpeed, 0);
			TE_SendToAll();
			g_MarkerPos[2] += g_MarkerMesafe;
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, g_MarkerColor, g_MarkerSpeed, 0);
			TE_SendToAll();
		}
		g_MarkerPos[2] = g_MarkerAna[2];
	}
	else if (CiftParca == 3)
	{
		g_MarkerAna[2] = g_MarkerPos[2];
		if (g_MarkerColorStat == 6)
		{
			int G_Color[4];
			G_Color[0] = GetRandomInt(1, 255);
			G_Color[1] = GetRandomInt(1, 255);
			G_Color[2] = GetRandomInt(1, 255);
			G_Color[3] = 255;
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, G_Color, g_MarkerSpeed, 0);
			TE_SendToAll();
			g_MarkerPos[2] += g_MarkerMesafe;
			G_Color[0] = GetRandomInt(1, 255);
			G_Color[1] = GetRandomInt(1, 255);
			G_Color[2] = GetRandomInt(1, 255);
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, G_Color, g_MarkerSpeed, 0);
			TE_SendToAll();
			g_MarkerPos[2] += g_MarkerMesafe;
			G_Color[0] = GetRandomInt(1, 255);
			G_Color[1] = GetRandomInt(1, 255);
			G_Color[2] = GetRandomInt(1, 255);
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, G_Color, g_MarkerSpeed, 0);
			TE_SendToAll();
		}
		else if (g_MarkerColorStat != 6)
		{
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, g_MarkerColor, g_MarkerSpeed, 0);
			TE_SendToAll();
			g_MarkerPos[2] += g_MarkerMesafe;
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, g_MarkerColor, g_MarkerSpeed, 0);
			TE_SendToAll();
			g_MarkerPos[2] += g_MarkerMesafe;
			TE_SetupBeamRingPoint(g_MarkerPos, g_MarkerSize, g_MarkerSize + 0.1, g_Beam, g_Halo, 0, 10, 1.0, g_MarkerWidht, g_MarkerAmplitude, g_MarkerColor, g_MarkerSpeed, 0);
			TE_SendToAll();
		}
		g_MarkerPos[2] = g_MarkerAna[2];
	}
}

void Marker_Sifirla() { for (int i = 0; i < 3; i++)g_MarkerPos[i] = 0.0; }

int GetClientAimTargetPos(int client, float pos[3])
{
	if (!client)
		return -1;
	float vAngles[3]; float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
	TR_GetEndPosition(pos, trace);
	int entity = TR_GetEntityIndex(trace);
	delete trace;
	return entity;
}

public bool TraceFilterAllEntities(int entity, int contentsMask, any client)
{
	if (entity == client)
		return false;
	if (entity > MaxClients)
		return false;
	if (!IsClientInGame(entity))
		return false;
	if (!IsPlayerAlive(entity))
		return false;
	return true;
} 