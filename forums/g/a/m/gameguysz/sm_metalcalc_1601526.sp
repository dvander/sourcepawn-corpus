/* Still In BETA. Need to clean*/

#include <sourcemod>
#include <sdktools>
#include <tf2>
#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo = 
{
	name = "sm_metalcalc",
	author = "gameguysz",
	description = "TF2 Metal Calculator for trading",
	version = PLUGIN_VERSION,
	url = "http://www.vdgamingnetwork.net/"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_mult", Mult, "Usage: mult <metel amount> <Metal type ex:ref> <multiply amount>");
	RegConsoleCmd("sm_add", Add, "Usage: add <metel amount> <Metal type ex:ref> <add amount>");
	RegConsoleCmd("sm_div", Div, "Usage: add <metel amount> <Metal type ex:ref> <add amount>");
	RegConsoleCmd("sm_sub", Sub, "Usage: add <metel amount> <Metal type ex:ref> <add amount>");
	RegConsoleCmd("mult", Mult, "Usage: mult <metel amount> <Metal type ex:ref> <multiply amount>");
	RegConsoleCmd("add", Add, "Usage: add <metel amount> <Metal type ex:ref> <add amount>");
	RegConsoleCmd("div", Div, "Usage: add <metel amount> <Metal type ex:ref> <add amount>");
	RegConsoleCmd("sub", Sub, "Usage: add <metel amount> <Metal type ex:ref> <add amount>");
	CreateConVar("sm_metalcalc_version", PLUGIN_VERSION, "Version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY);
}


public Action:Mult(client, args)
{
	if (args != 1)
	{
		new String:arg[32], String:arg2[32]
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(3, arg2, sizeof(arg2));
		new Float:MetalAmount, MultAmount
		MetalAmount = StringToFloat(arg);
		MultAmount = StringToInt(arg2);
		decl String:MetalType[8]
		GetCmdArg(2, MetalType, sizeof(MetalType));
		new Float:MetalTotal = MetalAmount * MultAmount;
		new Float:Mult1 = MetalTotal / 3;
		new Float:Mult2 = MetalTotal / 9;
		new Float:Mult3 = MetalTotal * 3;
		new Float:Mult4 = MetalTotal * 9;
		new Float:FindScraps = MetalTotal * 3;
		RoundToNearest(Mult2);
		RoundToNearest(Mult1);
		RoundToCeil(FindScraps);
		RoundToCeil(Mult3);
		
		//refine Calc
		if(MetalTotal >= 1.0 && StrEqual(MetalType,"ref", false) || StrEqual(MetalType,"refined", false) || StrEqual(MetalType,"refine", false))
		{
			PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref\x01 or %i Rec or %i Scrap(s)", MetalTotal, RoundToCeil(Mult3), RoundToCeil(Mult4));
		}
		//reclaim Calc
		else if (MetalTotal >= 1.0 && StrEqual(MetalType,"rec", false) || StrEqual(MetalType,"reclaim", false) || StrEqual(MetalType,"refclaimed", false))
		{
			if(MetalTotal >= 3.0)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref \x01or %i Rec or %i Scrap(s)",Mult1, RoundToNearest(MetalTotal), RoundToNearest(FindScraps));
			}
			else
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %f Rec or %i Scrap(s)", MetalTotal, RoundToNearest(Mult1));
			}
		}
		//scrap Calc
		else if (MetalTotal >= 1.0 && StrEqual(MetalType,"scrap", false) || StrEqual(MetalType,"scraps", false))
		{
			if (MetalTotal >= 3 && MetalTotal < 9)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %f Rec or %f Scraps(s)", RoundToNearest(Mult1), MetalTotal);
			}
			else if (MetalTotal >= 9)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref \x01or %i Rec or %i Scraps(s)", Mult2, RoundToNearest(Mult1), RoundToNearest(MetalTotal));
			}
			else if(MetalTotal >= 1 && MetalTotal < 6)
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %i Scraps(s)", RoundToNearest(MetalTotal));
		}
		else
		{
			PrintToChat(client, "\x03[SMMC] \x01Usage Example: mult 1.0 ref 2 [Amount to Multiply/Type Of Metal/Multiply By]");
		}
	}
	return Plugin_Handled;
}


