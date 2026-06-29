//sdk tools
#include <sourcemod>
#include <sdktools>

//plugin version
#define PLUGIN_VERSION "1.0.0"

//plugin info
public Plugin:myinfo = 
{
	name		= "Jackpf's HardCore Weapon Mod Mode",
	author		= "jackpf",
	description	= "HardCore weapon mod",
	version		= PLUGIN_VERSION,
	url			= "http://jackpf.co.uk"
}

//cvar handles
new Handle:HardCore_Weapons_Mod_Mode = INVALID_HANDLE;

//plugin setup
public OnPluginStart()
{
	//require Left 4 Dead 2
	decl String:Game[64];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "left4dead2", false))
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	
	//register cvars
	HardCore_Weapons_Mod_Mode = CreateConVar("l4d2_HardCore_Weapons_Mod_Mode", "0", "HardCore Weapons Mod Mode.", FCVAR_NOTIFY | FCVAR_PLUGIN);
	CreateConVar("l4d2_HardCore_Weapons_Mod_Version", PLUGIN_VERSION, "HardCore Weapons Mod version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);
	
	//event hooks
	HookEvent("round_start", HardCore_Weapons_Mod_Mode_Hook); //execute hardcore methods
	HookConVarChange(HardCore_Weapons_Mod_Mode, HardCore_Weapons_Mod_Mode_Hook2); //same as round start hook
}

//HardCore Weapon Mod hooks
public Action:HardCore_Weapons_Mod_Mode_Hook(Handle:event, const String:name[], bool:dontBroadcast)
{
	return HardCore_Weapons_Mode();
}
public HardCore_Weapons_Mod_Mode_Hook2(Handle:convar, const String:oldValue[], const String:newValue[])
{
	HardCore_Weapons_Mode();
}

Action:HardCore_Weapons_Mode()
{
	if(GetConVarInt(HardCore_Weapons_Mod_Mode) == 1)
	{
		for(new i = 0; i <= GetEntityCount(); i++)
		{
			decl String:EdictName[128];
			
			if(IsValidEntity(i))
			{
				GetEdictClassname(i, EdictName, sizeof(EdictName));
				
				if(StrContains(EdictName, "weapon_spawn", false) != -1)
				{
					DispatchKeyValue(i, "count", "1"); //set the pickup limit to 1 ;) (can be hard for earlier maps, since there are normally 2 weapon spawns in the saferoom)
				}
			}
		}	
	}
	
	return Plugin_Handled;
}