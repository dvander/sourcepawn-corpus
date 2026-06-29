//-----------------------------------
//------------ Include --------------
//-----------------------------------
#include <sourcemod>
#include <sdktools>


//-----------------------------------
//----------- Var & def -------------
//-----------------------------------
#define EK_Version "1.0"
#define EK_Creator "iNex"
#define EK_Plugin_Name "He unlocker"
#define EK_Site "http://www.infire.com"
#define EK_desc "Retire la limite pour les grenades"
#define CS_TEAM_CT 3
#define CS_TEAM_T 2
#define CS_TEAM_SPECTATOR 1
#define CS_TEAM_NONE 0

//For unlock nades
new Handle:HeAmmo;
new Handle:SmokeAmmo;
new Handle:FlashAmmo;
new Handle:g_he_nombre;
new Handle:g_smoke_nombre;
new Handle:g_flash_nombre;
//-----------------------------------
//----------- Public var ------------
//-----------------------------------
public Plugin:myinfo =
{
	name = EK_Plugin_Name,
	author = EK_Creator,
	description = EK_desc,
	version = EK_Version,
	url = EK_Site
};

public OnPluginStart() 
{	
	//For unlock number of nades
	FlashAmmo = FindConVar("ammo_flashbang_max");
	g_flash_nombre = CreateConVar("sm_max_flash", "3", "debloque le nombre max de grenade");
	new FlashNombre = GetConVarInt(g_flash_nombre);
	SetConVarInt(FlashAmmo, FlashNombre);
	SmokeAmmo = FindConVar("ammo_smokegrenade_max");
	g_smoke_nombre = CreateConVar("sm_max_smoke", "2", "debloque le nombre max de grenade");
	new SmokeNombre = GetConVarInt(g_smoke_nombre);
	SetConVarInt(SmokeAmmo, SmokeNombre);
	HeAmmo = FindConVar("ammo_hegrenade_max");
	g_he_nombre = CreateConVar("sm_max_he", "3", "debloque le nombre max de grenade");
	new HeNombre = GetConVarInt(g_he_nombre);
	SetConVarInt(HeAmmo, HeNombre);
	AutoExecConfig(true, "Unlock_Nades");
}