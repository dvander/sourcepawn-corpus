#pragma semicolon 1

#include <sourcemod>  
#include <sdktools>

public Plugin myinfo = 
{
	name = "Voice Switch",
	author = "Claucker",
	description = "Allows to switch between all 8 characters voices",
	version = "0.1",
	url = ""
}

public Action MakeSurvivorBeBill ( int client, int args )  
{
	SetVariantString("who:NamVet:0");
	DispatchKeyValue(client, "targetname", "NamVet");
	AcceptEntityInput(client, "AddContext");
}

public Action MakeSurvivorBeZoey ( int client, int args )  
{
	SetVariantString("who:TeenGirl:0");
	DispatchKeyValue(client, "targetname", "TeenGirl");
	AcceptEntityInput(client, "AddContext");
}

public Action MakeSurvivorBeLouis ( int client, int args )  
{
	SetVariantString("who:Manager:0");
	DispatchKeyValue(client, "targetname", "Manager");
	AcceptEntityInput(client, "AddContext");
}

public Action MakeSurvivorBeFrancis ( int client, int args )  
{
	SetVariantString("who:Biker:0");
	DispatchKeyValue(client, "targetname", "Biker");
	AcceptEntityInput(client, "AddContext");
}

public Action MakeSurvivorBeNick ( int client, int args )  
{
	SetVariantString("who:Gambler:0");
	DispatchKeyValue(client, "targetname", "Gambler");
	AcceptEntityInput(client, "AddContext");
}

public Action MakeSurvivorBeRochelle ( int client, int args )  
{
	SetVariantString("who:Producer:0");
	DispatchKeyValue(client, "targetname", "Producer");
	AcceptEntityInput(client, "AddContext");
}

public Action MakeSurvivorBeCoach ( int client, int args )  
{
	SetVariantString("who:Coach:0");
	DispatchKeyValue(client, "targetname", "Coach");
	AcceptEntityInput(client, "AddContext");
}

public Action MakeSurvivorBeEllis ( int client, int args )  
{
	SetVariantString("who:Mechanic:0");
	DispatchKeyValue(client, "targetname", "Mechanic");
	AcceptEntityInput(client, "AddContext");
}

public void RegisterConsoleCommands ()
{	
	// Change voice commands L4D1
	RegConsoleCmd("sm_bv", MakeSurvivorBeBill, "Set to be Bill's voice");
	RegConsoleCmd("sm_zv", MakeSurvivorBeZoey, "Set to be Zoey's voice");
	RegConsoleCmd("sm_lv", MakeSurvivorBeLouis, "Set to be Louis's voice");
	RegConsoleCmd("sm_fv", MakeSurvivorBeFrancis, "Set to be Francis's voice");
		
	// Change voice commands L4D2
	RegConsoleCmd("sm_nv", MakeSurvivorBeNick, "Set to be Nick's voice");
	RegConsoleCmd("sm_rv", MakeSurvivorBeRochelle, "Set to be Rochelle's voice");
	RegConsoleCmd("sm_cv", MakeSurvivorBeCoach, "Set to be Coach's voice");
	RegConsoleCmd("sm_ev", MakeSurvivorBeEllis, "Set to be Ellis's voice");
}

public OnPluginStart()  
{
	RegisterConsoleCommands();
}