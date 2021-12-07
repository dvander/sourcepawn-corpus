/**
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:clientTimer[MAXPLAYERS + 1];

new MaxHealth[MAXPLAYERS + 1];
new MaxArmor[MAXPLAYERS + 1];

new Handle:cvarKullHealth;
new Handle:cvarKullArmor;
new Handle:cvarKullTick;
new Handle:cvarKullTickAmt;

new Handle:cvarAnubisHealth;
new Handle:cvarAnubisArmor;
new Handle:cvarAnubisTick;
new Handle:cvarAnubisTickAmt;

new Handle:cvarJaffaHealth;
new Handle:cvarJaffaArmor;
new Handle:cvarJaffaTick;
new Handle:cvarJaffaTickAmt;

new Handle:cvarSupportHealth;
new Handle:cvarSupportArmor;
new Handle:cvarSupportTick;
new Handle:cvarSupportTickAmt;

new Handle:cvarAssaultHealth;
new Handle:cvarAssaultArmor;
new Handle:cvarAssaultTick;
new Handle:cvarAssaultTickAmt;

new Handle:cvarScoutHealth;
new Handle:cvarScoutArmor;
new Handle:cvarScoutTick;
new Handle:cvarScoutTickAmt;

new String:modName[32];

#define PLUGIN_VERSION "1.01"

public Plugin:myinfo = {
	name = "SGTLS Hp & Armor",
	author = "Sense",
	description = "Sets default HP/Armor and provides HP/Armor regeneration",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};


public OnPluginStart() {

	cvarKullHealth = CreateConVar("sm_sgtls_hp_kullhealth", "200", "Total Kull Health (Def 200)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarKullArmor = CreateConVar("sm_sgtls_hp_kullarmor", "100", "Total Kull Armor (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarKullTick = CreateConVar("sm_sgtls_hp_kulltick", "1", "Time in seconds to count for each tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarKullTickAmt = CreateConVar("sm_sgtls_hp_kulltickamt", "3", "Amount of armor to regenerate per tick (Def 3)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarAnubisHealth = CreateConVar("sm_sgtls_hp_anubishealth", "150", "Total Anubis Health (Def 150)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAnubisArmor = CreateConVar("sm_sgtls_hp_anubisarmor", "75", "Total Anubis Armor (Def 75)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAnubisTick = CreateConVar("sm_sgtls_hp_anubistick", "1", "Time in seconds to count for each tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAnubisTickAmt = CreateConVar("sm_sgtls_hp_anubistickamt", "2", "Amount of armor to regenerate per tick (Def 2)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarJaffaHealth = CreateConVar("sm_sgtls_hp_jaffahealth", "125", "Total Jaffa Scout Health (Def 125)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarJaffaArmor = CreateConVar("sm_sgtls_hp_jaffaarmor", "50", "Total Jaffa Scout Armor (Def 50)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarJaffaTick = CreateConVar("sm_sgtls_hp_jaffatick", "1", "Time in seconds to count for each tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarJaffaTickAmt = CreateConVar("sm_sgtls_hp_jaffatickamt", "1", "Amount of armor to regenerate per tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarSupportHealth = CreateConVar("sm_sgtls_hp_supporthealth", "150", "Total Support Health (Def 150)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupportArmor = CreateConVar("sm_sgtls_hp_supportarmor", "100", "Total Support Armor (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupportTick = CreateConVar("sm_sgtls_hp_supporttick", "1", "Time in seconds to count for each tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarSupportTickAmt = CreateConVar("sm_sgtls_hp_supporttickamt", "3", "Amount of armor to regenerate per tick (Def 3)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarAssaultHealth = CreateConVar("sm_sgtls_hp_assaulthealth", "125", "Total Assault Health (Def 125)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAssaultArmor = CreateConVar("sm_sgtls_hp_assaultarmor", "75", "Total Assault Armor (Def 75)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAssaultTick = CreateConVar("sm_sgtls_hp_assaulttick", "1", "Time in seconds to count for each tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarAssaultTickAmt = CreateConVar("sm_sgtls_hp_assaulttickamt", "2", "Amount of armor to regenerate per tick (Def 2)", FCVAR_PLUGIN, true, 0.0, false, _);

	cvarScoutHealth = CreateConVar("sm_sgtls_hp_scouthealth", "100", "Total Scout Health (Def 100)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarScoutArmor = CreateConVar("sm_sgtls_hp_scoutarmor", "50", "Total Scout Armor (Def 50)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarScoutTick = CreateConVar("sm_sgtls_hp_scouttick", "1", "Time in seconds to count for each tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);
	cvarScoutTickAmt = CreateConVar("sm_sgtls_hp_scouttickamt", "1", "Amount of armor to regenerate per tick (Def 1)", FCVAR_PLUGIN, true, 0.0, false, _);

	AutoExecConfig(true, "plugin.sgtls.hp");
	CreateTimer(3.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed(Handle:timer) {
	LogMessage("[SGTLS Armor Regen] - Loaded");

	HookEvent("player_hurt", event_PlayerHurt);
	HookEvent("player_spawn", event_PlayerSpawn);
	GetGameFolderName(modName, sizeof(modName));
}

public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
  new m_iClassId = FindSendPropOffs("CPlayerResource", "m_iClassId");
  new ClientOffset = m_iClassId + (client * 4);
  new PlayerClass = GetEntData(46, ClientOffset);

	if (clientTimer[client] == INVALID_HANDLE && PlayerClass == 7) {
		clientTimer[client] = CreateTimer(GetConVarFloat(cvarKullTick), RegenTick, client, TIMER_REPEAT); 
	}

	if (clientTimer[client] == INVALID_HANDLE && PlayerClass == 6) {
		clientTimer[client] = CreateTimer(GetConVarFloat(cvarAnubisTick), RegenTick, client, TIMER_REPEAT); 
	}

	if (clientTimer[client] == INVALID_HANDLE && PlayerClass == 5) {
		clientTimer[client] = CreateTimer(GetConVarFloat(cvarJaffaTick), RegenTick, client, TIMER_REPEAT); 
	}

	if (clientTimer[client] == INVALID_HANDLE && PlayerClass == 3) {
		clientTimer[client] = CreateTimer(GetConVarFloat(cvarSupportTick), RegenTick, client, TIMER_REPEAT); 
	} 

	if (clientTimer[client] == INVALID_HANDLE && PlayerClass == 2) {
		clientTimer[client] = CreateTimer(GetConVarFloat(cvarAssaultTick), RegenTick, client, TIMER_REPEAT); 
	} 

	if (clientTimer[client] == INVALID_HANDLE && PlayerClass == 1) {
		clientTimer[client] = CreateTimer(GetConVarFloat(cvarScoutTick), RegenTick, client, TIMER_REPEAT); 
	} 

}

public Action:RegenTick(Handle:timer, any:client) {

	new clientHp = GetPlayerHealth(client);
	new clientArmor = GetPlayerArmor(client);
  new m_iClassId = FindSendPropOffs("CPlayerResource", "m_iClassId");
  new ClientOffset = m_iClassId + (client * 4);
  new PlayerClass = GetEntData(46, ClientOffset);

	if (PlayerClass == 7) {
		if (clientHp < GetConVarInt(cvarKullHealth)) {
			if (clientHp + GetConVarInt(cvarKullTickAmt) > GetConVarInt(cvarKullHealth)) {
				SetPlayerHealth(client, GetConVarInt(cvarKullHealth), true, true);
			} else {
				SetPlayerHealth(client, clientHp + GetConVarInt(cvarKullTickAmt), true, true);
			}
		} 
		if (clientArmor < GetConVarInt(cvarKullArmor)) {
			if (clientArmor + GetConVarInt(cvarKullTickAmt) > GetConVarInt(cvarKullArmor)) {
				SetPlayerArmor(client, GetConVarInt(cvarKullArmor), true, true);
			} else {
				SetPlayerArmor(client, clientArmor + GetConVarInt(cvarKullTickAmt), true, true);
			}
		} 
	}

	if (PlayerClass == 6) {
		if (clientHp < GetConVarInt(cvarAnubisHealth)) {
			if (clientHp + GetConVarInt(cvarAnubisTickAmt) > GetConVarInt(cvarAnubisHealth)) {
				SetPlayerHealth(client, GetConVarInt(cvarAnubisHealth), true, true);
			} else {
				SetPlayerHealth(client, clientHp + GetConVarInt(cvarAnubisTickAmt), true, true);
			}
		} 
		if (clientArmor < GetConVarInt(cvarAnubisArmor)) {
			if (clientArmor + GetConVarInt(cvarAnubisTickAmt) > GetConVarInt(cvarAnubisArmor)) {
				SetPlayerArmor(client, GetConVarInt(cvarAnubisArmor), true, true);
			} else {
				SetPlayerArmor(client, clientArmor + GetConVarInt(cvarAnubisTickAmt), true, true);
			}
		} 
	}

	if (PlayerClass == 5) {
		if (clientHp < GetConVarInt(cvarJaffaHealth)) {
			if (clientHp + GetConVarInt(cvarJaffaTickAmt) > GetConVarInt(cvarJaffaHealth)) {
				SetPlayerHealth(client, GetConVarInt(cvarJaffaHealth), true, true);
			} else {
				SetPlayerHealth(client, clientHp + GetConVarInt(cvarJaffaTickAmt), true, true);
			}
		} 
		if (clientArmor < GetConVarInt(cvarJaffaArmor)) {
			if (clientArmor + GetConVarInt(cvarJaffaTickAmt) > GetConVarInt(cvarJaffaArmor)) {
				SetPlayerArmor(client, GetConVarInt(cvarJaffaArmor), true, true);
			} else {
				SetPlayerArmor(client, clientArmor + GetConVarInt(cvarJaffaTickAmt), true, true);
			}
		} 
	}

	if (PlayerClass == 3) {
		if (clientHp < GetConVarInt(cvarSupportHealth)) {
			if (clientHp + GetConVarInt(cvarSupportTickAmt) > GetConVarInt(cvarSupportHealth)) {
				SetPlayerHealth(client, GetConVarInt(cvarSupportHealth), true, true);
			} else {
				SetPlayerHealth(client, clientHp + GetConVarInt(cvarSupportTickAmt), true, true);
			}
		} 
		if (clientArmor < GetConVarInt(cvarSupportArmor)) {
			if (clientArmor + GetConVarInt(cvarSupportTickAmt) > GetConVarInt(cvarSupportArmor)) {
				SetPlayerArmor(client, GetConVarInt(cvarSupportArmor), true, true);
			} else {
				SetPlayerArmor(client, clientArmor + GetConVarInt(cvarSupportTickAmt), true, true);
			}
		} 
	} 

	if (PlayerClass == 2) {
		if (clientHp < GetConVarInt(cvarAssaultHealth)) {
			if (clientHp + GetConVarInt(cvarAssaultTickAmt) > GetConVarInt(cvarAssaultHealth)) {
				SetPlayerHealth(client, GetConVarInt(cvarAssaultHealth), true, true);
			} else {
				SetPlayerHealth(client, clientHp + GetConVarInt(cvarAssaultTickAmt), true, true);
			}
		} 
		if (clientArmor < GetConVarInt(cvarAssaultArmor)) {
			if (clientArmor + GetConVarInt(cvarAssaultTickAmt) > GetConVarInt(cvarAssaultArmor)) {
				SetPlayerArmor(client, GetConVarInt(cvarAssaultArmor), true, true);
			} else {
				SetPlayerArmor(client, clientArmor + GetConVarInt(cvarAssaultTickAmt), true, true);
			}
		} 
	} 

	if (PlayerClass == 1) {
		if (clientHp < GetConVarInt(cvarScoutHealth)) {
			if (clientHp + GetConVarInt(cvarScoutTickAmt) > GetConVarInt(cvarScoutHealth)) {
				SetPlayerHealth(client, GetConVarInt(cvarScoutHealth), true, true);
			} else {
				SetPlayerHealth(client, clientHp + GetConVarInt(cvarScoutTickAmt), true, true);
			}
		} 
		if (clientArmor < GetConVarInt(cvarScoutArmor)) {
			if (clientArmor + GetConVarInt(cvarScoutTickAmt) > GetConVarInt(cvarScoutArmor)) {
				SetPlayerArmor(client, GetConVarInt(cvarScoutArmor), true, true);
			} else {
				SetPlayerArmor(client, clientArmor + GetConVarInt(cvarScoutTickAmt), true, true);
			}
		} 
	} 

}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.25, getMaxHealth, client);
	CreateTimer(0.25, getMaxArmor, client);
	CreateTimer(0.5, setSpawnData, client);
}

public Action:setSpawnData(Handle:timer, any:client) {
  new m_iClassId = FindSendPropOffs("CPlayerResource", "m_iClassId");
  new ClientOffset = m_iClassId + (client * 4);
  new PlayerClass = GetEntData(46, ClientOffset);
    
	if (PlayerClass == 7) {
			SetPlayerHealth(client, GetConVarInt(cvarKullHealth), true, true);
			SetPlayerArmor(client, GetConVarInt(cvarKullArmor), true, true);
	}

	if (PlayerClass == 6) {
			SetPlayerHealth(client, GetConVarInt(cvarAnubisHealth), true, true);
			SetPlayerArmor(client, GetConVarInt(cvarAnubisArmor), true, true);
	}

	if (PlayerClass == 5) {
			SetPlayerHealth(client, GetConVarInt(cvarScoutHealth), true, true);
			SetPlayerArmor(client, GetConVarInt(cvarScoutArmor), true, true);
	}

	if (PlayerClass == 3) {
			SetPlayerHealth(client, GetConVarInt(cvarSupportHealth), true, true);
			SetPlayerArmor(client, GetConVarInt(cvarSupportArmor), true, true);
	}

	if (PlayerClass == 2) {
			SetPlayerHealth(client, GetConVarInt(cvarAssaultHealth), true, true);
			SetPlayerArmor(client, GetConVarInt(cvarAssaultArmor), true, true);
	}

	if (PlayerClass == 1) {
			SetPlayerHealth(client, GetConVarInt(cvarScoutHealth), true, true);
			SetPlayerArmor(client, GetConVarInt(cvarScoutArmor), true, true);
	}
}

public Action:getMaxHealth(Handle:timer, any:client)
	MaxHealth[client] = GetPlayerHealth(client, true);

public OnClientDisconnect(client)
	if (clientTimer[client] != INVALID_HANDLE)
		KillClientTimer(client);

public OnMapEnd()
	KillClientTimer(_, true);

GetPlayerHealth(entity, bool:maxHealth=false) {
	if (maxHealth) {
			return GetEntData(entity, FindDataMapOffs(entity, "m_iMaxHealth"));
	}
	return GetEntData(entity, FindDataMapOffs(entity, "m_iHealth"));
}

SetPlayerHealth(entity, amount, bool:maxHealth=false, bool:ResetMax=false) {
	if (maxHealth) {
		if (ResetMax) {
			SetEntData(entity, FindDataMapOffs(entity, "m_iMaxHealth"), MaxHealth[entity], 4, true);
		} else {
			SetEntData(entity, FindDataMapOffs(entity, "m_iMaxHealth"), amount, 4, true);
		}
	}
	SetEntityHealth(entity, amount);
}

public Action:getMaxArmor(Handle:timer, any:client)
	MaxArmor[client] = GetPlayerArmor(client, true);

GetPlayerArmor(entity, bool:maxArmor=false) {
	if (maxArmor) {
			return GetEntData(entity, 4224);
	}
	return GetEntData(entity, 4224);
}

SetPlayerArmor(entity, amount, bool:maxArmor=false, bool:ResetMax=false) {
	if (maxArmor) {
		if (ResetMax) {
			SetEntData(entity, 4228, MaxArmor[entity], 4, true);
		} else {
			SetEntData(entity, 4228, amount, 4, true);
		}
	}
//	SetEntityHealth(entity, amount);
}

KillClientTimer(client=0, bool:all=false)
{
	if (all)
	{
		for (new i; i <= MAXPLAYERS; i++)
		{
			if (clientTimer[i] != INVALID_HANDLE)
			{
				KillTimer(clientTimer[client]);
				clientTimer[client] = INVALID_HANDLE;
			}
		}
		return;
	}

	KillTimer(clientTimer[client]);
	clientTimer[client] = INVALID_HANDLE;
}
