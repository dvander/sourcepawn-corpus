/**********Thanks To**************
* {7~11} TROLL for the original plugin
* CrimsonGt - helped {7~11} TROLL with give player item issues
*********************************/
#pragma tabsize 0
#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.2.1"

new Handle:g_max_give[13];
new max_give[13]; //array for storing initial quota of each item
new give_quota0[MAXPLAYERS+1]; //quota left (each player) for item 1
new give_quota1[MAXPLAYERS+1]; //quota left (each player) for item 2
new give_quota2[MAXPLAYERS+1]; //quota left (each player) for item 3
new give_quota3[MAXPLAYERS+1]; //quota left (each player) for item 4
new give_quota4[MAXPLAYERS+1]; //quota left (each player) for item 5
new give_quota5[MAXPLAYERS+1]; //quota left (each player) for item 6
new give_quota6[MAXPLAYERS+1]; //quota left (each player) for item 7
new give_quota7[MAXPLAYERS+1]; //quota left (each player) for item 8
new give_quota8[MAXPLAYERS+1]; //quota left (each player) for item 9
new give_quota9[MAXPLAYERS+1]; //quota left (each player) for item 10
new give_quota10[MAXPLAYERS+1]; //quota left (each player) for item 11
new give_quota11[MAXPLAYERS+1]; //quota left (each player) for item 12
new give_quota12[MAXPLAYERS+1]; //quota left (each player) for item 13

