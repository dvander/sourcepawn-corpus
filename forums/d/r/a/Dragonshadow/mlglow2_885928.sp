#pragma semicolon 1
/*
/////////////////////////////////////////////////////////////////////////////////////////
		История версий ML Glow:
///////////////////////////////////////////////////////////////////////////////////////////
1.0:		-Первый релиз. Glow Q1 тема взята из l4d community autoexec 2.2f.
1.1:		-Добавлена D1 тема, активируется кваром ml_glow 2.
1.2:		-Квар ml_glow 0 теперь ставит тему по умолчанию.
1.3:		- Dragonshadow - Optimization
*/
#define PLUGIN_VERSION "1.3"

new Handle:MLGlow=INVALID_HANDLE;
new glowhook = 0;

public Plugin:myinfo = 
{
	name = "[L4D] Must Live Glow",
	author = "Pontifex",
	description = "Changes Glow Colors on Items to that of the 'l4d community autoexec 2.2f'",
	version = PLUGIN_VERSION,
	url = "http://must-live.ru"
}

public OnPluginStart()
{
	CreateConVar("ml_version", PLUGIN_VERSION, "[L4D] Must Live Glow Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	MLGlow = CreateConVar("ml_glow", "1", "Glow Mode (0 - default, 1 - Q1 glow, 2 - D1 glow)", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	
	HookConVarChange(MLGlow, cvarchanged); 
}


public OnClientPostAdminCheck(client)
{	
	if(glowhook != 0)
	{
		if(IsClientConnected(client))
		{
			TimerStart(client);
		}
	}
}

public OnConfigsExecuted() 
{
	glowhook = GetConVarInt(MLGlow);
} 

public cvarchanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	glowhook = GetConVarInt(MLGlow);
	if (glowhook != 0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
		TimerStart(i);
		}
	}
	
} 

public Action:Glow1(Handle:timer, any:client)  
{
	if(!IsClientConnected(client) && !IsClientInGame(client)) 
	{
		return Plugin_Stop;
	}
	
	switch(glowhook)
	{
	case 0:
		{
			ClientCommand(client, "cl_glow_item_far_b 1.0");
			ClientCommand(client, "cl_glow_item_far_g 0.4");
			ClientCommand(client, "cl_glow_item_far_r 0.3");
			
			ClientCommand(client, "cl_glow_ghost_infected_b 1.0");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.4");
			ClientCommand(client, "cl_glow_ghost_infected_r 0.3");
			
			ClientCommand(client, "cl_glow_item_b 1.0");
			ClientCommand(client, "cl_glow_item_g 0.7");
			ClientCommand(client, "cl_glow_item_r 0.7");
			
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.4");
			ClientCommand(client, "cl_glow_survivor_hurt_r 1.0");
			
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.0");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.4");
			ClientCommand(client, "cl_glow_survivor_vomit_r 1.0");
			
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.4");
			ClientCommand(client, "cl_glow_infected_r 0.3");
			
			ClientCommand(client, "cl_glow_survivor_b 1.0");
			ClientCommand(client, "cl_glow_survivor_g 0.4");
			ClientCommand(client, "cl_glow_survivor_r 0.3");
			return Plugin_Stop;
		}
		
	case 1:
		{
			ClientCommand(client, "cl_glow_item_far_r 0.5");
			ClientCommand(client, "cl_glow_item_far_g 1.0");
			ClientCommand(client, "cl_glow_item_far_b 0.0");
			
			ClientCommand(client, "cl_glow_ghost_infected_r 0.35");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.35");
			ClientCommand(client, "cl_glow_ghost_infected_b 0.35");
			
			ClientCommand(client, "cl_glow_item_r 0.5");
			ClientCommand(client, "cl_glow_item_g 1.0");
			ClientCommand(client, "cl_glow_item_b 0.0");
			
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.45");
			ClientCommand(client, "cl_glow_survivor_hurt_r 1.0");
			
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.07");
			ClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
			
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.5");
			ClientCommand(client, "cl_glow_infected_r 0.0");
			
			ClientCommand(client, "cl_glow_survivor_b 1.0");
			ClientCommand(client, "cl_glow_survivor_g 0.5");
			ClientCommand(client, "cl_glow_survivor_r 0.5");
		}	
		
	case 2:
		{
			ClientCommand(client, "cl_glow_item_far_r 0.0");
			ClientCommand(client, "cl_glow_item_far_b 1.0");
			ClientCommand(client, "cl_glow_item_far_g 0.6");
			
			ClientCommand(client, "cl_glow_ghost_infected_r 0.35");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.35");
			ClientCommand(client, "cl_glow_ghost_infected_b 0.35");
			
			ClientCommand(client, "cl_glow_item_r 0.0");
			ClientCommand(client, "cl_glow_item_b 1.0");
			ClientCommand(client, "cl_glow_item_g 0.5");
			
			ClientCommand(client, "cl_glow_survivor_hurt_b 0.0");
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.45");
			ClientCommand(client, "cl_glow_survivor_hurt_r 1.0");	
			
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.07");
			ClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
			
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.5");
			ClientCommand(client, "cl_glow_infected_r 0.0");
			
			ClientCommand(client, "cl_glow_survivor_b 1.0");
			ClientCommand(client, "cl_glow_survivor_g 0.5");
			ClientCommand(client, "cl_glow_survivor_r 0.5");
		}
	}
	return Plugin_Continue;
}

