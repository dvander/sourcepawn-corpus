#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <vip_core>

// Force 1.7 syntax
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

char g_cFeature[] = "skybox";

ConVar g_CvarSkyName;
Handle g_hCookie;
KeyValues g_Kv;
Menu g_Menu;

public Plugin myinfo =
{
	name = "[VIP] Skybox",
	description = "Allow vip players to choose skyboxes",
	author = "White Wolf",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/doctor_white http://steamcommunity.com/id/Deathknife273/ http://hlmod.ru"
};

public void OnPluginStart()
{
	g_hCookie = RegClientCookie("VIP_Skybox", "VIP_Skybox", CookieAccess_Public);
	
	// Find sv_skyname for clients
	g_CvarSkyName = FindConVar("sv_skyname");
	
	if (VIP_IsVIPLoaded())
		VIP_OnVIPLoaded();
	
	//RegConsoleCmd("sm_skybox", g_Menu, "Choose a skybox");
	//RegConsoleCmd("sm_sky", g_Menu, "Choose a skybox");
	
	LoadTranslations("vip_modules.phrases");
}

public void OnMapStart()
{
	g_Menu = new Menu(SkyboxMenu_Handler, MenuAction_Select|MenuAction_Cancel|MenuAction_DisplayItem);
	g_Menu.SetTitle("Escolha um SkyBox");
	// Add "default skybox" item
	g_Menu.AddItem("", "Padrão (Mapa)");
	g_Menu.ExitBackButton = true;
	LoadSkybox();
}

public void OnMapEnd()
{
	delete g_Menu;
}

public void VIP_OnVIPClientLoaded(int client)
{
	if(VIP_GetClientFeatureStatus(client, g_cFeature) != NO_ACCESS)
	{
		char cInfo[64];
		// Get cookie value
		GetClientCookie(client, g_hCookie, cInfo, sizeof(cInfo));
		if (cInfo[0] != NULL_STRING[0])
		{
			char cBuffer[64];
			if (IsSkyboxExistInKV(cInfo, cBuffer, sizeof(cBuffer)))
			{
				if (cBuffer[0] != NULL_STRING[0])
					SetSkybox(client, cBuffer);
			}
		}
	}
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_cFeature, BOOL, SELECTABLE, OnSkyboxItemSelect);
}

public bool OnSkyboxItemSelect(int client, const char[] cFeature)
{
	g_Menu.Display(client, MENU_TIME_FOREVER);
	
	return false;
}

public int SkyboxMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				VIP_SendClientVIPMenu(param1);
		}
		case MenuAction_Select:
		{
			char cInfo[64], cPath[64];
			menu.GetItem(param2, cInfo, sizeof(cInfo));
			if (IsSkyboxExistInKV(cInfo, cPath, sizeof(cPath)))
			{
				SetClientCookie(param1, g_hCookie, cInfo);
				//Set skybox for client (param1)
				SetSkybox(param1, cPath);
			}
			
			menu.DisplayAt(param1, menu.Selection, MENU_TIME_FOREVER);
		}
		case MenuAction_DisplayItem:
		{
			char cClientCookie[64], cInfo[64], cDisplay[64];
			menu.GetItem(param2, cInfo, sizeof(cInfo), _, cDisplay, sizeof(cDisplay));
			GetClientCookie(param1, g_hCookie, cClientCookie, sizeof(cClientCookie));
			
			if (StrEqual(cClientCookie, cInfo, false))
			{
				StrCat(cDisplay, sizeof(cDisplay), "[X]");
				return RedrawMenuItem(cDisplay);
			}
			
			return 0;
		}
	}
	
	return 0;
}

void SetSkybox(int client, const char[] cSkybox)
{
	// If skybox is default
	if (cSkybox[0] == NULL_STRING[0])
	{
		char cBuffer[32];
		g_CvarSkyName.GetString(cBuffer, sizeof(cBuffer));
		g_CvarSkyName.ReplicateToClient(client, cBuffer);
	}
	else
		g_CvarSkyName.ReplicateToClient(client, cSkybox);
}

void LoadSkybox()
{
	g_Kv = new KeyValues("Skybox");
	char cBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, cBuffer, sizeof(cBuffer), "data/vip/modules/skybox.ini");
	
	if (!g_Kv.ImportFromFile(cBuffer))
	{
		delete g_Kv;
		SetFailState("Failed to read from file \"%s\"", cBuffer);
	}
	g_Kv.Rewind();
	
	//Skybox suffixes.
	static char suffix[][] = {
		"bk",
		"Bk",
		"dn",
		"Dn",
		"ft",
		"Ft",
		"lf",
		"Lf",
		"rt",
		"Rt",
		"up",
		"Up",
	};
	
	if (g_Kv.GotoFirstSubKey())
	{
		char cPath[64];
		do
		{
			g_Kv.GetSectionName(cBuffer, sizeof(cBuffer));
			g_Menu.AddItem(cBuffer, cBuffer);
			// Get path
			g_Kv.GetString("path", cPath, sizeof(cPath));
			
			for (int i = 0; i < sizeof(suffix); ++i)
			{
				FormatEx(cBuffer, sizeof(cBuffer), "materials/skybox/%s%s.vtf", cPath, suffix[i]);
				if (FileExists(cBuffer, false)) AddFileToDownloadsTable(cBuffer);
				
				FormatEx(cBuffer, sizeof(cBuffer), "materials/skybox/%s%s.vmt", cPath, suffix[i]);
				if (FileExists(cBuffer, false)) AddFileToDownloadsTable(cBuffer);
			}			
		} while (g_Kv.GotoNextKey());
	}
	
	g_Kv.Rewind();
}

bool IsSkyboxExistInKV(const char[] cInfo, char[] cPath, int maxlength)
{
	// if `default` checked
	if (cInfo[0] == NULL_STRING[0])
		return true;
	
	KeyValues kv = new KeyValues("skybox_copy");
	KvCopySubkeys(g_Kv, kv);
	
	if (kv.JumpToKey(cInfo))
	{
		kv.GetString("path", cPath, maxlength);
		delete kv;
		return true;
	}
	
	delete kv;
	return false;
}