public Action:Add(client, args)
{
	if (args != 1)
	{
		new String:arg[32], String:arg2[32]
		decl String:MetalType[8]
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, MetalType, sizeof(MetalType));
		GetCmdArg(3, arg2, sizeof(arg2));
		new Float:MetalAmount, MultAmount
		MetalAmount = StringToFloat(arg);
		MultAmount = StringToInt(arg2);
		new Float:MetalTotal = MetalAmount += MultAmount;
		new Float:Mult1 = MetalTotal / 3;
		new Float:Mult2 = MetalTotal / 9;
		new Float:Mult3 = MetalTotal * 3;
		new Float:Mult4 = MetalTotal * 9;
		new Float:FindScraps = MetalTotal * 3;
		RoundToNearest(Mult2);
		
		//refine Calc
		if(MetalTotal >= 1.0 && StrEqual(MetalType,"ref", false) || StrEqual(MetalType,"refined", false) || StrEqual(MetalType,"refine", false))
		{
			PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref\x01 or %i Rec or %i Scrap(s)", MetalTotal, RoundToCeil(Mult3), RoundToCeil(Mult4));
		}
		//reclaim Calc
		else if (MetalTotal >= 1.0 && StrEqual(MetalType,"rec", false) || StrEqual(MetalType,"reclaim", false) || StrEqual(MetalType,"refclaimed", false))
		{
			if(MetalTotal >= 3.0)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref \x01or %i Rec or %i Scrap(s)",Mult1, RoundToNearest(MetalTotal), RoundToNearest(FindScraps));
			}
			else
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %f Rec or %i Scrap(s)", MetalTotal, RoundToNearest(Mult1));
			}
		}
		//scrap Calc
		else if (MetalTotal >= 1.0 && StrEqual(MetalType,"scrap", false) || StrEqual(MetalType,"scraps", false))
		{
			if (MetalTotal >= 3 && MetalTotal < 9)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %f Rec or %f Scraps(s)", RoundToNearest(Mult1), MetalTotal);
			}
			else if (MetalTotal >= 9)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref \x01or %i Rec or %i Scraps(s)", Mult2, RoundToNearest(Mult1), RoundToNearest(MetalTotal));
			}
			else if(MetalTotal >= 1 && MetalTotal < 6)
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %i Scraps(s)", RoundToNearest(MetalTotal));
		}
		else
		{
			PrintToChat(client, "\x03[SMMC] \x01Usage Example: add 1.0 ref 2 [Amount to Add/Type Of Metal/Add By]");
		}
	}
	return Plugin_Handled;
}