public Action:Glow2(Handle:timer, any:client)  
{
	if(!IsClientConnected(client) && !IsClientInGame(client)) 
	{
		return Plugin_Stop;
	}
	
	switch(glowhook)
	{
	case 0:
		{
			ClientCommand(client, "cl_glow_item_far_b 1.0");
			ClientCommand(client, "cl_glow_item_far_g 0.4");
			ClientCommand(client, "cl_glow_item_far_r 0.3");
			return Plugin_Stop;
		}
		
	case 1:
		{
			ClientCommand(client, "cl_glow_item_far_r 0.0");
			
			ClientCommand(client, "cl_glow_ghost_infected_r 0.7");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.7");
			ClientCommand(client, "cl_glow_ghost_infected_b 0.7");
			
			ClientCommand(client, "cl_glow_item_r 0.0");
			ClientCommand(client, "cl_glow_item_g 0.0");
			
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");
			
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.07");
			ClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
			
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.5");
			ClientCommand(client, "cl_glow_infected_r 0.0");
			
			ClientCommand(client, "cl_glow_survivor_b 1.0");
			ClientCommand(client, "cl_glow_survivor_g 0.5");
			ClientCommand(client, "cl_glow_survivor_r 0.5");
		}
		
	case 2:
		{
			ClientCommand(client, "cl_glow_item_far_r 0.45");
			
			ClientCommand(client, "cl_glow_ghost_infected_r 0.7");
			ClientCommand(client, "cl_glow_ghost_infected_g 0.7");
			ClientCommand(client, "cl_glow_ghost_infected_b 0.7");
			
			ClientCommand(client, "cl_glow_item_g 1.0");
			ClientCommand(client, "cl_glow_item_r 1.0");
			
			ClientCommand(client, "cl_glow_survivor_hurt_g 0.0");	
			
			ClientCommand(client, "cl_glow_survivor_vomit_b 0.72");
			ClientCommand(client, "cl_glow_survivor_vomit_g 0.07");
			ClientCommand(client, "cl_glow_survivor_vomit_r 0.79");
			
			ClientCommand(client, "cl_glow_infected_b 1.0");
			ClientCommand(client, "cl_glow_infected_g 0.5");
			ClientCommand(client, "cl_glow_infected_r 0.0");
			
			ClientCommand(client, "cl_glow_survivor_b 1.0");
			ClientCommand(client, "cl_glow_survivor_g 0.5");
			ClientCommand(client, "cl_glow_survivor_r 0.5");
		}
	}
	return Plugin_Continue;
}

public Action:TimerStart(client)
{
	CreateTimer(1.0, Glow1, client, TIMER_REPEAT);
	CreateTimer(2.0, Glow2, client, TIMER_REPEAT);
}