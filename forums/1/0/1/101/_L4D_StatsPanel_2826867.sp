#define LOOP(%1,%2)			for( int X = %1; X < %2 ; X++)
#define GPROP(%1,%2)		GetEntProp(%1 , Prop_Send, %2)
#define SPROP(%1,%2,%3)		SetEntProp(%1 , Prop_Send, %2 , %3)

Handle SlayersPanel, X_CVARS[7];

int rank[33][2],SKills[33];

char EVENTS[6][24] = {"tank_killed","witch_killed","player_death","mission_lost","round_start","finale_escape_start"};

char m_checkpoints_game[][][] =
{
	{"m_checkpointHeadshotAccuracy"	,"Most accurate (HS%)"},	// Not Working (fixed)
	{"m_checkpointHeadshots"		,"Most Headshots"},			// Not Working (fixed)
	{"m_checkpointZombieKills"		,"Most Kills"},
	{"m_checkpointDamageToTank"		,"Tank Slayers"},
	{"m_checkpointDamageToWitch"	,"Witch Killers"},
	{"m_checkpointDamageTaken"		,"Least Dmg Taken"}
}

public Plugin:MyInfo = 
{
	name = "L4D Stages Stats",
	author = "Sandy&Milk",
	description = "Display Panel that shows current stage statistics for survivors",
	version = "test",
	url = "http://forums.alliedmods.net"
}

public void OnPluginStart()
{
	LOOP(0,6) HookEvent( EVENTS[X] , E_T_X , EventHookMode_Post) ;
   
	X_CVARS[0]=CreateConVar("X_StatsPanel_Enable", "1",_, FCVAR_NONE);
	X_CVARS[1]=CreateConVar("X_StatsPanel_Tank_After_Wave", "1", "0 : Display slayers panel when any tank killed", FCVAR_NONE);
	X_CVARS[2]=CreateConVar("X_StatsPanel_Max_Count", "4", "Max count of players on list" , FCVAR_NONE,true , 1.0 , true , 16.0);
	X_CVARS[3]=CreateConVar("X_StatsPanel_Mission_Lost", "1", "Show stats by random after mission-lost", FCVAR_NONE);
	X_CVARS[4]=CreateConVar("X_StatsPanel_Witch_Stats", "1", "Show witch stats damage", FCVAR_NONE);
	X_CVARS[5]=CreateConVar("X_StatsPanel_Timer_Delay", "5.0", "How many seconds it takes before panel display" ,FCVAR_NONE,true , 0.1 , true , 15.0);
	X_CVARS[6]=CreateConVar("X_StatsPanel_Final_Stage", "1", "Show stage stats in final during escape", FCVAR_NONE);
	HookConVarChange(X_CVARS[0], OnCvarChange);
	
	RegConsoleCmd("sm_xpanel", Showlist);
}

public OnCvarChange(Handle:convar, char[] oldValue, char[] newValue)
{
	// This doesn't make sense (sm plugins unload XXXYYY IS THE BEST METHOD - THERE MUST BE A GENERAL PLUGIN THAT CONTROLS OTHERS Enable/Disable ON ADMINS-MENU)
	if ( StringToInt(newValue) && !StringToInt(oldValue) )	LOOP(0,6) HookEvent( EVENTS[X]  , E_T_X , EventHookMode_Post );
	if ( !StringToInt(newValue) && StringToInt(oldValue) )	LOOP(0,6) UnhookEvent( EVENTS[X], E_T_X , EventHookMode_Post );
}

public Action:Showlist(client,args)
{	
	if ( !client )
	{
		ReplyToCommand(client, "[SM] Usage : You can't access from server console .");
		return Plugin_Handled;
	}
	if ( !GetConVarInt(X_CVARS[0]) )
	{
		ReplyToCommand(client, "[SM] Usage : This command was blocked .");
		return Plugin_Handled;
	}
	if (SlayersPanel != null)
	{
		SendPanelToClient(SlayersPanel,client,rankPanl, 30);
	}
	return Plugin_Handled;
}

