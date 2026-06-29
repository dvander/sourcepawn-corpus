//Functions can be found here :  https://www.desmos.com/calculator/64pctdqjwk

#define Timer_Update_speed	1.0		

#define F1_x(%1)			Pow(0.0005 * %1 , 2) + 1	
#define F2_x(%1)			Pow(1.4 , 0.0005 * %1)
#define F3_x(%1)			float(RoundToCeil(0.0025 * %1))


Handle h_timer[MAXPLAYERS+1];
float pos1[3], pos2[3] , temp , f_nearest_distance;

public OnPluginStart()
{
	HookEvent("player_spawn",E_P_X);
	HookEvent("player_death",E_P_X);
}

public E_P_X(Handle:event, const String:name[], bool:Broadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)	return ;
	
	if (name[7] == 's')
	{
		if (GetEntProp(client, Prop_Data, "m_iMaxHealth") > 3999 && h_timer[client] == null)
		{
			h_timer[client] = CreateTimer(Timer_Update_speed ,Timer_Modify_Speed , client , TIMER_REPEAT);
		}
	}
	else	OnClientDisconnect(client);
}

public OnClientDisconnect(client)
{
    if (h_timer[client]!=null)	delete h_timer[client];   
}

public Action Timer_Modify_Speed(Handle Timer,any tank)
{
	GetEntPropVector(tank,Prop_Send,"m_vecOrigin",pos1);
	
	//To Find The Nearest Survivor :
	
	f_nearest_distance = 15000.0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==2)
		{
			GetEntPropVector(i,Prop_Send,"m_vecOrigin",pos2);
			temp = GetVectorDistance(pos1,pos2);
			
			if (temp < f_nearest_distance)	f_nearest_distance = temp;			
		}
	}
	
	/*--------------------------------------------------------------------------------------------------
	PrintToConsole(1,"F1_x : %N  [Distance  %.2f  - F_Multiplier  %.2f]" ,tank , f_nearest_distance , F1_x(f_nearest_distance) );
	PrintToConsole(1,"F2_x : %N  [Distance  %.2f  - F_Multiplier  %.2f]" ,tank , f_nearest_distance , F2_x(f_nearest_distance) );
	PrintToConsole(1,"F3_x : %N  [Distance  %.2f  - F_Multiplier  %.2f]" ,tank , f_nearest_distance , F3_x(f_nearest_distance) );
	PrintToConsole(1,"---------------------------------------------------------------------------------");*/
	
	/*
	* You Can Also Use F1_x or F2_x 
	* [For Hard mode] : 
	1) You can Increase Timer Inteval .
	2) Or search for the farthest Survivor so the tank would be always angry , Just change 15000.0 to 0.0 and < to >
	3) or you can edit the equations and Increase the factors of multiplying 
	*/
	
	
	SetEntPropFloat(tank, Prop_Send, "m_flLaggedMovementValue", F3_x(f_nearest_distance) );  
	return Plugin_Continue;
}