#include <sdktools>
#include <tf2items>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

ConVar cvarHealthOnHit,
	cvarUpgradeOnHit,
	cvarMetalMult,
	cvarAmmoOnHit,
	cvarNoUpgrade,
	cvarNoHealing,
	cvarNoAmmo;

int HealthOnHit = 50,
	UpgradeOnHit = 25,
	AmmoOnHit = 40,
	Noupgradelogic = 0,
	Nohealinglogic = 0,
	Noammologic = 0,
	abscount = 0;

int eventsMass[512];
bool constructMass[512];

char MetalMult[6] = "2.0";

#define PLUGIN_VERSION "1.3.0"

public Plugin myinfo = {
   name = "Pyrogineer REX",
   author = "Ordimary made by Blinx, Powered by Увеселитель",
   description = "Lets pyros upgrade friendly engineer buildings",
   version = PLUGIN_VERSION,
   url = "https://forums.alliedmods.net/showthread.php?t=325658"
}

public void OnPluginStart()
{
	CreateConVar("sm_pyrogineer_rex_version", PLUGIN_VERSION,
	"The version of the Pyrogineer REX plugin.", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED);
	
	AddNormalSoundHook(view_as<NormalSHook>(Hook_EntitySound));

	cvarHealthOnHit = CreateConVar("sm_pyrogineer_healthonhit", "50", "How much health a building recieves per hit", FCVAR_NONE, true, 0.0);
	cvarUpgradeOnHit = CreateConVar("sm_pyrogineer_upgradeonhit", "25", "How much upgrade a building recieves per hit", FCVAR_NONE, true, 0.0, true, 199.0);
	cvarAmmoOnHit = CreateConVar("sm_pyrogineer_ammoonhit", "40", "How much ammo a building recieves per hit", FCVAR_NONE, true, 0.0);
	cvarMetalMult = CreateConVar("sm_pyrogineer_metalmult", "2.0", "Multiplier for Pyrogineer metal pool, default is 100, thus a value of 2.0 yields a 200 metal pool", FCVAR_NONE, true, 0.0);
	cvarNoUpgrade = CreateConVar("sm_pyrogineer_noupgrade", "0", "Deny pyromans to upgrade buldings", FCVAR_NONE, true, 0.0);
	cvarNoHealing = CreateConVar("sm_pyrogineer_nohealing", "0", "Deny pyromans to heal buldings", FCVAR_NONE, true, 0.0);
	cvarNoAmmo = CreateConVar("sm_pyrogineer_noammo", "0", "Deny pyromans to give ammo to sentries", FCVAR_NONE, true, 0.0);

	cvarHealthOnHit.AddChangeHook(CvarChange);
	cvarUpgradeOnHit.AddChangeHook(CvarChange);
	cvarAmmoOnHit.AddChangeHook(CvarChange);
	cvarMetalMult.AddChangeHook(CvarChange);
	cvarNoUpgrade.AddChangeHook(CvarChange);
	cvarNoHealing.AddChangeHook(CvarChange);
	cvarNoAmmo.AddChangeHook(CvarChange);
	
	HookEvent("player_builtobject", Event_BuiltObject);
	HookEvent("object_destroyed", Event_ObjectDestroyed, EventHookMode_Pre);
	HookEvent("object_removed", Event_ObjectDestroyed, EventHookMode_Pre);
	HookEvent("player_carryobject", Event_ObjectDestroyed, EventHookMode_Pre);
	HookEvent("teamplay_round_win", OnRoundEnd);
	
	for (int i = 0; i < 512; i++)
	{
		eventsMass[i] = -1;
		constructMass[i] = false;
	}
}

public void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == cvarHealthOnHit) HealthOnHit = StringToInt(newValue);
	else if (convar == cvarUpgradeOnHit) UpgradeOnHit = StringToInt(newValue);
	else if (convar == cvarAmmoOnHit) AmmoOnHit = StringToInt(newValue);
	else if (convar == cvarMetalMult) strcopy(MetalMult, sizeof(MetalMult), newValue);
	else if (convar == cvarNoUpgrade) Noupgradelogic = StringToInt(newValue);
	else if (convar == cvarNoHealing) Nohealinglogic = StringToInt(newValue);
	else if (convar == cvarNoAmmo) Noammologic = StringToInt(newValue);
}

