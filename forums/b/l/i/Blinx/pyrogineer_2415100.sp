#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2items>
#include <tf2_stocks>
#include <tf2attributes>
#include <sdkhooks>
#include <morecolors>

new Handle:cvarHealthOnHit = INVALID_HANDLE;
new Handle:cvarUpgradeOnHit = INVALID_HANDLE;
new Handle:cvarMetalMult = INVALID_HANDLE;

new HealthOnHit = 50;
new UpgradeOnHit = 25;
new String:MetalMult[6] = "2.0";

public Plugin:myinfo = {
   name = "Pyrogineer",
   author = "Blinx",
   description = "Lets pyros upgrade friendly engineer buildings",
   version = "1.0.2"
}

public OnPluginStart()
{
	AddNormalSoundHook(NormalSHook:Hook_EntitySound);
	cvarHealthOnHit = CreateConVar("pyrogineer_healthonhit", "50", "How much health a building recieves per hit", FCVAR_NONE, true, 0.0);
	cvarUpgradeOnHit = CreateConVar("pyrogineer_upgradeonhit", "25", "How much upgrade a building recieves per hit", FCVAR_NONE, true, 0.0, true, 199.0);
	cvarMetalMult = CreateConVar("pyrogineer_metalmult", "2.0", "Multiplier for Pyrogineer metal pool, default is 100, thus a value of 2.0 yields a 200 metal pool", FCVAR_NONE, true, 0.0);
	
	HookConVarChange(cvarHealthOnHit, CvarChange);
	HookConVarChange(cvarUpgradeOnHit, CvarChange);
	HookConVarChange(cvarMetalMult, CvarChange);
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvarHealthOnHit)
		HealthOnHit = StringToInt(newValue);
	if (convar == cvarUpgradeOnHit)
		UpgradeOnHit = StringToInt(newValue);
	if (convar == cvarMetalMult)
		strcopy(MetalMult, sizeof(MetalMult), newValue);
}

public OnConfigsExecuted()
{
	HealthOnHit = GetConVarInt(cvarHealthOnHit);
	UpgradeOnHit = GetConVarInt(cvarUpgradeOnHit);
	GetConVarString(cvarMetalMult,MetalMult,sizeof(MetalMult));
}

public Action Hook_EntitySound(int clients[64],
  int &numClients,
  char sample[PLATFORM_MAX_PATH],
  int &client,
  int &channel,
  float &volume,
  int &level,
  int &pitch,
  int &flags,
  char soundEntry[PLATFORM_MAX_PATH],
  int &seed) //Yes, a sound hook is literally the best way to hook this event.
{
	if(StrContains(sample, "cbar_hit1", false) != -1
	|| StrContains(sample, "cbar_hit2", false) != -1
	|| StrContains(sample, "neon_sign_hit_world_01", false) != -1
	|| StrContains(sample, "neon_sign_hit_world_02", false) != -1
	|| StrContains(sample, "neon_sign_hit_world_03", false) != -1
	|| StrContains(sample, "neon_sign_hit_world_04", false) != -1) //When a Homewrecker or Neon sign sound goes off
	{
		new Float:angles[3];
		new Float:eyepos[3];
		GetClientEyeAngles(client, angles);
		GetClientEyePosition(client, eyepos);
				
		TR_TraceRayFilter(eyepos, angles, MASK_SOLID_BRUSHONLY, RayType_Infinite, TraceRayDontHitSelf, client);
		new ent = TR_GetEntityIndex();

		if (IsValidEntity(ent))
		{
			decl Float:EntPos[3];
			decl Float:ClientPos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", EntPos);
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", ClientPos);
			new Float:Distance = GetVectorDistance(EntPos, ClientPos, false);
			if (Distance < 100.0) //Make sure they're close enough to the building, it's pretty easy to trigger the sound without being in range
			{
				if(!IsValidEntity(ent))
				{
					return Plugin_Continue;
				}
				else
				{
					//CPrintToChat(client, "Building Hit! Client:%d Entity:%d", client, ent);
					BuildingHit(ent, client);
					return Plugin_Continue;
				}
			}
		}
	}
	return Plugin_Continue;
}


