#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// #define MDL_LASER "sprites/laserbeam.vmt"
#define MDL_MINE "models/props_buildables/mine_02.mdl"

//地雷存在数量
int gCount = 0;


public Plugin myinfo = {
	name = "Mine",
	author = "CD意识STEAM_1:0:211123334(kazya3)",
	description = "plant mine",
	version = "1.0",
};

public void OnPluginStart() 
{

}

public void OnMapStart()
{
	PrecacheModel(MDL_MINE, true);
	// PrecacheModel(MDL_LASER, true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "upgrade_ammo_explosive", false) || StrEqual(classname, "upgrade_ammo_incendiary", false)){
		RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
	}
}

void OnNextFrame(int iEntRef)
{
	if (!IsValidEntRef(iEntRef)){
		return;
	}

	int entity = EntRefToEntIndex(iEntRef);
	float Pos[3];
	char mineExplosive[64];//爆炸实体名字

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", Pos);//获取高爆弹position
	// PrintToChatAll("%f %f %f", Pos[0], Pos[1], Pos[2]);
	AcceptEntityInput(entity, "kill");
	int physics = CreateEntityByName("prop_dynamic_override");
	if (IsValidEntity(physics) && IsValidEdict(physics)){
		// char mine[64];//地雷实体名字
		char tmp[128];//输出
		// Format(mine, sizeof(mine), "mine%d", gCount);
		Format(mineExplosive, sizeof(mineExplosive), "mineExplosive%d", gCount);
		gCount = gCount > 10000 ? 1 : gCount + 1;
		if (gCount > 10000){
			gCount = 1;
		}
		DispatchKeyValue(physics, "model", MDL_MINE);
		DispatchSpawn(physics);
		//设置地雷位置
		TeleportEntity(physics, Pos, NULL_VECTOR, NULL_VECTOR);
		//设置发光
		SetEntProp(physics, Prop_Send, "m_iGlowType", 2);//2可被障碍物遮挡，3无视障碍物发光
		SetEntProp(physics, Prop_Send, "m_glowColorOverride", GetColor("255 0 0"));//65280绿色
		SetEntProp(physics, Prop_Send, "m_nGlowRange", 320);

		SetEntProp(physics, Prop_Data, "m_usSolidFlags", 152);
		SetEntProp(physics, Prop_Data, "m_CollisionGroup", 1);// Collides with nothing but world and static stuff
		SetEntityMoveType(physics, MOVETYPE_NONE);
		SetEntProp(physics, Prop_Data, "m_MoveCollide", 0);
		SetEntProp(physics, Prop_Data, "m_nSolidType", 6);// solid vphysics object, get vcollide from the model and collide with that
		// SetEntPropEnt(physics, Prop_Data, "m_hLastAttacker", client);
		//设置爆炸伤害和范围
		DispatchKeyValue(physics, "ExplodeRadius", "10");
		DispatchKeyValue(physics, "ExplodeDamage", "1");

		// Format(tmp, sizeof(tmp), "%s,Break,,0,-1", beammdl);
		// DispatchKeyValue(physics, "OnHealthChanged", tmp);
		Format(tmp, sizeof(tmp), "%s,Explode,,0,-1", mineExplosive);
		DispatchKeyValue(physics, "OnBreak", tmp);
		SetEntProp(physics, Prop_Data, "m_takedamage", 2);//DAMAGE_YES
		// SetEntProp(physics, Prop_Data, "m_iHealth", 100);
		// AcceptEntityInput(physics, "Enable");
	}

	int explosion = CreateEntityByName("env_explosion");
	if (IsValidEntity(explosion) && IsValidEdict(explosion)){
		TeleportEntity(explosion, Pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(explosion, "targetname", mineExplosive);
		DispatchKeyValue(explosion, "spawnflags", "1916");	// Random orientation
		DispatchKeyValue(explosion, "iMagnitude", "1000");
		DispatchKeyValue(explosion, "iRadiusOverride", "500");
		// SetEntPropEnt(explosion, Prop_Data, "m_hLastAttacker", client);
		SetEntProp(explosion, Prop_Data, "m_iHammerID", 1078682);
		DispatchSpawn(explosion);
		
		// SetVariantString("OnUser1 !self:Explode::0.01:1)");	// Add a delay to allow explosion effect to be visible
		// AcceptEntityInput(entity, "Addoutput");
	}

	SDKHook(physics , SDKHook_StartTouch, OnTouch);//当相关实体被销毁或插件被卸载时，挂钩将自动移除。
}

public OnTouch(physics, client)//被碰的，碰的
{
	// PrintToChatAll("client touched!");
	if( IsValidEntity(physics) && IsValidEdict(physics))
	{
		if(IsValidClient(client) || IsWitchOrInfected(client))
		{
			AcceptEntityInput(physics, "Break");
		}
	}
}

bool IsValidEntRef(int iEntRef)
{
    return iEntRef != 0 && EntRefToEntIndex(iEntRef) != INVALID_ENT_REFERENCE;
}

bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3);
}

IsWitchOrInfected(entity)
{
	if(entity > 0 && IsValidEdict(entity) && IsValidEntity(entity))
	{
		char classname[32];
		GetEdictClassname(entity, classname, sizeof(classname));
		if(StrEqual(classname, "witch") || StrEqual(classname, "infected"))
		{
			return true;
		}
	}
	return false;
}

int GetColor(char[] sTemp)
{
	if (strcmp(sTemp, "") == 0) {
		return 0;
	}
	
	char sColors[3][4];
	int iColor = ExplodeString(sTemp, " ", sColors, 3, 4);

	if (iColor != 3) {
		return 0;
	}
	
	iColor = StringToInt(sColors[0]);
	iColor += 256 * StringToInt(sColors[1]);
	iColor += 65536 * StringToInt(sColors[2]);

	return iColor;
}


public void OnConfigsExecuted()
{
	SwitchPlugin();
}

void SwitchPlugin()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if( damagetype & DMG_BLAST && victim > 0 && victim <= MaxClients && GetEntProp(inflictor, Prop_Data, "m_iHammerID") == 1078682)
	{
		if(GetClientTeam(victim) == 2 )
			damage = 0.0;
		else if(GetClientTeam(victim) == 3 )
			damage = 2000.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}