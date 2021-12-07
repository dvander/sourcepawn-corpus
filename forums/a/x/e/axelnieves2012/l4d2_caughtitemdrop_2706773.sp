/* Plugin Version History
* 1.0 - Public release
* 1.1 - renamed cvar descriptions
*/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define MODEL_V_FIREAXE "models/weapons/melee/v_fireaxe.mdl"
#define MODEL_V_FRYING_PAN "models/weapons/melee/v_frying_pan.mdl"
#define MODEL_V_MACHETE "models/weapons/melee/v_machete.mdl"
#define MODEL_V_BASEBALL_BAT "models/weapons/melee/v_bat.mdl"
#define MODEL_V_CROWBAR "models/weapons/melee/v_crowbar.mdl"
#define MODEL_V_CRICKET_BAT "models/weapons/melee/v_cricket_bat.mdl"
#define MODEL_V_TONFA "models/weapons/melee/v_tonfa.mdl"
#define MODEL_V_KATANA "models/weapons/melee/v_katana.mdl"
#define MODEL_V_ELECTRIC_GUITAR "models/weapons/melee/v_electric_guitar.mdl"
#define MODEL_V_GOLFCLUB "models/weapons/melee/v_golfclub.mdl"
#define MODEL_V_DUALPISTOLS "models/v_models/v_dualpistols.mdl"
#define MODEL_V_PISTOL "models/v_models/v_pistol.mdl"

#define PLUGIN_VERSION "1.2"
#define TIMER_THIS_MAP	(TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE)

public Plugin myinfo =
{
	name = "L4D2 Caught Item Drop",
	author = "kwski43 aka Jacklul, Axel Juan Nieves",
	description = "Survivors drop their current held item when caught by special infected.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1252856"
}

//Main functionality cvars
ConVar cvarAdvertDelay;
ConVar cvarShowInfo;

ConVar cvarDropOnHunter;
ConVar cvarDropOnSmoker;
ConVar cvarDropOnCharger;
ConVar cvarDropOnJockey;
bool g_bL4d2;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	if ( test == Engine_Left4Dead2 )
		g_bL4d2 = true;
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d2_ciw_version", PLUGIN_VERSION, "Caught Item Drop Version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	LoadTranslations("l4d2_caughtitemdrop.phrases");
	
	char s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if ( g_bL4d2 )
	{
		//Main cvars
		cvarAdvertDelay = CreateConVar("l4d2_ciw_adsdelay", "15.0", "Advertisements after round start delay? 0-disable", 0, true, 0.0, true, 120.0);
		cvarShowInfo = CreateConVar("l4d2_ciw_showinfo", "1", "Show info to players that they dropped item? 0-disabled, 1-chat, 2-hint", 0, true, 0.0, true, 1.0);
		cvarDropOnHunter = CreateConVar("l4d2_ciw_droponhunter", "1", "Drop Item when pounced?", 0, true, 0.0, true, 1.0);
		cvarDropOnSmoker = CreateConVar("l4d2_ciw_droponsmoker", "1", "Drop Item when dragged?", 0, true, 0.0, true, 1.0);
		cvarDropOnCharger = CreateConVar("l4d2_ciw_droponcharger", "1", "Drop Item when pummelled?", 0, true, 0.0, true, 1.0);
		cvarDropOnJockey = CreateConVar("l4d2_ciw_droponjockey", "1", "Drop Item when jockeyed?", 0, true, 0.0, true, 1.0);
		
		AutoExecConfig(true, "l4d2_caughtitemdrop");
		
		//Some infected attacks events
		HookEvent("charger_pummel_start", EventPlayerPummeled, EventHookMode_Post);
		HookEvent("jockey_ride", EventPlayerJockeyed, EventHookMode_Post);
	}
	else
	{
		//LogMessage("Detected Left4Dead!");
		//Main Cvars
		cvarAdvertDelay = CreateConVar("l4d_ciw_adsdelay", "15.0", "Advertisements after round start delay? 0-disable", 0, true, 0.0, true, 120.0);
		cvarShowInfo = CreateConVar("l4d_ciw_showinfo", "1", "Show info to players that they dropped item? 0-disabled, 1-chat, 2-hint", 0, true, 0.0, true, 1.0);
		cvarDropOnHunter = CreateConVar("l4d_ciw_droponhunter", "1", "Drop Item when pounced?", 0, true, 0.0, true, 1.0);
		cvarDropOnSmoker = CreateConVar("l4d_ciw_droponsmoker", "1", "Drop Item when dragged?", 0, true, 0.0, true, 1.0);
		
		AutoExecConfig(true, "l4d_caughtitemdrop");
	}
	
	HookEvent("tongue_grab", EventTongueGrab, EventHookMode_Post);
	HookEvent("lunge_pounce", EventPlayerPounced, EventHookMode_Post);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
}

