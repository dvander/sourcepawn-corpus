int OldTarget[MAXPLAYERS+1];
Handle htimer[MAXPLAYERS+1];
GlobalForward g_SpecJForward,g_SpecLForward;

public Plugin myinfo ={
    name = "[ANY] Spectators Tracker",
	author = "Zelda|101",
	description = "Catches when spectators update their target (join/leave a player's channel).",
    version = "2.0 - will be updated",
    url = "https://forums.alliedmods.net"}

public void OnPluginStart(){
	g_SpecJForward = CreateGlobalForward("OnSpecJoinTarget", ET_Ignore, Param_Cell, Param_Cell);
	g_SpecLForward = CreateGlobalForward("OnSpecLeftTarget", ET_Ignore, Param_Cell, Param_Cell);
}

public OnClientPostAdminCheck(P){
	if ( IsFakeClient(P) ) return;
	htimer[P] = CreateTimer(1.0,Timer_Check,P,TIMER_REPEAT);
}

public OnClientDisconnect(P){
	if ( IsFakeClient(P) ) return;
	KillTimer(htimer[P]);
	UpdateInfo(P,0,OldTarget[P]);
}
	

public Action Timer_Check(Handle hTimer, any P){
	int X = IsClientObserver(P) ? GetEntPropEnt(P,Prop_Send,"m_hObserverTarget") : 0;
	if (X != OldTarget[P] )
		UpdateInfo(P,X,OldTarget[P]);
	return Plugin_Continue;
}


static void UpdateInfo(P,X1,X0){
	if (X1>0 && IsPlayerAlive(X1)){
		Call_StartForward(g_SpecJForward);
		Call_PushCell(P);					
		Call_PushCell(X1);
		Call_Finish();
		
	}
	if (X0>0 && IsClientInGame(X0)){
		Call_StartForward(g_SpecLForward);
		Call_PushCell(P);					
		Call_PushCell(X0);
		Call_Finish();
	}
	OldTarget[P]= X1;
}