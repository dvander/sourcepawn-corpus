/* https://wiki.alliedmods.net/Scripting_FAQ_(SourceMod)#How_do_I_add_color_to_my_messages.3F */

#define JOIN			"\x03 %N is spectating you"
#define LEFT			"\x05 %N is no longer spectating"

int OldTarget[MAXPLAYERS+1];
Handle htimer[MAXPLAYERS+1];

public Plugin myinfo ={
    name = "[ANY] Spectators Announcer",
	author = "101",
	description = "Notifies players when a spectator join/left their channels",
    version = "1.0 - will be updated",
    url = "https://forums.alliedmods.net"}


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
	if (X1>0 && IsPlayerAlive(X1))
		PrintToChat(X1,JOIN,P);
	if (X0>0 && IsClientInGame(X0))
		PrintToChat(X0,LEFT,P);
	OldTarget[P]= X1;
}