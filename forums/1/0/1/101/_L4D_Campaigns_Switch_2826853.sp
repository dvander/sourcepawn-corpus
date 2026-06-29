ConVar X_CVAR;

int MIN , MAX , X ;

char Campaign[19][24] =
{
	"l4d_hospital01_apartment",
	"l4d_smalltown01_caves",
	"l4d_garage01_alleys",
	"l4d_airport01_greenhouse",
	"l4d_farm01_hilltop",
	"l4d_river01_docks",
	"c1m1_hotel",
	"c2m1_highway",
	"c3m1_plankcountry",
	"c4m1_milltown_a",
	"c5m1_waterfront",
	"c6m1_riverbank",
	"c7m1_docks",
	"c8m1_apartment",
	"c9m1_alleys",
	"c10m1_caves",
	"c11m1_greenhouse",
	"c12m1_hilltop",
	"c13m1_alpinecreek"
};

public void OnPluginStart()
{
	switch ( GetEngineVersion() )
	{
		case Engine_Left4Dead : { MIN = 0 ; MAX = 5 ; }
		case Engine_Left4Dead2: { MIN = 6 ; MAX = 18; }
	}
	
    X_CVAR = CreateConVar("X_ChangeLevel_Time", "10.0" ,_, FCVAR_NOTIFY, true ,0.1);
	
    HookEvent("finale_win" , E_F_W);
}

public E_F_W(Handle:event, const String:name[], bool:Broadcast) 
{
	X = MIN ; int num = MIN ? 3 : 5 ;
	
	char Map[32];GetCurrentMap(Map,sizeof(Map));
	
	while( X < MAX || (X = MIN) < 0)
	{
		if (!strncmp(Map,Campaign[X++],num)) break;	
	}
	CreateTimer(GetConVarFloat(X_CVAR), T_Map);
}

public Action T_Map(Handle Timer)
{
	ServerCommand("changelevel %s",Campaign[X]);
	return Plugin_Handled;
}