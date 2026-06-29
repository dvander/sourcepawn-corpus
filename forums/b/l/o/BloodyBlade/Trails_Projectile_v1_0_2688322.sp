#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"
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

int Sprite1 = 0, Sprite2 = 0;
ConVar TrailsProjectileEnabled;
bool bPluginOn = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public Plugin myinfo =
{
    name = "Trails_Projectile",
    author = "Fredd, Mister Game Over(edit. by BloodyBlade)",
    description = "Trails Projectile",
    version = PLUGIN_VERSION,
    url = "https://vk.com/club151027520"
}

public void OnPluginStart()
{
	CreateConVar("trails_projectile_version", PLUGIN_VERSION, "Trails_Projectile plugin version", CVAR_FLAGS|FCVAR_DONTRECORD);
	TrailsProjectileEnabled	= CreateConVar("trails_enables", "1", "Enables/Disables plugin", CVAR_FLAGS);
	TrailsProjectileEnabled.AddChangeHook(OnConVarPluginOnChange);
	AutoExecConfig(true, "trails_projectile");
}

public void OnConfigsExecuted()
{
	OnConVarPluginOnChange(null, "", "");
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	bPluginOn = TrailsProjectileEnabled.BoolValue;
}

public void OnMapStart()
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
// view_as<float>(2.0 = Time Live Trail  || время жизни трейла
		
public void OnEntityCreated(int Entity, const char[] Classname)
{
	if(bPluginOn)
	{
		if(strcmp(Classname, "pipe_bomb_projectile") == 0)
		{
			switch(GetRandomInt(1, 2))
			{
				case 1:
				{
					TE_SetupBeamFollow(Entity, Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5,  pipeColor); 
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5,  pipeColor);
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
					TE_SetupBeamFollow(Entity, Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, molotovColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, molotovColor);
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
					TE_SetupBeamFollow(Entity, Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, vomiteColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, vomiteColor);
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
					TE_SetupBeamFollow(Entity, Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5,  grenadeColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5,  grenadeColor);
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
					TE_SetupBeamFollow(Entity, Sprite1, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, tankrockColor);
					TE_SendToAll();
				}
				case 2:
				{
					TE_SetupBeamFollow(Entity, Sprite2, 0, view_as<float>(2.0), view_as<float>(10.0), view_as<float>(10.0), 5, tankrockColor);
					TE_SendToAll();
				}
			}
		}
	}
}
