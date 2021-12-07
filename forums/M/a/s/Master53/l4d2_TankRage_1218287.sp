#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define ZOMBIECLASS_TANK 8
#define PLUGIN_VERSION "1.20.01"
new CuffColor[4] = {200, 50, 50, 255};
new Handle:CV_RAGEENABLE = INVALID_HANDLE;
new Handle:CV_REGENENABLE = INVALID_HANDLE;
new Handle:CV_REGENSCORE = INVALID_HANDLE;
new Handle:CV_DAMAGEMULTIPLYER = INVALID_HANDLE;
new Handle:CV_MAXTANKHEALTH = INVALID_HANDLE;
new Float:g_flStopping_dmgmult;
new g_iLaggedMovementO	= -1;
new g_iHPBuffO = -1;
new GameType:gamemod;
enum GameType {

	Game_L4D,

	Game_L4D2,
};
public Plugin:myinfo = {
	name = "L4D && L4D2 Tank Ranger Mod",
	author = "Master(D)",
	description = "When a tank is spawned he is instantly turned into ragemode",
	version = PLUGIN_VERSION,
	url = ""
}
public OnPluginStart() {
	get_L4D_Version();
	g_iHPBuffO = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	g_iLaggedMovementO = FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
	CreateConVar("sm_tankrage_version", PLUGIN_VERSION, "shows the version in which this plugin uses", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CV_REGENENABLE = CreateConVar("sm_rageenable","1", "enable = 1, disable = 0");
	CV_REGENSCORE = CreateConVar("sm_regenscore","50", "Default = 1");
	CV_RAGEENABLE = CreateConVar("sm_regenenable","1", "enable = 1, disable = 0");
	CV_DAMAGEMULTIPLYER = CreateConVar("sm_damagemulti","1.5", "Defalt = 1.5, Normal = 1.0,");
	CV_MAXTANKHEALTH = CreateConVar("sm_damagemulti","5000", "Defalt = 5000, Normal = 4000,");
	g_flStopping_dmgmult = 1.5;


	if (gamemod == Game_L4D2)
 {
		HookEvent("player_hurt", Event_PlayerHurt);
	} HookEvent("tank_spawn", Event_Tank_Spawn);
}
get_L4D_Version()
{

	new String: game_description[64];

	GetGameDescription(game_description, 64, true);

	if (StrContains(game_description, "L4D", false) != -1 || StrContains(game_description, "Left 4 Dead", false) != -1)
 {

		gamemod = Game_L4D;

	}  else 	if (StrContains(game_description, "L4D2", false) != -1 || StrContains(game_description, "Left 4 Dead2", false) != -1)
 {
		gamemod = Game_L4D2;

	}
}
public OnClientPutInServer(Client) {
	if (gamemod == Game_L4D)
 {
		if(GetConVarInt(CV_RAGEENABLE) == 1) {
			SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage)
		}
	}
}
public Action:OnTakeDamage(Client, &attacker, &inflictor, &Float:damage, &damageType) {
	if(GetConVarInt(CV_REGENENABLE) == 1) {
		if(GetClientTeam(Client) == 2) {
			if(IsPlayerTank(attacker)) {
				damage *= GetConVarInt(CV_DAMAGEMULTIPLYER);
				if((GetClientHealth(attacker) + GetConVarInt(CV_REGENSCORE)) >= GetConVarInt(CV_MAXTANKHEALTH)) {
					SetEntityHealth(attacker, GetConVarInt(CV_MAXTANKHEALTH));
				} else {
					SetEntityHealth(attacker, (GetClientHealth(attacker) + GetConVarInt(CV_REGENSCORE)));
				}
			}
		}
	}
}
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetConVarInt(CV_RAGEENABLE) == 1) {
		new Client = GetClientOfUserId(GetEventInt(event,"attacker"));
		new attacker = GetClientOfUserId(GetEventInt(event,"userid"));
		new Currentdamage = GetEventInt(event,"dmg_health");
		//new damageadd = RoundToNearest(Currentdamage * GetConVarInt(CV_DAMAGEMULTIPLYER));
		new damageadd = RoundToNearest(Currentdamage * g_flStopping_dmgmult);
		if(GetConVarInt(CV_REGENENABLE) == 1) {
			if(GetClientTeam(Client) == 2) {
				if(IsPlayerTank(attacker)) {
					InfToSurDamageAdd(Client, damageadd ,GetEventInt(event,"dmg_health"));
					if((GetClientHealth(attacker) + GetConVarInt(CV_REGENSCORE)) >= GetConVarInt(CV_MAXTANKHEALTH)) {
						SetEntityHealth(attacker, GetConVarInt(CV_MAXTANKHEALTH));
					} else {
						SetEntityHealth(attacker, (GetClientHealth(attacker) + GetConVarInt(CV_REGENSCORE)));
					}
				}
			}
		}
	}
}
public Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if(GetConVarInt(CV_RAGEENABLE) == 1) {
		new Client, String:Model[32];
		GetClientModel(Client,Model,32);
		Client = GetClientOfUserId(GetEventInt(event,"userid"));
		if (Client==0 || GetClientTeam(Client)!=3) {
			return;
		} if (StrContains(Model,"hulk",false) == -1) {
			return;
		} if(IsPlayerTank(Client)) {
			SetEntDataFloat(Client,g_iLaggedMovementO, 1.5 ,true);
			SetEntityRenderColor(Client, CuffColor[0], CuffColor[1], CuffColor[2], CuffColor[3]);
			SetEntityHealth(Client, GetConVarInt(CV_MAXTANKHEALTH));
		}
	}
}
bool:IsPlayerTank(client) {
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK) {
		return true;
	} else {
		return false;
	}
}

/*
//////////////////////////////////////////////////////////////////////
	Thanks to PerkMod For This L4D2 Damage extraction
	Thanks to "tPoncho"
//////////////////////////////////////////////////////////////////////
*/
InfToSurDamageAdd (any:Client, any:iDmgAdd, any:iDmgOrig) {
	new iHP = GetEntProp(Client,Prop_Data,"m_iHealth");
	if (iHP>iDmgAdd) {
		return;
	} else {
		new Float:flHPBuff=GetEntDataFloat(Client,g_iHPBuffO);
		if (flHPBuff>0) {
			new iDmgCount=iHP-1;
			iDmgAdd-=iDmgCount;
			SetEntProp(Client,Prop_Data,"m_iHealth", iHP-iDmgCount );
			new iHPBuff=RoundToFloor(flHPBuff);
			if (iHPBuff<iDmgAdd) iDmgAdd=iHPBuff;
			SetEntDataFloat(Client,g_iHPBuffO, flHPBuff-iDmgAdd ,true);
			return;
		} else {
			if (iDmgOrig>=iHP) return;
			if (iDmgAdd>=iHP) iDmgAdd=iHP-1;
			if (iDmgAdd<0) return;
			SetEntProp(Client,Prop_Data,"m_iHealth", iHP-iDmgAdd );
			return;
		}
	}
}