public Action Event_BuiltObject(Handle event, const char[] name, bool dontBroadcast)
{
	char classname[32];
	int ObjIndex = GetEventInt(event, "index");
	GetEdictClassname(ObjIndex, classname, sizeof(classname));
	if (StrContains(classname, "obj_teleporter", false) != -1)
	{		
		eventsMass[abscount] = ObjIndex;
		constructMass[abscount] = true;
		
		abscount++;
		if (abscount > 511)
		{
			for (int i = 0; i < 512; i++)
			{
				eventsMass[i] = -1;
				constructMass[i] = false;
			}
			abscount = 0;
		}
	}

	return Plugin_Continue;
}


public Action Event_ObjectDestroyed(Handle event, const char[] name, bool dontBroadcast)
{
	int ObjIndex = GetEventInt(event, "index");
	for (int i = 0; i < 512; i++)
	{
		if (eventsMass[i] == ObjIndex)
		{
			eventsMass[i] = -1;
			constructMass[i] = false;
			break;
		}
	}
		
	return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 0; i < 512; i++)
	{
		eventsMass[i] = -1;		
		constructMass[i] = false;
	}
	abscount = 0;	
}

public void OnConfigsExecuted()
{
	HealthOnHit = cvarHealthOnHit.IntValue;
	UpgradeOnHit = cvarUpgradeOnHit.IntValue;
	AmmoOnHit = cvarAmmoOnHit.IntValue;

	cvarMetalMult.GetString(MetalMult, sizeof(MetalMult));
	
	Noupgradelogic = cvarNoUpgrade.IntValue;
	Nohealinglogic = cvarNoHealing.IntValue;
	Noammologic = cvarNoAmmo.IntValue;
}

public Action Hook_EntitySound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (StrContains(sample, "cbar_hit1", false) != -1 || 
		StrContains(sample, "cbar_hit2", false) != -1 || 
		StrContains(sample, "neon_sign_hit_world_01", false) != -1 || 
		StrContains(sample, "neon_sign_hit_world_02", false) != -1 || 
		StrContains(sample, "neon_sign_hit_world_03", false) != -1 || 
		StrContains(sample, "neon_sign_hit_world_04", false) != -1) // When a Homewrecker or Neon sign sound goes off
	{
		float angles[3];
		float eyepos[3];
		GetClientEyeAngles(client, angles);
		GetClientEyePosition(client, eyepos);

		TR_TraceRayFilter(eyepos, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceRayDontHitSelf, client);
		int ent = TR_GetEntityIndex();

		if (IsValidEntity(ent))
		{
			float EntPos[3];
			float ClientPos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", EntPos);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);

			float Distance = GetVectorDistance(EntPos, ClientPos, false);
			if (Distance < 100.0)
			{
				if (!IsValidEntity(ent)) return Plugin_Continue;
				else
				{
					BuildingHit(ent, client);
					return Plugin_Continue;
				}
			}
		}
	}

	return Plugin_Continue;
}


