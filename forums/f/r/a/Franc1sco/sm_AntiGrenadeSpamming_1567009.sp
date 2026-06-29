
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1

#define VERSION "v1.2 hegrenade edition"

new g_WeaponParent;

new Handle:g_CvarF = INVALID_HANDLE;
new Handle:guns_max = INVALID_HANDLE;

new bool:Blocked = false;


public Plugin:myinfo = 
{
	name = "SM AntiGunSpam",
	author = "Franc1sco steam: franug",
	description = "prevent gun spamming",
	version = VERSION,
	url = "http://servers-cfg.foroactivo.com/"
};


public OnPluginStart()
{

	g_CvarF = CreateConVar("sm_AntiGunSpam", VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	guns_max = CreateConVar("sm_antigunspam_max", "40", "Number max of hegrenades on the ground allowed");

	g_WeaponParent = FindSendPropOffs("CBaseCombatWeapon", "m_hOwnerEntity");

	SetConVarString(g_CvarF, VERSION);

	HookConVarChange(g_CvarF, VersionChange);

	HookEventEx("round_start", Event_RoundStart, EventHookMode_Pre);

//        RegAdminCmd("sm_gunsinmap", Command_Showguns, ADMFLAG_SLAY); // this for admin command

        RegConsoleCmd("sm_gunsinmap", Command_Showguns); // this for public command

}

public OnEntityCreated(entity, const String:classname[])
{
  if (!Blocked)
  {
    if (entity > MaxClients && IsValidEntity(entity))
    {
        new entities;
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_hegrenade") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
                        {
					entities++;
                        }
		}
	}
	if (entities > GetConVarInt(guns_max))
        {
                new Handle:pack;
                CreateDataTimer(4.0, Checker, pack);
                WritePackCell(pack, entity);
        }
    }
  }
}

public VersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, VERSION);
}

public OnMapStart()
{
    Blocked = true;
    CreateTimer(5.0, UnBlock);
}

public Action:UnBlock(Handle:timer)
{
    Blocked = false;
}

public Action:Checker(Handle:timer, Handle:pack)
{
  if (!Blocked)
  {
   new entity;

   ResetPack(pack);
   entity = ReadPackCell(pack);

   new String:weapon[64];

   if ( IsValidEdict(entity) && IsValidEntity(entity) )
   {
	GetEdictClassname(entity, weapon, sizeof(weapon));
	if ( ( StrContains(weapon, "weapon_hegrenade") != -1 ) && GetEntDataEnt2(entity, g_WeaponParent) == -1 )
        {
			AcceptEntityInput(entity, "Kill");
        }
   }
  }
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    Blocked = true;
    CreateTimer(5.0, UnBlock);
}

public Action:Command_Showguns(client, args)
{
        new entities;
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=GetMaxClients();i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( ( StrContains(weapon, "weapon_hegrenade") != -1 ) && GetEntDataEnt2(i, g_WeaponParent) == -1 )
                        {
					entities++;
                        }
		}
	}
//        PrintToChat(client, "\x04[SM_AntiGunSpam] \x01Numero de granadas en el suelo: %i", entities); // in spanish (my own language)
        PrintToChat(client, "\x04[SM_AntiGunSpam] \x01Number of he grenades on the ground: %i", entities);
}

// si eres español y quieres aprender a hacer plugins entonces agregame
// mi steam es: franug