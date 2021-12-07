#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <cstrike>

#define VERSION "v1.1"

new Handle:PSClientMessage = INVALID_HANDLE;
new Handle:PSWeaponUse = INVALID_HANDLE;
new Handle:PSWeaponName = INVALID_HANDLE;
new Handle:PSDamage = INVALID_HANDLE;
new Handle:PSDamageCheck = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "PreciseShot",
	author = "Xilver266 Steam: donchopo",
	description = "Force drop weapon client on shooting him in the hands",
	version = VERSION,
	url = "servers-cfg.foroactivo.com"
};

public OnPluginStart()
{
	AutoExecConfig(true, "plugin.preciseshot");
	CreateConVar("sm_preciseshot_version", VERSION, "PreciseShot", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	PSWeaponUse = CreateConVar("sm_psweaponuse", "0", "Use a specific weapon for make the drop function", _, true, 0.0, true, 1.0);
	PSWeaponName = CreateConVar("sm_psweaponname", "weapon_usp", "Specific weapon (Dependency: sm_psweaponuse)");
	PSDamageCheck = CreateConVar("sm_damagecheck", "1", "Damage to force drop weapon", _, true, 0.0, true, 1.0);	
	PSDamage = CreateConVar("sm_psdamage", "10", "Amount of damage to force drop weapon (Dependency: sm_psdamagecheck)");
	PSClientMessage = CreateConVar("sm_psclientmessage", "1", "Show messages to client", _, true, 0.0, true, 1.0);
	
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_TraceAttack, HookTraceAttack);
}

public IsValidClient(client) 
{ 
    if (!( 1 <= client <= MaxClients ) || !IsClientInGame(client)) 
        return false; 
     
    return true; 
}

public Action:HookTraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, HitGroup)
{
	if (IsValidClient(attacker))
	{
		new String:g_Weapon[32];
		GetClientWeapon(attacker, g_Weapon, sizeof(g_Weapon));
		
		new String:g_WeaponName[32];
		GetConVarString(PSWeaponName, g_WeaponName, sizeof(g_WeaponName));

		if (HitGroup == 4 || HitGroup == 5)
		{
			if (GetConVarBool(PSDamageCheck))
			{
				if (damage >= GetConVarInt(PSDamage))
				{
					if (GetConVarBool(PSWeaponUse))
					{
						if (StrEqual(g_Weapon, g_WeaponName))
						{
							FakeClientCommand(victim, "drop");
					
							if (GetConVarBool(PSClientMessage))
							{
								PrintToChat(victim, "\x04[SM PreciseShot] \x01The player \x04%N \x01have thrown thee the gun", attacker);
								PrintToChat(attacker, "\x04[SM PreciseShot] \x01You've thrown the gun of \x03%N", victim);
							}
							return Plugin_Continue;
						}	
					}
					else
					{
						FakeClientCommand(victim, "drop");
				
						if (GetConVarBool(PSClientMessage))
						{
							PrintToChat(victim, "\x04[SM PreciseShot] \x01The player \x04%N \x01have thrown thee the gun", attacker);
							PrintToChat(attacker, "\x04[SM PreciseShot] \x01You've thrown the gun of \x03%N", victim);
						}
						return Plugin_Continue;
					}
				}
			}
			else
			{
				if (GetConVarBool(PSWeaponUse))
				{
					if (StrEqual(g_Weapon, g_WeaponName))
					{
						FakeClientCommand(victim, "drop");
				
						if (GetConVarBool(PSClientMessage))
						{
							PrintToChat(victim, "\x04[SM PreciseShot] \x01The player \x04%N \x01have thrown thee the gun", attacker);
							PrintToChat(attacker, "\x04[SM PreciseShot] \x01You've thrown the gun of \x03%N", victim);
						}
						return Plugin_Continue;
					}				
				}
				else
				{
					FakeClientCommand(victim, "drop");
			
					if (GetConVarBool(PSClientMessage))
					{
						PrintToChat(victim, "\x04[SM PreciseShot] \x01The player \x04%N \x01have thrown thee the gun", attacker);
						PrintToChat(attacker, "\x04[SM PreciseShot] \x01You've thrown the gun of \x03%N", victim);
					}
					return Plugin_Continue;					
				}
			}
		}
	}
	return Plugin_Changed;
}
