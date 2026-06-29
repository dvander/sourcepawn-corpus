#pragma semicolon 1

#define PLUGIN_AUTHOR "Deathknife"
#define PLUGIN_VERSION "1.01"

#include <sourcemod>
#include <sdktools>
#include <clientprefs>

public Plugin myinfo = 
{
	name = "Skybox",
	author = PLUGIN_AUTHOR,
	description = "Allow clients to choose skyboxes",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/Deathknife273/"
};

//ConVar to hook sv_skyname
ConVar SkyName;
ConVar OpenMenu;

//Menu Handle
Menu gMenu;

//Cookie to store skybox choice
Handle SkyboxCookie;

public void OnPluginStart()
{
	//Register skybox commands
	RegConsoleCmd("sm_skybox", Cmd_Skybox, "Choose a skybox!");
	RegConsoleCmd("sm_sky", Cmd_Skybox, "Choose a skybox!");
	
	//Hook the cvar sv_skyname that will be sent to clients
	SkyName = FindConVar("sv_skyname");
	
	//Register any convars
	OpenMenu = CreateConVar("sm_skybox_reopenmenu", "1", "Reopen skybox menu after choosing?");
	
	//Register cookie
	SkyboxCookie = RegClientCookie("skybox_choice", "Skybox Choice", CookieAccess_Private);
}

public void OnMapStart() {
	//Create the menu
	gMenu = new Menu(Handler_SkyboxMenu);
	gMenu.SetTitle("Choose a skybox!");
	
	//Add "default" item
	gMenu.AddItem("mapdefault", "Map Skybox");
	
	//Load skyboxes from file
	LoadSkybox();
}

public void OnMapEnd() {
	//Delete menu handle!
	delete gMenu;
}

public void OnClientCookiesCached(int client) {
	//Client's cookie cached. If bot, return
	if (IsFakeClient(client))
		return;
		
	if(IsClientConnected(client)) {
		//Buffer to store cookie
		char buffer[64];
		
		//Get cookie skybox
		GetClientCookie(client, SkyboxCookie, buffer, sizeof(buffer));
		
		//Check if it's empty
		if(StrEqual(buffer, "")) {
			return;
		}
		SetSkybox(client, buffer);
	}
}

public void SetSkybox(int client, char[] skybox) {
	//Check if skybox is default.
	if (StrEqual(skybox, "mapdefault")) {
		//If it's default, get sv_skyname and set it to client
		char buffer[32];
		GetConVarString(SkyName, buffer, sizeof(buffer));
		SendConVarValue(client, SkyName, buffer);
		
		return;
	}
	//Send sv_skyname to client
	SendConVarValue(client, SkyName, skybox);
}

public void LoadSkybox() {
	//Create keyvalues
	Handle kv = CreateKeyValues("skybox");
	//Parse from config file
	static char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/skybox.ini");
	FileToKeyValues(kv, path);
	
	//Go to top node
	KvRewind(kv);
	
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
	
	//Loop through keyvalues, add to downloads & to the menu
	char buffer[PLATFORM_MAX_PATH];
	char sPath[64];
	char name[32];
	
	int iSkyboxes = 0;
	if(KvGotoFirstSubKey(kv)) {
		do
		{
			//Get path & name
			KvGetString(kv, "path", sPath, sizeof(sPath));
			KvGetString(kv, "name", name, sizeof(name));
			//Loop through suffixes and add to downloads table
			for (int i = 0; i < sizeof(suffix);i++) {
				FormatEx(buffer, sizeof(buffer), "materials/skybox/%s%s.vtf", sPath, suffix[i]);
				if(FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
		        
				FormatEx(buffer, sizeof(buffer), "materials/skybox/%s%s.vmt", sPath, suffix[i]);
				if(FileExists(buffer, false)) AddFileToDownloadsTable(buffer);
				
			}
			
			//Add to menu
			gMenu.AddItem(sPath, name);
			
			iSkyboxes++;
			
		} while (KvGotoNextKey(kv));
	}
	
	//Print to server
	PrintToServer("[SKYBOX] Loaded %i Skyboxes!", iSkyboxes);
	
	//Close handle!
	CloseHandle(kv);
}

public Action Cmd_Skybox(int client, int argc) {
	gMenu.Display(client, MENU_TIME_FOREVER);
}

public void SkyboxMenu(int client, int start) {
	DisplayMenuAtItem(gMenu, client, start, MENU_TIME_FOREVER);
}

public int Handler_SkyboxMenu(Menu menu, MenuAction menuaction, int client, int param2) {
	if(menuaction == MenuAction_Select) {
		//Retrieve the skybox
		char info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		//Set skybox for client
		SetSkybox(client, info);
		
		//Save as cookie
		SetClientCookie(client, SkyboxCookie, info);
		
		if (OpenMenu.BoolValue)SkyboxMenu(client, GetMenuSelectionPosition());
	}
}