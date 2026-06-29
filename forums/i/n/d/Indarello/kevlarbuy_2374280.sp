#include <sdktools>

public Plugin:myinfo = 
{
	name = "Kevlar buy",
	author = "Indarello",
	version = "1.0",
}


new iBuyZone = -1;
new ztime;
public OnPluginStart()
{
	RegConsoleCmd("buy", CommandSell);
	iBuyZone = FindSendPropOffs("CCSPlayer", "m_bInBuyZone");
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
//	RegConsoleCmd("mm", CommandSell2); 
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ztime = GetTime();
}

/*
public Action:CommandSell2(client, args)
{
	SetEntProp(client, Prop_Send, "m_iAccount", 500); 
	SetEntProp(client, Prop_Send, "m_ArmorValue", 70);
}
*/

public Action:CS_OnBuyCommand(client, const String:weapon[]) // Запрет покупки
{
	if(!strcmp(weapon, "kevlar"))
	{
		if(GetEntProp(client, Prop_Send, "m_ArmorValue") > 51) 
		{
			BuyArmor(client);
			return Plugin_Handled;
		}	
	}
	else if(!strcmp(weapon, "assaultsuit"))
	{
		if(GetEntProp(client, Prop_Send, "m_ArmorValue") > 51) 
		{
			BuyHelm(client);
			return Plugin_Handled;
		}	
	}
	
	return Plugin_Continue;
}

public Action:CommandSell(client, args)
{
	if(!IsClientInGame(client))
	{
		return Plugin_Continue;
	}	
	if(!GetEntData(client, iBuyZone, 1))
	{
		return Plugin_Continue;
	}
	if(args != 1 || GetTime() > ztime + 15)
	{
		return Plugin_Continue;
	}

	decl String:buffer[50];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	if(!strcmp(buffer, "vest"))
	{
		if(GetEntProp(client, Prop_Send, "m_ArmorValue") > 51) 
		{
			BuyArmor(client);
			return Plugin_Handled;
		}	
	}
	
	else if(!strcmp(buffer, "vesthelm") || !strcmp(buffer, "assaultsuit")) 
	{
		if(GetEntProp(client, Prop_Send, "m_ArmorValue") > 51) 
		{
			BuyHelm(client);
			return Plugin_Handled;
		}	
	} 
		
	return Plugin_Continue;
}

BuyHelm(client)
{
	new bool:sounded = BuyArmor(client);
	if(!GetEntProp(client, Prop_Send, "m_bHasHelmet"))
	{
		new money = GetEntProp(client, Prop_Send, "m_iAccount");
		if(money >= 350) 
		{
			if(!sounded) EmitSoundToClient(client, "items/ammopickup.wav");
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			SetEntProp(client, Prop_Send, "m_iAccount", money - 350); 
		}
	}
}

bool:BuyArmor(client)
{
	new money = GetEntProp(client, Prop_Send, "m_iAccount");
	
	new armor = GetEntProp(client, Prop_Send, "m_ArmorValue");
	if(money && armor!= 100)
	{
		if(money < RoundFloat(6.5*(100 - armor))*2)
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", armor+RoundFloat(money/6.5)/2);
			SetEntProp(client, Prop_Send, "m_iAccount", 0); 
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
			SetEntProp(client, Prop_Send, "m_iAccount", money - RoundFloat(6.5*(100 - armor))*2); 
		}
		EmitSoundToClient(client, "items/ammopickup.wav");
		return true;
	}
	return false;
}