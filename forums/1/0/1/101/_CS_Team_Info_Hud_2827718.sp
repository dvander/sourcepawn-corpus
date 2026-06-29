/* https://sm.alliedmods.net/new-api/halflife/SetHudTextParams
**************************************************************/
#include <sourcemod>
#include <cstrike>

#define LOOP(%1,%2)			for( int i = %1; i <= %2 ; i++)

Handle cvar[6],h_timer;

public Plugin myinfo ={
    name = "[CS:S/GO]  Show Teams Info , ... ",
	author = "Sergan",
	description = "Display current players , scores , most kills , info ..",
    version = "1.0",
    url = "https://forums.alliedmods.net/showthread.php?t=349158"}


public OnPluginStart(){
	cvar[0] = CreateConVar("Teams_HUD_Enable" ,"1" ,_, FCVAR_NONE);
	cvar[1] = CreateConVar("Teams_HUD_ChangeColor_Interval" , "30" ,"time in seconds before change hud color", FCVAR_NONE, true ,1.0);
	cvar[2] = CreateConVar("Teams_HUD_X_Position" , "0.0" ,"Hud Position On x-axis", FCVAR_NONE, true ,-1.0 , true , 1.0);
	cvar[3] = CreateConVar("Teams_HUD_Y_Position" , "0.1" ,"Hud Position On y-axis", FCVAR_NONE, true ,-1.0 , true , 1.0);
	cvar[4] = FindConVar("hostname");
	cvar[5] = FindConVar("DM_Enable");
	HookConVarChange(cvar[0], OnCvarChange);
	Check_Hud_Timer();}
	
public OnCvarChange(Handle:convar, char[] oldValue, char[] newValue){
	if (!StrEqual(oldValue, newValue)){
		if (h_timer != null)
			delete h_timer;
		Check_Hud_Timer();}
}

Check_Hud_Timer(){
	if (h_timer == null && GetConVarBool(cvar[0]))
		h_timer = CreateTimer(1.0, UpdateInfo ,_, TIMER_REPEAT);
}

public OnClientPutInServer(P){
	Check_Hud_Timer();}

public Action UpdateInfo(Handle timer)
{
	static char Text[256],SKiller[42],SBots[10];
	static int Players[66],Tscore,CTscore,b_team,b_alive,PKills,seconds,r,g,b;
	int T,CT,TA,CTA,Spec,Admins,Killer,count,bots,temp;
	
	LOOP(1,MaxClients)
	{
		if (!IsClientInGame(i))	continue;
		
		Players[count++] = i;
		
		b_team  = GetClientTeam(i);
		b_alive = IsPlayerAlive(i);
		
		if (IsFakeClient(i))
		{
			FormatEx(SBots,10,"(%d %s)" ,++bots , bots > 1 ? "bots" : "bot");
		}
		else if(GetUserAdmin(i) != INVALID_ADMIN_ID)
		{
			Admins++;
		}
	
		if (b_team == 2)
		{
			T++;
			if (b_alive) TA++;
		}
		else if (b_team == 3)
		{
			CT++;
			if (b_alive) CTA++;
		}
		else
		{
			Spec++;
		}
	
		PKills = GetClientFrags(i);
		if (PKills > temp)
		{
			Killer = i;
			temp = PKills;
		}
	}
	
	if (!count){
		h_timer = null;
		return Plugin_Stop;
	}
	
	Tscore  = CS_GetTeamScore(2);
	CTscore = CS_GetTeamScore(3);
	if (Killer)	FormatEx(SKiller , 32 , "Killer : %N" , Killer);
	else GetConVarString(cvar[4] , SKiller ,42);
	
	if (cvar[5] != null && GetConVarBool(cvar[5]))
		FormatEx(Text , 256 , "Deathmatch\nCT [%d] : T [%d]\n——————\n(%d) CT vs T(%d)\nPlayers :%d %s\nSpectators : %d\nAdmins : %d\nTeam Kills : CT(%d) - T(%d)\n%s" , CTscore , Tscore ,CT ,T , count-- , bots ? SBots : "" , Spec , Admins ,GetTeamKills(3) , GetTeamKills(2), SKiller );
	else
		FormatEx(Text , 256 , "CT [%d] : T [%d]\n——————\n(%d/%d) CT vs T(%d/%d)\nPlayers :%d %s\nSpectators : %d\nAdmins : %d\n%s" , CTscore , Tscore ,CTA ,CT , TA ,T , count-- , bots ? SBots : "" , Spec , Admins , SKiller );
	
	if (seconds++ % GetConVarInt(cvar[1]) == 0 ){
		r = 17 * GetRandomInt(0,15);
		g = 15 * GetRandomInt(0,17);
		b = 17 * GetRandomInt(0,15);
	}
	
	SetHudTextParams(GetConVarFloat(cvar[2]) , GetConVarFloat(cvar[3]) , 1.1 , r , g , b , 255 , 2 , 1.0 , 0.025 , 0.01);
	LOOP(0,count) ShowHudText( Players[i] , -1 , Text);
	
	return Plugin_Continue;
}

native int GetTeamKills(int team); 