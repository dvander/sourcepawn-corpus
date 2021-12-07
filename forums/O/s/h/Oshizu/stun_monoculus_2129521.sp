#include <sdktools>
 
new Handle:hGameConf;
new Handle:hStunMono;

public Plugin:myinfo =
{
	name = "[TF2] Stun Monoculus",
	author = "Mio Isurugi (Oshizu)",
	description = "Stuns MONOCULUS!",
	version = "1.0",
	url = "none"
};
  
public OnPluginStart()
{
	hGameConf = LoadGameConfigFile("tf2.stunmono");
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CEyeballBoss::BecomeEnraged");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hStunMono = EndPrepSDKCall();
 
	RegAdminCmd("sm_monostun", MonoculusStun, ADMFLAG_GENERIC);
	RegAdminCmd("sm_monostun2", MonoculusStun_2, ADMFLAG_GENERIC);
}

public Action:MonoculusStun(client, args)
{
	new entity = FindEntity(client, "eyeball_boss");
	if(IsValidEntity(entity))
		SDKCall(hStunMono, entity, 1101004800)
}

public Action:MonoculusStun_2(client, args)
{
	new entity = FindEntity(client, "eyeball_boss");
	if(IsValidEntity(entity))
		SDKCall(hStunMono, entity, 1084227584)
}

stock FindEntity(client, const String:classname[])
{
	new entity = -1
	while ((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
	{
		return entity;
	}
	return entity;
}