public Action:Timer_MetalHud(Handle:timer, client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		new Handle:metalHudText = CreateHudSynchronizer();
		new metal = GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
		SetHudTextParams(0.6, 0.9, 1.0, 0, 0, 255, 255);
		ShowSyncHudText(client, metalHudText, "Metal: %i", metal);
		CloseHandle(metalHudText);
		CreateTimer(0.25, Timer_MetalHud, client);
		
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action:BuildingHit(ent, client) 
{
	new PlayerWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	new index = GetEntProp(PlayerWeapon, Prop_Send, "m_iItemDefinitionIndex");
	if (index == 153 || index == 466 || index == 813 || index == 834) //If using Homewrecker, Maul, or Neon Annihilator
	{
		decl String:classname[32];
		GetEdictClassname(ent, classname, sizeof(classname));
		if ((StrContains(classname, "obj_dispenser", false) != -1 || StrContains(classname, "obj_sentry", false) != -1) && (FindBuildingOwnerTeam(ent) == GetClientTeam(client)))
		{
			if  (GetEntPropFloat(ent, Prop_Send, "m_flPercentageConstructed") >= 1.0)
			{
				new health = GetEntProp(ent, Prop_Send, "m_iHealth");
				new maxhealth = GetEntProp(ent, Prop_Send, "m_iMaxHealth");
				new newhealth;
				
				if (health < maxhealth) //Heal building
				{
					newhealth = health+HealthOnHit;
					
					if (newhealth > maxhealth)
						newhealth = maxhealth;
					
					SetEntProp(ent, Prop_Data, "m_iHealth", newhealth);
					SetEntProp(ent, Prop_Send, "m_iHealth", newhealth);
					
					return Plugin_Continue;
				}
				new buildlevel = GetEntProp(ent, Prop_Send, "m_iUpgradeLevel");
				new buildmetal = GetEntProp(ent, Prop_Send, "m_iUpgradeMetal");
				new metal = GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
				
				//CPrintToChat(client, "UpgLevel: %i | UpgMetal: %i | My Metal: %i | Constructed: %f", buildlevel, buildmetal, metal, Pconstructed);
				
				if (buildlevel < 3) //Don't build up max level building
				{
					if (metal >= UpgradeOnHit) //Enough metal for a full hit
					{
						if (buildmetal+UpgradeOnHit < 199) //If this hit won't make the  building hit max upgrade level
						{
							SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", buildmetal+UpgradeOnHit);
							SetEntProp(client, Prop_Send, "m_iAmmo", metal-UpgradeOnHit, _, 3);
								
							return Plugin_Continue;
						}
						else if (buildmetal+UpgradeOnHit >= 199) // if it will take the building to max upgrade level (199)
						{
							SetEntProp(client, Prop_Send, "m_iAmmo", metal-(199-buildmetal), _, 3);
							SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", 199);
								
							return Plugin_Continue;
						}
					}
					else //if you have less than 25 metal
					{
						if (buildmetal+metal < 199) //If this hit won't make the building hit max upg level
						{
							SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", buildmetal+metal);
							SetEntProp(client, Prop_Send, "m_iAmmo", 0, _, 3);
							
							return Plugin_Continue;
						}
						else //If it will make the building hit max upg level
						{
							SetEntProp(client, Prop_Send, "m_iAmmo", metal-(199-buildmetal), _, 3);
							SetEntProp(ent, Prop_Send, "m_iUpgradeMetal", 199);
								
							return Plugin_Continue;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock IsValidClient(client, bool:replaycheck = true)
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

stock Handle:PrepareItemHandle(Handle:hItem, String:name[] = "", index = -1, const String:att[] = "", bool:dontpreserve = false)
{
	static Handle:hWeapon;
	new addattribs = 0;

	new String:weaponAttribsArray[32][32];
	new attribCount = ExplodeString(att, " ; ", weaponAttribsArray, 32, 32);

	new flags = OVERRIDE_ATTRIBUTES;
	if (!dontpreserve) flags |= PRESERVE_ATTRIBUTES;
	if (hWeapon == INVALID_HANDLE) hWeapon = TF2Items_CreateItem(flags);
	else TF2Items_SetFlags(hWeapon, flags);
//	new Handle:hWeapon = TF2Items_CreateItem(flags);	//INVALID_HANDLE;
	if (hItem != INVALID_HANDLE)
	{
		addattribs = TF2Items_GetNumAttributes(hItem);
		if (addattribs > 0)
		{
			for (new i = 0; i < 2 * addattribs; i += 2)
			{
				new bool:dontAdd = false;
				new attribIndex = TF2Items_GetAttributeId(hItem, i);
				for (new z = 0; z < attribCount+i; z += 2)
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
		CloseHandle(hItem);	//probably returns false but whatever
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
		TF2Items_SetNumAttributes(hWeapon, (attribCount/2));
		new i2 = 0;
		for (new i = 0; i < attribCount && i2 < 16; i += 2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(weaponAttribsArray[i]), StringToFloat(weaponAttribsArray[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(hWeapon, 0);
	}
	TF2Items_SetFlags(hWeapon, flags);
	return hWeapon;
}

public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	switch (iItemDefinitionIndex)
	{
		case 153, 466, 813, 834:
		{	
			new String:MetalGiven[16] = "80 ; x.x";
			SetEntProp(client, Prop_Send, "m_iAmmo", 200, _, 3);
			CreateTimer(0.1, Timer_MetalHud, client, TIMER_FLAG_NO_MAPCHANGE);
			ReplaceString(MetalGiven, sizeof(MetalGiven), "x.x", MetalMult, false);
				
			new Handle:hItemOverride = PrepareItemHandle(hItem, _, _, MetalGiven); // 2x metal pool, default is 100
			if (hItemOverride != INVALID_HANDLE)
			{
				hItem = hItemOverride;
				
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    if(entity == data)
        return false;

    return true;
}

stock FindBuildingOwnerTeam(ent)
{
	new owner = GetEntPropEnt(ent, Prop_Send, "m_hBuilder");
	new ownerteam = GetClientTeam(owner);
	return ownerteam;
}