public Action Timer_MetalHud(Handle timer, any client)
{
	if (IsValidClient(client) && 
		IsPlayerAlive(client) && 
		TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if (IsValidTarget(client))
		{
			Handle metalHudText = CreateHudSynchronizer();
			int metal = GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
			SetHudTextParams(0.6, 0.9, 1.0, 0, 0, 255, 255);
			ShowSyncHudText(client, metalHudText, "Metal: %i", metal);
			metalHudText.Close();
		}

		CreateTimer(0.25, Timer_MetalHud, client);
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

void BuildingHit(int ent, int client)
{
	if (IsValidTarget(client)) //If using Homewrecker, Maul, or Neon Annihilator
	{
		char classname[32];
		GetEdictClassname(ent, classname, sizeof(classname));
		if ((StrContains(classname, "obj_dispenser", false) != -1 || StrContains(classname, "obj_sentry", false) != -1 || StrContains(classname, "obj_teleporter", false) != -1) && FindBuildingOwnerTeam(ent) == GetClientTeam(client))
		{
			if (GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") >= 1.0)
			{
				int health = GetEntProp(ent, Prop_Send, "m_iHealth");
				int maxhealth = GetEntProp(ent, Prop_Send, "m_iMaxHealth");
				int newhealth = maxhealth;
				
				bool isbuild = false;
				bool CurLogic = true;
				
				int metal = GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);				
				
				int secondtp = -1;
				if (StrEqual(classname, "obj_teleporter"))
				{						
					int owner;
					GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", owner);
					int ObjIndex = ent;
					for (int i = 0; i < 512; i++)
					{
						if (eventsMass[i] != -1 && eventsMass[i] != ObjIndex)
						{
							int checkclient;							
							GetEntPropEnt(eventsMass[i], Prop_Data, "m_hOwnerEntity", checkclient);
							if (checkclient == owner)
							{
								secondtp = eventsMass[i];
								isbuild = constructMass[i];
								break;
							}
						}
					}
				}
				
				if (Nohealinglogic != 0) CurLogic = false; 
				if (health < maxhealth && CurLogic) // Heal building
				{
					int metalcost = RoundToCeil(HealthOnHit * 0.5);
					if (metal >= metalcost) // Enough metal for a full hit
					{
						newhealth = health + HealthOnHit;
						if (newhealth  <= maxhealth) // If this hit won't make the building hp max level
						{
							SetEntProp(ent, Prop_Data, "m_iHealth", newhealth);
							SetEntProp(ent, Prop_Send, "m_iHealth", newhealth);
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - metalcost, _, 3);
						}
						else // If it will take the building to hp max level
						{
							SetEntProp(ent, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(ent, Prop_Send, "m_iHealth", maxhealth);
							metalcost = RoundToCeil((newhealth - maxhealth) * 0.5);
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - metalcost, _, 3);
						}
					}
					else // If you have less than 25 metal
					{
						newhealth = health + metal * 2;
						if (newhealth <= maxhealth) //If this hit won't make the building hp max level
						{
							SetEntProp(ent, Prop_Data, "m_iHealth", newhealth);
							SetEntProp(ent, Prop_Send, "m_iHealth", newhealth);
							SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 3);
						}
						else // if it will take the building to hp max level
						{
							SetEntProp(ent, Prop_Data, "m_iHealth", maxhealth);
							SetEntProp(ent, Prop_Send, "m_iHealth", maxhealth);
							metalcost = RoundToCeil((newhealth - maxhealth) * 0.5);
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - metalcost, _, 3);
						}					
					}
				}
				
				if (secondtp != -1 && GetEntPropFloat(secondtp, Prop_Send, "m_flPercentageConstructed") >= 1.0 && CurLogic)
				{
					health = GetEntProp(secondtp, Prop_Send, "m_iHealth");
					maxhealth = GetEntProp(secondtp, Prop_Send, "m_iMaxHealth");
					newhealth = maxhealth;
					if (health < maxhealth) // Heal building
					{
						int metalcost = RoundToCeil(HealthOnHit * 0.5);
						if (metal >= metalcost) // Enough metal for a full hit
						{
							newhealth = health + HealthOnHit;
							if (newhealth  <= maxhealth) // If this hit won't make the building hp max level
							{	
								SetEntProp(secondtp, Prop_Data, "m_iHealth", newhealth);
								SetEntProp(secondtp, Prop_Send, "m_iHealth", newhealth);
								SetEntProp(client, Prop_Send, "m_iAmmo", metal - metalcost, _, 3);
							}
							else // If it will take the building to hp max level
							{
	
								SetEntProp(secondtp, Prop_Data, "m_iHealth", maxhealth);
								SetEntProp(secondtp, Prop_Send, "m_iHealth", maxhealth);
								metalcost = RoundToCeil((newhealth - maxhealth) * 0.5);
								SetEntProp(client, Prop_Send, "m_iAmmo", metal - metalcost, _, 3);
							}
						}
						else // If you have less than 25 metal
						{
							newhealth = health + metal * 2;
							if (newhealth <= maxhealth) //If this hit won't make the building hp max level
							{
	
								SetEntProp(secondtp, Prop_Data, "m_iHealth", newhealth);
								SetEntProp(secondtp, Prop_Send, "m_iHealth", newhealth);
								SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 3);
							}
							else // if it will take the building to hp max level
							{
	
								SetEntProp(secondtp, Prop_Data, "m_iHealth", maxhealth);
								SetEntProp(secondtp, Prop_Send, "m_iHealth", maxhealth);
								metalcost = RoundToCeil((newhealth - maxhealth) * 0.5);
								SetEntProp(client, Prop_Send, "m_iAmmo", metal - metalcost, _, 3);
							}					
						}
					}
				}
				
				int buildlevel = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
				int buildmetal = GetEntProp(ent, Prop_Send, "m_iUpgradeMetal");

				metal = GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
				
				CurLogic = true;
				if (Noammologic !=0) CurLogic = false;
				if (StrEqual(classname, "obj_sentrygun") && CurLogic)
				{
					int shells = GetEntProp(ent, Prop_Send, "m_iAmmoShells");
					int maxammo = 150;

					if (buildlevel > 1) maxammo = 200;
					if (metal >= AmmoOnHit) // Enough metal for a full hit
					{
						if (shells + AmmoOnHit <= maxammo) // If this hit won't make the building ammo max level
						{
							SetEntProp(ent, Prop_Send, "m_iAmmoShells", shells + AmmoOnHit);
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - AmmoOnHit, _, 3);
						}
						else // If it will take the building to ammo max level
						{
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - (maxammo - shells), _, 3);
							SetEntProp(ent, Prop_Send, "m_iAmmoShells", maxammo);
						}
					}
					else // If you have less than 40 metal
					{
						if (shells + metal <= maxammo) // If this hit won't make the building ammo max level
						{
							SetEntProp(ent, Prop_Send, "m_iAmmoShells", shells + metal);
							SetEntProp(client, Prop_Send, "m_iAmmo", 0 , _, 3);
						}
						else // If it will take the building to ammo max level
						{
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - (maxammo - shells), _, 3);
							SetEntProp(ent, Prop_Send, "m_iAmmoShells", maxammo);
						}
					
					}
				}

				metal = GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);

				if (StrEqual(classname, "obj_sentrygun") && buildlevel == 3 && CurLogic)
				{
					int rockets = GetEntProp(ent, Prop_Send, "m_iAmmoRockets");
					int maxrockets = 36;

					if (metal >= 15) // Enough metal for a full hit
					{
						if (rockets + 15 <= maxrockets) // If this hit won't make the building ammo max level
						{
							SetEntProp(ent, Prop_Send, "m_iAmmoRockets", rockets + 15);
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - 15, _, 3);
						}
						else // If it will take the building to ammo max level
						{
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - (maxrockets - rockets), _, 3);
							SetEntProp(ent, Prop_Send, "m_iAmmoRockets", maxrockets);
						}
					}
					else // If you have less than 15 metal
					{
						if (rockets + metal <= maxrockets) // If this hit won't make the building ammo max level
						{
							SetEntProp(ent, Prop_Send, "m_iAmmoRockets", rockets + metal);
							SetEntProp(client, Prop_Send, "m_iAmmo", 0 , _, 3);
						}
						else // If it will take the building to ammo max level
						{
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - (maxrockets - rockets), _, 3);
							SetEntProp(ent, Prop_Send, "m_iAmmoRockets", maxrockets);
						}
					}
				}
				CurLogic = true;
				if (Noupgradelogic != 0) CurLogic = false;
				metal = GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
				int levelfix = GetEntProp(ent, Prop_Send, "m_iUpgradeMetalRequired");
				if (buildlevel < 3 && CurLogic) // Don't build up max level building
				{
					if (metal >= UpgradeOnHit) // Enough metal for a full hit
					{
						if (buildmetal+UpgradeOnHit < levelfix) // If this hit won't make the  building hit max upgrade level
						{
							SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", buildmetal + UpgradeOnHit);
							if (secondtp != -1)
							{	
								SetEntProp(secondtp, Prop_Send, "m_iUpgradeMetal", buildmetal + UpgradeOnHit);
							}
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - UpgradeOnHit, _, 3);
						}
						else // If it will take the building to max upgrade level (199)
						{	
							SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", 0);
							SetEntProp(ent, Prop_Send, "m_iHighestUpgradeLevel", buildlevel + 1);
							if (secondtp != -1)
							{	
								SetEntProp(secondtp, Prop_Send, "m_iUpgradeMetal", 0);
								SetEntProp(secondtp, Prop_Send, "m_iHighestUpgradeLevel", buildlevel + 1);
							}
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - (levelfix - buildmetal), _, 3);
						}
					}
					else // If you have less than 25 metal
					{
						if (buildmetal + metal < levelfix) // If this hit won't make the building hit max upg level
						{
							SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", buildmetal + metal);
							if (secondtp != -1)
							{	
								SetEntProp(secondtp, Prop_Send, "m_iUpgradeMetal", buildmetal + metal);
							}
							SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 3);
						}
						else // If it will make the building hit max upg level
						{	
							SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", 0);
							SetEntProp(ent, Prop_Send, "m_iHighestUpgradeLevel", buildlevel + 1);
							if (secondtp != -1)
							{	
								SetEntProp(secondtp, Prop_Send, "m_iUpgradeMetal", 0);
								SetEntProp(secondtp, Prop_Send, "m_iHighestUpgradeLevel", buildlevel + 1);
							}
							SetEntProp(client, Prop_Send, "m_iAmmo", metal - (levelfix - buildmetal), _, 3);
						}
					}
				}
				
				if (secondtp != -1 && GetEntPropFloat(secondtp, Prop_Send, "m_flPercentageConstructed") >= 1.0) isbuild = false;
				if (secondtp != -1 && isbuild)
				{	
					buildlevel = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
					buildmetal = GetEntProp(ent, Prop_Send, "m_iUpgradeMetal");
					int buildlevel2 = GetEntProp(secondtp, Prop_Send, "m_iUpgradeLevel");
					int buildmetal2 = GetEntProp(secondtp, Prop_Send, "m_iUpgradeMetal");
					
					if (buildlevel > buildlevel2)
					{
						SetEntProp(secondtp, Prop_Send, "m_iHighestUpgradeLevel", buildlevel);
						SetEntProp(secondtp, Prop_Send, "m_iUpgradeMetal", buildmetal);
						
					}
					else if (buildlevel < buildlevel2)
					{
						SetEntProp(ent, Prop_Send, "m_iHighestUpgradeLevel", buildlevel);
						SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", buildmetal);
						
					}
					else if (buildmetal > buildmetal2)
					{
						SetEntProp(secondtp, Prop_Send, "m_iUpgradeMetal", buildmetal);
					}
					else if (buildmetal < buildmetal2)
					{
						SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", buildmetal);
					}
					isbuild = true;
				}
			}
		}
	}
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client))
			return false;
	}
	return true;
}

