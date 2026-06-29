#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define LOOP(%1,%2)			for( int X = %1; X < %2 ; X++)
#define GPROP(%1,%2)		GetEntProp(%1 , Prop_Send, %2)
#define SPROP(%1,%2,%3)		SetEntProp(%1 , Prop_Send, %2 , %3)

Panel SlayersPanel;
ConVar X_CVARS[7];
int rank[33][2],SKills[33], iStatsPanelMaxCount;
char EVENTS[6][24] = {"tank_killed","witch_killed","player_death","mission_lost","round_start","finale_escape_start"};
bool bPluginOn = false, bHooked = false, bStatsPanelTankAfterWave, bStatsPanelMissionLost, bStatsPanelWitchStats, bStatsPanelFinalStage;
float fStatsPanelTimerDelay;

char m_checkpoints_game[][][] =
{
	{"m_checkpointHeadshotAccuracy"	,"Most accurate (HS%)"},	// Not Working (fixed)
	{"m_checkpointHeadshots"		,"Most Headshots"},			// Not Working (fixed)
	{"m_checkpointZombieKills"		,"Most Kills"},
	{"m_checkpointDamageToTank"		,"Tank Slayers"},
	{"m_checkpointDamageToWitch"	,"Witch Killers"},
	{"m_checkpointDamageTaken"		,"Least Dmg Taken"}
};

public Plugin MyInfo = 
{
	name = "L4D Stages Stats",
	author = "Sandy&Milk",
	description = "Display Panel that shows current stage statistics for survivors",
	version = "test",
	url = "https://forums.alliedmods.net/showthread.php?p=2826883#post2826883"
}

public void OnPluginStart()
{
	X_CVARS[0] = CreateConVar("X_StatsPanel_Enable", "1",_, CVAR_FLAGS);
	X_CVARS[1] = CreateConVar("X_StatsPanel_Tank_After_Wave", "1", "0 : Display slayers panel when any tank killed", CVAR_FLAGS);
	X_CVARS[2] = CreateConVar("X_StatsPanel_Max_Count", "4", "Max count of players on list" , CVAR_FLAGS,true , 1.0 , true , 16.0);
	X_CVARS[3] = CreateConVar("X_StatsPanel_Mission_Lost", "1", "Show stats by random after mission-lost", CVAR_FLAGS);
	X_CVARS[4] = CreateConVar("X_StatsPanel_Witch_Stats", "1", "Show witch stats damage", CVAR_FLAGS);
	X_CVARS[5] = CreateConVar("X_StatsPanel_Timer_Delay", "5.0", "How many seconds it takes before panel display" ,CVAR_FLAGS,true , 0.1 , true , 15.0);
	X_CVARS[6] = CreateConVar("X_StatsPanel_Final_Stage", "1", "Show stage stats in final during escape", CVAR_FLAGS);

	X_CVARS[0].AddChangeHook(OnPluginOnCvarChange);
	LOOP(0,6)
	{
	    X_CVARS[1].AddChangeHook(OnCvarChange);
	    X_CVARS[2].AddChangeHook(OnCvarChange);
	    X_CVARS[3].AddChangeHook(OnCvarChange);
	    X_CVARS[4].AddChangeHook(OnCvarChange);
	    X_CVARS[5].AddChangeHook(OnCvarChange);
	    X_CVARS[6].AddChangeHook(OnCvarChange);
	}

	AutoExecConfig(true, "Clear_Map");

	RegConsoleCmd("sm_xpanel", Showlist);
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnPluginOnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	// This doesn't make sense (sm plugins unload XXXYYY IS THE BEST METHOD - THERE MUST BE A GENERAL PLUGIN THAT CONTROLS OTHERS Enable/Disable ON ADMINS-MENU)
	IsAllowed();
}

void OnCvarChange(ConVar convar, char[] oldValue, char[] newValue)
{
	GetCvars();
}

void IsAllowed()
{
	bPluginOn = X_CVARS[0].BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		GetCvars();
		LOOP(0,6) HookEvent( EVENTS[X]  , E_T_X , EventHookMode_Post );
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		LOOP(0,6) UnhookEvent( EVENTS[X], E_T_X , EventHookMode_Post );
	}
}

void GetCvars()
{
	bStatsPanelTankAfterWave = X_CVARS[1].BoolValue;
	iStatsPanelMaxCount = X_CVARS[2].IntValue;
	bStatsPanelMissionLost = X_CVARS[3].BoolValue;
	bStatsPanelWitchStats = X_CVARS[4].BoolValue;
	fStatsPanelTimerDelay = X_CVARS[5].FloatValue;
	bStatsPanelFinalStage = X_CVARS[6].BoolValue;
}

