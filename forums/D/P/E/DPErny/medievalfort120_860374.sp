//I must thank Sirot, because I used some of his code (from Zombie Fortress) for the really tricky parts.


#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#include <tf2>
 
public Plugin:myinfo =
{
	name = "Medieval Fortress",
	author = "DPErny",
	description = "Plugin makes TF2 play with a medieval theme",
	version = "1.2.0",
	url = "none"
};

new bool:mf_isActive = false;

public OnPluginStart()
{
	RegAdminCmd ("sm_mf_enable", command_Enable, ADMFLAG_CHANGEMAP);
	RegAdminCmd ("sm_mf_disable", command_Disable, ADMFLAG_CHANGEMAP);
}

public Action:command_Enable (client, args)
{
	if (mf_isActive == false)
	{
		ServerCommand ("mp_restartround 1");
		function_enable();
		change_class();
	}
}

public Action:command_Disable (client, args)
{
	if (mf_isActive == true)
	{
		function_disable();
		ServerCommand ("mp_restartround 1");
	}
}

public OnMapStart ()
{
	new String:map[256];
	GetCurrentMap(map, sizeof(map));

	if(mf_isActive == false)
	{
		if (StrContains(map, "mf_", false) != -1)
		{
			function_enable();	
		}
	}
}

public OnMapEnd ()
{
	if (mf_isActive == true)
	{
		function_disable();
	}
}

public function_enable()
{
	HookEvent ("player_spawn", Event_playerspawn);
	ServerCommand ("sm_cvar tf_max_health_boost 1.25");
	function_DisableResupply(true);
	mf_isActive = true;
	PrintCenterTextAll ("Medieval Fortress is now Enabled.")
	PrintToChatAll ("\x05In Medieval Fortress, the only classes allowed are: Pyro, Heavy, Medic, and Sniper. Please note that resupply cabinet is disabled.");
	PrintToChatAll ("\x05If you see any bugs, please go over to the ubercharged.net forums, and find the topic for Medieval Fortress Bug Reporting.");
}

public function_disable()
{
	UnhookEvent ("player_spawn", Event_playerspawn);
	ServerCommand ("sm_cvar tf_max_health_boost 1.5");
	function_DisableResupply(false);
	mf_isActive = false ;
}

public Action:change_class()
{	
	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			TF2_SetPlayerClass(i, TFClassType:2);
		}
	}
}

//This is one of the bits of code that I borrowed

function_DisableResupply(bool:activate) 
{
	new search = -1;
	if (activate == true)
	{
		while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
			AcceptEntityInput(search, "Disable");
	}
	else
	{
		while ((search = FindEntityByClassname(search, "func_regenerate")) != -1)
			AcceptEntityInput(search, "Enable");
	}
}
	

public Event_playerspawn (Handle:eventi, const String:name[], bool:dontBroadcast)
{
	new player = GetEventInt (eventi, "userid");
	new playeri = GetClientOfUserId (player);
	new TFClassType:class = TF2_GetPlayerClass (playeri);
	function_DisableResupply(true);

	if (class == TFClassType:6)
	{
		SetEntPropFloat(playeri, Prop_Send, "m_flMaxspeed", 270.0);

		TF2_RemoveWeaponSlot(playeri, 0);
		new weaponiii = GetPlayerWeaponSlot(playeri, 1);
		if (IsValidEntity(weaponiii))
		{
			if (GetEntProp(weaponiii, Prop_Send, "m_iEntityQuality") != 3)
			{
				TF2_RemoveWeaponSlot(playeri, 1);
			}
		}
		PrintToChat (playeri, "\x05The weapons allowed in the Heavy class are: melee and Sandvich. Your speed has been boosted to 90%.");
	}

	if (class == TFClassType:5)
	{
		TF2_RemoveWeaponSlot (playeri, 0);
		PrintToChat(playeri, "\x05The weapons allowed in the Medic class are: Healgun and melee");
	}

	if (class == TFClassType:7)
	{
		TF2_RemoveWeaponSlot(playeri, 0);
		new weaponiiii = GetPlayerWeaponSlot(playeri, 1);
		if (IsValidEntity(weaponiiii))
		{
			if (GetEntProp(weaponiiii, Prop_Send, "m_iEntityQuality") != 3)
			{
				TF2_RemoveWeaponSlot(playeri, 1);
			}
		}

		new weaponaxe = GetPlayerWeaponSlot(playeri, 2);
		if (IsValidEntity(weaponaxe))
		{
			if (GetEntProp(weaponaxe, Prop_Send, "m_iEntityQuality") == 3)
			{
				TF2_RemoveWeaponSlot(playeri, 2);
			}
		}


		PrintToChat(playeri, "\x05The weapons allowed in the Pyro class are: Flaregun and melee. You cannot have the Axetinguisher.");
	}

	if (class == TFClassType:2)
	{

		//This is another bit of Sirot's code (modified, for my purposes) that I used


		//Checks for unlocks
		new weaponi = GetPlayerWeaponSlot(playeri, 0);
		if (IsValidEntity(weaponi))
		{
			if (GetEntProp(weaponi, Prop_Send, "m_iEntityQuality") != 3)
			{
				TF2_RemoveWeaponSlot(playeri, 0);
			}
		}
		new weaponii = GetPlayerWeaponSlot(playeri, 1);
		if (IsValidEntity(weaponii))
		{
			if (GetEntProp(weaponii, Prop_Send, "m_iEntityQuality") != 3)
			{
				TF2_RemoveWeaponSlot(playeri, 1);
			}
		}
		PrintToChat (playeri, "\x05The weapons allowed in the Sniper Class are; Huntsman, Jarate/Razorback, and melee");
	}

	if ((class != TFClass_Heavy)&&(class != TFClass_Medic)&&(class != TFClass_Sniper)&&(class!= TFClass_Pyro))
	{
		PrintToChat(playeri, "\x05That is not an allowed class. The only classes allowed are: Sniper, Medic, Heavy, and Pyro.");
		TF2_SetPlayerClass(playeri, TFClassType:TFClass_Sniper);
		TF2_RespawnPlayer(playeri);

	}
}