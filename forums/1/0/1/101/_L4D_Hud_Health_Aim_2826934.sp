/****************************************************************************************/
char XT[7][]={"Hint","Center","type 1","type 2","type 3","➣ Show Style:","➣ Text Style:"};
/****************************************************************************************/
#include <sdktools>	

#define LOOP(%1,%2)			for( int i = %1; i < %2 ; i++)

int ZC_TANK , client_data[33][5];
float X_HUD_ROWS;
Handle h_timer , X_CVARS[3] ;
char X_Text[][][] =
{
	{"【─̾D̾─̾E̾─̾A̾─̾D̾─̾─】" , "☖--D-☖-E-☖-A-☖-D--☖"	 , "҉҉҉҉҉҉D҉E҉A҉D҉҉҉҉҉҉" },
	{"【█──────────────────】" , "☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "█░░░░░░░░░░░░░░░░░░" },
	{"【██─────────────────】" , "☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "██░░░░░░░░░░░░░░░░░" },
	{"【███────────────────】" , "☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "███░░░░░░░░░░░░░░░░" },
	{"【████───────────────】" , "☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "████░░░░░░░░░░░░░░░" },
	{"【█████──────────────】" , "☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "█████░░░░░░░░░░░░░░" },
	{"【██████─────────────】" , "☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "██████░░░░░░░░░░░░░" },
	{"【███████────────────】" , "☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖"	 , "███████░░░░░░░░░░░░" },
	{"【████████───────────】" , "☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖"	 , "████████░░░░░░░░░░░" },
	{"【█████████──────────】" , "☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖"	 , "█████████░░░░░░░░░░" },
	{"【██████████─────────】" , "☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖"	 , "██████████░░░░░░░░░" },
    {"【███████████────────】" , "☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖"	 , "███████████░░░░░░░░" },
	{"【████████████───────】" , "☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖"	 , "████████████░░░░░░░" },
	{"【█████████████──────】" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖"	 , "█████████████░░░░░░" },
	{"【██████████████─────】" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖"	 , "██████████████░░░░░" },
	{"【███████████████────】" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖"	 , "███████████████░░░░" },
	{"【████████████████───】" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖"	 , "████████████████░░░" },
	{"【█████████████████──】" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖"	 , "█████████████████░░" },
	{"【██████████████████─】" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖"	 , "██████████████████░" },
	{"【███████████████████】" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗"	 , "███████████████████" }
}

public Plugin:MyInfo = {
	name = "L4D Tanks Show",
	author = "SandyMilk",
	description = "Generates a hint text msg displaying tanks health on HUD",
	version = "4 test",
	url = "https://forums.alliedmods.net/showthread.php?p=2826934#post2826934"}


public OnPluginStart(){
	HookEvent("player_spawn" , E_P_S , EventHookMode_Post);
	X_HUD_ROWS = float(sizeof(X_Text) - 1);
	ZC_TANK	   = GetEngineVersion() == Engine_Left4Dead ? 5 : 8;
	X_CVARS[0] = CreateConVar("X_HP_Hud_Enable",		 "1" ,_,FCVAR_NONE ,true ,0.0 ,true ,1.0);
	X_CVARS[1] = CreateConVar("X_HP_Hud_Update_Inteval", "1" ,_,FCVAR_NONE ,true ,0.1 ,true ,1.0);
	X_CVARS[2] = CreateConVar("X_HP_Hud_Spectators", 	 "1" ,_,FCVAR_NONE ,true ,0.0 ,true ,1.0);
	LOOP(0,3)	HookConVarChange(X_CVARS[i], OnCvarChange);
	RegConsoleCmd("sm_xhud", Hud_menu_options ,"allows client to change hud msg");
}

public OnCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if (!StrEqual(oldValue, newValue)) Check_Hud_Timer();}


public Action Hud_menu_options(client, args){
	if ( !client )
		ReplyToCommand(client, "You can't access from server console .");
	else if ( !GetConVarInt(X_CVARS[0]) )
		ReplyToCommand(client, "Command was blocked by administrator .");
	else	Create_Menu(client);
	return Plugin_Handled;}


Create_Menu(P){
	Handle XP = CreatePanel();
	SetPanelTitle(XP, XT[5]);
	LOOP(0,2)	DrawPanelItem(XP, XT[i] , client_data[P][0] == i  	? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	DrawPanelText(XP, "──────");
	DrawPanelText(XP, XT[6]);
	LOOP(2,5)	DrawPanelItem(XP, XT[i] , client_data[P][1] == i-2	? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	SendPanelToClient(XP,P,XC,99);
	CloseHandle(XP);}


public XC(Handle:M , MenuAction:A , P ,C){
	if (A == MenuAction_Select){
		if (0 < C < 3)		client_data[P][0] = C - 1;
		if (2 < C < 6)		client_data[P][1] = C - 3 ;
		if (0 < C < 6)		Create_Menu(P);
		if (!client_data[P][4]){
			client_data[P][2] = IsPlayerAlive(P) ? ( Is_Incap(P) ? 1 : GetClientHealth(P) ) : 0 ;
			client_data[P][3] = GetEntProp(P ,Prop_Send,"m_iMaxHealth");
		}
		DrawText(P,P);
	}
}

public E_P_S(Handle:event, const String:name[], bool:Broadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client)	OnPlayerSpawn(client);
}

OnPlayerSpawn(int client){
	client_data[client][4] = 0;
	if ( Is_Tank(client) ){
		int i_Health = GetEntProp(client ,Prop_Send,"m_iHealth");
		int i_MaxHealth = GetEntProp(client ,Prop_Send,"m_iMaxHealth");
		client_data[client][3] = i_MaxHealth > i_Health ? i_MaxHealth : i_Health;
		client_data[client][4] = 1;
		Check_Hud_Timer();
	}
}

Check_Hud_Timer(){
	if (IsValidHandle(h_timer))
		delete h_timer;
	if (GetConVarInt(X_CVARS[0]))
		h_timer = CreateTimer( GetConVarFloat(X_CVARS[1]) ,HP_Timer ,_, TIMER_REPEAT);
}


public Action HP_Timer(Handle timer){
	static int Count , T;
	Count = 0;
	LOOP(1,MaxClients+1){
		if (!IsClientInGame(i)) continue;
		client_data[i][2] = client_data[i][4] && ++Count && !Is_Incap(i) ? GetClientHealth(i) : 0;
		if ( Is_Allowed(i) ){
			T = GetClientAimTarget( i , true);
			if ( T > 0 && client_data[T][4] )
				DrawText(i,T);
		}
	}return Count ? Plugin_Continue : Plugin_Stop;
}

DrawText (X1 , X2){
	client_data[X1][0] ? PrintCenterText(X1 ,"%N\n%s", X2 , X_Text[ RatioToIndex(X2) ][client_data[X1][1]] ) : PrintHintText( X1 ,"%N\n%s", X2 , X_Text[ RatioToIndex(X2) ][client_data[X1][1]] );
}


stock bool:Is_Allowed(X){
	return (!IsFakeClient(X) && (!IsClientObserver(X) || GetConVarInt(X_CVARS[2])) );
}

stock int RatioToIndex(X){
	return RoundToCeil(X_HUD_ROWS * float(client_data[X][2]) / float(client_data[X][3]));
}

stock bool:Is_Tank(X){
	return GetEntProp(X , Prop_Send, "m_zombieClass") == ZC_TANK;
}

stock bool:Is_Incap(X){
	return GetEntProp(X, Prop_Send, "m_isIncapacitated", 1);
}