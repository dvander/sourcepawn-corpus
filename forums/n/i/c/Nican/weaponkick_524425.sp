#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"

#define MAXWEAPON 25

static String:WeaponNames[MAXWEAPON][] = {"p228","scout","xm1014","mac10","aug","elite","fiveseven","ump45","sg550","galil","famas","usp","glock18","awp","mp5navy","m249","m3","m4a1","tmp","g3sg1","deagle","sg552","ak47","knife","p90" };

new Float:weapon_strengh[MAXWEAPON];
new Float:weapon_cl_strenght[MAXWEAPON][MAXPLAYERS];

public Plugin:myinfo = 
{
	name = "Weapon kick back",
	author = "Nican132",
	description = "Players will get thrown back depending on the waepon",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("player_hurt", DamageEvent);
	
	CreateConVar("sm_kickbabk_version", PLUGIN_VERSION, "Kickback Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegAdminCmd("sm_kickback_add", Command_add_weapon, ADMFLAG_KICK, "sm_kickback_add <#weaponname> [Float:strengh:150.0]");
	RegAdminCmd("sm_kickback_remove", Command_remove_weapon, ADMFLAG_KICK, "sm_kickback_remove <#weaponname>");
	
	RegAdminCmd("sm_client_kickback_add", Command_AddClient_KickBack, ADMFLAG_KICK, "sm_kickback_add <#weaponname> [Float:strengh:150.0]");
	//RegAdminCmd("sm_client_kickback_remove", Command_RemClient_KickBack, ADMFLAG_KICK, "sm_kickback_remove <#weaponname>");
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
		stren = 150.0;
	else {
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
		if(StrEqual(weapon, WeaponNames[i],false)){
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
		
	if(!IsPlayerAlive(client))
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

public Action:Command_AddClient_KickBack(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_client_kickback_add <#userid|name> <Weapon> <Float:stren=150>");
		return Plugin_Handled;
	}

	decl String:Player[64], String:Weapon[64];
	new Float:stren;
	
	GetCmdArg( 1, Player, sizeof( Player ) );
	GetCmdArg( 2, Weapon, sizeof( Weapon ) );
	
	if(args == 2)
		stren = 150.0;
	else {
	 	decl String:strenstring[32];
	 	GetCmdArg(3, strenstring, sizeof(strenstring));
		stren = StringToFloat(strenstring);		
	}
	
	new id = GetWeaponId(Weapon);
	if(id == 0){
		ReplyToCommand(client, "[SM] Weapon %s not found", Weapon);
		return Plugin_Handled;
	}

	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			Player,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		
		for (new i = 0; i < target_count; i++)
		{
			weapon_cl_strenght[ id ][ target_list[i] ] = stren;
			ReplyToCommand(client, "[SM] Set player: \"%N\" weaponID: %d to strenght %f", target_list[i], id, stren );
		}
		
	}

	return Plugin_Handled;
}

public Action:Command_RemClient_KickBack(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_client_kickback_remove <#userid|name> <Weapon>");
		return Plugin_Handled;
	}

	decl String:Player[64], String:Weapon[64];
	
	GetCmdArg( 1, Player, sizeof( Player ) );
	GetCmdArg( 2, Weapon, sizeof( Weapon ) );
	
	new id = GetWeaponId(Weapon);
	if(id == 0){
		ReplyToCommand(client, "[SM] Weapon %s not found", Weapon);
		return Plugin_Handled;
	}

	
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			Player,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		
		for (new i = 0; i < target_count; i++)
		{
			weapon_cl_strenght[ id ][ target_list[i] ] = 0.0;
			ReplyToCommand(client, "[SM] Removed player: \"%N\" weaponID: %d", target_list[i], id );
		}
		
	}

	return Plugin_Handled;
}