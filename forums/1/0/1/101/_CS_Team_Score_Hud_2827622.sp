/* https://sm.alliedmods.net/new-api/halflife/SetHudTextParams
**************************************************************/
#include <cstrike>

Handle cvar[3] , h_timer[64];
int data[64][4] , colors[8] = { 0 , 50 , 70 , 100 , 180 , 200 , 230 , 255 };

public Plugin myinfo =
{
    name = "CS:Source Show Team Score",
    version = "1.0",
    url = "https://forums.alliedmods.net/"
}

public OnPluginStart()
{
	cvar[0] = CreateConVar("Teams_HUD_ChangeColor_Interval" , "30" ,"time in seconds before change client's hud color", FCVAR_NONE, true ,1.0);
	cvar[1] = CreateConVar("Teams_HUD_X_Position" , "-1.0" ,"Hud Position On x-axis", FCVAR_NONE, true ,-1.0 , true , 1.0);
	cvar[2] = CreateConVar("Teams_HUD_Y_Position" , "0.865" ,"Hud Position On y-axis", FCVAR_NONE, true ,-1.0 , true , 1.0);
}

public void OnClientPostAdminCheck(int X)
{
	data[X][0] = 0 ;
	h_timer[X] = CreateTimer(1.0, TScore , X, TIMER_REPEAT);
}

public Action TScore(Handle timer, any X)
{
	static char Text[16];
	FormatEx(Text , 16 , "CT [%d] : T [%d]" , CS_GetTeamScore(3) , CS_GetTeamScore(2));
	
	if (data[X][0]++ % GetConVarInt(cvar[0]) == 0 ){
		data[X][1] = colors[GetRandomInt(0,7)];
		data[X][2] = colors[GetRandomInt(0,7)];
		data[X][3] = colors[GetRandomInt(0,7)];
	}
	
	SetHudTextParams(GetConVarFloat(cvar[1]) , GetConVarFloat(cvar[2]) , 1.0 , data[X][1] , data[X][2] ,data[X][3] , 255 , 0 , 6.0 , 0.1 , 0.2);
	ShowHudText(X, -1, Text);
	
	return Plugin_Continue;
}

public void OnClientDisconnect(int X){
	if (h_timer[X] != null)	delete h_timer[X]; }