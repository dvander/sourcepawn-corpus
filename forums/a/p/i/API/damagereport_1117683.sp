#include <sourcemod>

#define MAX_CLIENTS 64

// When someone is a victim and dies, he references damage done, looping the y value with victim being x
new DmgDone[MAX_CLIENTS+1][MAX_CLIENTS+1]; // [x][y] How much damage did x do to y?
new DmgArmorDone[MAX_CLIENTS+1][MAX_CLIENTS+1]; // Ditto.
new bool:AttackedBy[MAX_CLIENTS+1][MAX_CLIENTS+1]; // Makes it easier to track.
// Simply print these values in a pretty format and print remaining HP.
new Handle:CVarDM;
new Handle:CVarEventDmg;
new Handle:CVarEventArmor;

ResetAttackedBy(x_val)
{
	if(x_val>0 && x_val<=MAX_CLIENTS)
	{
		for(new y=0;y<=MAX_CLIENTS;y++)
		{
			AttackedBy[x_val][y]=false;
		}
	}
	else
	{
		for(new x=0;x<=MAX_CLIENTS;x++)
		{
			for(new y=0;y<=MAX_CLIENTS;y++)
			{
				AttackedBy[x][y]=false;
			}
		}	
	}
}
	
ResetDmgDone(x_val)
{
	if(x_val>0 && x_val<=MAX_CLIENTS)
	{
		for(new y=1;y<=MAX_CLIENTS;y++)
		{
			DmgDone[x_val][y]=0;
			DmgArmorDone[x_val][y]=0;
		}
	}
	else
	{
		for(new x=1;x<=MAX_CLIENTS;x++)
		{
			for(new y=1;y<=MAX_CLIENTS;y++)
			{
				DmgDone[x][y]=0;
				DmgArmorDone[x][y]=0;
			}
		}	
	}
}

public Action:PSEvent(Handle:event, const String:name[], bool:dB)
{
	new cl=GetClientOfUserId(GetEventInt(event,"userid"));
	if(cl > 0 && cl <= MaxClients)
	{
		ResetDmgDone(cl);
		ResetAttackedBy(cl);
	}
}


public Action:PDEvent(Handle:event, const String:name[], bool:dontBroatcast)
{
	new victim=GetClientOfUserId(GetEventInt(event,"userid"));
	if(victim>0 && victim<=MaxClients)
	{
		// Print out the damage they did to all their attackers.
		for(new a=1;a<=MaxClients;a++)
		{
			if(IsClientConnected(a) && IsClientInGame(a))
			{
				if(AttackedBy[victim][a])
				{
					new String:clName[64];
					if(GetClientName(a,clName,64))
					{
						new hpLeft=GetClientHealth(a);
						new bool:DidDmg=false;
						new dmg = 0;
						new dmg_armor = 0;
						if((dmg = DmgDone[victim][a]) > 0)
						{
							DidDmg=true;
						}
						if((dmg_armor = DmgArmorDone[victim][a]) > 0)
						{
							DidDmg=true;
						}
						if(DidDmg)
						{
							// Print a phrase saying the attacker's name, HP left, and a damage report.
							PrintToChat(victim,"%T","Damage Report",victim,clName,hpLeft,dmg,dmg_armor);
						}
						else
						{
							// Print a phrase just saying the attackers name and their HP left.
							PrintToChat(victim,"%T","Damage Report No Damage",victim,clName,hpLeft);
						}
					}
				}
			}
		}
	}
}

public Action:PHEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim=GetClientOfUserId(GetEventInt(event,"userid"));
	new attacker=GetClientOfUserId(GetEventInt(event,"attacker"));
	if(victim>0 && victim<=MaxClients && attacker>0 && attacker<=MaxClients && victim!=attacker)
	{
		new bool:Fail=false;
		if(!GetConVarBool(CVarDM))
		{
			if(GetClientTeam(victim)==GetClientTeam(attacker))
			{
				Fail=true;
			}
		}
		if(!Fail)
		{
			new String:eventDmg[32];
			new String:eventDmgArmor[32];
			GetConVarString(CVarEventDmg,eventDmg,32);
			GetConVarString(CVarEventArmor,eventDmgArmor,32);
			new dmg=0;
			if(StrEqual(eventDmg,"",false))
			{
				dmg=GetEventInt(event,"dmg_health"); // Default adapted from CS: S.
			}
			else
			{
				dmg=GetEventInt(event,eventDmg);
			}
			new dmg_armor=0;
			if(StrEqual(eventDmgArmor,"",false))
			{
				dmg_armor=GetEventInt(event,"dmg_armor"); // Default adapted from CS: S.
			}
			else
			{
				dmg_armor=GetEventInt(event,eventDmgArmor);
			}
			if(dmg < 0)
			{
				dmg = 0; // This isn't really a proper implementation of player_hurt?
				LogError("WARNING: Negative damage inflicted!");
			}
			if(dmg_armor < 0)
			{
				dmg_armor = 0; // Ditto with previous "if"
				LogError("WARNING: Negative armor damage inflicted!");
			}
			AttackedBy[victim][attacker]=true;
			DmgDone[attacker][victim]+=dmg;
			DmgArmorDone[attacker][victim]+=dmg_armor;
		}	
	}
}

public OnClientPutInServer(cl)
{
	ResetDmgDone(cl);
	ResetAttackedBy(cl);
}

public OnPluginStart()
{
	ResetDmgDone(0); // Passing nothing will tell it to clear the whole array.
	ResetAttackedBy(0); // Ditto.
	LoadTranslations("damagereport.phrases");
	if(!HookEventEx("player_hurt",PHEvent))
	{
		SetFailState("Mod doesn't support player_hurt");
	}
	else if(!HookEventEx("player_spawn",PSEvent))
	{
		SetFailState("Mod doesn't support player_spawn");
	}
	else if(!HookEventEx("player_death",PDEvent))
	{
		SetFailState("Mod doesn't support player_death");
	}
	else if(!(CVarDM=CreateConVar("dmg_report_dm","0")))
	{
		SetFailState("Could not create cvar dmg_report_dm");
	}
	else if(!(CVarEventDmg=CreateConVar("dmg_report_dmg","dmg_health","Field in player_hurt for non-armor damage")))
	{
		SetFailState("Could not create cvar dmg_report_dmg");
	}
	else if(!(CVarEventArmor=CreateConVar("dmg_report_armor","dmg_armor","Field in player_hurt for armor damage")))
	{
		SetFailState("Could not create cvar dmg_report_armor");
	}
	else
	{
		PrintToServer("Loaded damage report.");
	}
}