public Plugin:myinfo = 
{
	name = "[L4D2] Secondary Weapons Menu",
	author = "Teddy Revisted",
	description = "Allows Clients To Get Melee Weapons",
	version = PLUGIN_VERSION,
	url = "www.blacktusklabs.com"
}
public OnPluginStart()
{
	//tank buster weapons menu cvar
	RegConsoleCmd("melee", TankBusterMenu);
	RegConsoleCmd("weapons", TankBusterMenu);
	RegConsoleCmd("weapon", TankBusterMenu);
	RegConsoleCmd("katana", TankBusterMenu);
	RegConsoleCmd("crowbar", TankBusterMenu);
	RegConsoleCmd("knife", TankBusterMenu);
	RegConsoleCmd("baseball", TankBusterMenu);
	RegConsoleCmd("baseballbat", TankBusterMenu);
	RegConsoleCmd("cricket", TankBusterMenu);
	RegConsoleCmd("cricketbat", TankBusterMenu);
	RegConsoleCmd("sword", TankBusterMenu);
	RegConsoleCmd("stab", TankBusterMenu);
	RegConsoleCmd("stabby", TankBusterMenu);
	RegConsoleCmd("bash", TankBusterMenu);
	RegConsoleCmd("fireaxe", TankBusterMenu);
	RegConsoleCmd("axe", TankBusterMenu);
	RegConsoleCmd("tonfa", TankBusterMenu);
	RegConsoleCmd("machete", TankBusterMenu);
	RegConsoleCmd("club", TankBusterMenu);
	RegConsoleCmd("golf", TankBusterMenu);
	RegConsoleCmd("golfclub", TankBusterMenu);
	RegConsoleCmd("pistol", TankBusterMenu);
	RegConsoleCmd("pistols", TankBusterMenu);
	RegConsoleCmd("magnum", TankBusterMenu);
	RegConsoleCmd("mag", TankBusterMenu);
	RegConsoleCmd("deserteagle", TankBusterMenu);
	RegConsoleCmd("eagle", TankBusterMenu);
	RegConsoleCmd("electricguitar", TankBusterMenu);
	RegConsoleCmd("electric", TankBusterMenu);
	RegConsoleCmd("guitar", TankBusterMenu);
	RegConsoleCmd("bat", TankBusterMenu);
	//plugin version
	CreateConVar("tank_buster2_version", PLUGIN_VERSION, "Tank_Buster_Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//Quota cvars for each player
	g_max_give[0] = CreateConVar("sm_quota_pistol_magnum", "-1", " Quota Given to each player for obtaining pistol_magnum in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[1] = CreateConVar("sm_quota_pistol", "-1", " Quota Given to each player for obtaining pistol in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[2] = CreateConVar("sm_quota_knifeknife", "-1", " Quota Given to each player for obtaining knife in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[3] = CreateConVar("sm_quota_machete", "-1", " Quota Given to each player for obtaining machete in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[4] = CreateConVar("sm_quota_tonfa", "-1", " Quota Given to each player for obtaining tonfa in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[5] = CreateConVar("sm_quota_katana", "-1", " Quota Given to each player for obtaining katana in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[6] = CreateConVar("sm_quota_golfclub", "-1", " Quota Given to each player for obtaining golfclub in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[7] = CreateConVar("sm_quota_baseball_bat", "-1", " Quota Given to each player for obtaining baseball_bat in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[8] = CreateConVar("sm_quota_fireaxe", "-1", " Quota Given to each player for obtaining fireaxe in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[9] = CreateConVar("sm_quota_electric_guitar", "-1", " Quota Given to each player for obtaining electric_guitar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[10] = CreateConVar("sm_quota_cricket_bat", "-1", " Quota Given to each player for obtaining cricket_bat in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[11] = CreateConVar("sm_quota_crowbar", "-1" ," Quota Given to each player for obtaining crowbar in each round ( -1 = unlimited 0 = disabled )");
	g_max_give[12] = CreateConVar("sm_quota_frying_pan", "-1", " Quota Given to each player for obtaining frying_pan in each round ( -1 = unlimited 0 = disabled )");
		//Execute or create cfg
	AutoExecConfig(true, "L4DWeaponsMenu_restricted");	
	
}

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	//Get max clients on server
	new maxclients = GetMaxClients();
	
	//Get inital quotas from cvars
	max_give[0] = GetConVarInt(g_max_give[0]);
	max_give[1] = GetConVarInt(g_max_give[1]);
	max_give[2] = GetConVarInt(g_max_give[2]);
	max_give[3] = GetConVarInt(g_max_give[3]);
	max_give[4] = GetConVarInt(g_max_give[4]);
	max_give[5] = GetConVarInt(g_max_give[5]);
	max_give[6] = GetConVarInt(g_max_give[6]);
	max_give[7] = GetConVarInt(g_max_give[7]);
	max_give[8] = GetConVarInt(g_max_give[8]);
	max_give[9] = GetConVarInt(g_max_give[9]);
	max_give[10] = GetConVarInt(g_max_give[10]);
	max_give[11] = GetConVarInt(g_max_give[11]);
	max_give[12] = GetConVarInt(g_max_give[12]);	
	
	//Sets inital quotas for every player
	for (new client = 1; client <= maxclients; client++)
	{
		give_quota0[client] = max_give[0];
		give_quota1[client] = max_give[1];
		give_quota2[client] = max_give[2];
		give_quota3[client] = max_give[3];
		give_quota4[client] = max_give[4];
		give_quota5[client] = max_give[5];
		give_quota6[client] = max_give[6];
		give_quota7[client] = max_give[7];
		give_quota8[client] = max_give[8];
		give_quota9[client] = max_give[9];
		give_quota10[client] = max_give[10];
		give_quota11[client] = max_give[11];
		give_quota12[client] = max_give[12];
	}
}

public OnClientPutInServer(client)
{
	//Get inital quotas from cvars
	max_give[0] = GetConVarInt(g_max_give[0]);
	max_give[1] = GetConVarInt(g_max_give[1]);
	max_give[2] = GetConVarInt(g_max_give[2]);
	max_give[3] = GetConVarInt(g_max_give[3]);
	max_give[4] = GetConVarInt(g_max_give[4]);
	max_give[5] = GetConVarInt(g_max_give[5]);
	max_give[6] = GetConVarInt(g_max_give[6]);
	max_give[7] = GetConVarInt(g_max_give[7]);
	max_give[8] = GetConVarInt(g_max_give[8]);
	max_give[9] = GetConVarInt(g_max_give[9]);
	max_give[10] = GetConVarInt(g_max_give[10]);
    max_give[11] = GetConVarInt(g_max_give[11]);	
	max_give[12] = GetConVarInt(g_max_give[12]);
	
	
	//Sets inital quotas for the player just joined   
	give_quota0[client] = max_give[0];
	give_quota1[client] = max_give[1];
	give_quota2[client] = max_give[2];
	give_quota3[client] = max_give[3];
	give_quota4[client] = max_give[4];
	give_quota5[client] = max_give[5];
	give_quota6[client] = max_give[6];
	give_quota7[client] = max_give[7];
	give_quota8[client] = max_give[8];
	give_quota9[client] = max_give[9];
	give_quota10[client] = max_give[10];
	give_quota11[client] = max_give[11];
	give_quota12[client] = max_give[12];
		
}

public Action:TankBusterMenu(client,args)
{
	TankBuster(client);
	return Plugin_Handled;
}

public Action:TankBuster(clientId)
{
	new Handle:menu = CreateMenu(TankBusterMenuHandler);
	SetMenuTitle(menu, "Secondary Weapons Menu");
	AddMenuItem(menu, "option0", "Magnum");
	AddMenuItem(menu, "option1", "Pistol");
	AddMenuItem(menu, "option2", "Knife");
	AddMenuItem(menu, "option3", "Machete");
	AddMenuItem(menu, "option4", "Tonfa");
	AddMenuItem(menu, "option5", "Katana");
	AddMenuItem(menu, "option6", "Golf Club");
	AddMenuItem(menu, "option7", "Baseball Bat");
	AddMenuItem(menu, "option8", "Fire Axe");
	AddMenuItem(menu, "option9", "Guitar");
	AddMenuItem(menu, "option10", "Cricket Bat");
	AddMenuItem(menu, "option11", "Crowbar");
	AddMenuItem(menu, "option12", "Frying Pan");
SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);
	//return Plugin_Handled;
}

public TankBusterMenuHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	//Strip the CHEAT flag off of the "give" command
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	
	if ( action == MenuAction_Select ) {  
		switch (itemNum)
		{
			
			
		    case 0: // Magnum
			{
				if ( give_quota0[client] > 0 || give_quota0[client] < 0) {
					//Give the player a pistol_magnum
					FakeClientCommand(client, "give pistol_magnum");
					//Decrease remaining quota of that player by 1
					give_quota0[client]--;
					//Notify remaining quota
					if (give_quota0[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a pistol_magnum until next round",give_quota0[client]);
					}
					else if (give_quota0[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pistol_magnum until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a pistol_magnum");
				}
			}
			case 1: // Pistols
			{
				if ( give_quota1[client] > 0 || give_quota1[client] < 0) {
					//Give the player a pistol
					FakeClientCommand(client, "give pistol");
					//Decrease remaining quota of that player by 1
					give_quota1[client]--;
					//Notify remaining quota
					if (give_quota1[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a pistol until next round",give_quota1[client]);
					}
					else if (give_quota1[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore pistol until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a pistol");
				}
			}
			case 2: // Knife
			{
				if ( give_quota2[client] > 0 || give_quota2[client] < 0) {
					//Give the player a Knife
					FakeClientCommand(client, "give knife");
					//Decrease remaining quota of that player by 1
					give_quota2[client]--;
					//Notify remaining quota
					if (give_quota2[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Knife until next round",give_quota2[client]);
					}
					else if (give_quota2[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Knife until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Knife");
				}
			}
			case 3: // Machete
			{
				if ( give_quota3[client] > 0 || give_quota3[client] < 0) {
					//Give the player a Machete
					FakeClientCommand(client, "give machete");
					//Decrease remaining quota of that player by 1
					give_quota3[client]--;
					//Notify remaining quota
					if (give_quota3[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Machete until next round",give_quota3[client]);
					}
					else if (give_quota3[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Machete until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Machete");
				}
			}
			case 4: // Tonfa
			{
				if ( give_quota4[client] > 0 || give_quota4[client] < 0) {
					//Give the player a Tonfa
					FakeClientCommand(client, "give tonfa");
					//Decrease remaining quota of that player by 1
					give_quota4[client]--;
					//Notify remaining quota
					if (give_quota4[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Tonfa until next round",give_quota4[client]);
					}
					else if (give_quota4[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Tonfa until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Tonfa");
				}
			}	
			case 5: // Katana
			{
				if ( give_quota5[client] > 0 || give_quota5[client] < 0) {
					//Give the player a Katana
					FakeClientCommand(client, "give katana");
					//Decrease remaining quota of that player by 1
					give_quota5[client]--;
					//Notify remaining quota
					if (give_quota5[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Katana until next round",give_quota5[client]);
					}
					else if (give_quota5[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Katana until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Katana");
				}
			}
			case 6: // Golf Club
			{
				if ( give_quota6[client] > 0 || give_quota6[client] < 0) {
					//Give the player a Golf Club
					FakeClientCommand(client, "give golfclub");
					//Decrease remaining quota of that player by 1
					give_quota6[client]--;
					//Notify remaining quota
					if (give_quota6[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Golf Club until next round",give_quota6[client]);
					}
					else if (give_quota6[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Golf Club until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Golf Club");
				}
			}
			case 7: // Baseball Bat
			{
				if ( give_quota7[client] > 0 || give_quota7[client] < 0) {
					//Give the player a Baseball Bat
					FakeClientCommand(client, "give baseball_bat");
					//Decrease remaining quota of that player by 1
					give_quota7[client]--;
					//Notify remaining quota
					if (give_quota7[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Baseball Bat until next round",give_quota7[client]);
					}
					else if (give_quota7[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Baseball Bat until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Baseball Bat");
				}
			}		
			case 8: // Fire Axe
			{
				if ( give_quota8[client] > 0 || give_quota8[client] < 0) {
					//Give the player a Fireaxe
					FakeClientCommand(client, "give fireaxe");
					//Decrease remaining quota of that player by 1
					give_quota8[client]--;
					//Notify remaining quota
					if (give_quota8[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Fireaxe until next round",give_quota8[client]);
					}
					else if (give_quota8[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Fireaxe until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Fireaxe");
				}
			}
			case 9: // Electric Guitar
			{
				if ( give_quota9[client] > 0 || give_quota9[client] < 0) {
					//Give the player a Electric Guitar
					FakeClientCommand(client, "give electric_guitar");
					//Decrease remaining quota of that player by 1
					give_quota9[client]--;
					//Notify remaining quota
					if (give_quota9[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain an Electric Guitar until next round",give_quota9[client]);
					}
					else if (give_quota9[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Electric Guitar until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain an Electric Guitar");
				}
			}
			case 10: // Cricket Bat
			{
				if ( give_quota10[client] > 0 || give_quota10[client] < 0) {
					//Give the player a Cricket Bat
					FakeClientCommand(client, "give cricket_bat");
					//Decrease remaining quota of that player by 1
					give_quota10[client]--;
					//Notify remaining quota
					if (give_quota10[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Cricket Bat until next round",give_quota10[client]);
					}
					else if (give_quota10[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Cricket Bat until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Cricket Bat");
				}
			}
			case 11: // pistol
			{
				if ( give_quota11[client] > 0 || give_quota11[client] < 0) {
					//Give the player a Crowbar
					FakeClientCommand(client, "give crowbar");
					//Decrease remaining quota of that player by 1
					give_quota11[client]--;
					//Notify remaining quota
					if (give_quota11[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Crowbar until next round",give_quota11[client]);
					}
					else if (give_quota11[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Crowbar until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Crowbar");
				}
			}
			case 12: // pistol_magnum
			{
				if ( give_quota12[client] > 0 || give_quota12[client] < 0) {
					//Give the player a Frying Pan
					FakeClientCommand(client, "give frying_pan");
					//Decrease remaining quota of that player by 1
					give_quota12[client]--;
					//Notify remaining quota
					if (give_quota12[client] > 0) {
						PrintToChat(client, "\x04[SM] \x01You have %d more chance to obtain a Frying Pan until next round",give_quota12[client]);
					}
					else if (give_quota12[client] == 0){
						PrintToChat(client, "\x04[SM] \x01You cannot obtain anymore Frying Pan until next round");
					}
				}
				else {
					//No more quota left
					PrintToChat(client, "\x04[SM] \x01You cannot obtain a Frying Pan");
				}
			}
			
			
		}
	}
	
	//Add the CHEAT flag back to "give" command
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}
