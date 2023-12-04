#include <tf_custom_attributes>
#include <tf2utils>
#include <sdkhooks> // we don't actually use this except for the DMG_* defines
#include <dhooks>
#include <tempents_stocks>
#include <tf_damageinfo_tools>

public Plugin myinfo =
{
	name = "Explosive Market Gardener Upgrades",
	author = "stick",
	description = "Allows you to purchase an upgrade that adds explosive crits to your Market Gardener",
	version = "1.00",
	url = "http://twitter.com/stick_twt"
};

Handle g_DHookMeleeOnEntityHit;

// ConVar mg_max_upgrades;
ConVar mg_upgrade_radius;
ConVar mg_upgrade_damage;
ConVar mg_upgrade_cost;
 
public void OnPluginStart()
{
	// mg_max_upgrades = CreateConVar("mg_max_upgrades", "4", "Maximum amount of times explosive market gardener can be upgraded");
	mg_upgrade_radius = CreateConVar("mg_upgrade_radius", "75", "Amount to upgrade the radius by each upgrade tick");
	mg_upgrade_damage = CreateConVar("mg_upgrade_damage", "65", "Amount to upgrade the damage by each upgrade tick");
	mg_upgrade_cost = CreateConVar("mg_upgrade_cost", "400", "Amount each upgrade tick costs");

	Handle hGameConf = LoadGameConfigFile("tf2.cattr_starterpack");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.cattr_starterpack).");
	}

	g_DHookMeleeOnEntityHit = DHookCreateFromConf(hGameConf,
		"CTFWeaponBaseMelee::OnEntityHit()");
	
	delete hGameConf;

	RegConsoleCmd("sm_explosiveupgrade", CMD_ExplosiveUpgrade, "Buy a tick of explosive market gardener");
	RegConsoleCmd("sm_upgrade_mg", CMD_upgrade_mg, "Open menu to buy explosive market gardener");
	RegConsoleCmd("sm_mg_upgrade", CMD_upgrade_mg, "Open menu to buy explosive market gardener");
}

public void OnMapStart() {
	int ent = -1;
	while ((ent = FindEntityByClassname(ent, "*")) != -1) {
		if (TF2Util_IsEntityWeapon(ent) && TF2Util_GetWeaponSlot(ent) == TFWeaponSlot_Melee) {
			OnMeleeWeaponCreated(ent);
		}
	}
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (TF2Util_IsEntityWeapon(entity)) {
		SDKHook(entity, SDKHook_SpawnPost, OnWeaponSpawnPost);
	}
}

void OnWeaponSpawnPost(int weapon) {
	if (TF2Util_GetWeaponSlot(weapon) == TFWeaponSlot_Melee) {
		OnMeleeWeaponCreated(weapon);
	}
}

void OnMeleeWeaponCreated(int weapon) {
	DHookEntity(g_DHookMeleeOnEntityHit, true, weapon, .callback = MeleeOnEntityHit);
}

MRESReturn MeleeOnEntityHit(int weapon, Handle hParams) {
	int target = DHookGetParam(hParams, 1);
	int attacker = TF2_GetEntityOwner(weapon);
	
	if (attacker < 1 || attacker > MaxClients) {
		return MRES_Ignored;
	}	
	if (target < 1 || target > MaxClients) {
		return MRES_Ignored;
	}

	if (GetClientTeam(target) == GetClientTeam(attacker)) {
		return MRES_Ignored;
	}

	if (!TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping)) {
		return MRES_Ignored;
	}

	if (TF2CustAttr_GetInt(weapon, "explosive crits") != 0) {
		float vecShootPos[3];
		TF2Util_GetPlayerShootPosition(attacker, vecShootPos);
		
		TE_SetupTFExplosion(vecShootPos, .weaponid = TF_WEAPON_GRENADELAUNCHER, .entity = weapon,
				.particleIndex = FindParticleSystemIndex("ExplosionCore_MidAir"));
		TE_SendToAll();

		KeyValues attributes = TF2CustAttr_GetAttributeKeyValues(weapon);
		if (attributes) 
		{
			if (attributes.JumpToKey("explosive crits"))
			{
				char value[128];
				attributes.GetString(NULL_STRING, value, sizeof(value))
				int amountUpgraded = StringToInt(value);
				
				float radius = amountUpgraded * GetConVarFloat(mg_upgrade_radius);
				float damage = amountUpgraded * GetConVarFloat(mg_upgrade_damage);
				
				CTakeDamageInfo damageInfo = new CTakeDamageInfo(attacker, attacker, damage, DMG_BLAST | DMG_CRIT | DMG_ALWAYSGIB | DMG_USEDISTANCEMOD | DMG_HALF_FALLOFF | DMG_SLOWBURN, weapon, vecShootPos, vecShootPos, vecShootPos);
	
				CTFRadiusDamageInfo radiusInfo = new CTFRadiusDamageInfo(damageInfo, vecShootPos, radius);
				
				radiusInfo.Apply();
				
				delete radiusInfo;
				delete damageInfo;
				return MRES_Ignored;
				
			}
		}
	}
	return MRES_Ignored;
}

