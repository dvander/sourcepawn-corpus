// https://forums.alliedmods.net/showthread.php?p=2835566#post2835566

#include <sdktools>

// %1 :  AliveSurvivors
// %2 :  AliveTanks
#define f1(%1)				RoundToCeil( float(%1) * 0.56 ) + 1		// SpecialZ count .When there are no tanks in the field 
#define f2(%1,%2)			%1/%2									// SpecialZ count .When there are some tanks in the field			
#define f3(%1)				RoundToCeil( float(%1) * 0.35 ) + 1		// Tanks count  (used as default)
#define f4(%1)				RoundToCeil( float(%1) * 0.6 )			// Tanks count  (not used)
#define f5(%1)				3000 * (5 + %1)							// Tanks health (used as default) . Another example : 2000 * (8 + %1)

#define Tanks_Const_Count		false
#define Tanks_Const_Health		false
#define Max_WaveTanks	3				// constant tanks count per wave  [If "Tanks_Const_Count" is set to true, this value will be considered . Otherwise : f3(AliveSurvivors)]
#define	Tanks_Health		24000		// constant tanks health per wave [If "Tanks_Const_Health" is set to true, this value will be considered . Otherwise : f5(AliveSurvivors)]
#define ZSpecials_SpawnInterval	30.0

Handle hTimer1 , hTimer2;
int Players[MAXPLAYERS+1] , RandomPlayers , AliveSurvivors, AliveZombies , AliveTanks ;

char ZName[3][] = { "boomer" , "hunter" , "smoker"};
int Percentage[3]= { 33 , 33 , 34 };	// boomer has 33% chance . Note : the order must be ascending and the total sum = 100.

public OnPluginStart(){

	Handle cvar = FindConVar("director_no_specials");
	SetConVarBounds(cvar , ConVarBound_Lower , true , 1.0);
	SetConVarInt(cvar,1);
	cvar = FindConVar("z_max_player_zombies");
	SetConVarBounds( cvar , ConVarBound_Upper , false);
	SetConVarInt(cvar,16);
	delete cvar;

	HookEvent("round_start", event_round_start , EventHookMode_Post);
	HookEvent("tank_spawn", event_tank_spawn , EventHookMode_Post);
	RegAdminCmd("sm_zcall", Call_Specials , ADMFLAG_RCON, "Refill special infected spawns");
}

public Action Call_Specials(int client, int args){
	if ( !IsValidHandle(hTimer2) ){
		ReplyToCommand(client , "Players are not ready yet .");
		return Plugin_Handled;
	}
    TriggerTimer(hTimer2, false);
    return Plugin_Handled;
}

public event_tank_spawn(Handle event, char[] event_name, bool dontBroadcast){
	static int LastTime;
	if (GetTime() - LastTime){
		LastTime = GetTime();
		UpdatePlayersCount();
		SpawnInfected(1 ,  Tanks_Const_Count ? Max_WaveTanks : f3(AliveSurvivors) , true);
	}SetEntityHealth(GetClientOfUserId(GetEventInt(event, "userid")), Tanks_Const_Health ? Tanks_Health : f5(AliveSurvivors) );
}


public event_round_start(Handle event, char[] event_name, bool dontBroadcast){
	if (IsValidHandle(hTimer1))
		KillTimer(hTimer1);
	if (IsValidHandle(hTimer2))
		KillTimer(hTimer2);
	hTimer1 = CreateTimer(1.0, Timer_LeftStartCheck,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_LeftStartCheck(Handle Timer){
    if (HasSurvivorsLeftSafeArea()){
        hTimer2 = CreateTimer( ZSpecials_SpawnInterval ,Timer_Spawn_Specials ,_, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        return Plugin_Stop;
    }return Plugin_Continue;
}


public Action Timer_Spawn_Specials(Handle timer){
	if (UpdatePlayersCount()){
		SpawnInfected(AliveZombies ,  AliveTanks ? f2(AliveSurvivors,AliveTanks) : f1(AliveSurvivors) ,false);
		return Plugin_Continue;
	}return Plugin_Stop;
}


SpawnInfected(start , limit , bool tanks){
	int flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	while(start++ < limit)
		FakeClientCommand( Players[GetRandomInt(0,RandomPlayers -1)]  , "z_spawn %s auto" , tanks ? "tank" : ZName[PickUpRandomIndex()]);
	SetCommandFlags("z_spawn", flags);
}


int UpdatePlayersCount(){
	RandomPlayers = AliveSurvivors = AliveZombies = AliveTanks = 0;
	for (int i=1 ; i<=MaxClients ; i++){
		if (!IsClientInGame(i)) continue;
		Players[RandomPlayers++] = i;
		if (!IsPlayerAlive(i)) continue;
		switch (GetEntProp(i , Prop_Send, "m_zombieClass")){
			case 6 : AliveSurvivors++;
			case 5 : AliveTanks++;
			default: AliveZombies++;
		}
	}return RandomPlayers;
}


int PickUpRandomIndex(){
    static int i , sum , rand;
	i = sum = 0;
	rand = GetRandomInt(0 , 99);
    while( i < 3 ){
		sum += Percentage[i++];
        if(sum  > rand)
            break;
    }return i-1;
}


bool HasSurvivorsLeftSafeArea(){
    int entity = FindEntityByClassname(-1, "terror_player_manager");
    return ( entity != -1 && GetEntProp(entity, Prop_Send, "m_hasAnySurvivorLeftSafeArea") );
}