public void Event_RoundFreezeEnd(Handle event, const char[] name, bool dontBroadcast)
{ 
	float fTime;
	if ( (fTime=GetConVarFloat(cvarAdvertDelay)) != 0.0)
	{
		CreateTimer(fTime, Advert, _, TIMER_THIS_MAP);
	}
}

public Action Advert(Handle timer)
{
	//You will drop current held item when caught by special infected
	PrintToChatAll("\x04[\x03CaughtItemDrop\x04]: \x01%t", "advert");
	return Plugin_Continue;
}

public void EventTongueGrab(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetConVarInt(cvarDropOnSmoker))
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

public void EventPlayerPounced(Handle event, char[] name, bool dontBroadcast)
{
	if (GetConVarInt(cvarDropOnHunter))
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

public void EventPlayerPummeled(Handle event, char[] name, bool dontBroadcast)
{
	if (GetConVarInt(cvarDropOnCharger))
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

public void EventPlayerJockeyed(Handle event, char[] name, bool dontBroadcast)
{
	if (GetConVarInt(cvarDropOnJockey))
	{
		int client = GetClientOfUserId(GetEventInt(event, "victim"));
		DropItem(client);
	}
}

//The following code is from l4d2_drop, http://forums.alliedmods.net/showthread.php?p=1136497
public void DropItem(int client)
{
	if (client == 0 || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
		return;

	char strWeapon[32];
	bool bDropped;
	GetClientWeapon(client, strWeapon, 32);

	if (StrEqual(strWeapon, "weapon_pumpshotgun") || StrEqual(strWeapon, "weapon_autoshotgun") || StrEqual(strWeapon, "weapon_rifle") || StrEqual(strWeapon, "weapon_smg") || StrEqual(strWeapon, "weapon_hunting_rifle") || StrEqual(strWeapon, "weapon_sniper_scout") || StrEqual(strWeapon, "weapon_sniper_military") || StrEqual(strWeapon, "weapon_sniper_awp") || StrEqual(strWeapon, "weapon_smg_silenced") || StrEqual(strWeapon, "weapon_smg_mp5") || StrEqual(strWeapon, "weapon_shotgun_spas") || StrEqual(strWeapon, "weapon_shotgun_chrome") || StrEqual(strWeapon, "weapon_rifle_sg552") || StrEqual(strWeapon, "weapon_rifle_desert") || StrEqual(strWeapon, "weapon_rifle_ak47") || StrEqual(strWeapon, "weapon_grenade_launcher") || StrEqual(strWeapon, "weapon_rifle_m60"))
		bDropped = DropSlot(client, 0);
	else if (StrEqual(strWeapon, "weapon_pistol") || StrEqual(strWeapon, "weapon_pistol_magnum") || StrEqual(strWeapon, "weapon_chainsaw") || StrEqual(strWeapon, "weapon_melee"))
		bDropped = DropSlot(client, 1);
	else if (StrEqual(strWeapon, "weapon_pipe_bomb") || StrEqual(strWeapon, "weapon_molotov") || StrEqual(strWeapon, "weapon_vomitjar"))
		bDropped = DropSlot(client, 2);
	else if (StrEqual(strWeapon, "weapon_first_aid_kit") || StrEqual(strWeapon, "weapon_defibrillator") || StrEqual(strWeapon, "weapon_upgradepack_explosive") || StrEqual(strWeapon, "weapon_upgradepack_incendiary"))
		bDropped = DropSlot(client, 3);
	else if (StrEqual(strWeapon, "weapon_pain_pills") || StrEqual(strWeapon, "weapon_adrenaline"))
		bDropped = DropSlot(client, 4);

	if ( bDropped )
	{
		if (GetConVarInt(cvarShowInfo)==1)
		{
			PrintToChat(client, "\x04[\x03CaughtItemDrop\x04]: \x01%t", "dropped");
		}
		else if (GetConVarInt(cvarShowInfo)==2)
		{
			PrintHintText(client, "%t", "dropped");
		}
	}
}

public bool DropSlot(int client, int slot)
{
	int iWeapon = GetPlayerWeaponSlot(client, slot);
	int iPistols;
	//PrintToChat(client, "iWeapon = %i", iWeapon);
	if ( iWeapon > -1 )
	{
		char strWeapon[32];
		int ammo;
		int clip;
		int upgrade;
		int upammo;
		int ammoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		GetEdictClassname(GetPlayerWeaponSlot(client, slot), strWeapon, sizeof(strWeapon));

		if (slot == 0)
		{
			clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
			if ( g_bL4d2 )
			{
				upgrade = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_upgradeBitVec");
				upammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
			}
			if (StrEqual(strWeapon, "weapon_rifle") || StrEqual(strWeapon, "weapon_rifle_sg552") || StrEqual(strWeapon, "weapon_rifle_desert") || StrEqual(strWeapon, "weapon_rifle_ak47"))
			{
				ammo = GetEntData(client, ammoOffset+(12));
				SetEntData(client, ammoOffset+(12), 0);
			}
			else if (StrEqual(strWeapon, "weapon_smg") || StrEqual(strWeapon, "weapon_smg_silenced") || StrEqual(strWeapon, "weapon_smg_mp5"))
			{
				ammo = GetEntData(client, ammoOffset+(20));
				SetEntData(client, ammoOffset+(20), 0);
			}
			else if (StrEqual(strWeapon, "weapon_pumpshotgun") || StrEqual(strWeapon, "weapon_shotgun_chrome"))
			{
				ammo = GetEntData(client, ammoOffset+(28));
				SetEntData(client, ammoOffset+(28), 0);
			}
			else if (StrEqual(strWeapon, "weapon_autoshotgun") || StrEqual(strWeapon, "weapon_shotgun_spas"))
			{
				ammo = GetEntData(client, ammoOffset+(32));
				SetEntData(client, ammoOffset+(32), 0);
			}
			else if (StrEqual(strWeapon, "weapon_hunting_rifle"))
			{
				ammo = GetEntData(client, ammoOffset+(36));
				SetEntData(client, ammoOffset+(36), 0);
			}
			else if (StrEqual(strWeapon, "weapon_sniper_scout") || StrEqual(strWeapon, "weapon_sniper_military") || StrEqual(strWeapon, "weapon_sniper_awp"))
			{
				ammo = GetEntData(client, ammoOffset+(40));
				SetEntData(client, ammoOffset+(40), 0);
			}
			else if (StrEqual(strWeapon, "weapon_grenade_launcher"))
			{
				ammo = GetEntData(client, ammoOffset+(68));
				SetEntData(client, ammoOffset+(68), 0);
			}
		}
		int entity = CreateEntityByName(strWeapon);
		float fOrigin[3];
		
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fOrigin);
		fOrigin[2] += 20.0;
		TeleportEntity(entity, fOrigin, NULL_VECTOR, NULL_VECTOR);

		if (slot == 1)
		{
			if (StrEqual(strWeapon, "weapon_melee"))
			{
				char strItem[150];
				GetEntPropString(GetPlayerWeaponSlot(client, 1), Prop_Data, "m_ModelName", strItem, sizeof(strItem));
				//PrintToChat(client, "%s", strItem);
				if (StrEqual(strItem, MODEL_V_FIREAXE))
				{
					DispatchKeyValue(entity, "model", MODEL_V_FIREAXE);
					DispatchKeyValue(entity, "melee_script_name", "fireaxe");
				}
				else if (StrEqual(strItem, MODEL_V_FRYING_PAN))
				{
					DispatchKeyValue(entity, "model", MODEL_V_FRYING_PAN);
					DispatchKeyValue(entity, "melee_script_name", "frying_pan");
				}
				else if (StrEqual(strItem, MODEL_V_MACHETE))
				{
					DispatchKeyValue(entity, "model", MODEL_V_MACHETE);
					DispatchKeyValue(entity, "melee_script_name", "machete");
				}
				else if (StrEqual(strItem, MODEL_V_BASEBALL_BAT))
				{
					DispatchKeyValue(entity, "model", MODEL_V_BASEBALL_BAT);
					DispatchKeyValue(entity, "melee_script_name", "baseball_bat");
				}
				else if (StrEqual(strItem, MODEL_V_CROWBAR))
				{
					DispatchKeyValue(entity, "model", MODEL_V_CROWBAR);
					DispatchKeyValue(entity, "melee_script_name", "crowbar");
				}
				else if (StrEqual(strItem, MODEL_V_CRICKET_BAT))
				{
					DispatchKeyValue(entity, "model", MODEL_V_CRICKET_BAT);
					DispatchKeyValue(entity, "melee_script_name", "cricket_bat");
				}
				else if (StrEqual(strItem, MODEL_V_TONFA))
				{
					DispatchKeyValue(entity, "model", MODEL_V_TONFA);
					DispatchKeyValue(entity, "melee_script_name", "tonfa");
				}
				else if (StrEqual(strItem, MODEL_V_KATANA))
				{
					DispatchKeyValue(entity, "model", MODEL_V_KATANA);
					DispatchKeyValue(entity, "melee_script_name", "katana");
				}
				else if (StrEqual(strItem, MODEL_V_ELECTRIC_GUITAR))
				{
					DispatchKeyValue(entity, "model", MODEL_V_ELECTRIC_GUITAR);
					DispatchKeyValue(entity, "melee_script_name", "electric_guitar");
				}
				else if (StrEqual(strItem, MODEL_V_GOLFCLUB))
				{
					DispatchKeyValue(entity, "model", MODEL_V_GOLFCLUB);
					DispatchKeyValue(entity, "melee_script_name", "golfclub");
				}
			}
			else if (StrEqual(strWeapon, "weapon_chainsaw"))
			{
				clip = GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iClip1");
			}
			else if ( StrEqual(strWeapon, "weapon_pistol") )
			{
				if ( GetEntProp(iWeapon, Prop_Send, "m_isDualWielding")>0 )
					iPistols = 2;
				else
					iPistols = 1;
			}
		}
		
		//drop current item, but only pistol...
		if ( iPistols==1 )
		{
			RemoveEntity(entity);
		}
		else if ( iPistols==2 )
		{
			DispatchSpawn(entity);
			ActivateEntity(entity);
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, slot));
			//give one pistol...
			SetCommandFlags("give", GetCommandFlags("give") & ~FCVAR_CHEAT);
			FakeClientCommand(client, "give %s", "pistol");
			SetCommandFlags("give", GetCommandFlags("give") | FCVAR_CHEAT);
		}
		else
		{
			DispatchSpawn(entity);
			ActivateEntity(entity);
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, slot));
		}

		if (slot == 0)
		{
			SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", ammo);
			SetEntProp(entity, Prop_Send, "m_iClip1", clip);
			if ( g_bL4d2 )
			{
				SetEntProp(entity, Prop_Send, "m_upgradeBitVec", upgrade);
				SetEntProp(entity, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", upammo);
			}
		}

		if (slot == 1)
		{
			if (StrEqual(strWeapon, "weapon_chainsaw"))
			{
				SetEntProp(entity, Prop_Send, "m_iClip1", clip);
			}
		}
	}
	
	if ( iPistols==1 )
		return false;
	else
		return true;
}

stock int IsValidClientInGame(int client)
{
	if (IsValidClientIndex(client))
	{
		if (IsClientInGame(client))
			return 1;
	}
	return 0;
}

stock int IsValidClientIndex(int index)
{
	if (index>0 && index<=MaxClients)
	{
		return 1;
	}
	return 0;
}