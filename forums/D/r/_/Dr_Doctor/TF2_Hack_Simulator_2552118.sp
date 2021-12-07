/*************************************************************************************************

---------------------------------[Sourcemod Hack Simulator]---------------------------------------

-------|	CREDITS:
-------|	ReFlexPoison: Bhop, AutoAirblast, 
-------|	shanapu : I stole many codes from him. Menu format, laser
-------|	DarthNinja : Thirdperson, 
-------|	retsam : AimName, 
-------|	Friagram : Aimbot, 
-------|	Deathreus : Aimbot, AutoAirblast

*************************************************************************************************/

////////////////////////
// Table of contents: // 
//		Main Menu	  //
//					  //
//		1.AIMBOT      //
//		2.TRIGGER	  //
//		3.ESP		  //
//	RADAR(Diasbled)   //
//		4.VISUALS	  //
//		5.MISC		  //
////////////////////////

#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Battlefield Duck"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools> 
#include <tf2_stocks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "[TF2] Sourcemod Hack Simulator",
	author = PLUGIN_AUTHOR,
	description = "A Hacking Simulator for tf2 by using sourcemod",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/battlefieldduck/"
};

EngineVersion game;
//Handle
Handle g_hHud;
//Bool
bool bEnabled = true;
bool g_bHopping			[MAXPLAYERS + 1];
bool g_bDuckJump		[MAXPLAYERS + 1];
bool g_bChatSpammer		[MAXPLAYERS + 1];
bool g_bVoiceSpammer	[MAXPLAYERS + 1];
bool g_bThirdperson		[MAXPLAYERS + 1];
bool g_bPlayers			[MAXPLAYERS + 1];
bool g_bLaser			[MAXPLAYERS + 1];
bool g_bEnemyOnly		[MAXPLAYERS + 1];
bool g_bCritHack		[MAXPLAYERS + 1];
bool g_bNoHands			[MAXPLAYERS + 1];
bool g_bNoScope			[MAXPLAYERS + 1];
bool g_bNoZoom			[MAXPLAYERS + 1];
bool g_bAirstuckMode    [MAXPLAYERS + 1];
bool g_bPlayerInfo		[MAXPLAYERS + 1];
bool g_bAimFoV			[MAXPLAYERS + 1];
bool g_bAutoShoot		[MAXPLAYERS + 1];
bool g_bAutoZoom		[MAXPLAYERS + 1];
bool g_bMeleeAimbot		[MAXPLAYERS + 1];
//int
int g_bAutoReflecting	[MAXPLAYERS + 1];
int g_bAutoAiming		[MAXPLAYERS + 1];
int g_iPlayerDesiredFOV [MAXPLAYERS + 1];
int g_iBeamSprite = -1;
int g_iBlueSprite = -1;
int g_iRedSprite = -1;
int g_iColors[2][4] = 
{
	{255, 0, 0, 255}, // red
	{0, 65, 255, 255}, // blue
};

public void OnPluginStart()
{
	game = GetEngineVersion();
	if(game != Engine_TF2)
		SetFailState("Game not supported.");
	//Hook
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	
	//ConVar
	CreateConVar("sm_hacksim_version", PLUGIN_VERSION, "", FCVAR_SPONLY|FCVAR_NOTIFY);

	//Commands
	RegAdminCmd("sm_hm", Command_HackMenu, ADMFLAG_ROOT, "Open hack menu");
	RegAdminCmd("sm_hackmenu", Command_HackMenu, ADMFLAG_ROOT, "Open hack menu");
	
	//Sync Hud
	g_hHud = CreateHudSynchronizer();
}

public void OnMapStart()
{
	g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iBlueSprite = PrecacheModel("materials/sprites/blueglow2.vmt");
	g_iRedSprite = PrecacheModel("materials/sprites/redglow2.vmt");
}

/*******************************************************************************************
	Main Hack Menu
*******************************************************************************************/
public Action Command_HackMenu(int client, int args)
{
	if (bEnabled)
	{
		char menuinfo[255];
		Menu menu = new Menu(Handler_HackMenu);
			
		Format(menuinfo, sizeof(menuinfo), "Hack Simulator Menu v1.0", client);
		menu.SetTitle(menuinfo);

		Format(menuinfo, sizeof(menuinfo), "AIMBOT", client);
		menu.AddItem("AIMBOT", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "TRIGGER", client);
		menu.AddItem("TRIGGER", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "ESP", client);
		menu.AddItem("ESP", menuinfo);
		//Format(menuinfo, sizeof(menuinfo), "RADAR", client);
		//menu.AddItem("RADAR", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "VISUALS", client);
		menu.AddItem("VISUALS", menuinfo);
		Format(menuinfo, sizeof(menuinfo), "MISC", client);
		menu.AddItem("MISC", menuinfo);

		menu.ExitBackButton = false;
		menu.ExitButton = true;
		menu.Display(client, -1);
	}
	return Plugin_Handled;
}

