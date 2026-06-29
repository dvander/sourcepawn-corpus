#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1

//	Colors || Цвета                                                                                                                                                 
// 	http://www.stm.dp.ua/web-design/color-html.php                                         
// 	{цвет,цвет,цвет,прозрачность} || {color,color,color,transparent} "0 - 255"              
//  Grenade Trails (Fredd) https://forums.alliedmods.net/showthread.php?p=594091

#define pipeColor      {255,48,48,255}  // Firebrick1
#define molotovColor   {255,255,0,255}  // Yellow
#define vomiteColor    {50,205,50,255}  // LimeGreen
#define grenadeColor   {160,32,240,255} // Purple
#define tankrockColor  {255,0,255,255}  // Magenta
#define hunterColor	   {30,144,255,255} // DodgerBlue
#define chargerColor   {255,165,0,255}  // Orange

#define ZOMBIECLASS_HUNTER	  3
#define ZOMBIECLASS_CHARGER	  6

new Sprite1;
new Sprite2;

new Handle:TrailsProjectileEnabled;

public Plugin:myinfo =
{
    name = "Trails_Projectile",
    author = "Fredd, Mister Game Over",
    description = "Trails Projectile",
    version = "1.1",
    url = "https://vk.com/club151027520"
}

public OnPluginStart()
{
	TrailsProjectileEnabled	=	CreateConVar("trails_enables",	"1",	"Enables/Disables plugin",	FCVAR_NOTIFY|FCVAR_PLUGIN);		
	
	HookEvent("player_jump",  			ePlayer_Jump); 
	HookEvent("charger_carry_start",    eCharger_Carry_Start);
}
    
public OnMapStart()
{
    Sprite1 = PrecacheModel("materials/sprites/laserbeam.vmt");    
    Sprite2 = PrecacheModel("materials/sprites/glow.vmt");  	
}

// ищем действие которое нам нужно || List Entities (Projectile)
// https://developer.valvesoftware.com/wiki/List_of_L4D2_Entities
// pipe bomb projectile         || полёт бомбы
// molotov projectile           || полёт молотова
// grenade launcher projectile  || полёт гранаты
// vomitjar projectile          || полёт банки с желчью 
// tank rock                    || полёт камня
// charger  carry start         || при захвате игрока 
// hunter jump                  || прыжок охотника
// Float:2.0 = Time Live Trail  || время жизни трейла
		
public OnEntityCreated(Entity, const String:Classname[])
{
	if(GetConVarInt(TrailsProjectileEnabled) != 1)
		return;
		
	if(strcmp(Classname, "pipe_bomb_projectile") == 0)
    {
		switch(GetRandomInt(1,2))
		{
			case 1:
			{
				TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, Float:10.0, Float:10.0, 5,  pipeColor); 
				TE_SendToAll();   								
			}		
			case 2:
			{
				TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, Float:10.0, Float:10.0, 5,  pipeColor);
				TE_SendToAll();   								   								
			}
		}	
    }
	else if(strcmp(Classname, "molotov_projectile") == 0)
    {
		switch(GetRandomInt(1,2))
		{
			case 1:
			{
				TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, Float:10.0, Float:10.0, 5, molotovColor);
				TE_SendToAll();   								
			}		
			case 2:
			{
				TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, Float:10.0, Float:10.0, 5, molotovColor);
				TE_SendToAll();   								
			}
		}	
    }
	else if(strcmp(Classname, "vomitjar_projectile") == 0)
    {
		switch(GetRandomInt(1,2))
		{
			case 1:
			{
				TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, Float:10.0, Float:10.0, 5, vomiteColor);
				TE_SendToAll();   								
			}		
			case 2:
			{
				TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, Float:10.0, Float:10.0, 5, vomiteColor);
				TE_SendToAll();   								  								
			}
		}	
    }          
	else if(strcmp(Classname, "grenade_launcher_projectile") == 0)
    {
		switch(GetRandomInt(1,2))
		{
			case 1:
			{
				TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, Float:10.0, Float:10.0, 5,  grenadeColor);
				TE_SendToAll();   								
			}		
			case 2:
			{
				TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, Float:10.0, Float:10.0, 5,  grenadeColor);
				TE_SendToAll();   															
			}
		}	
    }   
	else if(strcmp(Classname, "tank_rock") == 0)
    {
		switch(GetRandomInt(1,2))
		{
			case 1:
			{
				TE_SetupBeamFollow(Entity, Sprite1, 0, Float:2.0, Float:10.0, Float:10.0, 5, tankrockColor);
				TE_SendToAll();   								
			}		
			case 2:
			{
				TE_SetupBeamFollow(Entity, Sprite2, 0, Float:2.0, Float:10.0, Float:10.0, 5, tankrockColor);
				TE_SendToAll();   								
			}
		}	
    }       
	return;
}

public ePlayer_Jump(Handle:hEvent, String:sEventName[], bool:bDontBroadcast) 
{
	static iClient;
	iClient  = GetClientOfUserId(GetEventInt(hEvent, "userid"));
   
	if(iClient < 1 || iClient > MaxClients)
        return;

	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
     
	if(GetClientTeam(iClient) == 3)
	{
        switch (GetEntProp(iClient, Prop_Send, "m_zombieClass")) 
        {	
			case ZOMBIECLASS_HUNTER:
			{
				switch(GetRandomInt(1,2))
				{
					case 1:
					{
						TE_SetupBeamFollow(iClient, Sprite1, 0, Float:0.4, Float:10.0, Float:10.0, 5, hunterColor);
						TE_SendToAll();   								
					}		
					case 2:
					{
						TE_SetupBeamFollow(iClient, Sprite2, 0, Float:0.4, Float:10.0, Float:10.0, 5, hunterColor);
						TE_SendToAll();  
					}
				}	
			}
		}	
    }       
}

public eCharger_Carry_Start(Handle:hEvent, String:sEventName[], bool:bDontBroadcast) 
{
	static iClient;
	iClient  = GetClientOfUserId(GetEventInt(hEvent, "userid"));
   
	if(iClient < 1 || iClient > MaxClients)
        return;

	if(!IsClientInGame(iClient) || !IsPlayerAlive(iClient))
		return;
     
	if(GetClientTeam(iClient) == 3)
	{
        switch (GetEntProp(iClient, Prop_Send, "m_zombieClass")) 
        {	
			case ZOMBIECLASS_CHARGER:
			{
				switch(GetRandomInt(1,2))
				{
					case 1:
					{
						TE_SetupBeamFollow(iClient, Sprite1, 0, Float:1.5, Float:10.0, Float:10.0, 5, chargerColor);
						TE_SendToAll();   								
					}		
					case 2:
					{
						TE_SetupBeamFollow(iClient, Sprite2, 0, Float:1.5, Float:10.0, Float:10.0, 5, chargerColor);
						TE_SendToAll();  
					}
				}	
			}
		}	
    }       
}		