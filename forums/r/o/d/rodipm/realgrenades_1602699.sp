#include <sourcemod>
#include <cstrike>
#include <sdktools>

public Plugin:myinfo = 
{ 
    name = "Realistic Grenade (Explodes if holded for too many time)",
    author = "rodipm",
    description = "Your HE explodes if holded for too many time",
    version = "1.0",
    url = "sourcemod.net" 
} 

new bool:holding[MAXPLAYERS+1];
new weaponIndex[MAXPLAYERS+1];
new g_ExplosionSprite;
new g_SmokeSprite;
new Handle:Time = INVALID_HANDLE;
new Handle:Timer[MAXPLAYERS+1] = INVALID_HANDLE;

public OnPluginStart()
{
	Time = CreateConVar("rg_time", "10", "Time before player explode");
	OnMapStart();
	
	PrintToChatAll(" ");
	PrintToChatAll(" ");
	PrintToChatAll(" ");
	PrintToChatAll(" ");
	PrintToChatAll("\x04[Realistic Grenade \x01By.:RpM\x04]\x03 Be careful, if you hold your HE 'unlocked' for more than \x04%i\x03 seconds, it will explode and kill you!", GetConVarInt(Time));
	PrintToChatAll(" ");
	PrintToChatAll(" ");
	PrintToChatAll(" ");
	PrintToChatAll(" ");
}

public OnMapStart() 
{
	PrecacheSound("ambient/explosions/explode_8.wav", true);
	g_ExplosionSprite = PrecacheModel("sprites/blueglow2.vmt");
	g_SmokeSprite = PrecacheModel("sprites/steam1.vmt");
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	decl String:name[80]; 
	new wpindex = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon"); 
	
	if(IsValidEntity(wpindex))
	{
		GetEntityClassname(wpindex, name, sizeof(name));
		
		if(StrEqual(name, "weapon_hegrenade", false))
		{
			weaponIndex[client] = wpindex;
			if(buttons & IN_ATTACK)
			{
				if(!holding[client])
				{
					Timer[client] = CreateTimer(GetConVarFloat(Time), Check, any:client);
					holding[client] = true;
				}
			}
			else
			{
				if(holding[client] == true)
				{
					if(Timer[client] != INVALID_HANDLE)
					{
						KillTimer(Timer[client]);
						holding[client] = false;
					}
				}
			}
		}
		else
		{
			if(holding[client] == true)
			{
				if(Timer[client] != INVALID_HANDLE)
				{
					KillTimer(Timer[client]);
					holding[client] = false;
				}
			}
		}
	}
}

public Action:Check(Handle:timer, any:client)
{
	if(holding[client])
	{
		if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(IsValidEdict(weaponIndex[client]))
			{
				RemovePlayerItem(client, weaponIndex[client]);
				RemoveEdict(weaponIndex[client]);
				
				ForcePlayerSuicide(client);
				
				new Float:iVec[3];
				GetClientAbsOrigin(client, Float:iVec);
				new Float:normal[3] = {0.0, 0.0, 1.0};
				
				TE_SetupExplosion(iVec, g_ExplosionSprite, 5.0, 1, 0, 50, 40, normal);
				TE_SendToAll();
					
				TE_SetupSmoke(iVec, g_SmokeSprite, 10.0, 3);
				TE_SendToAll();
			
				EmitAmbientSound("ambient/explosions/explode_8.wav", iVec, client, SNDLEVEL_NORMAL);
				
				PrintToChat(client, "\x04[Realistic Grenade \x01By.:RpM\x04]\x03 You held your HE for more than \x04%i\x03 seconds and it exploded!", GetConVarInt(Time));
				
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
					{
						if(i != client)
							PrintToChat(i, "\x04[Realistic Grenade \x01By.:RpM\x04]\x03 The player %N held his HE for more than \x04%i\x03 seconds and it exploded!", client, GetConVarInt(Time));
					}
				}
				
				weaponIndex[client] = -1;
				holding[client] = false;
				Timer[client] = INVALID_HANDLE;
			}
		}
	}
}