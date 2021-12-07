/*/////////////////////////////////////////////////////////////////////////////////////////
		История версий ML Glow:
///////////////////////////////////////////////////////////////////////////////////////////
1.0:		-Первый релиз. Glow Q1 тема взята из l4d community autoexec 2.2f.
1.1:		-Добавлена D1 тема, активируется кваром ml_glow 2.
1.2:		-Квар ml_glow 0 теперь ставит тему по умолчанию.*/
	 
#define DEFAULT	0
#define Q1		1
#define D1		2
#define USER	3

new Handle:MLGlow=INVALID_HANDLE;

	public Plugin:myinfo = 
	{
		name = "[L4D] Must Live Glow",
		author = "Pontifex",
		description = "",
		version = "1.2",
		url = "http://must-live.ru"
	}

	public OnPluginStart()
	{
		MLGlow = CreateConVar("ml_glow", "1", "0 - default, 1 - Q1 glow, 2 - D1 glow", FCVAR_PLUGIN|FCVAR_NOTIFY);
	}


	public OnClientPutInServer(client)
	{	
	if (client)
		{
			CreateTimer(1.0, Glow1, client, TIMER_REPEAT);
			CreateTimer(2.0, Glow2,client, TIMER_REPEAT);
		}
	}
	
	public Action:Glow1(Handle:timer, any:client)  
	{
		if(!IsClientInGame(client)) return;
		
		switch (GetConVarInt(MLGlow))
		{
			case DEFAULT:
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
			}
				
			case Q1:
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
				
			case D1:
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

	}
	
	public Action:Glow2(Handle:timer, any:client)  
	{
		if(!IsClientInGame(client)) return;
		
		switch (GetConVarInt(MLGlow))
		{
			case DEFAULT:
			{
				ClientCommand(client, "cl_glow_item_far_b 1.0");
				ClientCommand(client, "cl_glow_item_far_g 0.4");
				ClientCommand(client, "cl_glow_item_far_r 0.3");
			}
			
			case Q1:
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
			
			case D1:
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
		
	}