Action Showlist(int client, int args)
{	
	if ( !client )
	{
		ReplyToCommand(client, "[SM] Usage : You can't access from server console .");
		return Plugin_Handled;
	}
	if ( !bPluginOn )
	{
		ReplyToCommand(client, "[SM] Usage : This command was blocked .");
		return Plugin_Handled;
	}
	if (SlayersPanel != null)
	{
		SlayersPanel.Send(client,rankPanl, 30);
	}
	return Plugin_Handled;
}

void E_T_X(Event event, const char[] name, bool Broadcast) 
{
	switch(name[0])
	{
		case 'r' :
		{
			LOOP(1,33)	SKills[X] = 0;
		}
		
		case 'm' :
		{
			if (bStatsPanelMissionLost) ShowStats( GetRandomInt(0,5) , true);
		}
		
		case 'f' :
		{
			if (bStatsPanelFinalStage) ShowStats( GetRandomInt(0,5) , true);
		}

		case 'p' :	//Duplicated (This should not be happened)
		{
			static int shooter, victim;			
			shooter = GetClientOfUserId(event. GetInt("attacker"));
			victim = GetClientOfUserId(event. GetInt("userid"));
			if (!shooter || GetClientTeam(shooter) != 2 || (victim && GetClientTeam(victim)== 2) )	return;			
			if (victim 	&&	GetClientTeam(victim) == 3 ) PrintCenterText( shooter ,"+ %d", ++SKills[shooter]);

			if (event.GetBool("headshot"))
			{
				SPROP(shooter, m_checkpoints_game[1][0], GPROP(shooter,m_checkpoints_game[1][0]) + 1 );
				SPROP(shooter, m_checkpoints_game[0][0], RoundToNearest(100.0 * float(GPROP(shooter,m_checkpoints_game[1][0])) /  float(GPROP(shooter,m_checkpoints_game[2][0]) + SKills[shooter]) ) );
				//PrintToChat(shooter , "T-Kills : %d , SI-Kills : %d   , HS : %d , HS-Accuracy : %d％ " , GPROP(shooter,m_checkpoints_game[2][0]) + SKills[shooter] , SKills[shooter] ,  GPROP(shooter,m_checkpoints_game[1][0]) ,GPROP(shooter,m_checkpoints_game[0][0]));
			}
		}
		
		case 'w' :
		{
			if (bStatsPanelWitchStats) ShowStats( 4 , false);
		}
		
		case 't' :
		{
			if ( !bStatsPanelTankAfterWave	||	GetActiveTanks( GPROP(GetClientOfUserId(GetEventInt(event, "userid")),"m_zombieClass") ) == 1)
				ShowStats( 3 , false);
		}
	}
}

void ShowStats(int R , bool End)
{
	int count, sum;
	LOOP(1,33)
	if (IsClientInGame(X)	&&	GetClientTeam(X) == 2)
	{
		rank[count][0] = X;
		rank[count][1] = GPROP(X , m_checkpoints_game[R][0]) + (R == 2 ? SKills[X] : 0);
		sum += rank[count++][1];
	}
	
	if (!sum)
	{
		if (End) ShowStats( GetRandomInt(0,5) , true);
		return;
	}

	static char TXT[48];
	
	if (SlayersPanel != null)
	{
		delete SlayersPanel;
	}

	SlayersPanel = new Panel();

	SlayersPanel.SetTitle(m_checkpoints_game[R][1]);

	if ( count > iStatsPanelMaxCount )
	{
		count = iStatsPanelMaxCount;
	}

	SortCustom2D(rank , count , R == 5 ? SortAscending : SortDescending);
	
	LOOP(0,count)
	{
		Format(TXT, sizeof(TXT), "➣ %N [%d%s]", rank[X][0] , rank[X][1] , R ? "" : "％" );
		DrawPanelText(SlayersPanel, TXT);
	}
	
	CreateTimer(fStatsPanelTimerDelay , Timer_Panel ,_,TIMER_FLAG_NO_MAPCHANGE );
}

Action Timer_Panel(Handle timer)
{
	LOOP(1,33)
	if (IsClientInGame(X) && GetClientTeam(X) == 2)
	{
		ClientCommand(X, "play ui/menu_countdown.wav");
		SlayersPanel.Send(X, rankPanl, 30);
	}
	return Plugin_Handled;
}

int rankPanl(Menu Panela, MenuAction action, int param1, int param2)
{
	return 0;
}

int SortDescending(int[] x, int[] y, int[][] array, Handle data){
	if (x[1] > y[1]) return -1;
	else if (x[1] < y[1]) return 1;
	return 0;
}

int SortAscending(int[] x, int[] y, int[][] array, Handle data){
	if (x[1] < y[1]) return -1;
	else if (x[1] > y[1]) return 1;
	return 0;
}

stock int GetActiveTanks(int ZC_Tank)
{
	int T ;	LOOP(1,33) if (IsClientInGame(X) && IsPlayerAlive(X) && GetEntProp(X, Prop_Send, "m_zombieClass") == ZC_Tank) T++;
	return T;
}
