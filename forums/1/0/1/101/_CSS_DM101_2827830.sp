#include <cstrike>
#include <sdktools>

Handle X_Handles[7];
int TeamKills[2];

public Plugin myinfo ={
    name = "[CS:S] Team Deathmatch Mode",
	author = "Sergan & 101",
	description = "Ignore main game objectives . after round time end , team with more kills is the winner ",
    version = "1.0",
    url = "https://forums.alliedmods.net"}

public APLRes AskPluginLoad2(Handle yourself, bool late, char[] error, int err_max) {
	CreateNative("GetTeamKills", GetTeamKills);
	return APLRes_Success;}


public int GetTeamKills(Handle plugin, int parameter) {
    return (4 > GetNativeCell(1) > 1) ? TeamKills[GetNativeCell(1) - 2] :
	ThrowNativeError(SP_ERROR_INDEX, "Invalid team index");} 



public void OnPluginStart(){
	X_Handles[0] = CreateConVar("DM_Enable" ,"0" ,_, FCVAR_NONE);
	X_Handles[1] = CreateConVar("DM_Spawn_Protection_Time" ,"5" ,_, FCVAR_NONE ,true ,0.1 , true ,10.0);
	X_Handles[2] = CreateConVar("DM_Respawn_Wait_Time" ,"1" ,_, FCVAR_NONE ,true ,0.2 , true ,10.0);
	X_Handles[3] = CreateConVar("DM_HeadShot_Bonus_Health" ,"10" ,_, FCVAR_NONE,true ,0.0 , true ,20.0);
	X_Handles[4] = CreateConVar("DM_Cumulative_Team_Kills" ,"0" ,"if 0 : team kills will be reset each new round , If 1 : team kills won't be reset until game restarted", FCVAR_NONE,true ,0.0 , true ,10.0);
	X_Handles[5] = FindConVar("mp_roundtime");
	HookConVarChange(X_Handles[0] , OnCvarChange);
	HookConVarChange(FindConVar("mp_restartgame") ,OnRestart);
	SetConVarInt(X_Handles[0],1);}
	
public OnRestart(Handle:convar, char[] oldValue, char[] newValue){
	if (StringToInt(newValue))
		TeamKills[0] = TeamKills[1] = 0;
}

public OnCvarChange(Handle:convar, char[] oldValue, char[] newValue){
	if ( StringToInt(newValue) && !StringToInt(oldValue) ){
		SetConVarInt(FindConVar("mp_ignore_round_win_conditions") , 1); 
		HookEvent("player_death", E_P_D);
		HookEvent("player_spawn", E_P_S);
		HookEvent("round_start", E_R_S);
		ServerCommand("mp_restartgame 1");
	}
	if ( !StringToInt(newValue) && StringToInt(oldValue) ){
		SetConVarInt(FindConVar("mp_ignore_round_win_conditions") , 0);
		UnhookEvent("player_death", E_P_D);
		UnhookEvent("player_spawn", E_P_S);
		UnhookEvent("round_start", E_R_S);
		ServerCommand("mp_restartgame 1");
		OnMapEnd();
	}}


public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason){
	if (GetConVarBool(X_Handles[0])){
		if(reason == CSRoundEnd_GameStart )
			TeamKills[0] = TeamKills[1] = 0;}
	return Plugin_Continue;}

public OnMapEnd(){
	if (X_Handles[6] != null) 
		delete X_Handles[6];
	TeamKills[0] = TeamKills[1] = 0;}


public E_R_S(Event event, const char[] name, bool dontBroadcast){
	if (!GetConVarBool(X_Handles[4]))
		TeamKills[0] = TeamKills[1] = 0;
	if (X_Handles[6] != null)
		delete X_Handles[6];
	X_Handles[6] = CreateTimer(GetConVarFloat(X_Handles[5]) * 60.0 + 1.0 , SetScore);}


public E_P_S(Event event, const char[] name, bool dontBroadcast){
    int X = GetClientOfUserId(event.GetInt("userid"));
    if(X){
		SetUp(X ,0 ,17 * GetRandomInt(0,15) , 17 * GetRandomInt(0,15) , 17 * GetRandomInt(0,15) , 20);
		CreateTimer(GetConVarFloat(X_Handles[1]) , Timer_EnableDmg , X);
	}}


public Action Timer_EnableDmg(Handle timer, int X){
    if (IsClientInGame(X))    SetUp(X,2,255,255,255,255);
    return Plugin_Handled;}


SetUp(X ,DmgType , r , g , b , Alpha){
    SetEntProp(X, Prop_Data, "m_takedamage", DmgType, 1);
    SetEntityRenderColor(X, r , g, b, Alpha);} 


public E_P_D(Event event,  const char[] name, bool dontBroadcast){
	int attacker = GetClientOfUserId( GetEventInt(event, "attacker") );
	int victim	 = GetClientOfUserId( GetEventInt(event, "userid") ) ;
	if (0 < attacker < MaxClients+1 && X_Handles[6] != null){
		TeamKills[GetClientTeam(attacker) - 2]++;
		if (GetEventBool(event,"headshot")){
			SetEntityHealth(attacker , GetClientHealth(attacker) + GetConVarInt(X_Handles[3]) );
			PaintScreen(attacker,{0,255,0,85});
			PaintScreen(victim	,{255,0,0,150});}
		else PaintScreen(attacker,{0,180,0,5});
	}
	CreateTimer(GetConVarFloat(X_Handles[2]) , Timer_Respawn , victim);}


public Action Timer_Respawn(Handle timer , any X){
	if (X && IsClientInGame(X) && !IsPlayerAlive(X))
		CS_RespawnPlayer(X);
	return Plugin_Handled;}


public Action SetScore(Handle timer){
	X_Handles[6] = null;
	int score ;
	if (TeamKills[0] > TeamKills[1]){
		CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_TerroristWin , true);
		score = CS_GetTeamScore(2) + 1;
		SetTeamScore(2, score);
		CS_SetTeamScore(2 ,score);
	}
	else if (TeamKills[1] > TeamKills[0]){
		CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_CTWin , true);
		score = CS_GetTeamScore(3) + 1;
		SetTeamScore(3, score);
		CS_SetTeamScore(3 ,score);
	}
	else
		CS_TerminateRound(GetConVarFloat(FindConVar("mp_round_restart_delay")), CSRoundEnd_Draw , true);
	PrintToChatAll("\x04[DM]\x01 TeamKills : CT (%d) - T (%d)" ,TeamKills[1],TeamKills[0]);
	return Plugin_Handled;}


PaintScreen(int X , int color[4]){
	Handle hBuffer = StartMessageOne("Fade", X);
	if ( hBuffer != INVALID_HANDLE){
		if (GetUserMessageType() == UM_BitBuf){
			BfWriteShort(hBuffer, 100);
			BfWriteShort(hBuffer, 100);
			BfWriteShort(hBuffer, 2);
			BfWriteByte(hBuffer, color[0]); 
			BfWriteByte(hBuffer, color[1]); 
			BfWriteByte(hBuffer, color[2]);   
			BfWriteByte(hBuffer, color[3]);}
		else{
			PbSetInt(hBuffer, "duration", 100);
			PbSetInt(hBuffer, "hold_time",100);
			PbSetInt(hBuffer, "flags", 2);
			PbSetColor(hBuffer, "clr", color);}
		EndMessage();
	}}