public Action:Div(client, args)
{
	if (args != 1)
	{
		new String:arg[32], String:arg2[32]
		decl String:MetalType[8]
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, MetalType, sizeof(MetalType));
		GetCmdArg(3, arg2, sizeof(arg2));
		new Float:MetalAmount, MultAmount
		MetalAmount = StringToFloat(arg);
		MultAmount = StringToInt(arg2);
		new Float:MetalTotal = MetalAmount / MultAmount;
		new Float:Mult1 = MetalTotal / 3;
		new Float:Mult2 = MetalTotal / 9;
		new Float:Mult3 = MetalTotal * 3;
		new Float:Mult4 = MetalTotal * 9;
		new Float:FindScraps = MetalTotal * 3;
		RoundToNearest(Mult2);
		
		//refine Calc
		if(MetalTotal >= 1.0 && StrEqual(MetalType,"ref", false) || StrEqual(MetalType,"refined", false) || StrEqual(MetalType,"refine", false))
		{
			PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref\x01 or %i Rec or %i Scrap(s)", MetalTotal, RoundToCeil(Mult3), RoundToCeil(Mult4));
		}
		//reclaim Calc
		else if (MetalTotal >= 1.0 && StrEqual(MetalType,"rec", false) || StrEqual(MetalType,"reclaim", false) || StrEqual(MetalType,"refclaimed", false))
		{
			if(MetalTotal >= 3.0)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref \x01or %i Rec or %i Scrap(s)",Mult1, RoundToNearest(MetalTotal), RoundToNearest(FindScraps));
			}
			else
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %f Rec or %i Scrap(s)", MetalTotal, RoundToNearest(Mult1));
			}
		}
		//scrap Calc
		else if (MetalTotal >= 1.0 && StrEqual(MetalType,"scrap", false) || StrEqual(MetalType,"scraps", false))
		{
			if (MetalTotal >= 3 && MetalTotal < 9)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %f Rec or %f Scraps(s)", RoundToNearest(Mult1), MetalTotal);
			}
			else if (MetalTotal >= 9)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref \x01or %i Rec or %i Scraps(s)", Mult2, RoundToNearest(Mult1), RoundToNearest(MetalTotal));
			}
			else if(MetalTotal >= 1 && MetalTotal < 6)
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %i Scraps(s)", RoundToNearest(MetalTotal));
		}
		else
		{
			PrintToChat(client, "\x03[SMMC] \x01Usage Example: add 1.0 ref 2 [Amount to Add/Type Of Metal/Add By]");
		}
	}
	return Plugin_Handled;
}

public Action:Sub(client, args)
{
	if (args != 1)
	{
		new String:arg[32], String:arg2[32]
		decl String:MetalType[8]
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, MetalType, sizeof(MetalType));
		GetCmdArg(3, arg2, sizeof(arg2));
		new Float:MetalAmount, MultAmount
		MetalAmount = StringToFloat(arg);
		MultAmount = StringToInt(arg2);
		new Float:MetalTotal = MetalAmount -= MultAmount;
		new Float:Mult1 = MetalTotal / 3;
		new Float:Mult2 = MetalTotal / 9;
		new Float:Mult3 = MetalTotal * 3;
		new Float:Mult4 = MetalTotal * 9;
		new Float:FindScraps = MetalTotal * 3;
		RoundToNearest(Mult2);
		
		//refine Calc
		if(MetalTotal >= 1.0 && StrEqual(MetalType,"ref", false) || StrEqual(MetalType,"refined", false) || StrEqual(MetalType,"refine", false))
		{
			PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref\x01 or %i Rec or %i Scrap(s)", MetalTotal, RoundToCeil(Mult3), RoundToCeil(Mult4));
		}
		//reclaim Calc
		else if (MetalTotal >= 1.0 && StrEqual(MetalType,"rec", false) || StrEqual(MetalType,"reclaim", false) || StrEqual(MetalType,"refclaimed", false))
		{
			if(MetalTotal >= 3.0)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref \x01or %i Rec or %i Scrap(s)",Mult1, RoundToNearest(MetalTotal), RoundToNearest(FindScraps));
			}
			else
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %f Rec or %i Scrap(s)", MetalTotal, RoundToNearest(Mult1));
			}
		}
		//scrap Calc
		else if (MetalTotal >= 1.0 && StrEqual(MetalType,"scrap", false) || StrEqual(MetalType,"scraps", false))
		{
			if (MetalTotal >= 3 && MetalTotal < 9)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %f Rec or %f Scraps(s)", RoundToNearest(Mult1), MetalTotal);
			}
			else if (MetalTotal >= 9)
			{
				PrintToChat(client, "\x03[SMMC]\x01Your total is: \x03%f Ref \x01or %i Rec or %i Scraps(s)", Mult2, RoundToNearest(Mult1), RoundToNearest(MetalTotal));
			}
			else if(MetalTotal >= 1 && MetalTotal < 6)
				PrintToChat(client, "\x03[SMMC]\x01Your total is: %i Scraps(s)", RoundToNearest(MetalTotal));
		}
		else
		{
			PrintToChat(client, "\x03[SMMC] \x01Usage Example: add 1.0 ref 2 [Amount to Add/Type Of Metal/Add By]");
		}
	}
	return Plugin_Handled;
}