#pragma semicolon 1
#include <sourcemod>

#define ATTACK        1 
#define JUMP         2 
#define DUCK         4 
#define FORWARD        8 
#define BACK        16 
#define USE            32 
#define CANCEL        64 
#define LEFT         128 
#define RIGHT        256 
#define MOVELEFT     512 
#define MOVERIGHT     1024 
#define ATTACK2        2048 
#define RUN            4096 
#define RELOAD        8192 
#define ALT1        16384 
#define ALT2        32768 
#define SCORE        65536 
#define SPEED        131072 
#define WALK        262144 
#define ZOOM        524288 
#define WEAPON1        1048576 
#define WEPAON2        2097152 
#define BULLRUSH     4194304 
#define GRENADE1     8388608 
#define GRENADE2     16777216 
#define ATTACK3        33554432

new const String:Key_Item[][] = 
{
	"ATTACK",
	"JUMP",
	"DUCK",
	"FORWARD",
	"BACK",
	"USE",
	"CANCEL",
	"LEFT",
	"RIGHT",
	"MOVELEFT",
	"MOVERIGHT",
	"ATTACK2",
	"RUN",
	"RELOAD",
	"ALT1",
	"ALT2",
	"SCORE",
	"SPEED",
	"WALK",
	"ZOOM",
	"WEAPON1",
	"WEPAON2",
	"BULLRUSH",
	"GRENADE1",
	"GRENADE2",
	"ATTACK3"
};

new const String:g_command[][] = 
{
	"sm_buy",
	"sm_pm",
	"sm_votes",
	"sm_dm",
	"sm_l"
};

//key on/off
ATTACK_save_key[MAXPLAYERS+1];
JUMP_save_key[MAXPLAYERS+1];
DUCK_save_key[MAXPLAYERS+1];
FORWARD_save_key[MAXPLAYERS+1];
BACK_save_key[MAXPLAYERS+1];
USE_save_key[MAXPLAYERS+1];
CANCEL_save_key[MAXPLAYERS+1];
LEFT_save_key[MAXPLAYERS+1];
RIGHT_save_key[MAXPLAYERS+1];
MOVELEFT_save_key[MAXPLAYERS+1];
MOVERIGHT_save_key[MAXPLAYERS+1];
ATTACK2_save_key[MAXPLAYERS+1];
RUN_save_key[MAXPLAYERS+1];
RELOAD_save_key[MAXPLAYERS+1];
ALT1_save_key[MAXPLAYERS+1];
ALT2_save_key[MAXPLAYERS+1];
SCORE_save_key[MAXPLAYERS+1];
SPEED_save_key[MAXPLAYERS+1];
WALK_save_key[MAXPLAYERS+1];
ZOOM_save_key[MAXPLAYERS+1];
WEAPON1_save_key[MAXPLAYERS+1];
WEPAON2_save_key[MAXPLAYERS+1];
BULLRUSH_save_key[MAXPLAYERS+1];
GRENADE1_save_key[MAXPLAYERS+1];
GRENADE2_save_key[MAXPLAYERS+1];
ATTACK3_save_key[MAXPLAYERS+1];

char ATTACK_command[MAXPLAYERS+1][56];
char JUMP_command[MAXPLAYERS+1][56];
char DUCK_command[MAXPLAYERS+1][56];
char FORWARD_command[MAXPLAYERS+1][56];
char BACK_command[MAXPLAYERS+1][56];
char USE_command[MAXPLAYERS+1][56];
char CANCEL_command[MAXPLAYERS+1][56];
char LEFT_command[MAXPLAYERS+1][56];
char RIGHT_command[MAXPLAYERS+1][56];
char MOVELEFT_command[MAXPLAYERS+1][56];
char MOVERIGHT_command[MAXPLAYERS+1][56];
char ATTACK2_command[MAXPLAYERS+1][56];
char RUN_command[MAXPLAYERS+1][56];
char RELOAD_command[MAXPLAYERS+1][56];
char ALT1_command[MAXPLAYERS+1][56];
char ALT2_command[MAXPLAYERS+1][56];
char SCORE_command[MAXPLAYERS+1][56];
char SPEED_command[MAXPLAYERS+1][56];
char WALK_command[MAXPLAYERS+1][56];
char ZOOM_command[MAXPLAYERS+1][56];
char WEAPON1_command[MAXPLAYERS+1][56];
char WEPAON2_command[MAXPLAYERS+1][56];
char BULLRUSH_command[MAXPLAYERS+1][56];
char GRENADE1_command[MAXPLAYERS+1][56];
char GRENADE2_command[MAXPLAYERS+1][56];
char ATTACK3_command[MAXPLAYERS+1][56];