bool IsValidTarget(int client)
{
	int PlayerWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int index = GetEntProp(PlayerWeapon, Prop_Send, "m_iItemDefinitionIndex");

	return index == 153 || index == 466 || index == 813 || index == 834;
}

Handle PrepareItemHandle(Handle hItem, char name[] = "", int index = -1, const char att[] = "", bool dontpreserve = false)
{
	static Handle hWeapon;
	int addattribs = 0;

	char weaponAttribsArray[32][32];
	int attribCount = ExplodeString(att, " ; ", weaponAttribsArray, 32, 32);

	int flags = OVERRIDE_ATTRIBUTES;
	if (!dontpreserve) flags |= PRESERVE_ATTRIBUTES;
	if (hWeapon == null) hWeapon = TF2Items_CreateItem(flags);
	else TF2Items_SetFlags(hWeapon, flags);

	if (hItem != null)
	{
		addattribs = TF2Items_GetNumAttributes(hItem);
		if (addattribs > 0)
		{
			for (int i = 0; i < 2 * addattribs; i += 2)
			{
				bool dontAdd = false;
				int attribIndex = TF2Items_GetAttributeId(hItem, i);

				for (int z = 0; z < attribCount+i; z += 2)
				{
					if (StringToInt(weaponAttribsArray[z]) == attribIndex)
					{
						dontAdd = true;
						break;
					}
				}

				if (!dontAdd)
				{
					IntToString(attribIndex, weaponAttribsArray[i+attribCount], 32);
					FloatToString(TF2Items_GetAttributeValue(hItem, i), weaponAttribsArray[i+1+attribCount], 32);
				}
			}

			attribCount += 2 * addattribs;
		}

		delete hItem;
	}

	if (name[0] != '\0')
	{
		flags |= OVERRIDE_CLASSNAME;
		TF2Items_SetClassname(hWeapon, name);
	}
	if (index != -1)
	{
		flags |= OVERRIDE_ITEM_DEF;
		TF2Items_SetItemIndex(hWeapon, index);
	}
	if (attribCount > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, (attribCount / 2));
		int i2 = 0;
		for (int i = 0; i < attribCount && i2 < 16; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i + 1]));
			i2++;
		}
	}
	else TF2Items_SetNumAttributes(hWeapon, 0);

	TF2Items_SetFlags(hWeapon, flags);
	return hWeapon;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &hItem)
{
	switch (iItemDefinitionIndex)
	{
		case 153, 466, 813, 834:
		{
			char MetalGiven[16] = "80 ; x.x";
			SetEntProp(client, Prop_Send, "m_iAmmo", 200, _, 3);
			CreateTimer(0.1, Timer_MetalHud, client, TIMER_FLAG_NO_MAPCHANGE);
			ReplaceString(MetalGiven, sizeof(MetalGiven), "x.x", MetalMult, false);

			Handle hItemOverride = PrepareItemHandle(hItem, _, _, MetalGiven); // 2x metal pool, default is 100
			if (hItemOverride)
			{
				hItem = hItemOverride;
				return Plugin_Changed;
			}
		}
	}

	return Plugin_Continue;
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity == data ? false : true;
}

int FindBuildingOwnerTeam(int ent)
{
	return GetClientTeam(GetEntPropEnt(ent, Prop_Send, "m_hBuilder"));
}