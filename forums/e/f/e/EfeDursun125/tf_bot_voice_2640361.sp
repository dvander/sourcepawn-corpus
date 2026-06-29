#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.1"

public Plugin:myinfo = 
{
	name = "TFBot Voice",
	author = "EfeDursun125",
	description = "TFBots now uses voice commands.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

public OnClientPutInServer(client)
{
	CreateTimer(10.0, MedicTimer, client, 3);
	CreateTimer(100.0, HelpThanksTimer, client, 3);
	CreateTimer(120.0, IncomingTimer, client, 3);
	return;
}

public Action:MedicTimer(Handle:timer, client)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				if (class == TFClass_Scout)
				{
					if(GetHealth(client) < 75.00)
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (class == TFClass_Soldier)
				{
					if(GetHealth(client) < 125.00)
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (class == TFClass_Pyro)
				{
					if(GetHealth(client) < 100.00)
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (class == TFClass_DemoMan)
				{
					if(GetHealth(client) < 100.00)
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (class == TFClass_Heavy)
				{
					if(GetHealth(client) < 200.00)
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (class == TFClass_Engineer)
				{
					if(GetHealth(client) < 75.00)
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (class == TFClass_Medic)
				{
					if(GetHealth(client) < 100.00)
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (class == TFClass_Sniper)
				{
					if(GetHealth(client) < 75.00)
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (class == TFClass_Spy)
				{
					if(GetHealth(client) < 70.00 && TF2_IsPlayerInCondition(client, TFCond_Disguising)) // 70 For Kunai
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
					else if(TF2_IsPlayerInCondition(client, TFCond_Cloaked))
					{
						FakeClientCommand(client, "voicemenu 0 0");
					}
				}
				if (GetHealth(client) <= 10)
				{
					FakeClientCommand(client, "voicemenu 1 6");
				}
			}
		}
	}
}

public Action:HelpThanksTimer(Handle:timer, client)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				new TFClassType:class = TF2_GetPlayerClass(client);
				if(TF2_IsPlayerInCondition(client, TFCond_Milked) || TF2_IsPlayerInCondition(client, TFCond_OnFire) &&  GetClientButtons(client) & IN_ATTACK || TF2_IsPlayerInCondition(client, TFCond_Bleeding) || TF2_IsPlayerInCondition(client, TFCond_Jarated) || TF2_IsPlayerInCondition(client, TFCond_Bonked))
				{
					FakeClientCommand(client, "voicemenu 2 0");
				}
				if(GetHealth(client) < 100.00 && GetClientButtons(client) & IN_ATTACK)
				{
					FakeClientCommand(client, "voicemenu 2 0");
				}
				if (class == TFClass_Scout)
				{
					if(GetHealth(client) >  125.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
				if (class == TFClass_Soldier)
				{
					if(GetHealth(client) >  200.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
				if (class == TFClass_Pyro)
				{
					if(GetHealth(client) > 175.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
				if (class == TFClass_DemoMan)
				{
					if(GetHealth(client) > 175.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
				if (class == TFClass_Heavy)
				{
					if(GetHealth(client) > 300.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
				if (class == TFClass_Engineer)
				{
					if(GetHealth(client) > 125.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
				if (class == TFClass_Medic)
				{
					if(GetHealth(client) > 150.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
				if (class == TFClass_Sniper)
				{
					if(GetHealth(client) > 125.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
				if (class == TFClass_Spy)
				{
					if(GetHealth(client) > 125.00)
					{
						FakeClientCommand(client, "voicemenu 0 1");
					}
				}
			}
		}
	}
}

public Action:IncomingTimer(Handle:timer, client)
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				if(GetHealth(client) < 125.00 && GetClientButtons(client) & IN_ATTACK)
				{
					FakeClientCommand(client, "voicemenu 1 0");
				}
				if(GetHealth(client) > 124.00 && GetClientButtons(client) & IN_ATTACK)
				{
					FakeClientCommand(client, "voicemenu 1 0");
					new random = GetRandomInt(1,3);
					new random2 = GetRandomInt(1,8);
					new random3 = GetRandomInt(1,3);
					switch(random)
					{
				    	case 1:
				    	{
				        	switch(random2)
				        	{
				        		case 1:
				        		{
				        			FakeClientCommand(client, "voicemenu 0 2");
								}
								case 2:
				        		{
				        			FakeClientCommand(client, "voicemenu 0 3");
								}
								case 3:
				        		{
				        			FakeClientCommand(client, "voicemenu 0 4");
								}
								case 4:
				        		{
				        			FakeClientCommand(client, "voicemenu 0 5");
								}
								case 5:
				        		{
				        			FakeClientCommand(client, "voicemenu 0 0");
								}
								case 6:
				        		{
				        			FakeClientCommand(client, "voicemenu 1 6");
								}
								case 7:
				        		{
				        			FakeClientCommand(client, "voicemenu 1 0");
								}
								case 8:
				        		{
				        			FakeClientCommand(client, "voicemenu 2 0");
								}
				        	}
				    	}
						case 2:
				    	{
				        	switch(random3)
				        	{
				        		case 1:
				        		{
				        			FakeClientCommand(client, "voicemenu 0 6");
								}
								case 2:
				        		{
				        			FakeClientCommand(client, "voicemenu 0 7");
								}
								case 3:
				        		{
				        			FakeClientCommand(client, "voicemenu 1 5");
								}
				        	}
				    	}
						case 3:
				    	{
				        	// NOPE
				    	}
					}
				}
			}
		}
	}
}

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock GetHealth(client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

bool:IsValidClient( client ) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}
  