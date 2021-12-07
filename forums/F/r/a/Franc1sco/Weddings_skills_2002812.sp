#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <weddings>


new g_BeamSprite;
new g_HaloSprite;
new g_iAccount = -1;


new bool:money[MAXPLAYERS+1];
new bool:beacon[MAXPLAYERS+1];
new bool:amigo[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "SM Weddings skills",
	author = "Franc1sco Steam: franug",
	description = "Requested by eyes of hunter",
	version = "1.0",
	url = "http://servers-cfg.foroactivo.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_weddings_skills", "1.0", "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_love", TheLove);
}

public OnClientPostAdminCheck(client)
{
	amigo[client] = true;
	money[client] = true;
	beacon[client] = true;
}

public OnMapStart()
{
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");

	CreateTimer(1.0, Temporizador, _,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
}

public Action:Temporizador(Handle:timer)
{
	decl String:steamid[64], String:steamid2[64], String:steamid3[64];
	for (new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			GetClientAuthString(i, steamid, sizeof(steamid));
			if(IsClientMarried(steamid))
			{
				GetPartnerID(steamid, steamid2);
				for (new i2 = 1; i2 <= MaxClients; i2++)
					if(IsClientInGame(i2) && IsPlayerAlive(i2))
					{
						GetClientAuthString(i2, steamid3, sizeof(steamid3));
						if(StrEqual(steamid2, steamid3)) 
						{
							SetupBeacon(i, i2);
							SharedMoney(i, i2);
							break;
						}
						
					}
				
			}
		}
}

SetupBeacon(client, married)
{
	if(!beacon[married]) return;
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	vec[2] += 10;
	TE_SetupBeamRingPoint(vec, 10.0, 375.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, {247, 191, 190, 255}, 10, 0);
	TE_SendToClient(married);
}


public OnClientPutInServer(client)
{

	SDKHook(client, SDKHook_OnTakeDamage, OnDamage);

}

public Action:OnDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!attacker || GetClientTeam(victim) != GetClientTeam(attacker)) return Plugin_Continue;
	
	decl String:steamid[64], String:steamid2[64], String:steamid3[64];
	GetClientAuthString(victim, steamid, sizeof(steamid));
	if(IsClientMarried(steamid))
	{
		GetClientAuthString(attacker, steamid2, sizeof(steamid2));
		if(IsClientMarried(steamid2))
		{
			GetPartnerID(steamid, steamid3);
			if(StrEqual(steamid2, steamid3) && amigo[victim] && amigo[attacker]) return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

SharedMoney(client, married)
{
	if(!money[client] || !money[married]) return;
	
	new dinerototal = ObtenerDinero(client) + ObtenerDinero(married);
	dinerototal /= 2;
	FijarDinero(client, dinerototal);
	FijarDinero(married, dinerototal);
}

stock ObtenerDinero(client)
{
	new dinero = GetEntData(client, g_iAccount);
	return dinero;
}

stock FijarDinero(client, cantidad)
{
	SetEntData(client, g_iAccount, cantidad);
}

public Action:TheLove(client,args)
{
	decl String:steamid[64];
	GetClientAuthString(client, steamid, sizeof(steamid));
	if(IsClientMarried(steamid))
		DID(client);
	else
		PrintToChat(client, "\x04[SM_Weddings-Skills] \x05You need to be married for use this command");
		
	return Plugin_Handled;
}

public Action:DID(clientId) 
{
	new Handle:menu = CreateMenu(DIDMenuHandler);
	SetMenuTitle(menu, "Weddings Skills");
	if(money[clientId]) AddMenuItem(menu, "option1", "Disable shared money");
	else AddMenuItem(menu, "option1", "Enable shared money");
	
	if(beacon[clientId]) AddMenuItem(menu, "option2", "Disable beacon in your wife");
	else AddMenuItem(menu, "option2", "Enable beacon in your wife");
	
	if(amigo[clientId]) AddMenuItem(menu, "option3", "Disable no Friendly Fire in your wife");
	else AddMenuItem(menu, "option3", "Enable no Friendly Fire in your wife");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, clientId, MENU_TIME_FOREVER);

}

public DIDMenuHandler(Handle:menu, MenuAction:action, client, itemNum) 
{
	if ( action == MenuAction_Select ) 
	{
		new String:info[32];
        
		GetMenuItem(menu, itemNum, info, sizeof(info));
        
		if ( strcmp(info,"option1") == 0 ) 
		{
			if(money[client])
			{
				money[client] = false;
				PrintToChat(client, "\x04[SM_Weddings-Skills] \x05Shared money disabled");
			}
			else
			{
				money[client] = true;
				PrintToChat(client, "\x04[SM_Weddings-Skills] \x05Shared money enabled");
			}
			DID(client);
		}
        
		else if ( strcmp(info,"option2") == 0 ) 
		{
			if(beacon[client])
			{
				beacon[client] = false;
				PrintToChat(client, "\x04[SM_Weddings-Skills] \x05Beacon in your wife disabled");
			}
			else
			{
				beacon[client] = true;
				PrintToChat(client, "\x04[SM_Weddings-Skills] \x05Beacon in your wife enabled");
			}
			DID(client);
		}
		else if ( strcmp(info,"option3") == 0 ) 
		{
			if(amigo[client])
			{
				amigo[client] = false;
				PrintToChat(client, "\x04[SM_Weddings-Skills] \x05No Friendly Fire in your wife disabled");
			}
			else
			{
				amigo[client] = true;
				PrintToChat(client, "\x04[SM_Weddings-Skills] \x05No Friendly Fire in your wife enabled");
			}
			DID(client);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
