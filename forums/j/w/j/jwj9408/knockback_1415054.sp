
/*

Description : Setting the weapon-knockback value with convar and the system take and find 'for - weaponname' to process to make knockback. 

*/
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "KnockBack",
	author = "Æç·Î¿ìÁî",
	description = "Weapon Knock Back",
	version = "1.0",
	url = ""
}

#define MAX_Weapon 28

new String:weaponKB[MAX_Weapon][2][256] = {
	{"knife", "30.0"},
	{"glock", "30.0"},
	{"usp", "40.0"},
	{"p228", "30.0"},
	{"deagle", "80.0"},
	{"elite", "50.0"},
	{"fiveseven", "40.0"},
	{"m3", "120.0"},
	{"xm1014", "110.0"},
	{"galil", "60.0"},
	{"ak47", "50.0"},
	{"scout", "100.0"},
	{"sg552", "100.0"},
	{"awp", "1800.0"},
	{"g3sg1", "200.0"},
	{"famas", "50.0"},
	{"m4a1", "50.0"},
	{"aug", "80.0"},
	{"sg550", "100.0"},
	{"mac10", "30.0"},
	{"tmp", "50.0"},
	{"mp5navy", "50.0"},
	{"ump45", "40.0"},
	{"p90", "60.0"},
	{"m249", "100.0"},
	{"flashbang", "2000.0"},
	{"hegrenade", "400.0"},
	{"smokegrenade", "2000.0"}
};

public OnPluginStart()
{
	CreateConVar("knockback_version", "1.0", "knockback plugin info cvar", FCVAR_REPLICATED | FCVAR_NOTIFY);
	HookEvent("player_hurt", Player_Hurt);
}
public Action:Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Client = GetClientOfUserId(GetEventInt(event, "userid"));
	new Attacker = GetClientOfUserId(GetEventInt(event, "Attacker"));
	if(AliveCheck(Client) == true && AliveCheck(Attacker) == true)
	{
		decl String:k_weapon[32];
		GetEventString(event, "weapon", k_weapon, 32);
		for(new i = 0; i < MAX_Weapon; i++)
		{
			if(StrEqual(weaponKB[i][0], k_weapon))
			{
				decl Float:Clientposition[3], Float:targetposition[3], Float:vector[3];
				GetClientEyePosition(Attacker, Clientposition);
				GetClientEyePosition(Client, targetposition);
				MakeVectorFromPoints(Clientposition, targetposition, vector);
				NormalizeVector(vector, vector);
				ScaleVector(vector, StringToFloat(weaponKB[i][1]));
				TeleportEntity(Client, NULL_VECTOR, NULL_VECTOR, vector);
				break;
			}
		}
	}
}
public bool:AliveCheck(Client)
{
	if(Client > 0 && Client <= MaxClients)
		if(IsClientConnected(Client) == true)
			if(IsClientInGame(Client) == true)
				if(IsPlayerAlive(Client) == true) return true;
				else return false;
			else return false;
		else return false;
	else return false;
}