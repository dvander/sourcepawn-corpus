#include <sdktools_functions>

int Max;

char l4d_Weapons[29][] =
{
	"weapon_pistol",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_pain_pills",
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_rifle_ak47",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_shotgun_spas",
	"weapon_shotgun_chrome",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_sniper_awp",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_rifle_m60",
	"weapon_pistol_magnum",
	"weapon_grenade_launcher",
	"weapon_chainsaw",
	"weapon_vomitjar",
	"weapon_adrenaline",
	"weapon_defibrillator",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_first_aid_kit"
};

public OnPluginStart() 
{
	switch ( GetEngineVersion() )
	{
		case Engine_Left4Dead : Max = 8;
		case Engine_Left4Dead2 : Max = 27;
		default : SetFailState("Made 4 L4D");
	}
	RegAdminCmd("sm_give_x", CommandGiveClient, ADMFLAG_SLAY, "sm_give_x <#userid|name> <Weapon Name>");
	HookEvent("player_first_spawn",E_F_S);
}

public Action CommandGiveClient(client, args) 
{
	if (args < 2)	// wrong inputs
	{
		ReplyToCommand(client, "[SM] Usage : sm_give_x <#userid|name> <Weapon Name>");
		return Plugin_Handled;
	}
	
	char Weapon[32];				// String to Store arg #2  
	char target[MAX_TARGET_LENGTH];	// String to Store arg #1

	/* This Function Is Supported by Sourcemod:*/
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		GetCmdArg(2, Weapon, 32);
		Apply2(target_list[i],Weapon);	
	}
	ShowActivity2(client, "[SM] ", "%s was Given %s", target_name , Weapon);
	return Plugin_Handled;
}

public E_F_S(Handle:event, const String:name[], bool:Broadcast) 
{
	new P = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !IsFakeClient(P) )
	{
		Apply2(P , l4d_Weapons[28]);					//Medkit
		Apply2(P , l4d_Weapons[GetRandomInt(0,Max)]);	//Random Item
	}
}

Apply2(int P , char[] WEAPON)
{
	if (IsClientInGame(P))
	{
		// This requires <sdktools_functions> :
		
		int K = CreateEntityByName(WEAPON);		
		if (K != -1)
		{
			DispatchSpawn(K);
			EquipPlayerWeapon(P,K); 
			FakeClientCommand(P, "use %s", WEAPON);
		}
	}
}


	