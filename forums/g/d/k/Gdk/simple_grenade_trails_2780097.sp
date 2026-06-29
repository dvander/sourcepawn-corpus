#pragma semicolon 1 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

Handle g_h_plugin_enabled = INVALID_HANDLE;
Handle g_h_trail_time = INVALID_HANDLE;
Handle g_h_trail_width_start = INVALID_HANDLE;
Handle g_h_trail_width_end = INVALID_HANDLE;
Handle g_h_he_color = INVALID_HANDLE;
Handle g_h_flash_color = INVALID_HANDLE;
Handle g_h_smoke_color = INVALID_HANDLE;
Handle g_h_molotov_color = INVALID_HANDLE;
Handle g_h_decoy_color = INVALID_HANDLE;
Handle g_h_default_color = INVALID_HANDLE;

int g_laser_sprite;
int g_nade_color[4] = {255, 255, 255, 255};

char g_projectiles[6][32] = {"flashbang_projectile", "hegrenade_projectile", "snowball_projectile", "smokegrenade_projectile", "decoy_projectile", "molotov_projectile"};

#define RED   	{255, 000, 000, 255}
#define BLUE	{000, 000, 255, 255}
#define GREEN	{000, 255, 000, 255}
#define PURPLE	{145, 000, 255, 255}
#define WHITE	{255, 255, 255, 255}
#define ORANGE  {255, 175, 000, 255}
#define YELLOW  {255, 255, 000, 255}
#define TEAL    {000, 255, 255, 255}

public Plugin myinfo =
{
	name = "Simple Grenade Trails",
	author = "Gdk",
	description = "Trails for grenades",
	version = "1.0.2",
	url = "https://github.com/RavageCS/Simple-Grenade-Trails"
}

public void OnPluginStart() 
{
	g_h_plugin_enabled = CreateConVar("sm_sgt_enabled", "1", "Whether simple grenade trails is enabled");
	g_h_trail_time = CreateConVar("sm_sgt_trail_time", "8", "Number of seconds trails are visible");
	g_h_trail_width_start = CreateConVar("sm_sgt_trail_width_start", "2.0", "Width of grenade trails from starting point");
	g_h_trail_width_end = CreateConVar("sm_sgt_trail_width_end", "4.0", "Width of grenade trails at ending point");

	g_h_he_color = CreateConVar("sm_sgt_he_color", 		 "Red",  "HE trail color");
	g_h_flash_color = CreateConVar("sm_sgt_flash_color", 	 "Blue", "Flash trail color");
	g_h_smoke_color = CreateConVar("sm_sgt_smoke_color",	 "Green", "Smoke trail color");
	g_h_molotov_color = CreateConVar("sm_sgt_molotov_color", "Purple", "Molotov trail color");
	g_h_decoy_color = CreateConVar("sm_sgt_decoy_color",	 "White", "Decoy trail color");
	g_h_default_color = CreateConVar("sm_sgt_default_color", "White", "Any other trail color");
	
	AutoExecConfig(true, "simple_grenade_trails", "sourcemod");

	g_laser_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
} 

public void OnMapStart()
{
	g_laser_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
}

public OnEntityCreated(entity, const char[] classname)
{
	if(IsValidEdict(entity) && GetConVarBool(g_h_plugin_enabled))
	{
		if(IsGrenadeProjectile(classname))
		{
			SDKHook(entity, SDKHook_SpawnPost, OnGrenadeSpawnPost);			
		}
	}
}

void OnGrenadeSpawnPost(int entity)
{
	if(IsValidEntity(entity))
	{
		float trail_time = float(GetConVarInt(g_h_trail_time));
		int trail_fade_time = RoundToNearest(trail_time - 1.0);

		float trail_width_start = float(GetConVarInt(g_h_trail_width_start));
		float trail_width_end = float(GetConVarInt(g_h_trail_width_end));

		char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));

		if(GetConVarBool(g_h_plugin_enabled))
		{
			if(!IsModelPrecached("materials/sprites/laserbeam.vmt"))
			{
				g_laser_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");
			}
			if(StrEqual(classname, "hegrenade_projectile"))
			{
				SetColor(g_h_he_color);
			}
			else if(StrEqual(classname, "flashbang_projectile"))
			{
				SetColor(g_h_flash_color);
			}
			else if(StrEqual(classname, "smokegrenade_projectile"))
			{
				SetColor(g_h_smoke_color);			
			}
			else if(StrEqual(classname, "molotov_projectile"))
			{
				SetColor(g_h_molotov_color);
			}
			else if(StrEqual(classname, "decoy_projectile"))
			{
				SetColor(g_h_decoy_color);
			}
			else if(StrEqual(classname, "snowball_projectile"))
			{
				SetColor(g_h_default_color);
			}

			TE_SetupBeamFollow(entity, g_laser_sprite, 0, trail_time, trail_width_start, trail_width_end, trail_fade_time, g_nade_color);
			TE_SendToAll();
		}
	}
}

bool IsGrenadeProjectile(const char[] classname)
{
	for(int i = 0; i < sizeof(g_projectiles); i++)
	{
		if(StrEqual(classname, g_projectiles[i]))
			return true;
	}
	return false;
}

void SetColor(Handle cvar)
{
	char cvar_string[32];
	GetConVarString(cvar, cvar_string, sizeof(cvar_string));

	if(StrEqual(cvar_string, "red", false))
		g_nade_color = RED;
	else if(StrEqual(cvar_string, "blue", false))
    		g_nade_color = BLUE;
	else if(StrEqual(cvar_string, "green", false))
    		g_nade_color = GREEN;
	else if(StrEqual(cvar_string, "purple", false))
    		g_nade_color = PURPLE;
	else if(StrEqual(cvar_string, "white", false))
    		g_nade_color = WHITE;
	else if(StrEqual(cvar_string, "orange", false))
    		g_nade_color = ORANGE;
	else if(StrEqual(cvar_string, "yellow", false))
    		g_nade_color = YELLOW;
	else if(StrEqual(cvar_string, "teal", false))
    		g_nade_color = TEAL;
	else
    		g_nade_color = WHITE;
}
