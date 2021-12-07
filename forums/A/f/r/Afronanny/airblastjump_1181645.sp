//The airblasting jump code stuff thing is from pyro++ by MikeJS
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
new Float:g_fPower = 700.0;
new Handle:g_hCvarPower;
public Plugin:myinfo = 
{
	name = "Pyro airblast jump",
	author = "Afronanny + MikeJS",
	description = "Pyro airblast jump",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=126561"
}
new TFClassType:pyro;
new flagOff;
new ammoOff;
public OnPluginStart()
{
	flagOff = FindSendPropOffs("CTFPlayer", "m_fFlags");
	ammoOff = FindSendPropInfo("CTFPlayer", "m_iAmmo")
	pyro = TF2_GetClass("pyro");
	g_hCvarPower = CreateConVar("sm_pyrojump_power", "700");
	HookConVarChange(g_hCvarPower, ConVarChanged_Power);
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (TF2_GetPlayerClass(client) == pyro)
	{
		if (GetEntData(client, flagOff) & FL_ONGROUND)
		{
			
			if (buttons & IN_ATTACK2)
			{
				
				decl String:cls[64];
				GetClientWeapon(client, cls, sizeof(cls));
				if (strcmp(cls, "tf_weapon_flamethrower") == 0 && GetEntData(client, ammoOff+4) > 0)
				{
					decl Float:vecAng[3], Float:vecVel[3];
					GetClientEyeAngles(client, vecAng);
					GetEntPropVector(client, Prop_Data, "m_vecVelocity", vecVel);
					vecAng[0] *= -1.0;
					vecAng[0] = DegToRad(vecAng[0]);
					vecAng[1] = DegToRad(vecAng[1]);
					vecVel[0] -= g_fPower * Cosine(vecAng[0]) * Cosine(vecAng[1]);
					vecVel[1] -= g_fPower * Cosine(vecAng[0]) * Sine(vecAng[1]);
					vecVel[2] -= g_fPower * Sine(vecAng[0]);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vecVel);
				}
			}
		}
	}
	return Plugin_Continue;
}
public ConVarChanged_Power(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fPower = StringToFloat(newValue);
}

