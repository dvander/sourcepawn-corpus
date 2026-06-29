#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"
#define CVAR_FLAGS FCVAR_NOTIFY
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

bool bL4D2 = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine == Engine_Left4Dead)
	{
		bL4D2 = false;
	}
	else if(engine == Engine_Left4Dead2)
	{
		bL4D2 = true;
	}
	else
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
    name = "[L4D] Trails_Projectile",
    author = "Fredd, Mister Game Over(edit. by BloodyBlade)",
    description = "Trails Projectile",
    version = PLUGIN_VERSION,
    url = "https://vk.com/club151027520"
}

PluginData plugin;

enum struct PluginCvars
{
	ConVar TrailsProjectileEnabled;

	void Init()
	{
		CreateConVar("l4d_trails_projectile_version", PLUGIN_VERSION, "Trails_Projectile plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
		this.TrailsProjectileEnabled = CreateConVar("l4d_trails_projectile_enables", "1", "Enables/Disables plugin", CVAR_FLAGS);
		this.TrailsProjectileEnabled.AddChangeHook(OnConVarPluginOnChange);
		AutoExecConfig(true, "l4d_trails_projectile");
	}
}

enum struct PluginData
{
	PluginCvars cvars;
	bool bHooked;
	bool bPluginOn;
	int Sprite1;
	int Sprite2;

	void Init()
	{
		this.cvars.Init();
	}

	void IsAllowed()
	{
		this.bPluginOn = this.cvars.TrailsProjectileEnabled.BoolValue;
		if(!this.bHooked && this.bPluginOn)
		{
			this.bHooked = true;
			HookEvent("player_jump", Events); 
			if(bL4D2)
			{
				HookEvent("charger_carry_start", Events);
			}
		}
		else if(this.bHooked && !this.bPluginOn)
		{
			this.bHooked = false;
			UnhookEvent("player_jump", Events);
			if(bL4D2)
			{
				UnhookEvent("charger_carry_start", Events);
			}
		}
	}
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

public void OnMapStart()
{
    plugin.Sprite1 = PrecacheModel("materials/sprites/laserbeam.vmt");    
    plugin.Sprite2 = PrecacheModel("materials/sprites/glow.vmt");  	
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
// view_as<float>(2.0 = Time Live Trail  || время жизни трейла
		
public void OnEntityCreated(int Entity, const char[] Classname)
{
	if(plugin.bHooked)
	{
		if(strcmp(Classname, "pipe_bomb_projectile") == 0)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5,  pipeColor); 
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5,  pipeColor);
					TE_SendToAll();
				}
			}
		}
		else if(strcmp(Classname, "molotov_projectile") == 0)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, molotovColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, molotovColor);
					TE_SendToAll();
				}
			}
		}
		else if(strcmp(Classname, "vomitjar_projectile") == 0)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, vomiteColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, vomiteColor);
					TE_SendToAll();
				}
			}
		}
		else if(strcmp(Classname, "grenade_launcher_projectile") == 0)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5,  grenadeColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5,  grenadeColor);
					TE_SendToAll();
				}
			}
		}
		else if(strcmp(Classname, "tank_rock") == 0)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, tankrockColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, plugin.Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, tankrockColor);
					TE_SendToAll();
				}
			}
		}
	}
}

Action Events(Event event, char[] name, bool dontBroadcast)
{
	static int iClient;
	iClient = GetClientOfUserId(event.GetInt("userid"));
	if(bInfected(iClient))
	{
        if(GetEntProp(iClient, Prop_Send, "m_zombieClass") == ZOMBIECLASS_HUNTER)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					TE_SetupBeamFollow(iClient, plugin.Sprite1, 0, view_as<float>(0.4), view_as<float>(10.0), view_as<float>(10.0), 5, hunterColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(iClient, plugin.Sprite2, 0, view_as<float>(0.4), view_as<float>(10.0), view_as<float>(10.0), 5, hunterColor);
					TE_SendToAll();
				}
			}
		}
        else if(bL4D2 && GetEntProp(iClient, Prop_Send, "m_zombieClass") == ZOMBIECLASS_CHARGER)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					TE_SetupBeamFollow(iClient, plugin.Sprite1, 0, view_as<float>(1.5), view_as<float>(10.0), view_as<float>(10.0), 5, chargerColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(iClient, plugin.Sprite2, 0, view_as<float>(1.5), view_as<float>(10.0), view_as<float>(10.0), 5, chargerColor);
					TE_SendToAll();
				}
			}
		}
    }
	return Plugin_Continue;
}

bool bInfected(int iClient)
{
	return iClient > 0 && iClient <= MaxClients && IsClientInGame(iClient) && IsPlayerAlive(iClient) && GetClientTeam(iClient) == 3;
}
