#include <sourcemod>
#include <sdktools>


public void OnPluginStart()
{
	HookEvent("tank_spawn", eTankSpawn);
}

public void OnMapStart()	
{
	PrecacheParticle("particle/particle_smokegrenade1.vmt");
}

public Action eTankSpawn(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	int iTank = GetEventInt(hEvent, "tankid");
	
	SetEntityRenderColor(iTank, 255, 0, 0, 255);
	use_particle(iTank);
}

public Action use_particle(client)
{
	int devil = CreateEntityByName("env_smokestack");
	DispatchKeyValue(devil,"BaseSpread", "100");
	DispatchKeyValue(devil,"SpreadSpeed", "70");
	DispatchKeyValue(devil,"Speed", "80");
	DispatchKeyValue(devil,"StartSize", "200");
	DispatchKeyValue(devil,"EndSize", "2");
	DispatchKeyValue(devil,"Rate", "30");
	DispatchKeyValue(devil,"JetLength", "400");
	DispatchKeyValue(devil,"Twist", "20"); 
	DispatchKeyValue(devil,"RenderColor", "255 0 0");
	DispatchKeyValue(devil,"RenderAmt", "255");
	DispatchKeyValue(devil,"SmokeMaterial", "particle/particle_smokegrenade1.vmt");

	SetVariantString("!activator");
	AcceptEntityInput(devil, "SetParent", client);
	DispatchSpawn(devil);
	AcceptEntityInput(devil, "TurnOn");
	TeleportEntity(devil, view_as<float>({ 0.0, 0.0, 30.0 }), NULL_VECTOR, NULL_VECTOR);
}

int PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	int index = FindStringIndex(table, sEffectName);
	if( index == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
		index = FindStringIndex(table, sEffectName);
	}

	return index;
}