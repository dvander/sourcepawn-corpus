#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


#define PLUGIN_VERSION	"1.1"

#define TEAM_ALLIES 2
#define TEAM_AXIS 3


new Handle:g_version = INVALID_HANDLE;
new Handle:g_Rocket = INVALID_HANDLE;
new Handle:g_GrenadeSmoke = INVALID_HANDLE;
new Handle:g_GrenadeFrag = INVALID_HANDLE;
new Handle:g_RifleGrenade = INVALID_HANDLE;


new redColor[4] = {255, 25, 25, 150};
new greenColor[4] = {0, 255, 80, 150};

new g_BeamSprite;

static const String:g_szGrenadeTypes[][] =
{
	"rocket_bazooka",
	"rocket_pschreck",
	"grenade_frag_us",
	"grenade_frag_ger",
	"grenade_smoke_us",
	"grenade_smoke_ger",
	"grenade_riflegren_us",
	"grenade_riflegren_ger"	
};


public Plugin:myinfo = 
{
	name = "Dod Grenade Trails",
	author = "Andi67, Modif Micmacx",
	description = "Add Trails to Grenades and Rockets",
	version = PLUGIN_VERSION,
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=micmacx&description=&search=1"
}

public OnPluginStart()
{
	g_version = CreateConVar("dod_grenadetrails_version",PLUGIN_VERSION,"DOD GRENADETRAILS VERSION",FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_Rocket= CreateConVar("dod_grenadetrails_rocket", "1", "1 is on 0 is off", _ ,true, 0.0, true, 1.0);	
	g_GrenadeSmoke = CreateConVar("dod_grenadetrails_smokegrenade", "1", "1 is on 0 is off", _ ,true, 0.0, true, 1.0);
	g_GrenadeFrag = CreateConVar("dod_grenadetrails_fraggrenade", "1", "1 is on 0 is off", _ ,true, 0.0, true, 1.0);	
	g_RifleGrenade = CreateConVar("dod_grenadetrails_riflegrenade", "1", "1 is on 0 is off", _ ,true, 0.0, true, 1.0);	
	AutoExecConfig(true, "dod_grenadetrails", "dod_grenadetrails")
}

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/crystal_beam1.vmt");
}

public OnPluginEnd()
{
	CloseHandle(g_version);
}

// SDKHooks Section
public OnEntityCreated(iEntity, const String:szEntityName[])
{
	for (new i = 0; i < sizeof(g_szGrenadeTypes); i++)
	{
		if (StrEqual(szEntityName, g_szGrenadeTypes[i]))
		{
			SDKHook(iEntity, SDKHook_Spawn, OnEntitySpawn);
			
			break;
		}
	}	
}

public OnEntitySpawn(iEntity)
{
	decl String:Classname[256];
	GetEdictClassname(iEntity, Classname, sizeof(Classname));
	
	if(GetConVarInt(g_Rocket) == 1)
	{
		if(StrEqual(Classname, "rocket_bazooka", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, greenColor);
			TE_SendToAll();
		}
		else if(StrEqual(Classname, "rocket_pschreck", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, redColor);
			TE_SendToAll();
		}
	}
	
	if(GetConVarInt(g_RifleGrenade) == 1)
	{	
		if(StrEqual(Classname, "grenade_riflegren_ger", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, redColor);
			TE_SendToAll();
		}
		else if(StrEqual(Classname, "grenade_riflegren_us", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, greenColor);
			TE_SendToAll();
		}
	}
	
	if(GetConVarInt(g_GrenadeFrag) == 1)
	{	
		if(StrEqual(Classname, "grenade_frag_ger", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, redColor);
			TE_SendToAll();
		}
		else if(StrEqual(Classname, "grenade_frag_us", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, greenColor);
			TE_SendToAll();
		}
	}
	
	if(GetConVarInt(g_GrenadeSmoke) == 1)
	{	
		if(StrEqual(Classname, "grenade_smoke_ger", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, redColor);
			TE_SendToAll();
		}
		else if(StrEqual(Classname, "grenade_smoke_us", false))
		{
			TE_SetupBeamFollow(iEntity, g_BeamSprite,	0, Float:2.0, Float:10.0, Float:10.0, 10, greenColor);
			TE_SendToAll();
		}
	}
}