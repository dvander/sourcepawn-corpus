#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "MiniGun Spawner",
	author = "The JCS",
	description = "Spawns a minigun o player location",
	version = "0.1",
	url = "http://l4dbrasil.com"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_minigun", Command_MiniGun);
}

public Action:Command_MiniGun(client, args)
{
	new Float:fOrigin[3];
	GetClientAbsOrigin(client,fOrigin);
	
	new Float:fAng[3];
	fAng[0] = 0.0;
	fAng[1] = 0.0;
	fAng[2] = 0.0;

	BuildMiniGun(fOrigin, fAng);
}


BuildMiniGun(Float:fOrigin[3], Float:fAngle[3])
{
	new iMiniGun = CreateEntityByName("prop_minigun");

	DispatchSpawn(iMiniGun);
    
	TeleportEntity(iMiniGun, fOrigin, fAngle, NULL_VECTOR);
    
    SetEntityModel(iMiniGun, "models/w_models/weapons/w_minigun.mdl");
    
    SetEntData(iMiniGun, FindSendPropOffs("CPropMinigun","m_maxYaw"), 90, 4, true);
	
    SetEntData(iMiniGun, FindSendPropOffs("CPropMinigun","m_maxPitch"), 60, 4, true);
    SetEntData(iMiniGun, FindSendPropOffs("CPropMinigun","m_minPitch"), -30, 4, true);
	
    SetEntDataFloat(iMiniGun, FindSendPropOffs("CPropMinigun","m_flMinRandAnimTime"), 5.0, true);
    SetEntDataFloat(iMiniGun, FindSendPropOffs("CPropMinigun","m_flMaxRandAnimTime"), 10.0, true);

    SetEntData(iMiniGun, FindSendPropOffs("CPropMinigun","m_nSolidType"), 6, 4, true);	
}  