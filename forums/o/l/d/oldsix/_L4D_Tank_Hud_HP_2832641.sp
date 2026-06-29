/****************************************************************************************/
char XT[7][]={"Hint","Center","type 1","type 2","type 3","➣ Show Style:","➣ Text Style:"};
/****************************************************************************************/
#include <sdktools>	

#define LOOP(%1,%2)			for( int i = %1; i < %2 ; i++)

int X_HUD_ROWS , ZC_TANK , client_data[33][3];

Handle h_timer , X_CVARS[3] ;

char X_Text[][][] =
{
	{"҉҉҉҉҉҉D҉E҉A҉D҉҉҉҉҉҉" , "☖--D-☖-E-☖-A-☖-D--☖"	 , "─̾D̾─̾E̾─̾A̾─̾D̾─̾─" },
	{"■□□□□□□□□□□□□□□□□□□" , "☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "█░░░░░░░░░░░░░░░░░░" },
	{"■■□□□□□□□□□□□□□□□□□" , "☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "██░░░░░░░░░░░░░░░░░" },
	{"■■■□□□□□□□□□□□□□□□□" , "☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "███░░░░░░░░░░░░░░░░" },
	{"■■■■□□□□□□□□□□□□□□□" , "☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "████░░░░░░░░░░░░░░░" },
	{"■■■■■□□□□□□□□□□□□□□" , "☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "█████░░░░░░░░░░░░░░" },
	{"■■■■■■□□□□□□□□□□□□□" , "☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖☖"	 , "██████░░░░░░░░░░░░░" },
	{"■■■■■■■□□□□□□□□□□□□" , "☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖☖"	 , "███████░░░░░░░░░░░░" },
	{"■■■■■■■■□□□□□□□□□□□" , "☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖☖"	 , "████████░░░░░░░░░░░" },
	{"■■■■■■■■■□□□□□□□□□□" , "☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖☖"	 , "█████████░░░░░░░░░░" },
	{"■■■■■■■■■■□□□□□□□□□" , "☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖☖"	 , "██████████░░░░░░░░░" },
	{"■■■■■■■■■■■□□□□□□□□" , "☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖☖"	 , "███████████░░░░░░░░" },
	{"■■■■■■■■■■■■□□□□□□□" , "☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖☖"	 , "████████████░░░░░░░" },
	{"■■■■■■■■■■■■■□□□□□□" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖☖"	 , "█████████████░░░░░░" },
	{"■■■■■■■■■■■■■■□□□□□" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖☖"	 , "██████████████░░░░░" },
	{"■■■■■■■■■■■■■■■□□□□" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖☖"	 , "███████████████░░░░" },
	{"■■■■■■■■■■■■■■■■□□□" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖☖"	 , "████████████████░░░" },
	{"■■■■■■■■■■■■■■■■■□□" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖☖"	 , "█████████████████░░" },
	{"■■■■■■■■■■■■■■■■■■□" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☖"	 , "██████████████████░" },
	{"■■■■■■■■■■■■■■■■■■■" , "☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗☗"	 , "███████████████████" }
}

public Plugin:MyInfo = {
	name = "L4D Tanks Show",
	author = "SandyMilk",
	description = "Generates a hint text msg displaying tanks health on HUD",
	version = "4 test",
	url = "https://forums.alliedmods.net/showthread.php?p=2826934#post2826934"}


public OnPluginStart(){
	HookEvent( "tank_spawn"  , E_T_X);
	X_HUD_ROWS = sizeof(X_Text) - 1 ;
	ZC_TANK	   = GetEngineVersion() == Engine_Left4Dead ? 5 : 8;
	X_CVARS[0] = CreateConVar("X_HP_Hud_Enable",		 "1" ,_,FCVAR_NONE ,true ,0.0 ,true ,1.0);
	X_CVARS[1] = CreateConVar("X_HP_Hud_Update_Inteval", "1" ,_,FCVAR_NONE ,true ,0.1 ,true ,1.0);
	X_CVARS[2] = CreateConVar("X_HP_Hud_Spectators", 	 "1" ,_,FCVAR_NONE ,true ,0.0 ,true ,1.0);
	LOOP(0,3)	HookConVarChange(X_CVARS[i], OnCvarChange);
	RegConsoleCmd("sm_xhud", Hud_menu_options ,"allows client to change hud msg");}


public OnCvarChange(Handle:convar, const String:oldValue[], const String:newValue[]){
	if (!StrEqual(oldValue, newValue)) Check_Hud_Timer();}


public Action Hud_menu_options(client, args){
	if ( !client )
		ReplyToCommand(client, "[SM] Usage : You can't access from server console .");
	else if ( !GetConVarInt(X_CVARS[0]) )
		ReplyToCommand(client, "[SM] Usage : Command was blocked by administrator .");
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
		DrawText(P,P);
	}}


public E_T_X(Handle:event, const String:name[], bool:Broadcast) {
	Check_Hud_Timer();}


Check_Hud_Timer(){
	if (h_timer != null)
		delete h_timer;
	if (GetConVarInt(X_CVARS[0]))
		h_timer = CreateTimer( GetConVarFloat(X_CVARS[1]) ,HP_Timer ,_, TIMER_REPEAT);
}


public Action HP_Timer(Handle timer){
	int Count;
	LOOP(1,33){
		if (IsValidClient(i)){
			client_data[i][2] = Is_Tank(i) ? ++Count : 0;
			if ( Is_Allowed(i) ){
				int T = GetClientAimTarget( i , true);
				if ( T > 0 && client_data[T][2] )
					DrawText(i,T);
			}	}
	}	
	if (!Count){
		h_timer=null;return Plugin_Stop;}
	return Plugin_Continue;
}

DrawText (X1 , X2){
	if (client_data[X1][0])	PrintHintText(X1 ,"%N\n%s", X2 , X_Text[ RatioToIndex( X2 , X_HUD_ROWS ) ][client_data[X1][1]] );
	else					 PrintCenterText( X1 ,"%N\n%s", X2 , X_Text[ RatioToIndex( X2 , X_HUD_ROWS ) ][client_data[X1][1]] );}


stock bool IsValidClient(int client){
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock bool:Is_Allowed(int X){
	return (!IsFakeClient(X) && (!IsClientObserver(X) || GetConVarInt(X_CVARS[2])) );}


stock int RatioToIndex(int T , int Rows){
	return	!GetEntProp( T , Prop_Send, "m_isIncapacitated") ? 
	RoundToCeil( float(Rows) * float(GetEntProp(T ,Prop_Data,"m_iHealth")) / float(GetEntProp(T ,Prop_Data,"m_iMaxHealth"))) : 0;}


stock bool:Is_Tank(int X){
	return GetEntProp(X , Prop_Send, "m_zombieClass") == ZC_TANK;}