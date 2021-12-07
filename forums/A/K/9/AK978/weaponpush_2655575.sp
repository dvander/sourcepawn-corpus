#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2"

#define MAXWEAPON 1


static String:WeaponNames[MAXWEAPON][] = {"rifle"};
static String:WeaponNames2[MAXWEAPON][] = {"rifle_m60"};

new Float:weapon_strengh[MAXWEAPON];
new Float:weapon_cl_strenght[MAXWEAPON][MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "Weapon push infected",
	author = "AK978",
	description = "Weapon push infected",
	version = PLUGIN_VERSION,
};

public OnPluginStart()
{
	HookEvent("player_hurt", DamageEvent);
	
	CreateConVar("sm_kickbabk_version", PLUGIN_VERSION, "Kickback Version", 0|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	RegAdminCmd("sm_kickback_add", Command_add_weapon, ADMFLAG_KICK, "sm_kickback_add <#weaponname> [Float:strengh:150.0]");
	RegAdminCmd("sm_kickback_remove", Command_remove_weapon, ADMFLAG_KICK, "sm_kickback_remove <#weaponname>");
}

public OnClientConnected( client )
{
	for(new i = 0; i < MAXWEAPON; i++){
		weapon_cl_strenght[ i ][ client ] = 0.0;
	}
}

public Action:Command_remove_weapon(client, args){
	new String:weaponname[32];
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] sm_kickback_remove <#weaponname>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, weaponname, sizeof(weaponname));
	
	new id = GetWeaponId(weaponname);
	if(id >= 0){
		weapon_strengh[id] = 0.0;
	} else
		ReplyToCommand(client, "[SM] Weapon %s not found", weaponname);
	return Plugin_Handled;
}

public Action:Command_add_weapon(client, args){
	new Float:stren, String:weaponname[32];
	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] sm_kickback_add <#weaponname> [Float:strengh:150.0]");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, weaponname, sizeof(weaponname));
	
	if(args == 1)
	{
		stren = 150.0;
	}
	else 
	{
	 	decl String:strenstring[32];
	 	GetCmdArg(2, strenstring, sizeof(strenstring));
		stren = StringToFloat(strenstring);		
	}
	
	new id = GetWeaponId(weaponname);
	
	if(id >= 0){
		weapon_strengh[id] = stren;
		LogMessage("Weapon Kick: Weapon %s (%d) with force %f", weaponname, id, stren );
	} else
		ReplyToCommand(client, "[SM] Weapon %s not found", weaponname);
	
	return Plugin_Handled;
}

stock GetWeaponId(const String:weapon[]){
	for(new i = 0; i < MAXWEAPON; i++){
		if(StrEqual(weapon, WeaponNames[i],false)
		|| StrEqual(weapon, WeaponNames2[i],false)){
			return i;
		}
	}
	return -1;	
}

Float:GetWeaponStrenght( weaponid, client )
{
	if( weapon_cl_strenght[ weaponid ][ client ] > 0.0 )
		return weapon_cl_strenght[ weaponid ][ client ];

	return weapon_strengh[weaponid];
}

public Action:DamageEvent(Handle:event, const String:name[], bool:dontBroadcat)
{

	new String:Weapon[16];	
	GetEventString(event, "weapon", Weapon, 15);
	
	new id = GetWeaponId(Weapon);
	
	//LogMessage("WeaponKick: Damage event called: %s", Weapon);
	
	if(id == -1)
		return Plugin_Continue;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		
	if(GetClientTeam(client) == 2)
		return Plugin_Continue;
		
	new Float:stren = GetWeaponStrenght( id, attacker );
		
	if(stren == 0.0)
		return Plugin_Continue;
	
	new Float:vAngles[3], Float:vReturn[3];	
	//Sinse m_angEyeAngles or m_angEyeAngles[0] works, I am using the harsh number
	GetClientEyeAngles(attacker, vAngles);
	
	vReturn[0] = FloatMul( Cosine( DegToRad(vAngles[1])  ) , stren);
	vReturn[1] = FloatMul( Sine( DegToRad(vAngles[1])  ) , stren);
	vReturn[2] = FloatMul( Sine( DegToRad(vAngles[0])  ) , stren);
		
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vReturn);
	
	//LogMessage("Throwing player: %N with strenght: %f", client, stren );
	
	return Plugin_Continue;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}