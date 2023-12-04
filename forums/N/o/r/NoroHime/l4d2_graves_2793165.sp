#define PLUGIN_VERSION		"1.1"
#define PLUGIN_NAME			"graves"
#define PLUGIN_NAME_FULL	"[L4D2] Graves"
#define PLUGIN_DESCRIPTION	"another Graves"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"steamcommunity.com/id/norohime"

/*
 *	v1.0 just released; 19-November-2022
 *	v1.1 change to more precious work way; 20-November-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2)

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

char MODELS_GRAVE[][] = {
	// graves
	"models/props_cemetery/grave_01.mdl",
	"models/props_cemetery/grave_02.mdl",
	"models/props_cemetery/grave_03.mdl",
	"models/props_cemetery/grave_04.mdl",
	"models/props_cemetery/grave_06.mdl",
	"models/props_cemetery/grave_07.mdl",

	// avoiding the "Late precache" message on the client console.
	"models/props_cemetery/gibs/grave_02a_gibs.mdl",
	"models/props_cemetery/gibs/grave_02b_gibs.mdl",
	"models/props_cemetery/gibs/grave_02c_gibs.mdl",
	"models/props_cemetery/gibs/grave_02d_gibs.mdl",
	"models/props_cemetery/gibs/grave_02e_gibs.mdl",
	"models/props_cemetery/gibs/grave_02f_gibs.mdl",
	"models/props_cemetery/gibs/grave_02g_gibs.mdl",
	"models/props_cemetery/gibs/grave_02h_gibs.mdl",
	"models/props_cemetery/gibs/grave_02i_gibs.mdl",
	"models/props_cemetery/gibs/grave_03a_gibs.mdl",
	"models/props_cemetery/gibs/grave_03b_gibs.mdl",
	"models/props_cemetery/gibs/grave_03c_gibs.mdl",
	"models/props_cemetery/gibs/grave_03d_gibs.mdl",
	"models/props_cemetery/gibs/grave_03e_gibs.mdl",
	"models/props_cemetery/gibs/grave_03f_gibs.mdl",
	"models/props_cemetery/gibs/grave_03g_gibs.mdl",
	"models/props_cemetery/gibs/grave_03h_gibs.mdl",
	"models/props_cemetery/gibs/grave_03i_gibs.mdl",
	"models/props_cemetery/gibs/grave_03j_gibs.mdl",
	"models/props_cemetery/gibs/grave_06a_gibs.mdl",
	"models/props_cemetery/gibs/grave_06b_gibs.mdl",
	"models/props_cemetery/gibs/grave_06c_gibs.mdl",
	"models/props_cemetery/gibs/grave_06d_gibs.mdl",
	"models/props_cemetery/gibs/grave_06e_gibs.mdl",
	"models/props_cemetery/gibs/grave_06f_gibs.mdl",
	"models/props_cemetery/gibs/grave_06g_gibs.mdl",
	"models/props_cemetery/gibs/grave_06h_gibs.mdl",
	"models/props_cemetery/gibs/grave_06i_gibs.mdl",
	"models/props_cemetery/gibs/grave_07a_gibs.mdl",
	"models/props_cemetery/gibs/grave_07b_gibs.mdl",
	"models/props_cemetery/gibs/grave_07c_gibs.mdl",
	"models/props_cemetery/gibs/grave_07d_gibs.mdl",
	"models/props_cemetery/gibs/grave_07e_gibs.mdl",
	"models/props_cemetery/gibs/grave_07f_gibs.mdl"
};

ConVar cDelay;		float flDelay;
ConVar cGlow;		char sGlow[32];
ConVar cGlowMin;	char sGlowMin[16];
ConVar cGlowMax;	char sGlowMax[16];
ConVar cGlowFlash;	bool bGlowFlash;
ConVar cHealth;		char sHealth[16];
ConVar cPosition;	float flPosition;

public void OnPluginStart() {

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,				"Version of " ... PLUGIN_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cDelay =		CreateConVar(PLUGIN_NAME ... "_delay", "1.0",			"time to delay spawn", FCVAR_NOTIFY);
	cGlow =			CreateConVar(PLUGIN_NAME ... "_glow", "100 0 0",		"glow color empty to dont glow, -1=random, leave empty=disable glow", FCVAR_NOTIFY);
	cGlowMin =		CreateConVar(PLUGIN_NAME ... "_glow_min", "200",		"glow min range", FCVAR_NOTIFY);
	cGlowMax =		CreateConVar(PLUGIN_NAME ... "_glow_max", "800",		"glow max range 0=unlimited", FCVAR_NOTIFY);
	cGlowFlash =	CreateConVar(PLUGIN_NAME ... "_glow_flash", "1",		"does make glow flashing", FCVAR_NOTIFY);
	cHealth =		CreateConVar(PLUGIN_NAME ... "_health", "300",			"grave health, leave empty to make un-Solid", FCVAR_NOTIFY);
	cPosition =		CreateConVar(PLUGIN_NAME ... "_position", "50",			"position offset of grave", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);

	cDelay.AddChangeHook(OnConVarChanged);
	cGlow.AddChangeHook(OnConVarChanged);
	cGlowMin.AddChangeHook(OnConVarChanged);
	cGlowMax.AddChangeHook(OnConVarChanged);
	cGlowFlash.AddChangeHook(OnConVarChanged);
	cHealth.AddChangeHook(OnConVarChanged);
	cPosition.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	// HookEvent("defibrillator_used_fail", OnDefibrillatorUsedFail);
}

public void OnMapStart() {
	for ( int i = 0; i < sizeof(MODELS_GRAVE); i++ )
		PrecacheModel(MODELS_GRAVE[i]);
}

void ApplyCvars() {
	flDelay = cDelay.FloatValue;
	cGlow.GetString(sGlow, sizeof(sGlow));
	cGlowMax.GetString(sGlowMax, sizeof(sGlowMax));
	cGlowMin.GetString(sGlowMin, sizeof(sGlowMin));
	bGlowFlash = cGlowFlash.BoolValue;
	cHealth.GetString(sHealth, sizeof(sHealth));
	flPosition = cPosition.FloatValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

ArrayList graves = null;


public void OnEntityCreated(int entity, const char[] classname) {

	if ( strcmp(classname, "survivor_death_model") == 0 ) {

		CreateTimer(flDelay, DelaySpawn, EntIndexToEntRef(entity));
	}
}

public void OnEntityDestroyed(int entity) {

	static char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));

	if ( strcmp(classname, "survivor_death_model") == 0 ) {

		float vOriginClient[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vOriginClient);

		for (int i = 0; i < graves.Length; i++) {

			int grave = EntRefToEntIndex(graves.Get(i));

			if (grave != INVALID_ENT_REFERENCE) {
				
				static float vOriginGrave[3];

				GetEntPropVector(grave, Prop_Data, "m_vecOrigin", vOriginGrave);

				if (GetVectorDistance(vOriginClient, vOriginGrave) < flPosition * 2) {

					SetVariantString("OnUser1 !self:Kill::0.0:-1");
					AcceptEntityInput(grave, "AddOutput");
					AcceptEntityInput(grave, "FireUser1");

					graves.Erase(i);
					return;
				}
			}
		}
	}
}


Action DelaySpawn(Handle timer, int corpse) {

	corpse = EntRefToEntIndex(corpse)

	if (corpse != INVALID_ENT_REFERENCE) {

		int grave = CreateEntityByName("prop_dynamic_override");

		if (grave != INVALID_ENT_REFERENCE) {

			float vOrigin[3], vAngles[3], vOriginGrave[3];

			GetEntPropVector(corpse, Prop_Send, "m_vecOrigin", vOrigin);
			GetEntPropVector(corpse, Prop_Send, "m_angRotation", vAngles);

			MoveForward(vOrigin, vAngles, vOriginGrave, flPosition);

			if (sHealth[0]) {

				DispatchKeyValue(grave, "health", sHealth);
				DispatchKeyValue(grave, "solid", "2");
			} else 
				DispatchKeyValue(grave, "solid", "0");

			if (sGlow[0]) {

				DispatchKeyValue(grave, "glowrange", sGlowMax);
				DispatchKeyValue(grave, "glowrangemin", sGlowMin);

				static char sTemp[12];

				if(strcmp(sGlow, "-1") == 0) { //part from fbef0102

					switch( GetRandomInt(1 ,13) ) {
						case 1: FormatEx(sTemp, sizeof(sTemp), "255 0 0");
						case 2: FormatEx(sTemp, sizeof(sTemp), "0 255 0");
						case 3: FormatEx(sTemp, sizeof(sTemp), "0 0 255");
						case 4: FormatEx(sTemp, sizeof(sTemp), "155 0 255");
						case 5: FormatEx(sTemp, sizeof(sTemp), "0 255 255");
						case 6: FormatEx(sTemp, sizeof(sTemp), "255 155 0");
						case 7: FormatEx(sTemp, sizeof(sTemp), "255 255 255");
						case 8: FormatEx(sTemp, sizeof(sTemp), "255 0 150");
						case 9: FormatEx(sTemp, sizeof(sTemp), "128 255 0");
						case 10: FormatEx(sTemp, sizeof(sTemp), "128 0 0");
						case 11: FormatEx(sTemp, sizeof(sTemp), "0 128 128");
						case 12: FormatEx(sTemp, sizeof(sTemp), "255 255 0");
						case 13: FormatEx(sTemp, sizeof(sTemp), "50 50 50");
					}

				} else
					FormatEx(sTemp, sizeof(sTemp), "%s", sGlow);

				DispatchKeyValue(grave, "glowcolor", sTemp);

				if (bGlowFlash)
					SetEntProp(grave, Prop_Send, "m_bFlashing", bGlowFlash);
			}

			SetEntityModel(grave, MODELS_GRAVE[GetRandomInt(0, 5)]);
			TeleportEntity(grave, vOriginGrave, vAngles, NULL_VECTOR);
			DispatchSpawn(grave);

			if (sGlow[0])
				AcceptEntityInput(grave, "StartGlowing");

			if (graves == null)
				graves = new ArrayList();

			graves.Push(EntIndexToEntRef(grave));
		}
	}

	return Plugin_Stop;
}

/*void OnDefibrillatorUsedFail(Event event, const char[] name, bool dontBroadcast) {

	int user = GetClientOfUserId(event.GetInt("userid"));

	int found = INVALID_ENT_REFERENCE;

	while ((found = FindEntityByClassname(found, "survivor_death_model")) != INVALID_ENT_REFERENCE)

		if (IsValidEntity(found) && IsSurvivor(user) && GetRangeBetweenEntities(user, found) > 500) {

			float vOriginClient[3];
			GetEntPropVector(user, Prop_Data, "m_vecOrigin", vOriginClient);

			if (graves != null)
				for (int i = 0; i < graves.Length; i++) {

					int grave = EntRefToEntIndex(graves.Get(i));

					if (grave != INVALID_ENT_REFERENCE) {
						
						float vOriginGrave[3], vAngles[3], vOriginCorpse[3], vOriginDest[3];

						GetEntPropVector(grave, Prop_Send, "m_angRotation", vAngles);

						GetEntPropVector(grave, Prop_Data, "m_vecOrigin", vOriginGrave);
						GetEntPropVector(found, Prop_Data, "m_vecOrigin", vOriginCorpse);

						MoveForward(vOriginClient, vAngles, vOriginDest, flPosition);

						if (GetVectorDistance(vOriginCorpse, vOriginGrave) < flPosition * 2) {

							TeleportEntity(grave, vOriginDest, NULL_VECTOR, NULL_VECTOR);

							break;
						}
					}
				}

			TeleportEntity(found, vOriginClient, NULL_VECTOR, NULL_VECTOR);

			PrintToChat(user, "啊哈哈，尸体来咯");
			return;
		}
}

float GetRangeBetweenEntities(int entity1, int entity2) {

	float vOrigin1[3], vOrigin2[3];
	GetEntPropVector(entity1, Prop_Send, "m_vecOrigin", vOrigin1);
	GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", vOrigin2);

	return GetVectorDistance(vOrigin1, vOrigin2);
}*/


// Taken from Silvers, im respect this haha
void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance) {
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}