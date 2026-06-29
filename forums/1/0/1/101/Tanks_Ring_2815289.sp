#include <sdktools>

int g_Sprite;
new Handle:h_timer[MAXPLAYERS+1];
int P_Color[MAXPLAYERS+1][4];
float P_Pos[3];

public void OnPluginStart()
{
    HookEvent("tank_spawn",E_Tank);
	HookEvent("tank_killed",E_Tank);
}

public void OnMapStart()
{
	g_Sprite = PrecacheModel("sprites/laserbeam.vmt", true);
	if (!g_Sprite)
		SetFailState("Unable to PrecacheModel");
}

public E_Tank(Handle:event, const String:name[], bool:Broadcast) 
{
	new P = GetClientOfUserId(GetEventInt(event, "userid"));
	if (StrContains(name,"_spawn")!= -1)
	{
		for (new i=0 ;i<3; i++)
		{
			P_Color[P][i]=GetRandomInt(0,3)*85;		//Red,Green,Blue
		}	
		P_Color[P][3]=255;	//Alpha
		
		h_timer[P]=CreateTimer(0.25, Timer_Beacon,P, TIMER_REPEAT);
	}
	else
		delete h_timer[P];
}

public OnClientDisconnect(P)
{
	if (h_timer[P]!=null)
		delete h_timer[P];
}

public Action Timer_Beacon(Handle Timer,any P)
{
	GetClientAbsOrigin(P, P_Pos);
	P_Pos[2] += 120.0;	//height of ring 
	TE_SetupBeamRingPoint(P_Pos, 10.0, 120.0, g_Sprite, g_Sprite, 1, 1, 0.50, 5.0, 0.0, P_Color[P], 0, 0);
	TE_SendToAll();
	
	return Plugin_Continue;
}