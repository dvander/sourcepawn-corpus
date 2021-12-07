#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>

#pragma newdecls required

#define PLUGIN_VERSION "0.0.0"
public Plugin myinfo = {
	name = "[TF2] Assign Boss Healthbar",
	author = "nosoop",
	description = "Attempts to assign the boss healthbar to a player.",
	version = PLUGIN_VERSION,
	url = "https://github.com/nosoop/"
}

int g_iBossTarget = -1;

#include <sdktools>

enum TFBossHealthState {
	HealthState_Default = 0,
	HealthState_Healing
};

methodmap TFMonsterResource {
	property int Index {
		public get() {
			return EntRefToEntIndex(view_as<int>(this));
		}
	}
	
	property int BossHealthPercentageByte {
		public get() {
			return GetEntProp(this.Index, Prop_Send, "m_iBossHealthPercentageByte");
		}
		public set(int value) {
			value = value > 0xFF? 0xFF : value;
			value = value < 0? 0 : value;
			SetEntProp(this.Index, Prop_Send, "m_iBossHealthPercentageByte", value);
		}
	}
	
	property TFBossHealthState BossHealthState {
		public get() {
			int index = this.Index;
			return view_as<TFBossHealthState>(GetEntProp(index, Prop_Send, "m_iBossState"));
		}
		public set(TFBossHealthState value) {
			SetEntProp(this.Index, Prop_Send, "m_iBossState", value);
		}
	}
	
	/**
	 * Updates the monster resource health display to display the current health of the
	 * specified entity.
	 */
	public void LinkHealth(int entity) {
		int hEntity = EntRefToEntIndex(entity);
		
		if (IsValidEntity(hEntity)) {
			int iMaxHealth = GetEntProp(hEntity, Prop_Data, "m_iMaxHealth");
			
			// account for max unbuffed health on clients
			if (entity > 0 && entity <= MaxClients) {
				int resource = GetPlayerResourceEntity();
				if (IsValidEntity(resource)) {
					iMaxHealth = GetEntProp(resource, Prop_Send, "m_iMaxHealth", _, entity);
				}
			}
			
			int iHealth = GetEntProp(hEntity, Prop_Data, "m_iHealth");
			
			this.BossHealthPercentageByte = RoundToCeil(float(iHealth) / iMaxHealth * 255);
		}
	}
	
	/**
	 * Returns the first monster_resource entity, creating it if it doesn't exist.
	 */
	public static TFMonsterResource GetEntity(bool create = false) {
		int hMonsterResource = FindEntityByClassname(-1, "monster_resource");
		
		if (hMonsterResource == -1) {
			hMonsterResource = CreateEntityByName("monster_resource");
			
			if (hMonsterResource == -1) {
				DispatchSpawn(hMonsterResource);
			}
		}
		
		return view_as<TFMonsterResource>(EntIndexToEntRef(hMonsterResource));
	}
}


public void OnPluginStart() {
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_boss", SetBossHealthTarget, ADMFLAG_ROOT);
}

public Action SetBossHealthTarget(int client, int argc) {
	if (!argc) {
		return Plugin_Handled;
	}
	
	char target[MAX_NAME_LENGTH + 1];
	GetCmdArg(1, target, sizeof(target));
	
	int iTarget = FindTarget(client, target, false, false);
	
	if (iTarget != -1) {
		g_iBossTarget = iTarget;
	}
	
	SDKHook(client, SDKHook_PostThink, OnBossPostThink);
	
	return Plugin_Handled;
}

public void OnBossPostThink(int client) {
	if (client != g_iBossTarget) {
		SDKUnhook(client, SDKHook_PostThink, OnBossPostThink);
		g_iBossTarget = -1;
		
		SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", false);
	}
	
	if (!TF2_IsGameModeMvM()) {
		// non-MvM, use monster resource health bar
		TFMonsterResource.GetEntity(true).LinkHealth(client);
	} else if (!GetEntProp(client, Prop_Send, "m_bUseBossHealthBar")) {
		// MvM, display boss health bar if it isn't already
		SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", true);
	}
}

public void OnClientDisconnect(int client) {
	if (client == g_iBossTarget) {
		g_iBossTarget = -1;
	}
}

// Powerlord's MvM stock
stock bool TF2_IsGameModeMvM() {
	return GameRules_GetProp("m_bPlayingMannVsMachine")? true : false;
}