public Action CMD_upgrade_mg(int client, int args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		int weapon = GetPlayerWeaponSlot(client, 2);
		if(IsValidEntity(weapon) && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 416)) 
		{
			Panel upgrademenu = CreatePanel();
			SetPanelTitle(upgrademenu, "Upgrade Explosive Market Gardener")
			DrawPanelText(upgrademenu, " ")

			char buffer[512];

			Format(buffer, sizeof(buffer), "Costs %i per tick",  GetConVarInt(mg_upgrade_cost));
			DrawPanelText(upgrademenu, buffer);

			Format(buffer, sizeof(buffer), "Each tick adds %i radius and %i damage",  GetConVarInt(mg_upgrade_radius), GetConVarInt(mg_upgrade_damage));
			DrawPanelText(upgrademenu, buffer);

			DrawPanelText(upgrademenu, " ");

			char upgradeProgress[5];
			for (int i = 0; i < sizeof(upgradeProgress); i++)
			{
				upgradeProgress[i] = '-';
			}
			upgradeProgress[sizeof(upgradeProgress) - 1] = 0; //null terminator

			KeyValues attributes = TF2CustAttr_GetAttributeKeyValues(weapon);
			if (attributes) 
			{
				if (attributes.JumpToKey("explosive crits"))
				{
					char value[128];
					attributes.GetString(NULL_STRING, value, sizeof(value))
					int amount = StringToInt(value);
					for (int i = 0; i < amount; i++)
					{
						upgradeProgress[i] = '+';
					}
				}
			}
			delete attributes;
			
			Format(buffer, sizeof(buffer), "Upgrade Progress: %s", upgradeProgress);

			DrawPanelText(upgrademenu, buffer)
			DrawPanelText(upgrademenu, " ")
			SetPanelCurrentKey(upgrademenu, 6)
			DrawPanelItem(upgrademenu, "Upgrade")
			SetPanelCurrentKey(upgrademenu, 7)
			DrawPanelItem(upgrademenu, "Close")
			SendPanelToClient(upgrademenu, client, Handler_upgrademenu, MENU_TIME_FOREVER);

			// PrintToChatAll("hi");
			// SetRuntimeCustomAttribute(weapon, "explosive crits", "1");
		}
	}
    return Plugin_Continue;
}

public Action CMD_ExplosiveUpgrade(int client, int args)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		int weapon = GetPlayerWeaponSlot(client, 2);
		if(IsValidEntity(weapon) && (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 416)) 
		{
			int currentCash = getClientCash(client);

			if(currentCash < GetConVarInt(mg_upgrade_cost))
			{
				ReplyToCommand(client, "Not enought credits");
				return Plugin_Continue;
			}

			KeyValues attributes = TF2CustAttr_GetAttributeKeyValues(weapon);
			if (attributes) 
			{
				if (attributes.JumpToKey("explosive crits"))
				{
					char value[128];
					attributes.GetString(NULL_STRING, value, sizeof(value))
					int amount = StringToInt(value);
					if(amount < 4)
					{
						amount++;
						IntToString(amount, value, 128);
						SetRuntimeCustomAttribute(weapon, "explosive crits", value);
						setClientCash(client, currentCash - GetConVarInt(mg_upgrade_cost));
						ClientCommand(client, "play mvm/mvm_bought_upgrade");
					}
					else 
					{
						ReplyToCommand(client, "Max upgrade level reached");
					}
				}
			} 
			else 
			{
				SetRuntimeCustomAttribute(weapon, "explosive crits", "1");
				setClientCash(client, currentCash - GetConVarInt(mg_upgrade_cost));
				ClientCommand(client, "play mvm/mvm_bought_upgrade");
			}
			delete attributes;
		}
	}
	return Plugin_Continue;
}

public Handler_upgrademenu(Handle:panel, MenuAction:action, client, slot)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            if (slot == 6)
            {
				FakeClientCommand(client, "sm_explosiveupgrade");
				FakeClientCommand(client, "sm_upgrade_mg");
            }
			else if (slot == 7)
            {
            }
        }
    }
}

bool IsValidClient( int client ) 
{
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
		return false; 
	 
	return true; 
}

static void SetRuntimeCustomAttribute(int entity, const char[] attrib, const char[] value) {
	KeyValues attributes = TF2CustAttr_GetAttributeKeyValues(entity);
	if (!attributes) {
		attributes = new KeyValues("CustomAttributes");
	}
	
	attributes.SetString(attrib, value);
	TF2CustAttr_UseKeyValues(entity, attributes);
	delete attributes;
}

int FindParticleSystemIndex(const char[] name) {
	int particleTable, particleIndex;
	if ((particleTable = FindStringTable("ParticleEffectNames")) == INVALID_STRING_TABLE) {
		ThrowError("Could not find string table: ParticleEffectNames");
	}
	if ((particleIndex = FindStringIndex(particleTable, name)) == INVALID_STRING_INDEX) {
		ThrowError("Could not find particle index: %s", name);
	}
	return particleIndex;
}

getClientCash(client)
{
	return GetEntProp(client, Prop_Send, "m_nCurrency");
}

setClientCash(client, amount)
{
	SetEntProp(client, Prop_Send, "m_nCurrency", amount);
}