// if lemurs had knives,
// they would throw them!

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cssthrowingknives>

#define NAME "CSS Throwing Knives"
#define VERSION "1.1 reedited for csgo"
#define KNIFE_MDL "models/weapons/w_knife.mdl"
#define KNIFEHIT_SOUND "weapons/knife/knife_hit3.wav"
#define TRAIL_MDL "materials/sprites/lgtning.vmt"
#define TRAIL_COLOR {177, 177, 177, 117}
#define ADD_OUTPUT "OnUser1 !self:Kill::1.5:1"
#define COUNT_TXT "Throwing Knives : %i"

new Handle:g_CVarEnable;
new Handle:g_CVarVelocity;
new Float:g_fVelocity;
new Handle:g_CVarKnives;
new Handle:g_CVarDamage;
new String:g_sDamage[8];
new Handle:g_CVarFF;


new Handle:g_CVarDisplay;
new g_iDisplay;
new const Float:g_fSpin[3] = {4877.4, 0.0, 0.0};
new g_iKnives[MAXPLAYERS+1];

new Skin[2] = { 0, 0 }

public Plugin:myinfo = {

	name = NAME,
	author = "meng, Franc1sco steam: franug",
	version = VERSION,
	description = "Throwing knives for CSS",
	url = "http://www.sourcemod.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {

	CreateNative("SetClientThrowingKnives", NativeSetClientThrowingKnives);
	CreateNative("GetClientThrowingKnives", NativeGetClientThrowingKnives);
	RegPluginLibrary("cssthrowingknives");
	return APLRes_Success;
}

public OnPluginStart() {

	CreateConVar("sm_cssthrowingknives", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarEnable = CreateConVar("sm_throwingknives_enable", "1", "Enable/disable plugin.", _, true, 0.0, true, 1.0);
	g_CVarVelocity = CreateConVar("sm_throwingknives_velocity", "5", "Velocity (speed) adjustment.", _, true, 1.0, true, 10.0);
	g_CVarKnives = CreateConVar("sm_throwingknives_count", "3", "Amount of knives players spawn with.", _, true, 0.0, true, 100.0);
	g_CVarDamage = CreateConVar("sm_throwingknives_damage", "57", "Damage adjustment.", _, true, 10.0, true, 200.0);
	g_CVarDisplay = CreateConVar("sm_throwingknives_display", "1", "Knives remaining display location. 1 = Hint | 2 = Key Hint", _, true, 1.0, true, 2.0);
	g_CVarFF = FindConVar("mp_friendlyfire");

	// initialize global vars, hook CVar changes
	HookConVarChange(g_CVarEnable, CVarChange);
	g_fVelocity = (1000.0 + (250.0 * GetConVarFloat(g_CVarVelocity)));
	HookConVarChange(g_CVarVelocity, CVarChange);
	GetConVarString(g_CVarDamage, g_sDamage, sizeof(g_sDamage));
	HookConVarChange(g_CVarDamage, CVarChange);
	g_iDisplay = GetConVarInt(g_CVarDisplay);
	HookConVarChange(g_CVarDisplay, CVarChange);

	AutoExecConfig(true, "throwingknives");


	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("weapon_fire", EventWeaponFire);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	if ((convar == g_CVarEnable) && (StringToInt(newValue) == 1)) {
		for (new i = 1; i <= MaxClients; i++)
			g_iKnives[i] = GetConVarInt(g_CVarKnives);
	}
	else if (convar == g_CVarVelocity)
		g_fVelocity = (1000.0 + (250.0 * StringToFloat(newValue)));
	else if (convar == g_CVarDamage)
		strcopy(g_sDamage, sizeof(g_sDamage), newValue);



	else if (convar == g_CVarDisplay)
		g_iDisplay = GetConVarInt(g_CVarDisplay);

}

public OnMapStart() {

	PrecacheModel(KNIFE_MDL);
	PrecacheSound(KNIFEHIT_SOUND);
}


public EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast) 
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (GetConVarBool(g_CVarEnable)) 
    {
        g_iKnives[client] = GetConVarInt(g_CVarKnives);
    }
    if ((GetConVarBool(g_CVarEnable)) && IsVip(client))
    {
        g_iKnives[client] = GetConVarInt(g_CVarKnives);
    }
    else
    {
        g_iKnives[client] = 0
    }
} 
public IsVip(client)
{
    if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1) return true;
    else return false;
}  

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast) { // only fires for primary attack

	if (GetConVarBool(g_CVarEnable)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		static String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if (!IsFakeClient(client) && StrEqual(sWeapon, "knife") && (g_iKnives[client] > 0))
			ThrowKnife(client);
	}
}