public int Handler_HackMenu(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));

		if (strcmp(info, "AIMBOT") == 0)
		{
			Command_AIMBOTMenu(client, -1);
		}
		else if (strcmp(info, "TRIGGER") == 0)
		{
			Command_TRIGGERMenu(client, -1);
		}
		else if (strcmp(info, "ESP") == 0)
		{
			Command_ESPMenu(client, -1);
		}
		//else if (strcmp(info, "RADAR") == 0)
		//{
		//	Command_RADARMenu(client, -1);
		//}
		else if (strcmp(info, "VISUALS") == 0)
		{
			Command_VISUALSMenu(client, -1);
		}
		else if (strcmp(info, "MISC") == 0)
		{
			Command_MISCMenu(client, -1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack) 
		{
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
/*******************************************************************************************
	Main Aimbot Menu
*******************************************************************************************/
public Action Command_AIMBOTMenu(int client, int args)
{
	if (bEnabled)
	{
		char menuinfo[255];
		Menu menu = new Menu(Handler_AIMBOTMenu);
			
		Format(menuinfo, sizeof(menuinfo), "Hack Simulator Menu \n AIMBOT (Work in progress)", client);
		menu.SetTitle(menuinfo);

		char status[12] = "OFF";
		if (g_bAutoAiming[client])	status = "ON";
		
		Format(menuinfo, sizeof(menuinfo), "AIM BOT : %s", status, client);
		menu.AddItem("AimBot", menuinfo);
		status = "OFF";

		if (g_bAimFoV[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "AIM FOV : %s", status, client);
		menu.AddItem("AimFov", menuinfo);
		status = "OFF";
		
		if (g_bAutoShoot[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "AUTO SHOOT : %s", status, client);
		menu.AddItem("AutoShoot", menuinfo);
		status = "OFF";
		
		if (g_bAutoZoom[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "(Sniper)AUTO ZOOM : %s", status, client);
		menu.AddItem("AutoZoom", menuinfo);
		status = "OFF";
		
		if (g_bMeleeAimbot[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "MELEE AIMBOT : %s", status, client);
		menu.AddItem("MeleeAimbot", menuinfo);
		status = "OFF";
		
		if (g_bCritHack[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "CRIT HACK : %s", status, client);
		menu.AddItem("Crithack", menuinfo);
		status = "OFF";
		
		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, -1);
	}
	return Plugin_Handled;
}

public int Handler_AIMBOTMenu(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));
		
		
		if (strcmp(info, "AimBot") == 0)
		{
			if(g_bAutoAiming[client])
			{		
				g_bAutoAiming[client] = false;
			}
			else	
			{
				g_bAutoAiming[client] = true;
			}
		}
		else if (strcmp(info, "AimFov") == 0)
		{
			if(g_bAimFoV[client])
			{		
				g_bAimFoV[client] = false;
			}
			else	
			{
				g_bAimFoV[client] = true;
			}
		}
		else if (strcmp(info, "AutoShoot") == 0)
		{
			if(g_bAutoShoot[client])
			{		
				g_bAutoShoot[client] = false;
			}
			else	
			{
				g_bAutoShoot[client] = true;
			}
		}
		else if (strcmp(info, "AutoZoom") == 0)
		{
			if(g_bAutoZoom[client])
			{		
				g_bAutoZoom[client] = false;
			}
			else	
			{
				g_bAutoZoom[client] = true;
			}
		}
		else if (strcmp(info, "MeleeAimbot") == 0)
		{
			if(g_bMeleeAimbot[client])
			{		
				g_bMeleeAimbot[client] = false;
			}
			else	
			{
				g_bMeleeAimbot[client] = true;
			}
		}
		else if (strcmp(info, "Crithack") == 0)
		{
			if(g_bCritHack[client])
			{		
				g_bCritHack[client] = false;
				TF2_RemoveCondition(client, TFCond_HalloweenCritCandy);
			}
			else	
			{
				g_bCritHack[client] = true;
				TF2_AddCondition(client, TFCond_HalloweenCritCandy, TFCondDuration_Infinite);
				//TF2_AddCondition(client, TFCond_CritOnWin, -1.0); //not work???
			}
		}
		Command_AIMBOTMenu(client, -1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack) 
		{
			Command_HackMenu(client, -1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/*******************************************************************************************
	Main Trigger Menu
*******************************************************************************************/
public Action Command_TRIGGERMenu(int client, int args)
{
	if (bEnabled)
	{
		char menuinfo[255];
		Menu menu = new Menu(Handler_TRIGGERMenu);
			
		Format(menuinfo, sizeof(menuinfo), "Hack Simulator Menu \n TRIGGER (Work in progress)", client);
		menu.SetTitle(menuinfo);
		
		char status[4] = "OFF";
		if(g_bAutoReflecting[client])	status = "ON";
		
		Format(menuinfo, sizeof(menuinfo), "AUTO AIRBLAST : %s", status, client);
		menu.AddItem("AutoAirblast", menuinfo);

		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, -1);
	}
	return Plugin_Handled;
}

public int Handler_TRIGGERMenu(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));

		if (strcmp(info, "AutoAirblast") == 0)
		{
			if(g_bAutoReflecting[client])
			{		
				g_bAutoReflecting[client] = false;
			}
			else	
			{
				g_bAutoReflecting[client] = true;
			}
		}
		//else if (strcmp(info, "TRIGGER") == 0)
		//{
		//}
		Command_TRIGGERMenu(client, -1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack) 
		{
			Command_HackMenu(client, -1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/*******************************************************************************************
	Main ESP Menu
*******************************************************************************************/
public Action Command_ESPMenu(int client, int args)
{
	if (bEnabled)
	{
		char menuinfo[255];
		Menu menu = new Menu(Handler_ESPMenu);
			
		Format(menuinfo, sizeof(menuinfo), "Hack Simulator Menu \n ESP", client);
		menu.SetTitle(menuinfo);
		
		char status[4] = "OFF";
		
		if(g_bPlayers[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "PLAYERS : %s", status, client);
		menu.AddItem("Players", menuinfo);
		status = "OFF";
		
		if(g_bLaser[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "LASER : %s", status, client);
		menu.AddItem("Laser", menuinfo);
		status = "OFF";
		
		if(g_bEnemyOnly[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "ENEMY ONLY : %s", status, client);
		menu.AddItem("EnemyOnly", menuinfo);
		status = "OFF";
		
		if(g_bPlayerInfo[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "PLAYER INFO : %s", status, client);
		menu.AddItem("PlayerInfo", menuinfo);

		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, -1);
	}
	return Plugin_Handled;
}

public int Handler_ESPMenu(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));

		if (strcmp(info, "Players") == 0)
		{
			if(g_bPlayers[client])
			{		
				g_bPlayers[client] = false;
				//TF2_RemoveCondition(client, view_as<TFCond>(114));
			}
			else	
			{
				g_bPlayers[client] = true;	
				//TF2_AddCondition(client, view_as<TFCond>(114), -1.0); // teammate only
				//SetEntProp(client, Prop_Send, "m_iTeamNum" , 1);      //This will trigger the outline of oppoent team but team changed to spec -buggy
			}
		}
		else if (strcmp(info, "Laser") == 0)
		{
			if(g_bLaser[client])
			{
				g_bLaser[client] = false;
			}
			else	
			{
				g_bLaser[client] = true;	
			}
		}
		else if (strcmp(info, "EnemyOnly") == 0)
		{
			if(g_bEnemyOnly[client])
			{
				g_bEnemyOnly[client] = false;
			}
			else	
			{
				g_bEnemyOnly[client] = true;	
			}
		}
		else if (strcmp(info, "PlayerInfo") == 0)
		{
			if(g_bPlayerInfo[client])
			{
				g_bPlayerInfo[client] = false;
			}
			else	
			{
				g_bPlayerInfo[client] = true;	
				CreateTimer(0.1, Timer_PlayerInfo, client);
			}
		}
		Command_ESPMenu(client, -1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack) 
		{
			Command_HackMenu(client, -1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/*******************************************************************************************
	Main RADAR Menu			(Disabled)
*******************************************************************************************/
/*
public Action Command_RADARMenu(int client, int args)
{
	if (bEnabled)
	{
		char menuinfo[255];
		Menu menu = new Menu(Handler_RADARMenu);
			
		Format(menuinfo, sizeof(menuinfo), "Hack Simulator Menu \n RADAR (Work in progress)", client);
		menu.SetTitle(menuinfo);
		
		char status[4] = "OFF";
		if(g_bRadar)	status = "ON";
		
		Format(menuinfo, sizeof(menuinfo), "RADAR : %s", status, client);
		menu.AddItem("radar", menuinfo);

		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, -1);
	}
	return Plugin_Handled;
}

public int Handler_RADARMenu(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));

		if (strcmp(info, "radar") == 0)
		{
			
		}
		//else if (strcmp(info, "TRIGGER") == 0)
		//{
		//}
		Command_RADARMenu(client, -1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack) 
		{
			Command_HackMenu(client, -1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}
*/
/*******************************************************************************************
	Main VISUALS Menu
*******************************************************************************************/
public Action Command_VISUALSMenu(int client, int args)
{
	if (bEnabled)
	{
		char menuinfo[255];
		Menu menu = new Menu(Handler_VISUALSMenu);
			
		Format(menuinfo, sizeof(menuinfo), "Hack Simulator Menu \n VISUAL", client);
		menu.SetTitle(menuinfo);

		char status[4] = "OFF";
		if(g_bThirdperson[client])	status = "ON";
		
		Format(menuinfo, sizeof(menuinfo), "THIRD PERSON : %s", status, client);
		menu.AddItem("Thirdperson", menuinfo);
		status = "OFF";
		
		if(g_bNoHands[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "NO HANDS : %s", status, client);
		menu.AddItem("NoHands", menuinfo);
		status = "OFF";
		
		if(g_bNoScope[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "NO SCOPE : %s", status, client);
		menu.AddItem("NoScope", menuinfo);
		status = "OFF";
		
		if(g_bNoZoom[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "NO ZOOM : %s", status, client);
		menu.AddItem("NoZoom", menuinfo);
		status = "OFF";


		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, -1);
	}
	return Plugin_Handled;
}

public int Handler_VISUALSMenu(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));

		if (strcmp(info, "Thirdperson") == 0)
		{
			if(g_bThirdperson[client])
			{		
				SetVariantInt(0);
				AcceptEntityInput(client, "SetForcedTauntCam");
				g_bThirdperson[client] = false;
			}
			else	
			{
				SetVariantInt(1);
				AcceptEntityInput(client, "SetForcedTauntCam");
				g_bThirdperson[client] = true;
			}
		}
		else if (strcmp(info, "NoHands") == 0)
		{
			if(g_bNoHands[client])
			{		
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
				g_bNoHands[client] = false;
			}
			else	
			{
				SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
				g_bNoHands[client] = true;

			}
		}
		else if (strcmp(info, "NoScope") == 0)
		{
			if(g_bNoScope[client])
			{		
				g_bNoScope[client] = false;
				SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
			}
			else	
			{
				g_bNoScope[client] = true;
			}
		}
		else if (strcmp(info, "NoZoom") == 0)
		{
			if(g_bNoZoom[client])
			{		
				g_bNoZoom[client] = false;
			}
			else	
			{
				g_bNoZoom[client] = true;
			}
		}
		Command_VISUALSMenu(client, -1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack) 
		{
			Command_HackMenu(client, -1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/*******************************************************************************************
	Main MISC Menu
*******************************************************************************************/
public Action Command_MISCMenu(int client, int args)
{
	if (bEnabled)
	{
		char menuinfo[255];
		Menu menu = new Menu(Handler_MISCMenu);
			
		Format(menuinfo, sizeof(menuinfo), "Hack Simulator Menu \n MISC", client);
		menu.SetTitle(menuinfo);
		
		char status[4] = "OFF";
		if(g_bHopping[client])	status = "ON";
		
		Format(menuinfo, sizeof(menuinfo), "BUNNY HOP : %s", status, client);
		menu.AddItem("BunnyHop", menuinfo);
		
		status = "OFF";
		if(g_bDuckJump[client])	status = "ON";
		
		Format(menuinfo, sizeof(menuinfo), "DUCK JUMP : %s", status, client);
		menu.AddItem("DuckJump", menuinfo);
		
		status = "OFF";
		if(g_bChatSpammer[client])	status = "ON";
		Format(menuinfo, sizeof(menuinfo), "CHAT SPAMMER : %s", status, client);
		menu.AddItem("ChatSpammer", menuinfo);
		status = "OFF";
		if(g_bVoiceSpammer[client])	status = "ON";
		
		Format(menuinfo, sizeof(menuinfo), "VOICEMENU SPAM : %s", status, client);
		menu.AddItem("VoiceSpam", menuinfo);
		status = "OFF";
		
		if (g_bAirstuckMode[client])status = "ON";
		Format(menuinfo, sizeof(menuinfo), "AIRSTUCK MODE : %s", status, client);
		menu.AddItem("AirstuckMode", menuinfo);
		status = "OFF";
		
		Format(menuinfo, sizeof(menuinfo), "Fake VAC Ban Message", client);
		menu.AddItem("FVBM", menuinfo);
		

		menu.ExitBackButton = true;
		menu.ExitButton = false;
		menu.Display(client, -1);
	}
	return Plugin_Handled;
}

public int Handler_MISCMenu(Menu menu, MenuAction action, int client, int selection)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(selection, info, sizeof(info));

		if (strcmp(info, "BunnyHop") == 0)
		{
			if(g_bHopping[client])
			{		
				g_bHopping[client] = false;
			}
			else	
			{
				g_bHopping[client] = true;
			}
		}
		else if (strcmp(info, "DuckJump") == 0)
		{
			if(g_bDuckJump[client])
			{		
				g_bDuckJump[client] = false;
			}
			else	
			{
				g_bDuckJump[client] = true;
			}
		}
		else if (strcmp(info, "ChatSpammer") == 0)
		{
			if(g_bChatSpammer[client])
			{		
				g_bChatSpammer[client] = false;
			}
			else	
			{
				g_bChatSpammer[client] = true;
				CreateTimer(0.1, Timer_ChatSpam, client);
			}
		}
		else if (strcmp(info, "VoiceSpam") == 0)
		{
			if(g_bVoiceSpammer[client])
			{		
				g_bVoiceSpammer[client] = false;
			}
			else	
			{
				g_bVoiceSpammer[client] = true;
				CreateTimer(1.0, Timer_VoiceSpam, client);
			}
		}
		else if (strcmp(info, "AirstuckMode") == 0)
		{
			if(g_bAirstuckMode[client])
			{		
				g_bAirstuckMode[client] = false;
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
			else	
			{
				g_bAirstuckMode[client] = true;
				SetEntityMoveType(client, MOVETYPE_NONE);
			}
		}
		else if (strcmp(info, "FVBM") == 0)
		{
			PrintToChatAll("Player %N left the game (VAC banned from secure server)", client);
		}
		Command_MISCMenu(client, -1);
	}
	else if (action == MenuAction_Cancel)
	{
		if (selection == MenuCancel_ExitBack) 
		{
			Command_HackMenu(client, -1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

/*******************************************************************************************
	Client connect or disconnect
*******************************************************************************************/
public void OnClientPutInServer(int client)
{
	g_bHopping[client] = false;
	g_bDuckJump[client] = false;
	g_bChatSpammer[client] = false;
	g_bVoiceSpammer[client] = false;
	g_bAutoReflecting[client] = false;
	g_bThirdperson[client] = false;
	g_bPlayers[client] = false;
	g_bLaser[client] = false;
	g_bAutoAiming[client] = false;
	g_bAirstuckMode[client] = false;
	g_bPlayerInfo[client] = false;
	g_bAimFoV[client] = false;
	g_bAutoShoot[client] = false;
	g_bAutoZoom[client] = false;
	g_bMeleeAimbot[client] = false;
	g_iPlayerDesiredFOV[client] = 90;
	if (!IsFakeClient(client))
		QueryClientConVar(client, "fov_desired", OnClientGetDesiredFOV);
}

public void OnClientDisconnect(int client)
{
	g_bHopping[client] = false;
	g_bDuckJump[client] = false;
	g_bChatSpammer[client] = false;
	g_bVoiceSpammer[client] = false;
	g_bAutoReflecting[client] = false;
	g_bThirdperson[client] = false;
	g_bPlayers[client] = false;
	g_bLaser[client] = false;
	g_bAutoAiming[client] = false;
	g_bAirstuckMode[client] = false;
	g_bPlayerInfo[client] = false;
	g_bAimFoV[client] = false;
	g_bAutoShoot[client] = false;
	g_bAutoZoom[client] = false;
	g_bMeleeAimbot[client] = false;
	g_iPlayerDesiredFOV[client] = 90;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) //Hookevent
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	TF2_RemoveCondition(client, TFCond_CritOnWin);
	if(g_bCritHack[client])	
	{	
		//TF2_AddCondition(client, TFCond_CritOnWin, TFCondDuration_Infinite);
		TF2_AddCondition(client, TFCond_HalloweenCritCandy, TFCondDuration_Infinite);
	}
	if(g_bNoHands[client])		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	if(g_bThirdperson[client])	CreateTimer(0.2, Timer_thirdperson, client);	//Tiny Delay for thirdperson when players spawn
	g_bAirstuckMode[client] = false;
}

/*******************************************************************************************
	Main Function
*******************************************************************************************/
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(!IsPlayerAlive(client))
		return Plugin_Continue;
		
	//Bunnyhop
	if(GetEntityFlags(client) & FL_ONGROUND && buttons & IN_JUMP && !(buttons & IN_DUCK) && g_bHopping[client])
	{
		float fVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = 280.0;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	
	//Duck jump
	if(buttons & IN_DUCK && buttons & IN_JUMP && g_bDuckJump[client])
    {
        int GroundEntity = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
        if(GroundEntity != -1)
        {
      		float PlayerVelocity[3];
       		GetEntPropVector(client, Prop_Data, "m_vecVelocity", PlayerVelocity);
       		PlayerVelocity[2] = 280.0;
        	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, PlayerVelocity);
        } 
    }
    
	//Autoreflect 
	if(g_bAutoReflecting[client] && TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		float vEntityOrigin[3], vClientEyes[3], vCamAngle[3];
		if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == GetPlayerWeaponSlot(client, TFWeaponSlot_Primary))
		{
			int iEntity = -1;
			while((iEntity = FindEntityByClassname(iEntity, "tf_projectile_*")) != -1 && GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1) != GetClientTeam(client) && CanBeDeflected(iEntity))
			{
				GetClientEyePosition(client, vClientEyes);
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vEntityOrigin);

				GetVectorAnglesTwoPoints(vClientEyes, vEntityOrigin, vCamAngle);
				AnglesNormalize(vCamAngle);
				
				if(GetVectorDistance(vClientEyes, vEntityOrigin) < 165.0)
				{
					TeleportEntity(client, NULL_VECTOR, vCamAngle, NULL_VECTOR);
					CopyVector(vCamAngle, angles);
					buttons |= IN_ATTACK2;
				}
			}
		}
	}
	
	//NoScope (Remove the fisheyes of sniper scoping)
	if(g_bNoScope[client])
	{
		if(TF2_GetPlayerClass(client) == TFClass_Sniper && TF2_IsPlayerInCondition(client, TFCond_Zoomed)) //Detect class = sniper and the zoomed
		{
		 	SetEntProp(client, Prop_Send, "m_iHideHUD", 5);
		}
		else 	
		{
			SetEntProp(client, Prop_Send, "m_iHideHUD", 0);
		}
	}
	
	//NoZoom
	if(g_bNoZoom[client])
	{
		if (TF2_GetPlayerClass(client) == TFClass_Sniper && buttons & IN_ATTACK2)
		{
			buttons &= ~IN_ATTACK2;
		}
	}
	
	//Wallhack
	if(g_bPlayers[client])
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && i != client && IsPlayerAlive(i))
			{
				float TE_ClientEye[3], TE_iEye[3], m_fImpact[3];
				int iSprite;
				if(GetClientTeam(i) == 2)
					iSprite = g_iRedSprite;
				else if(GetClientTeam(i) == 3)
					iSprite = g_iBlueSprite;
					
				GetClientEyePosition(client, TE_ClientEye);
				GetClientEyePosition(i, TE_iEye);
				
				if(g_bEnemyOnly[client])
				{
					if(GetClientTeam(client) != GetClientTeam(i))
					{
						for (int j = 0; j < 4; j++)
						{
							TE_iEye[2] -= float(j*10);
							GetClientSightEnd(TE_ClientEye, TE_iEye, m_fImpact);
							TE_SetupGlowSprite(m_fImpact, iSprite, 0.1, 0.3, 40);
							TE_SendToClient(client, 0.0);
						}
					}
				}
				else
				{
					for (int j = 0; j < 4; j++)
					{
						TE_iEye[2] -= float(j*10);
						GetClientSightEnd(TE_ClientEye, TE_iEye, m_fImpact);
						TE_SetupGlowSprite(m_fImpact, iSprite, 0.1, 0.3, 40);
						TE_SendToClient(client, 0.0);
					}
				}
			}//TE_SetupGlowSprite(m_fImpact, iSprite, 0.1, (GetVectorDistance(TE_ClientEye, m_fImpact)/(GetVectorDistance(TE_ClientEye, TE_iEye)*2.0)), 150);
		}
	}
	if(g_bLaser[client]) //Laser hack
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && i != client && IsPlayerAlive(i))
			{
				float TE_ClientEye[3], TE_iEye[3];	
				GetClientEyePosition(client, TE_ClientEye);
				GetClientEyePosition(i, TE_iEye);
				TE_ClientEye[2] -= 5.0;
				TE_iEye[2] -= 15.0;
				if(g_bEnemyOnly[client])
				{
					if(GetClientTeam(client) != GetClientTeam(i))
					{
						TE_SetupBeamPoints(TE_ClientEye, TE_iEye, g_iBeamSprite, 0, 0, 0, 0.1, 0.25, 0.25, 1, 0.0, g_iColors[GetClientTeam(i)-2], 0);
						TE_SendToClient(client, 0.0);
					}
				}
				else	
				{
					TE_SetupBeamPoints(TE_ClientEye, TE_iEye, g_iBeamSprite, 0, 0, 0, 0.1, 0.25, 0.25, 1, 0.0, g_iColors[GetClientTeam(i)-2], 0);
					TE_SendToClient(client, 0.0);
				}
			}
		}
	}
	
	//Aimbot
	if(g_bAutoAiming[client])
	{
		int i = GetClosestClient(client);
		if(IsValidClient(i))
		{
			float clientEye[3], iEye[3], clientAngle[3];	
			GetClientEyePosition(client, clientEye);
			GetClientEyePosition(i, iEye);
			GetVectorAnglesTwoPoints(clientEye, iEye, clientAngle);
			AnglesNormalize(clientAngle);
			TeleportEntity(client, NULL_VECTOR, clientAngle, NULL_VECTOR);
		}
	}
	
	//AutoShoot
	if(g_bAutoShoot[client])
	{
		int iTarget = GetClientAimTarget(client, true);
		if(IsValidClient(iTarget) && CanSeeTarget(client, iTarget, GetClientTeam(client), g_bAimFoV[client]) && GetClientTeam(client) != GetClientTeam(iTarget))
		{
			float vClientEyes[3], viTargetEyes[3];
			GetClientEyePosition(client, vClientEyes);
			GetClientEyePosition(iTarget, viTargetEyes);

			if(GetPlayerWeaponSlot(client, 0) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			{
				if(TF2_GetPlayerClass(client) == TFClass_Pyro && GetVectorDistance(vClientEyes, viTargetEyes) <= 250.0)
				{	
					buttons |= IN_ATTACK;
				}
				if(TF2_GetPlayerClass(client) == TFClass_Pyro && GetVectorDistance(vClientEyes, viTargetEyes) >= 250.0)
				{	
					 vel[0] = 300.0; //move forward
				}
				else if(TF2_GetPlayerClass(client) == TFClass_Sniper && g_bAutoZoom[client])
				{	
					if(!TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						buttons |= IN_ATTACK2;
					if(TF2_IsPlayerInCondition(client, TFCond_Zoomed))
						buttons |= IN_ATTACK;
				}
				else
				{
					buttons |= IN_ATTACK;
				}
			}
			else if(GetPlayerWeaponSlot(client, 1) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			{
				buttons |= IN_ATTACK;
			}
			else if(GetVectorDistance(vClientEyes, viTargetEyes) < 125 && GetPlayerWeaponSlot(client, 2) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
			{
				buttons |= IN_ATTACK;
			}
		}
	}
	
	//Melee Aimbot
	if(g_bMeleeAimbot[client])
	{
		if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") != GetPlayerWeaponSlot(client, 2))
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", GetPlayerWeaponSlot(client, 2));
		}
		
		if(g_bAutoAiming[client])
		{
			int i = GetClientAimTarget(client);
			if(IsValidClient(i))
			{
				float clientEye[3], iEye[3];
				GetClientEyePosition(client, clientEye);
				GetClientEyePosition(i, iEye);
				if(GetVectorDistance(clientEye, iEye) <= 80.0)
					buttons |= IN_ATTACK;
				if(GetVectorDistance(clientEye, iEye) >= 80.0)
					 vel[0] = 300.0; //move forward
			}
		}
		else if(!g_bAutoAiming[client])
		{
			int i = GetClosestClient(client);
			if(IsValidClient(i))
			{
				float clientEye[3], iEye[3], clientAngle[3];	
				GetClientEyePosition(client, clientEye);
				GetClientEyePosition(i, iEye);
				GetVectorAnglesTwoPoints(clientEye, iEye, clientAngle);
				AnglesNormalize(clientAngle);
				TeleportEntity(client, NULL_VECTOR, clientAngle, NULL_VECTOR);
				if(GetVectorDistance(clientEye, iEye) <= 80.0)
					buttons |= IN_ATTACK;
				if(GetVectorDistance(clientEye, iEye) >= 80.0)
					 vel[0] = 300.0; //move forward
			}
		}
	}
	
	return Plugin_Changed;
}     

/*******************************************************************************************
	Timer Function
*******************************************************************************************/
//Thirdspam
public Action Timer_thirdperson(Handle timer, int client)
{
	if(g_bThirdperson[client])		
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

//Voicespam
public Action Timer_VoiceSpam(Handle timer, int client)
{
    if(g_bVoiceSpammer[client])
    {
		switch(GetRandomInt(1,2))
		{
			case 1:
       		{
      			FakeClientCommand(client, "voicemenu 1 4"); 
       		}
      	  	case 2:
        	{
      			FakeClientCommand(client, "voicemenu 2 5"); 
        	}
		}
		if(g_bVoiceSpammer[client])		CreateTimer(3.0, Timer_VoiceSpam, client);
	}
}

//Chatspam
public Action Timer_ChatSpam(Handle timer, int client)
{
    if(g_bChatSpammer[client])
    {
		switch(GetRandomInt(1,2))
		{
			case 1:
     	  	{
      			//FakeClientCommand(client, "say WWW.LMAOBOX.NET - BEST FREE TF2 HACK!"); 
      			FakeClientCommand(client, "say forums.alliedmods.net - BEST FREE TF2 PLUGINS!");
       		}
      	  	case 2:
        	{
      			//FakeClientCommand(client, "say GET GOOD, GET LMAOBoX!");
				FakeClientCommand(client, "say GET PLUGINS, GET SOURCEMOD!");       				
        	}
		}
		if(g_bChatSpammer[client])	CreateTimer(4.0, Timer_ChatSpam, client);
	}
}

//Aimname
public Action Timer_PlayerInfo(Handle timer, int client)
{
	if(g_bPlayerInfo[client])
	{
		int iTarget = GetClientAimTarget(client, true);
		if(IsValidClient(iTarget) && IsClientInGame(iTarget))
		{	
			char cTarget_Team[8];
			if(GetClientTeam(iTarget) == 2)	
				cTarget_Team = "RED";
			if(GetClientTeam(iTarget) == 3)
				cTarget_Team = "BlUE";
				
			char cTarget_Weapon[64];
			GetClientWeapon(iTarget, cTarget_Weapon, sizeof(cTarget_Weapon));

			char iTarget_Class[32];
			if (TF2_GetPlayerClass(iTarget) == TFClass_Scout)			
				iTarget_Class = "Scout";
			else if (TF2_GetPlayerClass(iTarget) == TFClass_Soldier)		
				iTarget_Class = "Soldier";
			else if (TF2_GetPlayerClass(iTarget) == TFClass_Pyro)		
				iTarget_Class = "Pyro";
			else if (TF2_GetPlayerClass(iTarget) == TFClass_DemoMan)		
				iTarget_Class = "DemoMan";
			else if (TF2_GetPlayerClass(iTarget) == TFClass_Heavy)		
				iTarget_Class = "Heavy";
			else if (TF2_GetPlayerClass(iTarget) == TFClass_Engineer)		
				iTarget_Class = "Engineer";
			else if (TF2_GetPlayerClass(iTarget) == TFClass_Medic)		
				iTarget_Class = "Medic";
			else if (TF2_GetPlayerClass(iTarget) == TFClass_Sniper)		
				iTarget_Class = "Sniper";
			else if (TF2_GetPlayerClass(iTarget) == TFClass_Spy)		
				iTarget_Class = "Spy";
				
			float fClientEyePosition[3];
			GetClientEyePosition(client, fClientEyePosition);
			float fiTargetEyePosition[3];
			GetClientEyePosition(iTarget, fiTargetEyePosition);
			
			if(g_bEnemyOnly[client])
			{
				if(GetClientTeam(client) != GetClientTeam(iTarget))
				{		
					SetHudTextParams(-1.0, 0.59, 0.2, g_iColors[GetClientTeam(iTarget)-2][0], g_iColors[GetClientTeam(iTarget)-2][1], g_iColors[GetClientTeam(iTarget)-2][2], 255, 1, 6.0, 0.0, 0.5);
					ShowSyncHudText(client, g_hHud, "Playername: %N\n Team: %s(%s)  Health : %i\n SteamID: %i\n Weapon: %s\n Distance : %.2f",
					iTarget, cTarget_Team, iTarget_Class, GetClientHealth(iTarget), GetSteamAccountID(iTarget), cTarget_Weapon, GetVectorDistance(fClientEyePosition, fiTargetEyePosition));
				}
			}
			else
			{	
				SetHudTextParams(-1.0, 0.59, 0.2, g_iColors[GetClientTeam(iTarget)-2][0], g_iColors[GetClientTeam(iTarget)-2][1], g_iColors[GetClientTeam(iTarget)-2][2], 255, 1, 6.0, 0.0, 0.5);
				ShowSyncHudText(client, g_hHud, "Playername: %N\n Team: %s(%s)  Health : %i\n SteamID: %i\n Weapon: %s\n Distance : %.2f",
				iTarget, cTarget_Team, iTarget_Class, GetClientHealth(iTarget), GetSteamAccountID(iTarget), cTarget_Weapon, GetVectorDistance(fClientEyePosition, fiTargetEyePosition));
			}
		}
		if(g_bPlayerInfo[client])	CreateTimer(0.1, Timer_PlayerInfo, client);
	}
}

/*******************************************************************************************
	Stock
*******************************************************************************************/
bool CanBeDeflected(int iEntity)
{
	if(IsValidEntity(iEntity))
	{
		char sBuffer[32];
		GetEntityClassname(iEntity, sBuffer, sizeof(sBuffer));
		if(StrEqual(sBuffer, "tf_projectile_arrow", false) 
		|| StrEqual(sBuffer, "tf_projectile_ornament", false) 
		|| StrEqual(sBuffer, "tf_projectile_cleaver", false) 
		|| StrEqual(sBuffer, "tf_projectile_energy_ball", false)
		|| StrEqual(sBuffer, "tf_projectile_flare", false)
		|| StrEqual(sBuffer, "tf_projectile_jar", false)
		|| StrEqual(sBuffer, "tf_projectile_jar_milk", false)
		|| StrEqual(sBuffer, "tf_projectile_pipe", false)
		|| StrEqual(sBuffer, "tf_projectile_pipe_remote", false)
		|| StrEqual(sBuffer, "tf_projectile_rocket", false)
		|| StrEqual(sBuffer, "tf_projectile_sentryrocket", false)
		|| StrEqual(sBuffer, "tf_projectile_stun_ball", false))
			return true;
	}
	return false;
}

public void CopyVector(float vIn[3], float vOut[3])
{
	vOut[0] = vIn[0];
	vOut[1] = vIn[1];
	vOut[2] = vIn[2];
}

public void OnClientGetDesiredFOV(QueryCookie cookie, int iClient, ConVarQueryResult result, const char[]cvarName, const char[]cvarValue)
{
	if (!IsValidClient(iClient)) return;
	
	g_iPlayerDesiredFOV[iClient] = StringToInt(cvarValue);
}

stock int ModRateOfFire(int client, int iWeapon)
{
	float m_flNextPrimaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack");
	float m_flNextSecondaryAttack = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack");
	SetEntPropFloat(iWeapon, Prop_Send, "m_flPlaybackRate", 10.0);

	float fGameTime = GetGameTime();
	float fPrimaryTime = ((m_flNextPrimaryAttack - fGameTime) - 0.99);
	float fSecondaryTime = ((m_flNextSecondaryAttack - fGameTime) - 0.99);

	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack", fPrimaryTime + fGameTime);
	SetEntPropFloat(iWeapon, Prop_Send, "m_flNextSecondaryAttack", fSecondaryTime + fGameTime);
}

stock bool IsValidClient(int client) 
{ 
    if(client <= 0 ) return false; 
    if(client > MaxClients) return false; 
    if(!IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
}

void GetClientSightEnd(float TE_ClientEye[3], float TE_iEye[3], float out[3])
{
	TR_TraceRayFilter(TE_ClientEye, TE_iEye, MASK_SOLID, RayType_EndPoint, TraceRayDontHitPlayers);
	if (TR_DidHit())
		TR_GetEndPosition(out);
}

public bool TraceRayDontHitPlayers(int entity, int mask, any data)
{
	if (0 < entity <= MaxClients)
		return false;

	return true;
}

stock int GetClosestClient(int client)
{
	float vPos1[3], vPos2[3];
	GetClientEyePosition(client, vPos1);

	int iTeam = GetClientTeam(client);
	int iClosestEntity = -1;
	float flClosestDistance = -1.0;
	float flEntityDistance;

	for(int i = 1; i <= MaxClients; i++) if(IsValidClient(i))
	{
		if(GetClientTeam(i) != iTeam && IsPlayerAlive(i) && i != client)
		{
			GetClientEyePosition(i, vPos2);
			flEntityDistance = GetVectorDistance(vPos1, vPos2);
			if((flEntityDistance < flClosestDistance) || flClosestDistance == -1.0)
			{
				if(CanSeeTarget(client, i, iTeam, g_bAimFoV[client]))
				{
					flClosestDistance = flEntityDistance;
					iClosestEntity = i;
				}
			}
		}
	}
	return iClosestEntity;
}

stock float GetVectorAnglesTwoPoints(const float vStartPos[3], const float vEndPos[3], float vAngles[3])
{
	static float tmpVec[3];
	tmpVec[0] = vEndPos[0] - vStartPos[0];
	tmpVec[1] = vEndPos[1] - vStartPos[1];
	tmpVec[2] = vEndPos[2] - vStartPos[2];
	GetVectorAngles(tmpVec, vAngles);
}

public void AnglesNormalize(float vAngles[3])
{
	while(vAngles[0] >  89.0) vAngles[0]-=360.0;
	while(vAngles[0] < -89.0) vAngles[0]+=360.0;
	while(vAngles[1] > 180.0) vAngles[1]-=360.0;
	while(vAngles[1] <-180.0) vAngles[1]+=360.0;
}

bool CanSeeTarget(int iClient, int iTarget, int iTeam, bool bCheckFOV)
{
	float flStart[3], flEnd[3];
	GetClientEyePosition(iClient, flStart);
	GetClientEyePosition(iTarget, flEnd);
	
	TR_TraceRayFilter(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, iTarget);
	if(TR_GetEntityIndex() == iTarget)
	{
		if(TF2_GetPlayerClass(iTarget) == TFClass_Spy)
		{
			if(TF2_IsPlayerInCondition(iTarget, TFCond_Cloaked) || TF2_IsPlayerInCondition(iTarget, TFCond_Disguised))
			{
				if(TF2_IsPlayerInCondition(iTarget, TFCond_CloakFlicker)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_OnFire)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Jarated)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Milked)
				|| TF2_IsPlayerInCondition(iTarget, TFCond_Bleeding))
				{
					return true;
				}

				return false;
			}
			if(TF2_IsPlayerInCondition(iTarget, TFCond_Disguised) && GetEntProp(iTarget, Prop_Send, "m_nDisguiseTeam") == iTeam)
			{
				return false;
			}

			return true;
		}
		
		if(TF2_IsPlayerInCondition(iTarget, TFCond_Ubercharged)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedHidden)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedCanteen)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_UberchargedOnTakeDamage)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_PreventDeath)
		|| TF2_IsPlayerInCondition(iTarget, TFCond_Bonked))
		{
			return false;
		}
		if(bCheckFOV)
		{
			float eyeAng[3], reqVisibleAng[3];
			float flFOV = float(g_iPlayerDesiredFOV[iClient]);
			
			GetClientEyeAngles(iClient, eyeAng);
			
			SubtractVectors(flEnd, flStart, reqVisibleAng);
			GetVectorAngles(reqVisibleAng, reqVisibleAng);
			
			float flDiff = FloatAbs(reqVisibleAng[0] - eyeAng[0]) + FloatAbs(reqVisibleAng[1] - eyeAng[1]);
			if (flDiff > ((flFOV * 0.5) + 10.0)) 
				return false;
		}

		return true;
	}
	return false;
}

public bool TraceRayFilterClients(int iEntity, int iMask, any hData)
{
	if(iEntity > 0 && iEntity <=MaxClients)
	{
		if(iEntity == hData)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	return true;
}