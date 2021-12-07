#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = {
	name = "Projectile Camera",
	author = "lugui",
	description = "Watch the path of projectiles.",
	version = "1.1.0",
}

bool projectileCamEnabled[MAXPLAYERS+1];
int observedEntRef[MAXPLAYERS+1];

public OnPluginStart() {
	RegAdminCmd("sm_pc", Command_projectileCamera, ADMFLAG_ROOT, "Projectile Camera");
    for(int i = 1; i < MaxClients; i ++){
        observedEntRef[i] = -1;
    }
}


public Action Command_projectileCamera(client, args){
	projectileCamEnabled[client] = !projectileCamEnabled[client];
	ReplyToCommand(client, "Projectile Camera %s", projectileCamEnabled[client]? "enabled" : "disabled");
}

public void OnClientDisconnect (int client) {
    projectileCamEnabled[client] = false;
    observedEntRef[client] = 0;
}

public void OnEntityCreated(int entity, const char[] classname) {
	if(IsValidEntity(entity)) {
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawn);
	}
}

public OnEntitySpawn(int entity) {
    int iOwner = 0;
    observedEntRef[iOwner] = -1;
    if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity")){
        iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    } else if (HasEntProp(entity, Prop_Send, "m_hOwner")) {
        iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwner");
    } else if (HasEntProp(entity, Prop_Send, "m_hThrower")) {
        iOwner = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
    }
    
    if(!isValidClient(iOwner) || !projectileCamEnabled[iOwner]){
        return;
    }

    observedEntRef[iOwner] = EntIndexToEntRef(entity);
    SDKUnhook(entity, SDKHook_SpawnPost, OnEntitySpawn);
}

public OnGameFrame() {
    for(int client = 1; client < MaxClients; client++){
        if(!projectileCamEnabled[client] || !isValidClient(client) || !IsPlayerAlive(client)){
            continue;
        }

        int buttons = GetClientButtons(client);
        if(buttons & IN_RELOAD) {
            setClientToProjectileiew(client);
        } else {
            setClientToClientView(client);
        }
    }
}

void setClientToProjectileiew(int client) {
    int ent = EntRefToEntIndex(observedEntRef[client]);
    if(IsValidEntity(ent)){
        SetClientViewEntity(client, ent);
    } else {
        setClientToClientView(client);
    }
}

void setClientToClientView(int client) {
    SetClientViewEntity(client, client);
}



stock bool isValidClient(int client, bool allowBot = false) {
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsClientSourceTV(client) || (!allowBot && IsFakeClient(client) ) ){
		return false;
	}
	return true;
}