public E_T_X(Handle:event, const String:name[], bool:Broadcast) 
{
	switch(name[0])
	{
		case 'r' :
		{
			LOOP(1,33)	SKills[X] = 0;
		}
		
		case 'm' :
		{
			if (GetConVarInt(X_CVARS[3]))
				ShowStats( GetRandomInt(0,5) , true);
		}
		
		case 'f' :
		{
			if (GetConVarInt(X_CVARS[6]))
				ShowStats( GetRandomInt(0,5) , true);
		}
		
		case 'p' :	//Duplicated (This should not be happened)
		{
			static int shooter,victim;
			
			shooter = GetClientOfUserId( GetEventInt(event, "attacker") );
			victim = GetClientOfUserId( GetEventInt(event, "userid") );
			
			if (!shooter || GetClientTeam(shooter) != 2 || (victim && GetClientTeam(victim)== 2) )	return;
			
			if (victim 	&&	GetClientTeam(victim) == 3 )
				PrintCenterText( shooter ,"+ %d", ++SKills[shooter]);
				
			if (GetEventBool(event,"headshot"))
			{
				SPROP(shooter, m_checkpoints_game[1][0], GPROP(shooter,m_checkpoints_game[1][0]) + 1 );
				SPROP(shooter, m_checkpoints_game[0][0], RoundToNearest(100.0 * float(GPROP(shooter,m_checkpoints_game[1][0])) /  float(GPROP(shooter,m_checkpoints_game[2][0]) + SKills[shooter]) ) );
				//PrintToChat(shooter , "T-Kills : %d , SI-Kills : %d   , HS : %d , HS-Accuracy : %d％ " , GPROP(shooter,m_checkpoints_game[2][0]) + SKills[shooter] , SKills[shooter] ,  GPROP(shooter,m_checkpoints_game[1][0]) ,GPROP(shooter,m_checkpoints_game[0][0]));
			}
		}
		
		case 'w' :
		{
			if (GetConVarInt(X_CVARS[4]))
				ShowStats( 4 , false);
		}
		
		case 't' :
		{
			if ( !GetConVarInt(X_CVARS[1])	||	GetActiveTanks( GPROP(GetClientOfUserId(GetEventInt(event, "userid")),"m_zombieClass") ) == 1)
				ShowStats( 3 , false);
		}
	}
}

ShowStats(int R , bool End)
{
	int count , sum ;
	
	LOOP(1,33)
	if (IsClientInGame(X)	&&	GetClientTeam(X) == 2)
	{
		rank[count][0] = X;
		rank[count][1] = GPROP(X , m_checkpoints_game[R][0]) + (R == 2 ? SKills[X] : 0);
		sum += rank[count++][1];
	}
	
	if (!sum)
	{
		if (End)	ShowStats( GetRandomInt(0,5) , true);
		return;
	}
	
	static char TXT[48];
	
	if (SlayersPanel != null)
	{
		delete SlayersPanel;
	}
	
	SlayersPanel = CreatePanel();
	
	SetPanelTitle(SlayersPanel, m_checkpoints_game[R][1]);
	
	if ( count > GetConVarInt(X_CVARS[2]) )
	{
		count = GetConVarInt(X_CVARS[2]);
	}

	SortCustom2D(rank , count , R == 5 ? SortAscending : SortDescending);
	
	LOOP(0,count)
	{
		Format(TXT, sizeof(TXT), "➣ %N [%d%s]", rank[X][0] , rank[X][1] , R ? "" : "％" );
		DrawPanelText(SlayersPanel, TXT);
	}
	
	CreateTimer(GetConVarFloat(X_CVARS[5]) , Timer_Panel ,_,TIMER_FLAG_NO_MAPCHANGE );
}

public Action Timer_Panel(Handle timer)
{
	LOOP(1,33)
	if (IsClientInGame(X)	&&	GetClientTeam(X) == 2)
	{
		ClientCommand(X, "play ui/menu_countdown.wav");
		SendPanelToClient(SlayersPanel,X,rankPanl, 30);
	}
	return Plugin_Handled;
}

public rankPanl(Handle:Panela, MenuAction:action, param1, param2){}

public SortDescending(x[], y[], array[][], Handle:data){
	if (x[1] > y[1]) return -1;
	else if (x[1] < y[1]) return 1;
	return 0;
}

public SortAscending(x[], y[], array[][], Handle:data){
	if (x[1] < y[1]) return -1;
	else if (x[1] > y[1]) return 1;
	return 0;
}

public SortRandom(x[], y[], array[][], Handle:data){
	return GetRandomInt(-1,1);
}

stock int GetActiveTanks(int ZC_Tank){
	int T ;	LOOP(1,33) if (IsClientInGame(X) && IsPlayerAlive(X) && GetEntProp(X, Prop_Send, "m_zombieClass") == ZC_Tank) T++;
	return T;
}