char g_sMenuSelect[MAXPLAYERS+1][32];

char botton_menu[32];
char command_menu[56];

public Plugin:myinfo = {
	name = "[l4d2]server bind key - 2",
	author = "AK978",
	version = "1.0"
}

public OnPluginStart(){
	RegConsoleCmd("sm_binds_menu", Command_bind_key_menu, "menu");
	
	AutoExecConfig(true, "server_bind_key");
}

public OnClientDisconnect(int Client){					
	ATTACK_save_key[Client] = 0;
	JUMP_save_key[Client] = 0;
	DUCK_save_key[Client] = 0;
	FORWARD_save_key[Client] = 0;
	BACK_save_key[Client] = 0;
	USE_save_key[Client] = 0;
	CANCEL_save_key[Client] = 0;
	LEFT_save_key[Client] = 0;
	RIGHT_save_key[Client] = 0;
	MOVELEFT_save_key[Client] = 0;
	MOVERIGHT_save_key[Client] = 0;
	ATTACK2_save_key[Client] = 0;
	RUN_save_key[Client] = 0;
	RELOAD_save_key[Client] = 0;
	ALT1_save_key[Client] = 0;
	ALT2_save_key[Client] = 0;
	SCORE_save_key[Client] = 0;
	SPEED_save_key[Client] = 0;
	WALK_save_key[Client] = 0;
	ZOOM_save_key[Client] = 0;
	WEAPON1_save_key[Client] = 0;
	WEPAON2_save_key[Client] = 0;
	BULLRUSH_save_key[Client] = 0;
	GRENADE1_save_key[Client] = 0;
	GRENADE2_save_key[Client] = 0;
	ATTACK3_save_key[Client] = 0;
}

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2]){
	if (iButtons & ATTACK && ATTACK_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", ATTACK_command[iClient]);}
	if (iButtons & JUMP && JUMP_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", JUMP_command[iClient]);}
	if (iButtons & DUCK && DUCK_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", DUCK_command[iClient]);}
	if (iButtons & FORWARD && FORWARD_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", FORWARD_command[iClient]);}	
	if (iButtons & BACK && BACK_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", BACK_command[iClient]);}
	if (iButtons & USE && USE_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", USE_command[iClient]);}
	if (iButtons & CANCEL && CANCEL_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", CANCEL_command[iClient]);}
	if (iButtons & LEFT && LEFT_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", LEFT_command[iClient]);}
	if (iButtons & RIGHT && RIGHT_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", RIGHT_command[iClient]);}
	if (iButtons & MOVELEFT && MOVELEFT_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", MOVELEFT_command[iClient]);}
	if (iButtons & MOVERIGHT && MOVERIGHT_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", MOVERIGHT_command[iClient]);}
	if (iButtons & ATTACK2 && ATTACK2_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", ATTACK2_command[iClient]);}
	if (iButtons & RUN && RUN_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", RUN_command[iClient]);}
	if (iButtons & RELOAD && RELOAD_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", RELOAD_command[iClient]);}
	if (iButtons & ALT1 && ALT1_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", ALT1_command[iClient]);}
	if (iButtons & ALT2 && ALT2_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", ALT2_command[iClient]);}
	if (iButtons & SCORE && SCORE_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", SCORE_command[iClient]);}
	if (iButtons & SPEED && SPEED_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", SPEED_command[iClient]);}
	if (iButtons & WALK && WALK_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", WALK_command[iClient]);}
	if (iButtons & ZOOM && ZOOM_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", ZOOM_command[iClient]);}
	if (iButtons & WEAPON1 && WEAPON1_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", WEAPON1_command[iClient]);}
	if (iButtons & WEPAON2 && WEPAON2_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", WEPAON2_command[iClient]);}
	if (iButtons & BULLRUSH && BULLRUSH_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", BULLRUSH_command[iClient]);}
	if (iButtons & GRENADE1 && GRENADE1_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", GRENADE1_command[iClient]);}
	if (iButtons & GRENADE2 && GRENADE2_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", GRENADE2_command[iClient]);}
	if (iButtons & ATTACK3 && ATTACK3_save_key[iClient] == 1){
		FakeClientCommand(iClient, "%s", ATTACK3_command[iClient]);}
}

public Action:Command_bind_key_menu(int client, int args)
	BuildBindMenu(client);

BuildBindMenu(int client){
	new Handle:menu = CreateMenu(MenuHandler_Playmenu);
	
	AddMenuItem(menu, "clear_all", "clear all");
	for(int i = 0; i < sizeof(Key_Item); i++){
		strcopy(botton_menu, sizeof(botton_menu), Key_Item[i]);
		AddMenuItem(menu, botton_menu, botton_menu);
	}
	SetMenuTitle(menu, "Bind List");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_Playmenu(Handle:menu, MenuAction:action, param1, param2){
	switch(action){
	case MenuAction_End:
		CloseHandle(menu);
	case MenuAction_Select:{
			new String:item[56];
			int Client = param1;
			GetMenuItem(menu, param2, item, sizeof(item));		
			if(StrEqual(item, "clear_all", false)){	
				ATTACK_save_key[Client] = 0;
				JUMP_save_key[Client] = 0;
				DUCK_save_key[Client] = 0;
				FORWARD_save_key[Client] = 0;
				BACK_save_key[Client] = 0;
				USE_save_key[Client] = 0;
				CANCEL_save_key[Client] = 0;
				LEFT_save_key[Client] = 0;
				RIGHT_save_key[Client] = 0;
				MOVELEFT_save_key[Client] = 0;
				MOVERIGHT_save_key[Client] = 0;
				ATTACK2_save_key[Client] = 0;
				RUN_save_key[Client] = 0;
				RELOAD_save_key[Client] = 0;
				ALT1_save_key[Client] = 0;
				ALT2_save_key[Client] = 0;
				SCORE_save_key[Client] = 0;
				SPEED_save_key[Client] = 0;
				WALK_save_key[Client] = 0;
				ZOOM_save_key[Client] = 0;
				WEAPON1_save_key[Client] = 0;
				WEPAON2_save_key[Client] = 0;
				BULLRUSH_save_key[Client] = 0;
				GRENADE1_save_key[Client] = 0;
				GRENADE2_save_key[Client] = 0;
				ATTACK3_save_key[Client] = 0;
			}
			else {
				strcopy(g_sMenuSelect[Client], sizeof(g_sMenuSelect[]), item);
				BuildBindSubMenu(Client);}
		}	
	}
}

BuildBindSubMenu(client){
	new Handle:menu = CreateMenu(MenuHandler_TabMenu);
	
	AddMenuItem(menu, "clear", "clear");
	for(int i = 0; i < sizeof(g_command); i++){
		strcopy(command_menu, sizeof(command_menu), g_command[i]);
		AddMenuItem(menu, command_menu, command_menu);
	}	
	SetMenuTitle(menu, g_sMenuSelect[client]);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_TabMenu(Handle:menu, MenuAction:action, param1, param2){
	switch(action){
		case MenuAction_End:
			CloseHandle(menu);
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack)
				BuildBindMenu(param1);
		case MenuAction_Select:{
			new String:item[56];
			int client = param1;		
			GetMenuItem(menu, param2, item, sizeof(item));
			
			if (StrEqual(item, "clear", false)){
				if (StrEqual(g_sMenuSelect[client], "ATTACK")){
					ATTACK_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "JUMP")){
					JUMP_save_key[client] = 0;}	
				else if (StrEqual(g_sMenuSelect[client], "DUCK")){
					DUCK_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "FORWARD")){
					FORWARD_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "BACK")){
					BACK_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "USE")){
					USE_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "CANCEL")){
					CANCEL_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "LEFT")){
					LEFT_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "RIGHT")){
					RIGHT_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "MOVELEFT")){
					MOVELEFT_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "MOVERIGHT")){
					MOVERIGHT_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "ATTACK2")){
					ATTACK2_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "RUN")){
					RUN_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "RELOAD")){
					RELOAD_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "ALT1")){
					ALT1_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "ALT2")){
					ALT2_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "SCORE")){
					SCORE_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "SPEED")){
					SPEED_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "WALK")){
					WALK_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "ZOOM")){
					ZOOM_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "WEAPON1")){
					WEAPON1_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "WEPAON2")){
					WEPAON2_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "BULLRUSH")){
					BULLRUSH_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "GRENADE1")){
					GRENADE1_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "GRENADE2")){
					GRENADE2_save_key[client] = 0;}
				else if (StrEqual(g_sMenuSelect[client], "ATTACK3")){
					ATTACK3_save_key[client] = 0;}}
						
			if (StrEqual(g_sMenuSelect[client], "ATTACK")){
				strcopy(ATTACK_command[client], sizeof(ATTACK_command[]), item);
				ATTACK_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "JUMP")){
				strcopy(JUMP_command[client], sizeof(JUMP_command[]), item);
				JUMP_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "DUCK")){
				strcopy(DUCK_command[client], sizeof(DUCK_command[]), item);
				DUCK_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "FORWARD")){
				strcopy(FORWARD_command[client], sizeof(FORWARD_command[]), item);
				FORWARD_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "BACK")){
				strcopy(BACK_command[client], sizeof(BACK_command[]), item);
				BACK_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "USE")){
				strcopy(USE_command[client], sizeof(USE_command[]), item);
				USE_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "CANCEL")){
				strcopy(CANCEL_command[client], sizeof(CANCEL_command[]), item);
				CANCEL_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "LEFT")){
				strcopy(LEFT_command[client], sizeof(LEFT_command[]), item);
				LEFT_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "RIGHT")){
				strcopy(RIGHT_command[client], sizeof(RIGHT_command[]), item);
				RIGHT_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "MOVELEFT")){
				strcopy(MOVELEFT_command[client], sizeof(MOVELEFT_command[]), item);
				MOVELEFT_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "MOVERIGHT")){
				strcopy(MOVERIGHT_command[client], sizeof(MOVERIGHT_command[]), item);
				MOVERIGHT_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "ATTACK2")){
				strcopy(ATTACK2_command[client], sizeof(ATTACK2_command[]), item);
				ATTACK2_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "RUN")){
				strcopy(RUN_command[client], sizeof(RUN_command[]), item);
				RUN_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "RELOAD")){
				strcopy(RELOAD_command[client], sizeof(RELOAD_command[]), item);
				RELOAD_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "ALT1")){
				strcopy(ALT1_command[client], sizeof(ALT1_command[]), item);
				ALT1_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "ALT2")){
				strcopy(ALT2_command[client], sizeof(ALT2_command[]), item);
				ALT2_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "SCORE")){
				strcopy(SCORE_command[client], sizeof(SCORE_command[]), item);
				SCORE_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "SPEED")){
				strcopy(SPEED_command[client], sizeof(SPEED_command[]), item);
				SPEED_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "WALK")){
				strcopy(WALK_command[client], sizeof(WALK_command[]), item);
				WALK_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "ZOOM")){
				strcopy(ZOOM_command[client], sizeof(ZOOM_command[]), item);
				ZOOM_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "WEAPON1")){
				strcopy(WEAPON1_command[client], sizeof(WEAPON1_command[]), item);
				WEAPON1_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "WEPAON2")){
				strcopy(WEPAON2_command[client], sizeof(WEPAON2_command[]), item);
				WEPAON2_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "BULLRUSH")){
				strcopy(BULLRUSH_command[client], sizeof(BULLRUSH_command[]), item);
				BULLRUSH_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "GRENADE1")){
				strcopy(GRENADE1_command[client], sizeof(GRENADE1_command[]), item);
				GRENADE1_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "GRENADE2")){
				strcopy(GRENADE2_command[client], sizeof(GRENADE2_command[]), item);
				GRENADE2_save_key[client] = 1;}
			else if (StrEqual(g_sMenuSelect[client], "ATTACK3")){
				strcopy(ATTACK3_command[client], sizeof(ATTACK3_command[]), item);
				ATTACK3_save_key[client] = 1;}
		}	
	}
}