ThrowKnife(client) {


	static Float:fPos[3], Float:fAng[3], Float:fVel[3], Float:fPVel[3];
	GetClientEyePosition(client, fPos);


	// create & spawn entity. set model & owner. set to kill itself OnUser1
	// calc & set spawn position, angle, velocity & spin
	// add to lethal knife array, teleport, add trial, ...
	new entity = CreateEntityByName("prop_physics_override");
	if ((entity != -1)) {
		SetEntityModel(entity, KNIFE_MDL);
		SetEntProp(entity, Prop_Send, "m_nSkin", Skin[0]);
		DispatchSpawn(entity);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetVariantString(ADD_OUTPUT);
		AcceptEntityInput(entity, "AddOutput");
		GetClientEyeAngles(client, fAng);
		GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fVel, g_fVelocity);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVel);
		AddVectors(fVel, fPVel, fVel);
		SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", g_fSpin);
		SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.2);
		TeleportEntity(entity, fPos, fAng, fVel);
		SDKHook(entity, SDKHook_StartTouch, Touched);
		SDKHook(entity, SDKHook_Touch, Touched);
		KnifeCount(client, --g_iKnives[client]);
		CreateTimer(20.0, Delete, entity);

	}
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

public Action:Touched(ent, client)
{
	if(ent > 0 && IsValidClient(client) && IsPlayerAlive(client) && IsValidEdict(ent))
	{
		new attacker = GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity");
		if (GetConVarBool(g_CVarFF) || (GetClientTeam(client) != GetClientTeam(attacker)))
			if(IsValidClient(attacker))
			{
				AcceptEntityInput(ent, "Kill");
				new Float:damage = StringToFloat(g_sDamage); 
				SDKHooks_TakeDamage(client, attacker, attacker, damage); 
			}
	}
	else
		CreateTimer(3.0, Delete, ent);
}

public Action:Delete(Handle:timer,any:ent)
{
	if(ent > 0 && IsValidEdict(ent))
		AcceptEntityInput(ent, "Kill");
}


public bool:THFilter(entity, contentsMask, any:data) {

	return IsClientIndex(entity) && (entity != data);
}

bool:IsClientIndex(index) {

	return (index > 0) && (index <= MaxClients);
}

KnifeCount(client, count) {

	if (IsClientInGame(client)) {
		switch (g_iDisplay) {
			case 1: // Hint
				PrintHintText(client, COUNT_TXT, count);
			case 2: { // Key Hint
				static String:sBuffer[64];
				Format(sBuffer, 64, COUNT_TXT, count);
				new Handle:hKHT = StartMessageOne("KeyHintText", client);
				BfWriteByte(hKHT, 1);
				BfWriteString(hKHT, sBuffer);
				EndMessage();
			}
		}
	}
}



public NativeSetClientThrowingKnives(Handle:plugin, numParams) {

	new client = GetNativeCell(1);
	new num = GetNativeCell(2);
	KnifeCount(client, g_iKnives[client] = num);
}

public NativeGetClientThrowingKnives(Handle:plugin, numParams) {

	new client = GetNativeCell(1);
	return g_iKnives[client];
}

public IsAdmin(client)
{
if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1) return true;
else return false;
}